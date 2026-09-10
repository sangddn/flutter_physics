import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter_test/flutter_test.dart';

class _SwitcherFixture {
  final disposedChildren = <String>[];
  final controllers = <PhysicsController>[];

  Widget build(
    String? label, {
    String? childKey,
    Physics? physics,
    Duration? duration,
    Duration? reverseDuration,
    AnimatedSwitcherTransitionBuilder? transitionBuilder,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: ASwitcher(
          physics: physics ?? Spring.swift,
          duration: duration,
          reverseDuration: reverseDuration,
          transitionBuilder: transitionBuilder ?? _transitionBuilder,
          child: label == null
              ? null
              : _TrackedChild(
                  key: ValueKey(childKey ?? label),
                  label: label,
                  onDispose: disposedChildren.add,
                ),
        ),
      ),
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    final controller = animation as PhysicsController;
    if (!controllers.contains(controller)) controllers.add(controller);
    return FadeTransition(opacity: animation, child: child);
  }
}

class _TrackedChild extends StatefulWidget {
  const _TrackedChild({
    super.key,
    required this.label,
    required this.onDispose,
  });

  final String label;
  final ValueChanged<String> onDispose;

  @override
  State<_TrackedChild> createState() => _TrackedChildState();
}

class _TrackedChildState extends State<_TrackedChild> {
  @override
  Widget build(BuildContext context) => Text(widget.label);

  @override
  void dispose() {
    widget.onDispose(widget.label);
    super.dispose();
  }
}

void _expectDisposed(PhysicsController controller) {
  expect(controller.forward, throwsAssertionError);
}

void main() {
  group('ASwitcher outgoing children', () {
    testWidgets('repeated settled swaps retain only the current child',
        (tester) async {
      final fixture = _SwitcherFixture();
      for (final label in ['a', 'b', 'c', 'd']) {
        await tester.pumpWidget(fixture.build(label));
        await tester.pumpAndSettle();
      }

      expect(find.byType(_TrackedChild), findsOneWidget);
      expect(find.text('d'), findsOneWidget);
      expect(fixture.disposedChildren, ['a', 'b', 'c']);
      for (final controller in fixture.controllers.take(3)) {
        _expectDisposed(controller);
      }
      expect(fixture.controllers.last.status, AnimationStatus.completed);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the outgoing child until its reverse animation finishes',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('a'));
      await tester.pumpWidget(fixture.build('b'));
      await tester.pump(const Duration(milliseconds: 16));

      final outgoing = fixture.controllers.first;
      expect(outgoing.isAnimating, isTrue);
      expect(outgoing.status, AnimationStatus.reverse);
      expect(outgoing.value, greaterThan(0));
      expect(outgoing.value, lessThan(1));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(fixture.disposedChildren, isEmpty);

      await tester.pumpAndSettle();
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsOneWidget);
      expect(fixture.disposedChildren, ['a']);
      _expectDisposed(outgoing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rapid swaps can reuse a key while its previous child exits',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('first-a', childKey: 'a'));
      await tester.pumpWidget(fixture.build('b'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(fixture.build('second-a', childKey: 'a'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(_TrackedChild), findsNWidgets(3));
      expect(fixture.disposedChildren, isEmpty);
      expect(fixture.controllers, hasLength(3));

      await tester.pumpAndSettle();
      expect(find.byType(_TrackedChild), findsOneWidget);
      expect(find.text('second-a'), findsOneWidget);
      expect(fixture.disposedChildren, unorderedEquals(['first-a', 'b']));
      for (final controller in fixture.controllers.take(2)) {
        _expectDisposed(controller);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'transitioning to null disposes the outgoing child and controller',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('a'));
      await tester.pumpWidget(fixture.build(null));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('a'), findsOneWidget);
      expect(fixture.disposedChildren, isEmpty);

      await tester.pumpAndSettle();
      expect(find.byType(_TrackedChild), findsNothing);
      expect(fixture.disposedChildren, ['a']);
      _expectDisposed(fixture.controllers.single);

      await tester.pumpWidget(fixture.build('b'));
      await tester.pumpAndSettle();
      expect(find.text('b'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'same type and key updates the child without replacing its state',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('before', childKey: 'same'));
      final childState = tester.state(find.byType(_TrackedChild));
      final controller = fixture.controllers.single;

      await tester.pumpWidget(fixture.build('after', childKey: 'same'));

      expect(find.text('before'), findsNothing);
      expect(find.text('after'), findsOneWidget);
      expect(tester.state(find.byType(_TrackedChild)), same(childState));
      expect(fixture.controllers.single, same(controller));
      expect(controller.isAnimating, isFalse);
      expect(controller.status, AnimationStatus.completed);
      expect(fixture.disposedChildren, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('zero-duration swaps remove outgoing entries immediately',
        (tester) async {
      final fixture = _SwitcherFixture();
      Widget build(String? label) => fixture.build(
            label,
            physics: Curves.linear,
            duration: Duration.zero,
            reverseDuration: Duration.zero,
          );

      await tester.pumpWidget(build('a'));
      await tester.pumpWidget(build('b'));
      expect(tester.takeException(), isNull);
      expect(find.byType(_TrackedChild), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(fixture.disposedChildren, ['a']);
      _expectDisposed(fixture.controllers.first);

      await tester.pumpWidget(build(null));
      expect(find.byType(_TrackedChild), findsNothing);
      expect(fixture.disposedChildren, ['a', 'b']);
      _expectDisposed(fixture.controllers.last);
      expect(tester.takeException(), isNull);
    });

    testWidgets('interrupting a new child before its first tick cleans it up',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build(null));
      await tester.pumpWidget(fixture.build('a'));
      final interrupted = fixture.controllers.single;
      expect(interrupted.value, 0);

      await tester.pumpWidget(fixture.build('b'));
      await tester.pumpAndSettle();

      expect(find.byType(_TrackedChild), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(fixture.disposedChildren, ['a']);
      _expectDisposed(interrupted);
      expect(tester.takeException(), isNull);
    });

    testWidgets('removing the switcher during animation disposes all entries',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('a'));
      await tester.pumpWidget(fixture.build('b'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(fixture.controllers.every((c) => c.isAnimating), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(fixture.disposedChildren, unorderedEquals(['a', 'b']));
      for (final controller in fixture.controllers) {
        _expectDisposed(controller);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'changing the transition builder still removes outgoing entries',
        (tester) async {
      final fixture = _SwitcherFixture();
      await tester.pumpWidget(fixture.build('a'));
      await tester.pumpWidget(fixture.build('b'));
      await tester.pump(const Duration(milliseconds: 16));

      await tester.pumpWidget(fixture.build(
        'b',
        transitionBuilder: (child, animation) =>
            SizeTransition(sizeFactor: animation, child: child),
      ));
      expect(find.byType(SizeTransition), findsNWidgets(2));
      expect(find.byType(FadeTransition), findsNothing);
      // Changing the wrapper type remounts its children. Track the later
      // disposal caused specifically by the outgoing animation completing.
      fixture.disposedChildren.clear();

      await tester.pumpAndSettle();
      expect(find.byType(SizeTransition), findsOneWidget);
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsOneWidget);
      expect(fixture.disposedChildren, ['a']);
      _expectDisposed(fixture.controllers.first);
      expect(tester.takeException(), isNull);
    });
  });
}

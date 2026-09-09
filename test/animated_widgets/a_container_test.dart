import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter_test/flutter_test.dart';

const _shadowDecoration = BoxDecoration(
  color: Color(0xffeeeeee),
  boxShadow: [BoxShadow(blurRadius: 12, offset: Offset(0, 4))],
);
const _emptyDecoration = BoxDecoration(
  color: Color(0xffeeeeee),
  boxShadow: [],
);
const _nullShadowDecoration = BoxDecoration(color: Color(0xffeeeeee));

Widget _container({
  required bool foreground,
  required BoxDecoration decoration,
  double width = 100,
  Alignment alignment = Alignment.centerLeft,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: AContainer(
        physics: Spring.swift,
        decoration: foreground ? null : decoration,
        foregroundDecoration: foreground ? decoration : null,
        width: width,
        height: 100,
        alignment: alignment,
        child: const SizedBox(width: 10, height: 10),
      ),
    ),
  );
}

Container _renderedContainer(WidgetTester tester) => tester.widget<Container>(
      find.descendant(
        of: find.byType(AContainer),
        matching: find.byType(Container),
      ),
    );

BoxDecoration _renderedDecoration(WidgetTester tester, bool foreground) {
  final container = _renderedContainer(tester);
  return (foreground ? container.foregroundDecoration : container.decoration)
      as BoxDecoration;
}

Future<void> _pumpUntilOvershoot(WidgetTester tester) async {
  final state = tester.state<PhysicsAnimatedWidgetState<AContainer>>(
    find.byType(AContainer),
  );
  for (var frame = 0; frame < 120; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    if (state.animation.value > 1) return;
  }
  fail('Spring.swift must overshoot to exercise progress above 1.0.');
}

void main() {
  group('AContainer decoration overshoot', () {
    for (final foreground in [false, true]) {
      final property = foreground ? 'foregroundDecoration' : 'decoration';

      for (final target in [_emptyDecoration, _nullShadowDecoration]) {
        final shadowList = target.boxShadow == null ? 'null' : 'empty';
        testWidgets('$property safely removes shadows to $shadowList list',
            (tester) async {
          await tester.pumpWidget(_container(
            foreground: foreground,
            decoration: _shadowDecoration,
          ));
          await tester.pumpWidget(_container(
            foreground: foreground,
            decoration: target,
            width: 200,
            alignment: Alignment.centerRight,
          ));

          await _pumpUntilOvershoot(tester);
          final container = _renderedContainer(tester);
          expect(container.constraints!.minWidth, greaterThan(200));
          expect((container.alignment! as Alignment).x, greaterThan(1));
          expect(_renderedDecoration(tester, foreground), target);

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(ErrorWidget), findsNothing);
          expect(_renderedDecoration(tester, foreground), target);
        });
      }

      testWidgets('$property can retarget while the spring overshoots',
          (tester) async {
        await tester.pumpWidget(_container(
          foreground: foreground,
          decoration: _shadowDecoration,
        ));
        await tester.pumpWidget(_container(
          foreground: foreground,
          decoration: _emptyDecoration,
        ));

        final state = tester.state<PhysicsAnimatedWidgetState<AContainer>>(
          find.byType(AContainer),
        );
        final values = state.controller.value.toList();
        values[0] = 1.1;
        state.controller.value = values;
        expect(state.animation.value, greaterThan(1));

        // Retarget before the next build so this specifically exercises the
        // old tween's evaluation when selecting its new begin value.
        await tester.pumpWidget(_container(
          foreground: foreground,
          decoration: _shadowDecoration,
        ));
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(_renderedDecoration(tester, foreground), _emptyDecoration);

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        final decoration = _renderedDecoration(tester, foreground);
        expect(decoration.boxShadow, hasLength(1));
        expect(decoration.boxShadow!.single.blurRadius, closeTo(12, 0.01));
        expect(decoration.boxShadow!.single.offset.dy, closeTo(4, 0.01));
      });

      testWidgets('$property still interpolates within the unit interval',
          (tester) async {
        await tester.pumpWidget(_container(
          foreground: foreground,
          decoration: _shadowDecoration,
        ));
        await tester.pumpWidget(_container(
          foreground: foreground,
          decoration: _emptyDecoration,
        ));
        final state = tester.state<PhysicsAnimatedWidgetState<AContainer>>(
          find.byType(AContainer),
        );
        final values = state.controller.value.toList();
        values[0] = 0.5;
        state.controller.value = values;
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          _renderedDecoration(tester, foreground),
          BoxDecoration.lerp(_shadowDecoration, _emptyDecoration, 0.5),
        );
      });
    }
  });
}

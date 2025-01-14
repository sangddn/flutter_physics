import 'package:flutter/rendering.dart' hide RenderAnimatedSizeState;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

class TestPaintingContext implements PaintingContext {
  final List<Invocation> invocations = <Invocation>[];
  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  group('ASize', () {
    testWidgets('animates with physics simulation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      RenderBox box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      // Change size to trigger animation
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();

      // Verify animation is in progress
      await tester.pump(const Duration(milliseconds: 16));
      box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, greaterThan(100.0));
      expect(box.size.width, lessThan(200.0));
      expect(box.size.height, greaterThan(100.0));
      expect(box.size.height, lessThan(200.0));

      // Verify clipping during animation
      TestPaintingContext context = TestPaintingContext();
      box.paint(context, Offset.zero);
      expect(context.invocations.first.memberName, equals(#pushClipRect));

      // Let animation settle
      await tester.pumpAndSettle();
      box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, closeTo(200.0, 0.01));
      expect(box.size.height, closeTo(200.0, 0.01));
    });

    testWidgets('calls onEnd when physics animation completes',
        (WidgetTester tester) async {
      int callCount = 0;
      void handleEnd() {
        callCount++;
      }

      await tester.pumpWidget(
        Center(
          child: ASize(
            onEnd: handleEnd,
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      expect(callCount, equals(0));

      await tester.pumpWidget(
        Center(
          child: ASize(
            onEnd: handleEnd,
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();

      expect(callCount, equals(0));
      await tester.pumpAndSettle();
      expect(callCount, equals(1));
    });

    testWidgets('clamps animated size to constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 100.0,
            height: 100.0,
            child: ASize(
              physics: Spring(
                description: SpringDescription(
                  mass: 1.0,
                  damping: 20.0,
                  stiffness: 500.0,
                ),
              ),
              child: const SizedBox(
                width: 100.0,
                height: 100.0,
              ),
            ),
          ),
        ),
      );

      RenderBox box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      // Attempt to animate beyond the outer SizedBox
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 100.0,
            height: 100.0,
            child: ASize(
              physics: Spring(
                description: SpringDescription(
                  mass: 1.0,
                  damping: 20.0,
                  stiffness: 500.0,
                ),
              ),
              child: const SizedBox(
                width: 200.0,
                height: 200.0,
              ),
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();

      // Verify size remains clamped
      await tester.pump(const Duration(milliseconds: 16));
      box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));
    });

    testWidgets('tracks unstable child size', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      RenderASize box = tester.renderObject(find.byType(ASize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      // Start child animation
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );

      // Let the child animation start
      await tester.pump();

      // Let the child animation progress
      await tester.pump(const Duration(milliseconds: 50));

      // Verify ASize is tracking the child's animation
      expect(box.size.width, greaterThan(100.0));
      expect(box.size.width, lessThan(200.0));

      // Let animations settle
      await tester.pumpAndSettle();
      expect(box.size.width, closeTo(200.0, 0.01));
      expect(box.size.height, closeTo(200.0, 0.01));
    });

    testWidgets('can set and update clipBehavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      final RenderASize renderObject = tester.renderObject(find.byType(ASize));
      expect(renderObject.clipBehavior, equals(Clip.hardEdge));

      for (final Clip clip in Clip.values) {
        await tester.pumpWidget(
          Center(
            child: ASize(
              physics: Spring(
                description: SpringDescription(
                  mass: 1.0,
                  damping: 20.0,
                  stiffness: 500.0,
                ),
              ),
              clipBehavior: clip,
              child: const SizedBox(
                width: 100.0,
                height: 100.0,
              ),
            ),
          ),
        );
        expect(renderObject.clipBehavior, clip);
      }
    });

    testWidgets('disposes physics controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      final RenderASize box = tester.renderObject(find.byType(ASize));
      await tester.pumpWidget(
        const Center(),
      );

      expect(() => box.dispose(), throwsAssertionError);
    });
  });
}

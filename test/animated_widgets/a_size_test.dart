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
            physics: Spring.elegant,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      var box = tester.renderObject<RenderASize>(find.byType(ASize));
      expect(box.size.width, equals(100.0));
      expect(box.size.height, equals(100.0));

      // Change size to trigger animation
      await tester.pumpWidget(
        Center(
          child: ASize(
            physics: Spring.elegant,
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
      await tester.pump(const Duration(milliseconds: 50));
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
            physics: Spring.elegant,
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
            physics: Spring.elegant,
            child: const SizedBox(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );
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
              physics: Spring.elegant,
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
              physics: Spring.elegant,
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

    testWidgets(
        'tracks unstable child, then resumes animation when child stabilizes',
        (WidgetTester tester) async {
      Future<void> pumpMillis(int millis) async {
        await tester.pump(Duration(milliseconds: millis));
      }

      void verify({double? size, RenderAnimatedSizeState? state}) {
        assert(size != null || state != null);
        final box = tester.renderObject<RenderASize>(find.byType(ASize));
        if (size != null) {
          expect(box.size.width, closeTo(size, 0.001));
          expect(box.size.height, closeTo(size, 0.001));
        }
        if (state != null) {
          expect(box.state, state);
        }
      }

      await tester.pumpWidget(
        Center(
          child: ASize(
            child: AContainer(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );
      verify(size: 100.0, state: RenderAnimatedSizeState.stable);
      // Animate child size from 100 to 200 slowly (100ms).
      await tester.pumpWidget(
        Center(
          child: ASize(
            child: AContainer(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      );
      // Make sure animation proceeds at child's pace, with AnimatedSize
      // tightly tracking the child's size.
      verify(state: RenderAnimatedSizeState.stable);
      await pumpMillis(1); // register change
      verify(state: RenderAnimatedSizeState.changed);
      await pumpMillis(139);
      verify(size: 150.3834, state: RenderAnimatedSizeState.unstable);
      await pumpMillis(200);
      verify(size: 194.1519, state: RenderAnimatedSizeState.unstable);
      // Stabilize size
      await tester.pumpAndSettle(Duration(seconds: 1));
      verify(size: 200.0, state: RenderAnimatedSizeState.stable);
      // Quickly (in 1ms) change size back to 100
      await tester.pumpWidget(
        Center(
          child: ASize(
            child: AContainer(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );
      verify(size: 200.0, state: RenderAnimatedSizeState.stable);
      await pumpMillis(1); // register change
      verify(state: RenderAnimatedSizeState.changed);
      await pumpMillis(100);
      verify(size: 166.231, state: RenderAnimatedSizeState.unstable);
      await tester.pumpAndSettle(Duration(seconds: 1));
      verify(size: 100.0, state: RenderAnimatedSizeState.stable);
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
              physics: Spring.elegant,
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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

void main() {
  group('ATranslate', () {
    testWidgets('animates with physics simulation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: Offset.zero,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Initial offset should be zero
      var transform = tester.widget<Transform>(find.byType(Transform));
      expect(transform.transform.getTranslation(),
          equals(vm.Vector3(0.0, 0.0, 0.0)));

      // Change offset to trigger animation
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(50.0, 30.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();

      // Verify animation is in progress
      await tester.pump(const Duration(milliseconds: 50));
      transform = tester.widget<Transform>(find.byType(Transform));
      var translation = transform.transform.getTranslation();
      expect(translation.x, greaterThan(0.0));
      expect(translation.x, lessThan(50.0));
      expect(translation.y, greaterThan(0.0));
      expect(translation.y, lessThan(30.0));

      // Let animation settle
      await tester.pumpAndSettle();
      transform = tester.widget<Transform>(find.byType(Transform));
      translation = transform.transform.getTranslation();
      expect(translation.x, closeTo(50.0, 0.01));
      expect(translation.y, closeTo(30.0, 0.01));
    });

    testWidgets('calls onEnd when physics animation completes',
        (WidgetTester tester) async {
      int callCount = 0;
      void handleEnd() {
        callCount++;
      }

      await tester.pumpWidget(
        Center(
          child: ATranslate(
            onEnd: handleEnd,
            physics: Spring.elegant,
            offset: Offset.zero,
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
          child: ATranslate(
            onEnd: handleEnd,
            physics: Spring.elegant,
            offset: const Offset(100.0, 50.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(callCount, equals(0));
      await tester.pumpAndSettle();
      expect(callCount, equals(1));
    });

    testWidgets('animates negative offsets correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: Offset.zero,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Animate to negative offset
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(-25.0, -15.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();

      // Verify animation is in progress with negative values
      await tester.pump(const Duration(milliseconds: 50));
      var transform = tester.widget<Transform>(find.byType(Transform));
      var translation = transform.transform.getTranslation();
      expect(translation.x, lessThan(0.0));
      expect(translation.x, greaterThan(-25.0));
      expect(translation.y, lessThan(0.0));
      expect(translation.y, greaterThan(-15.0));

      // Let animation settle
      await tester.pumpAndSettle();
      transform = tester.widget<Transform>(find.byType(Transform));
      translation = transform.transform.getTranslation();
      expect(translation.x, closeTo(-25.0, 0.01));
      expect(translation.y, closeTo(-15.0, 0.01));
    });

    testWidgets('respects transformHitTests property',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xff000000),
          builder: (context, child) => Center(
            child: ATranslate(
              // physics: Spring.elegant,
              offset: const Offset(50.0, 50.0),
              transformHitTests: true,
              child: GestureDetector(
                onTap: () => tapped = true,
                child: Container(
                  color: const Color(0xffffffff),
                  height: 50.0,
                  width: 50.0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // tapping at the center of the translated widget should trigger the tap
      await tester.tapAt(tester.getCenter(find.byType(Container)));
      expect(tapped, isTrue);
      tapped = false;
      // tapping at the center of the un-translated widget should not trigger the tap
      await tester.tapAt(tester.getCenter(find.byType(Center)));
      expect(tapped, isFalse);

      // Test with transformHitTests = false
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xff000000),
          builder: (context, child) => Center(
            child: ATranslate(
              physics: Spring.elegant,
              offset: const Offset(50.0, 50.0),
              transformHitTests: false,
              child: GestureDetector(
                onTap: () => tapped = true,
                child: Container(
                  color: const Color(0xffffffff),
                  height: 50.0,
                  width: 50.0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // tapping at the center of the un-translated widget should trigger the tap
      await tester.tapAt(tester.getCenter(find.byType(Center)));
      expect(tapped, isTrue);
      tapped = false;
      // tapping at the center of the translated widget should not trigger the tap
      await tester.tapAt(tester.getCenter(find.byType(Container)));
      expect(tapped, isFalse);
    });

    testWidgets('can animate large offsets', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: Offset.zero,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Animate to a large offset
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(1000.0, 500.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      var transform = tester.widget<Transform>(find.byType(Transform));
      var translation = transform.transform.getTranslation();
      expect(translation.x, closeTo(1000.0, 0.01));
      expect(translation.y, closeTo(500.0, 0.01));
    });

    testWidgets('disposes physics controller', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring(
              description: SpringDescription(
                mass: 1.0,
                damping: 20.0,
                stiffness: 500.0,
              ),
            ),
            offset: Offset.zero,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Remove the widget to trigger dispose
      await tester.pumpWidget(
        const Center(),
      );

      // Verify no exceptions are thrown during disposal
      expect(tester.takeException(), isNull);
    });

    testWidgets('can set and update filterQuality',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(10.0, 10.0),
            filterQuality: FilterQuality.low,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      var transform = tester.widget<Transform>(find.byType(Transform));
      expect(transform.filterQuality, equals(FilterQuality.low));

      // Update filter quality
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(10.0, 10.0),
            filterQuality: FilterQuality.high,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      transform = tester.widget<Transform>(find.byType(Transform));
      expect(transform.filterQuality, equals(FilterQuality.high));
    });

    testWidgets('animates from one offset to another smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(20.0, 10.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change to a different offset
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(80.0, 60.0),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify animation progresses smoothly from the first offset to the second
      await tester.pump(const Duration(milliseconds: 50));
      var transform = tester.widget<Transform>(find.byType(Transform));
      var translation = transform.transform.getTranslation();
      expect(translation.x, greaterThan(20.0));
      expect(translation.x, lessThan(80.0));
      expect(translation.y, greaterThan(10.0));
      expect(translation.y, lessThan(60.0));

      await tester.pumpAndSettle();
      transform = tester.widget<Transform>(find.byType(Transform));
      translation = transform.transform.getTranslation();
      expect(translation.x, closeTo(80.0, 0.01));
      expect(translation.y, closeTo(60.0, 0.01));
    });

    testWidgets('handles fractional offsets', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: Offset.zero,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      // Animate to fractional offset
      await tester.pumpWidget(
        Center(
          child: ATranslate(
            physics: Spring.elegant,
            offset: const Offset(12.5, 7.3),
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      var transform = tester.widget<Transform>(find.byType(Transform));
      var translation = transform.transform.getTranslation();
      expect(translation.x, closeTo(12.5, 0.01));
      expect(translation.y, closeTo(7.3, 0.01));
    });
  });
}

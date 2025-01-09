import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  late PhysicsController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    controller = PhysicsController.bounded(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 100),
    );
  });

  test('PhysicsController initial values', () {
    expect(controller.value, equals(0.0));
    expect(controller.isAnimating, isFalse);
    expect(controller.status, equals(AnimationStatus.dismissed));
  });

  group('Animation control', () {
    testWidgets('forward animation', (WidgetTester tester) async {
      controller.forward();

      expect(controller.status, equals(AnimationStatus.forward));
      expect(controller.isAnimating, isTrue);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.value, greaterThan(0.0));
      expect(controller.value, lessThan(1.0));

      await tester.pumpAndSettle();

      expect(controller.value, equals(1.0));
      expect(controller.status, equals(AnimationStatus.completed));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('reverse animation', (WidgetTester tester) async {
      controller.value = 1.0;
      await tester.pump();

      controller.reverse();

      expect(controller.status, equals(AnimationStatus.reverse));
      expect(controller.isAnimating, isTrue);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.value, lessThan(1.0));
      expect(controller.value, greaterThan(0.0));

      await tester.pumpAndSettle();

      expect(controller.value, equals(0.0));
      expect(controller.status, equals(AnimationStatus.dismissed));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('stop animation', (WidgetTester tester) async {
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final intermediateValue = controller.value;
      controller.stop();

      expect(controller.isAnimating, isFalse);
      expect(controller.value, equals(intermediateValue));
    });
  });

  group('Physics simulations', () {
    testWidgets('spring animation', (WidgetTester tester) async {
      final spring = Spring(
        description: SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 10.0,
        ),
        start: controller.value,
        end: 1.0,
      );

      controller.animateWith(spring);
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();

      expect(controller.value, closeTo(1.0, 0.01));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('fling animation', (WidgetTester tester) async {
      controller.fling(velocity: 1.0);
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();

      expect(controller.value, closeTo(1.0, 0.01));
      expect(controller.isAnimating, isFalse);
    });
  });

  testWidgets('repeat animation', (WidgetTester tester) async {
    controller.repeat(
      period: const Duration(milliseconds: 100),
      count: 2,
      reverse: true,
      min: 0.0,
      max: 1.0,
    );

    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle(Duration(milliseconds: 150));
    expect(controller.value, closeTo(1.0, 0.01));

    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.value, closeTo(1.0, 0.01));
    expect(controller.isAnimating, false);
  });

  test('dispose', () {
    final localController = PhysicsController.bounded(
      vsync: const TestVSync(),
    );
    localController.dispose();

    expect(() => localController.forward(), throwsAssertionError);
    expect(() => localController.dispose(), throwsFlutterError);
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

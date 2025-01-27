import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  late PhysicsController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    controller = PhysicsController(vsync: const TestVSync());
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

      expect(controller.value, closeTo(1.0, 0.0001));
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

      expect(controller.value, closeTo(0.0, 0.0001));
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

    testWidgets('animateBack with physics simulation',
        (WidgetTester tester) async {
      controller.value = 1.0;
      await tester.pump();

      controller.animateBack(0.0);

      expect(controller.status, equals(AnimationStatus.reverse));
      expect(controller.isAnimating, isTrue);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.value, lessThan(1.0));
      expect(controller.value, greaterThan(0.0));
      expect(controller.velocity, lessThan(0.0)); // Moving backwards

      await tester.pumpAndSettle();

      expect(controller.value, closeTo(0.0, 0.0001));
      expect(controller.status, equals(AnimationStatus.dismissed));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('animateBack with velocityDelta', (WidgetTester tester) async {
      controller.value = 1.0;
      await tester.pump();

      controller.animateBack(0.0, velocityDelta: -50.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(controller.velocity, lessThan(-40.0)); // Should be around -50
      expect(controller.status, equals(AnimationStatus.reverse));

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(0.0, 0.0001));
    });

    testWidgets('toggle from forward to reverse', (WidgetTester tester) async {
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final intermediateValue = controller.value;
      controller.toggle();

      expect(controller.status, equals(AnimationStatus.reverse));
      expect(controller.isAnimating, isTrue);
      expect(controller.value, equals(intermediateValue));

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(0.0, 0.0001));
      expect(controller.status, equals(AnimationStatus.dismissed));
    });

    testWidgets('toggle from reverse to forward', (WidgetTester tester) async {
      controller.value = 1.0;
      controller.reverse();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final intermediateValue = controller.value;
      controller.toggle();

      expect(controller.status, equals(AnimationStatus.forward));
      expect(controller.isAnimating, isTrue);
      expect(controller.value, equals(intermediateValue));

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(1.0, 0.0001));
      expect(controller.status, equals(AnimationStatus.completed));
    });

    testWidgets('toggle with from parameter', (WidgetTester tester) async {
      controller.toggle(from: 0.5);

      expect(controller.value, equals(0.5));
      expect(controller.status, equals(AnimationStatus.forward));
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(1.0, 0.0001));
      expect(controller.status, equals(AnimationStatus.completed));
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

    // testWidgets('fling animation', (WidgetTester tester) async {
    //   controller.fling(velocity: 1.0);
    //   expect(controller.isAnimating, isTrue);

    //   await tester.pumpAndSettle();

    //   expect(controller.value, closeTo(1.0, 0.01));
    //   expect(controller.isAnimating, isFalse);
    // });

    testWidgets('Mid-flight velocity is carried over when retargeting',
        (tester) async {
      controller.animateTo(0.75);
      await tester.pump(const Duration(milliseconds: 50));
      final midVelocity = controller.velocity;
      controller.animateTo(0.05);
      await tester.pump(Duration(milliseconds: 10));
      expect(controller.velocity, closeTo(midVelocity, 50.0));
      await tester.pumpAndSettle();
      expect(controller.value, closeTo(0.05, 0.001));
    });
  });

  group('Custom durations and boundary edge cases', () {
    testWidgets('animateTo partial completion with custom duration',
        (tester) async {
      final localController = PhysicsController(
        vsync: const TestVSync(),
      );

      // We'll animate to 0.8 in 200ms. At 100ms, expect ~0.4 +/- some tolerance.
      localController.animateTo(
        0.8,
        physics: Curves.linear,
        duration: const Duration(milliseconds: 200),
      );

      // Initially
      await tester.pump();
      expect(localController.value, closeTo(0.0, 0.0001));
      expect(localController.isAnimating, true);

      // At 100ms, about halfway to 0.8
      await tester.pump(const Duration(milliseconds: 100));
      expect(localController.value, closeTo(0.4, 0.05));

      // After 200ms, should be at or near 0.8
      await tester.pump(const Duration(milliseconds: 110));
      expect(localController.value, closeTo(0.8, 0.05));
      expect(localController.isAnimating, false);

      localController.dispose();
    });

    testWidgets('Edge case: stopping at exact boundary', (tester) async {
      final localController = PhysicsController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.0,
        upperBound: 1.0,
      );

      // Start at ~0.99, animate to 1.0
      localController.value = 0.99;
      localController.animateTo(1.0);

      // Pump a little
      await tester.pump(const Duration(milliseconds: 10));
      // Should be close to or exactly 1.0
      // Let it settle
      await tester.pumpAndSettle();

      expect(localController.value, closeTo(1.0, 0.0001));
      expect(localController.status, AnimationStatus.completed);
      expect(localController.isAnimating, false);

      // Now do the same near 0.0
      localController.reverse(from: 0.01);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpAndSettle();

      expect(localController.value, closeTo(0.0, 0.0001));
      expect(localController.status, AnimationStatus.dismissed);
      expect(localController.isAnimating, false);

      localController.dispose();
    });
  });

  testWidgets('velocityDelta adds to current velocity', (tester) async {
    controller.forward();
    await tester.pump(const Duration(milliseconds: 50));
    final oldVelocity = controller.velocity;
    controller.animateTo(1.0, velocityDelta: 50.0);
    await tester.pump(const Duration(milliseconds: 10));
    // Right after we call animateTo, we expect velocity to be oldVelocity + 50
    expect(controller.velocity, closeTo(oldVelocity + 50.0, 10.0));

    await tester.pumpAndSettle();
    expect(controller.value, closeTo(1.0, 0.0001));
  });

  testWidgets('velocityOverride replaces current velocity', (tester) async {
    controller.forward();
    await tester.pump(const Duration(milliseconds: 50));
    final oldVelocity = controller.velocity;
    controller.animateTo(1.0, velocityOverride: 50.0);
    // Right after we call animateTo, we expect velocity to be exactly 50,
    // regardless of oldVelocity
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.velocity, closeTo(50.0, 15.0));
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.velocity, isNot(closeTo(oldVelocity, 1e-1)));
    await tester.pumpAndSettle();
    expect(controller.value, closeTo(1.0, 0.0001));
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
    final localController = PhysicsController(
      vsync: const TestVSync(),
    );
    localController.dispose();

    expect(() => localController.forward(), throwsAssertionError);
    expect(() => localController.dispose(), throwsFlutterError);
  });

  group('defaultPhysics behavior', () {
    testWidgets('Mid-flight physics change preserves velocity', (tester) async {
      final springDesc = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      final initialSpring = Spring(
        description: springDesc,
        start: 0.0,
        end: 1.0,
      );

      final newSpring = Spring(
        description: SpringDescription(
          mass: 2.0,
          stiffness: 200.0,
          damping: 20.0,
        ),
      );

      controller.animateWith(initialSpring);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Capture mid-flight velocity
      final midVelocity = controller.velocity;
      expect(midVelocity, greaterThan(0));

      // Change physics mid-flight
      controller.defaultPhysics = newSpring;

      // Immediately after change, velocity should be preserved
      expect(controller.velocity, closeTo(midVelocity, 1.0));
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(1.0, 0.01));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets(
        'Changing to non-physics simulation does not affect current animation',
        (tester) async {
      final spring = Spring(
        description: SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 10.0,
        ),
      );

      controller.animateWith(spring);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midValue = controller.value;
      final midVelocity = controller.velocity;

      // Change to a non-physics simulation
      controller.defaultPhysics = Curves.easeInOut;

      // Animation should continue unchanged
      expect(controller.value, equals(midValue));
      expect(controller.velocity, equals(midVelocity));
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();
      expect(controller.value, closeTo(1.0, 0.01));
    });

    test('Setting same physics instance does not restart animation', () {
      final spring = Spring.elegant;
      controller.defaultPhysics = spring;
      controller.animateWith(spring);

      // Setting same instance should not affect animation
      controller.defaultPhysics = spring;
      expect(controller.isAnimating, isTrue);
    });
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

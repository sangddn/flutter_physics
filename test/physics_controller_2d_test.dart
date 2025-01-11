import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

import 'matchers/offset_matcher.dart';

void main() {
  late PhysicsController2D controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    controller = PhysicsController2D(
      vsync: const TestVSync(),
      lowerBound: const Offset(-10000, -10000),
      upperBound: const Offset(10000, 10000),
    );
  });

  test('initial state is correct', () {
    expect(controller.value, Offset.zero);
    expect(controller.velocity, Offset.zero);
    expect(controller.isAnimating, false);
    expect(controller.status, AnimationStatus.forward);
  });

  test('setting value updates state correctly', () {
    const newValue = Offset(10, 20);
    controller.value = newValue;

    expect(controller.value, newValue);
    expect(controller.velocity, Offset.zero);
    expect(controller.isAnimating, false);
  });

  testWidgets('animateTo creates animation', (WidgetTester tester) async {
    const target = Offset(100, 100);

    controller.animateTo(
      target,
      physics: Simulation2D(
        Spring.snap,
        Spring.elegant,
      ),
    );

    expect(controller.isAnimating, true);
    expect(controller.status, AnimationStatus.forward);

    await tester.pumpAndSettle();

    expect(controller.value.dx, closeTo(100.0, 0.001));
    expect(controller.value.dy, closeTo(100.0, 0.001));
    expect(controller.isAnimating, false);
    expect(controller.status, AnimationStatus.completed);
  });

  testWidgets('animateTo with regular curves', (WidgetTester tester) async {
    final boundedController = PhysicsController2D(
      vsync: const TestVSync(),
      lowerBound: const Offset(-100, -100),
      upperBound: const Offset(100, 100),
      defaultPhysics: Simulation2D(Curves.ease, Curves.linear),
      duration: const Duration(milliseconds: 300),
    );

    boundedController.animateTo(const Offset(1000, 1000));

    expect(boundedController.isAnimating, true);

    await tester.pumpAndSettle();

    expect(boundedController.value.dx, lessThanOrEqualTo(100));
    expect(boundedController.value.dy, lessThanOrEqualTo(100));
    expect(boundedController.isAnimating, false);

    boundedController.dispose();
  });

  testWidgets('repeat animation works correctly', (WidgetTester tester) async {
    int forwardCount = 0;
    int reverseCount = 0;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) forwardCount++;
      if (status == AnimationStatus.reverse) reverseCount++;
    });

    controller.repeat(
      min: const Offset(0, 0),
      max: const Offset(10, 10),
      reverse: true,
      count: 2,
    );

    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(forwardCount, greaterThan(0));
    expect(reverseCount, greaterThan(0));
    expect(controller.isAnimating, false);
  });

  test('stop ends animation', () async {
    controller.animateTo(
      const Offset(100, 100),
      physics: Simulation2D(
        Spring(
            description:
                SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)),
        Spring(
            description:
                SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)),
      ),
    );

    expect(controller.isAnimating, true);

    controller.stop();

    expect(controller.isAnimating, false);
    expect(controller.velocity, Offset.zero);
  });

  test('reset returns to lowerBound', () {
    controller.value = const Offset(50, 50);
    controller.reset();

    expect(controller.value, controller.lowerBound);
    expect(controller.status, AnimationStatus.dismissed);
  });

  testWidgets('custom simulation works', (tester) async {
    final springDesc = SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 10.0,
    );

    final customSimulation = Simulation2D(
      Spring(
        description: springDesc,
        start: 0.0,
        end: 100.0,
        tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
      ),
      Spring(
        description: springDesc,
        start: 0.0,
        end: 100.0,
        tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
      ),
    );

    controller.animateWith(customSimulation);

    expect(controller.isAnimating, true);

    await tester.pumpAndSettle();

    expect(controller.value.dx, closeTo(100.0, 0.1));
    expect(controller.value.dy, closeTo(100.0, 0.1));
    expect(controller.isAnimating, false);
  });

  group('2D velocity continuity & clamping', () {
    testWidgets('Mid-flight retarget in 2D preserves velocity', (tester) async {
      final localController = PhysicsController2D(
        vsync: const TestVSync(),
        lowerBound: Offset.zero,
        upperBound: const Offset(2.0, 2.0),
        defaultPhysics: Simulation2D(Spring.elegant, Spring.elegant),
      );

      // Animate from (0,0) -> (1,1)
      localController.animateTo(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 100));

      // Capture mid-flight velocity
      final midVelocity = localController.velocity;
      expect(midVelocity.distance, greaterThan(0));

      // Retarget to (2,2) mid-flight - should keep velocity from earlier
      localController.animateTo(const Offset(2, 2));
      // Immediately after retarget, velocity shouldn't reset to zero
      expect(localController.velocity.distance,
          closeTo(midVelocity.distance, 1.5));

      // Let it settle
      await tester.pumpAndSettle();
      expect(localController.value, matchesOffset(const Offset(2.0, 2.0)));
      expect(localController.isAnimating, false);
      localController.dispose();
    });

    testWidgets('Clamping at upperBound in 2D', (tester) async {
      final localController = PhysicsController2D(
        vsync: const TestVSync(),
        lowerBound: Offset.zero,
        upperBound: const Offset(100.0, 100.0),
        defaultPhysics: Simulation2D(Curves.easeIn, Curves.easeOut),
      );

      // Animate to a target well outside upperBound
      localController.animateTo(
        const Offset(999, 999),
        duration: Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      // Should clamp at (100,100)
      expect(localController.value, const Offset(100.0, 100.0));
      expect(localController.isAnimating, false);

      localController.dispose();
    });
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  late PhysicsControllerMulti controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    controller = PhysicsControllerMulti(
      dimensions: 3,
      vsync: const TestVSync(),
      lowerBound: [-10000, -10000, -10000],
      upperBound: [10000, 10000, 10000],
    );
  });

  test('initial state is correct', () {
    expect(controller.value, [0.0, 0.0, 0.0]);
    expect(controller.velocity, [0.0, 0.0, 0.0]);
    expect(controller.isAnimating, false);
    expect(controller.status, AnimationStatus.forward);
  });

  test('setting value updates state correctly', () {
    final newValue = [10.0, 20.0, 30.0];
    controller.value = newValue;

    expect(controller.value, newValue);
    expect(controller.velocity, [0.0, 0.0, 0.0]);
    expect(controller.isAnimating, false);
  });

  testWidgets('animateTo creates animation', (WidgetTester tester) async {
    final target = [100.0, 100.0, 100.0];

    controller.animateTo(
      target,
      physics: [Spring.snap, Spring.elegant, Spring.elegant],
    );

    expect(controller.isAnimating, true);
    expect(controller.status, AnimationStatus.forward);

    await tester.pumpAndSettle();

    expect(controller.value[0], closeTo(100.0, 0.001));
    expect(controller.value[1], closeTo(100.0, 0.001));
    expect(controller.value[2], closeTo(100.0, 0.001));
    expect(controller.isAnimating, false);
    expect(controller.status, AnimationStatus.completed);
  });

  testWidgets('animateTo with regular curves', (WidgetTester tester) async {
    final boundedController = PhysicsControllerMulti(
      dimensions: 3,
      vsync: const TestVSync(),
      lowerBound: [-100, -100, -100],
      upperBound: [100, 100, 100],
      defaultPhysics: [Curves.ease, Curves.linear, Curves.bounceOut],
      duration: const Duration(milliseconds: 300),
    );

    boundedController.animateTo([1000.0, 1000.0, 1000.0]);

    expect(boundedController.isAnimating, true);

    await tester.pumpAndSettle();

    expect(boundedController.value[0], lessThanOrEqualTo(100));
    expect(boundedController.value[1], lessThanOrEqualTo(100));
    expect(boundedController.value[2], lessThanOrEqualTo(100));
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
      min: [0, 0, 0],
      max: [10, 10, 10],
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
      [100.0, 100.0, 100.0],
      physics: [
        Spring(
            description:
                SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)),
        Spring(
            description:
                SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)),
        Spring(
            description:
                SpringDescription(mass: 1.0, stiffness: 100.0, damping: 10.0)),
      ],
    );

    expect(controller.isAnimating, true);

    controller.stop();

    expect(controller.isAnimating, false);
    expect(controller.velocity, [0.0, 0.0, 0.0]);
  });

  test('reset returns to lowerBound', () {
    controller.value = [50.0, 50.0, 50.0];
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

    final springs = List.generate(
        3,
        (i) => Spring(
              description: springDesc,
              start: 0.0,
              end: 100.0,
              tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
            ));

    controller.animateTo([100.0, 100.0, 100.0], physics: springs);

    expect(controller.isAnimating, true);

    await tester.pumpAndSettle();

    for (int i = 0; i < 3; i++) {
      expect(controller.value[i], closeTo(100.0, 0.1));
    }
    expect(controller.isAnimating, false);
  });

  group('Multi-dimensional velocity continuity & clamping', () {
    testWidgets('Mid-flight retarget preserves velocity', (tester) async {
      final localController = PhysicsControllerMulti(
        dimensions: 3,
        vsync: const TestVSync(),
        lowerBound: [0.0, 0.0, 0.0],
        upperBound: [2.0, 2.0, 2.0],
        defaultPhysics: List.generate(3, (i) => Spring.elegant),
      );

      // Animate from [0,0,0] -> [1,1,1]
      localController.animateTo([1.0, 1.0, 1.0]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Capture mid-flight velocity
      final midVelocity = localController.velocity;
      expect(midVelocity.any((v) => v != 0), isTrue);

      // Retarget to [2,2,2] mid-flight - should keep velocity from earlier
      localController.animateTo([2.0, 2.0, 2.0]);
      await tester.pump();

      // Immediately after retarget, velocity shouldn't reset to zero
      for (int i = 0; i < 3; i++) {
        expect(localController.velocity[i].abs(), greaterThan(0.0));
      }

      // Let it settle
      await tester.pumpAndSettle();
      expect(localController.value, [2.0, 2.0, 2.0]);
      expect(localController.isAnimating, false);
      localController.dispose();
    });

    testWidgets('Clamping at upperBound', (tester) async {
      final localController = PhysicsControllerMulti(
        dimensions: 3,
        vsync: const TestVSync(),
        lowerBound: [0.0, 0.0, 0.0],
        upperBound: [100.0, 100.0, 100.0],
        defaultPhysics: List.generate(3, (i) => Spring.elegant),
      );

      // Animate to a target well outside upperBound
      localController.animateTo([999.0, 999.0, 999.0]);
      await tester.pump();
      await tester.pumpAndSettle();

      // Should clamp at [100,100,100]
      expect(localController.value, [100.0, 100.0, 100.0]);
      expect(localController.isAnimating, false);

      localController.dispose();
    });
  });

  group('defaultPhysics behavior', () {
    testWidgets('Mid-flight physics change preserves velocity', (tester) async {
      final springDesc = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      final initialSprings = List.generate(
          3,
          (i) => Spring(
                description: springDesc,
                start: 0.0,
                end: 1.0,
              ));

      final newSprings = List.generate(
          3,
          (i) => Spring(
                description: SpringDescription(
                  mass: 2.0,
                  stiffness: 200.0,
                  damping: 20.0,
                ),
              ));

      controller.animateTo([1.0, 1.0, 1.0], physics: initialSprings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Capture mid-flight velocity
      final midVelocity = controller.velocity;
      expect(midVelocity.any((v) => v != 0), isTrue);

      // Change physics mid-flight
      controller.defaultPhysics = newSprings;
      await tester.pump();

      // Immediately after change, velocity should be preserved
      for (int i = 0; i < 3; i++) {
        expect(controller.velocity[i].abs(), greaterThan(0.0));
      }
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        expect(controller.value[i], closeTo(1.0, 0.01));
      }
      expect(controller.isAnimating, isFalse);
    });

    testWidgets(
        'Changing to non-physics simulation does not affect current animation',
        (tester) async {
      final springs = List.generate(
          3,
          (i) => Spring(
                description: SpringDescription(
                  mass: 1.0,
                  stiffness: 100.0,
                  damping: 10.0,
                ),
              ));

      controller.animateTo([1.0, 1.0, 1.0], physics: springs);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midValue = controller.value;
      final midVelocity = controller.velocity;

      // Change to a non-physics simulation
      controller.defaultPhysics = List.generate(3, (i) => Curves.easeInOut);

      // Animation should continue unchanged
      expect(controller.value, midValue);
      expect(controller.velocity, midVelocity);
      expect(controller.isAnimating, isTrue);

      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        expect(controller.value[i], closeTo(1.0, 0.01));
      }
    });

    test('Setting same physics instance does not restart animation', () {
      final springs = List.generate(3, (i) => Spring.elegant);
      controller.defaultPhysics = springs;
      controller.animateTo([1.0, 1.0, 1.0], physics: springs);

      // Setting same instance should not affect animation
      controller.defaultPhysics = springs;
      expect(controller.isAnimating, isTrue);
    });
  });

  test('dimension() returns correct single-dimension animation', () {
    controller.value = [1.0, 2.0, 3.0];

    final dim0 = controller.dimension(0);
    final dim1 = controller.dimension(1);
    final dim2 = controller.dimension(2);

    expect(dim0.value, 1.0);
    expect(dim1.value, 2.0);
    expect(dim2.value, 3.0);

    expect(() => controller.dimension(-1), throwsAssertionError);
    expect(() => controller.dimension(3), throwsAssertionError);
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  late PhysicsController2D controller2D;
  late PhysicsControllerMulti controllerMulti;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create both controllers with identical settings
    controller2D = PhysicsController2D(
      vsync: const TestVSync(),
      lowerBound: const Offset(-10000, -10000),
      upperBound: const Offset(10000, 10000),
      defaultPhysics: Simulation2D(Spring.elegant, Spring.elegant),
    );

    controllerMulti = PhysicsControllerMulti(
      dimensions: 2,
      vsync: const TestVSync(),
      lowerBound: [-10000, -10000],
      upperBound: [10000, 10000],
      defaultPhysics: [Spring.elegant, Spring.elegant],
    );
  });

  tearDown(() {
    controller2D.dispose();
    controllerMulti.dispose();
  });

  test('initial state is identical', () {
    expect(controller2D.value.dx, controllerMulti.value[0]);
    expect(controller2D.value.dy, controllerMulti.value[1]);
    expect(controller2D.velocity.dx, controllerMulti.velocity[0]);
    expect(controller2D.velocity.dy, controllerMulti.velocity[1]);
    expect(controller2D.isAnimating, controllerMulti.isAnimating);
    expect(controller2D.status, controllerMulti.status);
  });

  test('setting value behaves identically', () {
    const offset = Offset(50, 75);
    final list = [50.0, 75.0];

    controller2D.value = offset;
    controllerMulti.value = list;

    expect(controller2D.value.dx, controllerMulti.value[0]);
    expect(controller2D.value.dy, controllerMulti.value[1]);
    expect(controller2D.status, controllerMulti.status);
  });

  testWidgets('animateTo with physics behaves identically', (tester) async {
    const target2D = Offset(100, 200);
    final targetMulti = [100.0, 200.0];

    // Start both animations
    controller2D.animateTo(target2D);
    controllerMulti.animateTo(targetMulti);

    // Check initial state
    expect(controller2D.isAnimating, controllerMulti.isAnimating);
    expect(controller2D.status, controllerMulti.status);

    // Check mid-animation state
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller2D.value.dx, closeTo(controllerMulti.value[0], 0.001));
    expect(controller2D.value.dy, closeTo(controllerMulti.value[1], 0.001));
    expect(
        controller2D.velocity.dx, closeTo(controllerMulti.velocity[0], 0.001));
    expect(
        controller2D.velocity.dy, closeTo(controllerMulti.velocity[1], 0.001));

    // Let animations complete
    await tester.pumpAndSettle();

    expect(controller2D.value.dx, controllerMulti.value[0]);
    expect(controller2D.value.dy, controllerMulti.value[1]);
    expect(controller2D.isAnimating, controllerMulti.isAnimating);
    expect(controller2D.status, controllerMulti.status);
  });

  testWidgets('animateTo with curves behaves identically', (tester) async {
    final bounded2D = PhysicsController2D(
      vsync: const TestVSync(),
      lowerBound: const Offset(-100, -100),
      upperBound: const Offset(100, 100),
      defaultPhysics: Simulation2D(Curves.easeInOut, Curves.easeInOut),
      duration: const Duration(milliseconds: 300),
    );

    final boundedMulti = PhysicsControllerMulti(
      dimensions: 2,
      vsync: const TestVSync(),
      lowerBound: [-100, -100],
      upperBound: [100, 100],
      defaultPhysics: [Curves.easeInOut, Curves.easeInOut],
      duration: const Duration(milliseconds: 300),
    );

    // Animate beyond bounds
    bounded2D.animateTo(const Offset(1000, 1000));
    boundedMulti.animateTo([1000.0, 1000.0]);

    // Check mid-animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(bounded2D.value.dx, closeTo(boundedMulti.value[0], 0.001));
    expect(bounded2D.value.dy, closeTo(boundedMulti.value[1], 0.001));
    expect(bounded2D.velocity.dx, closeTo(boundedMulti.velocity[0], 0.001));
    expect(bounded2D.velocity.dy, closeTo(boundedMulti.velocity[1], 0.001));

    // Let animations complete
    await tester.pumpAndSettle();

    expect(bounded2D.value.dx, boundedMulti.value[0]);
    expect(bounded2D.value.dy, boundedMulti.value[1]);
    expect(bounded2D.isAnimating, boundedMulti.isAnimating);
    expect(bounded2D.status, boundedMulti.status);

    bounded2D.dispose();
    boundedMulti.dispose();
  });

  testWidgets('repeat behaves identically', (tester) async {
    int forward2D = 0, reverse2D = 0;
    int forwardMulti = 0, reverseMulti = 0;

    controller2D.addStatusListener((status) {
      if (status == AnimationStatus.forward) forward2D++;
      if (status == AnimationStatus.reverse) reverse2D++;
    });

    controllerMulti.addStatusListener((status) {
      if (status == AnimationStatus.forward) forwardMulti++;
      if (status == AnimationStatus.reverse) reverseMulti++;
    });

    controller2D.repeat(
      min: const Offset(0, 0),
      max: const Offset(10, 10),
      reverse: true,
      count: 2,
    );

    controllerMulti.repeat(
      min: [0, 0],
      max: [10, 10],
      reverse: true,
      count: 2,
    );

    // Check at various intervals
    for (int i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller2D.value.dx, closeTo(controllerMulti.value[0], 0.001));
      expect(controller2D.value.dy, closeTo(controllerMulti.value[1], 0.001));
      expect(controller2D.velocity.dx,
          closeTo(controllerMulti.velocity[0], 0.001));
      expect(controller2D.velocity.dy,
          closeTo(controllerMulti.velocity[1], 0.001));
    }

    await tester.pumpAndSettle();

    expect(forward2D, forwardMulti);
    expect(reverse2D, reverseMulti);
    expect(controller2D.isAnimating, controllerMulti.isAnimating);
  });

  testWidgets('mid-flight retargeting behaves identically', (tester) async {
    // Start initial animation
    controller2D.animateTo(const Offset(100, 100));
    controllerMulti.animateTo([100.0, 100.0]);

    // Let it run for a bit
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Capture velocities
    final velocity2D = controller2D.velocity;
    final velocityMulti = controllerMulti.velocity;

    // Verify velocities match
    expect(velocity2D.dx, closeTo(velocityMulti[0], 0.001));
    expect(velocity2D.dy, closeTo(velocityMulti[1], 0.001));

    // Retarget mid-flight
    controller2D.animateTo(const Offset(50, 50));
    controllerMulti.animateTo([50.0, 50.0]);

    // Check immediate post-retarget state
    expect(
        controller2D.velocity.dx, closeTo(controllerMulti.velocity[0], 0.001));
    expect(
        controller2D.velocity.dy, closeTo(controllerMulti.velocity[1], 0.001));

    // Let animations complete
    await tester.pumpAndSettle();

    expect(controller2D.value.dx, controllerMulti.value[0]);
    expect(controller2D.value.dy, controllerMulti.value[1]);
    expect(controller2D.isAnimating, controllerMulti.isAnimating);
  });

  testWidgets('stop and reset behave identically', (tester) async {
    // Start animations
    controller2D.animateTo(const Offset(100, 100));
    controllerMulti.animateTo([100.0, 100.0]);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Stop both
    final velocity2D = controller2D.stop();
    final velocityMulti = controllerMulti.stop();

    expect(velocity2D.dx, closeTo(velocityMulti[0], 0.001));
    expect(velocity2D.dy, closeTo(velocityMulti[1], 0.001));
    expect(controller2D.isAnimating, controllerMulti.isAnimating);

    // Reset both
    controller2D.reset();
    controllerMulti.reset();

    expect(controller2D.value,
        Offset(controller2D.lowerBound.dx, controller2D.lowerBound.dy));
    expect(controllerMulti.value, controllerMulti.lowerBound);
    expect(controller2D.status, controllerMulti.status);
  });
}

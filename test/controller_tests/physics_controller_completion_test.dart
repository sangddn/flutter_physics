import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter_test/flutter_test.dart';

final _spring = Spring(
  description: const SpringDescription(mass: 1, stiffness: 100, damping: 20),
);

void main() {
  group('Exact controller completion', () {
    testWidgets('scalar completion listeners observe the exact target',
        (tester) async {
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: _spring);
      addTearDown(controller.dispose);
      final completedValues = <double>[];
      final terminalListenerValues = <double>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value);
        }
      });
      controller.addListener(() {
        if (!controller.isAnimating) {
          terminalListenerValues.add(controller.value);
        }
      });

      controller.animateTo(0.7);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(completedValues, [0.7]);
      expect(terminalListenerValues, [0.7]);
      expect(controller.value, 0.7);
    });

    testWidgets('2D completion listeners observe both exact coordinates',
        (tester) async {
      final controller = PhysicsController2D(
        vsync: tester,
        defaultPhysics: Simulation2D(_spring, _spring),
      );
      addTearDown(controller.dispose);
      final completedValues = <Offset>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value);
        }
      });
      const target = Offset(0.25, 0.7);

      controller.animateTo(target);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(completedValues, [target]);
      expect(controller.value, target);
    });

    testWidgets('multi completion listeners observe every exact coordinate',
        (tester) async {
      final controller = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 3,
        defaultPhysicsForAllDimensions: _spring,
      );
      addTearDown(controller.dispose);
      final completedValues = <List<double>>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value.toList());
        }
      });
      const target = [0.25, 0.7, 0.4];

      controller.animateTo(target);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(completedValues, [target]);
      expect(controller.value, target);
    });

    testWidgets('scalar forward, reverse, and animateBack finish exactly',
        (tester) async {
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: _spring);
      addTearDown(controller.dispose);
      final finishedValues = <double>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          finishedValues.add(controller.value);
        }
      });

      controller.forward();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, 1.0);
      controller.reverse();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, 0.0);
      controller.value = 0.8;
      controller.animateBack(0.3);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, 0.3);
      expect(finishedValues, [1.0, 0.0, 0.3]);
    });

    testWidgets('retargeting completes only the new scalar target',
        (tester) async {
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: _spring);
      addTearDown(controller.dispose);
      final completedValues = <double>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value);
        }
      });
      final firstRun = controller.animateTo(0.9);
      final canceled =
          expectLater(firstRun.orCancel, throwsA(isA<TickerCanceled>()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      expect(controller.value, inExclusiveRange(0.0, 0.9));

      controller.animateTo(0.35);
      await canceled;
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(controller.value, 0.35);
      expect(completedValues, [0.35]);
    });

    testWidgets('2D retargeting preserves an unchanged coordinate exactly',
        (tester) async {
      final controller = PhysicsController2D(
        vsync: tester,
        value: const Offset(0.25, 0),
        defaultPhysics: Simulation2D(_spring, _spring),
      );
      addTearDown(controller.dispose);
      controller.animateTo(const Offset(0.25, 0.9));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      expect(controller.value.dx, 0.25);
      controller.animateTo(const Offset(0.25, 0.4));

      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, const Offset(0.25, 0.4));
      controller.forward();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, const Offset(1, 1));
      controller.reverse();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, Offset.zero);
    });

    testWidgets(
        'multi retargeting snapshots mutable targets and fixed dimensions',
        (tester) async {
      final controller = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 3,
        value: [0.25, 0, 0.5],
        defaultPhysicsForAllDimensions: _spring,
      );
      addTearDown(controller.dispose);
      controller.animateTo([0.25, 0.9, 0.5]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final target = [0.25, 0.4, 0.5];
      controller.animateTo(target);
      target[1] = 0.8;

      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, [0.25, 0.4, 0.5]);
      expect(controller.dimension(1).value, 0.4);
      controller.forward();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, [1.0, 1.0, 1.0]);
      controller.reverse();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, [0.0, 0.0, 0.0]);
    });

    testWidgets('updating physics mid-flight retains the requested targets',
        (tester) async {
      final scalar = PhysicsController(vsync: tester, defaultPhysics: _spring);
      final twoD = PhysicsController2D(
        vsync: tester,
        defaultPhysics: Simulation2D(_spring, _spring),
      );
      final multi = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 3,
        defaultPhysicsForAllDimensions: _spring,
      );
      addTearDown(scalar.dispose);
      addTearDown(twoD.dispose);
      addTearDown(multi.dispose);
      scalar.animateTo(0.7);
      twoD.animateTo(const Offset(0.25, 0.7));
      multi.animateTo([0.25, 0.7, 0.4]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));

      scalar.defaultPhysics = Spring.swift;
      twoD.defaultPhysics = Simulation2D(Spring.swift, Spring.swift);
      multi.defaultPhysics = [Spring.swift, Spring.swift, Spring.swift];
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(scalar.value, 0.7);
      expect(twoD.value, const Offset(0.25, 0.7));
      expect(multi.value, [0.25, 0.7, 0.4]);
    });

    testWidgets(
        'zero-duration retargets stop previous runs at the exact target',
        (tester) async {
      final scalar = PhysicsController(vsync: tester, defaultPhysics: _spring);
      final twoD = PhysicsController2D(
        vsync: tester,
        defaultPhysics: Simulation2D(_spring, _spring),
      );
      final multi = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 2,
        defaultPhysicsForAllDimensions: _spring,
      );
      addTearDown(scalar.dispose);
      addTearDown(twoD.dispose);
      addTearDown(multi.dispose);
      scalar.animateTo(0.9);
      twoD.animateTo(const Offset(0.9, 0.9));
      multi.animateTo([0.9, 0.9]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));

      scalar.animateTo(0.3, duration: Duration.zero);
      twoD.animateTo(const Offset(0.3, 0.4), duration: Duration.zero);
      multi.animateTo([0.3, 0.4], duration: Duration.zero);
      expect(scalar.isAnimating, isFalse);
      expect(twoD.isAnimating, isFalse);
      expect(multi.isAnimating, isFalse);

      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(scalar.value, 0.3);
      expect(twoD.value, const Offset(0.3, 0.4));
      expect(multi.value, [0.3, 0.4]);
    });

    testWidgets(
        'generic simulations preserve their samples after targeted runs',
        (tester) async {
      final scalar = PhysicsController(vsync: tester, defaultPhysics: _spring);
      final multi = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 2,
        defaultPhysicsForAllDimensions: _spring,
      );
      addTearDown(scalar.dispose);
      addTearDown(multi.dispose);
      scalar.animateTo(0.9);
      multi.animateTo([0.9, 0.9]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));

      scalar.animateWith(_FiniteSimulation(0.4));
      multi.animateWith([_FiniteSimulation(0.4), _FiniteSimulation(0.6)]);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(scalar.value, 0.4);
      expect(multi.value, [0.4, 0.6]);

      scalar.animateTo(0.9);
      await tester.pump(const Duration(milliseconds: 16));
      scalar.animateBackWith(_FiniteSimulation(0.3));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(scalar.value, 0.3);
      expect(scalar.status, AnimationStatus.dismissed);
    });

    testWidgets('2D animateWith preserves clamped simulation endpoints',
        (tester) async {
      final controller = PhysicsController2D(
        vsync: tester,
        defaultPhysics: Simulation2D(_spring, _spring),
      );
      addTearDown(controller.dispose);
      controller.animateTo(const Offset(0.9, 0.9));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final x = ClampedPhysicsSimulation(_spring.copyWith(end: 0.6), xMax: 0.4);
      final y = ClampedPhysicsSimulation(_spring.copyWith(end: 0.7), xMax: 0.3);

      controller.animateWith(Simulation2D(x, y));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(controller.value, const Offset(0.4, 0.3));
    });

    testWidgets('explicit targets honor nested simulation clamps at completion',
        (tester) async {
      final clamped = ClampedPhysicsSimulation(
        ClampedPhysicsSimulation(_spring, xMin: 0.25, xMax: 0.4),
        xMin: 0.2,
        xMax: 0.5,
      );
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: clamped);
      addTearDown(controller.dispose);

      controller.animateTo(0.9);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, 0.4);

      controller.animateTo(0.1);
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      expect(controller.value, 0.25);
    });

    testWidgets('retuning a clamped run retains its original requested target',
        (tester) async {
      final controller = PhysicsController(
        vsync: tester,
        defaultPhysics: ClampedPhysicsSimulation(_spring, xMax: 0.4),
      );
      addTearDown(controller.dispose);
      controller.animateTo(0.7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));

      controller.defaultPhysics = _spring;
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(controller.value, 0.7);
    });

    testWidgets(
        'zero-duration targets apply simulation clamps to existing values',
        (tester) async {
      final clamped = ClampedPhysicsSimulation(_spring, xMax: 0.4);
      final scalar = PhysicsController(
        vsync: tester,
        value: 0.9,
        defaultPhysics: clamped,
      );
      final twoD = PhysicsController2D(
        vsync: tester,
        value: const Offset(0.9, 0.9),
        defaultPhysics: Simulation2D(clamped, clamped),
      );
      final multi = PhysicsControllerMulti(
        vsync: tester,
        dimensions: 2,
        value: [0.9, 0.9],
        defaultPhysicsForAllDimensions: clamped,
      );
      addTearDown(scalar.dispose);
      addTearDown(twoD.dispose);
      addTearDown(multi.dispose);

      // Even when the requested target equals the current value, the effective
      // endpoint changes because the simulation imposes a tighter bound.
      scalar.animateTo(0.9, duration: Duration.zero);
      twoD.animateTo(const Offset(0.9, 0.9), duration: Duration.zero);
      multi.animateTo([0.9, 0.9], duration: Duration.zero);

      expect(scalar.value, 0.4);
      expect(twoD.value, const Offset(0.4, 0.4));
      expect(multi.value, [0.4, 0.4]);
      expect(scalar.isAnimating, isFalse);
      expect(twoD.isAnimating, isFalse);
      expect(multi.isAnimating, isFalse);
    });

    testWidgets('stopping a targeted run preserves its current value',
        (tester) async {
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: _spring);
      addTearDown(controller.dispose);
      final completedValues = <double>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value);
        }
      });
      final future = controller.animateTo(0.7);
      final canceled =
          expectLater(future.orCancel, throwsA(isA<TickerCanceled>()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      final stoppedValue = controller.value;
      expect(stoppedValue, inExclusiveRange(0.0, 0.7));

      controller.stop();
      await canceled;
      await tester.pumpAndSettle();
      expect(controller.value, stoppedValue);
      expect(completedValues, isEmpty);

      controller.value = 0.2;
      controller.animateWith(_FiniteSimulation(0.4));
      await tester.pumpAndSettle();
      expect(controller.value, 0.4);
    });

    testWidgets(
        'disposal cancels targeted completion without notifying listeners',
        (tester) async {
      final controller =
          PhysicsController(vsync: tester, defaultPhysics: _spring);
      final completedValues = <double>[];
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          completedValues.add(controller.value);
        }
      });
      final future = controller.animateTo(0.7);
      final canceled =
          expectLater(future.orCancel, throwsA(isA<TickerCanceled>()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));

      controller.dispose();
      await canceled;
      await tester.pumpAndSettle();
      expect(completedValues, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FiniteSimulation extends Simulation {
  _FiniteSimulation(this.terminalValue);

  final double terminalValue;

  @override
  double x(double time) => terminalValue * (time / 0.05).clamp(0.0, 1.0);

  @override
  double dx(double time) => isDone(time) ? 0.0 : terminalValue / 0.05;

  @override
  bool isDone(double time) => time >= 0.05;
}

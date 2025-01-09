import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  group('Spring simulation', () {
    test('initial values are correct', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 1.0,
      );

      expect(spring.x(0.0), equals(0.0));
      expect(spring.dx(0.0), equals(0.0));
      expect(spring.isDone(0.0), isFalse);
    });

    test('reaches target with default parameters', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 1.0,
      );

      // Check position at various times
      expect(spring.x(0.0), equals(0.0));
      expect(spring.x(spring.duration), closeTo(1.0, 0.01));
    });

    test('handles different spring configurations', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 1.0,
        tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
      );

      expect(spring.x(0.0), equals(0.0));
      expect(spring.x(spring.duration), closeTo(1.0, 0.01));
    });

    test('respects initial velocity', () {
      final spring = Spring(
        description: SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 10.0,
        ),
        start: 0.0,
        end: 1.0,
        initialVelocity: 5.0,
      );

      expect(spring.dx(0.0), equals(5.0));
    });
  });

  group('Gravity simulation', () {
    test('initial values are correct', () {
      final gravity = Gravity(
        gravity: 9.81,
        start: 0.0,
        end: 100.0,
      );

      expect(gravity.x(0.0), equals(0.0));
      expect(gravity.dx(0.0), equals(0.0));
      expect(gravity.isDone(0.0), isFalse);
    });

    test('follows parabolic motion', () {
      final gravity = Gravity(
        gravity: 9.81,
        start: 0.0,
        end: 100.0,
      );

      final t1 = gravity.duration * 0.25;
      final t2 = gravity.duration * 0.5;
      final t3 = gravity.duration * 0.75;

      // Position should follow quadratic curve
      final x1 = gravity.x(t1);
      final x2 = gravity.x(t2);
      final x3 = gravity.x(t3);

      // Check that acceleration is roughly constant
      final v1 = (x2 - x1) / (t2 - t1);
      final v2 = (x3 - x2) / (t3 - t2);
      final a = (v2 - v1) / (t2 - t1);

      expect(a, closeTo(9.81, 0.1));
    });

    test('reaches target', () {
      final gravity = Gravity(
        gravity: 9.81,
        start: 0.0,
        end: 100.0,
      );

      expect(gravity.x(gravity.duration), closeTo(100.0, 0.01));
    });
  });

  group('Friction simulation', () {
    test('initial values are correct', () {
      final friction = Friction.withDrag(
        drag: 0.5,
        start: 0.0,
        initialVelocity: 1000.0,
        constantDeceleration: 100.0,
      );

      expect(friction.x(0.0), equals(0.0));
      expect(friction.dx(0.0), equals(1000.0));
      expect(friction.isDone(0.0), isFalse);
    });

    test('velocity decreases exponentially', () {
      final friction = Friction.withDrag(
        drag: 0.5,
        start: 0.0,
        initialVelocity: 1000.0,
        constantDeceleration: 100.0,
      );

      final v0 = friction.dx(0.0);
      final v1 = friction.dx(friction.duration * 0.5);
      final v2 = friction.dx(friction.duration);

      expect(v1, lessThan(v0));
      expect(v2, lessThan(v1));
      expect(v2.abs(), lessThan(1.0));
    });

    test('reaches target with specified drag', () {
      final friction = Friction.withDrag(
        drag: 0.5,
        start: 0.0,
        initialVelocity: 1000.0,
        constantDeceleration: 100.0,
      );

      final endPos = friction.x(friction.duration);
      expect(endPos, equals(friction.end));
    });
  });

  group('Simulation2D', () {
    test('combines two simulations correctly', () {
      final springDesc = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      final simulation = Simulation2D(
        Spring(
          description: springDesc,
          start: 0.0,
          end: 100.0,
          tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
        ),
        Spring(
          description: springDesc,
          start: 0.0,
          end: 200.0,
          tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
        ),
      );

      expect(simulation.x(0.0), equals(const Offset(0.0, 0.0)));

      final finalPos = simulation.x(simulation.xPhysics.duration);
      expect(finalPos.dx, closeTo(100.0, 0.1));
      expect(finalPos.dy, closeTo(200.0, 0.1));
    });

    test('handles different simulation types', () {
      final springDesc = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      final simulation = Simulation2D(
        Spring(
          description: springDesc,
          start: 0.0,
          end: 100.0,
          tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
        ),
        Gravity(
          gravity: 9.81,
          start: 0.0,
          end: 200.0,
          tolerance: const Tolerance(distance: 0.01, velocity: 0.01),
        ),
      );

      final maxDuration = math.max(
        simulation.xPhysics.duration,
        simulation.yPhysics.duration,
      );
      final finalPos = simulation.x(maxDuration);

      expect(finalPos.dx, closeTo(100.0, 0.1));
      expect(finalPos.dy, closeTo(200.0, 0.1));
    });

    test('isDone returns true when both simulations are done', () {
      final springDesc = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 10.0,
      );

      final simulation = Simulation2D(
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

      expect(simulation.isDone(0.0), isFalse);
      final double t = math.max(
        simulation.xPhysics.duration,
        simulation.yPhysics.duration,
      );
      expect(simulation.isDone(t), isTrue);
    });
  });

  group('ClampedPhysicalSimulation', () {
    test('clamps position within bounds', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 200.0,
        initialVelocity: 1000.0,
      );

      final clamped = ClampedPhysicalSimulation(
        spring,
        xMin: 0.0,
        xMax: 100.0,
      );

      // Should never exceed bounds
      for (double t = 0.0; t <= spring.duration; t += spring.duration / 10) {
        final x = clamped.x(t);
        expect(x, greaterThanOrEqualTo(0.0));
        expect(x, lessThanOrEqualTo(100.0));
      }
    });

    test('clamps velocity within bounds', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 100.0,
        initialVelocity: 1000.0,
      );

      final clamped = ClampedPhysicalSimulation(
        spring,
        dxMin: -500.0,
        dxMax: 500.0,
      );

      // Should never exceed velocity bounds
      for (double t = 0.0; t <= spring.duration; t += spring.duration / 10) {
        final v = clamped.dx(t);
        expect(v, greaterThanOrEqualTo(-500.0));
        expect(v, lessThanOrEqualTo(500.0));
      }
    });

    test('preserves isDone behavior', () {
      final spring = Spring(
        description: Spring.elegant,
        start: 0.0,
        end: 100.0,
      );

      final clamped = ClampedPhysicalSimulation(spring);

      expect(clamped.isDone(0.0), spring.isDone(0.0));
      expect(
        clamped.isDone(spring.duration),
        spring.isDone(spring.duration),
      );
    });
  });
}

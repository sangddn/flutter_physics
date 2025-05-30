import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  group('Spring Migration Flutter 3.32', () {
    // Test that predefined springs have reasonable damping ratios
    group('Predefined springs damping ratios', () {
      test('all springs should be underdamped or critically damped', () {
        final springs = [
          ('swift', Spring.swiftDescription),
          ('snap', Spring.snapDescription),
          ('playful', Spring.playfulDescription),
          ('stern', Spring.sternDescription),
          ('float', Spring.floatDescription),
          ('buoyant', Spring.buoyantDescription),
          ('fling', Spring.flingDescription),
          ('slow', Spring.slowDescription),
          ('bob', Spring.bobDescription),
          ('boingoingoing', Spring.boingoingoingDescription),
        ];

        for (final (name, desc) in springs) {
          final dampingRatio =
              desc.damping / (2 * math.sqrt(desc.stiffness * desc.mass));

          // All springs should be underdamped (< 1) or critically damped (≈ 1)
          expect(dampingRatio, lessThanOrEqualTo(1.0),
              reason:
                  '$name spring should not be overdamped (ratio: $dampingRatio)');

          // No spring should be completely undamped (ratio = 0)
          expect(dampingRatio, greaterThan(0.0),
              reason:
                  '$name spring should have some damping (ratio: $dampingRatio)');
        }
      });

      test('mass should be 1.0 for all predefined springs', () {
        final springs = [
          ('swift', Spring.swiftDescription),
          ('snap', Spring.snapDescription),
          ('playful', Spring.playfulDescription),
          ('stern', Spring.sternDescription),
          ('float', Spring.floatDescription),
          ('buoyant', Spring.buoyantDescription),
          ('fling', Spring.flingDescription),
          ('slow', Spring.slowDescription),
          ('bob', Spring.bobDescription),
          ('boingoingoing', Spring.boingoingoingDescription),
        ];

        for (final (name, desc) in springs) {
          expect(desc.mass, equals(1.0),
              reason:
                  '$name spring should have mass=1.0 to avoid Flutter 3.32 breaking changes');
        }
      });
    });

    group('Performance regression tests', () {
      test('swift spring should settle reasonably quickly', () {
        final spring = Spring(description: Spring.swiftDescription);

        // Swift should settle within 2 seconds for typical use
        expect(spring.duration, lessThan(2.0),
            reason: 'Swift spring should not be "super slow"');

        // Should reach 95% of target within 1 second
        final timeAt95Percent = _findTimeAtPercentage(spring, 0.95);
        expect(timeAt95Percent, lessThan(1.0),
            reason: 'Swift spring should reach 95% quickly');
      });

      test('snap spring should be responsive', () {
        final spring = Spring(description: Spring.snapDescription);

        expect(spring.duration, lessThan(1.5),
            reason: 'Snap spring should settle quickly');

        final timeAt90Percent = _findTimeAtPercentage(spring, 0.90);
        expect(timeAt90Percent, lessThan(0.8),
            reason: 'Snap spring should be responsive');
      });

      test('playful spring should have moderate bounce', () {
        final spring = Spring(description: Spring.playfulDescription);

        // Check for overshoot (bounce behavior)
        final hasOvershoot = _hasOvershoot(spring);
        expect(hasOvershoot, isTrue,
            reason: 'Playful spring should have some bounce');

        expect(spring.duration, lessThan(3.0),
            reason: 'Playful spring should still settle in reasonable time');
      });

      test('stern spring should have minimal oscillation', () {
        final spring = Spring(description: Spring.sternDescription);

        // Stern should reach target quickly with minimal overshoot
        final maxOvershoot = _getMaxOvershoot(spring);
        expect(maxOvershoot, lessThan(0.1),
            reason: 'Stern spring should have minimal overshoot');

        expect(spring.duration, lessThan(2.0),
            reason: 'Stern spring should settle quickly');
      });

      test('float spring should have gentle motion', () {
        final spring = Spring(description: Spring.floatDescription);

        // Float should settle in reasonable time (adjusted after migration)
        expect(spring.duration, lessThan(3.0),
            reason: 'Float spring should not be "super slow"');

        // Should have gentle, smooth motion with minimal overshoot
        final maxOvershoot = _getMaxOvershoot(spring);
        expect(maxOvershoot, lessThan(0.3),
            reason: 'Float spring should have gentle motion');
      });

      test('fling spring should not be extremely slow', () {
        final spring = Spring(description: Spring.flingDescription);

        // This was one of the most affected springs (1700% stiffness increase)
        // It should still settle in reasonable time
        expect(spring.duration, lessThan(10.0),
            reason: 'Fling spring should not exhibit "super slow" behavior');
      });

      test('slow spring behavior is appropriate', () {
        final spring = Spring(description: Spring.slowDescription);

        // Should be slow but not excessively so
        expect(spring.duration, greaterThan(2.0),
            reason: 'Slow spring should be relatively slow');
        expect(spring.duration, lessThan(15.0),
            reason: 'Slow spring should not be "super slow"');
      });

      test('bob spring should have significant oscillation', () {
        final spring = Spring(description: Spring.bobDescription);

        // Bob should have low damping and noticeable oscillation
        final numZeroCrossings = _countZeroCrossings(spring);
        expect(numZeroCrossings, greaterThan(3),
            reason: 'Bob spring should have multiple oscillations');
      });

      test('boingoingoing spring should be extremely bouncy', () {
        final spring = Spring(description: Spring.boingoingoingDescription);

        // Should have many oscillations
        final numZeroCrossings = _countZeroCrossings(spring);
        expect(numZeroCrossings, greaterThan(5),
            reason: 'Boingoingoing spring should be very bouncy');

        // Should have significant overshoot
        final maxOvershoot = _getMaxOvershoot(spring);
        expect(maxOvershoot, greaterThan(0.2),
            reason: 'Boingoingoing spring should overshoot significantly');
      });
    });

    group('Critical damping edge cases', () {
      test('springs near critical damping should behave continuously', () {
        // Test springs with damping ratios just above and below 1.0
        final underdamped = SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 2 * math.sqrt(100.0) * 0.9999, // ζ ≈ 0.9999
        );

        final overdamped = SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 2 * math.sqrt(100.0) * 1.0001, // ζ ≈ 1.0001
        );

        final springUnder = Spring(description: underdamped);
        final springOver = Spring(description: overdamped);

        // Duration should be similar for springs near critical damping
        final durationDiff = (springUnder.duration - springOver.duration).abs();
        expect(durationDiff, lessThan(0.5),
            reason:
                'Springs near critical damping should have similar durations');
      });

      test('critically damped spring should not overshoot', () {
        final criticallyDamped = SpringDescription(
          mass: 1.0,
          stiffness: 100.0,
          damping: 2 * math.sqrt(100.0), // ζ = 1.0
        );

        final spring = Spring(description: criticallyDamped);
        final maxOvershoot = _getMaxOvershoot(spring);

        expect(maxOvershoot, lessThan(0.01),
            reason: 'Critically damped spring should not overshoot');
      });
    });
  });
}

/// Helper function to find the time when spring reaches a certain percentage of target
double _findTimeAtPercentage(Spring spring, double percentage) {
  const int samples = 1000;
  final timeStep = spring.duration / samples;

  for (int i = 0; i < samples; i++) {
    final t = i * timeStep;
    final position = spring.x(t);
    final progress = (position - spring.start) / (spring.end - spring.start);

    if (progress >= percentage) {
      return t;
    }
  }

  return spring.duration; // Fallback
}

/// Helper function to check if spring overshoots its target
bool _hasOvershoot(Spring spring) {
  const int samples = 1000;
  final timeStep = spring.duration / samples;

  for (int i = 0; i < samples; i++) {
    final t = i * timeStep;
    final position = spring.x(t);

    // Check if position goes beyond target
    if (spring.end > spring.start && position > spring.end) {
      return true;
    } else if (spring.end < spring.start && position < spring.end) {
      return true;
    }
  }

  return false;
}

/// Helper function to get maximum overshoot amount
double _getMaxOvershoot(Spring spring) {
  const int samples = 1000;
  final timeStep = spring.duration / samples;
  double maxOvershoot = 0.0;

  for (int i = 0; i < samples; i++) {
    final t = i * timeStep;
    final position = spring.x(t);

    double overshoot = 0.0;
    if (spring.end > spring.start && position > spring.end) {
      overshoot = position - spring.end;
    } else if (spring.end < spring.start && position < spring.end) {
      overshoot = spring.end - position;
    }

    maxOvershoot = math.max(maxOvershoot, overshoot);
  }

  return maxOvershoot / (spring.end - spring.start).abs();
}

/// Helper function to count zero crossings (oscillations)
int _countZeroCrossings(Spring spring) {
  const int samples = 1000;
  final timeStep = spring.duration / samples;
  int crossings = 0;

  double? previousPosition;

  for (int i = 0; i < samples; i++) {
    final t = i * timeStep;
    final position = spring.x(t);
    final relativePosition =
        position - spring.end; // Position relative to target

    if (previousPosition != null) {
      // Check if we crossed the target line
      if ((previousPosition > 0 && relativePosition < 0) ||
          (previousPosition < 0 && relativePosition > 0)) {
        crossings++;
      }
    }

    previousPosition = relativePosition;
  }

  return crossings;
}

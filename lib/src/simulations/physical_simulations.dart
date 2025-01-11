import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

part 'spring.dart';
part 'gravity.dart';
part 'friction.dart';
part 'clamped.dart';
part 'simulation_2d.dart';

/// A type alias for the [Curve] interface to make it clear that users can pass
/// in any Flutter's native [Curve] or [PhysicsSimulation] to the [PhysicalController].
typedef Physics = Curve;

/// A base class for all physics simulations that also implement the [Curve]
/// interface.
@immutable
abstract class PhysicsSimulation implements Simulation, Curve {
  const PhysicsSimulation({
    this.start = 0.0,
    this.end = 1.0,
    this.initialVelocity = 0.0,
    this.tolerance = Tolerance.defaultTolerance,
  });

  /// The start position of the simulation.
  final double start;

  /// The end position of the simulation.
  final double end;

  /// The initial velocity of the simulation.
  final double initialVelocity;

  /// The estimated duration of the simulation. Built-in simulations will
  /// estimate this value either with the Newton's method or with the bisection
  /// method.
  double get duration;

  @override
  final Tolerance tolerance;

  @override
  set tolerance(Tolerance tolerance) {
    throw UnsupportedError(
        '[PhysicalSimulation].tolerance is read-only. You\'re likely using a [PhysicalSimulation] within a ScrollPhysics, which is disallowed.');
  }

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return transformInternal(t);
  }

  @override
  @protected
  double transformInternal(double t) => x(t * duration);

  @override
  Curve get flipped => FlippedCurve(this);

  /// Creates a new instance of the simulation with optionally modified properties while
  /// preserving the original simulation's behavior.
  ///
  /// Parameters:
  /// - [tolerance] defines new convergence criteria for the simulation.
  /// - [start] and [end] specify new position boundaries.
  /// - [duration] explicitly sets the simulation duration.
  /// - [durationScale] scales the current duration by a factor.
  ///
  /// Returns a new instance of the simulation with the specified modifications.
  ///
  /// This method is particularly useful when you need to:
  /// - Adjust the simulation's tolerance for position/velocity convergence
  /// - Change the start or end positions while maintaining the physics behavior
  /// - Scale or set a specific duration for the animation
  ///
  /// When both [duration] and [durationScale] are provided, they are used to calculate
  /// a new initial velocity that will make the simulation complete in the specified time.
  /// This allows for precise timing control while maintaining the physics-based motion.
  PhysicsSimulation copyWith({
    Tolerance? tolerance,
    double? start,
    double? end,
    Duration? duration,
    double? durationScale,
  });

  /// Calculates the initial velocity needed for the simulation to move from [start]
  /// to [end] position in roughly [durationInSeconds] seconds.
  ///
  /// Returns the calculated initial velocity in units per second.
  /// May return special values like [double.infinity] for impossible scenarios
  /// (e.g., zero duration).
  ///
  /// Parameters:
  /// - [start] and [end] define the positions to move between.
  /// - [durationInSeconds] specifies the exact time in seconds to complete the motion.
  ///
  /// This method is used internally by [copyWith] when a specific duration is requested,
  /// allowing precise control over animation timing while maintaining physics-based motion.
  ///
  /// Built-in [PhysicsSimulation]s implement this differently:
  /// - [Spring]: Solves the spring differential equation for initial velocity
  /// - [Gravity]: Uses projectile motion equations
  /// - [Friction]: Applies the inverse of the friction equation
  double solveInitialVelocity(
      double start, double end, double durationInSeconds);

  double _getEffectiveVelocity(
      double? start, double? end, Duration? duration, double? scale) {
    final durationInMicroseconds = duration == null
        ? null
        : scale == null
            ? duration.inMicroseconds
            : duration.inMicroseconds * scale;
    final durationInSeconds = durationInMicroseconds == null
        ? null
        : durationInMicroseconds / Duration.microsecondsPerSecond;
    final effectiveVelocity = durationInSeconds != null
        ? solveInitialVelocity(
            start ?? this.start, end ?? this.end, durationInSeconds)
        : initialVelocity;
    return effectiveVelocity;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'PhysicalSimulation')}(start: $start, end: $end, initialVelocity: $initialVelocity, duration: $duration)';
}

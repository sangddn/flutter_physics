import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';

part 'spring.dart';
part 'gravity.dart';
part 'friction.dart';
part 'clamped.dart';
part 'simulation_2d.dart';

/// A type alias for the [Curve] interface to make it clear that users can pass
/// in any Flutter's native [Curve] or [PhysicalSimulation] to the [PhysicalController].
typedef Physics = Curve;

/// A base class for all physical simulations that also implement the [Curve]
/// interface.
abstract class PhysicalSimulation extends Simulation implements Curve {
  PhysicalSimulation({
    this.start = 0.0,
    this.end = 1.0,
    this.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  });

  /// The start position of the simulation.
  final double start;

  /// The end position of the simulation.
  final double end;

  /// The initial velocity of the simulation.
  final double initialVelocity;

  double get duration;

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

  /// Creates a new [PhysicalSimulation] with the same properties as the current one,
  /// but with the specified [tolerance], [lowerBound], and [upperBound].
  PhysicalSimulation copyWith({
    Tolerance? tolerance,
    double? start,
    double? end,
    double? scale,
    Duration? duration,
  });

  double _solveInitialVelocity(double start, double end, double duration);
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
        ? _solveInitialVelocity(
            start ?? this.start, end ?? this.end, durationInSeconds)
        : initialVelocity;
    return effectiveVelocity;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'PhysicalSimulation')}(start: $start, end: $end, initialVelocity: $initialVelocity, duration: $duration)';
}

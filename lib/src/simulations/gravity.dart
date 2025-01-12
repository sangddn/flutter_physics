part of 'physics_simulations.dart';

/// A physics-based animation that simulates gravitational acceleration.
///
/// This simulation combines Flutter's [GravitySimulation] with the [Curve] interface,
/// allowing it to be used both as a physics simulation and as an animation curve.
///
/// The gravity simulation accelerates an object from a [start] position towards an [end]
/// position using constant acceleration (specified by [gravity]). The motion can begin
/// with an initial velocity.
///
/// Example usage:
/// ```dart
/// final gravityAnimation = Gravity(
///   gravity: 9.81,  // acceleration in logical pixels per second squared
///   start: 0.0,     // starting position
///   end: 100.0,     // ending position
///   initialVelocity: 0.0,  // optional initial velocity
/// );
///
/// // Use as a Curve in a standard animation
/// AnimatedContainer(
///   duration: const Duration(seconds: 1),
///   curve: gravityAnimation,
///   // ... other properties
/// );
///
/// // Or use directly as a Simulation
/// final controller = AnimationController(vsync: this);
/// controller.animateWith(gravityAnimation);
/// ```
///
/// The simulation continues until the object reaches its target position and velocity
/// approaches zero (within the specified [tolerance]).
class Gravity extends PhysicsSimulation {
  Gravity({
    required this.gravity,
    super.start = 0.0,
    super.end = 1.0,
    super.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  }) : duration = _solveForGravityTime(start, end, gravity, initialVelocity);

  static final earth = Gravity(gravity: 9.81);

  final double gravity;

  @override
  final double duration;

  @override
  double x(double time) =>
      start + initialVelocity * time + 0.5 * gravity * time * time;

  @override
  double dx(double time) => initialVelocity + gravity * time;

  @override
  bool isDone(double time) {
    // Check if we've reached or passed the end position in either direction
    return end < start ? x(time) <= end : x(time) >= end;
  }

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return transformInternal(t);
  }

  @override
  Gravity copyWith({
    double? start,
    double? end,
    double? durationScale,
    Duration? duration,
    Tolerance? tolerance,
    double? initialVelocity,
  }) {
    assert(initialVelocity == null ||
        (duration == null && durationScale == null) ||
        (start == null && end == null));
    return Gravity(
      gravity: gravity,
      start: start ?? this.start,
      end: end ?? this.end,
      initialVelocity: initialVelocity ??
          _getEffectiveVelocity(start, end, duration, durationScale),
      tolerance: tolerance ?? this.tolerance,
    );
  }

  @override
  String toString() => 'Gravity('
      'gravity: ${gravity.toStringAsFixed(2)}, '
      'start: ${start.toStringAsFixed(2)}, '
      'end: ${end.toStringAsFixed(2)}, '
      'initialVelocity: ${initialVelocity.toStringAsFixed(2)}, '
      'duration: ${duration.toStringAsFixed(2)})';

  @override
  double solveInitialVelocity(
    double start,
    double end,
    double durationInSeconds,
  ) {
    final d = end - start;
    if (durationInSeconds == 0) return double.infinity;
    if (gravity == 0) return d / durationInSeconds;
    return (d - 0.5 * gravity * durationInSeconds * durationInSeconds) /
        durationInSeconds;
  }

  @override
  bool operator ==(Object other) =>
      other is Gravity &&
      gravity == other.gravity &&
      start == other.start &&
      end == other.end &&
      initialVelocity == other.initialVelocity &&
      tolerance == other.tolerance;

  @override
  int get hashCode => Object.hash(
        gravity,
        start,
        end,
        initialVelocity,
        tolerance,
      );
}

double _solveForGravityTime(double x, double y, double a, double v0) {
  final d = y - x;
  if (a == 0 && v0 != 0) return d / v0;
  if (a == 0 && v0 == 0) return double.infinity;

  // When moving against gravity (d < 0), use absolute values and flip acceleration
  if (d < 0) {
    return _solveForGravityTime(y, x, -a, -v0);
  }

  // Use absolute acceleration to ensure positive time
  final absA = a.abs();
  return (math.sqrt(2 * absA * d + v0 * v0) + v0.abs()) / absA;
}

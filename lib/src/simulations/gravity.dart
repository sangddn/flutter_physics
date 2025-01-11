part of 'physical_simulations.dart';

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
    required super.start,
    required super.end,
    super.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  })  : _gravity = GravitySimulation(
          gravity,
          start,
          end,
          initialVelocity,
        ),
        duration = _solveForGravityTime(start, end, gravity, initialVelocity);

  final GravitySimulation _gravity;
  final double gravity;

  @override
  final double duration;

  @override
  double x(double time) => _gravity.x(time);

  @override
  double dx(double time) => _gravity.dx(time);

  @override
  bool isDone(double time) => _gravity.isDone(time);

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
  }) {
    return Gravity(
      gravity: gravity,
      start: start ?? this.start,
      end: end ?? this.end,
      initialVelocity:
          _getEffectiveVelocity(start, end, duration, durationScale),
      tolerance: tolerance ?? _gravity.tolerance,
    );
  }

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
}

double _solveForGravityTime(double x, double y, double a, double v0) {
  final d = y - x;
  if (a == 0) return d / v0;
  return (math.sqrt(2 * a * d + v0 * v0) - v0) / a;
}

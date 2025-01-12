part of 'physics_simulations.dart';

/// A physics-based animation that simulates motion with friction/drag.
///
/// This simulation combines Flutter's [FrictionSimulation] with the [Curve] interface,
/// allowing it to be used both as a physics simulation and as an animation curve.
///
/// The friction simulation applies a drag force that's proportional to velocity,
/// causing the motion to gradually slow down. The object starts at [start] position
/// with an [initialVelocity] and is affected by a [drag] coefficient.
///
/// The [drag] coefficient determines how quickly the motion slows down:
/// - Higher values (> 1.0) create more drag and faster deceleration
/// - Lower values (< 1.0) create less drag and slower deceleration
///
/// Example usage:
/// ```dart
/// final frictionAnimation = Friction.withDrag(
///   drag: 0.5,   // drag coefficient
///   start: 0.0,      // starting position
///   end: 100.0,      // ending position
///   initialVelocity: 1000.0,  // initial velocity (pixels per second)
/// );
///
/// // Use as a Curve in a standard animation
/// AnimatedContainer(
///   duration: const Duration(seconds: 1),
///   curve: frictionAnimation,
///   // ... other properties
/// );
///
/// // Or use directly as a Simulation
/// final controller = AnimationController(vsync: this);
/// controller.animateWith(frictionAnimation);
/// ```
///
/// The simulation continues until the object's velocity approaches zero
/// (within the specified [tolerance]). Note that unlike spring or gravity
/// simulations, a friction simulation might not reach exactly the target
/// position, as it primarily focuses on gradually reducing velocity.
class Friction extends PhysicsSimulation {
  Friction({
    required super.start,
    required this.end,
    required super.initialVelocity,
    super.tolerance = Tolerance.defaultTolerance,
    this.endVelocity = 0.0,
  })  : _friction = FrictionSimulation.through(
          start,
          end,
          initialVelocity,
          endVelocity,
        ),
        drag = _solveDrag(start, end, initialVelocity, endVelocity) {
    duration = _friction.timeAtX(end);
  }

  Friction.withDrag({
    required this.drag,
    required super.start,
    required super.initialVelocity,
    super.tolerance = Tolerance.defaultTolerance,
    double constantDeceleration = 0.0,
  }) : _friction = FrictionSimulation(
          drag,
          start,
          initialVelocity,
          constantDeceleration: constantDeceleration,
          tolerance: tolerance,
        ) {
    final dragLog = math.log(drag);
    var estimatedDuration = double.infinity;
    estimatedDuration = _newtonsMethod(
      initialGuess: 0,
      target: 0,
      f: dx,
      df: (double time) =>
          (initialVelocity * math.pow(drag, time) * dragLog) -
          constantDeceleration,
      iterations: 10,
    );
    duration = estimatedDuration;
    end = _friction.x(duration);
    endVelocity = _solveEndVelocity(initialVelocity, drag, duration);
    debugPrint('duration: $duration. end: $end. endVelocity: $endVelocity.');
  }

  final FrictionSimulation _friction;
  final double drag;
  late final double endVelocity;

  @override
  late final double duration;

  @override
  // ignore: overridden_fields
  late final double end;

  @override
  double x(double time) => _friction.x(time);

  @override
  double dx(double time) => _friction.dx(time);

  @override
  bool isDone(double time) => _friction.isDone(time);

  @override
  Friction copyWith({
    Tolerance? tolerance,
    double? start,
    double? end,
    double? durationScale,
    Duration? duration,
    double? initialVelocity,
  }) {
    assert(initialVelocity == null ||
        (duration == null && durationScale == null) ||
        (start == null && end == null));
    debugPrint('copyWith: $start, $end, $initialVelocity, $duration, $durationScale.');
    return Friction(
      start: start ?? this.start,
      end: end ?? this.end,
      initialVelocity: initialVelocity ??
          _getEffectiveVelocity(start, end, duration, durationScale),
      endVelocity: endVelocity,
      tolerance: tolerance ?? _friction.tolerance,
    );
  }

  @override
  double solveInitialVelocity(
    double start,
    double end,
    double durationInSeconds,
  ) {
    // For a friction simulation with drag coefficient 'drag',
    // x(t) = v0/k * (1 - e^(-kt)) + x0
    // where k is the drag coefficient
    // Solving for v0:
    // v0 = (x - x0) * k / (1 - e^(-kt))

    final k = math.log(drag);
    final denominator = 1 - math.exp(-k * durationInSeconds);

    if (denominator.abs() < 1e-10) {
      return 0.0;
    }

    return (end - start) * k / denominator;
  }
}

// Copied from Flutter's [FrictionSimulation].
double _solveDrag(double startPosition, double endPosition,
    double startVelocity, double endVelocity) {
  return math.pow(
          math.e, (startVelocity - endVelocity) / (startPosition - endPosition))
      as double;
}

// Copied from Flutter's [FrictionSimulation].
double _newtonsMethod(
    {required double initialGuess,
    required double target,
    required double Function(double) f,
    required double Function(double) df,
    required int iterations}) {
  double guess = initialGuess;
  for (int i = 0; i < iterations; i++) {
    guess = guess - (f(guess) - target) / df(guess);
  }
  return guess;
}

double _solveEndVelocity(double startVelocity, double drag, double duration) {
  return startVelocity * math.pow(drag, duration);
}

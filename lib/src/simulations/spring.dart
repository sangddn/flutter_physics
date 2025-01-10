part of 'physical_simulations.dart';

/// A physics-based animation that simulates spring motion.
///
/// This simulation combines Flutter's [SpringSimulation] with the [Curve] interface,
/// allowing it to be used both as a physics simulation and as an animation curve.
///
/// The spring simulation moves an object from a [start] position to an [end] position
/// using a spring force defined by [spring]. The motion can begin with an [initialVelocity]
/// and will oscillate around the target position before settling.
///
/// The [spring] parameter is a [SpringDescription] that defines the spring's properties:
/// - `mass`: The object's mass (higher values create more inertia)
/// - `stiffness`: The spring's stiffness (higher values create faster oscillations)
/// - `damping`: The amount of friction (higher values reduce oscillation)
///
/// Example usage:
/// ```dart
/// final springAnimation = Spring(
///   spring: SpringDescription(
///     mass: 1.0,
///     stiffness: 500.0,
///     damping: 20.0,
///   ),
///   start: 0.0,     // starting position
///   end: 100.0,     // ending position
///   initialVelocity: 0.0,  // optional initial velocity
/// );
///
/// // Use as a Curve in a standard animation
/// AnimatedContainer(
///   duration: const Duration(seconds: 1),
///   curve: springAnimation,
///   // ... other properties
/// );
///
/// // Or use directly as a Simulation
/// final controller = AnimationController(vsync: this);
/// controller.animateWith(springAnimation);
/// ```
///
/// The simulation continues until the spring settles at its rest position
/// (within the specified [tolerance]). The settling time and oscillation pattern
/// depend on the spring parameters.
class Spring extends PhysicalSimulation {
  Spring({
    required this.description,
    super.start = 0.0,
    super.end = 1.0,
    super.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  })  : _spring = SpringSimulation(description, start, end, initialVelocity),
        duration = _solveSpringDoneTime(
          description: description,
          startPosition: start,
          endPosition: end,
          velocity: initialVelocity,
          tolerance: tolerance,
        );

  Spring.withBounce({
    Duration duration = const Duration(milliseconds: 500),
    double bounce = 0.0,
    double mass = 1.0,
    super.start = 0.0,
    super.end = 1.0,
    super.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  })  : assert(duration > Duration.zero),
        assert(bounce >= -1.0 && bounce <= 1.0) {
    this.duration = duration.inMilliseconds / Duration.millisecondsPerSecond;
    description = SpringDescription(
      mass: mass,
      stiffness: math.pow(2 * math.pi / this.duration, 2).toDouble(),
      damping: 4 * math.pi * (1 - bounce) / this.duration,
    );
    _spring = SpringSimulation(description, start, end, initialVelocity);
  }

  Spring.withDamping({
    double dampingFraction = 0.9,
    Duration duration = const Duration(milliseconds: 400),
    double mass = 1.0,
    super.start = 0.0,
    super.end = 1.0,
    super.initialVelocity = 0.0,
    super.tolerance = Tolerance.defaultTolerance,
  }) : assert(dampingFraction >= 0.0 && dampingFraction <= 2.0) {
    this.duration = duration.inMilliseconds / Duration.millisecondsPerSecond;
    description = SpringDescription(
      mass: mass,
      stiffness: math.pow(2 * math.pi / this.duration, 2).toDouble(),
      damping: 4 * math.pi * dampingFraction / this.duration,
    );
    _spring = SpringSimulation(description, start, end, initialVelocity);
  }

  /// A swift, snappy spring with minimal oscillation
  static final swift = Spring(description: swiftDescription);
  static const swiftDescription = SpringDescription(
    mass: 0.3,
    stiffness: 280.0,
    damping: 18.0,
  );

  /// A smooth, elegant motion with slight bounce
  static final elegant = Spring.withDamping(
    mass: 0.6,
    dampingFraction: 0.86,
    initialVelocity: -1.0,
    duration: const Duration(milliseconds: 350),
  );

  /// A snappy, responsive spring
  static final snap = Spring(description: snapDescription);
  static const snapDescription = SpringDescription(
    mass: 0.4,
    stiffness: 320.0,
    damping: 20.0,
  );

  /// A stern, business-like spring with minimal oscillation
  static final stern = Spring(description: sternDescription);
  static const sternDescription = SpringDescription(
    mass: 1.2,
    stiffness: 550.0,
    damping: 30.0,
  );

  /// A floating, gentle motion
  static final float = Spring(description: floatDescription);
  static const floatDescription = SpringDescription(
    mass: 2.0,
    stiffness: 290.0,
    damping: 15.0,
  );

  /// A bouncy, buoyant spring with some weight
  static final buoyant = Spring(description: buoyantDescription);
  static const buoyantDescription = SpringDescription(
    mass: 10.0,
    stiffness: 900.0,
    damping: 80.0,
  );

  /// A quick, energetic fling
  static final fling = Spring(description: flingDescription);
  static const flingDescription = SpringDescription(
    mass: 4.0,
    stiffness: 800.0,
    damping: 80.0,
  );

  /// A slow, relaxed motion
  static final slow = Spring(description: slowDescription);
  static const slowDescription = SpringDescription(
    mass: 0.2,
    stiffness: 26.7,
    damping: 4.1,
  );

  /// A playful bobbing motion
  static final bob = Spring(description: bobDescription);
  static const bobDescription = SpringDescription(
    mass: 0.1,
    stiffness: 131.1,
    damping: 2.3,
  );

  /// An extremely bouncy, cartoonish spring
  static final boingoingoing = Spring(description: boingoingoingDescription);
  static const boingoingoingDescription = SpringDescription(
    mass: 0.1,
    stiffness: 1000.0,
    damping: 1.5,
  );

  late final SpringDescription description;
  late final SpringSimulation _spring;

  @override
  late final double duration;

  @override
  double x(double time) => _spring.x(time);

  @override
  double dx(double time) => _spring.dx(time);

  @override
  bool isDone(double time) => _spring.isDone(time);

  @override
  Spring copyWith({
    Tolerance? tolerance,
    double? start,
    double? end,
    double? scale,
    Duration? duration,
  }) {
    return Spring(
      description: description,
      start: start ?? this.start,
      end: end ?? this.end,
      initialVelocity: _getEffectiveVelocity(start, end, duration, scale),
      tolerance: tolerance ?? this.tolerance,
    );
  }

  @override
  double _solveInitialVelocity(double start, double end, double duration) =>
      _solveSpringVelocity(
        description: description,
        startPosition: start,
        endPosition: end,
        time: duration,
      );
}

/// Returns the velocity `v` that ensures a Flutter SpringSimulation
/// (with the given [description], start, end) reaches [endPosition]
/// exactly at time = [time], in the ideal continuous-time sense.
///
/// Handles underdamped, critically damped, and overdamped cases.
double _solveSpringVelocity({
  required SpringDescription description,
  required double startPosition,
  required double endPosition,
  required double time,
}) {
  final m = description.mass;
  final k = description.stiffness;
  final c = description.damping;

  // Angular frequency (undamped)
  final w0 = math.sqrt(k / m);

  // Damping ratio
  final zeta = c / (2 * math.sqrt(k * m));

  final startOffset = startPosition - endPosition; // A

  // Corner case: If startOffset == 0, then we're already at endPosition.
  if (startOffset.abs() < 1e-12) {
    // Then velocity should be 0 if we want to stay there.
    return 0.0;
  }

  if (zeta < 1.0) {
    // UNDERDAMPED
    final wd = w0 * math.sqrt(1 - zeta * zeta);

    // sin(wd*T) corner case
    final sinW = math.sin(wd * time);
    if (sinW.abs() < 1e-12) {
      // sin(...) = 0 => no finite velocity can force y(T) = 0
      // unless offset=0. We'll just return 0 or something.
      // But mathematically it diverges.
      return 0.0;
    }

    final cosW = math.cos(wd * time);
    // v = -A [ zeta*w0 + wd(cos(wdT)/sin(wdT)) ]
    return -startOffset * (zeta * w0 + wd * (cosW / sinW));
  } else if ((zeta - 1.0).abs() < 1e-12) {
    // CRITICALLY DAMPED (zeta == 1)
    // v = -A [ (1 / T) + w0 ]
    if (time.abs() < 1e-12) {
      // can't do 1/time
      return 0.0;
    }
    return -startOffset * ((1 / time) + w0);
  } else {
    // OVERDAMPED (zeta > 1)
    final sqrtTerm = w0 * math.sqrt(zeta * zeta - 1.0);
    final r1 = -zeta * w0 + sqrtTerm;
    final r2 = -zeta * w0 - sqrtTerm;

    final denom = 1 - math.exp((r1 - r2) * time);
    if (denom.abs() < 1e-12) {
      // The exponent is huge or something pathological
      return 0.0;
    }

    final numerator = (r1 - r2 * math.exp((r1 - r2) * time));
    return (startOffset / denom) * numerator;
  }
}

/// Numerically finds the earliest time `t >= 0` at which the
/// [SpringSimulation]'s position and velocity are both within the given
/// [tolerance]. If no such time is found up to [maxTime], returns [double.nan].
///
/// This method checks:
///   | x(t) - endPosition | <= tolerance.distance
///   AND
///   | dx(t) | <= tolerance.velocity
///
/// Uses a bracket-and-bisection approach.
double _solveSpringDoneTime({
  required SpringDescription description,
  required double startPosition,
  required double endPosition,
  required double velocity,
  required Tolerance tolerance,
  double maxTime = 60.0,
  int maxIterations = 30,
}) {
  // Create the simulation
  final simulation = SpringSimulation(
    description,
    startPosition,
    endPosition,
    velocity,
  );

  // This checks if the simulation is "within tolerance" at a given time t.
  bool isDone(double t) => simulation.isDone(t);

  // If it's already within tolerance at t=0, done.
  if (isDone(0.0)) {
    return 0.0;
  }

  // We'll first expand t exponentially until isDone(t) or we exceed maxTime.
  double tLow = 0.0;
  double tHigh = 1e-4; // a small positive number to expand from

  // Expand while not done and within maxTime
  while (tHigh < maxTime && !isDone(tHigh)) {
    tLow = tHigh;
    tHigh *= 2.0;
  }

  // If we got to maxTime without isDone, return NaN
  if (!isDone(tHigh) && tHigh >= maxTime) {
    return double.nan;
  }

  // Now we know it's not done at tLow, but it *is* done at tHigh (or tHigh < maxTime).
  // We'll do a bisection in [tLow, tHigh] to find the earliest time isDone(t) is true.

  for (int i = 0; i < maxIterations; i++) {
    final tMid = 0.5 * (tLow + tHigh);
    if (isDone(tMid)) {
      // If done at tMid, move upper bound down
      tHigh = tMid;
    } else {
      // Otherwise, move lower bound up
      tLow = tMid;
    }
  }

  // After bisection, tLow is the last time we were *not* done,
  // tHigh is the first time we *are* done. We return tHigh.
  return tHigh;
}

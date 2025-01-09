part of 'physical_simulations.dart';

/// A [PhysicalSimulation] that clamps the given simulation.
///
/// Modified version of Flutter's [ClampedSimulation] that implements the
/// [PhysicalSimulation] interface.
class ClampedPhysicalSimulation extends PhysicalSimulation {
  /// Creates a [ClampedPhysicalSimulation] that clamps the given simulation.
  ///
  /// The named arguments specify the ranges for the clamping behavior, as
  /// applied to [x] and [dx].
  ClampedPhysicalSimulation(
    this.simulation, {
    this.xMin = double.negativeInfinity,
    this.xMax = double.infinity,
    this.dxMin = double.negativeInfinity,
    this.dxMax = double.infinity,
  })  : assert(xMax >= xMin),
        assert(dxMax >= dxMin);

  /// The simulation being clamped. Calls to [x], [dx], and [isDone] are
  /// forwarded to the simulation.
  final PhysicalSimulation simulation;

  /// The minimum to apply to [x].
  final double xMin;

  /// The maximum to apply to [x].
  final double xMax;

  /// The minimum to apply to [dx].
  final double dxMin;

  /// The maximum to apply to [dx].
  final double dxMax;

  @override
  double x(double time) => clampDouble(simulation.x(time), xMin, xMax);

  @override
  double dx(double time) => clampDouble(simulation.dx(time), dxMin, dxMax);

  @override
  bool isDone(double time) => simulation.isDone(time);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ClampedSimulation')}(simulation: $simulation, x: ${xMin.toStringAsFixed(1)}..${xMax.toStringAsFixed(1)}, dx: ${dxMin.toStringAsFixed(1)}..${dxMax.toStringAsFixed(1)})';

  @override
  PhysicalSimulation copyWith({
    Tolerance? tolerance,
    double? start,
    double? end,
    double? scale,
    Duration? duration,
  }) =>
      ClampedPhysicalSimulation(
        simulation.copyWith(
          tolerance: tolerance,
          start: start,
          end: end,
          scale: scale,
          duration: duration,
        ),
        xMin: xMin,
        xMax: xMax,
        dxMin: dxMin,
        dxMax: dxMax,
      );

  @override
  double get duration => simulation.duration;

  @override
  double _solveInitialVelocity(double start, double end, double duration) =>
      simulation._solveInitialVelocity(start, end, duration);
}

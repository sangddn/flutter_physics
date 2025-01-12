part of 'physics_simulations.dart';

/// A wrapper class that combines two simulations to create 2D motion.
///
/// {@template simulation_2d}
/// [Simulation2D] allows you to specify separate physics simulations or curves for
/// X and Y coordinates. Both coordinates must use the same type - either both
/// [PhysicsSimulation] or both regular non-simulation [Curve].
///
/// ```dart
/// // Using physics simulations
/// final physics2D = Simulation2D(
///   Spring.elegant, // X-axis uses elegant spring motion
///   Spring.swift,   // Y-axis uses swift spring motion
/// );
///
/// // Using standard curves
/// final curves2D = Simulation2D(
///   Curves.easeOut, // X-axis eases out
///   Curves.easeIn,  // Y-axis eases in
/// );
/// ```
///
/// When using physics simulations, the simulation provides additional methods
/// for velocity and position calculations in 2D space.
/// {@endtemplate}
class Simulation2D extends Curve2D {
  /// Creates a 2D simulation using separate simulations for x and y coordinates.
  /// {@macro simulation_2d}
  const Simulation2D(this._x, this._y)
      : assert(_x is PhysicsSimulation == _y is PhysicsSimulation,
            "Both x and y must be physics simulations or both must be regular curves.");

  final Physics _x, _y;

  /// Returns true if both simulations are physics-based, ie. both are of type
  /// [PhysicsSimulation].
  bool isPhysicsBased() => _x is PhysicsSimulation && _y is PhysicsSimulation;

  /// Returns the position of the 2D simulation at the given time.
  Offset x(double time) {
    assert(isPhysicsBased(),
        "x(time) is only available for physics-based simulations.");
    return Offset(_xSim.x(time), _ySim.x(time));
  }

  /// Returns the velocity of the 2D simulation at the given time.
  Offset dx(double time) {
    assert(isPhysicsBased(),
        "dx(time) is only available for physics-based simulations.");
    return Offset(_xSim.dx(time), _ySim.dx(time));
  }

  /// Returns true if both simulations are done at the given time.
  bool isDone(double time) {
    assert(isPhysicsBased(),
        "isDone(time) is only available for physics-based simulations.");
    return _xSim.isDone(time) && _ySim.isDone(time);
  }

  /// Returns the physics simulation for the X axis.
  Curve get xPhysics => _x;

  /// Returns the physics simulation for the Y axis.
  Curve get yPhysics => _y;

  PhysicsSimulation get _xSim => _x as PhysicsSimulation;
  PhysicsSimulation get _ySim => _y as PhysicsSimulation;

  @override
  Offset transform(double t) => Offset(_x.transform(t), _y.transform(t));

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Simulation2D')}(x: $_x, y: $_y)';

  @override
  bool operator ==(Object other) =>
      other is Simulation2D && _x == other._x && _y == other._y;

  @override
  int get hashCode => Object.hash(_x, _y);
}

extension Simulation2DExtension on (Simulation, Simulation) {
  Offset x(double time) => Offset($1.x(time), $2.x(time));
  Offset dx(double time) => Offset($1.dx(time), $2.dx(time));
  bool isDone(double time) => $1.isDone(time) && $2.isDone(time);
  bool isPhysicsBased() => $1 is PhysicsSimulation && $2 is PhysicsSimulation;
}

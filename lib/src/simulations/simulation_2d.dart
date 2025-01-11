part of 'physics_simulations.dart';

typedef Physics2D = Curve2D;

/// A wrapper class that combines two simulations to create 2D motion
class Simulation2D extends Curve2D {
  /// Creates a 2D simulation using separate simulations for x and y coordinates
  const Simulation2D(this._x, this._y)
      : assert(_x is PhysicsSimulation == _y is PhysicsSimulation,
            "Both x and y must be physics simulations or both must be regular curves.");

  final Physics _x, _y;

  bool isPhysicsBased() => _x is PhysicsSimulation && _y is PhysicsSimulation;

  Offset x(double time) {
    assert(isPhysicsBased(),
        "x(time) is only available for physics-based simulations.");
    return Offset(_xSim.x(time), _ySim.x(time));
  }

  Offset dx(double time) {
    assert(isPhysicsBased(),
        "dx(time) is only available for physics-based simulations.");
    return Offset(_xSim.dx(time), _ySim.dx(time));
  }

  bool isDone(double time) {
    assert(isPhysicsBased(),
        "isDone(time) is only available for physics-based simulations.");
    return _xSim.isDone(time) && _ySim.isDone(time);
  }

  Curve get xPhysics => _x;
  Curve get yPhysics => _y;
  PhysicsSimulation get _xSim => _x as PhysicsSimulation;
  PhysicsSimulation get _ySim => _y as PhysicsSimulation;

  @override
  Offset transform(double t) => Offset(_x.transform(t), _y.transform(t));

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Simulation2D')}(x: $_x, y: $_y)';
}

extension Simulation2DExtension on (Simulation, Simulation) {
  Offset x(double time) => Offset($1.x(time), $2.x(time));
  Offset dx(double time) => Offset($1.dx(time), $2.dx(time));
  bool isDone(double time) => $1.isDone(time) && $2.isDone(time);
}

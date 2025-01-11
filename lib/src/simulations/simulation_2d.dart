part of 'physical_simulations.dart';

typedef Physics2D = Curve2D;

/// A wrapper class that combines two simulations to create 2D motion
class Simulation2D extends Curve2D {
  /// Creates a 2D simulation using separate simulations for x and y coordinates
  Simulation2D(this._x, this._y);

  final PhysicsSimulation _x, _y;

  Offset x(double time) => Offset(_x.x(time), _y.x(time));
  Offset dx(double time) => Offset(_x.dx(time), _y.dx(time));
  bool isDone(double time) => _x.isDone(time) && _y.isDone(time);

  PhysicsSimulation get xPhysics => _x;
  PhysicsSimulation get yPhysics => _y;

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

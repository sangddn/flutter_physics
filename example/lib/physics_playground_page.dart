import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

class PhysicsPlaygroundPage extends StatefulWidget {
  const PhysicsPlaygroundPage({super.key});

  @override
  State<PhysicsPlaygroundPage> createState() => _PhysicsPlaygroundPageState();
}

class _PhysicsPlaygroundPageState extends State<PhysicsPlaygroundPage>
    with SingleTickerProviderStateMixin {
  late final _gravityController =
      PhysicsController.unbounded(vsync: this, value: 0.0);

  @override
  void dispose() {
    _gravityController.dispose();
    super.dispose();
  }

  void _dropBall() {
    _gravityController.animateTo(
      10e10,
      physics: Gravity(gravity: 800, initialVelocity: 0),
    );
  }

  void _balloonUp() {
    _gravityController.animateTo(
      0.0,
      physics: Gravity(gravity: -800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gravity Simulation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 400,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _gravityController,
                    builder: (context, child) {
                      return Positioned(
                        top: _gravityController.value % 400.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _dropBall,
                  child: const Text('Drop'),
                ),
                const SizedBox(width: 16),
                AnimatedBuilder(
                    animation: _gravityController,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _gravityController.velocity <= 0
                                ? null
                                : _balloonUp,
                            child: const Text('Balloon'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Velocity: ${_gravityController.velocity.toStringAsFixed(1)}. Position: ${_gravityController.value.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

class InterruptedAnimationsPage extends StatefulWidget {
  const InterruptedAnimationsPage({super.key});

  @override
  State<InterruptedAnimationsPage> createState() =>
      _InterruptedAnimationsPageState();
}

class _InterruptedAnimationsPageState extends State<InterruptedAnimationsPage>
    with TickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );
  late final _physicsController = PhysicsController(
    vsync: this,
    defaultPhysics: Spring.elegant,
  );
  late final _rotationController = PhysicsController(
    vsync: this,
    lowerBound: 0.0,
    upperBound: double.infinity,
  );

  @override
  void dispose() {
    _physicsController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap anywhere on the slider to see how the bouncy spring '
              'naturally responds to mid-animation interruptions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _physicsController,
                builder: (context, _) {
                  return Slider(
                    value: _physicsController.value,
                    onChanged: (value) {
                      _physicsController.animateTo(
                        value,
                        physics: Spring.snap,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 64),
            const Text(
              'Compare that to Flutter\'s curve-based animation behavior.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return Slider(
                    value: _animationController.value,
                    onChanged: (value) {
                      _animationController.animateTo(
                        value,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.elasticOut,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 64),
            const Text(
              'Repeatedly rotate the box in different directions to see how it '
              'naturally responds to sudden changes in rotation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
                animation: _rotationController,
                builder: (_, child) => Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: child,
                    ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 40,
                  ),
                )),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _rotationController.animateTo(
                      _rotationController.value + .25,
                      physics: Spring.stern,
                    );
                  },
                  child: const Text('Rotate Right'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _rotationController.animateTo(
                      _rotationController.value - .25,
                      physics: Spring.stern,
                    );
                  },
                  child: const Text('Rotate Left'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

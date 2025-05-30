import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, Slider;
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
    return Material(
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Interrupted Animations'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Tap anywhere on the slider to see how the bouncy spring '
                    'naturally responds to mid-animation interruptions.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _physicsController,
                    builder: (context, _) {
                      return Slider(
                        value: _physicsController.value,
                        onChanged: (value) {
                          final diff = value - _physicsController.value;
                          if (diff.abs() < 0.1) {
                            _physicsController.value = value;
                          } else {
                            _physicsController.animateTo(
                              value,
                              physics: Spring.playful,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 64),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Compare that to Flutter\'s curve-based animation behavior.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      return Slider(
                        value: _animationController.value,
                        onChanged: (value) {
                          final diff = value - _animationController.value;
                          if (diff.abs() < 0.1) {
                            _animationController.value = value;
                          } else {
                            _animationController.animateTo(
                              value,
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.elasticOut,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 64),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Repeatedly rotate the box in different directions to see how it '
                    'naturally responds to sudden changes in rotation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
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
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      color: CupertinoColors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton.filled(
                      onPressed: () {
                        _rotationController.animateTo(
                          _rotationController.value + .25,
                          physics: Spring.stern,
                        );
                      },
                      child: const Text('Rotate Right'),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton.filled(
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
        ),
      ),
    );
  }
}

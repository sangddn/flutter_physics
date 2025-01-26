import 'package:flutter/cupertino.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Example by [@orestesgaolin](https://github.com/sangddn/flutter_physics/issues/1).
class TiltedCard extends StatefulWidget {
  const TiltedCard({super.key});

  @override
  State<TiltedCard> createState() => _TiltedCardState();
}

class _TiltedCardState extends State<TiltedCard> {
  bool show2D = true;

  @override
  void initState() {
    super.initState();
  }

  Offset tilt(double x, double y) {
    const force = 80.0;
    final rx = ((x / screenWidth) * force).clamp(-20.0, 20.0);
    final ry = ((y / screenHeight) * -force).clamp(-20.0, 20.0);
    currentOffset = Offset(rx, ry);
    return currentOffset;
  }

  double force = 80;
  Offset currentOffset = Offset.zero;
  Offset currentVelocity = Offset.zero;
  double screenWidth = 0;
  double screenHeight = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    final physicsChild = Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (DragUpdateDetails details) {
          final x =
              (screenWidth - details.globalPosition.dx) - (screenWidth / 2);
          final y =
              (screenHeight - details.globalPosition.dy) - (screenHeight / 2);

          setState(() {
            currentOffset = tilt(x, y);
          });
        },
        child: const _MyCard(),
      ),
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tilted Card'),
      ),
      child: SafeArea(
        child: Column(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoSlidingSegmentedControl(
              groupValue: show2D ? '2D' : '3D',
              onValueChanged: (value) {
                setState(() {
                  show2D = value == '2D';
                });
              },
              children: const {
                '2D': Text('PhysicsBuilder2D'),
                '3D': Text('PhysicsBuilderMulti'),
              },
            ),
            Expanded(
              child: Center(
                child: show2D
                    ? PhysicsBuilder2D(
                        value: currentOffset,
                        xPhysics: Spring.swift,
                        yPhysics: Spring.swift,
                        child: physicsChild,
                        builder: (context, offset, child) {
                          final xRadians = offset.dx * math.pi / 180;
                          final yRadians = offset.dy * math.pi / 180;

                          return Transform(
                            origin: Offset(screenWidth / 2, 300 / 2),
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(yRadians)
                              ..rotateY(xRadians),
                            child: child!,
                          );
                        },
                      )
                    : PhysicsBuilderMulti(
                        dimensions: 2,
                        value: [currentOffset.dx, currentOffset.dy],
                        physics: [Spring.swift, Spring.swift],
                        child: physicsChild,
                        builder: (context, offset, child) {
                          final xRadians = offset[0] * math.pi / 180;
                          final yRadians = offset[1] * math.pi / 180;

                          return Transform(
                            origin: Offset(screenWidth / 2, 300 / 2),
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(yRadians)
                              ..rotateY(xRadians),
                            child: child!,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCard extends StatelessWidget {
  const _MyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(25, 25),
            blurRadius: 75,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Hello Physics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'dart:math' as math;

const _gridCount = 4;
const _ballSize = 60.0;
const _gap = 10.0;
const _containerSize = (_ballSize + _gap) * _gridCount - _gap;

class PhysicsGrid extends StatefulWidget {
  const PhysicsGrid({super.key});

  @override
  State<PhysicsGrid> createState() => _PhysicsGridState();
}

class _PhysicsGridState extends State<PhysicsGrid>
    with SingleTickerProviderStateMixin {
  // Tracks which cell is being dragged.
  // Tracks which cell is being dragged.
  int activeRow = 0, activeCol = 0;
  Offset dragOffset = Offset.zero; // actual offset of the dragged cell

  // We'll animate the background hue from 0..360
  late final _hueController = PhysicsController(
    vsync: this,
    lowerBound: 0,
    upperBound: 360,
    // Using a standard curve for hue spin:
    defaultPhysics: Curves.ease,
    duration: const Duration(seconds: 10),
  );

  // Calculate custom stiffness/damping based on distance from active cell
  Spring _springForCell(int rowIndex, int colIndex) {
    final dx = (activeCol - colIndex).abs();
    final dy = (activeRow - rowIndex).abs();
    final d = dx + dy; // Manhattan distance
    return Spring.withBounce(
      mass: 0.6 + d * 0.05 + rowIndex * 0.05 + colIndex * 0.075,
      bounce: math.min(1.0, d * 0.1 + 0.1 - rowIndex * 0.05 + colIndex * 0.05),
      initialVelocity: -0.5,
      duration:
          const Duration(milliseconds: 150) + Duration(milliseconds: d * 50),
    );
  }

  @override
  void initState() {
    super.initState();
    // Just have it repeat from 0..360, loop forever
    _hueController.repeat(min: 0, max: 360, reverse: false);
  }

  @override
  void dispose() {
    _hueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Physics Grid'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox.square(
            dimension: _containerSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int row = 0; row < _gridCount; row++)
                  for (int col = 0; col < _gridCount; col++)
                    _buildCell(row, col),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int rowIndex, int colIndex) {
    final double baseLeft = colIndex * (_ballSize + _gap);
    final double baseTop = rowIndex * (_ballSize + _gap);

    final diagonalIndex = ((rowIndex + colIndex) * (360 / 6)).toInt();
    final color = HSVColor.fromAHSV(
      1.0,
      (_hueController.value + diagonalIndex) % 360,
      0.8,
      0.9,
    ).toColor();

    final isActive = rowIndex == activeRow && colIndex == activeCol;
    final spring = _springForCell(rowIndex, colIndex);
    return PhysicsBuilder2D(
      value: Offset(baseLeft, baseTop) + dragOffset,
      lowerBound: const Offset(-1000, -1000),
      upperBound: const Offset(1000, 1000),
      xPhysics: spring,
      yPhysics: spring,
      builder: (_, offset, child) {
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: child!,
        );
      },
      child: GestureDetector(
        onPanStart: (_) => setState(() {
          activeRow = rowIndex;
          activeCol = colIndex;
          dragOffset = Offset.zero;
        }),
        onPanUpdate: (details) => setState(() {
          dragOffset += details.delta;
        }),
        onPanEnd: (details) => setState(() {
          // Snap back to (0, 0) in local coords for this cell
          dragOffset = Offset.zero;
        }),
        child: _Circle(color, rowIndex, colIndex, isActive),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.color, this.row, this.col, this.isActive);

  final Color color;
  final int row;
  final int col;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ballSize,
      height: _ballSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_ballSize * 0.5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ]
            : [],
      ),
    );
  }
}

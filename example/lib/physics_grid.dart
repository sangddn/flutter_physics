import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'dart:math' as math;

class PhysicsGrid extends StatefulWidget {
  const PhysicsGrid({super.key});

  @override
  State<PhysicsGrid> createState() => _PhysicsGridState();
}

class _PhysicsGridState extends State<PhysicsGrid>
    with SingleTickerProviderStateMixin {
  static const gridCount = 4;
  static const size = 60.0;
  static const gap = 10.0;

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
  Widget build(BuildContext context) {
    const containerSize = (size + gap) * gridCount - gap;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Physics Grid'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox.square(
            dimension: containerSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int row = 0; row < gridCount; row++)
                  for (int col = 0; col < gridCount; col++)
                    _buildCell(row, col),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int rowIndex, int colIndex) {
    final double baseLeft = colIndex * (size + gap);
    final double baseTop = rowIndex * (size + gap);

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
          debugPrint('onPanStart: $rowIndex, $colIndex');
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
        child: _buildCircle(color, rowIndex, colIndex, isActive: isActive),
      ),
    );
  }

  Widget _buildCircle(Color color, int row, int col, {required bool isActive}) {
    return AContainer(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.5),
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

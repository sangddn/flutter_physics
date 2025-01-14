import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

void main() {
  group('PhysicsBuilder', () {
    testWidgets('animates from 0.0 to 1.0 with default physics',
        (tester) async {
      double currentValue = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: 0.0,
            builder: (context, value, child) {
              currentValue = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentValue, 0.0);

      // Update to 1.0
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: 1.0,
            builder: (context, value, child) {
              currentValue = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentValue, greaterThan(0.0));
      expect(currentValue, lessThan(1.0));

      // Finish animation
      await tester.pumpAndSettle();
      expect(currentValue, closeTo(1.0, 0.01));
    });

    testWidgets('respects bounds', (tester) async {
      double currentValue = 0.0;
      const lowerBound = -1.0;
      const upperBound = 1.0;

      // Start at lower bound
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: lowerBound,
            lowerBound: lowerBound,
            upperBound: upperBound,
            builder: (context, value, child) {
              currentValue = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentValue, equals(lowerBound));

      // Animate to upper bound
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: upperBound,
            lowerBound: lowerBound,
            upperBound: upperBound,
            builder: (context, value, child) {
              currentValue = value;
              return Container();
            },
          ),
        ),
      );

      // Let it settle
      await tester.pumpAndSettle();
      expect(currentValue, closeTo(upperBound, 0.01));
    });

    testWidgets('calls callbacks', (tester) async {
      int onValueChangedCalls = 0;
      int onEndCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: 0.0,
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      // Update value to trigger animation
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder(
            value: 1.0,
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      expect(onValueChangedCalls, 1); // Called once for value change
      expect(onEndCalls, 0); // Not called yet

      // Let animation complete
      await tester.pumpAndSettle();
      expect(onEndCalls, 1); // Called once after animation completes
    });

    testWidgets('preserves velocity on retarget', (tester) async {
      late PhysicsController controller;
      double currentValue = 0.0;

      Widget widget(double currentValue) => StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: PhysicsBuilder(
                  value: currentValue,
                  physics: Spring(
                    description: SpringDescription(
                      mass: 1.0,
                      stiffness:
                          50.0, // Lower stiffness for more visible motion
                      damping: 4.0, // Lower damping for more visible motion
                    ),
                  ),
                  builder: (context, value, child) {
                    return Container();
                  },
                ),
              );
            },
          );

      await tester.pumpWidget(widget(currentValue));

      // Get the controller from the state
      controller = tester
          .state<PhysicsBuilderState>(
            find.byType(PhysicsBuilder),
          )
          .controller;

      // Start animation to 1.0
      currentValue = 1.0;
      await tester.pumpWidget(widget(currentValue));

      // Let it build up some velocity
      await tester.pump(const Duration(milliseconds: 50));

      // Should have velocity by now
      expect(controller.velocity.abs(), greaterThan(0.0));
      final initialVelocitySign = controller.velocity.sign;

      // Retarget to 0.5
      currentValue = 0.5;
      await tester.pumpWidget(widget(currentValue));
      await tester.pump(); // One frame to process the retarget
      await tester.pump(const Duration(
          milliseconds: 16)); // One more frame to measure velocity

      // Velocity should be preserved
      expect(controller.velocity.abs(), greaterThan(0.0));
      expect(controller.velocity.sign, equals(initialVelocitySign));
    });
  });

  group('PhysicsBuilder2D', () {
    testWidgets('animates from zero to (100, 100)', (tester) async {
      Offset? currentOffset;
      const startOffset = Offset.zero;
      const endOffset = Offset(100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: startOffset,
            builder: (context, value, child) {
              currentOffset = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentOffset, equals(startOffset));

      // Update to end offset
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: endOffset,
            builder: (context, value, child) {
              currentOffset = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentOffset!.dx, greaterThan(0));
      expect(currentOffset!.dx, lessThan(100));
      expect(currentOffset!.dy, greaterThan(0));
      expect(currentOffset!.dy, lessThan(100));

      // Finish animation
      await tester.pumpAndSettle();
      expect(currentOffset!.dx, closeTo(endOffset.dx, 0.01));
      expect(currentOffset!.dy, closeTo(endOffset.dy, 0.01));
    });

    testWidgets('respects bounds', (tester) async {
      Offset? currentOffset;
      const lowerBound = Offset(-100, -100);
      const upperBound = Offset(100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: Offset.zero,
            lowerBound: lowerBound,
            upperBound: upperBound,
            builder: (context, value, child) {
              currentOffset = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentOffset, equals(Offset.zero));

      // Animate to upper bound
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: upperBound,
            lowerBound: lowerBound,
            upperBound: upperBound,
            builder: (context, value, child) {
              currentOffset = value;
              return Container();
            },
          ),
        ),
      );

      // Let it settle
      await tester.pumpAndSettle();
      expect(currentOffset!.dx, closeTo(upperBound.dx, 0.01));
      expect(currentOffset!.dy, closeTo(upperBound.dy, 0.01));
    });

    testWidgets('preserves velocity on retarget', (tester) async {
      late PhysicsController2D controller;
      Offset currentOffset = Offset.zero;

      Widget widget(Offset currentOffset) => StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: PhysicsBuilder2D(
                  value: currentOffset,
                  xPhysics: Spring(
                    description: SpringDescription(
                      mass: 1.0,
                      stiffness:
                          50.0, // Lower stiffness for more visible motion
                      damping: 4.0, // Lower damping for more visible motion
                    ),
                  ),
                  yPhysics: Spring(
                    description: SpringDescription(
                      mass: 1.0,
                      stiffness: 50.0,
                      damping: 4.0,
                    ),
                  ),
                  builder: (context, value, child) {
                    return Container();
                  },
                ),
              );
            },
          );

      await tester.pumpWidget(widget(currentOffset));

      // Get the controller from the state
      controller = tester
          .state<PhysicsBuilder2DState>(find.byType(PhysicsBuilder2D))
          .controller;

      // Start animation to (100, 100)
      currentOffset = const Offset(100, 100);
      await tester.pumpWidget(widget(currentOffset));

      // Let it build up some velocity
      await tester.pump(const Duration(milliseconds: 50));

      // Should have velocity by now
      expect(controller.velocity.distance, greaterThan(0.0));
      final initialVelocityDx = controller.velocity.dx;
      final initialVelocityDy = controller.velocity.dy;

      // Retarget to (50, 50)
      currentOffset = const Offset(50, 50);
      await tester.pumpWidget(widget(currentOffset));
      await tester.pump(); // One frame to process the retarget
      await tester.pump(const Duration(
          milliseconds: 16)); // One more frame to measure velocity

      // Velocity should be preserved
      expect(controller.velocity.distance, greaterThan(0.0));
      expect(controller.velocity.dx.sign, equals(initialVelocityDx.sign));
      expect(controller.velocity.dy.sign, equals(initialVelocityDy.sign));
    });

    testWidgets('calls callbacks', (tester) async {
      int onValueChangedCalls = 0;
      int onEndCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: Offset.zero,
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      // Update value to trigger animation
      await tester.pumpWidget(
        MaterialApp(
          home: PhysicsBuilder2D(
            value: const Offset(100, 100),
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      expect(onValueChangedCalls, 1); // Called once for value change
      expect(onEndCalls, 0); // Not called yet

      // Let animation complete
      await tester.pumpAndSettle();
      expect(onEndCalls, 1); // Called once after animation completes
    });
  });
}

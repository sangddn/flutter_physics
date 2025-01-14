import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

import '../matchers/color_matcher.dart';

void main() {
  group('AValue', () {
    testWidgets('AValue.double animates from 0.0 to 1.0', (tester) async {
      double currentValue = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.double(
            value: 0.0,
            normalize: (value) => value,
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
          home: AValue.double(
            value: 1.0,
            normalize: (value) => value,
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
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(currentValue, closeTo(1.0, 0.001));
    });

    testWidgets('AValue.color animates from red to blue', (tester) async {
      Color? currentColor;
      final startColor = const Color(0xFFFF0000); // Pure red
      final endColor = const Color(0xFF0000FF); // Pure blue

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.color(
            value: startColor,
            normalize: (color) => color.opacity,
            builder: (context, value, child) {
              currentColor = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentColor, matchesColor(startColor));

      // Update to blue
      await tester.pumpWidget(
        MaterialApp(
          home: AValue.color(
            value: endColor,
            normalize: (color) => color.opacity,
            builder: (context, value, child) {
              currentColor = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentColor, notMatchesColor(startColor));
      expect(currentColor, notMatchesColor(endColor));

      // Finish animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(currentColor, matchesColor(endColor));
    });

    testWidgets('AValue.size animates from small to large', (tester) async {
      Size? currentSize;
      const smallSize = Size(50, 50);
      const largeSize = Size(100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.size(
            value: smallSize,
            normalize: (size) => size.width / 100,
            builder: (context, value, child) {
              currentSize = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentSize!.width, closeTo(smallSize.width, 0.001));
      expect(currentSize!.height, closeTo(smallSize.height, 0.001));

      // Update to large size
      await tester.pumpWidget(
        MaterialApp(
          home: AValue.size(
            value: largeSize,
            normalize: (size) => size.width / 100,
            builder: (context, value, child) {
              currentSize = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentSize!.width, greaterThan(50));
      expect(currentSize!.width, lessThan(100));

      // Finish animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(currentSize!.width, closeTo(largeSize.width, 0.01));
      expect(currentSize!.height, closeTo(largeSize.height, 0.01));
    });

    testWidgets('AValue.offset animates from zero to (100, 100)',
        (tester) async {
      Offset? currentOffset;
      const startOffset = Offset.zero;
      const endOffset = Offset(100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.offset(
            value: startOffset,
            normalize: (offset) => offset.dx / 100,
            builder: (context, value, child) {
              currentOffset = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentOffset!.dx, closeTo(startOffset.dx, 0.001));
      expect(currentOffset!.dy, closeTo(startOffset.dy, 0.001));

      // Update to end offset
      await tester.pumpWidget(
        MaterialApp(
          home: AValue.offset(
            value: endOffset,
            normalize: (offset) => offset.dx / 100,
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

      // Finish animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(currentOffset!.dx, closeTo(endOffset.dx, 0.01));
      expect(currentOffset!.dy, closeTo(endOffset.dy, 0.01));
    });

    testWidgets('AValue.alignment animates from topLeft to bottomRight',
        (tester) async {
      AlignmentGeometry? currentAlignment;

      await tester.pumpWidget(
        MaterialApp(
          home: AValue<AlignmentGeometry>(
            value: AlignmentDirectional.topStart,
            lerp: (a, b, t) => AlignmentGeometry.lerp(a, b, t)!,
            normalize: (alignment) =>
                (alignment.resolve(TextDirection.ltr).x + 1) / 2,
            builder: (context, value, child) {
              currentAlignment = value;
              return Container();
            },
          ),
        ),
      );

      final resolvedStart = currentAlignment!.resolve(TextDirection.ltr);
      expect(resolvedStart.x, closeTo(-1.0, 0.001));
      expect(resolvedStart.y, closeTo(-1.0, 0.001));

      // Update to bottomRight
      await tester.pumpWidget(
        MaterialApp(
          home: AValue<AlignmentGeometry>(
            value: AlignmentDirectional.bottomEnd,
            lerp: (a, b, t) => AlignmentGeometry.lerp(a, b, t)!,
            normalize: (alignment) =>
                (alignment.resolve(TextDirection.ltr).x + 1) / 2,
            builder: (context, value, child) {
              currentAlignment = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      final midAlignment = currentAlignment!.resolve(TextDirection.ltr);
      expect(midAlignment.x, greaterThan(-1.0));
      expect(midAlignment.x, lessThan(1.0));

      // Finish animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      final resolvedEnd = currentAlignment!.resolve(TextDirection.ltr);
      expect(resolvedEnd.x, closeTo(1.0, 0.01));
      expect(resolvedEnd.y, closeTo(1.0, 0.01));
    });

    testWidgets('AValue.rect animates from small to large rect',
        (tester) async {
      Rect? currentRect;
      const smallRect = Rect.fromLTWH(0, 0, 50, 50);
      const largeRect = Rect.fromLTWH(0, 0, 100, 100);

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.rect(
            value: smallRect,
            normalize: (rect) => rect.width / 100,
            builder: (context, value, child) {
              currentRect = value;
              return Container();
            },
          ),
        ),
      );

      expect(currentRect!.width, closeTo(smallRect.width, 0.001));
      expect(currentRect!.height, closeTo(smallRect.height, 0.001));

      // Update to large rect
      await tester.pumpWidget(
        MaterialApp(
          home: AValue.rect(
            value: largeRect,
            normalize: (rect) => rect.width / 100,
            builder: (context, value, child) {
              currentRect = value;
              return Container();
            },
          ),
        ),
      );

      // Halfway through
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentRect!.width, greaterThan(50));
      expect(currentRect!.width, lessThan(100));

      // Finish animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(currentRect!.width, closeTo(largeRect.width, 0.01));
      expect(currentRect!.height, closeTo(largeRect.height, 0.01));
    });

    testWidgets('AValue calls onValueChanged and onEnd callbacks',
        (tester) async {
      int onValueChangedCalls = 0;
      int onEndCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AValue.double(
            value: 0.0,
            normalize: (value) => value,
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      // Update value
      await tester.pumpWidget(
        MaterialApp(
          home: AValue.double(
            value: 1.0,
            normalize: (value) => value,
            onValueChanged: (_) => onValueChangedCalls++,
            onEnd: () => onEndCalls++,
            builder: (context, value, child) => Container(),
          ),
        ),
      );

      expect(onValueChangedCalls, 1);
      expect(onEndCalls, 0);

      // Complete animation
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(onValueChangedCalls, 1);
      expect(onEndCalls, 1);
    });
  });
}

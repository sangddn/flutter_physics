import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AValue', () {
    testWidgets('double constructor animates correctly', (tester) async {
      double value = 0.0;
      double? lastValue;

      await tester.pumpWidget(
        AValue.double(
          value: value,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      value = 1.0;
      await tester.pumpWidget(
        AValue.double(
          value: value,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, 1.0);

      // Test mid-animation value
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
    });

    testWidgets('color constructor animates correctly', (tester) async {
      const color1 = Color(0xFF000000);
      const color2 = Color(0xFFFFFFFF);
      Color? lastValue;

      await tester.pumpWidget(
        AValue.color(
          value: color1,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      await tester.pumpWidget(
        AValue.color(
          value: color2,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, color2);
    });

    testWidgets('size constructor animates correctly', (tester) async {
      const size1 = Size(100, 100);
      const size2 = Size(200, 200);
      Size? lastValue;

      await tester.pumpWidget(
        AValue.size(
          value: size1,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      await tester.pumpWidget(
        AValue.size(
          value: size2,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, size2);
    });

    testWidgets('physics animation works correctly', (tester) async {
      double value = 0.0;
      bool animationEnded = false;

      await tester.pumpWidget(
        AValue.double(
          value: value,
          physics: Spring.elegant,
          onEnd: () => animationEnded = true,
          builder: (context, v, child) => Container(),
        ),
      );

      value = 1.0;
      await tester.pumpWidget(
        AValue.double(
          value: value,
          physics: Spring.elegant,
          onEnd: () => animationEnded = true,
          builder: (context, v, child) => Container(),
        ),
      );

      // Let the spring animation play out
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(animationEnded, true);
    });

    testWidgets('offset constructor animates correctly', (tester) async {
      const offset1 = Offset(0, 0);
      const offset2 = Offset(100, 100);
      Offset? lastValue;

      await tester.pumpWidget(
        AValue.offset(
          value: offset1,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      await tester.pumpWidget(
        AValue.offset(
          value: offset2,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, offset2);
    });

    testWidgets('rect constructor animates correctly', (tester) async {
      final rect1 = Rect.fromLTWH(0, 0, 100, 100);
      final rect2 = Rect.fromLTWH(50, 50, 200, 200);
      Rect? lastValue;

      await tester.pumpWidget(
        AValue.rect(
          value: rect1,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      await tester.pumpWidget(
        AValue.rect(
          value: rect2,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, rect2);
    });

    testWidgets('alignment constructor animates correctly', (tester) async {
      const alignment1 = Alignment.topLeft;
      const alignment2 = Alignment.bottomRight;
      Alignment? lastValue;

      await tester.pumpWidget(
        AValue.alignment(
          value: alignment1,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      await tester.pumpWidget(
        AValue.alignment(
          value: alignment2,
          duration: const Duration(milliseconds: 100),
          onValueChanged: (v) => lastValue = v,
          builder: (context, v, child) => Container(),
        ),
      );

      expect(lastValue, alignment2);
    });

    test('normalization functions work correctly', () {
      // Test double normalization
      expect(AValue.normalizeDouble(5.0), [5.0]);
      expect(AValue.denormalizeDouble([5.0]), 5.0);

      // Test color normalization
      final color = const Color(0xFF112233);
      final normalized = AValue.normalizeColor(color);
      final denormalized = AValue.denormalizeColor(normalized);
      expect(denormalized, color);

      // Test size normalization
      const size = Size(100, 200);
      final normalizedSize = AValue.normalizeSize(size);
      final denormalizedSize = AValue.denormalizeSize(normalizedSize);
      expect(denormalizedSize, size);

      // Test offset normalization
      const offset = Offset(10, 20);
      final normalizedOffset = AValue.normalizeOffset(offset);
      final denormalizedOffset = AValue.denormalizeOffset(normalizedOffset);
      expect(denormalizedOffset, offset);

      // Test rect normalization
      final rect = Rect.fromLTWH(0, 0, 100, 100);
      final normalizedRect = AValue.normalizeRect(rect);
      final denormalizedRect = AValue.denormalizeRect(normalizedRect);
      expect(denormalizedRect, rect);

      // Test alignment normalization
      const alignment = Alignment(0.5, -0.5);
      final normalizedAlignment = AValue.normalizeAlignment(alignment);
      final denormalizedAlignment =
          AValue.denormalizeAlignment(normalizedAlignment);
      expect(denormalizedAlignment, alignment);
    });
  });
}

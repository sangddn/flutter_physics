import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_physics/src/other_widgets/better_padding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetterPadding', () {
    testWidgets('handles positive padding normally', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: BetterPadding(
            padding: EdgeInsets.all(20),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsOneWidget);
      expect(find.byType(Transform), findsNothing);

      final paddingWidget = tester.widget<Padding>(paddingFinder);
      expect(paddingWidget.padding, const EdgeInsets.all(20));
    });

    testWidgets('handles negative padding using Transform', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: BetterPadding(
            padding: EdgeInsets.all(-20),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsOneWidget);

      final transform = tester.widget<Transform>(transformFinder);
      final translation = transform.transform.getTranslation();
      expect(translation[0], 0); // x translation
      expect(translation[1], 0); // y translation
    });

    testWidgets('handles mixed positive and negative padding', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: BetterPadding(
            padding:
                EdgeInsets.only(left: 20, top: -10, right: -15, bottom: 25),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(Transform), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);

      final transform = tester.widget<Transform>(find.byType(Transform));
      final translation = transform.transform.getTranslation();
      expect(translation[0], -15); // -0 + (-15) for x
      expect(translation[1], 10); // -(-10) + 0 for y

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(
        padding.padding,
        const EdgeInsets.only(left: 20, bottom: 25),
      );
    });

    testWidgets('handles RTL text direction', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: BetterPadding(
            padding: EdgeInsets.only(left: 20, right: -15),
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(Transform), findsOneWidget);
      expect(find.byType(Padding), findsOneWidget);

      final transform = tester.widget<Transform>(find.byType(Transform));
      final translation = transform.transform.getTranslation();
      expect(translation[0], -15); // RTL: end padding affects left translation
      expect(translation[1], 0);

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(
        padding.padding,
        const EdgeInsets.only(left: 20), // In RTL, left/right are not affected
      );
    });

    testWidgets('handles null child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: BetterPadding(
            padding: EdgeInsets.all(20),
            child: null,
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
    });

    test('provides correct debug properties', () {
      final padding = const BetterPadding(
        padding: EdgeInsets.all(20),
        child: SizedBox(),
      );

      final builder = DiagnosticPropertiesBuilder();
      padding.debugFillProperties(builder);

      final properties = builder.properties;
      expect(
        properties.any(
            (p) => p.name == 'padding' && p.value == const EdgeInsets.all(20)),
        isTrue,
      );
      expect(
        properties.any((p) => p.name == 'child' && p.value is SizedBox),
        isTrue,
      );
    });
  });
}

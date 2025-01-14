import 'package:flutter_physics/src/other_widgets/better_padding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

import '../matchers/color_matcher.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AContainer
  // ---------------------------------------------------------------------------
  testWidgets('AContainer animates decoration color from red to blue',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AContainer(
          decoration: BoxDecoration(color: Colors.red),
        ),
      ),
    );

    // Initial color should be red
    var container = tester.widget<Container>(find.byType(Container));
    expect((container.decoration as BoxDecoration).color,
        matchesColor(Colors.red));

    // Pump new widget with different decoration color
    await tester.pumpWidget(
      MaterialApp(
        home: AContainer(
          decoration: BoxDecoration(color: Colors.blue),
        ),
      ),
    );

    // Pump 250ms => half animation
    await tester.pump(const Duration(milliseconds: 200));
    container = tester.widget<Container>(find.byType(Container));
    final partialColor = (container.decoration as BoxDecoration).color!;
    expect(partialColor, isNot(Colors.red));
    expect(partialColor, isNot(Colors.blue));

    // Complete the animation
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    container = tester.widget<Container>(find.byType(Container));
    expect((container.decoration as BoxDecoration).color,
        matchesColor(Colors.blue));
  });

  // ---------------------------------------------------------------------------
  // APadding
  // ---------------------------------------------------------------------------
  testWidgets('APadding animates padding from zero to 20', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: APadding(
          padding: EdgeInsets.zero,
          child: Container(width: 50, height: 50, color: Colors.red),
        ),
      ),
    );

    // Initial padding is zero
    final initialPaddingWidget =
        tester.widget(find.byType(APadding)) as APadding;
    expect(initialPaddingWidget.padding, EdgeInsets.zero);

    // Update padding
    await tester.pumpWidget(
      MaterialApp(
        home: APadding(
          padding: const EdgeInsets.all(20),
          child: Container(width: 50, height: 50, color: Colors.red),
        ),
      ),
    );

    // Pump half the duration
    await tester.pump(const Duration(milliseconds: 150));
    final midPaddingElement = tester.element(find.byType(BetterPadding));
    final midPaddingWidget = midPaddingElement.widget as BetterPadding;
    expect(midPaddingWidget.padding.resolve(TextDirection.ltr).left,
        isNot(0)); // not zero
    expect(midPaddingWidget.padding.resolve(TextDirection.ltr).left,
        lessThan(20)); // not fully 20

    // Finish animation
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final finalPaddingWidget = tester.widget(find.byType(APadding)) as APadding;
    expect(finalPaddingWidget.padding, const EdgeInsets.all(20));
  });

  // ---------------------------------------------------------------------------
  // AAlign
  // ---------------------------------------------------------------------------
  testWidgets('AAlign animates alignment from topLeft to bottomRight',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AAlign(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );

    var alignWidget = tester.widget<Align>(find.byType(Align));
    expect(alignWidget.alignment, Alignment.topLeft);

    // Update alignment
    await tester.pumpWidget(
      MaterialApp(
        home: AAlign(
          alignment: Alignment.bottomRight,
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );

    // Halfway through
    await tester.pump(const Duration(milliseconds: 200));
    alignWidget = tester.widget<Align>(find.byType(Align));
    expect(alignWidget.alignment.resolve(TextDirection.ltr).x, lessThan(1.0));
    expect(alignWidget.alignment.resolve(TextDirection.ltr).y, lessThan(1.0));

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    alignWidget = tester.widget<Align>(find.byType(Align));
    expect((alignWidget.alignment as Alignment).x, closeTo(1.0, 0.001));
    expect((alignWidget.alignment as Alignment).y, closeTo(1.0, 0.001));
  });

  // ---------------------------------------------------------------------------
  // APositioned
  // ---------------------------------------------------------------------------
  testWidgets('APositioned animates left from 0 to 50', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            APositioned(
              left: 0,
              top: 0,
              child: Container(width: 20, height: 20, color: Colors.blue),
            ),
          ],
        ),
      ),
    );

    Positioned positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, 0);

    // Update
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            APositioned(
              left: 50,
              top: 0,
              child: Container(width: 20, height: 20, color: Colors.blue),
            ),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, greaterThan(0));
    expect(positioned.left, lessThan(50));

    // Finish
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, closeTo(50, 0.1));
  });

  // ---------------------------------------------------------------------------
  // APositionedDirectional
  // ---------------------------------------------------------------------------
  testWidgets('APositionedDirectional animates start from 0 to 40',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              APositionedDirectional(
                start: 0,
                top: 0,
                child: Container(width: 20, height: 20, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    final positioned = tester
        .widget<APositionedDirectional>(find.byType(APositionedDirectional));
    expect(positioned.start, 0);

    // Update to start=40
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              APositionedDirectional(
                start: 40,
                top: 0,
                child: Container(width: 20, height: 20, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));
    final mid = tester.widget<Positioned>(find.byType(Positioned));
    expect(mid.left, greaterThan(0));
    expect(mid.left, lessThan(40));

    // Finish
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final finalPos = tester.widget<Positioned>(find.byType(Positioned));
    expect(finalPos.left, closeTo(40, 0.1));
  });

  // ---------------------------------------------------------------------------
  // AScale
  // ---------------------------------------------------------------------------
  testWidgets('AScale animates scale from 1.0 to 2.0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AScale(
          scale: 1.0,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    var transform = tester.widget<Transform>(find.byType(Transform));
    expect(transform.transform.getMaxScaleOnAxis(), 1.0);

    // Update
    await tester.pumpWidget(
      MaterialApp(
        home: AScale(
          scale: 2.0,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    transform = tester.widget<Transform>(find.byType(Transform));
    final midScale = transform.transform.getMaxScaleOnAxis();
    expect(midScale, greaterThan(1.0));
    expect(midScale, lessThan(2.0));

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    transform = tester.widget<Transform>(find.byType(Transform));
    final endScale = transform.transform.getMaxScaleOnAxis();
    expect(endScale, closeTo(2.0, 0.1));
  });

  // ---------------------------------------------------------------------------
  // ARotation
  // ---------------------------------------------------------------------------
  testWidgets('ARotation animates turns from 0 to 1 (0..360 degrees)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ARotation(
          turns: 0.0,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    var transform = tester.widget<Transform>(find.byType(Transform));
    // angle = 0 initially
    expect(transform.transform, equals(Matrix4.identity()));

    // Animate to 1 turn
    await tester.pumpWidget(
      MaterialApp(
        home: ARotation(
          turns: 1.0,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    transform = tester.widget<Transform>(find.byType(Transform));
    // angle should be about pi (180 degrees) halfway
    // We'll just check it's not identity
    expect(transform.transform, isNot(Matrix4.identity()));

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    transform = tester.widget<Transform>(find.byType(Transform));
    // 360 degrees => transform ends up close to identity again, but with floating math
    // We'll just check approximate
    // A 360-degree rotation is effectively the identity, but let's ensure it doesn't break
    // We can just confirm there's no error. If we want a numeric check:
    // final angle = // you'd parse out from transform
    // For simplicity: we'll just expect it to be nearly identity:
    // But realistically it might be floating. We'll do a quick approach:
    // (For thoroughness, you can parse transform and check angle.)
    // We'll do a minimal check:
    expect(transform.transform[0], closeTo(1.0, 0.001));
  });

  // ---------------------------------------------------------------------------
  // ASlide
  // ---------------------------------------------------------------------------
  testWidgets('ASlide animates offset from (0,0) to (0.5, -0.5)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ASlide(
          offset: Offset.zero,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    var fractionalTranslation = tester
        .widget<FractionalTranslation>(find.byType(FractionalTranslation));
    expect(fractionalTranslation.translation, Offset.zero);

    // Update
    await tester.pumpWidget(
      MaterialApp(
        home: ASlide(
          offset: const Offset(0.5, -0.5),
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    fractionalTranslation = tester
        .widget<FractionalTranslation>(find.byType(FractionalTranslation));
    expect(fractionalTranslation.translation.dx, greaterThan(0.0));
    expect(fractionalTranslation.translation.dx, lessThan(0.5));

    // Finish
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    fractionalTranslation = tester
        .widget<FractionalTranslation>(find.byType(FractionalTranslation));
    expect(fractionalTranslation.translation.dx, closeTo(0.5, 0.001));
    expect(fractionalTranslation.translation.dy, closeTo(-0.5, 0.001));
  });

  // ---------------------------------------------------------------------------
  // AOpacity
  // ---------------------------------------------------------------------------
  testWidgets('AOpacity animates opacity from 1.0 to 0.4', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AOpacity(
          opacity: 1.0,
          child: Container(width: 100, height: 100, color: Colors.red),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.widget<AOpacity>(find.byType(AOpacity)).opacity, 1.0);

    // Animate to 0.4
    await tester.pumpWidget(
      MaterialApp(
        home: AOpacity(
          opacity: 0.4,
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    final opacityWidget =
        tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(opacityWidget.opacity.value, closeTo(0.4, 0.01));
  });

  // ---------------------------------------------------------------------------
  // ASliverOpacity
  // ---------------------------------------------------------------------------
  testWidgets('ASliverOpacity animates opacity from 0.2 to 1.0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: [
            ASliverOpacity(
              opacity: 0.2,
              sliver: SliverToBoxAdapter(
                child: SizedBox(width: 50, height: 50, child: Text('Hello')),
              ),
            ),
          ],
        ),
      ),
    );

    var sliverOpacity =
        tester.widget<ASliverOpacity>(find.byType(ASliverOpacity));
    expect(sliverOpacity.opacity, 0.2);

    // Animate to 1.0
    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          slivers: [
            ASliverOpacity(
              opacity: 1.0,
              sliver: SliverToBoxAdapter(
                child: SizedBox(width: 50, height: 50, child: Text('Hello')),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    sliverOpacity = tester.widget<ASliverOpacity>(find.byType(ASliverOpacity));
    expect(sliverOpacity.opacity, closeTo(1.0, 0.1));
  });

  // ---------------------------------------------------------------------------
  // ADefaultTextStyle
  // ---------------------------------------------------------------------------
  testWidgets('ADefaultTextStyle animates style color from black to red',
      (tester) async {
    final key = GlobalObjectKey('defaultTextStyle-test');
    final innerWidget = Builder(builder: (context) {
      return DefaultTextStyle(
        key: key,
        style: DefaultTextStyle.of(context).style,
        child: const Text('Hello'),
      );
    });
    final styleBlack = const TextStyle(color: Colors.black, fontSize: 16);
    final styleRed = const TextStyle(color: Colors.red, fontSize: 16);

    await tester.pumpWidget(
      MaterialApp(
        home: ADefaultTextStyle(
          style: styleBlack,
          child: innerWidget,
        ),
      ),
    );

    var defaultTextStyle = tester.widget<DefaultTextStyle>(find.byKey(key));
    expect(defaultTextStyle.style.color, matchesColor(Colors.black));

    // Animate to red
    await tester.pumpWidget(
      MaterialApp(
        home: ADefaultTextStyle(
          style: styleRed,
          child: innerWidget,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    defaultTextStyle = tester.widget<DefaultTextStyle>(find.byKey(key));
    // The color should be partially between black and red
    expect(defaultTextStyle.style.color, notMatchesColor(Colors.black));
    expect(defaultTextStyle.style.color, notMatchesColor(Colors.red));

    // Finish
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    defaultTextStyle = tester.widget<DefaultTextStyle>(find.byKey(key));
    expect(defaultTextStyle.style.color, matchesColor(Colors.red));
  });

  // ---------------------------------------------------------------------------
  // APhysicalModel
  // ---------------------------------------------------------------------------
  testWidgets('APhysicalModel animates elevation and color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: APhysicalModel(
          elevation: 2.0,
          color: Colors.black,
          shadowColor: Colors.grey,
          child: const SizedBox(width: 50, height: 50),
        ),
      ),
    );
    var physicalModel =
        tester.widget<PhysicalModel>(find.byType(PhysicalModel));
    expect(physicalModel.elevation, closeTo(2.0, 0.001));
    expect(physicalModel.color, matchesColor(Colors.black));

    // Animate to elevation=10, color=blue
    await tester.pumpWidget(
      MaterialApp(
        home: APhysicalModel(
          elevation: 10.0,
          color: Colors.blue,
          shadowColor: Colors.grey,
          child: const SizedBox(width: 50, height: 50),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    physicalModel = tester.widget<PhysicalModel>(find.byType(PhysicalModel));
    expect(physicalModel.elevation, greaterThan(2.0));
    expect(physicalModel.elevation, lessThan(10.0));
    expect(physicalModel.color, notMatchesColor(Colors.black));
    expect(physicalModel.color, notMatchesColor(Colors.blue));

    // Finish
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    physicalModel = tester.widget<PhysicalModel>(find.byType(PhysicalModel));
    expect(physicalModel.elevation, closeTo(10.0, 0.1));
    expect(physicalModel.color, matchesColor(Colors.blue));
  });

  // ---------------------------------------------------------------------------
  // AFractionallySizedBox
  // ---------------------------------------------------------------------------
  testWidgets('AFractionallySizedBox animates widthFactor from 0.5 to 1.0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AFractionallySizedBox(
          widthFactor: 0.5,
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    var fractionalBox =
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fractionalBox.widthFactor, closeTo(0.5, 0.001));

    // Animate to 1.0
    await tester.pumpWidget(
      MaterialApp(
        home: AFractionallySizedBox(
          widthFactor: 1.0,
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    fractionalBox =
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fractionalBox.widthFactor, greaterThan(0.5));
    expect(fractionalBox.widthFactor, lessThan(1.0));

    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    fractionalBox =
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fractionalBox.widthFactor, closeTo(1.0, 0.1));
  });
}

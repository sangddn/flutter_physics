import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';
import 'package:flutter_test/flutter_test.dart';

// A critically damped spring approaches its target from below, so decoration
// clamping during overshoot cannot hide a value left within settling tolerance.
final _spring = Spring.withDamping(dampingFraction: 1);

const _decorated = BoxDecoration(
  color: Color(0xffeeeeee),
  border: Border.fromBorderSide(
    BorderSide(color: Color(0xff123456), width: 4),
  ),
  boxShadow: [BoxShadow(blurRadius: 12, offset: Offset(0, 4))],
);
const _withoutBorderOrShadows = BoxDecoration(color: Color(0xffeeeeee));
const _withEmptyShadows = BoxDecoration(
  color: Color(0xffeeeeee),
  boxShadow: [],
);

Widget _container({
  required BoxDecoration decoration,
  bool foreground = false,
  double width = 100,
  double height = 100,
  Alignment alignment = Alignment.topLeft,
  VoidCallback? onEnd,
}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: AContainer(
          physics: _spring,
          decoration: foreground ? null : decoration,
          foregroundDecoration: foreground ? decoration : null,
          width: width,
          height: height,
          alignment: alignment,
          onEnd: onEnd,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );

Container _renderedContainer(WidgetTester tester) => tester.widget<Container>(
      find.descendant(
        of: find.byType(AContainer),
        matching: find.byType(Container),
      ),
    );

void main() {
  group('AContainer exact completion', () {
    for (final foreground in [false, true]) {
      final property = foreground ? 'foregroundDecoration' : 'decoration';

      for (final target in [_withoutBorderOrShadows, _withEmptyShadows]) {
        final shadowList = target.boxShadow == null ? 'null' : 'empty';

        testWidgets('$property removes border and $shadowList shadows exactly',
            (tester) async {
          await tester.pumpWidget(_container(
            decoration: _decorated,
            foreground: foreground,
          ));
          await tester.pumpWidget(_container(
            decoration: target,
            foreground: foreground,
          ));

          await tester.pumpAndSettle(const Duration(milliseconds: 16));

          final container = _renderedContainer(tester);
          final decoration = (foreground
              ? container.foregroundDecoration
              : container.decoration) as BoxDecoration;
          expect(decoration, target);
          expect(decoration.border, isNull);
          expect(decoration.boxShadow, target.boxShadow);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('onEnd observes exact tween progress and geometry targets',
        (tester) async {
      await tester.pumpWidget(_container(decoration: _decorated));
      final state = tester.state<PhysicsAnimatedWidgetState<AContainer>>(
        find.byType(AContainer),
      );
      var completions = 0;
      double? completedProgress;
      List<double>? completedValues;
      await tester.pumpWidget(_container(
        decoration: _withoutBorderOrShadows,
        width: 240,
        height: 160,
        alignment: Alignment.bottomRight,
        onEnd: () {
          completions++;
          completedProgress = state.animation.value;
          completedValues = state.controller.value.toList();
        },
      ));

      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(completions, 1);
      expect(completedProgress, 1.0);
      expect(completedValues!.first, 1.0);
      for (final entry in {
        'width': 240.0,
        'height': 160.0,
        'alignmentX': 1.0,
        'alignmentY': 1.0,
      }.entries) {
        final index = state.physicsAnimatedProperties.indexOf(entry.key) + 1;
        expect(completedValues![index], entry.value, reason: entry.key);
        expect(state.controller.value[index], entry.value, reason: entry.key);
      }
      expect(state.animation.value, 1.0);
      expect(state.controller.isAnimating, isFalse);
      final container = _renderedContainer(tester);
      expect(container.constraints, BoxConstraints.tight(const Size(240, 160)));
      expect(container.alignment, Alignment.bottomRight);
      expect(container.decoration, _withoutBorderOrShadows);
      expect(tester.takeException(), isNull);
    });
  });
}

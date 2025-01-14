import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// {@template better_padding}
/// A widget that provides better handling of negative padding.
///
/// This widget extends the capabilities of Flutter's standard [Padding] widget by
/// properly handling negative padding values through the use of [Transform.translate].
///
/// This example shows how to use negative padding to extend a child beyond its normal bounds:
///
/// ```dart
/// // Positive padding implemented as normal Padding.
/// BetterPadding(
///   padding: const EdgeInsets.only(left: 20, top: 10),
///   child: Container(
///     width: 100,
///     height: 100,
///     color: Colors.blue,
///   ),
/// )
///
/// // Negative padding implemented as Transform.translate.
/// BetterPadding(
///   padding: const EdgeInsets.only(left: -20, top: -10),
///   child: Container(
///     width: 100,
///     height: 100,
///     color: Colors.blue,
///   ),
/// )
///
/// // Mixed positive and negative padding is ok
/// BetterPadding(
///   padding: const EdgeInsets.only(left: 20, top: -10),
///   child: Container(
///     width: 100,
///     height: 100,
///     color: Colors.blue,
///   ),
/// )
/// ```
///
/// ## How it works
///
/// When negative padding values are detected:
/// 1. Positive padding values are applied using standard [Padding]
/// 2. Negative padding values are applied using [Transform.translate]
/// 3. The transformations are combined seamlessly
///
/// This approach ensures that:
/// * Negative padding works as expected
/// * Layout calculations remain accurate
/// * Child widgets are positioned correctly
///
/// Drawbacks:
/// * Transform.translate works after the layout phase, which affects hit testing.
///
/// See also:
/// * [APadding] for physics-based padding animations
/// * [AContainer] for more general container animations
/// {@endtemplate}
class BetterPadding extends StatelessWidget {
  /// Creates a [BetterPadding] widget.
  /// {@macro better_padding}
  const BetterPadding({
    required this.padding,
    required this.child,
    super.key,
  });

  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties
        .add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding.resolve(Directionality.maybeOf(context));
    final negativeTop = effectivePadding.top < 0 ? effectivePadding.top : 0.0;
    final negativeLeft =
        effectivePadding.left < 0 ? effectivePadding.left : 0.0;
    final negativeRight =
        effectivePadding.right < 0 ? effectivePadding.right : 0.0;
    final negativeBottom =
        effectivePadding.bottom < 0 ? effectivePadding.bottom : 0.0;
    final child = Padding(
      padding:
          effectivePadding.clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity),
      child: this.child,
    );
    if (negativeTop != 0 ||
        negativeLeft != 0 ||
        negativeRight != 0 ||
        negativeBottom != 0) {
      // For horizontal direction:
      // - negative left padding should move content left (-x)
      // - negative right padding should move content right (+x)
      final x = -negativeLeft + negativeRight;

      // For vertical direction:
      // - negative top padding should move content up (-y)
      // - negative bottom padding should move content down (+y)
      final y = -negativeTop + negativeBottom;

      return Transform.translate(
        offset: Offset(x, y),
        child: child,
      );
    }
    return child;
  }
}

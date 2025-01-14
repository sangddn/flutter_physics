import 'package:flutter/widgets.dart';

import '../animated_widgets/animated_widgets.dart';
import '../simulations/physics_simulations.dart';

/// The physics-based version of [FlutterLogo].
class FlutterPhysicsLogo extends StatelessWidget {
  /// Creates a [FlutterLogo] that animates with physics.
  const FlutterPhysicsLogo({
    super.key,
    this.size,
    this.textColor = const Color(0xFF757575),
    this.style = FlutterLogoStyle.markOnly,
    this.duration,
    this.physics,
  });

  /// The size of the logo in logical pixels.
  ///
  /// The logo will be fit into a square this size.
  ///
  /// Defaults to the current [IconTheme] size, if any. If there is no
  /// [IconTheme], or it does not specify an explicit size, then it defaults to
  /// 24.0.
  final double? size;

  /// The color used to paint the "Flutter" text on the logo, if [style] is
  /// [FlutterLogoStyle.horizontal] or [FlutterLogoStyle.stacked].
  ///
  /// If possible, the default (a medium grey) should be used against a white
  /// background.
  final Color textColor;

  /// Whether and where to draw the "Flutter" text. By default, only the logo
  /// itself is drawn.
  final FlutterLogoStyle style;

  /// The length of time for the animation if the [style] or [textColor]
  /// properties are changed.
  final Duration? duration;

  /// The curve for the logo animation if the [style] or [textColor] change.
  final Physics? physics;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconSize = size ?? iconTheme.size;
    return AContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      physics: physics ?? Spring.buoyant,
      decoration: FlutterLogoDecoration(
        style: style,
        textColor: textColor,
      ),
    );
  }
}

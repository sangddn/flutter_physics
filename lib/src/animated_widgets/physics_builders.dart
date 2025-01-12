import 'package:flutter/widgets.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physics_simulations.dart';
import 'a_state.dart';

/// A wrapper around [AState] that simplifies the creation of physics-based
/// animations for a single [double] value.
///
/// {@macro a_state}
class PhysicsBuilder extends StatelessWidget {
  const PhysicsBuilder({
    required this.physics,
    required this.value,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.builder,
    this.child,
    super.key,
  });

  final PhysicsSimulation physics;
  final double value;
  final double lowerBound;
  final double upperBound;
  final ValueWidgetBuilder<double> builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => AState.double(
        physics: physics,
        value: value,
        normalize: (double value) =>
            (value - lowerBound) / (upperBound - lowerBound),
        lowerBound: lowerBound,
        upperBound: upperBound,
        builder: builder,
        child: child,
      );
}

/// A widget that smoothly animates between different 2D positions using physics-based
/// animations, represented as [Offset] values.
///
/// This widget provides a simplified way to create physics-based animations for
/// two-dimensional movement, allowing independent physics simulations for both
/// x and y coordinates.
///
/// {@template physics_builder_2d}
/// When the [value] changes, the widget will animate to the new position using
/// the specified physics simulations. You can provide different physics for each
/// axis using [xPhysics] and [yPhysics], or use the same physics for both by
/// specifying just one of them.
///
/// The animation is constrained between [lowerBound] and [upperBound], which
/// define the valid range for both x and y coordinates.
///
/// {@tool snippet}
/// This example shows how to create a draggable object with spring physics:
///
/// ```dart
/// PhysicsBuilder2D(
///   value: position,
///   xPhysics: Spring.gentle,
///   yPhysics: Spring.bouncy,
///   lowerBound: Offset.zero,
///   upperBound: const Offset(100.0, 100.0),
///   builder: (context, value, child) => Positioned(
///     left: value.dx,
///     top: value.dy,
///     child: child!,
///   ),
///   child: const FlutterLogo(),
/// )
/// ```
/// {@end-tool}
///
/// You can also provide initial velocity for the animation using [velocityDelta],
/// which is particularly useful when implementing gesture-based interactions.
///
/// See also:
///
///  * [PhysicsBuilder], which provides similar functionality for single-dimensional values
///  * [PhysicsSimulation], the base class for physics-based animations
///  * [Spring], a common physics simulation for natural-feeling animations
/// {@endtemplate}
class PhysicsBuilder2D extends StatefulWidget {
  const PhysicsBuilder2D({
    this.xPhysics,
    this.yPhysics,
    required this.value,
    this.velocityDelta = Offset.zero,
    this.lowerBound = Offset.zero,
    this.upperBound = const Offset(1.0, 1.0),
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  });

  /// The physics simulation to use for the x-axis animation.
  ///
  /// If null, [yPhysics] will be used. If both are null, [Spring.elegant]
  /// will be used as the default.
  final PhysicsSimulation? xPhysics;

  /// The physics simulation to use for the y-axis animation.
  ///
  /// If null, [xPhysics] will be used. If both are null, [Spring.elegant]
  /// will be used as the default.
  final PhysicsSimulation? yPhysics;

  /// The target position to animate to.
  final Offset value;

  /// The initial velocity to apply to the animation when [value] changes.
  ///
  /// This is particularly useful for gesture-based interactions where you want
  /// to preserve the momentum of a drag or fling gesture.
  final Offset velocityDelta;

  /// The minimum x and y coordinates for the animation.
  final Offset lowerBound;

  /// The maximum x and y coordinates for the animation.
  final Offset upperBound;

  /// Optional fixed duration for the animation.
  ///
  /// Note: Setting a fixed duration may result in unnatural motion as it
  /// overrides the physics simulation's natural timing. For most natural-looking
  /// animations, leave this null and let the physics simulation determine
  /// the duration.
  final Duration? duration;

  /// Optional fixed duration for the reverse animation.
  ///
  /// If null and [duration] is specified, [duration] will be used.
  /// Note: Like [duration], setting this may result in unnatural motion.
  final Duration? reverseDuration;

  /// Called when the target [value] changes.
  final ValueChanged<Offset>? onValueChanged;

  /// Called when the animation completes.
  final VoidCallback? onEnd;

  /// Builder function that constructs the widget tree based on the current
  /// animated position.
  final ValueWidgetBuilder<Offset> builder;

  /// Optional child widget that will be passed to [builder].
  final Widget? child;

  @override
  State<PhysicsBuilder2D> createState() => _PhysicsBuilder2DState();
}

class _PhysicsBuilder2DState extends State<PhysicsBuilder2D>
    with SingleTickerProviderStateMixin {
  late final _controller = PhysicsController2D(
    vsync: this,
    value: widget.value,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
    lowerBound: widget.lowerBound,
    upperBound: widget.upperBound,
  );

  Simulation2D _getPhysics() => Simulation2D(
        widget.xPhysics ?? widget.yPhysics ?? Spring.elegant,
        widget.yPhysics ?? widget.xPhysics ?? Spring.elegant,
      );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onEnd?.call();
      }
    });
  }

  @override
  void didUpdateWidget(PhysicsBuilder2D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.onValueChanged?.call(widget.value);
      _controller.animateTo(
        widget.value,
        velocityDelta: widget.velocityDelta,
        physics: _getPhysics(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            widget.builder(context, _controller.value, child),
        child: widget.child,
      );
}

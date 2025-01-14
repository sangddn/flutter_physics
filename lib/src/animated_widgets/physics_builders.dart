import 'package:flutter/widgets.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physics_simulations.dart';
import 'a_value.dart';

/// {@template physics_builder}
/// A purely physics-based equivalent of [AValue.double] that simplifies the
/// physics-based animation of a single [double] value.
///
/// As opposed to [AValue.double]:
/// * [PhysicsBuilder] only supports physics simulations ([PhysicsSimulation]).
/// * Supports velocity delta and velocity override for gesture-driven
///   interactions.
/// {@endtemplate}
class PhysicsBuilder extends StatefulWidget {
  /// Creates a physics-based animation for a single [double] value.
  /// {@macro physics_builder}
  const PhysicsBuilder({
    this.physics,
    required this.value,
    this.lowerBound = double.negativeInfinity,
    this.upperBound = double.infinity,
    this.velocityDelta = 0.0,
    this.velocityOverride,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : assert(
          lowerBound <= upperBound,
          'Lower bound must be less than or equal to upper bound',
        ),
        assert(
          value >= lowerBound && value <= upperBound,
          'Value must be within the bounds',
        );

  /// The physics simulation to use for the animation.
  ///
  /// If null, [Spring.gentle] will be used as the default.
  final PhysicsSimulation? physics;

  /// The target value to animate to.
  final double value;

  /// The minimum value for the animation.
  final double lowerBound;

  /// The maximum value for the animation.
  final double upperBound;

  /// The velocity delta to apply to the animation when [value] changes.
  final double velocityDelta;

  /// The velocity override to apply to the animation when [value] changes.
  final double? velocityOverride;

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
  final ValueChanged<double>? onValueChanged;

  /// Called when the animation completes.
  final VoidCallback? onEnd;

  /// Builder function that constructs the widget tree based on the current
  /// animated value.
  final ValueWidgetBuilder<double> builder;

  /// Optional child widget that will be passed to [builder].
  final Widget? child;

  @override
  State<PhysicsBuilder> createState() => PhysicsBuilderState();
}

class PhysicsBuilderState extends State<PhysicsBuilder>
    with SingleTickerProviderStateMixin {
  late final controller = PhysicsController(
    vsync: this,
    value: widget.value,
    lowerBound: widget.lowerBound,
    upperBound: widget.upperBound,
    defaultPhysics: widget.physics,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
  );

  @override
  void initState() {
    super.initState();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onEnd?.call();
      }
    });
  }

  @override
  void didUpdateWidget(PhysicsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.onValueChanged?.call(widget.value);
      controller.animateTo(
        widget.value,
        velocityDelta: widget.velocityDelta,
        velocityOverride: widget.velocityOverride,
        physics: widget.physics,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) =>
          widget.builder(context, controller.value, child),
      child: widget.child,
    );
  }
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
    this.velocityOverride,
    this.lowerBound =
        const Offset(double.negativeInfinity, double.negativeInfinity),
    this.upperBound = Offset.infinite,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : assert(
          lowerBound <= upperBound,
          'Lower bound must be less than or equal to upper bound',
        ),
        assert(
          value >= lowerBound && value <= upperBound,
          'Value must be within the bounds',
        );

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

  /// The velocity delta to apply to the animation when [value] changes.
  ///
  /// This is particularly useful for gesture-based interactions where you want
  /// to preserve the momentum of a drag or fling gesture.
  final Offset velocityDelta;

  /// The velocity override to apply to the animation when [value] changes.
  ///
  /// This is particularly useful for gesture-based interactions where you want
  /// to preserve the momentum of a drag or fling gesture.
  final Offset? velocityOverride;

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
  State<PhysicsBuilder2D> createState() => PhysicsBuilder2DState();
}

class PhysicsBuilder2DState extends State<PhysicsBuilder2D>
    with SingleTickerProviderStateMixin {
  late final controller = PhysicsController2D(
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
    controller.addStatusListener((status) {
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
      controller.animateTo(
        widget.value,
        velocityDelta: widget.velocityDelta,
        velocityOverride: widget.velocityOverride,
        physics: _getPhysics(),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) =>
            widget.builder(context, controller.value, child),
        child: widget.child,
      );
}

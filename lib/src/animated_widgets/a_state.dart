import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physical_simulations.dart';

/// A widget that smoothly animates between different values of type [T] whenever
/// the value changes, using either standard curves or physics-based animations.
///
/// This widget provides a flexible way to animate various types of values with
/// built-in support for common Flutter types through named constructors:
///
/// * [AState.double] for animating numeric values
/// * [AState.color] for animating colors
/// * [AState.size] for animating sizes
/// * [AState.offset] for animating positions
/// * [AState.rect] for animating rectangles
/// * [AState.alignment] for animating alignments
///
/// {@template a_state}
/// When using a standard [Curve], you must provide a [duration]. When using a
/// [PhysicsSimulation], the duration is determined by the simulation itself.
///
/// The [normalize] parameter is required to convert your value to a double between
/// [lowerBound] and [upperBound] for animation purposes. This allows the widget to
/// properly animate between any type of value.
///
/// {@tool snippet}
/// This example shows how to animate a color with spring physics:
///
/// ```dart
/// AState.color(
///   value: _color,
///   physics: Spring.withDamping(
///     mass: 1.0,
///     damping: 0.7,
///   ),
///   normalize: (color) => color.opacity,
///   builder: (context, value, child) => Container(
///     color: value,
///     child: child,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to animate a custom value using the default constructor:
///
/// ```dart
/// AState<MyCustomType>(
///   value: _customValue,
///   lerp: (a, b, t) => MyCustomType.lerp(a, b, t),
///   normalize: (value) => value.progress,
///   physics: Spring.snap,
///   builder: (context, value, child) => CustomWidget(
///     value: value,
///     child: child,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TweenAnimationBuilder], which provides similar functionality but only with curve-based animations
///  * [PhysicsSimulation], the base class for physics-based animations
///  * [Spring], a common physics simulation for natural-feeling animations
///  * [ASize], a specialized version for size animations
/// {@endtemplate}
class AState<T> extends StatefulWidget {
  const AState({
    required this.value,
    required this.lerp,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  });

  /// Creates a widget that animates double values.
  /// {@macro a_state}
  const AState.double({
    required this.value,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpDouble as T Function(T, T, double);

  /// Creates a widget that animates between colors.
  /// {@macro a_state}
  const AState.color({
    required this.value,
    this.physics,
    this.duration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpColor as T Function(T, T, double);

  /// Creates a widget that animates between sizes.
  /// {@macro a_state}
  const AState.size({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpSize as T Function(T, T, double);

  /// Creates a widget that animates between positions.
  /// {@macro a_state}
  const AState.offset({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpOffset as T Function(T, T, double);

  /// Creates a widget that animates between rectangles.
  /// {@macro a_state}
  const AState.rect({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpRect as T Function(T, T, double);

  /// Creates a widget that animates between alignments.
  /// {@macro a_state}
  const AState.alignment({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required this.normalize,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  }) : lerp = AState.lerpAlignment as T Function(T, T, double);

  /// The current value to animate to.
  final T value;

  /// Function that defines how to interpolate between two values of type [T].
  final T Function(T, T, double) lerp;

  /// Called whenever the value changes.
  final ValueChanged<T>? onValueChanged;

  /// Called when the animation completes.
  final VoidCallback? onEnd;

  /// The minimum value for the animation's progress.
  final double lowerBound;

  /// The maximum value for the animation's progress.
  final double upperBound;

  /// Converts a value of type [T] to a progress value between [lowerBound] and [upperBound].
  final double Function(T) normalize;

  /// The physics simulation or curve to use for the animation.
  ///
  /// Can be either a standard [Curve] or a [PhysicsSimulation] like [Spring].
  /// When using a [Curve], [duration] must be provided.
  final Physics? physics;

  /// The duration for the animation when using curve-based physics.
  ///
  /// Required when [physics] is a [Curve], ignored when using [PhysicsSimulation].
  final Duration? duration;

  /// The reverse duration for the animation when using curve-based physics.
  ///
  /// If null, [duration] is used instead.
  final Duration? reverseDuration;

  /// Builder function that constructs the widget tree based on the animated value.
  final ValueWidgetBuilder<T> builder;

  /// Optional child widget that will be passed to [builder].
  final Widget? child;

  static double lerpDouble(double a, double b, double t) =>
      ui.lerpDouble(a, b, t)!;
  static Color lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  static Size lerpSize(Size a, Size b, double t) => Size.lerp(a, b, t)!;
  static Offset lerpOffset(Offset a, Offset b, double t) =>
      Offset.lerp(a, b, t)!;
  static Rect lerpRect(Rect a, Rect b, double t) => Rect.lerp(a, b, t)!;
  static AlignmentGeometry lerpAlignment(
    AlignmentGeometry a,
    AlignmentGeometry b,
    double t,
  ) =>
      AlignmentGeometry.lerp(a, b, t)!;

  @override
  State<AState<T>> createState() => _AStateState<T>();
}

class _AStateState<T> extends State<AState<T>>
    with SingleTickerProviderStateMixin {
  late final _controller = PhysicsController(
    vsync: this,
    value: widget.normalize.call(widget.value),
    lowerBound: widget.lowerBound,
    upperBound: widget.upperBound,
    defaultPhysics: widget.physics,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
  );

  late T _previousValue = _value;
  late T _value = widget.value;

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
  void didUpdateWidget(AState<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.onValueChanged?.call(widget.value);
      _previousValue = oldWidget.value;
      _value = widget.value;
      _controller.animateTo(widget.normalize.call(_value));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.lerp(_previousValue, _value, _controller.value);
        return widget.builder(context, value, child);
      },
      child: widget.child,
    );
  }
}

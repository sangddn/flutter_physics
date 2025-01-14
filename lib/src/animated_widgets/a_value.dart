import 'package:flutter/widgets.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physics_simulations.dart';

typedef Normalize<T> = List<double> Function(T);
typedef Denormalize<T> = T Function(List<double>);

/// A widget that smoothly animates between different values of type [T] whenever
/// the value changes, using either standard curves or physics-based animations.
///
/// This widget provides a flexible way to animate various types of values with
/// built-in support for common Flutter types through named constructors:
/// 
/// * [AValue.double] for animating numeric values
/// * [AValue.color] for animating colors
/// * [AValue.size] for animating sizes
/// * [AValue.offset] for animating positions
/// * [AValue.rect] for animating rectangles
/// * [AValue.alignment] for animating alignments
///
/// {@template a_state}
/// When using a standard [Curve], you must provide a [duration]. When using a
/// [PhysicsSimulation], the duration can be left `null` so the simulation itself
/// determines the duration.
///
/// {@tool snippet}
/// This example shows how to animate a custom value using the default constructor:
///
/// ```dart
/// AValue<MyCustomType>(
///   value: _customValue,
///   normalizeOutputLength: 1,
///   normalize: (value) => [value.progress],
///   denormalize: (value) => MyCustomType(progress: value[0]),
///   physics: Spring.snap,
///   builder: (context, value, child) => CustomWidget(
///     value: value,
///     child: child,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example shows how to animate a color with a spring physics simulation:
/// 
/// ```dart
/// AValue.color(
///   value: _color,
///   physics: Spring.withDamping(
///     mass: 1.0,
///     damping: 0.7,
///   ),
///   builder: (context, value, child) => Container(
///     color: value,
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
///  * [ASize], a specialized version for size animations that animates width and height
///    at layout
/// {@endtemplate}
class AValue<T> extends StatefulWidget {
  const AValue({
    required this.value,
    required this.normalizeOutputLength,
    required this.normalize,
    required this.denormalize,
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
  const AValue.double({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeDouble as List<double> Function(T),
        denormalize = AValue.denormalizeDouble as T Function(List<double>),
        normalizeOutputLength = 1;

  /// Creates a widget that animates between colors.
  /// {@macro a_state}
  const AValue.color({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeColor as Normalize<T>,
        denormalize = AValue.denormalizeColor as Denormalize<T>,
        normalizeOutputLength = 4;

  /// Creates a widget that animates between sizes.
  /// {@macro a_state}
  const AValue.size({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeSize as Normalize<T>,
        denormalize = AValue.denormalizeSize as Denormalize<T>,
        normalizeOutputLength = 2;

  /// Creates a widget that animates between positions.
  /// {@macro a_state}
  const AValue.offset({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeOffset as Normalize<T>,
        denormalize = AValue.denormalizeOffset as Denormalize<T>,
        normalizeOutputLength = 2;

  /// Creates a widget that animates between rectangles.
  /// {@macro a_state}
  const AValue.rect({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeRect as Normalize<T>,
        denormalize = AValue.denormalizeRect as Denormalize<T>,
        normalizeOutputLength = 4;

  /// Creates a widget that animates between alignments.
  /// {@macro a_state}
  const AValue.alignment({
    required this.value,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.onValueChanged,
    this.onEnd,
    required this.builder,
    this.child,
    super.key,
  })  : normalize = AValue.normalizeAlignment as Normalize<T>,
        denormalize = AValue.denormalizeAlignment as Denormalize<T>,
        normalizeOutputLength = 2;

  /// The current value to animate to.
  final T value;

  /// Called whenever the value changes.
  final ValueChanged<T>? onValueChanged;

  /// Called when the animation completes.
  final VoidCallback? onEnd;

  /// Converts a value of type [T] to a list of double values.
  final Normalize<T> normalize;

  /// Converts a list of double values back to a value of type [T].
  final Denormalize<T> denormalize;

  /// The number of dimensions in the output of [normalize].
  final int normalizeOutputLength;

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

  static List<double> normalizeDouble(double value) => [value];
  static double denormalizeDouble(List<double> value) => value[0];
  static List<double> normalizeColor(Color value) =>
      [value.r, value.g, value.b, value.a];
  static Color denormalizeColor(List<double> value) => Color.from(
        alpha: value[3],
        red: value[0],
        green: value[1],
        blue: value[2],
      );
  static List<double> normalizeSize(Size value) => [value.width, value.height];
  static Size denormalizeSize(List<double> value) => Size(value[0], value[1]);
  static List<double> normalizeOffset(Offset value) => [value.dx, value.dy];
  static Offset denormalizeOffset(List<double> value) =>
      Offset(value[0], value[1]);
  static List<double> normalizeRect(Rect value) =>
      [value.left, value.top, value.right, value.bottom];
  static Rect denormalizeRect(List<double> value) => Rect.fromPoints(
        Offset(value[0], value[1]),
        Offset(value[2], value[3]),
      );
  static List<double> normalizeAlignment(Alignment value) => [value.x, value.y];
  static Alignment denormalizeAlignment(List<double> value) =>
      Alignment(value[0], value[1]);

  @override
  State<AValue<T>> createState() => _AValueState<T>();
}

class _AValueState<T> extends State<AValue<T>>
    with SingleTickerProviderStateMixin {
  late PhysicsControllerMulti _controller;

  @override
  void initState() {
    super.initState();
    assert(
      widget.normalize(widget.value).length == widget.normalizeOutputLength,
      'Value must be within the bounds',
    );
    _controller = PhysicsControllerMulti.unbounded(
      vsync: this,
      dimensions: widget.normalizeOutputLength,
      value: widget.normalize(widget.value),
      defaultPhysicsForAllDimensions: widget.physics,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onEnd?.call();
      }
    });
  }

  @override
  void didUpdateWidget(AValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.normalizeOutputLength != oldWidget.normalizeOutputLength) {
      _controller.dispose();
      _controller = PhysicsControllerMulti.unbounded(
        vsync: this,
        dimensions: widget.normalizeOutputLength,
        value: widget.normalize(widget.value),
        defaultPhysicsForAllDimensions: widget.physics,
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
      );
    }
    if (widget.duration != oldWidget.duration ||
        widget.reverseDuration != oldWidget.reverseDuration) {
      _controller.duration = widget.duration;
      _controller.reverseDuration = widget.reverseDuration;
    }
    if (widget.physics != oldWidget.physics) {
      _controller.defaultPhysics = List.filled(
        widget.normalizeOutputLength,
        widget.physics ?? Spring.elegant,
      );
    }
    if (widget.value != oldWidget.value) {
      widget.onValueChanged?.call(widget.value);
      _controller.animateTo(widget.normalize(widget.value));
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
        assert(_controller.value.length == widget.normalizeOutputLength);
        final value = widget.denormalize(_controller.value);
        return widget.builder(context, value, child);
      },
      child: widget.child,
    );
  }
}

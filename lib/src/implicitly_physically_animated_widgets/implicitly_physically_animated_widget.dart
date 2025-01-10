// This file defines a physics-first equivalent of Flutter's ImplicitlyAnimatedWidget
// system, using a PhysicsController instead of AnimationController.
// It also provides all out-of-the-box variants like Container, Padding, Align, etc.,
// but renamed as AContainer, APadding, AAlign, etc., to avoid conflicts with Flutter.
//
// The general pattern is similar: each widget is an ImplicitlyPhysicallyAnimatedWidget
// subclass, and each state is a PhysicallyAnimatedWidgetBaseState that uses a
// PhysicsController to drive changes.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide
        AnimatedContainer,
        AnimatedPadding,
        AnimatedAlign,
        AnimatedPositioned,
        AnimatedPositionedDirectional,
        AnimatedScale,
        AnimatedRotation,
        AnimatedSlide,
        AnimatedOpacity,
        AnimatedDefaultTextStyle,
        AnimatedFractionallySizedBox,
        AnimatedPhysicalModel,
        SliverAnimatedOpacity;
import 'package:flutter_physics/flutter_physics.dart';

// ---------------------------------------------------------------------------
// ImplicitlyPhysicallyAnimatedWidget and its State
// ---------------------------------------------------------------------------

/// A base class resembling `ImplicitlyAnimatedWidget` driven by a [PhysicsController].
///
/// Instead of providing a [curve] and [duration], you typically provide
/// a [Duration] (or override the built-in [duration]) and possibly a custom [Physics].
/// The rest of the pattern is analogous to ImplicitlyAnimatedWidget.
abstract class ImplicitlyPhysicallyAnimatedWidget extends StatefulWidget {
  const ImplicitlyPhysicallyAnimatedWidget({
    super.key,
    required this.duration,
    this.physics,
    this.onEnd,
  });

  /// The length of time this "implicit" animation should last, unless overridden.
  /// This is used as the default for the [PhysicsController]'s forward or reverse calls.
  final Duration duration;

  /// If non-null, the [Physics] to use for transitions.
  /// Defaults to [Spring.defaultElegant] if not provided.
  final Physics? physics;

  /// Called every time an animation completes.
  final VoidCallback? onEnd;
}

/// Signature for a "property visitor" that, given an old tween and a new target,
/// returns a new or updated tween. Adapted from Flutter's TweenVisitor.
typedef PhysicsTweenVisitor<T extends Object> = Tween<T>? Function(
  Tween<T>? tween,
  T targetValue,
  TweenConstructor<T> constructor,
);

/// Signature for a factory function that creates a new `Tween<T>` given the initial value.
typedef TweenConstructor<T extends Object> = Tween<T> Function(T value);

/// A base state class that uses a [PhysicsController] instead of an [AnimationController].
/// Subclass this if you want to rebuild on each tick (like `AnimatedWidgetBaseState`).
///
/// To animate changes to your widget's fields, store `Tween` objects in your
/// subclass state. Override [forEachTween] to create/update these tweens
/// whenever new values come in from the updated widget. Then rely on the
/// physics-driven controller to update [animation] over time, and `setState` is
/// called automatically whenever the physics ticks.
abstract class PhysicallyAnimatedWidgetState<
        T extends ImplicitlyPhysicallyAnimatedWidget> extends State<T>
    with SingleTickerProviderStateMixin<T> {
  late final PhysicsController _controller;
  late Animation<double> _animation;

  /// The main animation that this state uses. Typically used to evaluate tweens.
  Animation<double> get animation => _animation;

  /// Exposes the underlying [PhysicsController].
  PhysicsController get controller => _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the physics controller
    _controller = PhysicsController(
      vsync: this,
      duration: widget.duration,
      defaultPhysics:
          widget.physics, // can be null => defaults in the constructor
    );

    // Listen for completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        widget.onEnd?.call();
      }
    });

    // We'll drive a simple [Curves.linear] style interpolation on top of the
    // physics value (0..1). If you want custom progress transforms, you can
    // override or do something else. For typical usage, we just let the
    // [controller]'s value go from 0 to 1 linearly by default. For more advanced
    // usage, you could do your own hooking here.
    _animation = _controller;
    _constructTweens();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If duration changed, we update the controller's duration
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // If user provided a new physics, we might want to re-sync or forcibly adapt it.
    // We'll just store it as defaultPhysics. Next animation will pick it up.
    if (widget.physics != oldWidget.physics) {
      // There's no direct "set defaultPhysics" but we can do:
      // We could re-create the controller, or just store it. We'll do a hack:
      _controller.stop();
      _controller.dispose();
      _recreateController();
    }

    if (_constructTweens()) {
      // Something changed => we do a forward from 0..1 or some approach
      // The simplest approach is: always re-run from 0..1
      _controller.stop();
      _controller.value = 0;
      _controller.forward();
      didUpdateTweens();
    }
  }

  void _recreateController() {
    final oldValue = _controller.value;
    final oldStatus = _controller.status;
    _controller.removeStatusListener(_handleStatusChange);

    final newController = PhysicsController(
      vsync: this,
      duration: widget.duration,
      defaultPhysics: widget.physics,
    );
    newController.addStatusListener(_handleStatusChange);
    // Attempt to preserve the old progress
    newController.value = oldValue;
    if (oldStatus == AnimationStatus.forward ||
        oldStatus == AnimationStatus.reverse) {
      newController.forward();
    }
    _controller = newController;
    _animation = _controller;
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _constructTweens() {
    // Subclasses must implement [forEachTween].
    // We'll pass them a "visitor" that checks if something changed.
    bool somethingChanged = false;
    forEachTween((tween, targetValue, constructor) {
      // If there's no target, we discard the tween
      if (targetValue == null) {
        if (tween != null) {
          somethingChanged = true;
          return null;
        } else {
          return null;
        }
      }
      // If the tween is null, create a new one => definitely changed
      if (tween == null) {
        somethingChanged = true;
        return constructor(targetValue);
      }
      // If the new target is different from the old end, we update
      if (tween.end != targetValue) {
        somethingChanged = true;
        tween.begin = tween.evaluate(animation);
        tween.end = targetValue;
      }
      return tween;
    });
    return somethingChanged;
  }

  /// Called after the tweens have been updated. Override this if needed.
  @protected
  void didUpdateTweens() {}

  /// Subclasses must override this to create/update tweens for each animated property.
  ///
  /// This is analogous to `AnimatedWidgetBaseState.forEachTween`.
  @protected
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor);
}

/// A mixin that rebuilds the state on each tick of the physics controller.
/// This is useful for widgets that need to rebuild on each tick, like [AContainer].
mixin _RebuildOnTick<T extends ImplicitlyPhysicallyAnimatedWidget> on State<T> {
  PhysicsController get _controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleAnimationChanged);
  }

  void _handleAnimationChanged() {
    setState(() {/* The animation ticked. Rebuild with new animation value */});
  }
}

/// Physics-based equivalent of [AnimatedContainer], renamed to [AContainer].
class AContainer extends ImplicitlyPhysicallyAnimatedWidget {
  const AContainer({
    super.key,
    required super.duration,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    this.constraints,
    this.padding,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
    this.child,
    super.physics,
    super.onEnd,
  });

  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;
  final Widget? child;

  @override
  State<AContainer> createState() => _AContainerState();
}

class _AContainerState extends PhysicallyAnimatedWidgetState<AContainer>
    with _RebuildOnTick {
  DecorationTween? _decoration;
  DecorationTween? _foregroundDecoration;
  AlignmentGeometryTween? _alignment;
  BoxConstraintsTween? _constraints;
  EdgeInsetsGeometryTween? _padding;
  EdgeInsetsGeometryTween? _margin;
  Matrix4Tween? _transform;
  AlignmentGeometryTween? _transformAlignment;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _decoration = visitor(_decoration, widget.decoration,
            (value) => DecorationTween(begin: value as Decoration?))
        as DecorationTween?;
    _foregroundDecoration = visitor(
            _foregroundDecoration,
            widget.foregroundDecoration,
            (value) => DecorationTween(begin: value as Decoration?))
        as DecorationTween?;
    _alignment = visitor(
            _alignment,
            widget.alignment,
            (value) =>
                AlignmentGeometryTween(begin: value as AlignmentGeometry?))
        as AlignmentGeometryTween?;
    _constraints = visitor(_constraints, widget.constraints,
            (value) => BoxConstraintsTween(begin: value as BoxConstraints?))
        as BoxConstraintsTween?;
    _padding = visitor(
            _padding,
            widget.padding,
            (value) =>
                EdgeInsetsGeometryTween(begin: value as EdgeInsetsGeometry?))
        as EdgeInsetsGeometryTween?;
    _margin = visitor(
            _margin,
            widget.margin,
            (value) =>
                EdgeInsetsGeometryTween(begin: value as EdgeInsetsGeometry?))
        as EdgeInsetsGeometryTween?;
    _transform = visitor(_transform, widget.transform,
        (value) => Matrix4Tween(begin: value as Matrix4?)) as Matrix4Tween?;
    _transformAlignment = visitor(
            _transformAlignment,
            widget.transformAlignment,
            (value) =>
                AlignmentGeometryTween(begin: value as AlignmentGeometry?))
        as AlignmentGeometryTween?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<DecorationTween>(
        'decoration', _decoration,
        defaultValue: null));
    description.add(DiagnosticsProperty<DecorationTween>(
        'foregroundDecoration', _foregroundDecoration,
        defaultValue: null));
    description.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'alignment', _alignment,
        defaultValue: null));
    description.add(DiagnosticsProperty<BoxConstraintsTween>(
        'constraints', _constraints,
        defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'padding', _padding,
        defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'margin', _margin,
        defaultValue: null));
    description
        .add(ObjectFlagProperty<Matrix4Tween>.has('transform', _transform));
    description.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'transformAlignment', _transformAlignment,
        defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final animation = this.animation;
    return Padding(
      padding: _margin!.evaluate(animation),
      child: Container(
        decoration: _decoration?.evaluate(animation),
        foregroundDecoration: _foregroundDecoration?.evaluate(animation),
        alignment: _alignment?.evaluate(animation),
        constraints: _constraints?.evaluate(animation),
        transform: _transform?.evaluate(animation),
        transformAlignment: _transformAlignment?.evaluate(animation),
        clipBehavior: widget.clipBehavior,
        child: Padding(
          padding: _padding!.evaluate(animation),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Physics-based equivalent of [AnimatedPadding], renamed to [APadding].
class APadding extends ImplicitlyPhysicallyAnimatedWidget {
  const APadding({
    super.key,
    required this.padding,
    required super.duration,
    super.physics,
    this.child,
    super.onEnd,
  });

  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  State<APadding> createState() => _APaddingState();
}

class _APaddingState extends PhysicallyAnimatedWidgetState<APadding>
    with _RebuildOnTick {
  EdgeInsetsGeometryTween? _padding;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _padding = visitor(
      _padding,
      widget.padding,
      (value) => EdgeInsetsGeometryTween(begin: value as EdgeInsetsGeometry),
    ) as EdgeInsetsGeometryTween?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'padding', _padding,
        defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final padding = _padding!.evaluate(animation);
    return _Padding(padding: padding, child: widget.child);
  }
}

class _Padding extends StatelessWidget {
  const _Padding({required this.padding, required this.child});

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
    final effectivePadding = padding.resolve(Directionality.of(context));
    final negativeTop = effectivePadding.top < 0 ? effectivePadding.top : 0;
    final negativeLeft = effectivePadding.left < 0 ? effectivePadding.left : 0;
    final negativeRight =
        effectivePadding.right < 0 ? effectivePadding.right : 0;
    final negativeBottom =
        effectivePadding.bottom < 0 ? effectivePadding.bottom : 0;
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
      final x = -negativeLeft + -negativeRight;

      // For vertical direction:
      // - negative top padding should move content up (-y)
      // - negative bottom padding should move content down (+y)
      final y = -negativeTop + -negativeBottom;

      return Transform.translate(
        offset: Offset(x.toDouble(), y.toDouble()),
        child: child,
      );
    }
    return child;
  }
}

/// Physics-based equivalent of [AnimatedAlign], renamed to [AAlign].
class AAlign extends ImplicitlyPhysicallyAnimatedWidget {
  const AAlign({
    super.key,
    required this.alignment,
    this.child,
    this.heightFactor,
    this.widthFactor,
    required super.duration,
    super.physics,
    super.onEnd,
  });

  final AlignmentGeometry alignment;
  final Widget? child;
  final double? heightFactor;
  final double? widthFactor;

  @override
  State<AAlign> createState() => _AAlignState();
}

class _AAlignState extends PhysicallyAnimatedWidgetState<AAlign>
    with _RebuildOnTick {
  AlignmentGeometryTween? _alignment;
  Tween<double>? _heightFactor;
  Tween<double>? _widthFactor;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _alignment = visitor(
            _alignment,
            widget.alignment,
            (dynamic value) =>
                AlignmentGeometryTween(begin: value as AlignmentGeometry))
        as AlignmentGeometryTween?;
    _heightFactor = visitor(_heightFactor, widget.heightFactor,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
    _widthFactor = visitor(_widthFactor, widget.widthFactor,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'alignment', _alignment,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Tween<double>>(
        'widthFactor', _widthFactor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Tween<double>>(
        'heightFactor', _heightFactor,
        defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _alignment?.evaluate(animation) ?? widget.alignment,
      heightFactor: (_heightFactor?.evaluate(animation) ?? widget.heightFactor)
          ?.clamp(0.0, double.infinity),
      widthFactor: (_widthFactor?.evaluate(animation) ?? widget.widthFactor)
          ?.clamp(0.0, double.infinity),
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedPositioned], renamed to [APositioned].
/// Only works if it's the child of a [Stack].
class APositioned extends ImplicitlyPhysicallyAnimatedWidget {
  const APositioned({
    super.key,
    required super.duration,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
    super.physics,
    super.onEnd,
  });

  final Widget child;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;

  @override
  State<APositioned> createState() => _APositionedState();
}

class _APositionedState extends PhysicallyAnimatedWidgetState<APositioned>
    with _RebuildOnTick {
  Tween<double>? _left;
  Tween<double>? _top;
  Tween<double>? _right;
  Tween<double>? _bottom;
  Tween<double>? _width;
  Tween<double>? _height;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _left = visitor(_left, widget.left,
        (dynamic v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _top = visitor(
            _top, widget.top, (dynamic v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _right = visitor(_right, widget.right,
        (dynamic v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _bottom = visitor(_bottom, widget.bottom,
        (dynamic v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _width = visitor(_width, widget.width,
        (dynamic v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _height = visitor(_height, widget.height,
        (dynamic v) => Tween<double>(begin: v as double)) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left?.evaluate(animation) ?? widget.left,
      top: _top?.evaluate(animation) ?? widget.top,
      right: _right?.evaluate(animation) ?? widget.right,
      bottom: _bottom?.evaluate(animation) ?? widget.bottom,
      width: _width?.evaluate(animation) ?? widget.width,
      height: _height?.evaluate(animation) ?? widget.height,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedPositionedDirectional], renamed to [APositionedDirectional].
/// Only works if it's the child of a [Stack].
class APositionedDirectional extends ImplicitlyPhysicallyAnimatedWidget {
  const APositionedDirectional({
    super.key,
    required super.duration,
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    required this.child,
    super.physics,
    super.onEnd,
  });

  final Widget child;
  final double? start;
  final double? top;
  final double? end;
  final double? bottom;
  final double? width;
  final double? height;

  @override
  State<APositionedDirectional> createState() => _APositionedDirectionalState();
}

class _APositionedDirectionalState
    extends PhysicallyAnimatedWidgetState<APositionedDirectional>
    with _RebuildOnTick {
  Tween<double>? _start;
  Tween<double>? _top;
  Tween<double>? _end;
  Tween<double>? _bottom;
  Tween<double>? _width;
  Tween<double>? _height;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _start =
        visitor(_start, widget.start, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
    _top = visitor(_top, widget.top, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _end = visitor(_end, widget.end, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _bottom = visitor(
            _bottom, widget.bottom, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
    _width =
        visitor(_width, widget.width, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
    _height = visitor(
            _height, widget.height, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      start: _start?.evaluate(animation) ?? widget.start,
      top: _top?.evaluate(animation) ?? widget.top,
      end: _end?.evaluate(animation) ?? widget.end,
      bottom: _bottom?.evaluate(animation) ?? widget.bottom,
      width: _width?.evaluate(animation) ?? widget.width,
      height: _height?.evaluate(animation) ?? widget.height,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedScale], renamed to [AScale].
///
/// Animates its [scale] property using physics-based animations.
/// The [alignment] and [filterQuality] properties are not animated.
class AScale extends ImplicitlyPhysicallyAnimatedWidget {
  const AScale({
    super.key,
    required this.scale,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    required super.duration,
    super.physics,
    super.onEnd,
  });

  final Widget? child;
  final double scale;
  final Alignment alignment;
  final FilterQuality? filterQuality;

  @override
  State<AScale> createState() => _AScaleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('scale', scale));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class _AScaleState extends PhysicallyAnimatedWidgetState<AScale> {
  Tween<double>? _scale;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _scale =
        visitor(_scale, widget.scale, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Tween<double>>('scale', _scale));
  }

  @override
  Widget build(BuildContext context) {
    final double currentScale = _scale?.evaluate(animation) ?? widget.scale;
    return Transform.scale(
      scale: currentScale.clamp(0.0, double.infinity),
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedRotation], renamed to [ARotation].
///
/// Animates its [turns] property using physics-based animations.
/// The [alignment] and [filterQuality] properties are not animated.
class ARotation extends ImplicitlyPhysicallyAnimatedWidget {
  const ARotation({
    super.key,
    required this.turns,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    required super.duration,
    super.physics,
    super.onEnd,
  });

  final Widget? child;
  final double turns;
  final Alignment alignment;
  final FilterQuality? filterQuality;

  @override
  State<ARotation> createState() => _ARotationState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('turns', turns));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class _ARotationState extends PhysicallyAnimatedWidgetState<ARotation> {
  Tween<double>? _turns;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _turns =
        visitor(_turns, widget.turns, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Tween<double>>('turns', _turns));
  }

  @override
  Widget build(BuildContext context) {
    final currentTurns = _turns?.evaluate(animation) ?? widget.turns;
    return Transform.rotate(
      angle: currentTurns * 2.0 * 3.141592653589793,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedSlide], renamed to [ASlide].
///
/// Animates its [offset] property using physics-based animations to slide
/// the child widget relative to its normal position.
class ASlide extends ImplicitlyPhysicallyAnimatedWidget {
  const ASlide({
    super.key,
    required this.offset,
    this.child,
    required super.duration,
    super.physics,
    super.onEnd,
  });

  final Offset offset;
  final Widget? child;

  @override
  State<ASlide> createState() => _ASlideState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }
}

class _ASlideState extends PhysicallyAnimatedWidgetState<ASlide> {
  Tween<Offset>? _offset;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _offset = visitor(
            _offset, widget.offset, (v) => Tween<Offset>(begin: v as Offset))
        as Tween<Offset>?;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Tween<Offset>>('offset', _offset));
  }

  @override
  Widget build(BuildContext context) {
    final value = _offset?.evaluate(animation) ?? widget.offset;
    return FractionalTranslation(
      translation: value,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedOpacity], renamed to [AOpacity].
///
/// Animates its [opacity] property using physics-based animations.
/// The [alwaysIncludeSemantics] property is not animated.
class AOpacity extends ImplicitlyPhysicallyAnimatedWidget {
  const AOpacity({
    super.key,
    required super.duration,
    required this.opacity,
    this.child,
    this.alwaysIncludeSemantics = false,
    super.physics,
    super.onEnd,
  });

  final double opacity;
  final Widget? child;
  final bool alwaysIncludeSemantics;

  @override
  State<AOpacity> createState() => _AOpacityState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'always include semantics'));
  }
}

class _AOpacityState extends PhysicallyAnimatedWidgetState<AOpacity> {
  Tween<double>? _opacity;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _opacity = visitor(
            _opacity, widget.opacity, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double val = _opacity?.evaluate(animation) ?? widget.opacity;
    return Opacity(
      opacity: val.clamp(0.0, 1.0),
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Tween<double>>('opacity', _opacity));
  }
}

/// Physics-based equivalent of [SliverAnimatedOpacity], renamed to [ASliverOpacity].
///
/// Animates its [opacity] property using physics-based animations.
/// The [alwaysIncludeSemantics] property is not animated.
class ASliverOpacity extends ImplicitlyPhysicallyAnimatedWidget {
  const ASliverOpacity({
    super.key,
    required super.duration,
    required this.opacity,
    this.sliver,
    this.alwaysIncludeSemantics = false,
    super.physics,
    super.onEnd,
  });

  final double opacity;
  final Widget? sliver;
  final bool alwaysIncludeSemantics;

  @override
  State<ASliverOpacity> createState() => _ASliverOpacityState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'always include semantics'));
  }
}

class _ASliverOpacityState
    extends PhysicallyAnimatedWidgetState<ASliverOpacity> {
  Tween<double>? _opacity;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _opacity = visitor(
            _opacity, widget.opacity, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double val = _opacity?.evaluate(animation) ?? widget.opacity;
    return SliverOpacity(
      opacity: val.clamp(0.0, 1.0),
      sliver: widget.sliver,
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Tween<double>>('opacity', _opacity));
  }
}

/// Physics-based equivalent of [AnimatedDefaultTextStyle], renamed to [ADefaultTextStyle].
///
/// Animates changes in [style] using physics-based animations.
/// Other properties like [textAlign], [softWrap], [overflow], etc. are not animated.
class ADefaultTextStyle extends ImplicitlyPhysicallyAnimatedWidget {
  const ADefaultTextStyle({
    super.key,
    required this.style,
    this.child,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    required super.duration,
    super.physics,
    super.onEnd,
  });

  final TextStyle style;
  final Widget? child;
  final TextAlign? textAlign;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  State<ADefaultTextStyle> createState() => _ADefaultTextStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('style', style));
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters'));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    properties
        .add(EnumProperty<TextWidthBasis>('textWidthBasis', textWidthBasis));
    properties.add(DiagnosticsProperty<TextHeightBehavior>(
        'textHeightBehavior', textHeightBehavior,
        defaultValue: null));
  }
}

class _ADefaultTextStyleState
    extends PhysicallyAnimatedWidgetState<ADefaultTextStyle>
    with _RebuildOnTick {
  TextStyleTween? _style;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _style = visitor(
            _style, widget.style, (v) => TextStyleTween(begin: v as TextStyle))
        as TextStyleTween?;
  }

  @override
  Widget build(BuildContext context) {
    final s = _style?.evaluate(animation) ?? widget.style;
    return DefaultTextStyle(
      style: s,
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      child: widget.child ?? const SizedBox(),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyleTween>('style', _style));
  }
}

/// Physics-based equivalent of [AnimatedPhysicalModel], renamed to [APhysicalModel].
///
/// Animates [elevation], [color], and [shadowColor] using physics-based animations.
/// The [color] and [shadowColor] animations can be disabled using [animateColor] and
/// [animateShadowColor] respectively.
class APhysicalModel extends ImplicitlyPhysicallyAnimatedWidget {
  const APhysicalModel({
    super.key,
    required super.duration,
    required this.child,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0.0,
    required this.color,
    this.animateColor = true,
    required this.shadowColor,
    this.animateShadowColor = true,
    super.physics,
    super.onEnd,
  }) : assert(elevation >= 0.0);

  final Widget child;
  final BoxShape shape;
  final Clip clipBehavior;
  final BorderRadius? borderRadius;
  final double elevation;
  final Color color;
  final bool animateColor;
  final Color shadowColor;
  final bool animateShadowColor;

  @override
  State<APhysicalModel> createState() => _APhysicalModelState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties
        .add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(FlagProperty('animateColor', value: animateColor));
    properties.add(ColorProperty('shadowColor', shadowColor));
    properties
        .add(FlagProperty('animateShadowColor', value: animateShadowColor));
  }
}

class _APhysicalModelState extends PhysicallyAnimatedWidgetState<APhysicalModel>
    with _RebuildOnTick {
  BorderRadiusTween? _borderRadius;
  Tween<double>? _elevation;
  ColorTween? _color;
  ColorTween? _shadowColor;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(
            _borderRadius,
            widget.borderRadius ?? BorderRadius.zero,
            (v) => BorderRadiusTween(begin: v as BorderRadius))
        as BorderRadiusTween?;
    _elevation = visitor(_elevation, widget.elevation,
        (v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _color = visitor(_color, widget.color, (v) => ColorTween(begin: v as Color))
        as ColorTween?;
    _shadowColor = visitor(_shadowColor, widget.shadowColor,
        (v) => ColorTween(begin: v as Color)) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final colorVal =
        widget.animateColor ? _color?.evaluate(animation) : widget.color;
    final shadowVal = widget.animateShadowColor
        ? _shadowColor?.evaluate(animation)
        : widget.shadowColor;
    return PhysicalModel(
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      borderRadius: _borderRadius?.evaluate(animation),
      elevation: _elevation?.evaluate(animation) ?? widget.elevation,
      color: colorVal ?? widget.color,
      shadowColor: shadowVal ?? widget.shadowColor,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<BorderRadiusTween>('borderRadius', _borderRadius));
    properties.add(DiagnosticsProperty<Tween<double>>('elevation', _elevation));
    properties.add(DiagnosticsProperty<ColorTween>('color', _color));
    properties
        .add(DiagnosticsProperty<ColorTween>('shadowColor', _shadowColor));
  }
}

/// Physics-based equivalent of [AnimatedFractionallySizedBox], renamed to [AFractionallySizedBox].
///
/// Animates [widthFactor] and [heightFactor] using physics-based animations.
/// The [alignment] property is not animated.
class AFractionallySizedBox extends ImplicitlyPhysicallyAnimatedWidget {
  const AFractionallySizedBox({
    super.key,
    required super.duration,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    this.child,
    super.physics,
    super.onEnd,
  });

  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;
  final Widget? child;

  @override
  State<AFractionallySizedBox> createState() => _AFractionallySizedBoxState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor));
    properties.add(DoubleProperty('heightFactor', heightFactor));
  }
}

class _AFractionallySizedBoxState
    extends PhysicallyAnimatedWidgetState<AFractionallySizedBox>
    with _RebuildOnTick {
  AlignmentGeometryTween? _alignment;
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment,
            (v) => AlignmentGeometryTween(begin: v as AlignmentGeometry))
        as AlignmentGeometryTween?;
    _widthFactor = visitor(_widthFactor, widget.widthFactor,
        (v) => Tween<double>(begin: v as double)) as Tween<double>?;
    _heightFactor = visitor(_heightFactor, widget.heightFactor,
        (v) => Tween<double>(begin: v as double)) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final alignVal = _alignment?.evaluate(animation) ?? widget.alignment;
    final wVal = _widthFactor?.evaluate(animation) ?? widget.widthFactor;
    final hVal = _heightFactor?.evaluate(animation) ?? widget.heightFactor;
    return FractionallySizedBox(
      alignment: alignVal,
      widthFactor: wVal?.clamp(0.0, double.infinity),
      heightFactor: hVal?.clamp(0.0, double.infinity),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<AlignmentGeometryTween>('alignment', _alignment));
    properties
        .add(DiagnosticsProperty<Tween<double>>('widthFactor', _widthFactor));
    properties
        .add(DiagnosticsProperty<Tween<double>>('heightFactor', _heightFactor));
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physics_simulations.dart';

/// A widget that automatically transitions its size over a given duration
/// whenever the given child's size changes, using either standard curves or
/// physics-based animations.
///
/// This widget is similar to [AnimatedSize], but with enhanced animation capabilities:
///
/// * Supports both standard [Curve]s and [PhysicsSimulation]s (like [Spring])
/// * Maintains velocity when size changes mid-animation
/// * Provides more natural-feeling transitions, especially for gesture-driven animations
///
/// When using a standard [Curve], you must provide a [duration]. When using a
/// [PhysicsSimulation], the duration is determined by the simulation itself.
///
/// {@tool snippet}
/// This example shows a container that smoothly resizes using a spring simulation:
///
/// ```dart
/// ASize(
///   physics: Spring.withDamping(
///     mass: 1.0,
///     damping: 0.7,
///   ),
///   child: Container(
///     width: _expanded ? 200.0 : 100.0,
///     height: _expanded ? 200.0 : 100.0,
///     color: Colors.blue,
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedSize], which only supports curve-based animations
///  * [PhysicsSimulation], the base class for physics-based animations
///  * [Spring], a common physics simulation for natural-feeling animations
class ASize extends StatefulWidget {
  /// Creates a widget that animates its size to match that of its child.
  ///
  /// When [physics] is a [Curve], the [duration] parameter is required.
  /// When [physics] is a [PhysicsSimulation], [duration] is optional.
  const ASize({
    super.key,
    this.child,
    this.alignment = Alignment.center,
    this.physics,
    this.duration,
    this.reverseDuration,
    this.clipBehavior = Clip.hardEdge,
    this.onEnd,
  }) : assert(duration != null || physics is PhysicsSimulation?,
            'duration is required when using a Curve');

  /// The widget below this widget in the tree.
  final Widget? child;

  /// The alignment of the child within the parent when the parent is not yet
  /// the same size as the child.
  ///
  /// Defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The physics simulation or curve to use when transitioning this widget's
  /// size to match the child's size.
  ///
  /// Can be either a standard [Curve] or a [PhysicsSimulation] like [Spring].
  /// When using a [Curve], [duration] must be provided.
  final Physics? physics;

  /// The duration when transitioning this widget's size to match the child's size.
  ///
  /// Required when [physics] is a standard [Curve]. Ignored when [physics] is
  /// a [PhysicsSimulation].
  final Duration? duration;

  /// The duration when transitioning this widget's size to match the child's
  /// size when going in reverse.
  ///
  /// If not specified, defaults to [duration].
  final Duration? reverseDuration;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Called every time an animation completes.
  final VoidCallback? onEnd;

  @override
  State<ASize> createState() => _ASizeState();
}

class _ASizeState extends State<ASize> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return _ASizeRenderObject(
      alignment: widget.alignment,
      physics: widget.physics,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      vsync: this,
      clipBehavior: widget.clipBehavior,
      onEnd: widget.onEnd,
      child: widget.child,
    );
  }
}

class _ASizeRenderObject extends SingleChildRenderObjectWidget {
  const _ASizeRenderObject({
    super.child,
    this.alignment = Alignment.center,
    required this.physics,
    this.duration,
    this.reverseDuration,
    required this.vsync,
    this.clipBehavior = Clip.hardEdge,
    this.onEnd,
  });

  final AlignmentGeometry alignment;
  final Physics? physics;
  final Duration? duration;
  final Duration? reverseDuration;
  final TickerProvider vsync;
  final Clip clipBehavior;
  final VoidCallback? onEnd;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderASize(
      alignment: alignment,
      physics: physics,
      duration: duration,
      reverseDuration: reverseDuration,
      vsync: vsync,
      textDirection: Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
      onEnd: onEnd,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderASize renderObject) {
    renderObject
      ..alignment = alignment
      ..physics = physics
      ..duration = duration
      ..reverseDuration = reverseDuration
      ..vsync = vsync
      ..textDirection = Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior
      ..onEnd = onEnd;
  }
}

/// Directly copied from [RenderAnimatedSize].
enum RenderAnimatedSizeState {
  start,
  stable,
  changed,
  unstable,
}

class RenderASize extends RenderAligningShiftedBox {
  RenderASize({
    required TickerProvider vsync,
    Physics? physics,
    Duration? duration,
    Duration? reverseDuration,
    super.alignment,
    super.textDirection,
    super.child,
    Clip clipBehavior = Clip.hardEdge,
    VoidCallback? onEnd,
  })  : assert(duration != null || physics is PhysicsSimulation?,
            'duration is required when using a Curve'),
        _clipBehavior = clipBehavior,
        _vsync = vsync {
    _controller = PhysicsController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
      defaultPhysics: physics,
    );
    _onEnd = onEnd;
  }

  late final PhysicsController _controller;
  final SizeTween _sizeTween = SizeTween();
  late bool _hasVisualOverflow;
  var _state = RenderAnimatedSizeState.start;
  bool _needsAnimation = false;
  bool _isAnimating = false;
  Size? _lastSize;
  Size? _targetSize;

  Physics get physics => _controller.defaultPhysics;
  set physics(Physics? value) {
    if (value == _controller.defaultPhysics || value == null) {
      return;
    }
    _controller.defaultPhysics = value;
  }

  Duration? get duration => _controller.duration;
  set duration(Duration? value) {
    if (value == _controller.duration) {
      return;
    }
    _controller.duration = value;
  }

  Duration? get reverseDuration => _controller.reverseDuration;
  set reverseDuration(Duration? value) {
    if (value == _controller.reverseDuration) {
      return;
    }
    _controller.reverseDuration = value;
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.hardEdge;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get isAnimating => _isAnimating;

  final TickerProvider _vsync;
  TickerProvider get vsync => _vsync;
  set vsync(TickerProvider value) {
    if (value == _vsync) {
      return;
    }
    _controller.resync(value);
  }

  VoidCallback? get onEnd => _onEnd;
  VoidCallback? _onEnd;
  set onEnd(VoidCallback? value) {
    if (value == _onEnd) {
      return;
    }
    _onEnd = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(_handleControllerChange);
    _controller.addStatusListener(_handleStatusChange);
    if (_state != RenderAnimatedSizeState.start &&
        _state != RenderAnimatedSizeState.stable) {
      markNeedsLayout();
    }
  }

  @override
  void detach() {
    _controller.removeListener(_handleControllerChange);
    _controller.removeStatusListener(_handleStatusChange);
    _controller.stop();
    super.detach();
  }

  void _handleControllerChange() {
    if (!_isAnimating) return;
    markNeedsLayout();
  }

  Size? get _animatedSize {
    return _sizeTween.evaluate(_controller);
  }

  @override
  void performLayout() {
    _hasVisualOverflow = false;
    final BoxConstraints constraints = this.constraints;
    if (child == null || constraints.isTight) {
      _controller.stop();
      size = _sizeTween.begin = _sizeTween.end = constraints.smallest;
      _state = RenderAnimatedSizeState.start;
      child?.layout(constraints);
      return;
    }

    child!.layout(constraints, parentUsesSize: true);
    final childSize = child!.size;

    if (_targetSize != childSize) {
      _targetSize = childSize;
      if (_state == RenderAnimatedSizeState.start) {
        _sizeTween.begin = _sizeTween.end = debugAdoptSize(childSize);
        _state = RenderAnimatedSizeState.stable;
      } else {
        _sizeTween.begin = size;
        _sizeTween.end = debugAdoptSize(childSize);
        _needsAnimation = true;
        _state = RenderAnimatedSizeState.changed;
      }
    }

    if (_needsAnimation) {
      _scheduleAnimation();
    }

    size = constraints.constrain(_animatedSize ?? childSize);
    alignChild();

    if (size.width < _sizeTween.end!.width ||
        size.height < _sizeTween.end!.height) {
      _hasVisualOverflow = true;
    }
  }

  void _scheduleAnimation() {
    _needsAnimation = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached) return;
      _isAnimating = true;
      _controller.forward();
    });
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (child == null || constraints.isTight) {
      return constraints.smallest;
    }
    final Size childSize = child!.getDryLayout(constraints);
    return constraints.constrain(childSize);
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isAnimating = false;
      _state = RenderAnimatedSizeState.stable;
      _onEnd?.call();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _hasVisualOverflow && clipBehavior != Clip.none) {
      final Rect rect = Offset.zero & size;
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        rect,
        super.paint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      super.paint(context, offset);
    }
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    _controller.dispose();
    super.dispose();
  }
}

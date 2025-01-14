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
      ..physics = physics ?? Spring.elegant
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
    _controller = PhysicsController2D.unbounded(
      vsync: vsync,
      value: const Offset(-1, -1), // special value to indicate start
      duration: duration,
      reverseDuration: reverseDuration,
      defaultPhysics: physics == null ? null : Simulation2D(physics, physics),
    )..addListener(() {
        if (_controller.value != _lastValue) {
          markNeedsLayout();
        }
      });
    _onEnd = onEnd;
  }

  @visibleForTesting
  PhysicsController2D? get debugController {
    PhysicsController2D? controller;
    assert(() {
      controller = _controller;
      return true;
    }());
    return controller;
  }

  late final PhysicsController2D _controller;

  Size? _beginSize, _targetSize;
  late bool _hasVisualOverflow;
  Offset? _lastValue;

  /// The state this size animation is in.
  ///
  /// See [RenderAnimatedSizeState] for possible states.
  @visibleForTesting
  RenderAnimatedSizeState get state => _state;
  RenderAnimatedSizeState _state = RenderAnimatedSizeState.start;

  Physics get physics => _controller.defaultPhysics.xPhysics;
  set physics(Physics value) {
    if (value == physics) {
      return;
    }
    _controller.defaultPhysics = Simulation2D(value, value);
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

  bool get isAnimating => _controller.isAnimating;

  TickerProvider _vsync;
  TickerProvider get vsync => _vsync;
  set vsync(TickerProvider value) {
    if (value == _vsync) {
      return;
    }
    _vsync = value;
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
    switch (state) {
      case RenderAnimatedSizeState.start:
      case RenderAnimatedSizeState.stable:
        break;
      case RenderAnimatedSizeState.changed:
      case RenderAnimatedSizeState.unstable:
        // Call markNeedsLayout in case the RenderObject isn't marked dirty
        // already, to resume interrupted resizing animation.
        markNeedsLayout();
    }
    _controller.addStatusListener(_handleStatusChange);
  }

  @override
  void detach() {
    _controller.stop();
    _controller.removeStatusListener(_handleStatusChange);
    super.detach();
  }

  Size? get _animatedSize {
    final value = _controller.value;
    if (value.dx == -1 && value.dy == -1) {
      return _beginSize ?? _targetSize;
    }
    return Size(value.dx, value.dy);
  }

  @override
  void performLayout() {
    _lastValue = _controller.value;
    _hasVisualOverflow = false;
    final constraints = this.constraints;
    if (child == null || constraints.isTight) {
      _controller.stop();
      size = _beginSize = _targetSize = constraints.smallest;
      _state = RenderAnimatedSizeState.start;
      child?.layout(constraints);
      return;
    }

    child!.layout(constraints, parentUsesSize: true);

    switch (_state) {
      case RenderAnimatedSizeState.start:
        _layoutStart();
      case RenderAnimatedSizeState.stable:
        _layoutStable();
      case RenderAnimatedSizeState.changed:
        _layoutChanged();
      case RenderAnimatedSizeState.unstable:
        _layoutUnstable();
    }

    size = constraints.constrain(_animatedSize!);
    alignChild();

    if (_targetSize != null &&
        (size.width < _targetSize!.width ||
            size.height < _targetSize!.height)) {
      _hasVisualOverflow = true;
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (child == null || constraints.isTight) {
      return constraints.smallest;
    }

    final childSize = child!.getDryLayout(constraints);
    switch (_state) {
      case RenderAnimatedSizeState.start:
        return constraints.constrain(childSize);
      case RenderAnimatedSizeState.stable:
        if (_targetSize != childSize) {
          return constraints.constrain(size);
        } else if (_targetSize?.isVeryCloseTo(_controller.value.toSize()) ??
            false) {
          return constraints.constrain(childSize);
        }
      case RenderAnimatedSizeState.unstable:
      case RenderAnimatedSizeState.changed:
        if (_targetSize != childSize) {
          return constraints.constrain(childSize);
        }
    }

    return constraints.constrain(_animatedSize!);
  }

  void _layoutStart() {
    _beginSize = _targetSize = debugAdoptSize(child!.size);
    _state = RenderAnimatedSizeState.stable;
  }

  void _layoutStable() {
    if (_targetSize != child!.size) {
      _beginSize = _targetSize = debugAdoptSize(child!.size);
      _restartAnimation();
      _state = RenderAnimatedSizeState.changed;
    } else if (_targetSize?.isVeryCloseTo(_controller.value.toSize()) ??
        false) {
      _beginSize = _targetSize = debugAdoptSize(child!.size);
    } else if (!_controller.isAnimating) {
      if (_targetSize case final size?) _controller.animateTo(size.toOffset());
    }
  }

  void _layoutChanged() {
    if (_targetSize != child!.size) {
      _beginSize = _targetSize = debugAdoptSize(child!.size);
      _restartAnimation();
      _state = RenderAnimatedSizeState.unstable;
    } else {
      _state = RenderAnimatedSizeState.stable;
      if (!_controller.isAnimating && _targetSize != null) {
        _controller.animateTo(_targetSize!.toOffset());
      }
    }
  }

  void _layoutUnstable() {
    if (_targetSize != child!.size) {
      _beginSize = _targetSize = debugAdoptSize(child!.size);
      _restartAnimation();
    } else {
      _controller.stop();
      _state = RenderAnimatedSizeState.stable;
    }
  }

  void _restartAnimation() {
    _lastValue = _beginSize!.toOffset();
    _controller.value = _lastValue!;
    _controller.animateTo(_targetSize!.toOffset());
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _onEnd?.call();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _hasVisualOverflow && clipBehavior != Clip.none) {
      final rect = Offset.zero & size;
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

  final _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    _controller.dispose();
    super.dispose();
  }
}

extension _OffsetToSize on Offset {
  Size toSize() => Size(dx, dy);
}

extension _SizeToOffset on Size {
  Offset toOffset() => Offset(width, height);
  bool isVeryCloseTo(Size other) =>
      (width - other.width).abs() < 0.0001 &&
      (height - other.height).abs() < 0.0001;
}

// This file defines a physics-first equivalent of Flutter's ImplicitlyAnimatedWidget
// system, using a PhysicsController instead of AnimationController.
// It also provides all out-of-the-box variants like Container, Padding, Align, etc.,
// but renamed as AContainer, APadding, AAlign, etc., to avoid conflicts with Flutter.
//
// The general pattern is similar: each widget is an ImplicitlyPhysicsAnimatedWidget
// subclass, and each state is a PhysicsAnimatedWidgetBaseState that uses a
// PhysicsController to drive changes.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_physics/flutter_physics.dart';

/// A base class resembling `ImplicitlyAnimatedWidget` driven by a [PhysicsController].
///
/// This class provides a physics-first approach to implicit animations, allowing widgets
/// to smoothly animate changes to their properties using physics simulations or curves.
///
/// {@tool snippet}
/// This example shows a basic usage of [ImplicitlyPhysicsAnimatedWidget] to create
/// a container that animates its color using spring physics:
///
/// ```dart
/// class BouncingBox extends ImplicitlyPhysicsAnimatedWidget {
///   const BouncingBox({
///     super.key,
///     required this.offset,
///     super.physics = const Spring(
///       mass: 1.0,
///       stiffness: 180,
///       damping: 12,
///     ),
///   });
///
///   final Offset offset;
///
///   @override
///   State<BouncingBox> createState() => _BouncingBoxState();
/// }
///
/// class _BouncingBoxState extends PhysicsAnimatedWidgetState<BouncingBox> {
///   OffsetTween? _offsetTween;
///
///   @override
///   void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
///     _offsetTween = visitor(
///       _offsetTween,
///       widget.offset,
///       (value) => OffsetTween(begin: value as Offset),
///     ) as OffsetTween?;
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Transform.translate(
///       offset: _offsetTween?.evaluate(animation) ?? Offset.zero,
///       child: Container(
///         width: 100,
///         height: 100,
///         decoration: BoxDecoration(
///           color: Colors.blue,
///           borderRadius: BorderRadius.circular(8),
///           boxShadow: [
///             BoxShadow(
///               color: Colors.black.withOpacity(0.2),
///               blurRadius: 8,
///               offset: const Offset(0, 4),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Key Features
///
/// Unlike Flutter's built-in [ImplicitlyAnimatedWidget], this widget:
/// * Uses [PhysicsController] instead of [AnimationController]
/// * Supports both [PhysicsSimulation] and [Curve] based animations
/// * Provides natural-feeling animations through physics
/// * Can work without a fixed duration when using physics simulations
///
/// ## Common Use Cases
///
/// This widget is particularly useful for:
/// * Creating smooth, natural-feeling transitions
/// * Animating UI elements with realistic physics
/// * Building responsive interfaces that react to user input
/// * Implementing gesture-driven animations
///
/// ## Built-in Variants
///
/// Several pre-built physics-animated widgets are provided:
/// * [AContainer] - Physics version of [AnimatedContainer]
/// * [APadding] - Physics version of [AnimatedPadding]
/// * [AAlign] - Physics version of [AnimatedAlign]
/// * [APositioned] - Physics version of [AnimatedPositioned]
/// * [AOpacity] - Physics version of [AnimatedOpacity]
/// * And more...
///
/// {@template ImplicitlyPhysicsAnimatedWidget}
/// The key properties that control how this widget animates:
///
/// * [duration]: Controls how long the animation takes to complete.
///   - For physics simulations ([PhysicsSimulation]): Leave this null for best results.
///   - For curve-based animations ([Curve]): This is required.
///   - Can be overridden when manually controlling the animation.
///   - Used as the default duration for [PhysicsController.forward] and [PhysicsController.reverse]
///
/// * [physics]: Determines the motion behavior of the animation.
///   - Can be a physics simulation (like [Spring.snap]) or a standard [Curve] (like [Curves.easeInOut]).
///   - Physics simulations provide natural, dynamic motion.
///   - Curves provide traditional easing animations.
///   - Defaults to [Spring.elegant] if not specified.
///
/// * [onEnd]: A callback function that runs when the animation finishes.
///   - Called after both forward and reverse animations complete.
///   - Useful for chaining animations or triggering follow-up actions.
/// {@endtemplate}
abstract class ImplicitlyPhysicsAnimatedWidget extends StatefulWidget {
  /// Creates a new [ImplicitlyPhysicsAnimatedWidget].
  /// {@macro ImplicitlyPhysicsAnimatedWidget}
  const ImplicitlyPhysicsAnimatedWidget({
    super.key,
    this.duration,
    this.physics,
    this.onEnd,
  }) : assert(duration != null || physics is PhysicsSimulation?);

  /// The duration of the animation.
  ///
  /// This value is used as the default duration for [PhysicsController.forward] and
  /// [PhysicsController.reverse] calls. It can be overridden when manually controlling
  /// the animation.
  ///
  /// For physics simulations ([PhysicsSimulation]), this should be null to allow the
  /// physics to determine the natural duration. For curve-based animations ([Curve]),
  /// this is required.
  final Duration? duration;

  /// The physics or curve that controls how the animation moves.
  ///
  /// This can be either:
  /// * A [PhysicsSimulation] like [Spring.snap] for natural, dynamic motion
  /// * A [Curve] like [Curves.easeInOut] for traditional easing animations
  ///
  /// If not specified, defaults to [Spring.elegant] for natural motion.
  ///
  /// Physics simulations provide more natural-feeling animations by modeling real-world
  /// physics, while curves provide more predictable, traditional easing animations.
  final Physics? physics;

  /// A callback that is called when the animation completes.
  ///
  /// This callback is invoked in two scenarios:
  /// * When a forward animation reaches its target value
  /// * When a reverse animation returns to its initial value
  ///
  /// This is useful for:
  /// * Chaining multiple animations together
  /// * Triggering side effects after an animation
  /// * Cleaning up resources when an animation finishes
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
/// Subclassing this does **not** automatically rebuild on each tick. To rebuild
/// on each tick, use the `RebuildOnTick` mixin.
///
/// To animate changes to your widget's fields, store `Tween` objects in your
/// subclass state. Override [forEachTween] to create/update these tweens
/// whenever new values come in from the updated widget. Then rely on the
/// physics-driven controller to update [animation] over time, and `setState` is
/// called automatically whenever the physics ticks.
abstract class PhysicsAnimatedWidgetState<
        T extends ImplicitlyPhysicsAnimatedWidget> extends State<T>
    with SingleTickerProviderStateMixin<T> {
  late PhysicsController _controller;

  /// The main animation that this state uses. Typically used to evaluate tweens.
  Animation<double> get animation => _controller;

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
    _controller.addStatusListener(_handleStatusChange);

    _constructTweens();
    didUpdateTweens();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If duration changed, we update the controller's duration
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // If user provided a new physics, we want to re-sync or forcibly adapt it.
    if (widget.physics != oldWidget.physics) {
      _updateController();
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

  void _updateController() {
    _controller.defaultPhysics = widget.physics ?? _controller.defaultPhysics;
    final status = _controller.status;
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.reverse) {
      _controller.forward();
    }
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
    forEachTween((Tween<dynamic>? tween, dynamic targetValue,
        TweenConstructor<dynamic> constructor) {
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
mixin RebuildOnTick<T extends ImplicitlyPhysicsAnimatedWidget> on State<T> {
  PhysicsController get controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleAnimationChanged);
  }

  void _handleAnimationChanged() {
    setState(() {/* The animation ticked. Rebuild with new animation value */});
  }
}

/// Physics-based equivalent of [AnimatedContainer], renamed to [AContainer].
///
/// Automatically transitions between different values for properties when they change,
/// using physics-based animations. The physics simulation or curve used for the transition
/// is configurable via the [physics] property.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a container that uses spring physics to animate its size and color:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _expanded = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return AContainer(
///       // duration: const Duration(milliseconds: 500), // Only used for curve-based physics
///       physics: Spring.withDamping(dampingFraction: 0.5), // or Curves.easeInOut
///       width: _expanded ? 200.0 : 100.0,
///       height: _expanded ? 200.0 : 100.0,
///       decoration: BoxDecoration(
///         color: _expanded ? Colors.blue : Colors.red,
///         borderRadius: BorderRadius.circular(8),
///       ),
///       child: GestureDetector(
///         onTap: () => setState(() => _expanded = !_expanded),
///         child: const Center(child: Text('Tap me!')),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// The following properties are animated:
/// * [decoration]
/// * [foregroundDecoration]
/// * [constraints]
/// * [margin]
/// * [padding]
/// * [transform]
/// * [alignment]
/// * [transformAlignment]
///
/// The [child] and [clipBehavior] properties are not animated.
///
/// See also:
/// * [APadding], which only animates the padding property
/// * [AAlign], which only animates the alignment property
/// * [Container], the non-animated version of this widget
class AContainer extends ImplicitlyPhysicsAnimatedWidget {
  const AContainer({
    super.key,
    super.duration,
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

class _AContainerState extends PhysicsAnimatedWidgetState<AContainer>
    with RebuildOnTick {
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
    return BetterPadding(
      padding: _margin?.evaluate(animation) ?? widget.margin ?? EdgeInsets.zero,
      child: Container(
        decoration: _decoration?.evaluate(animation),
        foregroundDecoration: _foregroundDecoration?.evaluate(animation),
        alignment: _alignment?.evaluate(animation),
        constraints: _constraints?.evaluate(animation),
        transform: _transform?.evaluate(animation),
        transformAlignment: _transformAlignment?.evaluate(animation),
        clipBehavior: widget.clipBehavior,
        child: BetterPadding(
          padding: _padding?.evaluate(animation) ??
              widget.padding ??
              EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A widget that animates changes in size using physics-based animations.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a container that animates its size with spring physics:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _expanded = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return ASizedBox(
///       physics: Spring.elegant,
///       width: _expanded ? 200.0 : 100.0,
///       height: _expanded ? 200.0 : 100.0,
///       child: GestureDetector(
///         onTap: () => setState(() => _expanded = !_expanded),
///         child: Container(
///           color: Colors.blue,
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
/// * [AContainer], which can animate size along with other properties
/// * [SizedBox], which provides non-animated sizing
class ASizedBox extends ImplicitlyPhysicsAnimatedWidget {
  const ASizedBox({
    super.key,
    this.width,
    this.height,
    super.duration,
    super.physics,
    this.child,
    super.onEnd,
  });

  /// The width to animate to.
  final double? width;

  /// The height to animate to.
  final double? height;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  State<ASizedBox> createState() => _ASizedBoxState();
}

class _ASizedBoxState extends PhysicsAnimatedWidgetState<ASizedBox>
    with RebuildOnTick {
  Tween<double>? _width;
  Tween<double>? _height;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _width = visitor(_width, widget.width,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
    _height = visitor(_height, widget.height,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<Tween<double>>('width', _width,
        defaultValue: null));
    description.add(DiagnosticsProperty<Tween<double>>('height', _height,
        defaultValue: null));
  }
}

/// Physics-based equivalent of [AnimatedPadding], renamed to [APadding].
///
/// Animates changes in padding using physics-based animations, providing more natural
/// and configurable transitions compared to curve-based animations.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a container that expands its padding with spring physics:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _expanded = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return APadding(
///       physics: Spring.elegant,
///       padding: EdgeInsets.all(_expanded ? 32.0 : 8.0),
///       child: GestureDetector(
///         onTap: () => setState(() => _expanded = !_expanded),
///         child: Container(
///           color: Colors.blue,
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
/// * [AContainer], which can animate padding along with other properties
/// * [BetterPadding], which handles negative padding values correctly
class APadding extends ImplicitlyPhysicsAnimatedWidget {
  const APadding({
    super.key,
    required this.padding,
    super.duration,
    super.physics,
    this.child,
    super.onEnd,
  });

  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  State<APadding> createState() => _APaddingState();
}

class _APaddingState extends PhysicsAnimatedWidgetState<APadding>
    with RebuildOnTick {
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
    return BetterPadding(padding: padding, child: widget.child);
  }
}

/// Physics-based equivalent of [AnimatedAlign], renamed to [AAlign].
///
/// Animates changes in alignment using physics-based animations. This widget is particularly
/// useful for creating smooth, physics-based positioning transitions.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a box that bounces between different alignment positions:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _aligned = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return AAlign(
///       physics: Spring.snap,
///       alignment: _aligned ? Alignment.topRight : Alignment.bottomLeft,
///       child: GestureDetector(
///         onTap: () => setState(() => _aligned = !_aligned),
///         child: Container(
///           width: 50,
///           height: 50,
///           color: Colors.blue,
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Properties
///
/// * [alignment] - The target alignment to animate towards
/// * [heightFactor] - Optional height factor that can be animated
/// * [widthFactor] - Optional width factor that can be animated
///
/// The [heightFactor] and [widthFactor] properties, if non-null, cause the child to
/// expand to fill a fraction of the available space.
///
/// See also:
/// * [APositioned], for animating position in a [Stack]
/// * [ASlide], for animating position relative to normal position
class AAlign extends ImplicitlyPhysicsAnimatedWidget {
  const AAlign({
    super.key,
    required this.alignment,
    this.child,
    this.heightFactor,
    this.widthFactor,
    super.duration,
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

class _AAlignState extends PhysicsAnimatedWidgetState<AAlign>
    with RebuildOnTick {
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
/// {@template a_positioned}
/// Animates changes in position within a [Stack] using physics-based animations.
/// This widget must be a direct child of a [Stack].
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a positioned box that springs between two positions in a stack:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _moved = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return Stack(
///       children: [
///         APositioned(
///           physics: Spring.withDamping(
///             mass: 1.0,
///             dampingFraction: 0.5,
///           ),
///           left: _moved ? 250.0 : 50.0,
///           top: _moved ? 50.0 : 150.0,
///           width: 50.0,
///           height: 50.0,
///           child: GestureDetector(
///             onTap: () => setState(() => _moved = !_moved),
///             child: Container(color: Colors.blue),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Usage Notes
///
/// * At least one position property (left, right, top, or bottom) must be non-null
/// * If both left and right (or top and bottom) are non-null, the widget will be stretched
/// * Width and height are optional but recommended for predictable sizing
///
/// See also:
/// * [APositionedDirectional] for RTL-aware positioning
/// * [ASlide] for simpler relative positioning
/// {@endtemplate}
class APositioned extends ImplicitlyPhysicsAnimatedWidget {
  const APositioned({
    super.key,
    super.duration,
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

class _APositionedState extends PhysicsAnimatedWidgetState<APositioned>
    with RebuildOnTick {
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
/// Directional equivalent of [APositioned].
///
/// Copied from [APositioned]:
/// {@macro a_positioned}
class APositionedDirectional extends ImplicitlyPhysicsAnimatedWidget {
  const APositionedDirectional({
    super.key,
    super.duration,
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
    extends PhysicsAnimatedWidgetState<APositionedDirectional>
    with RebuildOnTick {
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
/// Animates changes in scale using physics-based animations, providing natural-feeling
/// scaling effects. This is particularly useful for interactive UI elements that
/// need to scale in response to user input.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a widget that bounces between two scales when tapped:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _enlarged = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return AScale(
///       physics: Spring.snap,
///       scale: _enlarged ? 1.5 : 1.0,
///       alignment: Alignment.center,
///       child: GestureDetector(
///         onTap: () => setState(() => _enlarged = !_enlarged),
///         child: Container(
///           width: 100,
///           height: 100,
///           color: Colors.blue,
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Performance Considerations
///
/// * Scale animations are generally more performant than opacity animations
/// * Consider using [filterQuality] to improve scaled image quality
/// * Large scale factors may impact performance due to increased pixel processing
///
/// See also:
/// * [ARotation] for rotating widgets
/// * [ASlide] for translating widgets
/// * [AOpacity] for fading widgets
class AScale extends ImplicitlyPhysicsAnimatedWidget {
  const AScale({
    super.key,
    required this.scale,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    super.duration,
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

class _AScaleState extends PhysicsAnimatedWidgetState<AScale> {
  Tween<double>? _scale;
  late Animation<double> _scaleAnimation;

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
  void didUpdateTweens() {
    _scaleAnimation = animation.drive(_scale!);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedRotation], renamed to [ARotation].
///
/// Animates changes in rotation using physics-based animations. This widget is useful
/// for creating natural-feeling rotation animations, especially when combined with
/// spring physics.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a widget that springs between two rotation angles:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _rotated = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return ARotation(
///       physics: Spring.withDamping(
///         mass: 1.0,
///         dampingFraction: 0.5,
///       ),
///       turns: _rotated ? 0.5 : 0.0, // Half turn when rotated
///       child: GestureDetector(
///         onTap: () => setState(() => _rotated = !_rotated),
///         child: Container(
///           width: 100,
///           height: 100,
///           color: Colors.blue,
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Properties
///
/// * [turns] - The target rotation in turns (1.0 = 360 degrees)
/// * [alignment] - The alignment of the rotation origin
/// * [filterQuality] - The quality of image filtering when rotating
///
/// See also:
/// * [AScale] for scaling animations
/// * [ASlide] for translation animations
class ARotation extends ImplicitlyPhysicsAnimatedWidget {
  const ARotation({
    super.key,
    required this.turns,
    this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
    super.duration,
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

class _ARotationState extends PhysicsAnimatedWidgetState<ARotation> {
  Tween<double>? _turns;
  late Animation<double> _turnsAnimation;

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
  void didUpdateTweens() {
    _turnsAnimation = animation.drive(_turns!);
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _turnsAnimation,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedSlide], renamed to [ASlide].
///
/// Animates changes in position relative to its normal position using physics-based
/// animations. This provides a simpler alternative to [APositioned] when you just
/// want to offset a widget from its normal position.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a widget that slides horizontally with spring physics:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _slid = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return ASlide(
///       physics: Spring.withDamping(
///         mass: 1.0,
///         dampingFraction: 0.5,
///       ),
///       offset: Offset(_slid ? 1.0 : 0.0, 0.0), // Slide right by 100% of width
///       child: GestureDetector(
///         onTap: () => setState(() => _slid = !_slid),
///         child: Container(
///           width: 100,
///           height: 100,
///           color: Colors.blue,
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Understanding Offset Values
///
/// The [offset] property uses relative values where:
/// * x: 1.0 = 100% of the child's width
/// * y: 1.0 = 100% of the child's height
///
/// This makes it easy to create responsive animations that work across different
/// screen sizes.
///
/// See also:
/// * [APositioned] for absolute positioning within a [Stack]
/// * [AAlign] for alignment-based positioning
class ASlide extends ImplicitlyPhysicsAnimatedWidget {
  const ASlide({
    super.key,
    required this.offset,
    this.child,
    super.duration,
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

class _ASlideState extends PhysicsAnimatedWidgetState<ASlide> {
  Tween<Offset>? _offset;
  late Animation<Offset> _offsetAnimation;

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
  void didUpdateTweens() {
    _offsetAnimation = animation.drive(_offset!);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [AnimatedOpacity], renamed to [AOpacity].
///
/// {@template a_opacity}
/// Animates changes in opacity using physics-based animations, providing more natural
/// and configurable transitions compared to curve-based animations.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a fading text widget that uses a custom spring simulation:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _visible = true;
///
///   @override
///   Widget build(BuildContext context) {
///     return AOpacity(
///       physics: Spring.withDamping(
///         mass: 1.0,
///         dampingFraction: 0.8,
///       ),
///       opacity: _visible ? 1.0 : 0.0,
///       child: const Text('Fade me!'),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Performance Considerations
///
/// Animating opacity is relatively expensive because it requires painting the child
/// into an intermediate buffer. For better performance:
///
/// * Consider using [ASlide] or [AScale] instead if possible
/// * Use [alwaysIncludeSemantics] judiciously
/// * Consider combining with [AnimatedSwitcher] for more complex transitions
///
/// ## Hit Testing
///
/// When [opacity] is 0.0, hit testing is still performed. To prevent this,
/// wrap the [AOpacity] widget in an [IgnorePointer]:
///
/// ```dart
/// IgnorePointer(
///   ignoring: opacity < 0.1,
///   child: AOpacity(
///     opacity: opacity,
///     child: child,
///   ),
/// )
/// ```
/// {@endtemplate}
class AOpacity extends ImplicitlyPhysicsAnimatedWidget {
  const AOpacity({
    super.key,
    super.duration,
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

class _AOpacityState extends PhysicsAnimatedWidgetState<AOpacity> {
  Tween<double>? _opacity;
  late Animation<double> _opacityAnimation;

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _opacity = visitor(
            _opacity, widget.opacity, (v) => Tween<double>(begin: v as double))
        as Tween<double>?;
  }

  @override
  void didUpdateTweens() {
    _opacityAnimation = animation.drive(_opacity!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<Animation<double>>('opacity', _opacityAnimation));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
      child: widget.child,
    );
  }
}

/// Physics-based equivalent of [SliverAnimatedOpacity], renamed to [ASliverOpacity].
/// {@macro a_opacity}
class ASliverOpacity extends ImplicitlyPhysicsAnimatedWidget {
  const ASliverOpacity({
    super.key,
    super.duration,
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

class _ASliverOpacityState extends PhysicsAnimatedWidgetState<ASliverOpacity> {
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
/// Animates changes in text style using physics-based animations. This is particularly
/// useful for creating smooth transitions between different text styles, such as
/// when implementing dynamic typography or theme changes.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows text that springs between two different styles:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _enlarged = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return ADefaultTextStyle(
///       physics: Spring.withDamping(
///         mass: 1.0,
///         dampingFraction: 0.8,
///       ),
///       style: TextStyle(
///         fontSize: _enlarged ? 24.0 : 16.0,
///         color: _enlarged ? Colors.blue : Colors.black,
///         fontWeight: _enlarged ? FontWeight.bold : FontWeight.normal,
///       ),
///       child: GestureDetector(
///         onTap: () => setState(() => _enlarged = !_enlarged),
///         child: const Text('Tap to resize me!'),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Animatable Properties
///
/// The following [TextStyle] properties are animated:
/// * [TextStyle.color]
/// * [TextStyle.backgroundColor]
/// * [TextStyle.fontSize]
/// * [TextStyle.fontWeight]
/// * [TextStyle.letterSpacing]
/// * [TextStyle.wordSpacing]
/// * [TextStyle.height]
/// * [TextStyle.decorationThickness]
///
/// Other [TextStyle] properties are not animated and update immediately.
///
/// See also:
/// * [AOpacity] for fading text in and out
/// * [AContainer] for animating text containers
class ADefaultTextStyle extends ImplicitlyPhysicsAnimatedWidget {
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
    super.duration,
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
    extends PhysicsAnimatedWidgetState<ADefaultTextStyle> with RebuildOnTick {
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
/// Animates changes in elevation and colors using physics-based animations. This widget
/// is particularly useful for creating material design-style cards with natural-feeling
/// elevation changes.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a card that springs up when tapped:
///
/// ```dart
/// class ExampleWidget extends StatefulWidget {
///   const ExampleWidget({super.key});

///   @override
///   State<ExampleWidget> createState() => _ExampleWidgetState();
/// }

/// class _ExampleWidgetState extends State<ExampleWidget> {
///   bool _elevated = false;

///   @override
///   Widget build(BuildContext context) {
///     return APhysicalModel(
///       physics: Spring.elegant,
///       elevation: _elevated ? 8.0 : 1.0,
///       color: _elevated ? Colors.blue.shade200 : Colors.white,
///       borderRadius: BorderRadius.circular(8),
///       child: GestureDetector(
///         onTap: () => setState(() => _elevated = !_elevated),
///         child: Container(
///           width: 200,
///           height: 100,
///           alignment: Alignment.center,
///           child: Text(_elevated ? 'Tap to lower' : 'Tap to raise'),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Animatable Properties
///
/// * [elevation] - Animates the z-height of the widget
/// * [color] - Animates the surface color (if [animateColor] is true)
/// * [shadowColor] - Animates the shadow color (if [animateShadowColor] is true)
///
/// The [shape] and [clipBehavior] properties are not animated.
///
/// See also:
/// * [AContainer] for simpler container animations
/// * [AOpacity] for fading effects
class APhysicalModel extends ImplicitlyPhysicsAnimatedWidget {
  const APhysicalModel({
    super.key,
    super.duration,
    required this.child,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0.0,
    this.color = const Color(0xffFFFFFF),
    this.animateColor = true,
    this.shadowColor = const Color(0xff000000),
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
    properties.add(FlagProperty('animateColor',
        value: animateColor,
        ifTrue: 'animate color',
        ifFalse: 'do not animate color'));
    properties.add(ColorProperty('shadowColor', shadowColor));
    properties.add(FlagProperty('animateShadowColor',
        value: animateShadowColor,
        ifTrue: 'animate shadow color',
        ifFalse: 'do not animate shadow color'));
  }
}

class _APhysicalModelState extends PhysicsAnimatedWidgetState<APhysicalModel>
    with RebuildOnTick {
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
/// Animates changes in fractional dimensions using physics-based animations. This widget
/// is useful for creating responsive animations that scale relative to their parent's size.
///
/// {@macro ImplicitlyPhysicsAnimatedWidget}
///
/// {@tool snippet}
/// This example shows a box that springs between different fractional sizes:
///
/// ```dart
/// class _MyWidget extends StatefulWidget {
///   @override
///   State<_MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<_MyWidget> {
///   bool _expanded = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return AFractionallySizedBox(
///       physics: Spring(
///         mass: 1.0,
///         dampingFraction: 0.9,
///       ),
///       widthFactor: _expanded ? 0.8 : 0.3,
///       heightFactor: _expanded ? 0.4 : 0.2,
///       child: GestureDetector(
///         onTap: () => setState(() => _expanded = !_expanded),
///         child: Container(
///           decoration: BoxDecoration(
///             color: Colors.blue,
///             borderRadius: BorderRadius.circular(8),
///           ),
///           child: const Center(child: Text('Tap me!')),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ## Understanding Factors
///
/// * [widthFactor] and [heightFactor] must be non-negative
/// * A factor of 1.0 means 100% of the parent's corresponding dimension
/// * A factor of 0.5 means 50% of the parent's corresponding dimension
/// * If a factor is null, the child's corresponding dimension will not be constrained
///
/// ## Common Use Cases
///
/// * Responsive layouts that adapt to parent size
/// * Expandable panels or drawers
/// * Interactive UI elements that need to scale relative to their container
///
/// See also:
/// * [AContainer] for more general container animations
/// * [AAlign] for alignment-based positioning
class AFractionallySizedBox extends ImplicitlyPhysicsAnimatedWidget {
  const AFractionallySizedBox({
    super.key,
    super.duration,
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
    extends PhysicsAnimatedWidgetState<AFractionallySizedBox>
    with RebuildOnTick {
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

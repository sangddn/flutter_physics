// This file defines a physics-first equivalent of Flutter's ImplicitlyAnimatedWidget
// system, using a PhysicsController instead of AnimationController.
// It also provides all out-of-the-box variants like AnimatedContainer, AnimatedPadding, AnimatedAlign, etc.,
// renamed as AContainer, APadding, AAlign, etc., to avoid conflicts with Flutter.
//
// The general pattern is similar: each widget is an ImplicitlyPhysicsAnimatedWidget
// subclass, and each state is a PhysicsAnimatedWidgetBaseState that uses a
// PhysicsController to drive changes.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../simulations/physics_simulations.dart';
import '../controllers/physics_controller.dart';
import '../other_widgets/other_widgets.dart';

/// A base class resembling `ImplicitlyAnimatedWidget` driven by one or more [PhysicsController]s.
///
/// This class provides a physics-first approach to implicit animations, allowing widgets
/// to smoothly animate changes to their properties using physics simulations or curves.
///
/// {@tool snippet}
/// This example shows a basic usage of [ImplicitlyPhysicsAnimatedWidget] to create
/// a container that animates its color using spring physics in a similar fashion
/// to [ImplicitlyAnimatedWidget]:
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
/// * Supports multiple [PhysicsController]s for different properties that may
///   require different bounds (instead of just 0..1)
/// * Supports both [PhysicsSimulation] and [Curve] based animations
/// * Can work without a fixed duration when using physics simulations
///
/// ## Common Use Cases
///
/// This widget is designed for:
/// * Creating simple, smooth, natural-feeling transitions automatically
/// * Ease of use: Users do not need to worry about managing a controller
///
/// See also:
/// * [AValue] - An implicitly animated widget that provides implicit animation
///   for one single value.
/// * [PhysicsBuilder] - An implicitly animated widget that provides implicit animation
///   for a single value with support for gesture-driven animations.
/// * [PhysicsBuilder2D] - An implicitly animated widget that provides implicit animation
///   for a two-dimensional value with support for gesture-driven animations.
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

  /// {@template ImplicitlyPhysicsAnimatedWidget.duration}
  /// The duration of the animation.
  ///
  /// This value is used as the default duration for [PhysicsController.forward] and
  /// [PhysicsController.reverse] calls. It can be overridden when manually controlling
  /// the animation.
  ///
  /// For curve-based animations ([Curve]), this is required.
  /// For physics simulations ([PhysicsSimulation]), setting a fixed duration
  /// may result in unnatural motion.
  /// {@endtemplate}
  final Duration? duration;

  /// {@template ImplicitlyPhysicsAnimatedWidget.physics}
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
  /// {@endtemplate}
  final Physics? physics;

  /// {@template ImplicitlyPhysicsAnimatedWidget.onEnd}
  /// A callback that is called when an animation completes.
  ///
  /// This callback is specifically invoked in two scenarios:
  /// * When a forward animation reaches its target value
  /// * When a reverse animation returns to its initial value
  ///
  /// This is useful for:
  /// * Chaining multiple animations together
  /// * Triggering side effects after an animation
  /// * Cleaning up resources when an animation finishes
  /// {@endtemplate}
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

/// Signature for a "property visitor" that, given an old [PhysicsAnimatedProperty]
/// and a new target, returns a new or updated [PhysicsAnimatedProperty].
/// Analog of Flutter's TweenVisitor.
typedef PhysicsPropertyVisitor = PhysicsAnimatedProperty? Function(
  PhysicsAnimatedProperty? oldProperty,
  double? targetValue,
  PhysicsAnimationConstructor constructor,
);

/// Signature of a function that creates a new [PhysicsAnimatedProperty] given the initial value
/// and bounds. Physics-based analog of [TweenConstructor].
typedef PhysicsAnimationConstructor = PhysicsAnimatedProperty Function(
    double value);

class PhysicsAnimatedProperty {
  const PhysicsAnimatedProperty({
    required this.key,
    required this.initialValue,
    this.targetValue,
  });

  final String key;
  final double initialValue;
  final double? targetValue;

  PhysicsAnimatedProperty copyWith({
    double? initialValue,
    double? targetValue,
  }) =>
      PhysicsAnimatedProperty(
        key: key,
        initialValue: initialValue ?? this.initialValue,
        targetValue: targetValue ?? this.targetValue,
      );

  @override
  String toString() =>
      'PhysicsAnimatedProperty(key: $key, initialValue: $initialValue, targetValue: $targetValue)';
}

/// A base state class that uses a [PhysicsController] instead of an [AnimationController].
/// Subclassing this does **not** automatically rebuild on each tick. To rebuild
/// on each tick, use [PhysicsAnimatedWidgetBaseState].
///
/// To animate changes to your widget's fields, store `Tween` objects in your
/// subclass state. Override [forEachTween] to create/update these tweens
/// whenever new values come in from the updated widget. Then rely on the
/// physics-driven controller to update [tweenAnimation] over time, and `setState` is
/// called automatically whenever the physics ticks.
abstract class PhysicsAnimatedWidgetState<
        T extends ImplicitlyPhysicsAnimatedWidget> extends State<T>
    with SingleTickerProviderStateMixin<T> {
  late final PhysicsControllerMulti _controller;

  /// The animation for the tween animations.
  Animation<double> get animation => _controller.dimension(0);

  /// The controller for all tween and physics animations.
  PhysicsControllerMulti get controller => _controller;

  /// Subclass must declare all physics-animated properties.
  /// This list should not be changed throughout the lifetime of the widget.
  List<String> get physicsAnimatedProperties => [];
  bool get _hasPhysicsProperties => physicsAnimatedProperties.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _constructTweens();
    didUpdateTweens();
    if (_hasPhysicsProperties) {
      final initialValues = _constructPhysicsProperties();
      didUpdatePhysicsProperties();
      _controller.value = [
        0.0,
        ...List.generate(
          physicsAnimatedProperties.length,
          (i) =>
              initialValues[physicsAnimatedProperties[i]]?.initialValue ?? 0.0,
        )
      ];
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If duration changed, we update the controller's duration
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    // If physics changed, we update the controller's physics
    if (widget.physics != oldWidget.physics) {
      _controller.defaultPhysics =
          List.filled(_controller.dimensions, widget.physics ?? Spring.elegant);
    }

    final someTweensChanged = _constructTweens();
    final changedPhysicsProperties = _constructPhysicsProperties();

    if (someTweensChanged || changedPhysicsProperties.isNotEmpty) {
      _controller.stop();
      _controller.value = [
        if (someTweensChanged) 0.0 else _controller.value[0],
        ...physicsAnimatedProperties.indexedMap((i, key) {
          final prop = changedPhysicsProperties[key];
          if (prop == null) return _controller.value[i + 1];
          return prop.initialValue;
        })
      ];
      _controller.animateTo([
        if (someTweensChanged) 1.0 else _controller.value[0],
        ...physicsAnimatedProperties.indexedMap((i, key) {
          final prop = changedPhysicsProperties[key];
          if (prop == null) return _controller.value[i + 1];
          return prop.targetValue ?? prop.initialValue;
        })
      ]);
      if (someTweensChanged) didUpdateTweens();
      if (changedPhysicsProperties.isNotEmpty) didUpdatePhysicsProperties();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PhysicsControllerMulti _createController() {
    final c = PhysicsControllerMulti(
      vsync: this,
      // Reserve the first dimension for all the Tween animations
      dimensions: 1 + physicsAnimatedProperties.length,
      duration: widget.duration,
      defaultPhysicsForAllDimensions: widget.physics,
      lowerBound: [
        0.0,
        ...List.filled(
          physicsAnimatedProperties.length,
          double.negativeInfinity,
        )
      ],
      upperBound: [
        2.0, // 2.0 allows spring physics to oscillate
        ...List.filled(physicsAnimatedProperties.length, double.infinity)
      ],
    );
    c.addStatusListener(_handleStatusChange);
    return c;
  }

  /// Evaluates the value of a physics property.
  ///
  /// This is used to get the current value of a physics property.
  double? evaluate(PhysicsAnimatedProperty? property) {
    if (property == null) return null;
    assert(
      physicsAnimatedProperties.contains(property.key),
      'Property ${property.key} is not in the [physicsAnimatedProperties] list.',
    );
    return _controller
        .value[physicsAnimatedProperties.indexOf(property.key) + 1];
  }

  /// Get the animation for the value of a physics property.
  Animation<double>? getAnimation(PhysicsAnimatedProperty? property) {
    if (property == null) return null;
    assert(
      physicsAnimatedProperties.contains(property.key),
      'Property ${property.key} is not in the [physicsAnimatedProperties] list.',
    );
    return _controller
        .dimension(physicsAnimatedProperties.indexOf(property.key) + 1);
  }

  Map<String, PhysicsAnimatedProperty> _constructPhysicsProperties() {
    if (!_hasPhysicsProperties) return {};
    final changedProperties = <String, PhysicsAnimatedProperty>{};
    forEachPhysicsProperty((PhysicsAnimatedProperty? oldProperty,
        double? targetValue, PhysicsAnimationConstructor constructor) {
      // If there's no target, we "discard" the property
      if (targetValue == null) {
        if (oldProperty != null) {
          final newProp = oldProperty.copyWith(targetValue: null);
          changedProperties[newProp.key] = newProp;
          return null;
        } else {
          return null;
        }
      }
      if (oldProperty == null) {
        final newProp = constructor(targetValue);
        changedProperties[newProp.key] = newProp;
        return newProp;
      }
      // If the new target is different from the old end, we update
      if (oldProperty.targetValue != targetValue) {
        final prop = oldProperty.copyWith(
          initialValue: evaluate(oldProperty)!,
          targetValue: targetValue,
        );
        changedProperties[prop.key] = prop;
        return prop;
      }
      return oldProperty;
    });
    return changedProperties;
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

  /// Subclasses must override this to create/update tweens if it has any
  /// tween-based properties.
  ///
  /// This is analogous to `AnimatedWidgetBaseState.forEachTween`.
  /// Invoked every time the widget is updated.
  @protected
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {}

  /// Called when the physics properties have been updated. Override this if needed.
  @protected
  void didUpdatePhysicsProperties() {}

  /// Subclasses must override this to return a map from controller keys to
  /// a tuple of the old value and the new target value for the respective
  /// controller.
  ///
  /// Invoked every time the widget is updated.
  @protected
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) =>
      throw UnimplementedError(
        '${objectRuntimeType(this, 'PhysicsAnimatedWidgetState')} must implement forEachPhysicsProperty if it declares physics-animated properties.',
      );

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();
    }
  }
}

abstract class PhysicsAnimatedWidgetBaseState<
        T extends ImplicitlyPhysicsAnimatedWidget>
    extends PhysicsAnimatedWidgetState<T> {
  @override
  PhysicsControllerMulti _createController() {
    final c = super._createController();
    c.addListener(_handleAnimationChanged);
    return c;
  }

  void _handleAnimationChanged() {
    setState(() {/* The animation ticked. Rebuild with new animation value */});
  }
}

/// {@template a_container}
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
/// * [width]
/// * [height]
///
/// The [child] and [clipBehavior] properties are not animated.
///
/// See also:
/// * [APadding], which only animates the padding property
/// * [AAlign], which only animates the alignment property
/// * [Container], the non-animated version of this widget
/// {@endtemplate}
class AContainer extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [AContainer].
  /// {@macro a_container}
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
    this.width,
    this.height,
    this.child,
    super.physics,
    super.onEnd,
  });

  /// The decoration to paint behind the [child].
  ///
  /// Use the [decoration] property to paint a [BoxDecoration] either behind or in
  /// front of the child. When both [decoration] and [foregroundDecoration] are
  /// defined, they will be animated independently.
  final Decoration? decoration;

  /// The decoration to paint in front of the [child].
  ///
  /// Use the [foregroundDecoration] property to paint a [BoxDecoration] in front of
  /// the child. When both [decoration] and [foregroundDecoration] are defined,
  /// they will be animated independently.
  final Decoration? foregroundDecoration;

  /// Align the [child] within the container.
  ///
  /// If non-null, the container will expand to fill its parent and position its
  /// child within itself according to the given value. If the container's parent
  /// does not provide unbounded constraints, then [child] is aligned within the
  /// container's bounds.
  final Alignment? alignment;

  /// Additional constraints to apply to the child.
  ///
  /// The [constraints] are combined with the constraints that the container gets
  /// from its parent to derive the constraints used to lay out the container's
  /// child.
  final BoxConstraints? constraints;

  /// Empty space to inscribe inside the [decoration]. The [child], if any, is
  /// placed inside this padding.
  ///
  /// Negative values are interpreted as [Transform.translate.offset].
  ///
  /// This padding is in addition to any padding inherent in the [decoration];
  /// see [Decoration.padding].
  final EdgeInsets? padding;

  /// Empty space to surround the [decoration] and [child].
  ///
  /// Negative values are interpreted as [Transform.translate.offset].
  ///
  /// The [margin] property effectively adds empty space around the container to
  /// separate it from its parent and siblings.
  final EdgeInsets? margin;

  /// The transformation matrix to apply before painting the container.
  ///
  /// This property allows you to rotate, scale, or translate the container before
  /// painting it. The transformation is applied in the opposite order of the
  /// operations described in the matrix.
  final Matrix4? transform;

  /// The alignment of the origin, relative to the size of the container, if [transform] is specified.
  ///
  /// When [transform] is null, the value of this property is ignored.
  ///
  /// See also:
  ///
  ///  * [Transform.alignment], which is set by this property.
  final Alignment? transformAlignment;

  /// The clip behavior when [Container.decoration] is not null.
  ///
  /// Defaults to [Clip.none]. Must not be null.
  ///
  /// If [clipBehavior] is [Clip.none] and [decoration] is not null, then the
  /// decoration can paint outside of the container's bounds.
  final Clip clipBehavior;

  /// If non-null, requires the container to have exactly this width.
  ///
  /// This property is preferred to using [constraints] to set the width, as it
  /// will usually lead to less complex layout behavior.
  final double? width;

  /// If non-null, requires the container to have exactly this height.
  ///
  /// This property is preferred to using [constraints] to set the height, as it
  /// will usually lead to less complex layout behavior.
  final double? height;

  /// The [child] contained by the container.
  ///
  /// If null, and if the [constraints] are unbounded or also null, the container
  /// will expand to fill all available space in its parent, unless the parent
  /// provides unbounded constraints, in which case the container will attempt to
  /// be as small as possible.
  final Widget? child;

  @override
  State<AContainer> createState() => _AContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<Decoration>(
        'foregroundDecoration', foregroundDecoration));
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties
        .add(DiagnosticsProperty<BoxConstraints>('constraints', constraints));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin));
    properties.add(DiagnosticsProperty<Matrix4>('transform', transform));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'transformAlignment', transformAlignment));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
    properties.add(DoubleProperty('width', width));
    properties.add(DoubleProperty('height', height));
  }
}

class _AContainerState extends PhysicsAnimatedWidgetBaseState<AContainer> {
  DecorationTween? _decoration;
  DecorationTween? _foregroundDecoration;
  BoxConstraintsTween? _constraints;
  Matrix4Tween? _transform;

  PhysicsAnimatedProperty? _width, _height;
  PhysicsAnimatedProperty? _paddingTop,
      _paddingRight,
      _paddingLeft,
      _paddingBottom;
  PhysicsAnimatedProperty? _marginTop, _marginRight, _marginLeft, _marginBottom;
  PhysicsAnimatedProperty? _alignmentX, _alignmentY;
  PhysicsAnimatedProperty? _transformAlignmentX, _transformAlignmentY;

  @override
  List<String> get physicsAnimatedProperties => const [
        'width',
        'height',
        'paddingTop',
        'paddingRight',
        'paddingLeft',
        'paddingBottom',
        'marginTop',
        'marginRight',
        'marginLeft',
        'marginBottom',
        'alignmentX',
        'alignmentY',
        'transformAlignmentX',
        'transformAlignmentY',
      ];

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
    _constraints = visitor(_constraints, widget.constraints,
            (value) => BoxConstraintsTween(begin: value as BoxConstraints?))
        as BoxConstraintsTween?;
    _transform = visitor(_transform, widget.transform,
        (value) => Matrix4Tween(begin: value as Matrix4?)) as Matrix4Tween?;
  }

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    final p = widget.padding;
    final a = widget.alignment;
    final m = widget.margin;
    final ta = widget.transformAlignment;
    _width = visitor(_width, widget.width,
        (v) => PhysicsAnimatedProperty(key: 'width', initialValue: v));
    _height = visitor(_height, widget.height,
        (v) => PhysicsAnimatedProperty(key: 'height', initialValue: v));
    _paddingTop = visitor(_paddingTop, p?.top,
        (v) => PhysicsAnimatedProperty(key: 'paddingTop', initialValue: v));
    _paddingRight = visitor(_paddingRight, p?.right,
        (v) => PhysicsAnimatedProperty(key: 'paddingRight', initialValue: v));
    _paddingLeft = visitor(_paddingLeft, p?.left,
        (v) => PhysicsAnimatedProperty(key: 'paddingLeft', initialValue: v));
    _paddingBottom = visitor(_paddingBottom, p?.bottom,
        (v) => PhysicsAnimatedProperty(key: 'paddingBottom', initialValue: v));
    _marginTop = visitor(_marginTop, m?.top,
        (v) => PhysicsAnimatedProperty(key: 'marginTop', initialValue: v));
    _marginRight = visitor(_marginRight, m?.right,
        (v) => PhysicsAnimatedProperty(key: 'marginRight', initialValue: v));
    _marginLeft = visitor(_marginLeft, m?.left,
        (v) => PhysicsAnimatedProperty(key: 'marginLeft', initialValue: v));
    _marginBottom = visitor(_marginBottom, m?.bottom,
        (v) => PhysicsAnimatedProperty(key: 'marginBottom', initialValue: v));
    _alignmentX = visitor(_alignmentX, a?.x,
        (v) => PhysicsAnimatedProperty(key: 'alignmentX', initialValue: v));
    _alignmentY = visitor(_alignmentY, a?.y,
        (v) => PhysicsAnimatedProperty(key: 'alignmentY', initialValue: v));
    _transformAlignmentX = visitor(
        _transformAlignmentX,
        ta?.x,
        (v) => PhysicsAnimatedProperty(
            key: 'transformAlignmentX', initialValue: v));
    _transformAlignmentY = visitor(
        _transformAlignmentY,
        ta?.y,
        (v) => PhysicsAnimatedProperty(
            key: 'transformAlignmentY', initialValue: v));
  }

  @override
  Widget build(BuildContext context) {
    final pt = evaluate(_paddingTop);
    final pr = evaluate(_paddingRight);
    final pl = evaluate(_paddingLeft);
    final pb = evaluate(_paddingBottom);
    final mt = evaluate(_marginTop);
    final mr = evaluate(_marginRight);
    final ml = evaluate(_marginLeft);
    final mb = evaluate(_marginBottom);
    final ax = evaluate(_alignmentX);
    final ay = evaluate(_alignmentY);
    final tax = evaluate(_transformAlignmentX);
    final tay = evaluate(_transformAlignmentY);
    final p = pt != null && pr != null && pl != null && pb != null
        ? EdgeInsets.only(top: pt, right: pr, left: pl, bottom: pb)
        : widget.padding;
    final m = mt != null && mr != null && ml != null && mb != null
        ? EdgeInsets.only(top: mt, right: mr, left: ml, bottom: mb)
        : widget.margin;
    final a = ax != null && ay != null ? Alignment(ax, ay) : widget.alignment;
    final ta = tax != null && tay != null
        ? Alignment(tax, tay)
        : widget.transformAlignment;
    return BetterPadding(
      padding: m ?? EdgeInsets.zero,
      child: Container(
        decoration: _decoration?.evaluate(animation),
        foregroundDecoration: _foregroundDecoration?.evaluate(animation),
        alignment: a,
        constraints: _constraints?.evaluate(animation).normalize(),
        transform: _transform?.evaluate(animation),
        transformAlignment: ta,
        clipBehavior: widget.clipBehavior,
        width: evaluate(_width)?.clamp(0, double.infinity),
        height: evaluate(_height)?.clamp(0, double.infinity),
        child: BetterPadding(
          padding: p ?? EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );
  }
}

/// {@template a_sized_box}
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
/// {@endtemplate}
class ASizedBox extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [ASizedBox].
  /// {@macro a_sized_box}
  const ASizedBox({
    super.key,
    this.width,
    this.height,
    super.duration,
    super.physics,
    super.onEnd,
    this.child,
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

class _ASizedBoxState extends PhysicsAnimatedWidgetBaseState<ASizedBox> {
  PhysicsAnimatedProperty? _width, _height;

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _width = visitor(_width, widget.width,
        (v) => PhysicsAnimatedProperty(key: 'width', initialValue: v));
    _height = visitor(_height, widget.height,
        (v) => PhysicsAnimatedProperty(key: 'height', initialValue: v));
  }

  @override
  List<String> get physicsAnimatedProperties => const ['width', 'height'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: evaluate(_width),
      height: evaluate(_height),
      child: widget.child,
    );
  }
}

/// {@template a_padding}
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
/// {@endtemplate}
class APadding extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [APadding].
  /// {@macro a_padding}
  const APadding({
    super.key,
    required this.padding,
    super.duration,
    super.physics,
    this.child,
    super.onEnd,
  });

  final EdgeInsets padding;
  final Widget? child;

  @override
  State<APadding> createState() => _APaddingState();
}

class _APaddingState extends PhysicsAnimatedWidgetBaseState<APadding> {
  PhysicsAnimatedProperty? _top, _right, _left, _bottom;

  @override
  List<String> get physicsAnimatedProperties => const [
        'top',
        'right',
        'left',
        'bottom',
      ];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    final p = widget.padding;
    _top = visitor(_top, p.top,
        (v) => PhysicsAnimatedProperty(key: 'top', initialValue: v));
    _right = visitor(_right, p.right,
        (v) => PhysicsAnimatedProperty(key: 'right', initialValue: v));
    _left = visitor(_left, p.left,
        (v) => PhysicsAnimatedProperty(key: 'left', initialValue: v));
    _bottom = visitor(_bottom, p.bottom,
        (v) => PhysicsAnimatedProperty(key: 'bottom', initialValue: v));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<PhysicsAnimatedProperty>('top', _top,
        defaultValue: null));
    description.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'right', _right,
        defaultValue: null));
    description.add(DiagnosticsProperty<PhysicsAnimatedProperty>('left', _left,
        defaultValue: null));
    description.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'bottom', _bottom,
        defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final top = evaluate(_top);
    final right = evaluate(_right);
    final left = evaluate(_left);
    final bottom = evaluate(_bottom);
    return BetterPadding(
      padding: top != null && right != null && left != null && bottom != null
          ? EdgeInsets.only(
              top: top,
              right: right,
              left: left,
              bottom: bottom,
            )
          : widget.padding,
      child: widget.child,
    );
  }
}

/// {@template a_align}
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
/// {@endtemplate}
class AAlign extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [AAlign].
  /// {@macro a_align}
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

  final Alignment alignment;
  final Widget? child;
  final double? heightFactor;
  final double? widthFactor;

  @override
  State<AAlign> createState() => _AAlignState();
}

class _AAlignState extends PhysicsAnimatedWidgetBaseState<AAlign> {
  PhysicsAnimatedProperty? _alignmentX,
      _alignmentY,
      _heightFactor,
      _widthFactor;

  @override
  List<String> get physicsAnimatedProperties => const [
        'alignmentX',
        'alignmentY',
        'heightFactor',
        'widthFactor',
      ];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _alignmentX = visitor(
        _alignmentX,
        widget.alignment.x,
        (dynamic value) =>
            PhysicsAnimatedProperty(key: 'alignmentX', initialValue: value));
    _alignmentY = visitor(
        _alignmentY,
        widget.alignment.y,
        (dynamic value) =>
            PhysicsAnimatedProperty(key: 'alignmentY', initialValue: value));
    _heightFactor = visitor(
        _heightFactor,
        widget.heightFactor,
        (dynamic value) =>
            PhysicsAnimatedProperty(key: 'heightFactor', initialValue: value));
    _widthFactor = visitor(
        _widthFactor,
        widget.widthFactor,
        (dynamic value) =>
            PhysicsAnimatedProperty(key: 'widthFactor', initialValue: value));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'alignmentX', _alignmentX,
        defaultValue: null));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'alignmentY', _alignmentY,
        defaultValue: null));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'widthFactor', _widthFactor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'heightFactor', _heightFactor,
        defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final alignX = evaluate(_alignmentX);
    final alignY = evaluate(_alignmentY);
    return Align(
      alignment: alignX != null && alignY != null
          ? Alignment(alignX, alignY)
          : widget.alignment,
      heightFactor: evaluate(_heightFactor)?.clamp(0.0, double.infinity),
      widthFactor: evaluate(_widthFactor)?.clamp(0.0, double.infinity),
      child: widget.child,
    );
  }
}

/// {@template a_positioned_full}
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
/// {@endtemplate}
class APositioned extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [APositioned].
  /// {@macro a_positioned_full}
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

class _APositionedState extends PhysicsAnimatedWidgetBaseState<APositioned> {
  PhysicsAnimatedProperty? _left, _top, _right, _bottom, _width, _height;

  @override
  List<String> get physicsAnimatedProperties => const [
        'left',
        'top',
        'right',
        'bottom',
        'width',
        'height',
      ];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _left = visitor(_left, widget.left,
        (dynamic v) => PhysicsAnimatedProperty(key: 'left', initialValue: v));
    _top = visitor(_top, widget.top,
        (dynamic v) => PhysicsAnimatedProperty(key: 'top', initialValue: v));
    _right = visitor(_right, widget.right,
        (dynamic v) => PhysicsAnimatedProperty(key: 'right', initialValue: v));
    _bottom = visitor(_bottom, widget.bottom,
        (dynamic v) => PhysicsAnimatedProperty(key: 'bottom', initialValue: v));
    _width = visitor(_width, widget.width,
        (dynamic v) => PhysicsAnimatedProperty(key: 'width', initialValue: v));
    _height = visitor(_height, widget.height,
        (dynamic v) => PhysicsAnimatedProperty(key: 'height', initialValue: v));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: evaluate(_left) ?? widget.left,
      top: evaluate(_top) ?? widget.top,
      right: evaluate(_right) ?? widget.right,
      bottom: evaluate(_bottom) ?? widget.bottom,
      width: evaluate(_width) ?? widget.width,
      height: evaluate(_height) ?? widget.height,
      child: widget.child,
    );
  }
}

/// {@template a_positioned_directional}
/// Physics-based equivalent of [AnimatedPositionedDirectional], renamed to [APositionedDirectional].
/// Directional equivalent of [APositioned].
///
/// Copied from [APositioned]:
/// {@macro a_positioned}
/// {@endtemplate}
class APositionedDirectional extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [APositionedDirectional].
  /// {@macro a_positioned_directional}
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
    extends PhysicsAnimatedWidgetBaseState<APositionedDirectional> {
  PhysicsAnimatedProperty? _start, _top, _end, _bottom, _width, _height;

  @override
  List<String> get physicsAnimatedProperties => const [
        'start',
        'top',
        'end',
        'bottom',
        'width',
        'height',
      ];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _start = visitor(_start, widget.start,
        (v) => PhysicsAnimatedProperty(key: 'start', initialValue: v));
    _top = visitor(_top, widget.top,
        (v) => PhysicsAnimatedProperty(key: 'top', initialValue: v));
    _end = visitor(_end, widget.end,
        (v) => PhysicsAnimatedProperty(key: 'end', initialValue: v));
    _bottom = visitor(_bottom, widget.bottom,
        (v) => PhysicsAnimatedProperty(key: 'bottom', initialValue: v));
    _width = visitor(_width, widget.width,
        (v) => PhysicsAnimatedProperty(key: 'width', initialValue: v));
    _height = visitor(_height, widget.height,
        (v) => PhysicsAnimatedProperty(key: 'height', initialValue: v));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      start: evaluate(_start) ?? widget.start,
      top: evaluate(_top) ?? widget.top,
      end: evaluate(_end) ?? widget.end,
      bottom: evaluate(_bottom) ?? widget.bottom,
      width: evaluate(_width) ?? widget.width,
      height: evaluate(_height) ?? widget.height,
      child: widget.child,
    );
  }
}

/// {@template a_scale}
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
/// {@endtemplate}
class AScale extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [AScale].
  /// {@macro a_scale}
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
  PhysicsAnimatedProperty? _scale;

  @override
  List<String> get physicsAnimatedProperties => ['scale'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _scale = visitor(_scale, widget.scale,
        (v) => PhysicsAnimatedProperty(key: 'scale', initialValue: v))!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('scale', _scale));
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: getAnimation(_scale)!,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// {@template a_rotation}
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
/// {@endtemplate}
class ARotation extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [ARotation].
  /// {@macro a_rotation}
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
  PhysicsAnimatedProperty? _turns;

  @override
  List<String> get physicsAnimatedProperties => ['turns'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _turns = visitor(_turns, widget.turns,
        (v) => PhysicsAnimatedProperty(key: 'turns', initialValue: v))!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('turns', _turns));
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: getAnimation(_turns)!,
      alignment: widget.alignment,
      filterQuality: widget.filterQuality,
      child: widget.child,
    );
  }
}

/// {@template a_slide}
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
/// {@endtemplate}
class ASlide extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [ASlide].
  /// {@macro a_slide}
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
  PhysicsAnimatedProperty? _offsetX;
  PhysicsAnimatedProperty? _offsetY;
  late Animation<Offset> _offsetAnimation;

  @override
  List<String> get physicsAnimatedProperties => ['offsetX', 'offsetY'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _offsetX = visitor(_offsetX, widget.offset.dx,
        (v) => PhysicsAnimatedProperty(key: 'offsetX', initialValue: v))!;
    _offsetY = visitor(_offsetY, widget.offset.dy,
        (v) => PhysicsAnimatedProperty(key: 'offsetY', initialValue: v))!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('offsetX', _offsetX));
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('offsetY', _offsetY));
  }

  @override
  void didUpdatePhysicsProperties() {
    final x = getAnimation(_offsetX)!;
    final y = getAnimation(_offsetY)!;
    _offsetAnimation = _OffsetAnimation(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: widget.child);
  }
}

/// Helper class to combine 2 double animations into an offset animation.
class _OffsetAnimation extends Animation<Offset>
    with
        AnimationLazyListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  _OffsetAnimation(this.x, this.y);
  final Animation<double> x, y;

  @override
  Offset get value => Offset(x.value, y.value);

  @override
  void didStartListening() {
    x.addListener(_maybeNotifyListeners);
    x.addStatusListener(_maybeNotifyStatusListeners);
    y.addListener(_maybeNotifyListeners);
    y.addStatusListener(_maybeNotifyStatusListeners);
  }

  @override
  void didStopListening() {
    x.removeListener(_maybeNotifyListeners);
    x.removeStatusListener(_maybeNotifyStatusListeners);
    y.removeListener(_maybeNotifyListeners);
    y.removeStatusListener(_maybeNotifyStatusListeners);
  }

  @override
  AnimationStatus get status => y.status.isAnimating ? y.status : x.status;

  @override
  String toString() => 'OffsetAnimation($x, $y)';

  AnimationStatus? _lastStatus;
  void _maybeNotifyStatusListeners(AnimationStatus _) {
    if (status != _lastStatus) {
      _lastStatus = status;
      notifyStatusListeners(status);
    }
  }

  Offset? _lastValue;
  void _maybeNotifyListeners() {
    if (value != _lastValue) {
      _lastValue = value;
      notifyListeners();
    }
  }
}

/// {@template a_opacity_full}
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
/// {@endtemplate}
class AOpacity extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [AOpacity].
  /// {@macro a_opacity_full}
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
  PhysicsAnimatedProperty? _opacity;

  @override
  List<String> get physicsAnimatedProperties => ['opacity'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _opacity = visitor(_opacity, widget.opacity,
        (v) => PhysicsAnimatedProperty(key: 'opacity', initialValue: v))!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('opacity', _opacity));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: getAnimation(_opacity)!,
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
      child: widget.child,
    );
  }
}

/// {@template a_sliver_opacity}
/// Physics-based equivalent of [SliverAnimatedOpacity], renamed to [ASliverOpacity].
/// {@macro a_opacity}
/// {@endtemplate}
class ASliverOpacity extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [ASliverOpacity].
  /// {@macro a_sliver_opacity}
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

class _ASliverOpacityState
    extends PhysicsAnimatedWidgetBaseState<ASliverOpacity> {
  PhysicsAnimatedProperty? _opacity;

  @override
  List<String> get physicsAnimatedProperties => ['opacity'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _opacity = visitor(_opacity, widget.opacity,
        (v) => PhysicsAnimatedProperty(key: 'opacity', initialValue: v))!;
  }

  @override
  Widget build(BuildContext context) {
    final val = evaluate(_opacity)!;
    return SliverOpacity(
      opacity: val.clamp(0.0, 1.0),
      sliver: widget.sliver,
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<PhysicsAnimatedProperty>('opacity', _opacity));
  }
}

/// {@template a_default_text_style}
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
/// {@endtemplate}
class ADefaultTextStyle extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [ADefaultTextStyle].
  /// {@macro a_default_text_style}
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
    extends PhysicsAnimatedWidgetBaseState<ADefaultTextStyle> {
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

/// {@template a_physical_model}
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
/// {@endtemplate}
class APhysicalModel extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [APhysicalModel].
  /// {@macro a_physical_model}
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

class _APhysicalModelState
    extends PhysicsAnimatedWidgetBaseState<APhysicalModel> {
  BorderRadiusTween? _borderRadius;
  ColorTween? _color;
  ColorTween? _shadowColor;

  PhysicsAnimatedProperty? _elevation;

  @override
  List<String> get physicsAnimatedProperties => ['elevation'];

  @override
  void forEachTween(PhysicsTweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(
            _borderRadius,
            widget.borderRadius ?? BorderRadius.zero,
            (v) => BorderRadiusTween(begin: v as BorderRadius))
        as BorderRadiusTween?;
    _color = visitor(_color, widget.color, (v) => ColorTween(begin: v as Color))
        as ColorTween?;
    _shadowColor = visitor(_shadowColor, widget.shadowColor,
        (v) => ColorTween(begin: v as Color)) as ColorTween?;
  }

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _elevation = visitor(_elevation, widget.elevation,
        (v) => PhysicsAnimatedProperty(key: 'elevation', initialValue: v));
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
      elevation: (evaluate(_elevation) ?? widget.elevation)
          .clamp(0.0, double.infinity),
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
    properties.add(
        DiagnosticsProperty<PhysicsAnimatedProperty>('elevation', _elevation));
    properties.add(DiagnosticsProperty<ColorTween>('color', _color));
    properties
        .add(DiagnosticsProperty<ColorTween>('shadowColor', _shadowColor));
  }
}

/// {@template a_fractionally_sized_box}
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
/// {@endtemplate}
class AFractionallySizedBox extends ImplicitlyPhysicsAnimatedWidget {
  /// Creates a new [AFractionallySizedBox].
  /// {@macro a_fractionally_sized_box}
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

  /// How to align the child within the available space.
  ///
  /// The default is [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final Alignment alignment;

  /// If non-null, the fraction of the incoming width given to the child.
  ///
  /// If non-null, the child is given a tight width constraint that is the product
  /// of the incoming width constraint and this factor.
  ///
  /// If null, the child is given the incoming width constraints.
  final double? widthFactor;

  /// If non-null, the fraction of the incoming height given to the child.
  ///
  /// If non-null, the child is given a tight height constraint that is the product
  /// of the incoming height constraint and this factor.
  ///
  /// If null, the child is given the incoming height constraints.
  final double? heightFactor;
  final Widget? child;

  @override
  State<AFractionallySizedBox> createState() => _AFractionallySizedBoxState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor));
    properties.add(DoubleProperty('heightFactor', heightFactor));
  }
}

class _AFractionallySizedBoxState
    extends PhysicsAnimatedWidgetBaseState<AFractionallySizedBox> {
  PhysicsAnimatedProperty? _alignmentX,
      _alignmentY,
      _widthFactor,
      _heightFactor;

  @override
  List<String> get physicsAnimatedProperties =>
      ['alignmentX', 'alignmentY', 'widthFactor', 'heightFactor'];

  @override
  void forEachPhysicsProperty(PhysicsPropertyVisitor visitor) {
    _alignmentX = visitor(_alignmentX, widget.alignment.x,
        (v) => PhysicsAnimatedProperty(key: 'alignmentX', initialValue: v));
    _alignmentY = visitor(_alignmentY, widget.alignment.y,
        (v) => PhysicsAnimatedProperty(key: 'alignmentY', initialValue: v));
    _widthFactor = visitor(_widthFactor, widget.widthFactor,
        (v) => PhysicsAnimatedProperty(key: 'widthFactor', initialValue: v));
    _heightFactor = visitor(_heightFactor, widget.heightFactor,
        (v) => PhysicsAnimatedProperty(key: 'heightFactor', initialValue: v));
  }

  @override
  Widget build(BuildContext context) {
    final alignX = evaluate(_alignmentX);
    final alignY = evaluate(_alignmentY);
    return FractionallySizedBox(
      alignment: alignX != null && alignY != null
          ? Alignment(alignX, alignY)
          : widget.alignment,
      widthFactor: evaluate(_widthFactor)?.clamp(0.0, double.infinity),
      heightFactor: evaluate(_heightFactor)?.clamp(0.0, double.infinity),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'alignmentX', _alignmentX));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'alignmentY', _alignmentY));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'widthFactor', _widthFactor));
    properties.add(DiagnosticsProperty<PhysicsAnimatedProperty>(
        'heightFactor', _heightFactor));
  }
}

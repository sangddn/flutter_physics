part of 'physics_controller.dart';

/// {@template physics_controller_multi}
/// A controller for multi-dimensional physics-based animations that supports both standard curves
/// and physics simulations.
///
/// Similar to [PhysicsController], but works with multiple dimensions to control animations in
/// N-dimensional space using lists of values. Key features include:
///
/// * Accepts both standard [Curve]s and [PhysicsSimulation]s (like [Spring])
/// * Dynamically responds to changes mid-animation when using physics simulations
/// * Maintains velocity across animation updates
/// * Drop-in replacement for [AnimationController] in multi-dimensional contexts
///
/// ## Usage
///
/// Create a controller with a [TickerProvider] (usually from [SingleTickerProviderStateMixin]):
///
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
///   late final _controller = PhysicsControllerMulti(
///     dimensions: 3,  // For 3D space
///     vsync: this,
///     defaultPhysics: [
///       Spring.elegant, // X-axis physics
///       Spring.swift,   // Y-axis physics
///       Spring.gentle,  // Z-axis physics
///     ],
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// ### Using with Standard Curves
///
/// When using standard curves, you must provide a duration either in the constructor
/// or in animation methods:
///
/// ```dart
/// // In constructor
/// final controller = PhysicsControllerMulti(
///   dimensions: 2,
///   vsync: this,
///   duration: const Duration(milliseconds: 300),
///   defaultPhysics: [
///     Curves.easeOut,
///     Curves.easeIn,
///   ],
/// );
///
/// // Or in methods
/// controller.animateTo(
///   [100.0, 200.0],
///   duration: const Duration(milliseconds: 300),
///   physics: [
///     Curves.easeOut,
///     Curves.easeIn,
///   ],
/// );
/// ```
///
/// ### Using with Physics Simulations
///
/// {@tool snippet}
/// Physics simulations like [Spring] automatically calculate their duration and
/// respond naturally to interruptions:
///
/// ```dart
/// class PhysicsObject extends StatefulWidget {
///   const PhysicsObject({super.key});
///
///   @override
///   State<PhysicsObject> createState() => _PhysicsObjectState();
/// }
///
/// class _PhysicsObjectState extends State<PhysicsObject>
///     with SingleTickerProviderStateMixin {
///   late final _controller = PhysicsControllerMulti.unbounded(
///     dimensions: 3,
///     vsync: this,
///     defaultPhysics: [
///       Spring.elegant,
///       Spring.elegant,
///       Spring.elegant,
///     ],
///   );
///
///   List<double> _position = [0, 0, 0];
///
///   void _onUpdate(List<double> delta) {
///     for (int i = 0; i < _position.length; i++) {
///       _position[i] += delta[i];
///     }
///     _controller.animateTo(_position);
///   }
///
///   void _onEnd(List<double> velocity) {
///     // Physics simulation maintains momentum
///     _controller.animateTo(
///       List.filled(3, 0),
///       velocityDelta: velocity,
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return AnimatedBuilder(
///       animation: _controller,
///       builder: (context, child) {
///         return Transform.translate(
///           offset: Offset(_controller.value[0], _controller.value[1]),
///           child: Transform.translate(
///             offset: Offset(0, _controller.value[2]),
///             child: child,
///           ),
///         );
///       },
///       child: const Card(
///         child: FlutterLogo(size: 128),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// ### Responding to Changes Mid-Animation
///
/// Physics simulations maintain momentum when target values change:
///
/// ```dart
/// // Initial animation
/// controller.animateTo([100, 100, 100]);
///
/// // Later, interrupt with new target
/// await Future.delayed(const Duration(milliseconds: 100));
/// controller.animateTo([50, 50, 50]); // Maintains current velocity
/// ```
///
/// ## Common Use Cases
///
/// * Multi-dimensional animations (3D, 4D, etc.)
/// * Complex physics simulations
/// * Particle systems
/// * Data visualization animations
///
/// This controller can be used anywhere [AnimationController] is accepted,
/// with the values accessible as a list.
///
/// See also:
///
/// * [PhysicsController2D], for 2D-specific animations
/// * [Spring], a physics simulation that creates natural-feeling animations
/// * [PhysicsController], the 1D version of this controller
/// * [AnimationController], Flutter's standard animation controller
/// {@endtemplate}
class PhysicsControllerMulti extends Animation<UnmodifiableListView<double>>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  PhysicsControllerMulti({
    required this.dimensions,
    List<double>? value,
    this.debugLabel,
    required TickerProvider vsync,
    this.animationBehavior = AnimationBehavior.normal,
    List<Physics>? defaultPhysics,
    Physics? defaultPhysicsForAllDimensions,
    List<double>? lowerBound,
    List<double>? upperBound,
    this.duration,
    this.reverseDuration,
  })  : assert(dimensions > 0, "Dimensions must be greater than 0"),
        assert(defaultPhysics == null || defaultPhysics.length == dimensions,
            "Default physics must be provided for all dimensions. If you want to use the same physics for all dimensions, use the `defaultPhysicsForAllDimensions` parameter."),
        assert(lowerBound == null || lowerBound.length == dimensions,
            "Lower bound must be provided for all dimensions"),
        assert(upperBound == null || upperBound.length == dimensions,
            "Upper bound must be provided for all dimensions"),
        assert(value == null || value.length == dimensions,
            "Value must be provided for all dimensions"),
        _direction = _AnimationDirection.forward,
        _defaultPhysics = defaultPhysics ??
            List.filled(
                dimensions, defaultPhysicsForAllDimensions ?? Spring.elegant),
        lowerBound =
            UnmodifiableListView(lowerBound ?? List.filled(dimensions, 0.0)),
        upperBound =
            UnmodifiableListView(upperBound ?? List.filled(dimensions, 1.0)) {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue((value ?? List.filled(dimensions, 0.0)));
  }

  /// Creates an unbounded 2D physics-based animation controller.
  ///
  /// * [value] is the initial position of the animation. Defaults to [Offset.zero].
  ///
  /// * [duration] is the length of time this animation should last.
  ///
  /// * [debugLabel] is a string to help identify this animation during debugging.
  ///
  /// * [vsync] is the required [TickerProvider] for the current context.
  PhysicsControllerMulti.unbounded({
    required int dimensions,
    List<double>? value,
    String? debugLabel,
    required TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    List<Physics>? defaultPhysics,
    Physics? defaultPhysicsForAllDimensions,
    List<double>? lowerBound,
    List<double>? upperBound,
    Duration? duration,
    Duration? reverseDuration,
  }) : this(
          dimensions: dimensions,
          value: value,
          debugLabel: debugLabel,
          vsync: vsync,
          animationBehavior: animationBehavior,
          defaultPhysics: defaultPhysics,
          defaultPhysicsForAllDimensions: defaultPhysicsForAllDimensions,
          lowerBound: List.filled(dimensions, double.negativeInfinity),
          upperBound: List.filled(dimensions, double.infinity),
          duration: duration,
          reverseDuration: reverseDuration,
        );

  /// The number of dimensions this controller animates.
  /// For example, 3 for 3D space, 4 for 4D space, etc.
  final int dimensions;

  /// A label that is used in the [toString] output. Useful for debugging.
  final String? debugLabel;

  /// The default physics simulation to use for each dimension.
  ///
  /// Must contain exactly [dimensions] number of physics simulations.
  /// Each simulation controls the motion along its respective axis.
  List<Physics> _defaultPhysics;
  List<Physics> get defaultPhysics => _defaultPhysics;

  /// Sets the default physics simulation for each dimension.
  ///
  /// If the current and new physics are both physics-based ([PhysicsSimulation]s),
  /// this will maintain momentum from the current simulation.
  ///
  /// Must contain exactly [dimensions] number of physics simulations.
  set defaultPhysics(List<Physics> physics) {
    final currentSims = _sims;
    final shouldUpdate = !listEquals(_defaultPhysics, physics) &&
        currentSims.isPhysicsBased() &&
        physics.isPhysicsBased();
    _defaultPhysics = physics;
    if (shouldUpdate) {
      final velocity = stop();
      final currents = _sims.cast<PhysicsSimulation>();
      final news = physics.cast<PhysicsSimulation>();
      final effectiveSims = news
          .indexedMap(
            (i, s) => s.copyWith(
              start: _value[i],
              end: currents[i].end,
              initialVelocity: velocity[i],
            ),
          )
          .toList();
      _startSimulations(effectiveSims);
    }
  }

  /// The behavior of the controller when animations are disabled via
  /// [AccessibilityFeatures.disableAnimations].
  final AnimationBehavior animationBehavior;

  /// The lower bounds for each dimension.
  ///
  /// Each value represents the minimum allowed value for its respective dimension.
  /// The list length matches [dimensions].
  final UnmodifiableListView<double> lowerBound;

  /// The upper bounds for each dimension.
  ///
  /// Each value represents the maximum allowed value for its respective dimension.
  /// The list length matches [dimensions].
  final UnmodifiableListView<double> upperBound;

  /// The duration of the animation when using non-physics-based animations.
  ///
  /// Required when using [Curve]s instead of [PhysicsSimulation]s.
  Duration? duration;

  /// The duration of the animation when reversing with non-physics-based animations.
  ///
  /// If null, [duration] is used for both forward and reverse animations.
  Duration? reverseDuration;

  Ticker? _ticker;
  final List<Simulation> _sims = [];
  _AnimationDirection _direction;

  /// The current position of the animation in N-dimensional space.
  ///
  /// Returns an unmodifiable list of length [dimensions] representing
  /// the current value along each axis.
  @override
  UnmodifiableListView<double> get value {
    assert(_value.length == dimensions);
    return _value;
  }

  late UnmodifiableListView<double> _value;

  /// Sets the controller's position to [newValue], stopping any running simulation.
  ///
  /// The values will be clamped between [lowerBound] and [upperBound].
  /// Must provide exactly [dimensions] number of values.
  set value(List<double> newValue) {
    stop();
    _internalSetValue(UnmodifiableListView(newValue));
    notifyListeners();
    _checkStatusChanged();
  }

  /// The current velocity of the animation in points per second.
  ///
  /// Returns a list of length [dimensions] representing the velocity
  /// along each axis. Returns zeros when not animating.
  UnmodifiableListView<double> get velocity {
    if (!isAnimating) {
      return UnmodifiableListView(List.filled(dimensions, 0.0));
    }
    final double t = lastElapsedDuration!.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond;
    if (_sims.isEmpty) throw StateError("No simulations running");
    return _sims.dx(t);
  }

  void _internalSetValue(List<double> newValue) {
    assert(newValue.length == dimensions);
    _value = _clampDoubles(newValue, lowerBound, upperBound);
    if (listEquals(_value, lowerBound)) {
      _status = AnimationStatus.dismissed;
    } else if (listEquals(_value, upperBound)) {
      _status = AnimationStatus.completed;
    } else {
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  /// The time elapsed since the animation started.
  ///
  /// Returns null if the animation is not running.
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  /// Whether this animation is currently running in either direction.
  @override
  bool get isAnimating => _ticker != null && _ticker!.isActive;

  @override
  AnimationStatus get status => _status;
  late AnimationStatus _status;

  /// Stops the current animation and returns the velocity at the moment of stopping.
  ///
  /// The returned velocity can be used to maintain momentum in subsequent animations.
  UnmodifiableListView<double> stop({bool canceled = true}) {
    final velocity = this.velocity;
    _sims.clear();
    _lastElapsedDuration = null;
    _ticker?.stop(canceled: canceled);
    return velocity;
  }

  /// Release the resources used by this object.
  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    clearStatusListeners();
    clearListeners();
    super.dispose();
  }

  /// Resets the controller's value to [lowerBound], stopping the animation.
  void reset() {
    value = lowerBound;
  }

  /// Drives the animation from its current position to [target].
  ///
  /// * [target] must contain exactly [dimensions] number of values
  /// * [duration] overrides [this.duration] if provided
  /// * [physics] overrides [defaultPhysics] if provided
  /// * [velocityDelta] adds to the current velocity when using physics simulations
  /// * [velocityOverride] replaces the current velocity when using physics simulations
  TickerFuture animateTo(
    List<double> target, {
    Duration? duration,
    List<Physics>? physics,
    List<double>? velocityDelta,
    List<double>? velocityOverride,
  }) {
    physics ??= defaultPhysics;
    assert(
      _ticker != null,
      'PhysicsControllerMulti.animateTo() called after PhysicsControllerMulti.dispose()\n'
      'PhysicsControllerMulti methods should not be used after calling dispose.',
    );
    assert(
      physics.isPhysicsBased() ||
          (velocityOverride == null && velocityDelta == null),
      'VelocityDelta and VelocityOverride are only supported when physics is a PhysicsSimulation.',
    );
    assert(
      velocityOverride == null || velocityOverride.length == dimensions,
      'Invalid dimensions for velocityOverride.',
    );
    assert(
      velocityDelta == null || velocityDelta.length == dimensions,
      'Invalid dimensions for velocityDelta.',
    );
    assert(
      physics.length == dimensions,
      'Invalid dimensions for physics.',
    );
    assert(
      target.length == dimensions,
      'Invalid dimensions for target.',
    );
    if (duration == null) {
      final range = upperBound - lowerBound;
      final remainingFraction = range.isAllFinite()
          ? (target - _value).euclideanDistance / range.euclideanDistance
          : 1.0;
      final directionDuration =
          (_direction == _AnimationDirection.reverse && reverseDuration != null)
              ? reverseDuration
              : this.duration;
      duration = directionDuration == null
          ? null
          : directionDuration * remainingFraction;
    } else if (listEquals(target, value)) {
      duration = Duration.zero;
    }

    final durationScale = duration == null
        ? null
        : switch (animationBehavior) {
            AnimationBehavior.normal
                when SemanticsBinding.instance.disableAnimations =>
              0.05,
            AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
          };

    _direction = _AnimationDirection.forward;

    if (duration == Duration.zero) {
      if (!listEquals(value, target)) {
        _value =
            _clampDoubles(UnmodifiableListView(target), lowerBound, upperBound);
        notifyListeners();
      }
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      _checkStatusChanged();
      return TickerFuture.complete();
    }

    final velocity = stop();

    if (physics.isPhysicsBased()) {
      return _startSimulations(
        physics
            .indexedMap(
              (index, p) => (p as PhysicsSimulation).copyWith(
                start: _value[index],
                end: target[index],
                duration: duration,
                durationScale: durationScale,
                initialVelocity: durationScale == null
                    ? (velocityOverride?[index] ??
                        velocity[index] +
                            p.initialVelocity +
                            (velocityDelta?[index] ?? 0.0))
                    : null,
              ),
            )
            .toList(),
      );
    }

    assert(duration != null,
        "[duration] must be provided for non-physics-based animations.");

    return _startSimulations(
      physics
          .indexedMap(
            (index, p) => _InterpolationSimulation(
              _value[index],
              target[index],
              duration!,
              p,
              durationScale!,
            ),
          )
          .toList(),
    );
  }

  /// Starts the animation from the current position (or [from]) to [upperBound].
  ///
  /// Uses [defaultPhysics] for the animation unless otherwise specified.
  TickerFuture forward({List<double>? from}) {
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return animateTo(upperBound);
  }

  /// Starts the animation from the current position (or [from]) to [lowerBound].
  ///
  /// Uses [defaultPhysics] for the animation unless otherwise specified.
  TickerFuture reverse({List<double>? from}) {
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return animateTo(lowerBound);
  }

  /// Drives the animation according to the given 2D simulation.
  TickerFuture animateWith(List<Simulation> simulations) {
    stop();
    _direction = _AnimationDirection.forward;
    return _startSimulations(simulations);
  }

  /// Returns an [Animation<double>] that tracks a single dimension of this controller.
  ///
  /// The [dimension] parameter specifies which dimension to track (0 for X, 1 for Y, etc.).
  /// Throws [RangeError] if [dimension] is out of bounds.
  Animation<double> dimension(int dimension) {
    assert(
      dimension >= 0 && dimension < dimensions,
      "Dimension must be between 0 and ${dimensions - 1}.",
    );
    return _DimensionAnimation(this, dimension);
  }

  TickerFuture _startSimulations(List<Simulation> simulations) {
    assert(!isAnimating);
    assert(simulations.length == dimensions);
    _sims
      ..clear()
      ..addAll(simulations);
    _lastElapsedDuration = Duration.zero;
    _value = _clampDoubles(simulations.x(0), lowerBound, upperBound);
    final TickerFuture result = _ticker!.start();
    // Assume forward if we don't know better
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  /// Repeats the animation between [min] and [max] for [count] times or indefinitely.
  ///
  /// * If [min]/[max] are not provided, uses [lowerBound]/[upperBound]
  /// * If [reverse] is true, alternates direction on each repeat
  /// * If [count] is null, repeats indefinitely
  /// * [physics] overrides [defaultPhysics] if provided
  TickerFuture repeat({
    List<double>? min,
    List<double>? max,
    bool reverse = false,
    int? count,
    List<Physics>? physics,
  }) {
    min ??= lowerBound;
    max ??= upperBound;

    assert(() {
      if (count != null && count <= 0) {
        throw FlutterError(
            'PhysicsControllerMulti.repeat() "count" must be > 0');
      }
      return true;
    }());

    final velocity = stop();
    _direction = _AnimationDirection.forward;

    physics ??= defaultPhysics;

    return _startSimulations(
      value
          .indexedMap((index, val) => _RepeatingSimulation(
                val,
                min![index],
                max![index],
                reverse,
                null,
                physics![index],
                velocity[index],
                _directionSetter,
                count,
              ))
          .toList(),
    );
  }

  void _directionSetter(_AnimationDirection direction) {
    // In a single-axis scenario, we can flip direction easily.
    // In 2D it's ambiguous, so we do the naive approach:
    _direction = direction;
    _status = (direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
  }

  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    final AnimationStatus newStatus = status;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double t =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(t >= 0.0);
    _value = _clampDoubles(_sims.x(t), lowerBound, upperBound);

    if (_sims.isDone(t)) {
      // If done, finalize the status
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }

  @override
  String toStringDetails() {
    final String paused = isAnimating ? '' : '; paused';
    final String ticker =
        _ticker == null ? '; DISPOSED' : (_ticker!.muted ? '; silenced' : '');
    String label = '';
    assert(() {
      if (debugLabel != null) {
        label = '; for $debugLabel';
      }
      return true;
    }());
    return '${super.toStringDetails()} $_value$paused$ticker$label';
  }
}

/// An [Animation] that tracks a single dimension of a [PhysicsControllerMulti].
class _DimensionAnimation extends Animation<double>
    with AnimationWithParentMixin<UnmodifiableListView<double>> {
  _DimensionAnimation(this._parent, this._dimension);

  final PhysicsControllerMulti _parent;
  final int _dimension;

  @override
  Animation<UnmodifiableListView<double>> get parent => _parent;

  @override
  double get value => _parent.value[_dimension];

  @override
  AnimationStatus get status => _parent.status;
}

UnmodifiableListView<double> _clampDoubles(
  List<double> v,
  List<double> min,
  List<double> max,
) {
  assert(v.length == min.length && v.length == max.length);
  final list = UnmodifiableListView(
    // .toList() is necessary to avoid a bug where the list is not updated
    v
        .indexedMap((index, e) => e.clamp(min[index], max[index]))
        .toList(growable: false),
  );
  assert(list.length == v.length);
  return list;
}

extension _MultiSimulations on List<Simulation> {
  bool isPhysicsBased() => every((e) => e is PhysicsSimulation);

  bool isDone(double t) => every((e) => e.isDone(t));

  UnmodifiableListView<double> dx(double t) {
    return UnmodifiableListView(
      map((e) => (e as PhysicsSimulation).x(t)).toList(growable: false),
    );
  }

  UnmodifiableListView<double> x(double t) {
    return UnmodifiableListView(
      map((e) => (e as PhysicsSimulation).x(t)).toList(growable: false),
    );
  }
}

extension _MultiPhysics on List<Physics> {
  bool isPhysicsBased() => every((e) => e is PhysicsSimulation);
}

extension _Utils on List<double> {
  UnmodifiableListView<double> operator -(List<double> other) {
    assert(length == other.length);
    return UnmodifiableListView(
      indexedMap((index, e) => e - other[index]).toList(growable: false),
    );
  }

  double get euclideanDistance {
    return math.sqrt(indexedMap((index, e) => math.pow(e, 2).toDouble())
        .reduce((x, y) => x + y));
  }

  bool isAllFinite() => every((e) => e.isFinite);
}

extension FP<T> on Iterable<T> {
  Iterable<R> indexedMap<R>(R Function(int index, T element) fn) {
    var i = 0;
    return map((e) => fn(i++, e));
  }
}

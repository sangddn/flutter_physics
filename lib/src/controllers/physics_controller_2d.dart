part of 'physics_controller.dart';

/// {@template physics_controller_2d}
/// A controller for 2D physics-based animations that supports both standard curves and physics simulations.
///
/// Similar to [PhysicsController], but works with [Simulation2D] to control animations in 2D space
/// using [Offset] values. Key features include:
///
/// * Accepts both standard [Curve]s and [PhysicsSimulation]s (like [Spring])
/// * Dynamically responds to changes mid-animation when using physics simulations
/// * Maintains velocity across animation updates
/// * Drop-in replacement for [AnimationController] in 2D contexts
///
/// ## Usage
///
/// Create a controller with a [TickerProvider] (usually from [SingleTickerProviderStateMixin]):
///
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
///   late final _controller = PhysicsController2D(
///     vsync: this,
///     defaultPhysics: Simulation2D(
///       Spring.elegant, // X-axis physics
///       Spring.swift,   // Y-axis physics
///     ),
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
/// final controller = PhysicsController2D(
///   vsync: this,
///   duration: const Duration(milliseconds: 300),
///   defaultPhysics: Simulation2D(
///     Curves.easeOut,
///     Curves.easeIn,
///   ),
/// );
///
/// // Or in methods
/// controller.animateTo(
///   const Offset(100, 200),
///   duration: const Duration(milliseconds: 300),
///   physics: Simulation2D(
///     Curves.easeOut,
///     Curves.easeIn,
///   ),
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
/// class PhysicsCard extends StatefulWidget {
///   const PhysicsCard({super.key});
///
///   @override
///   State<PhysicsCard> createState() => _PhysicsCardState();
/// }
///
/// class _PhysicsCardState extends State<PhysicsCard> with SingleTickerProviderStateMixin {
///   late final _controller = PhysicsController2D.unbounded(
///     vsync: this,
///     defaultPhysics: Simulation2D(
///       Spring.elegant,
///       Spring.elegant,
///     ),
///   );
///
///   Offset _position = Offset.zero;
///
///   void _onPanUpdate(DragUpdateDetails details) {
///     _position += details.delta;
///     _controller.animateTo(_position);
///   }
///
///   void _onPanEnd(DragEndDetails details) {
///     // Physics simulation maintains momentum from gesture
///     _controller.animateTo(
///       Offset.zero,
///       velocityDelta: details.velocity.pixelsPerSecond,
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onPanUpdate: _onPanUpdate,
///       onPanEnd: _onPanEnd,
///       child: AnimatedBuilder(
///         animation: _controller,
///         builder: (context, child) {
///           return Transform.translate(
///             offset: _controller.value,
///             child: child,
///           );
///         },
///         child: const Card(
///           child: FlutterLogo(size: 128),
///         ),
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
/// controller.animateTo(const Offset(100, 100));
///
/// // Later, interrupt with new target
/// await Future.delayed(const Duration(milliseconds: 100));
/// controller.animateTo(const Offset(50, 50)); // Maintains current velocity
/// ```
///
/// ## Common Use Cases
///
/// * Gesture-driven animations (drag and release)
/// * 2D transitions and transforms
/// * Interactive UI elements
/// * Natural-feeling animations in 2D space
///
/// This controller can be used anywhere [AnimationController] is accepted:
/// [AnimatedBuilder], [SlideTransition], etc.
///
/// See also:
///
/// * [Simulation2D], for combining physics simulations or curves for 2D motion
/// * [Spring], a physics simulation that creates natural-feeling animations
/// * [PhysicsController], the 1D version of this controller
/// * [AnimationController], Flutter's standard animation controller
/// {@endtemplate}
class PhysicsController2D extends Animation<Offset>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  /// Creates a 2D physics-based animation controller.
  ///
  /// * [value] is the initial position of the animation. Defaults to [Offset.zero].
  ///
  /// * [duration] is the length of time this animation should last.
  ///
  /// * [debugLabel] is a string to help identify this animation during debugging.
  ///
  /// * [vsync] is the required [TickerProvider] for the current context.
  ///
  /// * [lowerBound], [upperBound] define the bounding box for the animation.
  ///   By default, the animation is unbounded: from `(-∞, -∞)` to `(∞, ∞)`.
  PhysicsController2D({
    Offset? value,
    this.debugLabel,
    required TickerProvider vsync,
    this.animationBehavior = AnimationBehavior.normal,
    Simulation2D? defaultPhysics,
    this.lowerBound = const Offset(0.0, 0.0),
    this.upperBound = const Offset(1.0, 1.0),
    this.duration,
    this.reverseDuration,
  })  : _direction = _AnimationDirection.forward,
        _defaultPhysics =
            defaultPhysics ?? Simulation2D(Spring.elegant, Spring.elegant) {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? Offset.zero);
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
  PhysicsController2D.unbounded({
    Offset? value,
    String? debugLabel,
    required TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    Simulation2D? defaultPhysics,
    Duration? duration,
    Duration? reverseDuration,
  }) : this(
          value: value,
          debugLabel: debugLabel,
          vsync: vsync,
          animationBehavior: animationBehavior,
          defaultPhysics: defaultPhysics,
          lowerBound:
              const Offset(double.negativeInfinity, double.negativeInfinity),
          upperBound: const Offset(double.infinity, double.infinity),
          duration: duration,
          reverseDuration: reverseDuration,
        );

  /// A label that is used in the [toString] output.
  final String? debugLabel;

  /// The default physics simulation to use for this controller.
  Simulation2D _defaultPhysics;
  Simulation2D get defaultPhysics => _defaultPhysics;

  /// Sets the default physics simulation to use for this controller.
  ///
  /// If the physics simulation is physics-based, it will maintain momentum
  /// from the current simulation.
  set defaultPhysics(Simulation2D physics) {
    final currentSims = _sims;
    final shouldUpdate = _defaultPhysics != physics &&
        currentSims != null &&
        currentSims.isPhysicsBased() &&
        physics.isPhysicsBased();
    _defaultPhysics = physics;
    if (shouldUpdate) {
      final velocity = stop();
      final currentX = currentSims.$1 as PhysicsSimulation;
      final currentY = currentSims.$2 as PhysicsSimulation;
      final newX = physics.xPhysics as PhysicsSimulation;
      final newY = physics.yPhysics as PhysicsSimulation;
      final x = newX.copyWith(
        start: _value.dx,
        end: currentX.end,
        initialVelocity: velocity.dx,
      );
      final y = newY.copyWith(
        start: _value.dy,
        end: currentY.end,
        initialVelocity: velocity.dy,
      );
      _startSimulations(x, y);
    }
  }

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  final AnimationBehavior animationBehavior;

  /// The lower bound (bottom-left corner) of the 2D bounding box.
  final Offset lowerBound;

  /// The upper bound (top-right corner) of the 2D bounding box.
  final Offset upperBound;

  /// The duration of the animation.
  Duration? duration;

  /// The duration of the animation when reversing.
  Duration? reverseDuration;

  Ticker? _ticker;
  (Simulation, Simulation)? _sims;
  _AnimationDirection _direction;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick);
    _ticker!.absorbTicker(oldTicker);
  }

  /// The current position of the animation.
  @override
  Offset get value => _value;
  late Offset _value;

  /// Sets the controller's position to [newValue], stopping any running simulation.
  set value(Offset newValue) {
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  /// The velocity of the animation in points per second.
  Offset get velocity {
    if (!isAnimating) {
      return Offset.zero;
    }
    final double t = lastElapsedDuration!.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond;
    return _sims!.dx(t);
  }

  void _internalSetValue(Offset newValue) {
    _value = _clampOffset(newValue, lowerBound, upperBound);
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = _direction == _AnimationDirection.forward
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  Offset _clampOffset(Offset v, Offset min, Offset max) {
    return Offset(
      v.dx.clamp(min.dx, max.dx),
      v.dy.clamp(min.dy, max.dy),
    );
  }

  /// The amount of time that has passed between animation start and last tick.
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  /// Whether this animation is currently animating in either direction.
  @override
  bool get isAnimating => _ticker != null && _ticker!.isActive;

  @override
  AnimationStatus get status => _status;
  late AnimationStatus _status;

  /// Stops running this animation and returns the current velocity.
  Offset stop({bool canceled = true}) {
    final velocity = this.velocity;
    _sims = null;
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
  /// If no [duration] is provided, [this.duration] is used.
  /// If [target] is the same as [value], no animation occurs.
  TickerFuture animateTo(
    Offset target, {
    Duration? duration,
    Simulation2D? physics,
    Offset velocityDelta = Offset.zero,
    Offset? velocityOverride,
  }) {
    physics ??= defaultPhysics;
    assert(
      _ticker != null,
      'PhysicsController2D.animateTo() called after PhysicsController2D.dispose()\n'
      'PhysicsController2D methods should not be used after calling dispose.',
    );
    assert(
      physics.isPhysicsBased() ||
          (velocityOverride == null && velocityDelta == Offset.zero),
      'VelocityDelta and VelocityOverride are only supported when physics is a PhysicsSimulation.',
    );
    if (duration == null) {
      final range = upperBound - lowerBound;
      final remainingFraction =
          range.isFinite ? (target - _value).distance / range.distance : 1.0;
      final directionDuration =
          (_direction == _AnimationDirection.reverse && reverseDuration != null)
              ? reverseDuration
              : this.duration;
      duration = directionDuration == null
          ? null
          : directionDuration * remainingFraction;
    } else if (target == value) {
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
      if (value != target) {
        _value = _clampOffset(target, lowerBound, upperBound);
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
      final xPhysics = physics.xPhysics as PhysicsSimulation;
      final yPhysics = physics.yPhysics as PhysicsSimulation;
      return _startSimulations(
        xPhysics.copyWith(
          start: _value.dx,
          end: target.dx,
          duration: duration,
          durationScale: durationScale,
          initialVelocity: durationScale == null
              ? (velocityOverride?.dx ??
                  velocity.dx + xPhysics.initialVelocity + velocityDelta.dx)
              : null,
        ),
        (physics.yPhysics as PhysicsSimulation).copyWith(
          start: _value.dy,
          end: target.dy,
          duration: duration,
          durationScale: durationScale,
          initialVelocity: durationScale == null
              ? (velocityOverride?.dy ??
                  (velocity.dy + yPhysics.initialVelocity + velocityDelta.dy))
              : null,
        ),
      );
    }

    assert(duration != null,
        "[duration] must be provided for non-physics-based animations.");

    return _startSimulations(
      _InterpolationSimulation(
        _value.dx,
        target.dx,
        duration!,
        physics.xPhysics,
        durationScale!,
      ),
      _InterpolationSimulation(
        _value.dy,
        target.dy,
        duration,
        physics.yPhysics,
        durationScale,
      ),
    );
  }

  /// Starts the animation in the forward direction (from [value] up to [upperBound]).
  TickerFuture forward({Offset? from}) {
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return animateTo(upperBound);
  }

  /// Starts the animation in reverse (from [value] down to [lowerBound]).
  TickerFuture reverse({Offset? from}) {
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return animateTo(lowerBound);
  }

  /// Drives the animation according to the given 2D simulation.
  TickerFuture animateWith(Simulation2D simulation) {
    assert(simulation.isPhysicsBased(),
        "animateWith() requires a physics-based simulation.");
    stop();
    _direction = _AnimationDirection.forward;
    return _startSimulations(
      simulation.xPhysics as PhysicsSimulation,
      simulation.yPhysics as PhysicsSimulation,
    );
  }

  TickerFuture _startSimulations(Simulation x, Simulation y) {
    assert(!isAnimating);
    _sims = (x, y);
    _lastElapsedDuration = Duration.zero;
    _value = _clampOffset(Offset(x.x(0), y.x(0)), lowerBound, upperBound);
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
  /// If no [min]/[max] are given, this defaults to [lowerBound] and [upperBound].
  /// Setting [reverse] to true will alternate the direction on each repeat.
  /// If [count] is not provided, it repeats indefinitely.
  ///
  /// Note: This is more limited for 2D than the 1D version. We use a custom repeating
  /// simulation for each axis, then wrap them in a combined 2D simulation.
  TickerFuture repeat({
    Offset? min,
    Offset? max,
    bool reverse = false,
    int? count,
    Simulation2D? physics,
  }) {
    min ??= lowerBound;
    max ??= upperBound;

    assert(() {
      if (count != null && count <= 0) {
        throw FlutterError('PhysicsController2D.repeat() "count" must be > 0');
      }
      return true;
    }());

    final velocity = stop();
    _direction = _AnimationDirection.forward;

    physics ??= defaultPhysics;

    final xRep = _RepeatingSimulation(
      value.dx,
      min.dx,
      max.dx,
      reverse,
      null,
      physics.xPhysics,
      velocity.dx,
      _directionSetter,
      count,
    );
    final yRep = _RepeatingSimulation(
      value.dy,
      min.dy,
      max.dy,
      reverse,
      null,
      physics.yPhysics,
      velocity.dy,
      _directionSetter,
      count,
    );
    return _startSimulations(xRep, yRep);
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
    final offsetRaw = Offset(_sims!.$1.x(t), _sims!.$2.x(t));
    _value = _clampOffset(offsetRaw, lowerBound, upperBound);

    if (_sims!.isDone(t)) {
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

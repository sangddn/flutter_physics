import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../simulations/physics_simulations.dart';

part 'physics_controller_2d.dart';
part 'physics_controller_multi.dart';

/// {@template physics_controller}
/// A controller for physics-based animations that supports both standard curves and physics simulations.
///
/// Similar to [AnimationController], but with enhanced support for physics-based animations.
/// The key features are:
///
/// * Accepts both standard [Curve]s and [PhysicsSimulation]s (like [Spring])
/// * Dynamically responds to changes mid-animation when using physics simulations
/// * Maintains velocity across animation updates
/// * Drop-in replacement for [AnimationController]
///
/// ## Usage
///
/// Create a controller with a [TickerProvider] (usually from [SingleTickerProviderStateMixin]):
///
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
///   late final _controller = PhysicsController(vsync: this);
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
/// final controller = PhysicsController(
///   vsync: this,
///   duration: const Duration(milliseconds: 300),
/// );
///
/// // Or in methods
/// controller.animateTo(
///   1.0,
///   duration: const Duration(milliseconds: 300),
///   physics: Curves.easeOut,
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
///   late final _controller = PhysicsController(
///     vsync: this,
///     defaultPhysics: Spring.withDamping(
///       dampingFraction: 0.9,
///     ),
///   );
///
///   Alignment _alignment = Alignment.center;
///
///   void _onPanEnd(DragEndDetails details) {
///     // Physics simulation maintains momentum from gesture
///     _controller.animateTo(0.0);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     // Use AnimatedBuilder to rebuild on each tick.
///     return AnimatedBuilder(
///       animation: _controller,
///       builder: (context, child) {
///         return Align(
///           alignment: _alignment,
///           child: child,
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
/// controller.animateTo(1.0);
///
/// // Later, interrupt with new target
/// await Future.delayed(const Duration(milliseconds: 100));
/// controller.animateTo(0.5); // Maintains current velocity
/// ```
///
/// ## Common Use Cases
///
/// * Gesture-driven animations (drag and release)
/// * Pull-to-refresh indicators
/// * Scrolling physics
/// * Natural-feeling transitions
///
/// This controller can be used anywhere [AnimationController] is accepted:
/// [AnimatedBuilder], [RotationTransition], etc.
///
/// See also:
///
/// * [Spring], a physics simulation that creates natural-feeling animations
/// * [AnimationController], Flutter's standard animation controller
/// * [PhysicsSimulation], base class for custom physics simulations
/// {@endtemplate}
class PhysicsController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  /// Creates a physics-based animation controller.
  ///
  /// {@macro physics_controller}
  PhysicsController({
    double value = 0.0,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    required TickerProvider vsync,
    this.animationBehavior = AnimationBehavior.preserve,
    Physics? defaultPhysics,
  })  : assert(upperBound >= lowerBound),
        assert(duration != null ||
            reverseDuration != null ||
            defaultPhysics is PhysicsSimulation?),
        _direction = _AnimationDirection.forward,
        _defaultPhysics = defaultPhysics ?? Spring.elegant {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value);
  }

  /// Creates a physics-based animation controller with an unbounded range.
  ///
  /// {@macro physics_controller}
  PhysicsController.unbounded({
    double? value,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.animationBehavior = AnimationBehavior.normal,
    Physics? defaultPhysics,
    required TickerProvider vsync,
  })  : lowerBound = double.negativeInfinity,
        upperBound = double.infinity,
        assert(duration != null ||
            reverseDuration != null ||
            defaultPhysics is PhysicsSimulation?),
        _direction = _AnimationDirection.forward,
        _defaultPhysics = defaultPhysics ?? Spring.elegant {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? lowerBound);
  }

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// The default physics simulation to use for this controller.
  ///
  /// This physics will be used when no explicit physics is provided to animation methods.
  /// Common choices include:
  ///
  /// ```dart
  /// // Natural spring motion
  /// defaultPhysics = Spring.withDamping(dampingFraction: 0.9);
  ///
  /// // Standard curve
  /// defaultPhysics = Curves.easeOutCubic;
  /// ```
  Physics get defaultPhysics => _defaultPhysics;
  Physics _defaultPhysics;

  /// Sets the default physics simulation to use for this controller.
  ///
  /// If the physics simulation is physics-based, it will maintain momentum
  /// from the current simulation.
  set defaultPhysics(Physics physics) {
    final currentSim = _simulation;
    final shouldUpdate = _defaultPhysics != physics &&
        currentSim != null &&
        currentSim is PhysicsSimulation &&
        physics is PhysicsSimulation;
    _defaultPhysics = physics;
    if (shouldUpdate) {
      final velocity = stop();
      final currentPhysics = currentSim;
      final newPhysics = physics;
      _startSimulation(
        newPhysics.copyWith(
          start: _value,
          end: currentPhysics.end,
          initialVelocity: velocity,
        ),
      );
    }
  }

  /// A label that is used in the [toString] output.
  final String? debugLabel;

  /// The behavior of the controller when [AccessibilityFeatures.disableAnimations]
  /// is true.
  final AnimationBehavior animationBehavior;

  /// Returns an [Animation<double>] for this animation controller.
  Animation<double> get view => this;

  /// The length of time this animation should last.
  Duration? duration;

  /// The length of time this animation should last when going in [reverse].
  Duration? reverseDuration;

  Ticker? _ticker;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick);
    _ticker!.absorbTicker(oldTicker);
  }

  Simulation? _simulation;

  /// The current value of the animation.
  @override
  double get value => _value;
  late double _value;

  /// Stops the animation controller and sets the current value.
  set value(double newValue) {
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  /// Sets the controller's value to [lowerBound], stopping the animation.
  void reset() {
    value = lowerBound;
  }

  /// The current velocity of the animation.
  ///
  /// Returns 0.0 when not animating.
  double get velocity {
    if (!isAnimating) {
      return 0.0;
    }
    return _simulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond);
  }

  void _internalSetValue(double newValue) {
    _value = clampDouble(newValue, lowerBound, upperBound);
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

  /// The amount of time that has passed between animation start and last tick.
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  /// Whether this animation is currently animating in either direction.
  @override
  bool get isAnimating => _ticker != null && _ticker!.isActive;

  _AnimationDirection _direction;

  @override
  AnimationStatus get status => _status;
  late AnimationStatus _status;

  /// Starts running this animation forwards (towards the end).
  TickerFuture forward({double? from}) {
    assert(
      _ticker != null,
      'PhysicsController.forward() called after PhysicsController.dispose()\n'
      'PhysicsController methods should not be used after calling dispose.',
    );
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(upperBound, physics: defaultPhysics);
  }

  /// Starts running this animation in reverse (towards the beginning).
  TickerFuture reverse({double? from}) {
    assert(
      _ticker != null,
      'PhysicsController.reverse() called after PhysicsController.dispose()\n'
      'PhysicsController methods should not be used after calling dispose.',
    );
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(lowerBound, physics: defaultPhysics);
  }

  /// Drives the animation from its current value to target.
  ///
  /// When using [PhysicsSimulation] as the [physics] parameter, the animation
  /// can maintain momentum across updates, and can accept [velocityOverride]
  /// and [velocityDelta] to tailor the initial velocity.
  ///
  /// ```dart
  /// void onPanEnd(DragEndDetails details) {
  ///   // Combine gesture velocity with current animation velocity
  ///   final velocity = details.velocity.pixelsPerSecond.dx + controller.velocity;
  ///   controller.animateTo(
  ///     targetValue,
  ///     velocityDelta: velocity,
  ///   );
  /// }
  /// ```
  ///
  /// The [velocityOverride] and [velocityDelta] parameters are only valid when using
  /// physics simulations. They allow fine-tuning of the initial velocity:
  /// * [velocityOverride] completely replaces the current velocity
  /// * [velocityDelta] adds to the current velocity.
  ///
  /// For standard curves, [duration] is required if not already provided
  /// in the controller ([PhysicsController.duration] or [PhysicsController.reverseDuration]).
  ///
  /// ```dart
  /// controller.animateTo(
  ///   1.0,
  ///   duration: const Duration(milliseconds: 300),
  ///   physics: Curves.easeOut,
  /// );
  /// ```
  TickerFuture animateTo(
    double target, {
    double velocityDelta = 0.0,
    double? velocityOverride,
    Duration? duration,
    Physics? physics,
  }) {
    physics ??= defaultPhysics;
    assert(
      _ticker != null,
      'PhysicsController.animateTo() called after PhysicsController.dispose()\n'
      'PhysicsController methods should not be used after calling dispose.',
    );
    assert(
      physics is PhysicsSimulation ||
          (velocityOverride == null && velocityDelta == 0.0),
      'VelocityDelta and VelocityOverride are only supported when physics is a PhysicsSimulation.',
    );
    _direction = _AnimationDirection.forward;

    return _animateToInternal(
      target,
      duration: duration,
      physics: physics,
      velocityDelta: velocityDelta,
      velocityOverride: velocityOverride,
    );
  }

  TickerFuture _animateToInternal(
    double target, {
    Duration? duration,
    required Physics physics,
    double velocityDelta = 0.0,
    double? velocityOverride,
  }) {
    Duration? simulationDuration = duration;
    if (simulationDuration == null) {
      final range = upperBound - lowerBound;
      final remainingFraction =
          range.isFinite ? (target - _value).abs() / range : 1.0;
      final directionDuration =
          (_direction == _AnimationDirection.reverse && reverseDuration != null)
              ? reverseDuration
              : this.duration;
      simulationDuration = directionDuration == null
          ? null
          : directionDuration * remainingFraction;
    } else if (target == value) {
      simulationDuration = Duration.zero;
    }

    final currentVelocity = stop();
    if (simulationDuration == Duration.zero) {
      if (value != target) {
        _value = clampDouble(target, lowerBound, upperBound);
        notifyListeners();
      }
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      _checkStatusChanged();
      return TickerFuture.complete();
    }

    assert(!isAnimating);

    final durationScale = simulationDuration == null
        ? null
        : switch (animationBehavior) {
            AnimationBehavior.normal
                when SemanticsBinding.instance.disableAnimations =>
              0.05,
            AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
          };

    if (physics is PhysicsSimulation) {
      final disabledAnimation = animationBehavior == AnimationBehavior.normal &&
          SemanticsBinding.instance.disableAnimations;
      final initV = simulationDuration == null && !disabledAnimation
          ? (velocityOverride ??
              (physics.initialVelocity + currentVelocity + velocityDelta))
          : null;
      return _startSimulation(
        physics.copyWith(
          duration: disabledAnimation ? Duration.zero : simulationDuration,
          durationScale: durationScale,
          start: _value,
          end: target,
          initialVelocity: initV,
        ),
      );
    }

    assert(
      simulationDuration != null,
      "Duration must be provided if physics is not a [PhysicsSimulation].",
    );

    return _startSimulation(
      _InterpolationSimulation(
        _value,
        target,
        simulationDuration!,
        physics,
        durationScale!,
      ),
    );
  }

  /// Drives the animation with a spring simulation. This is purely for
  /// compatibility with the [AnimationController.fling] method and can be
  /// replaced with [animateTo] with a [Spring].
  @Deprecated('Use `animateTo` with a `Spring` instead.')
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) {
    springDescription ??= _kFlingSpringDescription;
    final currentVelocity = stop();
    _direction = velocity < 0.0
        ? _AnimationDirection.reverse
        : _AnimationDirection.forward;
    final double target = velocity < 0.0
        ? lowerBound - _kFlingTolerance.distance
        : upperBound + _kFlingTolerance.distance;
    final AnimationBehavior behavior =
        animationBehavior ?? this.animationBehavior;
    final scale = switch (behavior) {
      AnimationBehavior.normal
          when SemanticsBinding.instance.disableAnimations =>
        200.0,
      AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
    };

    final simulation = SpringSimulation(
      springDescription,
      value,
      target,
      velocity * scale + currentVelocity,
    )..tolerance = _kFlingTolerance;

    return _startSimulation(simulation);
  }

  /// Drives the animation according to the given simulation.
  TickerFuture animateWith(Simulation simulation) {
    assert(
      _ticker != null,
      'PhysicsController.animateWith() called after PhysicsController.dispose()\n'
      'PhysicsController methods should not be used after calling dispose.',
    );
    final velocity = stop();
    _direction = _AnimationDirection.forward;
    if (simulation is PhysicsSimulation) {
      simulation = simulation.copyWith(
        initialVelocity: simulation.initialVelocity + velocity,
      );
    }
    return _startSimulation(simulation);
  }

  TickerFuture _startSimulation(Simulation simulation) {
    assert(!isAnimating);
    _simulation = simulation;
    _lastElapsedDuration = Duration.zero;
    _value = clampDouble(simulation.x(0.0), lowerBound, upperBound);
    final TickerFuture result = _ticker!.start();
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  /// Stops running this animation and returns the current velocity of the
  /// simulation.
  double stop({bool canceled = true}) {
    assert(
      _ticker != null,
      'PhysicsController.stop() called after PhysicsController.dispose()\n'
      'PhysicsController methods should not be used after calling dispose.',
    );
    final velocity = _simulation?.dx(
        lastElapsedDuration!.inMicroseconds / Duration.microsecondsPerSecond);
    _simulation = null;
    _lastElapsedDuration = null;
    _ticker!.stop(canceled: canceled);
    return velocity ?? 0.0;
  }

  /// Release the resources used by this object.
  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('PhysicsController.dispose() called more than once.'),
          ErrorDescription(
              'A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<PhysicsController>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());

    _ticker!.dispose();
    _ticker = null;
    clearStatusListeners();
    clearListeners();
    super.dispose();
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
    final elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);
    _value =
        clampDouble(_simulation!.x(elapsedInSeconds), lowerBound, upperBound);
    if (_simulation!.isDone(elapsedInSeconds)) {
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
    final String more =
        '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
    return '$more$paused$ticker$label';
  }

  /// Starts running this animation in the forward direction, and
  /// restarts the animation when it completes.
  ///
  /// {@tool snippet}
  /// Particularly useful for continuous animations like loading indicators or
  /// background effects:
  ///
  /// ```dart
  /// class SpringingRotation extends StatefulWidget {
  ///   const SpringingRotation({super.key});
  ///
  ///   @override
  ///   State<SpringingRotation> createState() => _SpringingRotationState();
  /// }
  ///
  /// class _SpringingRotationState extends State<SpringingRotation>
  ///     with SingleTickerProviderStateMixin {
  ///   late final _controller = PhysicsController(
  ///     vsync: this,
  ///     defaultPhysics: Spring.snap,
  ///   );
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _controller.repeat(
  ///       min: 0,
  ///       max: pi * 2,
  ///       reverse: true, // Oscillate back and forth
  ///     );
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return RotationTransition(
  ///       turns: _controller,
  ///       child: const FlutterLogo(size: 64),
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// The [min] and [max] parameters default to [lowerBound] and [upperBound].
  /// When [reverse] is true, the animation alternates direction each cycle.
  /// The [count] parameter limits the number of repetitions (infinite by default).
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
    Physics? physics,
  }) {
    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;
    physics ??= defaultPhysics;
    assert(max >= min);
    assert(max <= upperBound && min >= lowerBound);
    assert(count == null || count > 0,
        'Count shall be greater than zero if not null');

    final currentVelocity = stop();

    return _startSimulation(
      _RepeatingSimulation(
        _value,
        min,
        max,
        reverse,
        period,
        physics,
        currentVelocity,
        _directionSetter,
        count,
      ),
    );
  }

  void _directionSetter(_AnimationDirection direction) {
    _direction = direction;
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
  }
}

/// The direction in which an animation is running.
enum _AnimationDirection {
  /// The animation is running from beginning to end.
  forward,

  /// The animation is running backwards, from end to beginning.
  reverse,
}

final _kFlingSpringDescription =
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 500.0);

const _kFlingTolerance = Tolerance(velocity: double.infinity, distance: 0.01);

class _InterpolationSimulation extends Simulation {
  _InterpolationSimulation(
      this._begin, this._end, Duration duration, this._curve, double scale)
      : assert(duration.inMicroseconds > 0),
        assert(_curve is! PhysicsSimulation),
        _durationInSeconds =
            (duration.inMicroseconds * scale) / Duration.microsecondsPerSecond;

  final double _durationInSeconds;
  final double _begin;
  final double _end;
  final Curve _curve;

  @override
  double x(double timeInSeconds) {
    final double t = clampDouble(timeInSeconds / _durationInSeconds, 0.0, 1.0);
    return switch (t) {
      0.0 => _begin,
      1.0 => _end,
      _ => _begin + (_end - _begin) * _curve.transform(t),
    };
  }

  @override
  double dx(double timeInSeconds) {
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) /
        (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

typedef _DirectionSetter = void Function(_AnimationDirection direction);

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(
    this._initialValue,
    this.min,
    this.max,
    this.reverse,
    Duration? period,
    Physics physics,
    double currentVelocity,
    this.directionSetter,
    this.count,
  )   : assert(count == null || count > 0,
            'Count shall be greater than zero if not null'),
        assert(physics is PhysicsSimulation || period != null,
            "Period must be provided if physics is not a [PhysicsSimulation].") {
    if (physics is PhysicsSimulation) {
      _physics = physics.copyWith(
        start: min,
        end: max,
        initialVelocity: currentVelocity,
      );
    } else {
      _physics = physics;
    }
    period ??= Duration(
        milliseconds: ((physics as PhysicsSimulation).duration * 1000).ceil());
    _periodInSeconds = period.inMicroseconds / Duration.microsecondsPerSecond;
    assert(_periodInSeconds > 0.0);
    assert(_initialT >= 0.0);
  }

  final double min;
  final double max;
  final bool reverse;
  final int? count;
  final _DirectionSetter directionSetter;
  late final double _periodInSeconds;
  final double _initialValue;
  late final Physics _physics;

  late final double _initialT = (max == min)
      ? 0.0
      : ((clampDouble(_initialValue, min, max) - min) / (max - min)) *
          _periodInSeconds;

  late final double _exitTimeInSeconds =
      count == null ? double.infinity : (count! * _periodInSeconds) - _initialT;

  @override
  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);

    final double totalTimeInSeconds = timeInSeconds + _initialT;
    final double t = (totalTimeInSeconds / _periodInSeconds) % 1.0;
    final bool isPlayingReverse =
        reverse && (totalTimeInSeconds ~/ _periodInSeconds).isOdd;

    final fn = _physics is PhysicsSimulation
        ? (_physics as PhysicsSimulation).x
        : _physics.transform;

    if (isPlayingReverse) {
      directionSetter(_AnimationDirection.reverse);
      return min + (max - min) * fn(1.0 - t);
    }

    directionSetter(_AnimationDirection.forward);
    return min + (max - min) * fn(t);
  }

  @override
  double dx(double timeInSeconds) {
    if (_physics is PhysicsSimulation) {
      return (_physics as PhysicsSimulation).dx(timeInSeconds);
    }
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) /
        (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds >= _exitTimeInSeconds;
}

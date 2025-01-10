import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../simulations/physical_simulations.dart';

part 'physics_controller_2d.dart';

/// A controller for physical animations.
///
/// This is similar to [AnimationController], but it has special handling for
/// [PhysicalSimulation]s - allowing them to be used directly as curves while
/// maintaining their physical simulation properties.
class PhysicsController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  /// Creates a physical animation controller.
  ///
  /// {@macro physics_controller_parameters}
  ///
  /// * [lowerBound] is the smallest value this animation can obtain and the
  ///   value at which this animation is deemed to be dismissed.
  ///
  /// * [upperBound] is the largest value this animation can obtain and the
  ///   value at which this animation is deemed to be completed.
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
            defaultPhysics is PhysicalSimulation?),
        _direction = _AnimationDirection.forward,
        defaultPhysics = defaultPhysics ?? Spring.elegant {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value);
  }

  /// Creates a physical animation controller with an unounded range.
  ///
  /// {@template physics_controller_parameters}
  /// * [value] is the initial value of the animation.
  ///
  /// * [duration] is the length of time this animation should last. Required if
  ///   [defaultPhysics] is not a [PhysicalSimulation].
  ///
  /// * [debugLabel] is a string to help identify this animation during
  ///   debugging (used by [toString]).
  ///
  /// * `vsync` is the required [TickerProvider] for the current context.
  /// {@endtemplate}
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
            defaultPhysics is PhysicalSimulation?),
        _direction = _AnimationDirection.forward,
        defaultPhysics = defaultPhysics ?? Spring.elegant {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? lowerBound);
  }

  /// The value at which this animation is deemed to be dismissed.
  final double lowerBound;

  /// The value at which this animation is deemed to be completed.
  final double upperBound;

  /// The default physics simulation to use for this controller.
  Physics defaultPhysics;

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

  /// The rate of change of [value] per second.
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
      'PhysicalController.forward() called after PhysicalController.dispose()\n'
      'PhysicalController methods should not be used after calling dispose.',
    );
    _direction = _AnimationDirection.forward;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(upperBound);
  }

  /// Starts running this animation in reverse (towards the beginning).
  TickerFuture reverse({double? from}) {
    assert(
      _ticker != null,
      'PhysicalController.reverse() called after PhysicalController.dispose()\n'
      'PhysicalController methods should not be used after calling dispose.',
    );
    _direction = _AnimationDirection.reverse;
    if (from != null) {
      value = from;
    }
    return _animateToInternal(lowerBound);
  }

  /// Drives the animation from its current value to target.
  TickerFuture animateTo(
    double target, {
    Duration? duration,
    Physics? physics,
  }) {
    physics ??= defaultPhysics;
    assert(
      _ticker != null,
      'PhysicalController.animateTo() called after PhysicalController.dispose()\n'
      'PhysicalController methods should not be used after calling dispose.',
    );
    _direction = _AnimationDirection.forward;

    return _animateToInternal(target, duration: duration, physics: physics);
  }

  TickerFuture _animateToInternal(
    double target, {
    Duration? duration,
    Physics? physics,
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) {
    physics ??= defaultPhysics;
    final double scale = switch (animationBehavior) {
      AnimationBehavior.normal
          when SemanticsBinding.instance.disableAnimations =>
        0.05,
      AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
    };

    Duration? simulationDuration = duration;
    if (simulationDuration == null) {
      final double range = upperBound - lowerBound;
      final double remainingFraction =
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

    stop();
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

    if (physics is PhysicalSimulation) {
      return _startSimulation(physics.copyWith(
        duration: simulationDuration,
        tolerance: tolerance,
        start: _value,
        end: target,
        scale: scale,
      ));
    }

    assert(simulationDuration != null,
        "Duration must be provided if physics is not a [PhysicalSimulation].");

    return _startSimulation(
      _InterpolationSimulation(
        _value,
        target,
        simulationDuration!,
        physics,
        scale,
      ),
    );
  }

  /// Drives the animation with a spring simulation.
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) {
    springDescription ??= _kFlingSpringDescription;
    _direction = velocity < 0.0
        ? _AnimationDirection.reverse
        : _AnimationDirection.forward;
    final double target = velocity < 0.0
        ? lowerBound - _kFlingTolerance.distance
        : upperBound + _kFlingTolerance.distance;
    final AnimationBehavior behavior =
        animationBehavior ?? this.animationBehavior;
    final double scale = switch (behavior) {
      AnimationBehavior.normal
          when SemanticsBinding.instance.disableAnimations =>
        200.0,
      AnimationBehavior.normal || AnimationBehavior.preserve => 1.0,
    };

    final SpringSimulation simulation = SpringSimulation(
      springDescription,
      value,
      target,
      velocity * scale,
    )..tolerance = _kFlingTolerance;

    stop();
    return _startSimulation(simulation);
  }

  /// Drives the animation according to the given simulation.
  TickerFuture animateWith(Simulation simulation) {
    assert(
      _ticker != null,
      'PhysicalController.animateWith() called after PhysicalController.dispose()\n'
      'PhysicalController methods should not be used after calling dispose.',
    );
    stop();
    _direction = _AnimationDirection.forward;
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

  /// Stops running this animation.
  void stop({bool canceled = true}) {
    assert(
      _ticker != null,
      'PhysicalController.stop() called after PhysicalController.dispose()\n'
      'PhysicalController methods should not be used after calling dispose.',
    );
    _simulation = null;
    _lastElapsedDuration = null;
    _ticker!.stop(canceled: canceled);
  }

  /// Release the resources used by this object.
  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('PhysicalController.dispose() called more than once.'),
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
    final double elapsedInSeconds =
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
  /// Defaults to repeating between the [lowerBound] and [upperBound] of the
  /// [PhysicsController] when no explicit value is set for [min] and [max].
  ///
  /// With [reverse] set to true, instead of always starting over at [min]
  /// the starting value will alternate between [min] and [max] values on each
  /// repeat. The [status] will be reported as [AnimationStatus.reverse] when
  /// the animation runs from [max] to [min].
  ///
  /// Each run of the animation will have a duration of `period`. If `period` is not
  /// provided, [duration] will be used instead, which has to be set before [repeat] is
  /// called either in the constructor or later by using the [duration] setter.
  ///
  /// If a value is passed to [count], the animation will perform that many
  /// iterations before stopping. Otherwise, the animation repeats indefinitely.
  ///
  /// Returns a [TickerFuture] that never completes, unless a [count] is specified.
  /// The [TickerFuture.orCancel] future completes with an error when the animation is
  /// stopped (e.g. with [stop]).
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

    stop();

    return _startSimulation(_RepeatingSimulation(
      _value,
      min,
      max,
      reverse,
      period,
      physics,
      _directionSetter,
      count,
    ));
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

final SpringDescription _kFlingSpringDescription =
    SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 500.0,
);

const Tolerance _kFlingTolerance = Tolerance(
  velocity: double.infinity,
  distance: 0.01,
);

class _InterpolationSimulation extends Simulation {
  _InterpolationSimulation(
      this._begin, this._end, Duration duration, this._curve, double scale)
      : assert(duration.inMicroseconds > 0),
        assert(_curve is! PhysicalSimulation),
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
    this.directionSetter,
    this.count,
  )   : assert(count == null || count > 0,
            'Count shall be greater than zero if not null'),
        assert(physics is PhysicalSimulation || period != null,
            "Period must be provided if physics is not a [PhysicalSimulation].") {
    period ??= Duration(
        milliseconds: ((physics as PhysicalSimulation).duration * 1000).ceil());
    _periodInSeconds = period.inMicroseconds / Duration.microsecondsPerSecond;
    assert(_periodInSeconds > 0.0);
    assert(_initialT >= 0.0);
    if (physics is PhysicalSimulation) {
      _physics = physics.copyWith(
        duration: period,
        start: min,
        end: max,
      );
    } else {
      _physics = physics;
    }
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

    final fn = _physics is PhysicalSimulation
        ? (_physics as PhysicalSimulation).x
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
    if (_physics is PhysicalSimulation) {
      return (_physics as PhysicalSimulation).dx(timeInSeconds);
    }
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) /
        (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds >= _exitTimeInSeconds;
}

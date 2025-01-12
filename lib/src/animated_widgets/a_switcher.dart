import 'package:flutter/widgets.dart';

import '../controllers/physics_controller.dart';
import '../simulations/physics_simulations.dart';

/// {@template a_switcher}
/// A widget that animates between two children using physics-based animations.
///
/// Similar to [AnimatedSwitcher], but with enhanced support for physics-based animations.
/// The key features are:
///
/// * Accepts both standard [Curve]s and physics simulations (like [Spring])
/// * Dynamically responds to changes mid-animation when using physics simulations
/// * Maintains momentum across animation updates
///
/// ## Basic Usage
///
/// You can use it just like [AnimatedSwitcher]:
/// ```dart
/// ASwitcher(
///   duration: const Duration(milliseconds: 300), // Required for standard curves
///   physics: Curves.easeOut,
///   child: currentChild,
/// )
/// ```
///
/// ### Using with Physics Simulations
///
/// Use [PhysicsSimulation]s like [Spring] to respond naturally to interruptions:
///
/// ```dart
/// ASwitcher(
///   physics: Spring.elegant, // Duration not needed for physics!
///   child: currentChild,
/// )
/// ```
///
/// When using physics simulations (especially [Spring]), the transitions feel more
/// natural because:
///
/// 1. They maintain momentum when interrupted
/// 2. They automatically adjust their duration based on the distance
/// 3. They respond to mid-animation changes smoothly
///
/// For example, if you rapidly switch between children while a transition is still
/// in progress, a spring simulation will smoothly redirect the animation while
/// preserving the current velocity. This creates a more fluid experience compared
/// to standard curves which would abruptly start a new animation.
///
/// ### Using with Standard Curves
///
/// When using standard curves, you must provide a duration either in the constructor
/// or in animation methods:
///
/// ```dart
/// ASwitcher(
///   duration: const Duration(milliseconds: 300), // Again, required for curves
///   physics: Curves.easeOut,
///   child: currentChild,
/// )
/// ```
///
/// ## Custom Transitions
///
/// You can customize how children are transitioned using [transitionBuilder]:
///
/// ```dart
/// ASwitcher(
///   physics: Spring.smooth,
///   transitionBuilder: (child, animation) {
///     return ScaleTransition(
///       scale: animation,
///       child: child,
///     );
///   },
///   child: currentChild,
/// )
/// ```
///
/// ## Custom Layouts
///
/// The [layoutBuilder] determines how the transitioning children are laid out:
///
/// ```dart
/// ASwitcher(
///   physics: Spring.smooth,
///   layoutBuilder: (currentChild, previousChildren) {
///     return Stack(
///       alignment: Alignment.center,
///       children: [
///         ...previousChildren,
///         if (currentChild != null) currentChild,
///       ],
///     );
///   },
///   child: currentChild,
/// )
/// ```
///
/// ## Important Notes
///
/// 1. When using physics simulations:
///    * Leaving [duration] `null` for the most natural simulations
///    * The animation will naturally adjust to the transition distance
///    * Interruptions are handled smoothly with preserved momentum
///
/// 2. When using standard curves:
///    * [duration] is required
///    * Interruptions will restart the animation
///    * The same duration is used regardless of transition distance
///
/// See also:
///
/// * [Spring], a physics simulation that creates natural-feeling animations
/// * [AnimatedSwitcher], Flutter's standard switching widget
/// * [PhysicsController], the underlying controller that enables physics-based animations
/// {@endtemplate}
class ASwitcher extends StatefulWidget {
  const ASwitcher({
    super.key,
    this.child,
    this.duration,
    this.reverseDuration,
    this.physics,
    this.transitionBuilder = ASwitcher.fadeTransitionBuilder,
    this.layoutBuilder = ASwitcher.alignedLayoutBuilder,
  });

  /// The child widget to display.
  ///
  /// If a new widget is provided with a different key, the old widget will be
  /// transitioned out while the new widget transitions in using the provided
  /// [transitionBuilder] and [layoutBuilder].
  final Widget? child;

  /// The duration of the transition when a new child is added.
  final Duration? duration;

  /// The duration of the transition when a child is removed.
  final Duration? reverseDuration;

  /// The [Curve] (can be a [PhysicsSimulation]) to use for the transition.
  /// Defaults to [Spring.elegant] in [PhysicsController].
  final Physics? physics;

  /// A function that wraps a new child with an animated transition.
  ///
  /// The function takes the child and an animation that drives the transition.
  /// By default, uses [fadeTransitionBuilder] which creates a fade transition.
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  /// A function that determines how to lay out the current child and previous children.
  ///
  /// By default, uses [alignedLayoutBuilder] which stacks the children with the
  /// current child on top, centered within a [Stack].
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  static Widget fadeTransitionBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    return FadeTransition(
      key: ValueKey<Key?>(child.key),
      opacity: animation,
      child: child,
    );
  }

  static Widget alignedLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren, [
    AlignmentGeometry alignment = Alignment.center,
  ]) {
    return Stack(
      alignment: alignment,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }

  @override
  State<ASwitcher> createState() => _ASwitcherState();
}

class _ASwitcherState extends State<ASwitcher> with TickerProviderStateMixin {
  _ChildEntry? _currentEntry;
  final Set<_ChildEntry> _outgoingEntries = <_ChildEntry>{};
  List<Widget>? _outgoingWidgets;
  int _childNumber = 0;

  @override
  void initState() {
    super.initState();
    _addEntryForNewChild(animate: false);
  }

  @override
  void didUpdateWidget(ASwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _outgoingEntries.forEach(_updateTransitionForEntry);
      if (_currentEntry != null) {
        _updateTransitionForEntry(_currentEntry!);
      }
      _markChildWidgetCacheAsDirty();
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _currentEntry != null;
    if (hasNewChild != hasOldChild ||
        hasNewChild &&
            !Widget.canUpdate(widget.child!, _currentEntry!.widgetChild)) {
      _childNumber += 1;
      _addEntryForNewChild(animate: true);
    } else if (_currentEntry != null) {
      _currentEntry!.widgetChild = widget.child!;
      _updateTransitionForEntry(_currentEntry!);
      _markChildWidgetCacheAsDirty();
    }
  }

  void _addEntryForNewChild({required bool animate}) {
    if (_currentEntry != null) {
      _outgoingEntries.add(_currentEntry!);
      _currentEntry!.controller.reverse();
      _markChildWidgetCacheAsDirty();
      _currentEntry = null;
    }
    if (widget.child == null) {
      return;
    }

    final controller = PhysicsController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      defaultPhysics: widget.physics,
    );

    _currentEntry = _ChildEntry(
      controller: controller,
      widgetChild: widget.child!,
      transition: KeyedSubtree.wrap(
        widget.transitionBuilder(widget.child!, controller),
        _childNumber,
      ),
    );

    if (animate) {
      controller.forward();
    } else {
      controller.value = 1.0;
    }
  }

  void _markChildWidgetCacheAsDirty() {
    _outgoingWidgets = null;
  }

  void _updateTransitionForEntry(_ChildEntry entry) {
    entry.transition = KeyedSubtree(
      key: entry.transition.key,
      child: widget.transitionBuilder(entry.widgetChild, entry.controller),
    );
  }

  void _rebuildOutgoingWidgetsIfNeeded() {
    _outgoingWidgets ??= List<Widget>.unmodifiable(
      _outgoingEntries.map<Widget>((_ChildEntry entry) => entry.transition),
    );
  }

  @override
  void dispose() {
    _currentEntry?.controller.dispose();
    for (final entry in _outgoingEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rebuildOutgoingWidgetsIfNeeded();
    return widget.layoutBuilder(
      _currentEntry?.transition,
      _outgoingWidgets!
          .where((Widget outgoing) =>
              outgoing.key != _currentEntry?.transition.key)
          .toList(),
    );
  }
}

class _ChildEntry {
  _ChildEntry({
    required this.controller,
    required this.widgetChild,
    required this.transition,
  });

  final PhysicsController controller;
  Widget widgetChild;
  Widget transition;
}

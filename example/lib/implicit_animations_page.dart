import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter/services.dart';
import 'package:flutter_physics/flutter_physics.dart';

class ImplicitAnimationsPage extends StatefulWidget {
  const ImplicitAnimationsPage({super.key});

  @override
  State<ImplicitAnimationsPage> createState() => _ImplicitAnimationsPageState();
}

class _ImplicitAnimationsPageState extends State<ImplicitAnimationsPage> {
  int _step = 0;

  void _next() => setState(() => _step = (_step + 1) % 4);
  void _previous() => setState(() => _step = (_step - 1) % 4);

  bool get step1 => _step == 1;
  bool get step2 => _step == 2;
  bool get step3 => _step == 3;

  @override
  Widget build(BuildContext context) {
    final spring = Spring.buoyant;
    final duration =
        Duration(milliseconds: (spring.duration * 1000 + 100).toInt());
    final containerChild = LayoutBuilder(builder: (context, constraints) {
      final dim = constraints.maxHeight;
      if (dim < 60) return const SizedBox.shrink();
      final velocity = (context
              .findAncestorStateOfType<PhysicsAnimatedWidgetBaseState>()
              ?.controller
              .velocity[1] ??
          context
              .findAncestorStateOfType<AnimatedWidgetBaseState>()!
              // ignore: invalid_use_of_protected_member
              .controller
              .velocity);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.0,
        children: [
          Text('v=$velocity', maxLines: 1),
          Text('dim=${constraints.maxHeight.toStringAsFixed(2)}', maxLines: 1),
        ],
      );
    });
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.arrowRight): _next,
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): _previous,
      },
      child: Focus(
        autofocus: true,
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Implicit Animations'),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SafeArea(child: SizedBox.shrink()),
                  const Center(
                    child: Text(
                      'All widgets below, both left and right, are animated with Spring.buoyant.',
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  _twoSides(
                    _buildSection(
                      'AnimatedContainer (curve-based)',
                      AnimatedContainer(
                        duration: duration,
                        curve: spring,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: step3
                            ? 200
                            : step2
                                ? 100
                                : step1
                                    ? 60
                                    : 10,
                        height: step3
                            ? 200
                            : step2
                                ? 100
                                : step1
                                    ? 60
                                    : 10,
                        child: containerChild,
                      ),
                    ),
                    _buildSection(
                      'AContainer (physics-based)',
                      AContainer(
                        physics: spring,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: step3
                            ? 200
                            : step2
                                ? 100
                                : step1
                                    ? 60
                                    : 10,
                        height: step3
                            ? 200
                            : step2
                                ? 100
                                : step1
                                    ? 60
                                    : 10,
                        child: containerChild,
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedPadding (curve-based)',
                      Center(
                        child: ColoredBox(
                          color: Colors.grey[200]!,
                          child: AnimatedPadding(
                            duration: duration,
                            curve: spring,
                            padding: step3
                                ? const EdgeInsets.all(64)
                                : step2
                                    ? const EdgeInsets.all(16)
                                    : step1
                                        ? const EdgeInsets.all(8)
                                        : EdgeInsets.zero,
                            child: Container(
                              color: Colors.blue,
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildSection(
                      'APadding (physics-based)',
                      Center(
                        child: ColoredBox(
                          color: Colors.grey[200]!,
                          child: APadding(
                            physics: spring,
                            padding: step3
                                ? const EdgeInsets.all(64)
                                : step2
                                    ? const EdgeInsets.all(16)
                                    : step1
                                        ? const EdgeInsets.all(8)
                                        : EdgeInsets.zero,
                            child: Container(
                              color: Colors.blue,
                              width: 50,
                              height: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedAlign (curve-based)',
                      Container(
                        height: 240.0,
                        color: Colors.grey[200],
                        child: AnimatedAlign(
                          duration: duration,
                          curve: spring,
                          alignment: step3
                              ? Alignment.topLeft
                              : step2
                                  ? const Alignment(.1, .1)
                                  : step1
                                      ? const Alignment(.7, -1.2)
                                      : Alignment.center,
                          child: const FlutterPhysicsLogo(size: 60),
                        ),
                      ),
                    ),
                    _buildSection(
                      'AAlign (physics-based)',
                      Container(
                        height: 240.0,
                        color: Colors.grey[200],
                        child: AAlign(
                          physics: spring,
                          alignment: step3
                              ? Alignment.topLeft
                              : step2
                                  ? const Alignment(.1, .1)
                                  : step1
                                      ? const Alignment(.7, -1.2)
                                      : Alignment.center,
                          child: const FlutterPhysicsLogo(size: 60),
                        ),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedScale (curve-based)',
                      Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: AnimatedScale(
                          duration: duration,
                          curve: spring,
                          scale: step3
                              ? 4.0
                              : step2
                                  ? 2.0
                                  : step1
                                      ? 1.5
                                      : .3,
                          child: const FlutterPhysicsLogo(size: 50),
                        ),
                      ),
                    ),
                    _buildSection(
                      'AScale (physics-based)',
                      Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: AScale(
                          physics: spring,
                          scale: step3
                              ? 4.0
                              : step2
                                  ? 2.0
                                  : step1
                                      ? 1.5
                                      : .3,
                          child: const FlutterPhysicsLogo(size: 50),
                        ),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedRotation (curve-based)',
                      AnimatedRotation(
                        duration: duration,
                        curve: spring,
                        turns: step3
                            ? 1.5
                            : step2
                                ? .5
                                : step1
                                    ? .1
                                    : 0.0,
                        child: const FlutterPhysicsLogo(size: 100),
                      ),
                    ),
                    _buildSection(
                      'ARotation (physics-based)',
                      ARotation(
                        physics: spring,
                        turns: step3
                            ? 1.5
                            : step2
                                ? .5
                                : step1
                                    ? .1
                                    : 0.0,
                        child: const FlutterPhysicsLogo(size: 100),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedSlide (curve-based)',
                      SizedBox(
                        height: 100,
                        child: AnimatedSlide(
                          duration: duration,
                          curve: spring,
                          offset: step3
                              ? const Offset(1.5, 0.0)
                              : step2
                                  ? const Offset(-1.5, 0.7)
                                  : step1
                                      ? const Offset(0.1, 0.0)
                                      : Offset.zero,
                          child: const FlutterPhysicsLogo(size: 100),
                        ),
                      ),
                    ),
                    _buildSection(
                      'ASlide (physics-based)',
                      SizedBox(
                        height: 100,
                        child: ASlide(
                          physics: spring,
                          offset: step3
                              ? const Offset(1.5, 0.0)
                              : step2
                                  ? const Offset(-1.5, 0.7)
                                  : step1
                                      ? const Offset(0.1, 0.0)
                                      : Offset.zero,
                          child: const FlutterPhysicsLogo(size: 100),
                        ),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedOpacity (curve-based)',
                      AnimatedOpacity(
                        duration: duration,
                        curve: spring,
                        opacity: step3
                            ? 0.3
                            : step2
                                ? .5
                                : step1
                                    ? .7
                                    : 1.0,
                        child: const FlutterPhysicsLogo(size: 100),
                      ),
                    ),
                    _buildSection(
                      'AOpacity (physics-based)',
                      AOpacity(
                        physics: spring,
                        opacity: step3
                            ? 0.3
                            : step2
                                ? .5
                                : step1
                                    ? .7
                                    : 1.0,
                        child: const FlutterPhysicsLogo(size: 100),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedPhysicalModel (curve-based)',
                      AnimatedPhysicalModel(
                        duration: duration,
                        curve: spring,
                        elevation: step3
                            ? 20.0
                            : step2
                                ? 10.0
                                : step1
                                    ? 2.0
                                    : 2.0,
                        color: step3
                            ? Colors.blue
                            : step2
                                ? Colors.green
                                : step1
                                    ? Colors.red
                                    : Colors.blue,
                        shadowColor: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                    _buildSection(
                      'APhysicalModel (physics-based)',
                      APhysicalModel(
                        physics: spring,
                        elevation: step3
                            ? 20.0
                            : step2
                                ? 10.0
                                : step1
                                    ? 2.0
                                    : 2.0,
                        color: step3
                            ? Colors.blue
                            : step2
                                ? Colors.green
                                : step1
                                    ? Colors.red
                                    : Colors.blue,
                        shadowColor: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  ),
                  _twoSides(
                    _buildSection(
                      'AnimatedFractionallySizedBox (curve-based)',
                      Container(
                        color: Colors.grey[200],
                        height: 100,
                        child: AnimatedFractionallySizedBox(
                          duration: duration,
                          curve: spring,
                          widthFactor: step3
                              ? 1.0
                              : step2
                                  ? .5
                                  : step1
                                      ? .25
                                      : 0.1,
                          child: Container(color: Colors.blue),
                        ),
                      ),
                    ),
                    _buildSection(
                      'AFractionallySizedBox (physics-based)',
                      Container(
                        color: Colors.grey[200],
                        height: 100,
                        child: AFractionallySizedBox(
                          physics: spring,
                          widthFactor: step3
                              ? 1.0
                              : step2
                                  ? .5
                                  : step1
                                      ? .25
                                      : 0.1,
                          child: Container(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton.filled(
                      onPressed: _next,
                      child: const Icon(Icons.arrow_forward),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton.filled(
                      onPressed: _previous,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoSides(Widget left, Widget right) {
    return SizedBox(
      height: 300.0,
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Center(child: child),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_physics/flutter_physics.dart';

class ImplicitAnimationsPage extends StatefulWidget {
  const ImplicitAnimationsPage({super.key});

  @override
  State<ImplicitAnimationsPage> createState() => _ImplicitAnimationsPageState();
}

class _ImplicitAnimationsPageState extends State<ImplicitAnimationsPage> {
  bool _isAnimated = false;
  Timer? _timer;

  void _toggleAnimation() {
    setState(() {
      _isAnimated = !_isAnimated;
    });
  }

  void _toggleBackAndForth() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isAnimated = !_isAnimated;
      });
    });
  }

  void _stopBackAndForth() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spring = Spring.elegant;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'AContainer',
              AContainer(
                physics: spring,
                decoration: BoxDecoration(
                  color: _isAnimated ? Colors.blue : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
            _buildSection(
              'APadding',
              SizedBox(
                height: 300.0,
                child: Center(
                  child: ColoredBox(
                    color: Colors.grey[200]!,
                    child: APadding(
                      physics: spring,
                      padding: _isAnimated
                          ? const EdgeInsets.all(32)
                          : const EdgeInsets.all(8),
                      child: Container(
                        color: Colors.blue,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildSection(
              'AAlign',
              Container(
                height: 200,
                color: Colors.grey[200],
                child: AAlign(
                  physics: spring,
                  alignment:
                      _isAnimated ? Alignment.bottomRight : Alignment.topLeft,
                  child: const FlutterLogo(size: 60),
                ),
              ),
            ),
            _buildSection(
              'AScale',
              AScale(
                physics: spring,
                scale: _isAnimated ? 2.0 : 1.0,
                child: const FlutterLogo(size: 50),
              ),
            ),
            _buildSection(
              'ARotation',
              ARotation(
                physics: spring,
                turns: _isAnimated ? 1.0 : 0.0,
                child: const FlutterLogo(size: 50),
              ),
            ),
            _buildSection(
              'ASlide',
              SizedBox(
                height: 100,
                child: ASlide(
                  physics: spring,
                  offset: _isAnimated ? const Offset(0.5, 0.0) : Offset.zero,
                  child: const FlutterLogo(size: 50),
                ),
              ),
            ),
            _buildSection(
              'AOpacity',
              AOpacity(
                physics: spring,
                opacity: _isAnimated ? 0.3 : 1.0,
                child: const FlutterLogo(size: 50),
              ),
            ),
            _buildSection(
              'APhysicalModel',
              APhysicalModel(
                physics: spring,
                elevation: _isAnimated ? 20.0 : 2.0,
                color: _isAnimated ? Colors.blue : Colors.red,
                shadowColor: Colors.black,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
            _buildSection(
              'AFractionallySizedBox',
              Container(
                color: Colors.grey[200],
                height: 100,
                child: AFractionallySizedBox(
                  physics: spring,
                  widthFactor: _isAnimated ? 1.0 : 0.5,
                  child: Container(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 500),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _toggleAnimation,
            child: Icon(_isAnimated ? Icons.refresh : Icons.play_arrow),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _toggleBackAndForth,
            child: const Icon(Icons.repeat),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _stopBackAndForth,
            child: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Center(child: child),
        ],
      ),
    );
  }
}

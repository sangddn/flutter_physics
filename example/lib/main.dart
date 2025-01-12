import 'package:flutter/cupertino.dart';
import 'implicit_animations_page.dart';
import 'interrupted_animations_page.dart';
import 'physics_playground_page.dart';
import 'physics_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Flutter Physics Demo',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Flutter Physics Demo'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavigationButton(
                context,
                'Implicit Animations',
                const ImplicitAnimationsPage(),
              ),
              const SizedBox(height: 16),
              _buildNavigationButton(
                context,
                'Interrupted Animations',
                const InterruptedAnimationsPage(),
              ),
              const SizedBox(height: 16),
              _buildNavigationButton(
                context,
                'Physics Playground',
                const PhysicsPlaygroundPage(),
              ),
              const SizedBox(height: 16),
              _buildNavigationButton(
                context,
                'Physics Grid',
                const PhysicsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      BuildContext context, String title, Widget page) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => page),
          );
        },
        child: Text(title),
      ),
    );
  }
}

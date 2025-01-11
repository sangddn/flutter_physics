import 'package:flutter/material.dart';
import 'implicit_animations_page.dart';
import 'interrupted_animations_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Physics Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Physics Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Implicit Animations'),
              Tab(text: 'Interrupted Animations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ImplicitAnimationsPage(),
            InterruptedAnimationsPage(),
          ],
        ),
      ),
    );
  }
}

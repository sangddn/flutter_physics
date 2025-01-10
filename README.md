# Flutter Physics

A powerful Flutter package that brings physics-based animations to your app with an elegant, easy-to-use API. This package combines the precision of physical simulations with the simplicity of Flutter's animation system.

## Features

- 🎯 **Physics-First Animations**: Spring, gravity, and friction simulations that behave like real-world physics
- 🎨 **Drop-in Animated Widgets**: Ready-to-use widgets like `AContainer`, `APadding`, `AAlign`, and more that automatically animate with physics
- 🎮 **Flexible Controllers**: `PhysicsController` and `PhysicsController2D` for precise control over physics-based animations
- 🔄 **Curve Compatibility**: All physics simulations can be used as standard Flutter curves
- 📐 **2D Motion Support**: Built-in support for 2D physics animations with combined X/Y simulations

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_physics: ^latest_version
```

## Usage

### Physics-Based Animated Widgets

Use the pre-built widgets that start with 'A' for automatic physics animations:

```dart
AContainer(
  physics: Spring.elegant, // Pre-configured spring with elegant motion
  decoration: BoxDecoration(
    color: _isAnimated ? Colors.blue : Colors.red,
    borderRadius: BorderRadius.circular(8),
  ),
  child: const SizedBox(width: 100, height: 100),
),
```

### Custom Spring Animations

Create custom spring animations with precise control:

```dart
final springAnimation = Spring(
  description: SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 20.0,
  ),
  start: 0.0,
  end: 100.0,
  initialVelocity: 0.0,
);

// Use with AnimationController
controller.animateWith(springAnimation);

// Or use as a Curve
AnimatedContainer(
  duration: const Duration(seconds: 1),
  curve: springAnimation,
  // ... other properties
);
```

### Gravity and Friction

Simulate gravity or friction-based motion:

```dart
final gravityAnimation = Gravity(
  gravity: 9.81,
  start: 0.0,
  end: 100.0,
);

final frictionAnimation = Friction(
  friction: 0.5,
  start: 0.0,
  end: 100.0,
  initialVelocity: 1000.0,
);
```

### 2D Physics

Create complex 2D motion with combined physics:

```dart
final controller2D = PhysicsController2D(
  vsync: this,
  defaultPhysics: Simulation2D(
    Spring.elegant, // X-axis physics
    Spring.swift,   // Y-axis physics
  ),
);
```

## Pre-configured Physics

The package includes carefully tuned presets:

- `Spring.elegant`: Smooth motion with slight bounce
- `Spring.swift`: Snappy motion with minimal oscillation

## Additional Information

- [API Documentation](https://pub.dev/documentation/flutter_physics/latest/)
- [GitHub Repository](https://github.com/sangddn/flutter_physics)
- [Bug Reports](https://github.com/sangddn/flutter_physics/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

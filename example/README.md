# Flutter Physics Example

This is a demo project showcasing the `flutter_physics` package, which provides physics-based animations and widgets for Flutter applications. The example demonstrates various ways to add delightful, natural-feeling animations to your Flutter UI.

## Features

### 1. Physics Grid
The main showcase is an interactive grid of animated elements that respond to touch with physics-based animations:
- A 4x4 grid of circular elements that react to touch with spring animations
- Each element's animation is influenced by its distance from the touched element
- Custom spring physics with varying stiffness and bounce based on position
- Smooth color transitions using physics-based controllers

### 2. Implicit Animations
The example also includes a demonstration of implicit animations using physics:
- Comparison between standard curve-based animations and physics-based ones
- Animated containers, sizes, positions, and other properties
- Uses the `Spring.buoyant` preset for natural, bouncy animations

## Getting Started

1. Clone this repository
2. Ensure you have Flutter installed and set up
3. Run `flutter pub get` to install dependencies
4. Launch the example with `flutter run`

## Playing with the Example

You can experiment with the physics-based animations in several ways:

1. **Physics Grid:**
   - Tap and drag any circle in the grid
   - Observe how surrounding circles react with varying spring animations
   - Notice how the animation characteristics change based on distance from the touched element

2. **Implicit Animations:**
   - Navigate to the implicit animations page
   - Tap the controls to trigger state changes
   - Compare the natural feel of physics-based animations versus traditional curve-based ones

3. **Customization:**
   You can modify various physics parameters in the code:
   - Adjust spring stiffness, damping, and bounce in `_springForCell()`
   - Modify animation durations
   - Change the grid size or element spacing

## Learning More

This example demonstrates how physics-based animations can create more engaging and natural-feeling user interfaces. The animations respond to user input with realistic motion, making the interface feel more dynamic and alive.

For more details about Flutter animations and physics-based motion, check out:
- [Flutter Physics Package Documentation](https://pub.dev/packages/flutter_physics)
- [Flutter Animation Documentation](https://docs.flutter.dev/development/ui/animations)

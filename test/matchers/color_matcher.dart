import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ColorMatcher extends Matcher {
  final Color expectedColor;
  final double epsilon;

  const ColorMatcher(this.expectedColor, {this.epsilon = 0.001});

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! Color) return false;

    return item.r.closeTo(expectedColor.r, epsilon) &&
        item.g.closeTo(expectedColor.g, epsilon) &&
        item.b.closeTo(expectedColor.b, epsilon) &&
        item.a.closeTo(expectedColor.a, epsilon);
  }

  @override
  Description describe(Description description) =>
      description.add('matches color ${expectedColor.toString()}');

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (item is! Color) {
      return mismatchDescription.add('is not a Color');
    }
    return mismatchDescription.add(
        'was Color(r: ${item.r}, g: ${item.g}, b: ${item.b}, a: ${item.a})');
  }
}

/// Matches if the color components are within [epsilon] of the expected color
Matcher matchesColor(Color color, {double epsilon = 0.001}) =>
    ColorMatcher(color, epsilon: epsilon);

/// Matches if the color components are NOT within [epsilon] of the expected color
Matcher notMatchesColor(Color color, {double epsilon = 0.001}) =>
    isNot(ColorMatcher(color, epsilon: epsilon));

extension _CloseTo on double {
  bool closeTo(double other, double epsilon) => (this - other).abs() <= epsilon;
}

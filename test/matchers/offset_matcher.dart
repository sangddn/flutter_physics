import 'package:flutter_test/flutter_test.dart';

/// Matches an [Offset] with optional tolerance.
///
/// Example:
/// ```dart
/// expect(offset, matchesOffset(Offset(10, 10), tolerance: 0.1));
/// ```
Matcher matchesOffset(Offset expected, {double tolerance = 0.0001}) {
  return _OffsetMatcher(expected, tolerance);
}

class _OffsetMatcher extends Matcher {
  final Offset expected;
  final double tolerance;

  const _OffsetMatcher(this.expected, this.tolerance);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Offset) return false;
    final dx = (item.dx - expected.dx).abs();
    final dy = (item.dy - expected.dy).abs();
    return dx <= tolerance && dy <= tolerance;
  }

  @override
  Description describe(Description description) {
    return description
        .add('matches Offset(${expected.dx}, ${expected.dy}) ')
        .add('within tolerance of $tolerance');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Offset) {
      return mismatchDescription.add('is not an Offset');
    }
    return mismatchDescription.add(
      'was Offset(${item.dx}, ${item.dy})',
    );
  }
}

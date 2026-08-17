import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('Durations', () {
    test('kHoverDuration is 100 milliseconds', () {
      expect(kHoverDuration, equals(const Duration(milliseconds: 100)));
    });

    test('kPageTransitionDuration is 250 milliseconds', () {
      expect(
        kPageTransitionDuration,
        equals(const Duration(milliseconds: 250)),
      );
    });
  });
}

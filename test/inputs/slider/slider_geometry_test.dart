import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('quantizeLayrzSliderValue', () {
    test('returns the clamped value unchanged when divisions is null', () {
      expect(
        quantizeLayrzSliderValue(value: 42.3, min: 0, max: 100, divisions: null),
        42.3,
      );
    });

    test('returns the clamped value unchanged when divisions is 0', () {
      expect(
        quantizeLayrzSliderValue(value: 42.3, min: 0, max: 100, divisions: 0),
        42.3,
      );
    });

    test('returns the clamped value unchanged when divisions is 1', () {
      expect(
        quantizeLayrzSliderValue(value: 42.3, min: 0, max: 100, divisions: 1),
        42.3,
      );
    });

    test('snaps to the nearest of 4 divisions', () {
      // Divisions of 4 over [0, 100] -> steps at 0, 25, 50, 75, 100.
      expect(quantizeLayrzSliderValue(value: 10, min: 0, max: 100, divisions: 4), 0);
      expect(quantizeLayrzSliderValue(value: 13, min: 0, max: 100, divisions: 4), 25);
      expect(quantizeLayrzSliderValue(value: 60, min: 0, max: 100, divisions: 4), 50);
      expect(quantizeLayrzSliderValue(value: 99, min: 0, max: 100, divisions: 4), 100);
    });

    test('clamps a value above max before quantising', () {
      expect(quantizeLayrzSliderValue(value: 500, min: 0, max: 100, divisions: 4), 100);
    });

    test('clamps a value below min before quantising', () {
      expect(quantizeLayrzSliderValue(value: -500, min: 0, max: 100, divisions: 4), 0);
    });

    test('collapses to min when max == min (degenerate range)', () {
      expect(quantizeLayrzSliderValue(value: 5, min: 10, max: 10, divisions: 4), 10);
      expect(quantizeLayrzSliderValue(value: 100, min: 10, max: 10, divisions: null), 10);
    });

    test('handles a non-zero-based range', () {
      // [10, 20] with 2 divisions -> steps at 10, 15, 20.
      expect(quantizeLayrzSliderValue(value: 12, min: 10, max: 20, divisions: 2), 10);
      expect(quantizeLayrzSliderValue(value: 14, min: 10, max: 20, divisions: 2), 15);
      expect(quantizeLayrzSliderValue(value: 18, min: 10, max: 20, divisions: 2), 20);
    });
  });

  group('layrzSliderValueToFraction', () {
    test('returns 0.0 at min', () {
      expect(layrzSliderValueToFraction(value: 0, min: 0, max: 100), 0.0);
    });

    test('returns 1.0 at max', () {
      expect(layrzSliderValueToFraction(value: 100, min: 0, max: 100), 1.0);
    });

    test('returns 0.5 at the midpoint', () {
      expect(layrzSliderValueToFraction(value: 50, min: 0, max: 100), 0.5);
    });

    test('clamps above 1.0 for an out-of-range value', () {
      expect(layrzSliderValueToFraction(value: 999, min: 0, max: 100), 1.0);
    });

    test('clamps below 0.0 for an out-of-range value', () {
      expect(layrzSliderValueToFraction(value: -999, min: 0, max: 100), 0.0);
    });

    test('returns 0.0 when max == min (degenerate range)', () {
      expect(layrzSliderValueToFraction(value: 10, min: 10, max: 10), 0.0);
    });
  });

  group('layrzSliderFractionToValue', () {
    test('returns min at fraction 0.0', () {
      expect(layrzSliderFractionToValue(fraction: 0.0, min: 0, max: 100), 0.0);
    });

    test('returns max at fraction 1.0', () {
      expect(layrzSliderFractionToValue(fraction: 1.0, min: 0, max: 100), 100.0);
    });

    test('returns the midpoint at fraction 0.5', () {
      expect(layrzSliderFractionToValue(fraction: 0.5, min: 0, max: 100), 50.0);
    });

    test('clamps a fraction above 1.0', () {
      expect(layrzSliderFractionToValue(fraction: 2.0, min: 0, max: 100), 100.0);
    });

    test('clamps a fraction below 0.0', () {
      expect(layrzSliderFractionToValue(fraction: -2.0, min: 0, max: 100), 0.0);
    });
  });
}

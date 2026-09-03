import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('formatLayrzProgressValue', () {
    test('a true zero value formats as 0% regardless of decimals', () {
      expect(formatLayrzProgressValue(0.0, 0), '0%');
      expect(formatLayrzProgressValue(0.0, 1), '0%');
      expect(formatLayrzProgressValue(0.0, 2), '0%');
    });

    test('a true one value formats as 100% regardless of decimals', () {
      expect(formatLayrzProgressValue(1.0, 0), '100%');
      expect(formatLayrzProgressValue(1.0, 1), '100%');
      expect(formatLayrzProgressValue(1.0, 2), '100%');
    });

    test('a tiny non-zero value that would round to 0 floors up to the smallest step', () {
      expect(formatLayrzProgressValue(0.001, 0), '1%');
      expect(formatLayrzProgressValue(0.004, 0), '1%');
      expect(formatLayrzProgressValue(0.0001, 1), '0.1%');
      expect(formatLayrzProgressValue(0.0001, 2), '0.01%');
    });

    test('a value just below 1.0 that would round to 100 ceils down to the largest step below it', () {
      expect(formatLayrzProgressValue(0.999, 0), '99%');
      expect(formatLayrzProgressValue(0.9999, 1), '99.9%');
      expect(formatLayrzProgressValue(0.99999, 2), '99.99%');
    });

    test('unaffected mid-range values format exactly as toStringAsFixed would', () {
      expect(formatLayrzProgressValue(0.5, 0), '50%');
      expect(formatLayrzProgressValue(0.6789, 0), '68%');
      expect(formatLayrzProgressValue(0.6789, 1), '67.9%');
      expect(formatLayrzProgressValue(0.6789, 2), '67.89%');
    });

    test('a value large enough to round normally at decimals: 0 is untouched', () {
      // 0.06 rounds to '6%' -- a genuine, non-boundary rounding, not the
      // all-zero-digits case this function guards against.
      expect(formatLayrzProgressValue(0.06, 0), '6%');
    });

    test('a value low enough to round normally away from the 100% boundary is untouched', () {
      // 0.94 rounds to '94%' -- nowhere near rounding up to 100.
      expect(formatLayrzProgressValue(0.94, 0), '94%');
    });

    test('values outside [0.0, 1.0] are clamped before formatting', () {
      expect(formatLayrzProgressValue(-0.5, 0), '0%');
      expect(formatLayrzProgressValue(1.5, 0), '100%');
    });
  });
}

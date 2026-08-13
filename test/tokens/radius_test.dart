import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzRadiusTokens', () {
    test('default constructor uses correct values', () {
      const tokens = LayrzRadiusTokens();

      expect(tokens.base, equals(8.0));
      expect(tokens.r8, equals(8.0));
      expect(tokens.r10, equals(10.0));
      expect(tokens.r12, equals(12.0));
      expect(tokens.r14, equals(14.0));
      expect(tokens.r16, equals(16.0));
      expect(tokens.r20, equals(20.0));
      expect(tokens.r24, equals(24.0));
      expect(tokens.full, equals(999.0));
    });

    test('radius values match their names', () {
      const tokens = LayrzRadiusTokens();

      expect(tokens.r12, equals(12.0));
      expect(tokens.r24, equals(24.0));
    });

    test('full is pill-shaped (999)', () {
      const tokens = LayrzRadiusTokens();
      expect(tokens.full, equals(999.0));
    });

    test('borderRadius getter returns BorderRadius with base value', () {
      const tokens = LayrzRadiusTokens();
      expect(tokens.borderRadius, equals(BorderRadius.circular(8.0)));
    });

    test('innerRadius subtracts spacer from outer radius', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadius(outerRadius: 12.0, spacer: 4.0);
      expect(result, equals(BorderRadius.circular(8.0)));
    });

    test('innerRadius clamps to zero when spacer exceeds outerRadius', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadius(outerRadius: 4.0, spacer: 10.0);
      expect(result, equals(BorderRadius.circular(0.0)));
    });

    test('innerRadius never goes negative', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadius(outerRadius: 2.0, spacer: 100.0);
      expect(result, equals(BorderRadius.circular(0.0)));
    });

    test('copyWith creates new instance with replaced fields', () {
      const original = LayrzRadiusTokens();
      final modified = original.copyWith(r12: 14.0, base: 10.0);

      expect(modified.r12, equals(14.0));
      expect(modified.base, equals(10.0));
      expect(modified.r8, equals(original.r8));
      expect(original.r12, equals(12.0)); // original unchanged
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzRadiusTokens();
      const tokens2 = LayrzRadiusTokens();
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      const original = LayrzRadiusTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different base values', () {
      const tokens1 = LayrzRadiusTokens();
      final tokens2 = LayrzRadiusTokens(base: 10.0);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzRadiusTokens();
      const tokens2 = LayrzRadiusTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      const tokens1 = LayrzRadiusTokens();
      final tokens2 = LayrzRadiusTokens(base: 10.0);
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('custom base value propagates to borderRadius getter', () {
      final tokens = LayrzRadiusTokens(base: 12.0);
      expect(tokens.borderRadius, equals(BorderRadius.circular(12.0)));
    });
  });
}

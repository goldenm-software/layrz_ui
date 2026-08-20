import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzRadiusTokens', () {
    test('default constructor uses correct values', () {
      const tokens = LayrzRadiusTokens();

      expect(tokens.r1, equals(4.0));
      expect(tokens.r2, equals(8.0));
      expect(tokens.r3, equals(16.0));
      expect(tokens.r4, equals(24.0));
      expect(tokens.r5, equals(32.0));
      expect(tokens.full, equals(999.0));
    });

    test('border radius getters return BorderRadius.circular with correct values', () {
      const tokens = LayrzRadiusTokens();

      expect(tokens.br1, equals(BorderRadius.circular(4.0)));
      expect(tokens.br2, equals(BorderRadius.circular(8.0)));
      expect(tokens.br3, equals(BorderRadius.circular(16.0)));
      expect(tokens.br4, equals(BorderRadius.circular(24.0)));
      expect(tokens.br5, equals(BorderRadius.circular(32.0)));
    });

    test('full is pill-shaped (999)', () {
      const tokens = LayrzRadiusTokens();
      expect(tokens.full, equals(999.0));
    });

    test('innerRadiusValue subtracts spacer from outer radius', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadiusValue(outerRadius: 12.0, spacer: 4.0);
      expect(result, equals(8.0));
    });

    test('innerRadiusValue clamps to zero when spacer exceeds outerRadius', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadiusValue(outerRadius: 4.0, spacer: 10.0);
      expect(result, equals(0.0));
    });

    test('innerRadiusValue never goes negative', () {
      const tokens = LayrzRadiusTokens();
      final result = tokens.innerRadiusValue(outerRadius: 2.0, spacer: 100.0);
      expect(result, equals(0.0));
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
      final modified = original.copyWith(r1: 5.0, r4: 25.0);

      expect(modified.r1, equals(5.0));
      expect(modified.r4, equals(25.0));
      expect(modified.r2, equals(original.r2));
      expect(modified.r3, equals(original.r3));
      expect(modified.r5, equals(original.r5));
      expect(modified.full, equals(original.full));
      expect(original.r1, equals(4.0)); // original unchanged
    });

    test('copyWith with no arguments returns equal instance', () {
      const original = LayrzRadiusTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzRadiusTokens();
      const tokens2 = LayrzRadiusTokens();
      expect(tokens1, equals(tokens2));
    });

    test('inequality works for different values', () {
      const tokens1 = LayrzRadiusTokens();
      final tokens2 = LayrzRadiusTokens(r1: 5.0);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzRadiusTokens();
      const tokens2 = LayrzRadiusTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      const tokens1 = LayrzRadiusTokens();
      final tokens2 = LayrzRadiusTokens(r1: 5.0);
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('custom radius values propagate to border radius getters', () {
      final tokens = LayrzRadiusTokens(
        r1: 5.0,
        r2: 10.0,
        r3: 20.0,
        r4: 30.0,
        r5: 40.0,
      );

      expect(tokens.br1, equals(BorderRadius.circular(5.0)));
      expect(tokens.br2, equals(BorderRadius.circular(10.0)));
      expect(tokens.br3, equals(BorderRadius.circular(20.0)));
      expect(tokens.br4, equals(BorderRadius.circular(30.0)));
      expect(tokens.br5, equals(BorderRadius.circular(40.0)));
    });

    test('custom full value is preserved', () {
      final tokens = LayrzRadiusTokens(full: 500.0);
      expect(tokens.full, equals(500.0));
    });
  });
}

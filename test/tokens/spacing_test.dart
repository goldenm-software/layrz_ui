import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('LayrzSpacingTokens', () {
    test('default constructor uses correct values', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.base, equals(8.0));
      expect(tokens.sp4, equals(4.0));
      expect(tokens.sp6, equals(6.0));
      expect(tokens.sp8, equals(8.0));
      expect(tokens.sp10, equals(10.0));
      expect(tokens.sp12, equals(12.0));
      expect(tokens.sp14, equals(14.0));
      expect(tokens.sp16, equals(16.0));
      expect(tokens.sp20, equals(20.0));
      expect(tokens.sp24, equals(24.0));
      expect(tokens.sp28, equals(28.0));
      expect(tokens.sp32, equals(32.0));
      expect(tokens.sp36, equals(36.0));
      expect(tokens.sp40, equals(40.0));
      expect(tokens.sp44, equals(44.0));
      expect(tokens.sp48, equals(48.0));
    });

    test('spacing values match their names', () {
      const tokens = LayrzSpacingTokens();

      expect(tokens.sp8, equals(8.0));
      expect(tokens.sp48, equals(48.0));
    });

    test('base equals 8', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.base, equals(8.0));
    });

    test('spacingSize getter returns correct size', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.spacingSize, equals(const Size(8.0, 8.0)));
    });

    test('sizedBox returns SizedBox with correct size', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.sizedBox, isA<SizedBox>());
    });

    test('margin returns EdgeInsets with base value', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.margin, equals(EdgeInsets.all(8.0)));
    });

    test('reducedMargin returns EdgeInsets with half base value', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.reducedMargin, equals(EdgeInsets.all(4.0)));
    });

    test('padding returns EdgeInsets with base value', () {
      const tokens = LayrzSpacingTokens();
      expect(tokens.padding, equals(EdgeInsets.all(8.0)));
    });

    test('copyWith creates new instance with replaced fields', () {
      const original = LayrzSpacingTokens();
      final modified = original.copyWith(sp16: 20.0, base: 10.0);

      expect(modified.sp16, equals(20.0));
      expect(modified.base, equals(10.0));
      expect(modified.sp8, equals(original.sp8));
      expect(original.sp16, equals(16.0)); // original unchanged
    });

    test('equality works for identical values', () {
      const tokens1 = LayrzSpacingTokens();
      const tokens2 = LayrzSpacingTokens();
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      const original = LayrzSpacingTokens();
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different base values', () {
      const tokens1 = LayrzSpacingTokens();
      final tokens2 = LayrzSpacingTokens(base: 10.0);
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      const tokens1 = LayrzSpacingTokens();
      const tokens2 = LayrzSpacingTokens();
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      const tokens1 = LayrzSpacingTokens();
      final tokens2 = LayrzSpacingTokens(base: 10.0);
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('custom base value propagates to convenience getters', () {
      final tokens = LayrzSpacingTokens(base: 12.0);
      expect(tokens.margin, equals(EdgeInsets.all(12.0)));
      expect(tokens.reducedMargin, equals(EdgeInsets.all(6.0)));
      expect(tokens.spacingSize, equals(const Size(12.0, 12.0)));
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('LayrzBorderTokens', () {
    test('default constructor uses correct values', () {
      final tokens = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));

      expect(tokens.base, equals(1.5));
      expect(tokens.stroke1, equals(1.0));
      expect(tokens.stroke2, equals(2.0));
      expect(tokens.stroke3, equals(3.0));
      expect(tokens.dividerColor, equals(const Color(0xFFE0E0E0)));
    });

    test('light getter has correct stroke and color', () {
      final tokens = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));

      expect(tokens.light.width, equals(1.0));
      expect(tokens.light.color, equals(const Color(0xFFE0E0E0)));
    });

    test('normal getter has correct stroke and color', () {
      final tokens = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));

      expect(tokens.normal.width, equals(2.0));
      expect(tokens.normal.color, equals(const Color(0xFFE0E0E0)));
    });

    test('thick getter has correct stroke and color', () {
      final tokens = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));

      expect(tokens.thick.width, equals(3.0));
      expect(tokens.thick.color, equals(const Color(0xFFE0E0E0)));
    });

    test('copyWith creates new instance with replaced fields', () {
      final original = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      const newDividerColor = Color(0xFF999999);
      final modified = original.copyWith(
        base: 2.0,
        dividerColor: newDividerColor,
      );

      expect(modified.base, equals(2.0));
      expect(modified.dividerColor, equals(newDividerColor));
      expect(modified.stroke1, equals(original.stroke1));
      expect(original.base, equals(1.5)); // original unchanged
    });

    test('equality works for identical values', () {
      final tokens1 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      final tokens2 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      final original = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different dividerColor', () {
      final tokens1 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      final tokens2 = LayrzBorderTokens(dividerColor: const Color(0xFF999999));
      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      final tokens1 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      final tokens2 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different values', () {
      final tokens1 = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));
      final tokens2 = LayrzBorderTokens(dividerColor: const Color(0xFF999999));
      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('all borders use the same divider color', () {
      final tokens = LayrzBorderTokens(dividerColor: const Color(0xFFE0E0E0));

      expect(tokens.light.color, equals(tokens.dividerColor));
      expect(tokens.normal.color, equals(tokens.dividerColor));
      expect(tokens.thick.color, equals(tokens.dividerColor));
    });
  });
}

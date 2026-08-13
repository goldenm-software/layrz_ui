import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzTokens', () {
    test('light factory creates correct structure', () {
      final tokens = LayrzTokens.light();

      expect(tokens.colors, isA<LayrzColorTokens>());
      expect(tokens.typography, isA<LayrzTextTheme>());
      expect(tokens.spacing, isA<LayrzSpacingTokens>());
      expect(tokens.radius, isA<LayrzRadiusTokens>());
      expect(tokens.shadow, isA<LayrzShadowTokens>());
      expect(tokens.border, isA<LayrzBorderTokens>());
      expect(tokens.motion, isA<LayrzMotionTokens>());
    });

    test('light factory wires shadow.surfaceColor to colors.surface', () {
      final tokens = LayrzTokens.light();

      expect(tokens.shadow.surfaceColor, equals(tokens.colors.surface));
    });

    test('light factory wires border.dividerColor to colors.divider', () {
      final tokens = LayrzTokens.light();

      expect(tokens.border.dividerColor, equals(tokens.colors.divider));
    });

    test('light factory wires typography textColor to colors.fg1', () {
      final tokens = LayrzTokens.light();

      // All text styles should have fg1 as their color
      expect(tokens.typography.bodyMedium.color, equals(tokens.colors.fg1));
      expect(tokens.typography.displayLarge.color, equals(tokens.colors.fg1));
      expect(tokens.typography.labelSmall.color, equals(tokens.colors.fg1));
    });

    test('light factory respects primaryColor parameter', () {
      const customPrimary = Color(0xFF123456);
      final tokens = LayrzTokens.light(primaryColor: customPrimary);

      expect(tokens.colors.primary, equals(customPrimary));
    });

    test('light factory respects accentColor parameter', () {
      const customAccent = Color(0xFF654321);
      final tokens = LayrzTokens.light(accentColor: customAccent);

      expect(tokens.colors.accent, equals(customAccent));
    });

    test('light factory uses default colors when not specified', () {
      final tokens = LayrzTokens.light();

      expect(tokens.colors.primary, equals(kPrimaryColor));
      expect(tokens.colors.accent, equals(kAccentColor));
    });

    test('light factory wires shadow.baseRadius to radius.base', () {
      final tokens = LayrzTokens.light();

      expect(tokens.shadow.baseRadius, equals(tokens.radius.base));
    });

    test('copyWith creates new instance with replaced categories', () {
      final original = LayrzTokens.light();
      final newColors = LayrzColorTokens.light(
        primary: const Color(0xFF888888),
      );
      final modified = original.copyWith(colors: newColors);

      expect(modified.colors.primary, equals(const Color(0xFF888888)));
      expect(modified.typography, equals(original.typography));
      expect(
        original.colors.primary,
        equals(kPrimaryColor),
      ); // original unchanged
    });

    test('equality works for identical light factories', () {
      final tokens1 = LayrzTokens.light();
      final tokens2 = LayrzTokens.light();

      expect(tokens1, equals(tokens2));
    });

    test('equality works for copyWith with same values', () {
      final original = LayrzTokens.light();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('inequality works for different primary colors', () {
      final tokens1 = LayrzTokens.light();
      final tokens2 = LayrzTokens.light(primaryColor: const Color(0xFF888888));

      expect(tokens1, isNot(equals(tokens2)));
    });

    test('hashCode is stable for same values', () {
      final tokens1 = LayrzTokens.light();
      final tokens2 = LayrzTokens.light();

      expect(tokens1.hashCode, equals(tokens2.hashCode));
    });

    test('hashCode differs for different primary colors', () {
      final tokens1 = LayrzTokens.light();
      final tokens2 = LayrzTokens.light(primaryColor: const Color(0xFF888888));

      expect(tokens1.hashCode, isNot(equals(tokens2.hashCode)));
    });

    test('all derived tokens are seeded consistently', () {
      final tokens = LayrzTokens.light();

      // Verify the key wiring relationships
      expect(tokens.shadow.surfaceColor, equals(tokens.colors.surface));
      expect(tokens.border.dividerColor, equals(tokens.colors.divider));
      expect(tokens.shadow.baseRadius, equals(tokens.radius.base));

      // Typography should use fg1 for text color
      final bodyStyle = tokens.typography.bodyMedium;
      expect(bodyStyle.color, equals(tokens.colors.fg1));
    });
  });
}

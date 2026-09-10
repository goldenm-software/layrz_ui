import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

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

    test('light factory wires shadow.surfaceColor to colors.sf1', () {
      final tokens = LayrzTokens.light();

      expect(tokens.shadow.surfaceColor, equals(tokens.colors.sf1));
    });

    test('light factory wires border.dividerColor to colors.divider', () {
      final tokens = LayrzTokens.light();

      expect(tokens.border.dividerColor, equals(tokens.colors.divider));
    });

    test('light factory wires typography textColor to colors.fg1', () {
      final tokens = LayrzTokens.light();

      // All text styles should have fg1 as their color
      expect(tokens.typography.body.color, equals(tokens.colors.fg1));
      expect(tokens.typography.display.color, equals(tokens.colors.fg1));
      expect(tokens.typography.label.color, equals(tokens.colors.fg1));
    });

    test('light factory respects primaryColor parameter', () {
      const customPrimary = Color(0xFF123456);
      final tokens = LayrzTokens.light(primaryColor: customPrimary);

      expect(tokens.colors.primary, equals(customPrimary));
    });

    test('light factory uses default colors when not specified', () {
      final tokens = LayrzTokens.light();

      expect(tokens.colors.primary, equals(kLightPrimaryColor));
    });

    test('light factory wires shadow.baseRadius to radius.r2', () {
      final tokens = LayrzTokens.light();

      expect(tokens.shadow.baseRadius, equals(tokens.radius.r2));
    });

    test('copyWith creates new instance with replaced categories', () {
      final original = LayrzTokens.light();
      final newColors = LayrzColorTokens.light(
        primary: const Color(0xFF888888),
      );
      final modified = original.copyWith(colors: newColors);

      expect(modified.colors.primary, equals(const Color(0xFF888888)));
      expect(modified.typography, equals(original.typography));
      expect(original.colors.primary, equals(kLightPrimaryColor)); // original unchanged
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
      expect(tokens.shadow.surfaceColor, equals(tokens.colors.sf1));
      expect(tokens.border.dividerColor, equals(tokens.colors.divider));
      expect(tokens.shadow.baseRadius, equals(tokens.radius.r2));

      // Typography should use fg1 for text color
      final bodyStyle = tokens.typography.body;
      expect(bodyStyle.color, equals(tokens.colors.fg1));
    });

    group('dark() factory (BETA)', () {
      test('dark factory creates correct structure', () {
        final tokens = LayrzTokens.dark();

        expect(tokens.colors, isA<LayrzColorTokens>());
        expect(tokens.typography, isA<LayrzTextTheme>());
        expect(tokens.spacing, isA<LayrzSpacingTokens>());
        expect(tokens.radius, isA<LayrzRadiusTokens>());
        expect(tokens.shadow, isA<LayrzShadowTokens>());
        expect(tokens.border, isA<LayrzBorderTokens>());
        expect(tokens.motion, isA<LayrzMotionTokens>());
      });

      test('dark factory sets brightness to dark; light factory to light', () {
        expect(LayrzTokens.dark().brightness, equals(Brightness.dark));
        expect(LayrzTokens.light().brightness, equals(Brightness.light));
      });

      test('dark factory uses default dark primary color', () {
        final tokens = LayrzTokens.dark();
        expect(tokens.colors.primary, equals(kDarkPrimaryColor));
      });

      test('dark factory respects primaryColor parameter', () {
        const customPrimary = Color(0xFF123456);
        final tokens = LayrzTokens.dark(primaryColor: customPrimary);

        expect(tokens.colors.primary, equals(customPrimary));
      });

      test('dark factory wires shadow.surfaceColor to dark colors.sf1', () {
        final tokens = LayrzTokens.dark();

        expect(tokens.colors.sf1, equals(const Color(0xFF29272C)));
        expect(tokens.shadow.surfaceColor, equals(tokens.colors.sf1));
      });

      test('dark factory boosts shadow opacity so a black shadow reads on dark', () {
        final tokens = LayrzTokens.dark();

        // Elevation on dark uses a black shadow (like light) but at a boosted
        // opacity scale, plus a faint light outline at elevation 0. The lighter
        // dark surface gives the black shadow the contrast it needs.
        expect(tokens.shadow.shadowColor, equals(const Color(0xFF000000)));
        expect(tokens.shadow.shadowOpacityScale, equals(2.0));
        expect(tokens.shadow.outlineColor, equals(const Color(0x1FFFFFFF)));
        expect(tokens.shadow.elevationOverlay, isFalse);

        // Light theme keeps the black shadow at the default 1.0 scale.
        expect(LayrzTokens.light().shadow.shadowColor, equals(const Color(0xFF000000)));
        expect(LayrzTokens.light().shadow.shadowOpacityScale, equals(1.0));
      });

      test('dark factory wires border.dividerColor to dark colors.divider', () {
        final tokens = LayrzTokens.dark();

        expect(tokens.colors.divider, equals(const Color(0x14FFFFFF)));
        expect(tokens.border.dividerColor, equals(tokens.colors.divider));
      });

      test('dark factory wires typography textColor to dark colors.fg1', () {
        final tokens = LayrzTokens.dark();

        expect(tokens.colors.fg1, equals(const Color(0xFFECEEF3)));
        expect(tokens.typography.body.color, equals(tokens.colors.fg1));
        expect(tokens.typography.display.color, equals(tokens.colors.fg1));
        expect(tokens.typography.label.color, equals(tokens.colors.fg1));
      });

      test('dark factory wires shadow.baseRadius to radius.r2', () {
        final tokens = LayrzTokens.dark();

        expect(tokens.shadow.baseRadius, equals(tokens.radius.r2));
      });

      test('dark tokens differ from light tokens', () {
        final light = LayrzTokens.light();
        final dark = LayrzTokens.dark();

        expect(light, isNot(equals(dark)));
        expect(light.colors, isNot(equals(dark.colors)));
      });
    });
  });
}

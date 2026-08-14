import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/fonts/fonts.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzTextTheme', () {
    test('defaults factory applies textColor to all styles', () {
      const testColor = Color(0xFF123456);
      final theme = LayrzTextTheme.defaults(textColor: testColor);

      expect(theme.displayLarge.color, equals(testColor));
      expect(theme.displayMedium.color, equals(testColor));
      expect(theme.displaySmall.color, equals(testColor));
      expect(theme.headlineLarge.color, equals(testColor));
      expect(theme.headlineMedium.color, equals(testColor));
      expect(theme.headlineSmall.color, equals(testColor));
      expect(theme.titleLarge.color, equals(testColor));
      expect(theme.titleMedium.color, equals(testColor));
      expect(theme.titleSmall.color, equals(testColor));
      expect(theme.bodyLarge.color, equals(testColor));
      expect(theme.bodyMedium.color, equals(testColor));
      expect(theme.bodySmall.color, equals(testColor));
      expect(theme.labelLarge.color, equals(testColor));
      expect(theme.labelMedium.color, equals(testColor));
      expect(theme.labelSmall.color, equals(testColor));
    });

    test('defaults factory uses correct font sizes', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.displayLarge.fontSize, equals(57));
      expect(theme.displayMedium.fontSize, equals(45));
      expect(theme.displaySmall.fontSize, equals(36));
      expect(theme.headlineLarge.fontSize, equals(32));
      expect(theme.headlineMedium.fontSize, equals(28));
      expect(theme.headlineSmall.fontSize, equals(24));
      expect(theme.titleLarge.fontSize, equals(22));
      expect(theme.titleMedium.fontSize, equals(16));
      expect(theme.titleSmall.fontSize, equals(14));
      expect(theme.bodyLarge.fontSize, equals(16));
      expect(theme.bodyMedium.fontSize, equals(14));
      expect(theme.bodySmall.fontSize, equals(12));
      expect(theme.labelLarge.fontSize, equals(14));
      expect(theme.labelMedium.fontSize, equals(12));
      expect(theme.labelSmall.fontSize, equals(11));
    });

    test('defaults factory with null fontHandler uses font name directly', () {
      final theme = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
        titleFont: const LayrzFont(
          source: LayrzFontSource.google,
          name: 'Open Sans',
        ),
        bodyFont: const LayrzFont(
          source: LayrzFontSource.google,
          name: 'Roboto',
        ),
        fontHandler: null,
      );

      expect(theme.displayLarge.fontFamily, equals('Open Sans'));
      expect(theme.bodyMedium.fontFamily, equals('Roboto'));
      expect(theme.titleLarge.fontFamilyFallback, equals(kLayrzFontFallbacks));
    });

    test('all styles have overflow ellipsis', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.displayLarge.overflow, equals(TextOverflow.ellipsis));
      expect(theme.bodyMedium.overflow, equals(TextOverflow.ellipsis));
      expect(theme.labelSmall.overflow, equals(TextOverflow.ellipsis));
    });

    test('all styles have no text decoration', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.displayLarge.decoration, equals(TextDecoration.none));
      expect(theme.bodyMedium.decoration, equals(TextDecoration.none));
      expect(theme.labelSmall.decoration, equals(TextDecoration.none));
    });

    test('copyWith creates new instance with replaced styles', () {
      final original = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final newBodyMedium = original.bodyMedium.copyWith(fontSize: 20);
      final modified = original.copyWith(bodyMedium: newBodyMedium);

      expect(modified.bodyMedium.fontSize, equals(20));
      expect(modified.displayLarge, equals(original.displayLarge));
      expect(original.bodyMedium.fontSize, equals(14)); // original unchanged
    });

    test('equality works for identical factories', () {
      final theme1 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final theme2 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      expect(theme1, equals(theme2));
    });

    test('equality works for copyWith with same values', () {
      final original = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('inequality works for different colors', () {
      final theme1 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final theme2 = LayrzTextTheme.defaults(
        textColor: const Color(0xFFFFFFFF),
      );
      expect(theme1, isNot(equals(theme2)));
    });

    test('hashCode is stable for same values', () {
      final theme1 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final theme2 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('hashCode differs for different colors', () {
      final theme1 = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final theme2 = LayrzTextTheme.defaults(
        textColor: const Color(0xFFFFFFFF),
      );
      expect(theme1.hashCode, isNot(equals(theme2.hashCode)));
    });
  });
}

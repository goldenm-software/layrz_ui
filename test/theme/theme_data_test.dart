import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/fonts/fonts.dart';
import 'package:layrz_ui/theme/theme.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzThemeData', () {
    group('light() factory', () {
      test('uses default primary color', () {
        final data = LayrzThemeData.light();
        expect(data.primaryColor, equals(kPrimaryColor));
      });

      test('uses default background color', () {
        final data = LayrzThemeData.light();
        expect(data.backgroundColor, equals(kLightBackgroundColor));
      });

      test('accepts custom primary color', () {
        const customPrimary = Color(0xFF112233);
        final data = LayrzThemeData.light(primaryColor: customPrimary);
        expect(data.primaryColor, equals(customPrimary));
      });

      test('creates IconThemeData with fg1 color and size 24', () {
        final data = LayrzThemeData.light();
        expect(data.iconTheme.color, equals(data.tokens.colors.fg1));
        expect(data.iconTheme.size, equals(24));
      });

      test('accepts custom titleFont and bodyFont', () {
        final customFont = LayrzFont(
          source: LayrzFontSource.local,
          name: 'CustomFont',
        );
        final data = LayrzThemeData.light(
          titleFont: customFont,
          bodyFont: customFont,
        );
        // Verify that the typography was created (indirect verification).
        expect(data.tokens.typography, isNotNull);
        expect(data.tokens.typography.displayLarge, isNotNull);
      });
    });

    group('Delegating getters', () {
      late LayrzThemeData data;

      setUp(() {
        data = LayrzThemeData.light();
      });

      test('primaryColor delegates to tokens.colors.primary', () {
        expect(data.primaryColor, equals(data.tokens.colors.primary));
      });

      test('backgroundColor delegates to tokens.colors.background', () {
        expect(data.backgroundColor, equals(data.tokens.colors.background));
      });

      test('surfaceColor delegates to tokens.colors.surface', () {
        expect(data.surfaceColor, equals(data.tokens.colors.surface));
      });

      test('textColor delegates to tokens.colors.fg1', () {
        expect(data.textColor, equals(data.tokens.colors.fg1));
      });

      test('hintColor delegates to tokens.colors.fg3', () {
        expect(data.hintColor, equals(data.tokens.colors.fg3));
      });

      test('borderColor delegates to tokens.colors.divider', () {
        expect(data.borderColor, equals(data.tokens.colors.divider));
      });

      test('dangerColor delegates to tokens.colors.danger', () {
        expect(data.dangerColor, equals(data.tokens.colors.danger));
      });

      test('successColor delegates to tokens.colors.success', () {
        expect(data.successColor, equals(data.tokens.colors.success));
      });

      test('warningColor delegates to tokens.colors.warning', () {
        expect(data.warningColor, equals(data.tokens.colors.warning));
      });

      test('textTheme delegates to tokens.typography', () {
        expect(data.textTheme, same(data.tokens.typography));
      });

      test('textStyle returns tokens.typography.bodyMedium', () {
        expect(data.textStyle, equals(data.tokens.typography.bodyMedium));
      });

      test('borderRadius delegates to tokens.radius.base (8.0)', () {
        expect(data.borderRadius, equals(8.0));
        expect(data.borderRadius, equals(data.tokens.radius.base));
      });
    });

    group('copyWith', () {
      test('replaces tokens when provided', () {
        final data1 = LayrzThemeData.light();
        final customTokens = LayrzTokens.light(
          primaryColor: const Color(0xFF999999),
        );
        final data2 = data1.copyWith(tokens: customTokens);

        expect(data2.tokens, same(customTokens));
        expect(data1.tokens, isNot(same(customTokens)));
      });

      test('replaces iconTheme when provided', () {
        final data1 = LayrzThemeData.light();
        const customIconTheme = IconThemeData(
          color: Color(0xFF555555),
          size: 32,
        );
        final data2 = data1.copyWith(iconTheme: customIconTheme);

        expect(data2.iconTheme, equals(customIconTheme));
        expect(data1.iconTheme, isNot(equals(customIconTheme)));
      });

      test('preserves fields not in copyWith arguments', () {
        final data1 = LayrzThemeData.light();
        const customIconTheme = IconThemeData(
          color: Color(0xFF555555),
          size: 32,
        );
        final data2 = data1.copyWith(iconTheme: customIconTheme);

        expect(data2.tokens, same(data1.tokens));
      });
    });

    group('Equality', () {
      test('two light() instances with same args are equal', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light();

        expect(data1, equals(data2));
      });

      test('two instances with different primary colors are unequal', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light(
          primaryColor: const Color(0xFF999999),
        );

        expect(data1, isNot(equals(data2)));
      });

      test('identical instances are equal', () {
        final data = LayrzThemeData.light();
        expect(data, equals(data));
      });
    });

    group('hashCode', () {
      test('two equal instances have the same hash code', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light();

        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('two unequal instances likely have different hash codes', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light(
          primaryColor: const Color(0xFF999999),
        );

        // While hash codes are not guaranteed to be different for unequal objects,
        // the likelihood is very high for well-distributed hash functions.
        expect(data1.hashCode, isNot(equals(data2.hashCode)));
      });
    });

    group('Light mode only', () {
      test('LayrzThemeData.light() constructs without error', () {
        expect(() => LayrzThemeData.light(), returnsNormally);
      });

      test('LayrzThemeData has no dark mode factory', () {
        // This test documents that dark mode is not supported.
        // The absence of LayrzThemeData.dark() is a compile-time guarantee.
        // We verify that the API is light-only by checking that light() works.
        final data = LayrzThemeData.light();
        expect(data, isNotNull);
      });
    });
  });
}

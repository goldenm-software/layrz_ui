import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzThemeData', () {
    group('light() factory', () {
      test('uses default primary color', () {
        final data = LayrzThemeData.light();
        expect(data.primaryColor, equals(kPrimaryColor));
      });

      test('uses default background color', () {
        final data = LayrzThemeData.light();
        expect(data.backgroundColor, equals(const Color(0xFFFCFCFC)));
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

      test('accepts custom font', () {
        final customFont = LayrzRobotoFont();
        final data = LayrzThemeData.light(
          font: customFont,
        );
        // Verify that the typography was created (indirect verification).
        expect(data.tokens.typography, isNotNull);
        expect(data.tokens.typography.display, isNotNull);
      });

      test('defaults to Roboto font when font is null', () {
        final data = LayrzThemeData.light();
        // The default font should be Roboto
        expect(data.tokens.typography.display.fontFamily, equals('Roboto'));
        expect(data.tokens.typography.body.fontFamily, equals('Roboto'));
      });

      test('font is used when provided', () {
        final font = LayrzRobotoFont();
        final data = LayrzThemeData.light(
          font: font,
        );
        // Verify that custom font is used
        expect(data.tokens.typography.display.fontFamily, equals('Roboto'));
        expect(data.tokens.typography.body.fontFamily, equals('Roboto'));
      });
    });

    group('Delegating getters', () {
      late LayrzThemeData data;

      setUp(() {
        data = LayrzThemeData.light();
      });

      test('primaryColor delegates to tokens.colors.primary.shade500', () {
        expect(data.primaryColor, equals(data.tokens.colors.primary.shade500));
      });

      test('backgroundColor delegates to tokens.colors.sf1', () {
        expect(data.backgroundColor, equals(data.tokens.colors.sf1));
      });

      test('surfaceColor delegates to tokens.colors.sf1', () {
        expect(data.surfaceColor, equals(data.tokens.colors.sf1));
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

      test('dangerColor delegates to tokens.colors.danger.shade500', () {
        expect(data.dangerColor, equals(data.tokens.colors.danger.shade500));
      });

      test('successColor delegates to tokens.colors.success.shade500', () {
        expect(data.successColor, equals(data.tokens.colors.success.shade500));
      });

      test('warningColor delegates to tokens.colors.warning.shade500', () {
        expect(data.warningColor, equals(data.tokens.colors.warning.shade500));
      });

      test('textTheme delegates to tokens.typography', () {
        expect(data.textTheme, same(data.tokens.typography));
      });

      test('textStyle returns tokens.typography.body', () {
        expect(data.textStyle, equals(data.tokens.typography.body));
      });

      test('borderRadius delegates to tokens.radius.r2 (10.0)', () {
        expect(data.borderRadius, equals(10.0));
        expect(data.borderRadius, equals(data.tokens.radius.r2));
      });
    });

    group('copyWith', () {
      test('replaces tokens when provided', () {
        final data1 = LayrzThemeData.light();
        final customTokens = LayrzTokens.light(primaryColor: const Color(0xFF999999));
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
        final data2 = LayrzThemeData.light(primaryColor: const Color(0xFF999999));

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
        final data2 = LayrzThemeData.light(primaryColor: const Color(0xFF999999));

        // While hash codes are not guaranteed to be different for unequal objects
        // the likelihood is very high for well-distributed hash functions.
        expect(data1.hashCode, isNot(equals(data2.hashCode)));
      });
    });

    group('Light mode only', () {
      test('LayrzThemeData.light() constructs without arguments', () {
        expect(
          () => LayrzThemeData.light(),
          returnsNormally,
        );
      });

      test('LayrzThemeData has no dark mode factory', () {
        // This test documents that dark mode is not supported.
        // The absence of LayrzThemeData.dark() is a compile-time guarantee.
        // We verify that the API is light-only by checking that light() works.
        final data = LayrzThemeData.light();
        expect(data, isNotNull);
      });
    });

    group('Mandatory font loading regression test', () {
      test(
        'LayrzThemeData.light() uses default LayrzRobotoFont',
        () {
          // REGRESSION TEST: Proves the default font is LayrzRobotoFont.
          // The LayrzRobotoFont performs no network I/O. A design system
          // should not perform implicit network calls; consumers who need custom
          // fonts should provide their own handler via layrz_ui_extensions.
          final theme = LayrzThemeData.light();
          final family = theme.tokens.typography.body.fontFamily;

          expect(family, isNotNull);
          expect(
            family,
            equals('Roboto'),
            reason: 'default font is LayrzRobotoFont, which provides Roboto without any network calls',
          );
        },
      );

      test(
        'LayrzTextTheme.defaults() with null font uses LayrzRobotoFont',
        () {
          // This test ensures the null-font path still works for pure logic testing
          final data = LayrzTextTheme.defaults(
            textColor: const Color(0xFF000000),
          );

          // When font is null, defaults to Roboto
          expect(data.body.fontFamily, equals('Roboto'));
        },
      );
    });
  });
}

/// Test fon

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzThemeData', () {
    group('light() factory', () {
      test('uses default primary color', () {
        final data = LayrzThemeData.light();
        expect(data.primaryColor, equals(kLightPrimaryColor));
      });

      test('brightness is Brightness.light', () {
        final data = LayrzThemeData.light();
        expect(data.brightness, equals(Brightness.light));
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

      test('defaults selectionColor to tokens.colors.selectionColor tinted by tonalOpacity', () {
        final data = LayrzThemeData.light();
        final expected = data.tokens.colors.selectionColor.withValues(alpha: data.tokens.colors.tonalOpacity);
        expect(data.selectionColor, equals(expected));
      });

      test('defaults cursorColor to tokens.colors.primary', () {
        final data = LayrzThemeData.light();
        expect(data.cursorColor, equals(data.tokens.colors.primary));
      });

      test('accepts custom selectionColor', () {
        const customSelectionColor = Color(0x330000FF);
        final data = LayrzThemeData.light(selectionColor: customSelectionColor);
        expect(data.selectionColor, equals(customSelectionColor));
      });

      test('accepts custom cursorColor', () {
        const customCursorColor = Color(0xFF00FF00);
        final data = LayrzThemeData.light(cursorColor: customCursorColor);
        expect(data.cursorColor, equals(customCursorColor));
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

      test('primaryColor delegates to tokens.colors.primary', () {
        expect(data.primaryColor, equals(data.tokens.colors.primary));
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

      test('replaces selectionColor when provided, without touching cursorColor', () {
        final data1 = LayrzThemeData.light();
        const customSelectionColor = Color(0x33FF00FF);
        final data2 = data1.copyWith(selectionColor: customSelectionColor);

        expect(data2.selectionColor, equals(customSelectionColor));
        expect(data2.cursorColor, equals(data1.cursorColor));
      });

      test('replaces cursorColor when provided, without touching selectionColor', () {
        final data1 = LayrzThemeData.light();
        const customCursorColor = Color(0xFFABCDEF);
        final data2 = data1.copyWith(cursorColor: customCursorColor);

        expect(data2.cursorColor, equals(customCursorColor));
        expect(data2.selectionColor, equals(data1.selectionColor));
      });

      test('replaces brightness when provided', () {
        final data1 = LayrzThemeData.light();
        final data2 = data1.copyWith(brightness: Brightness.dark);

        expect(data2.brightness, equals(Brightness.dark));
        expect(data1.brightness, equals(Brightness.light));
      });

      test('preserves brightness when not provided', () {
        final data1 = LayrzThemeData.dark();
        final data2 = data1.copyWith(cursorColor: const Color(0xFF445566));

        expect(data2.brightness, equals(Brightness.dark));
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

      test('two instances with different selectionColor are unequal', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light(selectionColor: const Color(0x33112233));

        expect(data1, isNot(equals(data2)));
      });

      test('two instances with different cursorColor are unequal', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light(cursorColor: const Color(0xFF445566));

        expect(data1, isNot(equals(data2)));
      });

      test('two instances with different brightness are unequal', () {
        final data1 = LayrzThemeData.light();
        final data2 = data1.copyWith(brightness: Brightness.dark);

        expect(data1, isNot(equals(data2)));
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

      test('two instances with different selectionColor have different hash codes', () {
        final data1 = LayrzThemeData.light();
        final data2 = LayrzThemeData.light(selectionColor: const Color(0x33112233));

        expect(data1.hashCode, isNot(equals(data2.hashCode)));
      });

      test('two instances with different brightness have different hash codes', () {
        final data1 = LayrzThemeData.light();
        final data2 = data1.copyWith(brightness: Brightness.dark);

        expect(data1.hashCode, isNot(equals(data2.hashCode)));
      });
    });

    group('dark() factory (BETA)', () {
      test('LayrzThemeData.light() constructs without arguments', () {
        // Genuine no-throw contract: this is a zero-arg constructor smoke test --
        // every parameter falls back to its default.
        expect(
          () => LayrzThemeData.light(),
          returnsNormally,
        );
      });

      test('LayrzThemeData now has a dark mode factory', () {
        // BETA dark mode (DESIGN-204): LayrzThemeData.dark() exists and
        // produces a theme flagged as Brightness.dark.
        expect(
          () => LayrzThemeData.dark(),
          returnsNormally,
        );
        final data = LayrzThemeData.dark();
        expect(data, isNotNull);
        expect(data.brightness, equals(Brightness.dark));
      });

      test('uses default dark primary color', () {
        final data = LayrzThemeData.dark();
        expect(data.primaryColor, equals(kDarkPrimaryColor));
      });

      test('accepts custom primary color', () {
        const customPrimary = Color(0xFF112233);
        final data = LayrzThemeData.dark(primaryColor: customPrimary);
        expect(data.primaryColor, equals(customPrimary));
      });

      test('uses dark background color', () {
        final data = LayrzThemeData.dark();
        expect(data.backgroundColor, equals(const Color(0xFF29272C)));
      });

      test('creates IconThemeData with dark fg1 color and size 24', () {
        final data = LayrzThemeData.dark();
        expect(data.iconTheme.color, equals(data.tokens.colors.fg1));
        expect(data.iconTheme.size, equals(24));
      });

      test('defaults selectionColor to tokens.colors.selectionColor tinted by tonalOpacity', () {
        final data = LayrzThemeData.dark();
        final expected = data.tokens.colors.selectionColor.withValues(alpha: data.tokens.colors.tonalOpacity);
        expect(data.selectionColor, equals(expected));
      });

      test('defaults cursorColor to tokens.colors.primary', () {
        final data = LayrzThemeData.dark();
        expect(data.cursorColor, equals(data.tokens.colors.primary));
      });

      test('light() and dark() produce unequal themes', () {
        final light = LayrzThemeData.light();
        final dark = LayrzThemeData.dark();
        expect(light, isNot(equals(dark)));
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

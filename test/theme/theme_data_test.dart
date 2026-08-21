import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzThemeData', () {
    group('light() factory', () {
      test('uses default primary color', () {
        final data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        expect(data.primaryColor, equals(kPrimaryColor));
      });

      test('uses default background color', () {
        final data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        expect(data.backgroundColor, equals(const Color(0xFFFCFCFC)));
      });

      test('accepts custom primary color', () {
        const customPrimary = Color(0xFF112233);
        final data = LayrzThemeData.light(
          primaryColor: customPrimary,
          fontHandler: const FakeFontHandler(),
        );
        expect(data.primaryColor, equals(customPrimary));
      });

      test('creates IconThemeData with fg1 color and size 24', () {
        final data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
          fontHandler: const FakeFontHandler(),
        );
        // Verify that the typography was created (indirect verification).
        expect(data.tokens.typography, isNotNull);
        expect(data.tokens.typography.display, isNotNull);
      });

      test('wraps fontName into Google Font when titleFont and bodyFont are null', () {
        final data = LayrzThemeData.light(
          fontName: 'Roboto',
          fontHandler: const FakeFontHandler(),
        );
        // The fake handler returns font names directly, so both should be 'Roboto'
        expect(data.tokens.typography.display.fontFamily, equals('Roboto'));
        expect(data.tokens.typography.body.fontFamily, equals('Roboto'));
      });

      test('titleFont and bodyFont override fontName when provided', () {
        final titleFont = LayrzFont(
          source: LayrzFontSource.local,
          name: 'CustomTitle',
        );
        final bodyFont = LayrzFont(
          source: LayrzFontSource.local,
          name: 'CustomBody',
        );
        final data = LayrzThemeData.light(
          fontName: 'Roboto',
          titleFont: titleFont,
          bodyFont: bodyFont,
          fontHandler: const FakeFontHandler(),
        );
        // Verify that custom fonts are used, not the fontName
        expect(data.tokens.typography.display.fontFamily, equals('CustomTitle'));
        expect(data.tokens.typography.body.fontFamily, equals('CustomBody'));
      });

      test('defaults to Open Sans font name', () {
        final data = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
        );
        // Default font should be Open Sans
        expect(data.tokens.typography.display.fontFamily, equals('Open Sans'));
        expect(data.tokens.typography.body.fontFamily, equals('Open Sans'));
      });
    });

    group('Delegating getters', () {
      late LayrzThemeData data;

      setUp(() {
        data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      });

      test('primaryColor delegates to tokens.colors.primary.shade500', () {
        expect(data.primaryColor, equals(data.tokens.colors.primary.shade500));
      });

      test('backgroundColor delegates to tokens.colors.sf1', () {
        expect(data.backgroundColor, equals(data.tokens.colors.sf1));
      });

      test('surfaceColor delegates to tokens.colors.sf2', () {
        expect(data.surfaceColor, equals(data.tokens.colors.sf2));
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
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final customTokens = LayrzTokens.light(
          primaryColor: const Color(0xFF999999),
          fontHandler: const FakeFontHandler(),
        );
        final data2 = data1.copyWith(tokens: customTokens);

        expect(data2.tokens, same(customTokens));
        expect(data1.tokens, isNot(same(customTokens)));
      });

      test('replaces iconTheme when provided', () {
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        const customIconTheme = IconThemeData(
          color: Color(0xFF555555),
          size: 32,
        );
        final data2 = data1.copyWith(iconTheme: customIconTheme);

        expect(data2.iconTheme, equals(customIconTheme));
        expect(data1.iconTheme, isNot(equals(customIconTheme)));
      });

      test('preserves fields not in copyWith arguments', () {
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final data2 = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        expect(data1, equals(data2));
      });

      test('two instances with different primary colors are unequal', () {
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final data2 = LayrzThemeData.light(
          primaryColor: const Color(0xFF999999),
          fontHandler: const FakeFontHandler(),
        );

        expect(data1, isNot(equals(data2)));
      });

      test('identical instances are equal', () {
        final data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        expect(data, equals(data));
      });
    });

    group('hashCode', () {
      test('two equal instances have the same hash code', () {
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final data2 = LayrzThemeData.light(fontHandler: const FakeFontHandler());

        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('two unequal instances likely have different hash codes', () {
        final data1 = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        final data2 = LayrzThemeData.light(
          primaryColor: const Color(0xFF999999),
          fontHandler: const FakeFontHandler(),
        );

        // While hash codes are not guaranteed to be different for unequal objects,
        // the likelihood is very high for well-distributed hash functions.
        expect(data1.hashCode, isNot(equals(data2.hashCode)));
      });
    });

    group('Light mode only', () {
      test('LayrzThemeData.light() constructs with fake handler', () {
        expect(
          () => LayrzThemeData.light(fontHandler: const FakeFontHandler()),
          returnsNormally,
        );
      });

      test('LayrzThemeData has no dark mode factory', () {
        // This test documents that dark mode is not supported.
        // The absence of LayrzThemeData.dark() is a compile-time guarantee.
        // We verify that the API is light-only by checking that light() works.
        final data = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        expect(data, isNotNull);
      });
    });

    group('preloadFont static method', () {
      test('delegates to fontHandler.preload with correct font', () async {
        var preloadCalled = false;
        String? preloadedFontName;

        final testHandler = _TestFontHandler(
          onPreload: (font) {
            preloadCalled = true;
            preloadedFontName = font.name;
          },
        );

        await LayrzThemeData.preloadFont('My Font', testHandler);

        expect(preloadCalled, isTrue);
        expect(preloadedFontName, equals('My Font'));
      });

      test('preloadFont defaults to Open Sans', () async {
        var preloadedFontName = '';

        final testHandler = _TestFontHandler(
          onPreload: (font) {
            preloadedFontName = font.name;
          },
        );

        await LayrzThemeData.preloadFont(kLayrzFontName, testHandler);

        expect(preloadedFontName, equals('Open Sans'));
      });
    });

    group('Mandatory font loading regression test', () {
      test(
        'LayrzThemeData.light() with no arguments uses default GoogleFontsHandler',
        () {
          // REGRESSION TEST: Proves mandatory font loading guarantee.
          // If fontHandler default is ever reverted to null, this test fails.
          // GoogleFonts.getFont() returns a resolved family name synchronously
          // (e.g. 'OpenSans-Regular' instead of raw 'Open Sans'), so the family
          // here should NOT be the raw name. Offline-safe because the sync
          // constructor completes; only async byte fetch happens later.
          final theme = LayrzThemeData.light();
          final family = theme.tokens.typography.body.fontFamily;

          expect(family, isNotNull);
          expect(
            family,
            isNot(equals('Open Sans')),
            reason:
                'fontHandler must resolve the family; raw "Open Sans" '
                'means no resolution happened (default reverted to null)',
          );
        },
      );

      test('LayrzThemeData.light() with explicit handler uses that handler', () {
        var resolveCalled = false;

        final testHandler = _TestFontHandler(
          onResolveFamily: (font) {
            resolveCalled = true;
            return font.name;
          },
        );

        final data = LayrzThemeData.light(fontHandler: testHandler);

        // Verify that the handler was used to resolve fonts
        expect(resolveCalled, isTrue);
        expect(data.tokens.typography.body, isNotNull);
      });

      test(
        'LayrzTextTheme.defaults() with null handler uses raw font name',
        () {
          // This test ensures the null-handler path still works for pure logic testing
          final data = LayrzTextTheme.defaults(
            textColor: const Color(0xFF000000),
            fontHandler: null,
          );

          // When fontHandler is null, font name is used directly
          expect(data.body.fontFamily, equals('Open Sans'));
        },
      );
    });
  });
}

/// Test fake handler that records method calls for verification.
class _TestFontHandler implements LayrzFontHandler {
  final void Function(LayrzFont)? onPreload;
  final String Function(LayrzFont)? onResolveFamily;

  _TestFontHandler({this.onPreload, this.onResolveFamily});

  @override
  Future<void> preload(LayrzFont font) async {
    onPreload?.call(font);
  }

  @override
  String resolveFamily(LayrzFont font) {
    return onResolveFamily?.call(font) ?? font.name;
  }

  @override
  String resolveFamilyForWeight(LayrzFont font, FontWeight weight) {
    return onResolveFamily?.call(font) ?? font.name;
  }

  @override
  List<String> get fallbacks => kLayrzFontFallbacks;
}

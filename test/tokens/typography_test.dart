import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/fonts.dart';
import 'package:layrz_ui/tokens.dart';

void main() {
  group('LayrzTextTheme', () {
    test('defaults factory applies textColor to all styles', () {
      const testColor = Color(0xFF123456);
      final theme = LayrzTextTheme.defaults(textColor: testColor);

      expect(theme.display.color, equals(testColor));
      expect(theme.headline.color, equals(testColor));
      expect(theme.title.color, equals(testColor));
      expect(theme.body.color, equals(testColor));
      expect(theme.label.color, equals(testColor));
    });

    test('defaults factory uses correct font sizes', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.fontSize, equals(45));
      expect(theme.headline.fontSize, equals(28));
      expect(theme.title.fontSize, equals(16));
      expect(theme.body.fontSize, equals(14));
      expect(theme.label.fontSize, equals(12));
    });

    test('defaults factory uses correct font weights', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.fontWeight, equals(FontWeight.w800));
      expect(theme.headline.fontWeight, equals(FontWeight.w700));
      expect(theme.title.fontWeight, equals(FontWeight.w500));
      expect(theme.body.fontWeight, equals(FontWeight.w300));
      expect(theme.label.fontWeight, equals(FontWeight.w100));
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

      expect(theme.display.fontFamily, equals('Open Sans'));
      expect(theme.body.fontFamily, equals('Roboto'));
      expect(theme.display.fontFamilyFallback, equals(kLayrzFontFallbacks));
    });

    test('all styles have overflow ellipsis', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.overflow, equals(TextOverflow.ellipsis));
      expect(theme.body.overflow, equals(TextOverflow.ellipsis));
      expect(theme.label.overflow, equals(TextOverflow.ellipsis));
    });

    test('all styles have no text decoration', () {
      final theme = LayrzTextTheme.defaults(textColor: const Color(0xFF000000));

      expect(theme.display.decoration, equals(TextDecoration.none));
      expect(theme.body.decoration, equals(TextDecoration.none));
      expect(theme.label.decoration, equals(TextDecoration.none));
    });

    test('copyWith creates new instance with replaced styles', () {
      final original = LayrzTextTheme.defaults(
        textColor: const Color(0xFF000000),
      );
      final newBody = original.body.copyWith(fontSize: 20);
      final modified = original.copyWith(body: newBody);

      expect(modified.body.fontSize, equals(20));
      expect(modified.display, equals(original.display));
      expect(original.body.fontSize, equals(14)); // original unchanged
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

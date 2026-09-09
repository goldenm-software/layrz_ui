import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

void main() {
  group('LayrzCodeThemeExtension.dark', () {
    const theme = LayrzCodeThemeExtension.dark();

    test('has the expected default surface colors', () {
      expect(theme.background, const Color(0xFF1A1A1A));
      expect(theme.foreground, const Color(0xFFECF0F1));
    });

    test('has the expected default syntax colors', () {
      expect(theme.function, const Color(0xFF3498DB));
      expect(theme.string, const Color(0xFFF1C40F));
      expect(theme.number, const Color(0xFF2ECC71));
      expect(theme.constant, const Color(0xFFE67E22));
    });

    test('has the expected default error color', () {
      expect(theme.errorColor, const Color(0xFFE74C3C));
    });
  });

  group('LayrzCodeThemeExtension.copyWith', () {
    test('replaces only the given field and preserves the rest', () {
      const original = LayrzCodeThemeExtension.dark();
      final copy = original.copyWith(string: const Color(0xFF000000));

      expect(copy.string, const Color(0xFF000000));
      expect(copy.background, original.background);
      expect(copy.foreground, original.foreground);
      expect(copy.function, original.function);
      expect(copy.keyword, original.keyword);
    });

    test('with no arguments returns an equal instance', () {
      const original = LayrzCodeThemeExtension.dark();
      final copy = original.copyWith();

      expect(copy, equals(original));
    });
  });

  group('LayrzCodeThemeExtension.lerp', () {
    const from = LayrzCodeThemeExtension.dark();
    const to = LayrzCodeThemeExtension(
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF000000),
      gutterBackground: Color(0xFFFFFFFF),
      gutterForeground: Color(0xFF000000),
      currentLineBackground: Color(0xFFFFFFFF),
      errorColor: Color(0xFFFFFFFF),
      keyword: Color(0xFFFFFFFF),
      builtin: Color(0xFFFFFFFF),
      function: Color(0xFFFFFFFF),
      string: Color(0xFFFFFFFF),
      number: Color(0xFFFFFFFF),
      comment: Color(0xFFFFFFFF),
      constant: Color(0xFFFFFFFF),
      decorator: Color(0xFFFFFFFF),
      variable: Color(0xFFFFFFFF),
    );

    test('returns this unmodified when other is null', () {
      expect(from.lerp(null, 0.5), same(from));
    });

    test('at t=0 matches the starting colors', () {
      final result = from.lerp(to, 0);

      expect(result.background, from.background);
      expect(result.function, from.function);
      expect(result.string, from.string);
    });

    test('at t=1 matches the other palette colors', () {
      final result = from.lerp(to, 1);

      expect(result, equals(to));
    });
  });

  group('LayrzCodeThemeExtension.colorForScope', () {
    const theme = LayrzCodeThemeExtension.dark();

    test('maps text to foreground', () {
      expect(theme.colorForScope(LayrzHighlightScope.text), theme.foreground);
    });

    test('maps every non-text scope to its like-named field', () {
      expect(theme.colorForScope(LayrzHighlightScope.keyword), theme.keyword);
      expect(theme.colorForScope(LayrzHighlightScope.builtin), theme.builtin);
      expect(theme.colorForScope(LayrzHighlightScope.function), theme.function);
      expect(theme.colorForScope(LayrzHighlightScope.string), theme.string);
      expect(theme.colorForScope(LayrzHighlightScope.number), theme.number);
      expect(theme.colorForScope(LayrzHighlightScope.comment), theme.comment);
      expect(theme.colorForScope(LayrzHighlightScope.constant), theme.constant);
      expect(theme.colorForScope(LayrzHighlightScope.decorator), theme.decorator);
      expect(theme.colorForScope(LayrzHighlightScope.variable), theme.variable);
    });
  });

  group('LayrzCodeThemeExtension.styleForScope', () {
    const theme = LayrzCodeThemeExtension.dark();

    test('function scope is bold via fontVariations wght 700, not fontWeight', () {
      final style = theme.styleForScope(LayrzHighlightScope.function, fontSize: 14);

      expect(style.fontVariations, isNotNull);
      expect(
        style.fontVariations!.any((v) => v.axis == 'wght' && v.value == 700),
        isTrue,
        reason: 'expected a wght=700 FontVariation for the bold function scope',
      );
      expect(style.color, theme.function);
      expect(style.fontSize, 14);
    });

    test('non-bold scopes use body weight (wght 400)', () {
      final style = theme.styleForScope(LayrzHighlightScope.keyword, fontSize: 14);

      expect(
        style.fontVariations!.any((v) => v.axis == 'wght' && v.value == 400),
        isTrue,
      );
    });

    test('string scope resolves the string color and requested font size', () {
      final style = theme.styleForScope(LayrzHighlightScope.string, fontSize: 14);

      expect(style.color, theme.string);
      expect(style.fontSize, 14);
    });

    test('text scope resolves the foreground color', () {
      final style = theme.styleForScope(LayrzHighlightScope.text, fontSize: 12);

      expect(style.color, theme.foreground);
      expect(style.fontSize, 12);
    });
  });

  group('LayrzCodeThemeExtension.resolveStyles', () {
    const theme = LayrzCodeThemeExtension.dark();

    test('covers every LayrzHighlightScope value', () {
      final styles = theme.resolveStyles(fontSize: 14);

      expect(styles.length, LayrzHighlightScope.values.length);
      for (final scope in LayrzHighlightScope.values) {
        expect(styles.containsKey(scope), isTrue, reason: 'missing style for $scope');
      }
    });

    test('matches styleForScope for each scope', () {
      final styles = theme.resolveStyles(fontSize: 16);

      for (final scope in LayrzHighlightScope.values) {
        expect(styles[scope], theme.styleForScope(scope, fontSize: 16));
      }
    });
  });

  group('LayrzCodeThemeExtension equality', () {
    test('equal instances compare equal and share a hashCode', () {
      const a = LayrzCodeThemeExtension.dark();
      const b = LayrzCodeThemeExtension.dark();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing in a single field makes instances unequal', () {
      const a = LayrzCodeThemeExtension.dark();
      final b = a.copyWith(comment: const Color(0xFF123456));

      expect(a, isNot(equals(b)));
    });
  });
}

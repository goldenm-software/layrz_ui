import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/code/src/code_snippet.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCodeThemeExtension.styleForScope — forcePlainWhiteText', () {
    test('forces text scope color to pure white when forcePlainWhiteText is true', () {
      const codeTheme = LayrzCodeThemeExtension.dark();

      final forced = codeTheme.styleForScope(LayrzHighlightScope.text, fontSize: 14, forcePlainWhiteText: true);
      expect(forced.color, const Color(0xFFFFFFFF));
    });

    test('leaves text scope color at the normal foreground when forcePlainWhiteText is false (default)', () {
      const codeTheme = LayrzCodeThemeExtension.dark();

      final normal = codeTheme.styleForScope(LayrzHighlightScope.text, fontSize: 14);
      expect(normal.color, codeTheme.foreground);
      expect(normal.color, isNot(const Color(0xFFFFFFFF)));
    });

    test('forcePlainWhiteText does not affect a non-text scope (e.g. keyword stays its own color)', () {
      const codeTheme = LayrzCodeThemeExtension.dark();

      final forced = codeTheme.styleForScope(LayrzHighlightScope.keyword, fontSize: 14, forcePlainWhiteText: true);
      expect(forced.color, codeTheme.keyword);
      expect(forced.color, isNot(const Color(0xFFFFFFFF)));
    });

    test('resolveStyles applies forcePlainWhiteText only to the text scope entry', () {
      const codeTheme = LayrzCodeThemeExtension.dark();

      final styles = codeTheme.resolveStyles(fontSize: 14, forcePlainWhiteText: true);
      expect(styles[LayrzHighlightScope.text]!.color, const Color(0xFFFFFFFF));
      expect(styles[LayrzHighlightScope.keyword]!.color, codeTheme.keyword);
      expect(styles[LayrzHighlightScope.string]!.color, codeTheme.string);
    });

    test('resolveStyles without forcePlainWhiteText reproduces the original per-scope colors', () {
      const codeTheme = LayrzCodeThemeExtension.dark();

      final styles = codeTheme.resolveStyles(fontSize: 14);
      expect(styles[LayrzHighlightScope.text]!.color, codeTheme.foreground);
    });
  });

  group('LayrzCodeSnippet — plain language renders white text, python does not', () {
    testWidgets('a plain-language snippet resolves its text-scope color to white', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: 'just plain unhighlighted text', language: LayrzCodeLanguage.plain),
      );

      const codeTheme = LayrzCodeThemeExtension.dark();
      final expectedPlainStyle = codeTheme.styleForScope(
        LayrzHighlightScope.text,
        fontSize: 14,
        forcePlainWhiteText: true,
      );

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final rootStyle = richText.text.style;
      expect(rootStyle?.color, expectedPlainStyle.color);
      expect(rootStyle?.color, const Color(0xFFFFFFFF));
    });

    testWidgets('a python snippet does NOT resolve its text-scope color to white', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        const LayrzCodeSnippet(code: 'plain surrounding text around code', language: LayrzCodeLanguage.python),
      );

      const codeTheme = LayrzCodeThemeExtension.dark();

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final rootStyle = richText.text.style;
      expect(rootStyle?.color, codeTheme.foreground);
      expect(rootStyle?.color, isNot(const Color(0xFFFFFFFF)));
    });
  });
}

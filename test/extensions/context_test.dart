import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/extensions/extensions.dart';
import 'package:layrz_ui/theme/theme.dart';
import 'package:layrz_ui/tokenizer/tokenizer.dart';
import 'package:layrz_ui/tokens/tokens.dart';

void main() {
  group('LayrzContextExtensions', () {
    testWidgets('theme returns the injected LayrzThemeData', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzThemeData resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.theme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, same(themeData));
    });

    testWidgets('tokens returns theme.tokens', (tester) async {
      final themeData = LayrzThemeData.light();
      late LayrzTokens resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.tokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, same(themeData.tokens));
    });

    testWidgets('tokenizer returns a LayrzTokenizer wrapping theme.tokens', (
      tester,
    ) async {
      final themeData = LayrzThemeData.light();
      late LayrzTokenizer resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.tokenizer;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.tokens, same(themeData.tokens));
    });

    testWidgets('primaryColor returns theme.primaryColor', (tester) async {
      const customColor = Color(0xFF112233);
      final themeData = LayrzThemeData.light(primaryColor: customColor);
      late Color resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.primaryColor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(customColor));
    });

    testWidgets('titleStyle is 18pt bold text style', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.titleStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.fontSize, equals(18));
      expect(resolved.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('subtitleStyle is 16pt bold text style', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.subtitleStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.fontSize, equals(16));
      expect(resolved.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('bodyStyle returns theme.textStyle', (tester) async {
      final themeData = LayrzThemeData.light();
      late TextStyle resolved;

      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              resolved = context.bodyStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, equals(themeData.textStyle));
    });
  });
}

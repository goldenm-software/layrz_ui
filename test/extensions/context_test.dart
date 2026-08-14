import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/extensions/extensions.dart';
import 'package:layrz_ui/theme/theme.dart';
import 'package:layrz_ui/tokenizer/tokenizer.dart';
import 'package:layrz_ui/tokens/tokens.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzContextExtensions', () {
    testWidgets('theme returns the injected LayrzThemeData', (tester) async {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
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

    testWidgets(
      'themeExtension<T>() returns registered extension',
      (tester) async {
        final ext = _TestContextExtension(value: 'test');
        final themeData = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [ext],
        );
        late _TestContextExtension resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.themeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, same(ext));
        expect(resolved.value, equals('test'));
      },
    );

    testWidgets(
      'maybeThemeExtension<T>() returns null when not registered',
      (tester) async {
        final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
        _TestContextExtension? resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, isNull);
      },
    );

    testWidgets(
      'maybeThemeExtension<T>() returns extension when registered',
      (tester) async {
        final ext = _TestContextExtension(value: 'maybe-test');
        final themeData = LayrzThemeData.light(
          fontHandler: const FakeFontHandler(),
          extensions: [ext],
        );
        late _TestContextExtension? resolved;

        await tester.pumpWidget(
          LayrzTheme(
            data: themeData,
            child: Builder(
              builder: (context) {
                resolved = context.maybeThemeExtension<_TestContextExtension>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, same(ext));
      },
    );
  });
}

/// Concrete extension for testing context accessors.
class _TestContextExtension extends LayrzThemeExtension<_TestContextExtension> {
  /// A simple string value.
  final String value;

  /// Creates a test extension with the given value.
  const _TestContextExtension({required this.value});

  @override
  _TestContextExtension copyWith({String? value}) {
    return _TestContextExtension(value: value ?? this.value);
  }

  @override
  _TestContextExtension lerp(covariant _TestContextExtension? other, double t) {
    if (other is! _TestContextExtension) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

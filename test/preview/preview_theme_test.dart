import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/preview.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzPreviewTheme', () {
    test('light() returns a LayrzPreviewTheme with light-theme tokens', () {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;

      expect(previewTheme, isA<LayrzPreviewTheme>());
      expect(previewTheme.data, isA<LayrzThemeData>());

      // Verify the theme data contains light-mode tokens
      expect(previewTheme.data.backgroundColor, isNotNull);
      expect(previewTheme.data.primaryColor, isNotNull);
      expect(previewTheme.data.textStyle, isNotNull);
      expect(previewTheme.data.iconTheme, isNotNull);
    });

    testWidgets('apply() makes LayrzTheme.of(context) resolve successfully', (
      WidgetTester tester,
    ) async {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;
      late LayrzThemeData resolvedTheme;

      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return previewTheme.apply(
              context,
              Builder(
                builder: (innerContext) {
                  resolvedTheme = LayrzTheme.of(innerContext);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(testWidget);

      expect(resolvedTheme, isNotNull);
      expect(resolvedTheme, equals(previewTheme.data));
    });

    testWidgets('apply() installs correct DefaultTextStyle', (
      WidgetTester tester,
    ) async {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;
      late TextStyle resolvedStyle;

      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return previewTheme.apply(
              context,
              Builder(
                builder: (innerContext) {
                  resolvedStyle = DefaultTextStyle.of(innerContext).style;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(testWidget);

      expect(resolvedStyle, equals(previewTheme.data.textStyle));
    });

    testWidgets('apply() installs correct IconTheme', (
      WidgetTester tester,
    ) async {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;
      late IconThemeData resolvedIconTheme;

      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return previewTheme.apply(
              context,
              Builder(
                builder: (innerContext) {
                  resolvedIconTheme = IconTheme.of(innerContext);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      await tester.pumpWidget(testWidget);

      expect(resolvedIconTheme.color, equals(previewTheme.data.iconTheme.color));
      expect(resolvedIconTheme.size, equals(previewTheme.data.iconTheme.size));
    });

    testWidgets('apply() paints the correct background colour', (
      WidgetTester tester,
    ) async {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;

      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Builder(
            builder: (context) {
              return previewTheme.apply(
                context,
                const SizedBox(width: 100, height: 100),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Find the ColoredBox and verify its color
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == previewTheme.data.backgroundColor,
        ),
        findsWidgets,
        reason: 'The background ColoredBox should use the theme data\'s backgroundColor',
      );
    });

    testWidgets('apply() nesting order matches LayrzApp._wrapWithTheme', (
      WidgetTester tester,
    ) async {
      final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;
      final child = const SizedBox();

      final testWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            final applied = previewTheme.apply(context, child);

            // Verify the nesting order: LayrzTheme > DefaultTextStyle > IconTheme > ColoredBox > child
            expect(applied, isA<LayrzTheme>());

            final layrzTheme = applied as LayrzTheme;
            expect(layrzTheme.child, isA<DefaultTextStyle>());

            final defaultTextStyle = layrzTheme.child as DefaultTextStyle;
            expect(defaultTextStyle.child, isA<IconTheme>());

            final iconTheme = defaultTextStyle.child as IconTheme;
            expect(iconTheme.child, isA<ColoredBox>());

            final coloredBox = iconTheme.child as ColoredBox;
            expect(coloredBox.child, same(child));

            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(testWidget);
    });

    test('light is assignable to PreviewTheme typedef', () {
      // This test verifies that LayrzPreviewTheme.light is a valid tear-off
      // for the PreviewTheme typedef (a zero-arg function returning PreviewThemeData).
      // At compile time, if the signature is wrong, this will fail to compile.
      const PreviewTheme fn = LayrzPreviewTheme.light;
      final result = fn();

      expect(result, isA<PreviewThemeData>());
      expect(result, isA<LayrzPreviewTheme>());
    });

    test('constructor is const-evaluable with LayrzThemeData', () {
      // Verify that the constructor can be used with a real LayrzThemeData
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      final theme = LayrzPreviewTheme(data: themeData);

      expect(theme, isNotNull);
      expect(theme.data, same(themeData));
    });

    testWidgets(
      'theme applied via apply() provides full token access',
      (WidgetTester tester) async {
        final previewTheme = LayrzPreviewTheme.light() as LayrzPreviewTheme;

        final testWidget = Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              return previewTheme.apply(
                context,
                Builder(
                  builder: (innerContext) {
                    final tokens = LayrzTheme.of(innerContext).tokens;
                    expect(tokens.spacing.sp4, isNotNull);
                    expect(tokens.colors.primary, isNotNull);
                    expect(tokens.radius.base, isNotNull);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        );

        await tester.pumpWidget(testWidget);
      },
    );

    test('data field holds the provided LayrzThemeData', () {
      final themeData = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      final previewTheme = LayrzPreviewTheme(data: themeData);

      expect(previewTheme.data, same(themeData));
    });
  });
}

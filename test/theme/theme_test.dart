import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTheme', () {
    testWidgets('of() returns the injected data', (WidgetTester tester) async {
      final data = LayrzThemeData.light();
      late LayrzThemeData resolvedData;

      final widget = LayrzTheme(
        data: data,
        child: Builder(
          builder: (context) {
            resolvedData = LayrzTheme.of(context);
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );

      expect(resolvedData, same(data));
    });

    testWidgets('maybeOf() returns null with no ancestor', (
      WidgetTester tester,
    ) async {
      LayrzThemeData? resolvedData;

      final widget = Builder(
        builder: (context) {
          resolvedData = LayrzTheme.maybeOf(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );

      expect(resolvedData, isNull);
    });

    testWidgets('maybeOf() returns the data when ancestor exists', (
      WidgetTester tester,
    ) async {
      final data = LayrzThemeData.light();
      late LayrzThemeData? resolvedData;

      final widget = LayrzTheme(
        data: data,
        child: Builder(
          builder: (context) {
            resolvedData = LayrzTheme.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );

      expect(resolvedData, same(data));
    });

    test('updateShouldNotify is true for differing data', () {
      final data1 = LayrzThemeData.light();
      final data2 = LayrzThemeData.light(primaryColor: const Color(0xFF888888));

      final widget1 = LayrzTheme(data: data1, child: const SizedBox());
      final widget2 = LayrzTheme(data: data2, child: const SizedBox());

      expect(widget1.updateShouldNotify(widget2), isTrue);
    });

    test('updateShouldNotify is false for equal data', () {
      final data = LayrzThemeData.light();

      final widget1 = LayrzTheme(data: data, child: const SizedBox());
      final widget2 = LayrzTheme(data: data, child: const SizedBox());

      expect(widget1.updateShouldNotify(widget2), isFalse);
    });

    testWidgets(
      'LayrzTheme survives an Overlay boundary via InheritedTheme.wrap()',
      (WidgetTester tester) async {
        final themeData = LayrzThemeData.light();
        LayrzThemeData? resolvedInOverlay;

        final widget = LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              return Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (overlayContext) {
                      // Try to resolve the theme inside the overlay entry.
                      resolvedInOverlay = LayrzTheme.maybeOf(overlayContext);
                      return const SizedBox();
                    },
                  ),
                ],
              );
            },
          ),
        );

        await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: widget),
        );

        // The overlay entry should be able to resolve the theme via InheritedTheme.wrap().
        expect(
          resolvedInOverlay,
          isNotNull,
          reason: 'LayrzTheme should survive Overlay boundary via InheritedTheme.wrap()',
        );
        expect(resolvedInOverlay, same(themeData));
      },
    );

    testWidgets('wrap() returns a LayrzTheme wrapping the child', (
      WidgetTester tester,
    ) async {
      final themeData = LayrzThemeData.light();
      final childWidget = const SizedBox();

      final theme = LayrzTheme(data: themeData, child: childWidget);

      // Test wrap() by calling it with a dummy context (wrap doesn't use it).
      late BuildContext dummyContext;
      await tester.pumpWidget(
        LayrzTheme(
          data: themeData,
          child: Builder(
            builder: (context) {
              dummyContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final wrapped = theme.wrap(dummyContext, childWidget);

      expect(wrapped, isA<LayrzTheme>());
      expect((wrapped as LayrzTheme).data, same(themeData));
    });
  });
}

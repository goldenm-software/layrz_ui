import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzApp themeMode (BETA dark mode)', () {
    testWidgets('LayrzThemeMode.dark makes context.isDark true and uses the dark background', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool resolvedIsDark;
      late Color resolvedBackground;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          themeMode: LayrzThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              resolvedBackground = context.tokens.colors.sf1;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isTrue);
      expect(resolvedBackground, equals(const Color(0xFF12141C)));
    });

    testWidgets('LayrzThemeMode.light makes context.isDark false and uses the light background', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool resolvedIsDark;
      late Color resolvedBackground;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          themeMode: LayrzThemeMode.light,
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              resolvedBackground = context.tokens.colors.sf1;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isFalse);
      expect(resolvedBackground, equals(const Color(0xFFFCFCFC)));
    });

    testWidgets('LayrzThemeMode.system chooses dark when platformBrightness is dark', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: LayrzApp(
            title: 'Test App',
            home: Builder(
              builder: (context) {
                resolvedIsDark = context.isDark;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolvedIsDark, isTrue);
    });

    testWidgets('LayrzThemeMode.system chooses light when platformBrightness is light', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: LayrzApp(
            title: 'Test App',
            home: Builder(
              builder: (context) {
                resolvedIsDark = context.isDark;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolvedIsDark, isFalse);
    });

    testWidgets('themeMode defaults to LayrzThemeMode.system', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const app = LayrzApp(title: 'Test App', home: SizedBox.shrink());
      expect(app.themeMode, equals(LayrzThemeMode.system));
    });

    testWidgets('a custom darkTheme is used when themeMode is dark', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final customDarkTheme = LayrzThemeData.dark(primaryColor: const Color(0xFF00FF00));
      late Color resolvedPrimary;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          themeMode: LayrzThemeMode.dark,
          darkTheme: customDarkTheme,
          home: Builder(
            builder: (context) {
              resolvedPrimary = context.tokens.colors.primary;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedPrimary, equals(const Color(0xFF00FF00)));
    });
  });
}

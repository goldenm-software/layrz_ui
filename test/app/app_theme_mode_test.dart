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
      expect(resolvedBackground, equals(const Color(0xFF29272C)));
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

      // `LayrzApp` sits at the ROOT of the tree in real usage — there is no
      // ancestor `MediaQuery` above it, since `WidgetsApp` is what installs
      // one. Driving brightness via `platformBrightnessTestValue` (rather
      // than wrapping in an outer `MediaQuery`, which would mask the bug this
      // test exists to catch) reflects that.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isTrue);
    });

    testWidgets('LayrzThemeMode.system chooses light when platformBrightness is light', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isFalse);
    });

    testWidgets('LayrzThemeMode.dark stays dark regardless of platformBrightness', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Platform reports light, but the explicit `.dark` mode must win.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          themeMode: LayrzThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isTrue);
    });

    testWidgets('LayrzThemeMode.light stays light regardless of platformBrightness', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Platform reports dark, but the explicit `.light` mode must win.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          themeMode: LayrzThemeMode.light,
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isFalse);
    });

    testWidgets('LayrzThemeMode.system live-updates isDark when platformBrightness changes at runtime', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late bool resolvedIsDark;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolvedIsDark = context.isDark;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedIsDark, isFalse);

      // Flip the platform brightness after the first pump and notify the
      // binding, exactly as the real `platformDispatcher` would when the OS
      // setting changes while the app is running.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.binding.handlePlatformBrightnessChanged();
      await tester.pump();

      expect(resolvedIsDark, isTrue);
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

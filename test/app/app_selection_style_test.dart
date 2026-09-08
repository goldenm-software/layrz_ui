import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzApp text-selection style', () {
    testWidgets('installs a DefaultSelectionStyle with the themed selection and cursor colors', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      late DefaultSelectionStyle resolvedStyle;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: Builder(
            builder: (context) {
              resolvedStyle = DefaultSelectionStyle.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final expectedSelectionColor = theme.tokens.colors.selectionColor.shade500.withValues(
        alpha: theme.tokens.colors.tonalOpacity,
      );
      final expectedCursorColor = theme.tokens.colors.primary.shade500;

      // These flow through `LayrzThemeData.selectionColor`/`.cursorColor`, whose
      // `.light()` defaults are computed from `tokens` as asserted above.
      expect(theme.selectionColor, equals(expectedSelectionColor));
      expect(theme.cursorColor, equals(expectedCursorColor));
      expect(resolvedStyle.selectionColor, equals(expectedSelectionColor));
      expect(resolvedStyle.cursorColor, equals(expectedCursorColor));
    });

    testWidgets('a custom LayrzThemeData.selectionColor/cursorColor overrides the defaults app-wide', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const customSelectionColor = Color(0x55AA33CC);
      const customCursorColor = Color(0xFFFF6600);
      final theme = LayrzThemeData.light().copyWith(
        selectionColor: customSelectionColor,
        cursorColor: customCursorColor,
      );
      late DefaultSelectionStyle resolvedStyle;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: Builder(
            builder: (context) {
              resolvedStyle = DefaultSelectionStyle.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Proves themeability: the app-wide DefaultSelectionStyle reflects the
      // overrides, not the aiAccent/primary defaults — this is what makes a
      // future dark theme trivial to wire up.
      expect(resolvedStyle.selectionColor, equals(customSelectionColor));
      expect(resolvedStyle.cursorColor, equals(customCursorColor));
      expect(resolvedStyle.selectionColor, isNot(equals(theme.tokens.colors.selectionColor.shade500)));
      expect(resolvedStyle.cursorColor, isNot(equals(theme.tokens.colors.primary.shade500)));
    });

    testWidgets('a custom theme changes the resolved selection and cursor colors', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light(primaryColor: const Color(0xFF112233));
      late DefaultSelectionStyle resolvedStyle;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: Builder(
            builder: (context) {
              resolvedStyle = DefaultSelectionStyle.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedStyle.cursorColor, equals(theme.tokens.colors.primary.shade500));
      expect(
        resolvedStyle.selectionColor,
        equals(theme.tokens.colors.selectionColor.shade500.withValues(alpha: theme.tokens.colors.tonalOpacity)),
      );
    });

    testWidgets('router path also installs the themed DefaultSelectionStyle', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      late DefaultSelectionStyle resolvedStyle;

      final routerConfig = RouterConfig<Object>(
        routeInformationProvider: _SimpleRouteInformationProvider(),
        routeInformationParser: _SimpleRouteInformationParser(),
        routerDelegate: _SimpleRouterDelegate(
          builder: (context) {
            resolvedStyle = DefaultSelectionStyle.of(context);
            return const Placeholder();
          },
        ),
      );

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Router Test',
          theme: theme,
          routerConfig: routerConfig,
        ),
      );

      expect(
        resolvedStyle.selectionColor,
        equals(theme.tokens.colors.selectionColor.shade500.withValues(alpha: theme.tokens.colors.tonalOpacity)),
      );
      expect(resolvedStyle.cursorColor, equals(theme.tokens.colors.primary.shade500));
    });
  });
}

/// Minimal router delegate for exercising [LayrzApp.router] in isolation.
class _SimpleRouterDelegate extends RouterDelegate<Object> {
  /// Builds the routed content; receives the [BuildContext] so tests can
  /// read ambient inherited state (e.g. [DefaultSelectionStyle]) from below
  /// `_wrapWithTheme`.
  final WidgetBuilder builder;

  final List<VoidCallback> _listeners = [];

  /// Creates a [_SimpleRouterDelegate] with the given content [builder].
  _SimpleRouterDelegate({required this.builder});

  @override
  RouteInformation get currentConfiguration => RouteInformation(uri: Uri.parse('/'));

  @override
  Widget build(BuildContext context) => builder(context);

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  Future<bool> popRoute() async => false;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

/// Minimal route information provider for exercising [LayrzApp.router].
class _SimpleRouteInformationProvider extends RouteInformationProvider {
  final List<VoidCallback> _listeners = [];

  @override
  RouteInformation get value => RouteInformation(uri: Uri.parse('/'));

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

/// Minimal route information parser for exercising [LayrzApp.router].
class _SimpleRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async => routeInformation;

  @override
  RouteInformation restoreRouteInformation(Object configuration) => configuration as RouteInformation;
}

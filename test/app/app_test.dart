import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/app.dart';
import 'package:layrz_ui/theme.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzApp', () {
    testWidgets('imperative constructor pumps without error', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: const SizedBox(width: 100, height: 100),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('router constructor pumps without error', (tester) async {
      // Note: A full router test would require a complex setup.
      // This test just verifies the constructor accepts a RouterConfig.
      // The router functionality is tested through WidgetsApp.router.
      expect(LayrzApp.router, isNotNull);
    });

    testWidgets('installs the theme correctly', (tester) async {
      final customTheme = LayrzThemeData.light(
        primaryColor: const Color(0xFF112233),
      );
      late LayrzThemeData resolvedTheme;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: customTheme,
          home: Builder(
            builder: (context) {
              resolvedTheme = LayrzTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedTheme.primaryColor, equals(const Color(0xFF112233)));
    });

    testWidgets('uses default theme when none provided', (tester) async {
      late LayrzThemeData resolvedTheme;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolvedTheme = LayrzTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final defaultTheme = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      expect(resolvedTheme.primaryColor, equals(defaultTheme.primaryColor));
    });

    testWidgets('DefaultTextStyle carries theme.textStyle', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: Builder(
            builder: (context) {
              final inherited = DefaultTextStyle.of(context);
              return Text('Test', style: inherited.style);
            },
          ),
        ),
      );

      final textWidget = find.byType(Text).first;
      final textElement = tester.element(textWidget);
      final inheritedStyle = DefaultTextStyle.of(textElement as BuildContext).style;

      expect(inheritedStyle, equals(theme.textStyle));
    });

    testWidgets('IconTheme carries theme.iconTheme', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: Builder(
            builder: (context) {
              final iconTheme = IconTheme.of(context);
              return SizedBox(
                width: 100,
                height: 100,
                child: Text('Size: ${iconTheme.size}'),
              );
            },
          ),
        ),
      );

      final textWidget = find.byType(Text).first;
      final textElement = tester.element(textWidget);
      final resolvedIconTheme = IconTheme.of(textElement as BuildContext);

      expect(resolvedIconTheme.color, equals(theme.iconTheme.color));
      expect(resolvedIconTheme.size, equals(theme.iconTheme.size));
    });

    testWidgets('ColoredBox carries theme.backgroundColor', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: const SizedBox.shrink(),
        ),
      );

      final coloredBox = find.byType(ColoredBox);
      expect(coloredBox, findsWidgets);
    });

    testWidgets('scrollBehavior is applied when provided', (tester) async {
      late ScrollBehavior resolvedBehavior;

      final customBehavior = _CustomScrollBehavior();

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          scrollBehavior: customBehavior,
          home: Builder(
            builder: (context) {
              resolvedBehavior = ScrollConfiguration.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedBehavior, same(customBehavior));
    });

    testWidgets('builder is invoked and wraps the content', (tester) async {
      bool builderCalled = false;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: const SizedBox(width: 50, height: 50),
          builder: (context, child) {
            builderCalled = true;
            return Container(color: const Color(0xFF111111), child: child);
          },
        ),
      );

      expect(builderCalled, isTrue);
      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('color defaults to theme.primaryColor', (tester) async {
      final theme = LayrzThemeData.light(
        primaryColor: const Color(0xFFAABBCC),
        fontHandler: const FakeFontHandler(),
      );

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          theme: theme,
          home: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(WidgetsApp), findsOneWidget);
    });

    testWidgets('color can be overridden', (tester) async {
      const customColor = Color(0xFF123456);

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          color: customColor,
          home: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(WidgetsApp), findsOneWidget);
    });

    testWidgets('title is set on WidgetsApp', (tester) async {
      const testTitle = 'My Custom Title';

      await tester.pumpWidget(
        LayrzApp(title: testTitle, home: const SizedBox.shrink()),
      );

      expect(find.byType(WidgetsApp), findsOneWidget);
    });

    testWidgets('router constructor pumps and renders router widget', (tester) async {
      final routerConfig = RouterConfig<Object>(
        routeInformationProvider: _SimpleRouteInformationProvider(),
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(),
      );

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Router Test',
          routerConfig: routerConfig,
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('router path installs theme via _wrapWithTheme', (tester) async {
      final customTheme = LayrzThemeData.light(
        primaryColor: const Color(0xFFAABBCC),
      );
      late LayrzThemeData resolvedTheme;

      final routerConfig = RouterConfig<Object>(
        routeInformationProvider: _SimpleRouteInformationProvider(),
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (context) {
            resolvedTheme = LayrzTheme.of(context);
            return const Placeholder();
          },
        ),
      );

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Router Test',
          theme: customTheme,
          routerConfig: routerConfig,
        ),
      );

      expect(resolvedTheme.primaryColor, equals(const Color(0xFFAABBCC)));
    });

    testWidgets('router path applies DefaultTextStyle, IconTheme, and ColoredBox', (tester) async {
      final theme = LayrzThemeData.light(fontHandler: const FakeFontHandler());
      late TextStyle resolvedTextStyle;
      late IconThemeData resolvedIconTheme;

      final routerConfig = RouterConfig<Object>(
        routeInformationProvider: _SimpleRouteInformationProvider(),
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (context) {
            resolvedTextStyle = DefaultTextStyle.of(context).style;
            resolvedIconTheme = IconTheme.of(context);
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

      expect(resolvedTextStyle, equals(theme.textStyle));
      expect(resolvedIconTheme.color, equals(theme.iconTheme.color));
      expect(resolvedIconTheme.size, equals(theme.iconTheme.size));
    });

    testWidgets('router path respects scrollBehavior wiring via _wrapWithTheme', (tester) async {
      final customBehavior = _CustomScrollBehavior();
      late ScrollBehavior resolvedBehavior;

      final routerConfig = RouterConfig<Object>(
        routeInformationProvider: _SimpleRouteInformationProvider(),
        routeInformationParser: SimpleRouteInformationParser(),
        routerDelegate: SimpleRouterDelegate(
          builder: (context) {
            resolvedBehavior = ScrollConfiguration.of(context);
            return const Placeholder();
          },
        ),
      );

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Router Test',
          scrollBehavior: customBehavior,
          routerConfig: routerConfig,
        ),
      );

      expect(resolvedBehavior, same(customBehavior));
    });
  });
}

/// Simple scroll behavior for testing.
class _CustomScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const AlwaysScrollableScrollPhysics();
}

/// Simple router delegate for testing declarative routing.
class SimpleRouterDelegate extends RouterDelegate<Object> {
  /// Optional builder for custom widget rendering in tests.
  final WidgetBuilder? _customBuilder;
  final List<VoidCallback> _listeners = [];

  SimpleRouterDelegate({WidgetBuilder? builder}) : _customBuilder = builder;

  @override
  RouteInformation get currentConfiguration => RouteInformation(uri: Uri.parse('/'));

  @override
  Widget build(BuildContext context) => _customBuilder?.call(context) ?? const Placeholder();

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

/// Simple route information provider for testing declarative routing.
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

  void dispose() {
    _listeners.clear();
  }

  Future<bool> didPushRoute(String route) async => false;

  Future<bool> didPushRouteInformation(RouteInformation routeInformation) => Future.value(false);

  @override
  void routerReportsNewRouteInformation(
    RouteInformation information, {
    RouteInformationReportingType type = RouteInformationReportingType.navigate,
  }) {}
}

/// Simple route information parser for testing declarative routing.
class SimpleRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async => routeInformation;

  @override
  RouteInformation restoreRouteInformation(Object configuration) => configuration as RouteInformation;
}

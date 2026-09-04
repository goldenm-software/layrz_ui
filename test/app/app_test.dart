import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzApp', () {
    testWidgets('imperative constructor pumps without error', (tester) async {
      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: const SizedBox(width: 100, height: 100),
        ),
      );

      // LayrzApp auto-installs a LayrzSnackbarMessenger in `_wrapWithTheme`,
      // which renders its own `SizedBox.shrink()` for the (empty) toast
      // overlay alongside the app's content. A bare type-finder would match
      // both, so this looks for the specific 100x100 box `home` declares.
      expect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == 100 && widget.height == 100),
        findsOneWidget,
      );
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

      final defaultTheme = LayrzThemeData.light();
      expect(resolvedTheme.primaryColor, equals(defaultTheme.primaryColor));
    });

    testWidgets('DefaultTextStyle carries theme.textStyle', (tester) async {
      final theme = LayrzThemeData.light();

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
      final theme = LayrzThemeData.light();

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

    testWidgets('auto-installs a LayrzSnackbarMessenger reachable from home', (tester) async {
      late LayrzSnackbarMessengerState resolvedState;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolvedState = LayrzSnackbarMessenger.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolvedState, isNotNull);
      expect(find.byType(LayrzSnackbarMessenger), findsOneWidget);
    });

    testWidgets('ColoredBox carries theme.backgroundColor', (tester) async {
      final theme = LayrzThemeData.light();

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

      // LayrzApp auto-installs a LayrzSnackbarMessenger in `_wrapWithTheme`,
      // which renders its own `SizedBox.shrink()` for the (empty) toast
      // overlay alongside the builder's content. A bare type-finder would
      // match both, so this looks for the specific 50x50 box `home` declares.
      expect(builderCalled, isTrue);
      expect(find.byType(Container), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == 50 && widget.height == 50),
        findsOneWidget,
      );
    });

    testWidgets('color defaults to theme.primaryColor', (tester) async {
      final theme = LayrzThemeData.light(
        primaryColor: const Color(0xFFAABBCC),
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
      final theme = LayrzThemeData.light();
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

    group('pageTransitionType', () {
      testWidgets('defaults to fade and installs a FadeTransition on pushed routes', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            initialRoute: '/',
            routes: {
              '/': (context) => Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/second'),
                  child: const Text('first'),
                ),
              ),
              '/second': (context) => const Text('second'),
            },
          ),
        );

        await tester.tap(find.text('first'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(FadeTransition), findsWidgets);
      });

      testWidgets('a caller-supplied type overrides the default', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            initialRoute: '/',
            pageTransitionType: LayrzTransitionType.none,
            routes: {
              '/': (context) => Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/second'),
                  child: const Text('first'),
                ),
              ),
              '/second': (context) => const Text('second'),
            },
          ),
        );

        await tester.tap(find.text('first'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(FadeTransition), findsNothing);
        expect(find.byType(ScaleTransition), findsNothing);
      });

      testWidgets('respects reduced motion even with the default fade type', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: LayrzApp(
              title: 'Test App',
              initialRoute: '/',
              routes: {
                '/': (context) => Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/second'),
                    child: const Text('first'),
                  ),
                ),
                '/second': (context) => const Text('second'),
              },
            ),
          ),
        );

        await tester.tap(find.text('first'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(FadeTransition), findsNothing);
        expect(find.text('second'), findsOneWidget);
      });

      testWidgets('pageTransitionTypeOf reads the ambient value from an imperative LayrzApp', (
        tester,
      ) async {
        late LayrzTransitionType resolved;

        await tester.pumpWidget(
          LayrzApp(
            title: 'Test App',
            pageTransitionType: LayrzTransitionType.slide,
            home: Builder(
              builder: (context) {
                resolved = LayrzApp.pageTransitionTypeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved, LayrzTransitionType.slide);
      });

      testWidgets('pageTransitionTypeOf reads the ambient value from a router-based LayrzApp', (
        tester,
      ) async {
        late LayrzTransitionType resolved;

        final routerConfig = RouterConfig<Object>(
          routeInformationProvider: _SimpleRouteInformationProvider(),
          routeInformationParser: SimpleRouteInformationParser(),
          routerDelegate: SimpleRouterDelegate(
            builder: (context) {
              resolved = LayrzApp.pageTransitionTypeOf(context);
              return const Placeholder();
            },
          ),
        );

        await tester.pumpWidget(
          LayrzApp.router(
            title: 'Router Test',
            pageTransitionType: LayrzTransitionType.scale,
            routerConfig: routerConfig,
          ),
        );

        expect(resolved, LayrzTransitionType.scale);
      });

      testWidgets('pageTransitionTypeOf defaults to fade with no LayrzApp ancestor', (tester) async {
        late LayrzTransitionType resolved;

        await tester.pumpWidget(
          Builder(
            builder: (context) {
              resolved = LayrzApp.pageTransitionTypeOf(context);
              return const SizedBox.shrink();
            },
          ),
        );

        expect(resolved, LayrzTransitionType.fade);
      });
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

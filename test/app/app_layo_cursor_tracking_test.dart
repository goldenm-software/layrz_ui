import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Widget-level tests for [LayrzApp.enableLayoCursorTracking] (both the
/// default and [LayrzApp.router] constructors): the default `false` installs
/// no [LayoCursorScope] anywhere below the app, `true` installs exactly one,
/// and — where a real pointer is simulated — that scope's own notifier
/// actually reflects a live hover/exit without ever triggering a rebuild
/// above the point a descendant reads it.
void main() {
  group('LayrzApp.enableLayoCursorTracking', () {
    testWidgets('defaults to false: LayoCursorScope.maybeOf resolves to null below the app', (tester) async {
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          home: Builder(
            builder: (context) {
              resolved = LayoCursorScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isNull);
    });

    testWidgets('true installs a LayoCursorScope: LayoCursorScope.maybeOf resolves to a non-null notifier', (
      tester,
    ) async {
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          enableLayoCursorTracking: true,
          home: Builder(
            builder: (context) {
              resolved = LayoCursorScope.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isNotNull);
    });

    testWidgets('router constructor: defaults to false, LayoCursorScope.maybeOf resolves to null', (tester) async {
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Test App',
          routerConfig: RouterConfig<Object>(
            routerDelegate: _StaticRouterDelegate(
              Builder(
                builder: (context) {
                  resolved = LayoCursorScope.maybeOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNull);
    });

    testWidgets('router constructor: true installs a LayoCursorScope with a non-null notifier', (tester) async {
      late ValueNotifier<Offset?>? resolved;

      await tester.pumpWidget(
        LayrzApp.router(
          title: 'Test App',
          enableLayoCursorTracking: true,
          routerConfig: RouterConfig<Object>(
            routerDelegate: _StaticRouterDelegate(
              Builder(
                builder: (context) {
                  resolved = LayoCursorScope.maybeOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      expect(resolved, isNotNull);
    });

    testWidgets('true: hovering writes the global position into the notifier with no ancestor rebuild', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var homeBuildCount = 0;
      ValueNotifier<Offset?>? notifier;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          enableLayoCursorTracking: true,
          home: Builder(
            builder: (context) {
              homeBuildCount++;
              notifier = LayoCursorScope.maybeOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(notifier, isNotNull);
      final buildsAfterFirstPump = homeBuildCount;
      expect(notifier!.value, isNull, reason: 'no pointer has moved yet');

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      // `addPointer` alone only introduces the pointer at its initial
      // location without firing `onHover` -- a real `onHover` requires an
      // actual move, which `moveTo` provides.
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(123, 45));
      await tester.pump();

      expect(notifier!.value, const Offset(123, 45));
      expect(
        homeBuildCount,
        buildsAfterFirstPump,
        reason: 'the notifier is the only channel a pointer move travels through -- home must not rebuild',
      );

      await gesture.moveTo(const Offset(0, 0));
      await tester.pump();
      expect(notifier!.value, Offset.zero);
      expect(homeBuildCount, buildsAfterFirstPump);
    });

    testWidgets('true: the pointer leaving the app content resets the notifier to null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ValueNotifier<Offset?>? notifier;

      await tester.pumpWidget(
        LayrzApp(
          title: 'Test App',
          enableLayoCursorTracking: true,
          home: Builder(
            builder: (context) {
              notifier = LayoCursorScope.maybeOf(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(50, 50));
      await tester.pump();
      expect(notifier!.value, const Offset(50, 50));

      await gesture.moveTo(const Offset(-500, -500));
      await tester.pump();
      expect(notifier!.value, isNull);
    });
  });
}

/// A minimal, fixed [RouterDelegate] that always shows [child] and never
/// itself changes configuration — enough to exercise
/// [LayrzApp.router]'s own `enableLayoCursorTracking` wiring without a real
/// router package dependency.
class _StaticRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  /// Creates a [_StaticRouterDelegate] that always shows [child].
  _StaticRouterDelegate(this.child);

  /// The single widget this delegate's [Navigator] always shows.
  final Widget child;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Object? get currentConfiguration => Object();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [_StaticTestPage(child: child)],
      onDidRemovePage: (page) {},
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

/// A bare, non-Material [Page] wrapping [child] in a [PageRouteBuilder] with
/// no transition — this design system's `LayrzApp` is Material-free, so this
/// test cannot reach for `MaterialPage`.
class _StaticTestPage extends Page<void> {
  /// Creates a [_StaticTestPage] showing [child].
  const _StaticTestPage({required this.child});

  /// The widget this page's route always builds.
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

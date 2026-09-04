import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../../helpers/pump_themed.dart';

/// Pumps a [LayrzSnackbarMessenger] wrapping a themed tree, returning a
/// [BuildContext] descendant of the messenger so callers can drive
/// `LayrzSnackbarMessenger.of(context)` without repeating the wrapping
/// boilerplate in every test.
///
/// [tester] is the active [WidgetTester]. [maxWidth], [padding], and
/// [maxVisible] forward directly to [LayrzSnackbarMessenger]'s matching
/// constructor parameters, letting a test override the stacking cap or
/// layout without hand-rolling the tree.
///
/// The returned [BuildContext] is captured from a [Builder] placed directly
/// under the messenger's [LayrzSnackbarMessenger.child] slot, so
/// `LayrzSnackbarMessenger.of(capturedContext)` always resolves to the
/// pumped messenger's state.
///
/// There is deliberately no `globalKey`/`showGlobal` parameter here —
/// [LayrzSnackbarMessenger] resolves by tree ancestry only (DESIGN-60 rework).
Future<BuildContext> pumpMessenger(
  WidgetTester tester, {
  double maxWidth = kLayrzSnackbarMaxWidth,
  EdgeInsets padding = const EdgeInsets.all(16),
  int maxVisible = kLayrzSnackbarMaxVisible,
}) async {
  late BuildContext capturedContext;

  await pumpThemed(
    tester,
    LayrzSnackbarMessenger(
      maxWidth: maxWidth,
      padding: padding,
      maxVisible: maxVisible,
      child: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return capturedContext;
}

/// Pumps a bare [LayrzApp] (imperative-routing constructor) whose `home`
/// builds [child], and returns a [BuildContext] from inside that subtree —
/// proving [LayrzSnackbarMessenger] is auto-installed by [LayrzApp] (R7):
/// no manual [LayrzSnackbarMessenger] is constructed anywhere in this tree,
/// yet `LayrzSnackbarMessenger.of(capturedContext)` must resolve.
///
/// [tester] is the active [WidgetTester]. [child] is wrapped in a [Builder]
/// so it receives (and can capture) a [BuildContext] that sits below
/// [LayrzApp]'s auto-installed messenger.
Future<BuildContext> pumpAutoInstalledApp(WidgetTester tester) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    LayrzApp(
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();

  return capturedContext;
}

/// Pumps a bare [LayrzApp.router] (declarative-routing constructor) whose
/// routed content builds [child], and returns a [BuildContext] from inside
/// that subtree — the `.router` counterpart of [pumpAutoInstalledApp],
/// proving auto-install also covers the declarative-routing build path.
///
/// [tester] is the active [WidgetTester]. Uses [_SingleRouteRouterDelegate],
/// which — like `test/app/app_test.dart`'s own `SimpleRouterDelegate` —
/// returns its content directly from `build()` with no [Navigator] involved.
/// A real [Navigator]/[Page] wraps its content in an unbounded-height
/// [Overlay] entry, which the messenger's own accordion `Column` (sized by
/// its content, not by its parent) cannot satisfy — that combination throws
/// a `RenderStack requires bounded constraints` layout assertion. Skipping
/// the [Navigator] avoids that entirely, and is sufficient here since this
/// helper only needs to prove the messenger is reachable from a descendant
/// context, not exercise real navigation.
Future<BuildContext> pumpAutoInstalledRouterApp(WidgetTester tester) async {
  late BuildContext capturedContext;

  final delegate = _SingleRouteRouterDelegate(
    builder: (context) {
      capturedContext = context;
      return const SizedBox.shrink();
    },
  );

  await tester.pumpWidget(
    LayrzApp.router(
      routerDelegate: delegate,
      routeInformationParser: _SingleRouteInformationParser(),
    ),
  );
  await tester.pump();

  return capturedContext;
}

/// A minimal [RouterDelegate] that always renders a single [Builder]-wrapped
/// widget directly from `build()`, just enough to exercise [LayrzApp.router]'s
/// build path in tests without pulling in a real routing package or a
/// [Navigator] (see [pumpAutoInstalledRouterApp] for why a [Navigator] is
/// deliberately avoided here).
class _SingleRouteRouterDelegate extends RouterDelegate<Object> with ChangeNotifier {
  /// Builds the single route's content, capturing its [BuildContext].
  final WidgetBuilder builder;

  /// Creates a [_SingleRouteRouterDelegate] that always shows [builder]'s content.
  _SingleRouteRouterDelegate({required this.builder});

  @override
  Object? get currentConfiguration => Object();

  @override
  Widget build(BuildContext context) => Builder(builder: builder);

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  Future<bool> popRoute() async => false;
}

/// A minimal [RouteInformationParser] that ignores the platform's route
/// information entirely — this test app has exactly one route.
class _SingleRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async => Object();
}

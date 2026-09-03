import 'package:flutter/widgets.dart';

/// A minimal, single-page [Page] used only by [ThinRouterDelegate].
class _ThinPage extends Page<void> {
  /// Creates a new [_ThinPage].
  const _ThinPage({required this.child, required super.key});

  /// The content this page hosts.
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

/// A stand-in for a real declarative router package (e.g. `go_router`),
/// which `layrz_ui` has no dependency on and cannot import in its own test
/// suite.
///
/// Reproduces the one invariant relevant to the maintainer's Finding 2
/// report: a real page-based router's delegate tracks its own current page
/// stack and throws when asked for [currentConfiguration] after that stack
/// has been popped empty from underneath it -- mirroring `go_router`'s own
/// `GoRouterDelegate.currentConfiguration`, whose real assertion text is
/// `'currentConfiguration.isNotEmpty'`, the exact string in the maintainer's
/// crash report.
///
/// [builder] supplies this delegate's single page's content, hosted inside a
/// real, page-based [Navigator] this delegate owns. [LayrzEndDrawer]/
/// [LayrzBottomSheet] push their own route onto that same [Navigator]
/// imperatively (via `Navigator.of(context, rootNavigator: true)`), sitting
/// above this delegate's one page in the Navigator's history -- exactly like
/// a real app's drawer sits above go_router's own current page. **A single
/// pop of that imperative route is harmless** (it only removes the drawer's
/// own route, leaving this delegate's page alone) -- the maintainer's crash
/// needs a SECOND pop, arriving after the first has already removed the
/// drawer, which then pops this delegate's own root page instead. [popped]
/// flips `true` when that happens; [currentConfiguration] throws once it
/// has, so a test can assert either directly.
class ThinRouterDelegate extends RouterDelegate<Object> with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  /// Creates a new [ThinRouterDelegate].
  ThinRouterDelegate({required this.builder});

  /// Builds the single page's content.
  final WidgetBuilder builder;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Whether this delegate's own root page has been popped out from under
  /// it -- the condition a real go_router-hosted app crashes on.
  bool popped = false;

  @override
  RouteInformation get currentConfiguration {
    if (popped) {
      throw StateError(
        "currentConfiguration.isNotEmpty -- You have popped the last page off of the stack",
      );
    }
    return RouteInformation(uri: Uri.parse('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        _ThinPage(
          key: const ValueKey('thin-root'),
          child: Builder(builder: builder),
        ),
      ],
      onDidRemovePage: (page) {
        popped = true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

/// Parses/restores the trivial [RouteInformation] [ThinRouterDelegate] uses.
class ThinRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async => routeInformation;

  @override
  RouteInformation restoreRouteInformation(Object configuration) => configuration as RouteInformation;
}

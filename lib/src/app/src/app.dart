import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/scrollbar/scrollbar.dart';
import 'package:layrz_ui/src/snackbar/snackbar.dart';
import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/transitions/transitions.dart';

/// Root application widget for layrz_ui.
///
/// Light-mode-only widget built exclusively on [WidgetsApp] — no Material
/// or Cupertino dependency.
///
/// Usage (declarative routing):
/// ```dart
/// LayrzApp.router(
///   routerConfig: myRouter,
///   theme: LayrzThemeData.light(primaryColor: brandColor),
///   title: 'My App',
/// )
/// ```
///
/// Usage (imperative routing):
/// ```dart
/// LayrzApp(
///   home: MyHomePage(),
///   theme: LayrzThemeData.light(),
/// )
/// ```
class LayrzApp extends StatefulWidget {
  // ── Routing (imperative) ────────────────────────────────────────────

  /// The widget for the default route of the app (`/`).
  /// Used only with the imperative-routing constructor.
  final Widget? home;

  /// A map of named routes. Used only with the imperative-routing constructor.
  final Map<String, WidgetBuilder>? routes;

  /// Called to generate a route for the given [RouteSettings].
  /// Used only with the imperative-routing constructor.
  final RouteFactory? onGenerateRoute;

  /// Called when no matching route is found.
  /// Used only with the imperative-routing constructor.
  final RouteFactory? onUnknownRoute;

  /// Observers for the [Navigator]. Used only with the imperative-routing constructor.
  final List<NavigatorObserver> navigatorObservers;

  /// The name of the first route to show. Defaults to `/`.
  /// Used only with the imperative-routing constructor.
  final String? initialRoute;

  // ── Routing (declarative) ───────────────────────────────────────────

  /// A [RouterConfig] that configures the [Router] widget.
  /// Used only with [LayrzApp.router].
  final RouterConfig<Object>? routerConfig;

  /// A delegate that provides a widget tree for the current [RouteInformation].
  /// Used only with [LayrzApp.router].
  final RouterDelegate<Object>? routerDelegate;

  /// Restores [RouteInformation] from and to the platform.
  /// Used only with [LayrzApp.router].
  final RouteInformationParser<Object>? routeInformationParser;

  /// Provides [RouteInformation] to the [Router].
  /// Used only with [LayrzApp.router].
  final RouteInformationProvider? routeInformationProvider;

  /// Handles the platform back button. Used only with [LayrzApp.router].
  final BackButtonDispatcher? backButtonDispatcher;

  // ── Theme ───────────────────────────────────────────────────────────

  /// The light [LayrzThemeData]. Defaults to [LayrzThemeData.light()] when not provided.
  final LayrzThemeData? theme;

  // ── App metadata ────────────────────────────────────────────────────

  /// The one-line description of this app, shown in the OS task switcher.
  final String title;

  /// Callback to generate a localized [title] string. Takes precedence over [title].
  final GenerateAppTitle? onGenerateTitle;

  /// Primary color surfaced to the host OS (Android task-switcher, etc.).
  /// Defaults to [LayrzThemeData.primaryColor] of the effective theme.
  final Color? color;

  /// Whether to show the debug banner in the top-right corner. Defaults to `true`.
  final bool debugShowCheckedModeBanner;

  /// Whether to show the semantics debugger overlay. Defaults to `false`.
  final bool showSemanticsDebugger;

  /// Whether to show the widget inspector overlay. Defaults to `false`.
  final bool debugShowWidgetInspector;

  // ── Localizations ───────────────────────────────────────────────────

  /// The initial locale for this app. Defaults to the system locale.
  final Locale? locale;

  /// Delegates for localizing this app's content.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// The locales this app supports. Defaults to `[Locale('en')]`.
  final Iterable<Locale> supportedLocales;

  /// Callback to select a locale from the device's preferred list.
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// Callback to select a locale given a single requested locale.
  final LocaleResolutionCallback? localeResolutionCallback;

  // ── Builder ─────────────────────────────────────────────────────────

  /// A widget builder inserted between [WidgetsApp] and the route content.
  /// Receives the resolved child; return a new widget wrapping it.
  final TransitionBuilder? builder;

  // ── Scroll behavior ─────────────────────────────────────────────────

  /// Overrides the default scroll behavior for the entire app.
  ///
  /// When null (the default), [LayrzScrollBehavior] is used, which installs
  /// [LayrzScrollbar] globally on all vertical scrollables on pointer platforms
  /// (desktop/web). This is a visible behavior change for existing consumers —
  /// scroll views that previously had no scrollbar will now display one.
  ///
  /// Set this to a custom [ScrollBehavior] to opt out of the default behavior.
  final ScrollBehavior? scrollBehavior;

  // ── Shortcuts / actions ─────────────────────────────────────────────

  /// A map of keyboard shortcut activators to [Intent]s.
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// A map of [Intent] types to [Action]s.
  final Map<Type, Action<Intent>>? actions;

  /// The identifier for state restoration.
  final String? restorationScopeId;

  // ── Page transitions ────────────────────────────────────────────────

  /// The design system's default page-transition animation.
  ///
  /// Defaults to [LayrzTransitionType.fade]. On the imperative-routing
  /// constructor ([LayrzApp.new]), this value has a real, direct effect: it
  /// is resolved via [LayrzPageTransitions.resolve] and installed as the
  /// `transitionsBuilder` (with [LayrzPageTransitions.durationOf] as the
  /// matching `transitionDuration`) on every [PageRouteBuilder] this widget
  /// constructs for [home], [routes], and [onGenerateRoute].
  ///
  /// On the declarative-routing constructor ([LayrzApp.router]), `layrz_ui`
  /// has no dependency on `go_router` (or any other router package) and
  /// therefore cannot reach into a caller-supplied [RouterConfig] to install
  /// a transition on routes it did not build — there is no seam to intercept.
  /// This value is still propagated as ambient app state, reachable via
  /// [LayrzApp.pageTransitionTypeOf], so a router-based caller can read the
  /// design system's default and apply it explicitly to their own route
  /// builders (for example, go_router's `CustomTransitionPage.transitionsBuilder:
  /// LayrzPageTransitions.resolve(LayrzApp.pageTransitionTypeOf(context))`).
  /// It is not applied automatically for router-based apps.
  ///
  /// Every builder [LayrzPageTransitions.resolve] can return already checks
  /// [MediaQuery.disableAnimationsOf] and falls back to
  /// [LayrzPageTransitions.none] when the platform requests reduced motion,
  /// so this default respects that preference wherever it is actually
  /// applied.
  final LayrzTransitionType pageTransitionType;

  /// Imperative-routing constructor.
  const LayrzApp({
    super.key,
    this.home,
    this.routes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const [],
    this.initialRoute,
    this.theme,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.debugShowCheckedModeBanner = true,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en')],
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.builder,
    this.scrollBehavior,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.pageTransitionType = LayrzTransitionType.fade,
  }) : routerConfig = null,
       routerDelegate = null,
       routeInformationParser = null,
       routeInformationProvider = null,
       backButtonDispatcher = null;

  /// Declarative-routing constructor (go_router, auto_route, etc.).
  const LayrzApp.router({
    super.key,
    this.routerConfig,
    this.routerDelegate,
    this.routeInformationParser,
    this.routeInformationProvider,
    this.backButtonDispatcher,
    this.theme,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.debugShowCheckedModeBanner = true,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en')],
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.builder,
    this.scrollBehavior,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.pageTransitionType = LayrzTransitionType.fade,
  }) : home = null,
       routes = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const [],
       initialRoute = null;

  /// Returns the nearest ancestor [LayrzApp]'s [pageTransitionType].
  ///
  /// [context] is the [BuildContext] to search upward from. Intended for
  /// router-based callers (see [pageTransitionType]'s doc comment) who build
  /// their own route pages and want to apply the design system's default
  /// transition rather than hardcoding [LayrzTransitionType.fade] themselves.
  ///
  /// Returns [LayrzTransitionType.fade] — the same default [pageTransitionType]
  /// itself falls back to — if no [LayrzApp] ancestor is found, so this is
  /// safe to call even outside a [LayrzApp] subtree.
  static LayrzTransitionType pageTransitionTypeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LayrzAppScope>();
    return scope?.pageTransitionType ?? LayrzTransitionType.fade;
  }

  @override
  State<LayrzApp> createState() => _LayrzAppState();
}

/// [InheritedWidget] that propagates [LayrzApp.pageTransitionType] down the
/// widget tree, so [LayrzApp.pageTransitionTypeOf] can read it from any
/// descendant context — including inside a router-based caller's own route
/// builders, which sit below this scope.
class _LayrzAppScope extends InheritedWidget {
  /// The [LayrzApp.pageTransitionType] value being propagated.
  final LayrzTransitionType pageTransitionType;

  /// Creates a [_LayrzAppScope].
  ///
  /// [pageTransitionType] is the value to propagate. [child] is the widget
  /// subtree that can read it via [LayrzApp.pageTransitionTypeOf].
  const _LayrzAppScope({required this.pageTransitionType, required super.child});

  @override
  bool updateShouldNotify(_LayrzAppScope oldWidget) => pageTransitionType != oldWidget.pageTransitionType;
}

/// Combines caller-supplied localizations delegates with the default [LayrzUiL10nDelegate].
///
/// Appends [LayrzUiL10nDelegate] last so caller-supplied delegates take precedence
/// via Flutter's delegate resolution order. If a [LayrzUiL10nDelegate] is already
/// present in [userDelegates], it is not duplicated.
///
/// Parameters:
/// - [userDelegates]: an iterable of caller-supplied [LocalizationsDelegate] instances,
///   or null if no caller delegates were provided. This iterable is copied (not mutated).
///
/// Returns a list containing all caller delegates (in order) followed by the default
/// [LayrzUiL10nDelegate] (if not already present).
@visibleForTesting
List<LocalizationsDelegate<dynamic>> buildLayrzUiL10nDelegates(
  Iterable<LocalizationsDelegate<dynamic>>? userDelegates,
) {
  final delegates = userDelegates?.toList() ?? <LocalizationsDelegate<dynamic>>[];

  if (!delegates.any((d) => d is LayrzUiL10nDelegate)) {
    delegates.add(const LayrzUiL10nDelegate());
  }

  return delegates;
}

class _LayrzAppState extends State<LayrzApp> {
  /// Combines user-supplied localizations delegates with the default [LayrzUiL10nDelegate].
  ///
  /// Preserves the order of user delegates (which take precedence), then appends
  /// the default [LayrzUiL10nDelegate] if not already present.
  List<LocalizationsDelegate<dynamic>> _buildLocalizationsDelegates() {
    return buildLayrzUiL10nDelegates(widget.localizationsDelegates);
  }

  Widget _wrapWithTheme({
    required BuildContext context,
    required LayrzThemeData themeData,
    required Widget? child,
  }) {
    final userChild = widget.builder?.call(context, child) ?? child ?? const SizedBox.shrink();

    final innerChild = LayrzTheme(
      data: themeData,
      child: DefaultTextStyle(
        style: themeData.textStyle,
        child: IconTheme(
          data: themeData.iconTheme,
          child: ColoredBox(
            color: themeData.backgroundColor,
            child: LayrzSnackbarMessenger(child: userChild),
          ),
        ),
      ),
    );

    // Use the provided scrollBehavior, or fall back to LayrzScrollBehavior
    final scrollBehavior = widget.scrollBehavior ?? const LayrzScrollBehavior();

    return _LayrzAppScope(
      pageTransitionType: widget.pageTransitionType,
      child: ScrollConfiguration(
        behavior: scrollBehavior,
        child: innerChild,
      ),
    );
  }

  bool get _isRouter => widget.routerConfig != null || widget.routerDelegate != null;

  @override
  Widget build(BuildContext context) {
    final themeData = widget.theme ?? LayrzThemeData.light();
    final appColor = widget.color ?? themeData.primaryColor;
    final localizationsDelegates = _buildLocalizationsDelegates();

    if (_isRouter) {
      return WidgetsApp.router(
        key: GlobalObjectKey(this),
        color: appColor,
        title: widget.title,
        onGenerateTitle: widget.onGenerateTitle,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        showSemanticsDebugger: widget.showSemanticsDebugger,
        debugShowWidgetInspector: widget.debugShowWidgetInspector,
        locale: widget.locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: widget.supportedLocales,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        localeResolutionCallback: widget.localeResolutionCallback,
        shortcuts: widget.shortcuts,
        actions: widget.actions,
        restorationScopeId: widget.restorationScopeId,
        routerConfig: widget.routerConfig,
        routerDelegate: widget.routerDelegate,
        routeInformationParser: widget.routeInformationParser,
        routeInformationProvider: widget.routeInformationProvider,
        backButtonDispatcher: widget.backButtonDispatcher,
        builder: (ctx, child) => _wrapWithTheme(context: ctx, themeData: themeData, child: child),
      );
    }

    return WidgetsApp(
      key: GlobalObjectKey(this),
      color: appColor,
      title: widget.title,
      onGenerateTitle: widget.onGenerateTitle,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      showSemanticsDebugger: widget.showSemanticsDebugger,
      debugShowWidgetInspector: widget.debugShowWidgetInspector,
      locale: widget.locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: widget.supportedLocales,
      localeListResolutionCallback: widget.localeListResolutionCallback,
      localeResolutionCallback: widget.localeResolutionCallback,
      shortcuts: widget.shortcuts,
      actions: widget.actions,
      restorationScopeId: widget.restorationScopeId,
      home: widget.home,
      routes: widget.routes ?? const {},
      onGenerateRoute: widget.onGenerateRoute,
      onUnknownRoute: widget.onUnknownRoute,
      navigatorObservers: widget.navigatorObservers,
      initialRoute: widget.initialRoute,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
          transitionsBuilder: LayrzPageTransitions.resolve(widget.pageTransitionType),
          transitionDuration: themeData.tokens.motion.dPageTransition,
        );
      },
      builder: (ctx, child) => _wrapWithTheme(context: ctx, themeData: themeData, child: child),
    );
  }
}

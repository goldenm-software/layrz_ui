import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/find_in_page/find_in_page.dart';
import 'package:layrz_ui/src/keyboard/keyboard.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/scrollbar/scrollbar.dart';
import 'package:layrz_ui/src/snackbar/snackbar.dart';
import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/transitions/transitions.dart';

import 'app_banner.dart';
import 'app_banner_painter.dart';

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

  /// The BETA dark [LayrzThemeData]. Defaults to [LayrzThemeData.dark()] when not provided.
  ///
  /// Only used when [themeMode] resolves to dark — either [LayrzThemeMode.dark]
  /// directly, or [LayrzThemeMode.system] when the platform brightness is
  /// [Brightness.dark].
  final LayrzThemeData? darkTheme;

  /// Which of [theme] and [darkTheme] is active. Defaults to [LayrzThemeMode.system],
  /// which follows the operating system's brightness setting.
  final LayrzThemeMode themeMode;

  // ── App metadata ────────────────────────────────────────────────────

  /// The one-line description of this app, shown in the OS task switcher.
  final String title;

  /// Callback to generate a localized [title] string. Takes precedence over [title].
  final GenerateAppTitle? onGenerateTitle;

  /// Primary color surfaced to the host OS (Android task-switcher, etc.).
  /// Defaults to [LayrzThemeData.primaryColor] of the effective theme.
  final Color? color;

  /// Configures the debug-only, tiled diagonal watermark rendered above the
  /// app's content — this is `LayrzApp`'s full replacement for Flutter's red
  /// DEBUG corner banner, which `LayrzApp` never renders (the SDK's
  /// `debugShowCheckedModeBanner` is always hardcoded to `false`
  /// internally — there is no way to bring it back).
  ///
  /// **Automatic by default**: when [showDebugWatermark] is `true` (the
  /// default) and [banner] is `null`, [_LayrzAppState._wrapWithTheme]
  /// automatically renders the watermark in debug builds — no caller
  /// action required — using `LayrzAppBanner(labelText: l10n.debugBanner)`
  /// so the label is localized. Passing a non-null [banner] overrides the
  /// label (and optionally the color) shown, for example to read `'STAGING'`
  /// instead of the localized default. To disable the watermark entirely,
  /// set [showDebugWatermark] to `false` rather than relying on `banner`,
  /// since `banner: null` now means "use the automatic default" rather than
  /// "no watermark". This has no effect at all outside debug mode — release
  /// and profile builds never render a watermark regardless of what is
  /// passed here.
  final LayrzAppBanner? banner;

  /// Whether the debug-only watermark described by [banner] may render at
  /// all. Defaults to `true`.
  ///
  /// Set this to `false` to opt out of the watermark entirely — for example
  /// in golden/screenshot tests, or an app that never wants the watermark —
  /// even in debug mode and even if [banner] is provided. When `true` (the
  /// default), the watermark still only ever renders in debug builds, per
  /// [banner]'s doc comment.
  final bool showDebugWatermark;

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

  // ── Find-in-page ────────────────────────────────────────────────────

  /// Whether the browser-style, in-page Ctrl/Cmd+F find feature is enabled.
  ///
  /// Defaults to **`true`** — this is opt-**out**, not opt-in: find-in-page
  /// ships on for every app unless a caller explicitly disables it per
  /// customer/build. When `true`, [_LayrzAppState._wrapWithTheme] wraps the
  /// app's content in a [LayrzFindInPageHost], which registers Ctrl+F
  /// (Cmd+F on macOS) via the ambient [LayrzShortcut] registry and — on web
  /// only — additionally suppresses the browser's own native find dialog so
  /// this themed one opens instead (see [LayrzFindInPageHost]'s own doc for
  /// the full mechanism).
  ///
  /// **Idle cost is negligible.** [LayrzFindInPageHost] holds no
  /// [SemanticsHandle] — the expensive resource behind find's match search —
  /// until the user actually opens find; see
  /// [LayrzFindInPageController]'s "Idle cost" doc for why this is safe to
  /// leave on by default for every app rather than something a caller must
  /// remember to enable. Set this to `false` to opt a specific app (or a
  /// specific customer build) out entirely.
  final bool enableFindInPage;

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
    this.darkTheme,
    this.themeMode = LayrzThemeMode.system,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.banner,
    this.showDebugWatermark = true,
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
    this.enableFindInPage = true,
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
    this.darkTheme,
    this.themeMode = LayrzThemeMode.system,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.banner,
    this.showDebugWatermark = true,
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
    this.enableFindInPage = true,
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

    // Without an ancestor `DefaultSelectionStyle`, `EditableText.selectionColor`
    // and `SelectableRegion.selectionColor` both resolve to null and paint
    // fully transparent — text selection is present but invisible everywhere
    // in the app (Material installs this via `TextSelectionTheme`; this
    // Material-free design system has no equivalent unless installed here).
    // Both colors are first-class themeable fields on `LayrzThemeData` (see
    // `LayrzThemeData.selectionColor` / `.cursorColor`) rather than hardcoded
    // here, so a future dark theme can override them without touching this file.
    // enableFindInPage wraps the innermost user content only — it needs to
    // sit UNDER LayrzShortcut (so LayrzFindInPageHost can register its
    // Ctrl/Cmd+F chord against the ambient registry) and under
    // LayrzSnackbarMessenger's own root Overlay/WidgetsApp chain (so its
    // root-overlay highlight/find-bar painting has an Overlay ancestor to
    // resolve). Composing it here — nearest to userChild, innermost in the
    // chain — satisfies both without disturbing LayrzShortcut,
    // LayrzSnackbarMessenger, DefaultSelectionStyle, or the debug watermark
    // built around this whole themedChild below.
    final contentWithFindInPage = widget.enableFindInPage ? LayrzFindInPageHost(child: userChild) : userChild;

    final themedChild = LayrzTheme(
      data: themeData,
      child: DefaultSelectionStyle(
        selectionColor: themeData.selectionColor,
        cursorColor: themeData.cursorColor,
        child: DefaultTextStyle(
          style: themeData.textStyle,
          child: IconTheme(
            data: themeData.iconTheme,
            child: ColoredBox(
              color: themeData.backgroundColor,
              child: LayrzShortcut(child: LayrzSnackbarMessenger(child: contentWithFindInPage)),
            ),
          ),
        ),
      ),
    );

    // Resolve the effective banner: an explicit `widget.banner` always wins;
    // otherwise, in debug builds, fall back to the localized automatic
    // default — unless the caller opted out via `showDebugWatermark: false`.
    // Reading `context.l10n` here is safe: this builder runs inside
    // WidgetsApp's own `builder`, which is invoked below the `Localizations`
    // widget WidgetsApp installs, so localizations are already in scope.
    final effectiveBanner = !widget.showDebugWatermark
        ? null
        : widget.banner ?? (kDebugMode ? LayrzAppBanner(labelText: context.l10n.debugBanner) : null);

    final innerChild = kDebugMode && effectiveBanner != null
        ? Stack(
            children: [
              themedChild,
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: LayrzAppBannerPainter(
                        labelText: effectiveBanner.labelText,
                        color: effectiveBanner.color ?? themeData.tokens.colors.watermark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : themedChild;

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
    final lightData = widget.theme ?? LayrzThemeData.light();
    final darkData = widget.darkTheme ?? LayrzThemeData.dark();
    final LayrzThemeData themeData;
    switch (widget.themeMode) {
      case LayrzThemeMode.light:
        themeData = lightData;
      case LayrzThemeMode.dark:
        themeData = darkData;
      case LayrzThemeMode.system:
        final brightness = MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
        themeData = brightness == Brightness.dark ? darkData : lightData;
    }
    final appColor = widget.color ?? themeData.primaryColor;
    final localizationsDelegates = _buildLocalizationsDelegates();

    if (_isRouter) {
      return WidgetsApp.router(
        key: GlobalObjectKey(this),
        color: appColor,
        title: widget.title,
        onGenerateTitle: widget.onGenerateTitle,
        debugShowCheckedModeBanner: false,
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
      debugShowCheckedModeBanner: false,
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

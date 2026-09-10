# LayrzApp — API Reference

Source: `lib/src/app/src/app.dart`
- `LayrzApp` class (imperative + `.router` constructors)
- `_LayrzAppScope` — internal `InheritedWidget` propagating `pageTransitionType`
- Companion: `lib/src/app/src/app_banner.dart` — `LayrzAppBanner`
- Companion: `lib/src/app/src/app_banner_painter.dart` — `LayrzAppBannerPainter`

---

## Examples

```dart
// Imperative routing
LayrzApp(
  home: const HomePage(),
  title: 'My App',
  theme: LayrzThemeData.light(),
)

// Declarative routing
LayrzApp.router(
  routerConfig: myRouter,
  title: 'My App',
  theme: LayrzThemeData.light(),
)

// Debug watermark with a custom label
LayrzApp(
  title: 'My Application',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  banner: const LayrzAppBanner(labelText: 'STAGING'),
)

// Opting out of the debug watermark entirely
LayrzApp(
  title: 'My Application',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  showDebugWatermark: false,
)

// Custom scroll behavior (opts out of the default themed scrollbar)
LayrzApp(
  title: 'My Application',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  scrollBehavior: const MyCustomScrollBehavior(),
)

// Reading the app-wide default transition for a router-based page
final transitionsBuilder = LayrzPageTransitions.resolve(LayrzApp.pageTransitionTypeOf(context));
```

---

## Constructor

```dart
// Imperative-routing constructor
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

// Declarative-routing constructor
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
```

No asserts on this constructor — the two forms are kept mutually exclusive purely by which fields each constructor initializes to `null`.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `home` | `Widget?` | `null` | The default route (`/`). Imperative constructor only. |
| `routes` | `Map<String, WidgetBuilder>?` | `null` | Named routes. Imperative constructor only. |
| `onGenerateRoute` | `RouteFactory?` | `null` | Generates a route for a given `RouteSettings`. Imperative constructor only. |
| `onUnknownRoute` | `RouteFactory?` | `null` | Called when no matching route is found. Imperative constructor only. |
| `navigatorObservers` | `List<NavigatorObserver>` | `[]` | Observers for the `Navigator`. Imperative constructor only. |
| `initialRoute` | `String?` | `null` | First route to show; defaults to `/`. Imperative constructor only. |
| `routerConfig` | `RouterConfig<Object>?` | `null` | Configures the `Router` widget. `.router` constructor only. |
| `routerDelegate` | `RouterDelegate<Object>?` | `null` | Provides a widget tree for the current `RouteInformation`. `.router` constructor only. |
| `routeInformationParser` | `RouteInformationParser<Object>?` | `null` | Restores `RouteInformation` from/to the platform. `.router` constructor only. |
| `routeInformationProvider` | `RouteInformationProvider?` | `null` | Provides `RouteInformation` to the `Router`. `.router` constructor only. |
| `backButtonDispatcher` | `BackButtonDispatcher?` | `null` | Handles the platform back button. `.router` constructor only. |
| `theme` | `LayrzThemeData?` | `LayrzThemeData.light()` | The light theme. Immutable once mounted. |
| `darkTheme` | `LayrzThemeData?` | `LayrzThemeData.dark()` | The (beta) dark theme, used only when `themeMode` resolves to dark. See Behavior notes. |
| `themeMode` | `LayrzThemeMode` | `.system` | Which of `theme`/`darkTheme` is active: `.light`, `.dark`, or `.system` (follows `MediaQuery.platformBrightness`). |
| `title` | `String` | `''` | One-line app description shown in the OS task switcher. |
| `onGenerateTitle` | `GenerateAppTitle?` | `null` | Generates a localized title; takes precedence over `title`. |
| `color` | `Color?` | `null` | Primary color surfaced to the host OS. Defaults to the effective theme's `primaryColor`. |
| `showSemanticsDebugger` | `bool` | `false` | Shows the semantics debugger overlay. |
| `debugShowWidgetInspector` | `bool` | `false` | Shows the widget inspector overlay. |
| `banner` | `LayrzAppBanner?` | `null` | Overrides the label/color of the automatic debug watermark. `null` means "use the automatic localized default," not "no watermark" — see `showDebugWatermark`. |
| `showDebugWatermark` | `bool` | `true` | Whether the debug-only watermark may render at all. Set `false` to opt out entirely (e.g. golden tests), even if `banner` is set. |
| `locale` | `Locale?` | `null` | Initial locale. Defaults to the system locale. |
| `localizationsDelegates` | `Iterable<LocalizationsDelegate<dynamic>>?` | `null` | Caller delegates; `LayrzUiL10nDelegate` is appended automatically if not already present. |
| `supportedLocales` | `Iterable<Locale>` | `[Locale('en')]` | Locales the app supports. |
| `localeListResolutionCallback` | `LocaleListResolutionCallback?` | `null` | Selects a locale from the device's preferred list. |
| `localeResolutionCallback` | `LocaleResolutionCallback?` | `null` | Selects a locale given one requested locale. |
| `builder` | `TransitionBuilder?` | `null` | Inserted between `WidgetsApp` and the route content; receives the resolved child. |
| `scrollBehavior` | `ScrollBehavior?` | `null` | Defaults to `LayrzScrollBehavior`, which installs `LayrzScrollbar` on pointer platforms. |
| `shortcuts` | `Map<ShortcutActivator, Intent>?` | `null` | Keyboard shortcut activators to `Intent`s. |
| `actions` | `Map<Type, Action<Intent>>?` | `null` | `Intent` types to `Action`s. |
| `restorationScopeId` | `String?` | `null` | State restoration identifier. |
| `pageTransitionType` | `LayrzTransitionType` | `.fade` | Default page transition. Real effect only on the imperative constructor (installed on every `PageRouteBuilder`); on `.router` it is only ambient state readable via `LayrzApp.pageTransitionTypeOf`. |
| `enableFindInPage` | `bool` | `true` | Installs `LayrzFindInPageHost` (Ctrl/Cmd+F). Opt-out, not opt-in. |

---

## Static members

| Member | Signature | Notes |
|---|---|---|
| `pageTransitionTypeOf` | `static LayrzTransitionType pageTransitionTypeOf(BuildContext context)` | Returns the nearest ancestor `LayrzApp`'s `pageTransitionType`, or `.fade` if no `LayrzApp` ancestor exists. Intended for router-based callers building their own route pages. |
| `buildLayrzUiL10nDelegates` | `@visibleForTesting List<LocalizationsDelegate<dynamic>> buildLayrzUiL10nDelegates(Iterable<LocalizationsDelegate<dynamic>>? userDelegates)` | Top-level helper (not a member of the class) merging caller delegates with the default `LayrzUiL10nDelegate`, without duplicating it. |

---

## Companion widgets

- **`LayrzAppBanner`** (`app_banner.dart`) — immutable config class for the debug watermark:
  - `labelText` (`String`, required) — text repeated across the tiled diagonal watermark.
  - `color` (`Color?`, default `null`) — watermark text color before the low-opacity alpha; falls back to `LayrzColorTokens.watermark` when `null`.
  - Provides `copyWith`, value `==`/`hashCode`. No style enum — tiled-diagonal is the only style.
- **`LayrzAppBannerPainter`** (`app_banner_painter.dart`) — the `CustomPainter` that actually draws the tiled watermark; not typically constructed directly by consumers.

---

## Behavior notes

- **Theme installation tree**: `LayrzApp` → `LayrzTheme` → `DefaultSelectionStyle` → `DefaultTextStyle` → `IconTheme` → `ColoredBox` (background) → `LayrzShortcut` → `LayrzSnackbarMessenger` → (`LayrzFindInPageHost` if enabled) → your content.
- **Watermark stacking**: in debug builds with an effective banner, a `Stack` overlays `LayrzAppBannerPainter` above the themed content via `Positioned.fill(IgnorePointer(ExcludeSemantics(CustomPaint(...))))` — it never intercepts input or appears in the semantics tree.
- **Dark mode / `themeMode` is a beta feature** (decision D78, which reopened D7's original light-only scope under DESIGN-204). `theme`/`darkTheme`/`themeMode`/`LayrzThemeMode` all exist and work in current source, but the design system's own documentation posture is still light-mode-first in most places, and a handful of components still hardcode light-only colors. Prefer omitting `darkTheme`/`themeMode` (light-only) unless the app has explicitly opted into the beta dark palette; never claim full dark-mode parity when writing consumer code or docs.
- **`WidgetsApp.debugShowCheckedModeBanner` is unconditionally `false`** on both internal `WidgetsApp`/`WidgetsApp.router` calls — there is no way to bring back the SDK's own corner banner.
- **`pageRouteBuilder`** (imperative constructor only) wraps every `home`/`routes`/`onGenerateRoute` route in a `PageRouteBuilder` using `LayrzPageTransitions.resolve(pageTransitionType)` and `themeData.tokens.motion.dPageTransition` as the transition duration.
- **Find-in-page idle cost is negligible** — `LayrzFindInPageHost` holds no `SemanticsHandle` until the user actually opens find, so leaving `enableFindInPage: true` (the default) costs nothing at rest.

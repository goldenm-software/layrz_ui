---
name: layrz-ui-app
description: Use LayrzApp in a layrz_ui Flutter app. Apply when bootstrapping the app root — imperative routing (LayrzApp) vs declarative routing (LayrzApp.router), theme installation, the debug watermark banner, find-in-page, or page-transition defaults.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.fade`, `.system`) — never the fully-qualified form (`LayrzTransitionType.fade`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The single root widget of every layrz_ui app — wraps `WidgetsApp`/`WidgetsApp.router` to install the theme, default text style, icon theme, background color, scroll behavior, and (by default) find-in-page.
- Use the **default constructor** (`LayrzApp(...)`) for imperative routing (`Navigator.push`, named `routes`, `onGenerateRoute`).
- Use **`LayrzApp.router(...)`** for declarative routing (go_router, auto_route, or any `RouterConfig`).
- Use `banner` (a `LayrzAppBanner`) to replace the SDK's red DEBUG corner banner with a tiled diagonal watermark — debug builds only, automatic even without setting it.
- **Do not use** `MaterialApp` or `CupertinoApp` anywhere — `LayrzApp` is the only app root allowed in this design system.
- **Do not use** for a nested navigation/content shell inside an already-running app — use `LayrzLayout` instead.

---

## Minimal usage

```dart
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      title: 'My Application',
      theme: LayrzThemeData.light(primaryColor: const Color(0xFF001E60)),
      home: const HomePage(),
    );
  }
}
```

---

## Key behaviors

- **Two constructors, mutually exclusive.** The default constructor accepts `home`/`routes`/`onGenerateRoute`/`onUnknownRoute`/`navigatorObservers`/`initialRoute`; `LayrzApp.router` accepts `routerConfig`/`routerDelegate`/`routeInformationParser`/`routeInformationProvider`/`backButtonDispatcher`. Each constructor nulls out the other's fields internally.
- **`theme` is immutable at runtime.** To change it, wrap `LayrzApp` in your own stateful widget that owns the theme and rebuilds `LayrzApp` with a new `LayrzThemeData`.
- **`debugShowCheckedModeBanner` is always forced to `false` internally** — `LayrzApp` never renders the SDK's own corner banner; `banner` + `showDebugWatermark` are the full replacement (debug builds only, no-op in profile/release regardless of value).
- **The debug watermark is automatic.** Even with `banner: null`, `LayrzApp` shows a localized watermark in debug builds unless `showDebugWatermark: false`. Passing a non-null `banner` only overrides its label/color.
- **Find-in-page ships on by default** (`enableFindInPage: true`) — Ctrl/Cmd+F opens a themed find bar over the current page. Set `enableFindInPage: false` to opt a build out.
- **`scrollBehavior` defaults to `LayrzScrollBehavior`**, which installs a themed scrollbar on pointer platforms automatically — passing your own `ScrollBehavior` opts out of that.
- **`pageTransitionType` only drives real page transitions on the imperative constructor.** On `LayrzApp.router`, there is no seam into a caller-supplied `RouterConfig`'s pages; read `LayrzApp.pageTransitionTypeOf(context)` and apply it to your own route builder.
- Localization always installs `LayrzUiL10nDelegate` — appended after any caller-supplied `localizationsDelegates`, never duplicated.

---

## Common patterns

```dart
// 1. Declarative routing (go_router)
LayrzApp.router(
  routerConfig: myRouter,
  title: 'My App',
  theme: LayrzThemeData.light(),
)

// 2. Debug/staging watermark
LayrzApp(
  title: 'My Application',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  banner: const LayrzAppBanner(labelText: 'STAGING'),
)

// 3. Opting out of find-in-page for a specific customer build
LayrzApp(
  title: 'My Application',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  enableFindInPage: false,
)

// 4. Reading the design system's default page transition from a go_router page
CustomTransitionPage(
  child: const DetailPage(),
  transitionsBuilder: LayrzPageTransitions.resolve(LayrzApp.pageTransitionTypeOf(context)),
)
```

---

## App setup conventions

- Exactly one `LayrzApp` (or `LayrzApp.router`) per app, at the root of `runApp(...)`.
- Never import `package:flutter/material.dart` or `package:flutter/cupertino.dart` in app setup — `LayrzApp` is built exclusively on `WidgetsApp`.
- Pass a real `theme: LayrzThemeData.light(primaryColor: ...)` rather than relying on the built-in default when the app has brand colors.
- Leave `banner`/`showDebugWatermark` at their defaults for normal development; only set `banner` explicitly to relabel the watermark (e.g. `'STAGING'`) for a specific build.
- Read colors/text styles from `context.theme` / `context.tokens` inside pages — never hardcode design values, even inside the `home`/route content that sits under `LayrzApp`.

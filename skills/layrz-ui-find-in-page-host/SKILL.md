---
name: layrz-ui-find-in-page-host
description: Use LayrzFindInPageHost in a layrz_ui Flutter app. Apply when the app needs browser-style Ctrl/Cmd+F find-in-page — installed automatically by LayrzApp (opt-out via `enableFindInPage: false`), reached via `LayrzFindInPageHost.of(context).controller` to drive open/close/search programmatically, e.g. from a custom "Find" menu item.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any `LayrzApp`-based app automatically gets Ctrl+F (Cmd+F on macOS) find-in-page with zero setup — `LayrzApp.enableFindInPage` defaults to `true`.
- Reach the running host to drive find programmatically — e.g. a "Find" menu item that opens the bar without the keyboard shortcut: `LayrzFindInPageHost.of(context).controller.open()`.
- **Do not use** to construct a `LayrzFindInPageHost` yourself in application code — `LayrzApp` installs exactly one automatically. Constructing a second one under an existing one is asserted against in debug and rendered inertly in release.
- **Do not use** for content painted directly via `CustomPainter` and expect it to be findable automatically — wrap it in `LayrzSearchable` first; find-in-page walks the semantics tree, not the render tree.
- **Do not use** this mechanism for navigation — opening find overlays the *current* page; it never pushes, pops, or touches a `Navigator`/router.

---

## Minimal usage

```dart
// LayrzApp already installs the host — this is all that's needed:
LayrzApp(
  title: 'My App',
  theme: LayrzThemeData.light(),
  home: const HomePage(),
  // enableFindInPage: true, // default — omit unless opting out
)
```

```dart
// Driving it programmatically from a menu item:
LayrzFindInPageHost.of(context).controller.open();
```

---

## Key behaviors

- **On by default, opt-out per app.** Set `LayrzApp.enableFindInPage: false` to disable the feature entirely for a specific app/build.
- **Idle cost is effectively zero.** The controller acquires a `SemanticsHandle` (the expensive part — it forces Flutter to build and maintain a full semantics tree app-wide) only between `open()` and `close()`, never for the app's whole lifetime.
- **Root-overlay painting.** Both the find bar and the highlight layer live in the app's root `Overlay`, not a page-local `Stack` — this is what lets highlight rects stay correct regardless of what chrome (sidebar, app bar) the current page sits behind.
- **Ancestry-resolved, no `GlobalKey`.** `LayrzFindInPageHost.of`/`.maybeOf` resolve via `InheritedWidget`, mirroring `LayrzShortcut.of` and `LayrzSnackbarMessenger.of`.
- **Graceful degradation.** The Ctrl/Cmd+F registration uses `LayrzShortcut.maybeOf`, not `.of` — a tree with no `LayrzShortcut` ancestor (a bare host under test) simply can't open find via keyboard, rather than crashing.
- **Two capture paths on web.** A `LayrzShortcut` registration (all platforms) plus, on web only, a browser-level JS `keydown` capture — without it, the browser's own native find dialog would open underneath this one.

---

## Common patterns

```dart
// 1. Opt out entirely for a customer build
LayrzApp(
  title: 'Embedded Kiosk',
  theme: LayrzThemeData.light(),
  home: const KioskHome(),
  enableFindInPage: false,
)

// 2. Custom "Find" menu item driving the host
LayrzButton(
  labelText: 'Find on page',
  onTap: () => LayrzFindInPageHost.of(context).controller.open(),
)

// 3. Making custom-painted content findable (paired with LayrzSearchable)
LayrzSearchable(
  text: 'Revenue by quarter',
  child: CustomPaint(painter: MyChartAxisLabelPainter()),
)
```

---

## Usage conventions

- Never construct `LayrzFindInPageHost` directly in application code — always reach the installed instance via `.of(context)`/`.maybeOf(context)`.
- Use `.maybeOf` (not `.of`) in any widget that must also work outside a `LayrzApp` subtree (a bare widget test, a Storybook-style preview).
- Wrap any `CustomPainter`-drawn text a user might reasonably search for in `LayrzSearchable` — plain `Text`/`RichText`/`LayrzTextInput`-backed content is already findable automatically and needs no wrapper.
- Remember opening find never navigates — don't build "find and jump to a different route" flows on top of this; it searches only what's already on screen.

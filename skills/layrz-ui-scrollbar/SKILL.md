---
name: layrz-ui-scrollbar
description: Use LayrzScrollbar in a layrz_ui Flutter widget. Apply when wrapping a scrollable with visible scroll feedback — always-visible rounded thumb, hover-revealed track, or the app-wide LayrzScrollBehavior that installs it automatically on desktop.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. This widget has no enum parameters of its own.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Wrapping any scrollable (`ListView`, `SingleChildScrollView`, `CustomScrollView`) that needs visible scroll feedback on desktop/pointer platforms.
- In most cases you don't need to reach for this directly — `LayrzApp` installs `LayrzScrollBehavior` by default, which wraps every vertical scrollable automatically.
- Use `LayrzScrollbar` explicitly only when a scrollable's controller isn't the app's `PrimaryScrollController` and you want an explicit, correctly-wired scrollbar around it.
- **Do not use** for horizontal scrollables — `LayrzScrollBehavior` (the default app-wide installer) only decorates vertical ones; horizontal scroll relies on native/no feedback.
- **Do not use** on touch platforms expecting it to show — both `LayrzScrollbar` (via `LayrzScrollBehavior`'s platform gate) and native scroll feedback take over there; the persistent thumb is a desktop/pointer-platform affordance.

---

## Minimal usage

```dart
// Usually nothing to do — LayrzApp installs LayrzScrollBehavior by default.
LayrzApp(
  home: ListView(children: [...]), // gets a LayrzScrollbar automatically
)
```

---

## Key behaviors

- `LayrzScrollbar` is a `StatefulWidget` — the thumb color shifts on hover (`tokens.colors.fg4` at rest, `tokens.colors.fg3` on hover) and the track (`tokens.colors.sf3`) is invisible until hover, tracked via an internal `MouseRegion`. These colors are **not** caller-configurable — there is no `thumbColor`/`trackColor` parameter.
- The constructor takes only `child` (required) and `controller` (optional) — no `thickness`, `radius`, or visibility parameters are exposed; those are fixed constants (`kLayrzScrollbarThickness`, `kLayrzScrollbarRadius`).
- `controller` should be the **same** `ScrollController` attached to the wrapped scrollable's `Scrollable` widget. When `null`, it falls back to `PrimaryScrollController`.
- `LayrzScrollBehavior` (the app-wide installer) gates on **platform** (`windows`/`linux`/`macOS` only — Android/iOS/fuchsia get no persistent scrollbar) **and** on **axis** (vertical only).

---

## Common patterns

```dart
// 1. Explicit wrap with a matching controller
final scrollController = ScrollController();

LayrzScrollbar(
  controller: scrollController,
  child: ListView(
    controller: scrollController,
    children: [...],
  ),
)

// 2. Opting out app-wide
LayrzApp(
  scrollBehavior: const ScrollBehavior(), // disables LayrzScrollBehavior entirely
  home: MyHome(),
)

// 3. Opting out for one subtree only
ScrollConfiguration(
  behavior: const ScrollBehavior(),
  child: ListView(children: [...]), // no scrollbar here
)

// 4. Re-asserting the default explicitly (redundant under LayrzApp, but valid)
ScrollConfiguration(
  behavior: const LayrzScrollBehavior(),
  child: ListView(children: [...]),
)
```

---

## Pitfalls

- **Don't try to pass `thumbColor`/`trackColor`/`thickness`/`radius`** — the current constructor exposes only `child` and `controller`. Any wiki text or older reference implying otherwise is stale; those visuals are fixed constants in `constants/src/scrollbar.dart`.
- **A mismatched `controller`** (not the same instance attached to the scrollable) silently produces a scrollbar that doesn't track the actual scroll position — always pass the identical `ScrollController` to both the scrollbar and its scrollable.
- **Don't expect a persistent scrollbar on iOS/Android** — `LayrzScrollBehavior` deliberately returns the plain `child` unchanged on touch platforms; native scroll feedback takes precedence there by design, not by omission.
- **Don't wrap a horizontal scrollable expecting the same treatment** — `LayrzScrollBehavior` only decorates vertical `Scrollable`s; a horizontal one always renders unchanged regardless of platform.
- **Disabling scrollbars app-wide via `scrollBehavior: ScrollBehavior()` also removes any other `LayrzScrollBehavior` customization** — if you only want to change one screen, use a local `ScrollConfiguration` instead of the app-wide `LayrzApp.scrollBehavior` override.

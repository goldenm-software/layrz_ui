---
name: layrz-ui-refresh-indicator
description: Use LayrzRefreshIndicator in a layrz_ui Flutter widget. Apply when reporting a refresh lifecycle above a scrollable region — LayrzRefreshController.refresh() as the primary programmatic entry point, an optional touch drag-to-refresh gesture, or the pointer-only fallback button via fallbackButtonMode.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.auto`, `.refreshing`) — never the fully-qualified form (`LayrzRefreshFallbackButtonMode.auto`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any scrollable region that needs a "refresh this data" affordance and loading indicator, on desktop or touch.
- **The programmatic path is primary, not the drag gesture** — `layrz_ui` is desktop-first. Drive `LayrzRefreshController.refresh(...)` from a button, a keyboard shortcut, or any app logic; the drag gesture is one of three ways into the same call.
- Use `controller` to trigger a refresh from outside the widget (e.g. a toolbar "Refresh" button next to the scrollable).
- **Do not use** as a pull-to-refresh-only widget expecting the drag gesture alone to work on desktop — a mouse/trackpad user cannot produce the required drag; rely on the programmatic path or the built-in fallback button (`fallbackButtonMode`) instead.
- **Do not use** for a full-page blocking loading state — this is a lightweight floating indicator over a scrollable; use a dedicated loading view/overlay for full-page loading instead.

---

## Minimal usage

```dart
final controller = LayrzRefreshController();

LayrzRefreshIndicator(
  controller: controller,
  onRefresh: () async => api.reloadData(),
  child: ListView(children: [...]),
)

// Elsewhere — a button drives the exact same loading affordance, no drag at all:
LayrzButton(
  labelText: 'Refresh',
  onTap: () => controller.refresh(() => api.reloadData()),
)
```

---

## Key behaviors

- State machine: `idle → armed → refreshing → settling → idle`. A programmatic `refresh()` call skips `armed` entirely (no drag distance to arm past) and goes straight `idle → refreshing`.
- `LayrzRefreshController.refresh(onRefresh)` is a no-op if a refresh is already in progress — always safe to call from a button's `onTap` with no manual guard.
- `enableDragGesture` (default `true`) wires up `LayrzRefreshGestureDetector`, which watches for real finger/pointer drag overscroll — never a mouse-wheel bounce or ballistic overscroll. Set `false` when a drag gesture would conflict with another gesture already on `child`.
- **`fallbackButtonMode` (default `.auto`) floats a built-in "Refresh" button** for pointer-only sessions that can't produce a drag — shown automatically whenever `LayrzPlatform.isTouchOS` is `false`. Force it with `.enabled`/`.disabled` when the automatic OS-based read doesn't fit your surface.
- Lifecycle mirrors `LayrzStepper`: `controller: null` means the widget creates and disposes its own; non-null means caller-owned disposal, and swapping the instance on rebuild asserts.
- The indicator floats over `child` in a `Stack` — `child` is never resized or pushed down; the reveal/retract is an opacity fade honoring reduce-motion.
- `refresh()` rethrows any error from `onRefresh` after settling, so an awaiting caller still observes failure — wrap the call in your own try/catch if you need to show an error state.

---

## Common patterns

```dart
// 1. Drag-only surface (no fallback button, e.g. embedded panel)
LayrzRefreshIndicator(
  onRefresh: () async => api.reload(),
  fallbackButtonMode: .disabled,
  child: ListView(children: [...]),
)

// 2. Programmatic-only (no drag gesture, e.g. a fixed-height panel)
LayrzRefreshIndicator(
  controller: controller,
  onRefresh: () async => api.reload(),
  enableDragGesture: false,
  child: ListView(children: [...]),
)

// 3. Disabling the toolbar refresh button while a refresh is running
AnimatedBuilder(
  animation: controller,
  builder: (context, _) => LayrzButton(
    labelText: 'Refresh',
    isDisabled: controller.isRefreshing,
    onTap: () => controller.refresh(() => api.reload()),
  ),
)

// 4. Custom trigger distance and indicator size
LayrzRefreshIndicator(
  onRefresh: () async => api.reload(),
  triggerDistance: 120,
  indicatorSize: 40,
  child: ListView(children: [...]),
)
```

---

## Usage conventions

- Keep a `LayrzRefreshController` in a `State` field (not inline in `build()`) whenever any external widget (a toolbar button) also needs to trigger `refresh()`.
- Await `controller.refresh(...)` from external triggers so you can show a snackbar or error state on completion/failure — it returns the same `Future` `onRefresh` returns.
- Leave `fallbackButtonMode` at `.auto` unless you have a specific reason to override it — it already handles the desktop/mobile-web distinction correctly (including mobile web, which still reports as touch OS).
- Don't call `controller.settle()` yourself — it's driven by the indicator's own retraction animation; call `refresh()` and let the widget manage the rest of the lifecycle.

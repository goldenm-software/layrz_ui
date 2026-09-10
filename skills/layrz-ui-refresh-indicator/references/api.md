# LayrzRefreshIndicator — API Reference

Source: `lib/src/refresh/src/`
- `LayrzRefreshIndicator` class — `refresh_indicator.dart`
- `LayrzRefreshGestureDetector` class — `refresh_gesture_detector.dart`
- `LayrzRefreshController` class — `refresh_controller.dart`
- `LayrzRefreshState` enum — `refresh_state.dart`
- `LayrzRefreshVisual` class — `refresh_visual.dart`
- `LayrzRefreshFallbackButtonMode` enum — `refresh_fallback_button_mode.dart`

> **Note on the wiki page** (`wiki/Widgets/LayrzRefreshIndicator.md`): it does not mention `fallbackButtonMode`/`LayrzRefreshFallbackButtonMode` at all. The shipped source has a third refresh entry point — a built-in floating "Refresh" button for pointer-only sessions — governed by this parameter. This reference follows the source, per this skill's authoring rule that code wins.

---

## Examples

```dart
// Basic usage with an external controller
final controller = LayrzRefreshController();

LayrzRefreshIndicator(
  controller: controller,
  onRefresh: () async => api.reloadData(),
  child: ListView(children: [...]),
)

// Programmatic-only trigger from a button, no drag at all
LayrzButton(
  labelText: 'Refresh',
  onTap: () => controller.refresh(() => api.reloadData()),
)

// Disable the drag gesture (programmatic + fallback button only)
LayrzRefreshIndicator(
  onRefresh: () async => api.reloadData(),
  enableDragGesture: false,
  child: ListView(children: [...]),
)

// Force the fallback button on for a pointer-driven touch-OS surface
LayrzRefreshIndicator(
  onRefresh: () async => api.reloadData(),
  fallbackButtonMode: .enabled,
  child: ListView(children: [...]),
)
```

---

## Constructor — `LayrzRefreshIndicator`

```dart
const LayrzRefreshIndicator({
  required this.onRefresh,
  required this.child,
  this.controller,
  this.enableDragGesture = true,
  this.triggerDistance = 80.0,
  this.indicatorSize = 32.0,
  this.fallbackButtonMode = LayrzRefreshFallbackButtonMode.auto,
  super.key,
});
```

---

## Properties — `LayrzRefreshIndicator`

| Property | Type | Default | Notes |
|---|---|---|---|
| `onRefresh` | `Future<void> Function()` | — | Required. Called by every trigger path (controller, drag, fallback button). Awaited before settling. |
| `child` | `Widget` | — | Required. The scrollable content the indicator floats above. |
| `controller` | `LayrzRefreshController?` | `null` | `null` means the widget creates, owns, and disposes its own. Non-`null` means caller-owned disposal; swapping the instance on rebuild asserts. |
| `enableDragGesture` | `bool` | `true` | `false` exposes only the programmatic (and fallback-button) paths. |
| `triggerDistance` | `double` | `80.0` | How far (logical px) a drag must travel past the top before release commits to a refresh. Ignored when `enableDragGesture` is `false`. |
| `indicatorSize` | `double` | `32.0` | Diameter of the loading visual (and the fallback button's loading state). |
| `fallbackButtonMode` | `LayrzRefreshFallbackButtonMode` | `LayrzRefreshFallbackButtonMode.auto` | Governs the built-in pointer-only fallback "Refresh" button. See enum table below. |

---

## `LayrzRefreshController extends ChangeNotifier`

The source of truth; the widget is a thin renderer subscribing via `addListener`.

| Member | Signature | Notes |
|---|---|---|
| `state` | `LayrzRefreshState get` | Current lifecycle state. |
| `dragProgress` | `double get` | `[0.0, 1.0]`, how far a drag has advanced toward `triggerDistance`. Stays `0.0` throughout a programmatic-only refresh. |
| `isRefreshing` | `bool get` | `true` for `.refreshing`/`.settling`, `false` for `.idle`/`.armed`. Useful for disabling an external refresh button. |
| `refresh(Future<void> Function() onRefresh)` | `Future<void>` | **Primary public API.** No-op if already refreshing. Rethrows any `onRefresh` error after settling. Returns the same `Future` `onRefresh` returns. |
| `settle()` | `void` | Called by the retraction animation on completion — not typically called by application code directly. No-op unless `state == .settling`. |
| `updateDragProgress(double progress)` | `void` | Backing call for the gesture layer. Ignored once a refresh has committed (`.refreshing` or later). |
| `releaseDrag(Future<void> Function() onRefresh)` | `Future<void>` | Backing call for the gesture layer's pointer-up. Commits to `refresh` if `.armed`, otherwise resets `dragProgress` to `0.0`. |

---

## `LayrzRefreshState` enum

| Value | Description |
|---|---|
| `.idle` | No refresh in progress, indicator fully retracted and invisible. |
| `.armed` | Drag crossed the trigger threshold, pointer not yet released. Never reached by the programmatic `refresh()` path. |
| `.refreshing` | The caller's `Future` is in flight; indicator shows its loading spinner and announces to assistive tech. |
| `.settling` | The `Future` resolved (or threw); indicator animates back to retracted. Auto-transitions to `.idle` on completion. |

---

## `LayrzRefreshGestureDetector`

Wired internally by `LayrzRefreshIndicator` when `enableDragGesture` is `true` — rarely constructed directly.

```dart
const LayrzRefreshGestureDetector({
  required this.controller,
  required this.onRefresh,
  required this.child,
  this.triggerDistance = 80.0,
  super.key,
});
```

| Property | Type | Notes |
|---|---|---|
| `controller` | `LayrzRefreshController` | Required. Drives `updateDragProgress`/`releaseDrag` as the user drags. |
| `onRefresh` | `Future<void> Function()` | Required. Passed through to `controller.releaseDrag`. |
| `child` | `Widget` | Required. Must contain a `Scrollable` descendant for overscroll notifications to dispatch. |
| `triggerDistance` | `double` | Default `80.0`. `dragProgress = overscroll / triggerDistance`, clamped `[0.0, 1.0]`. |

Watches `OverscrollNotification`s carrying real `DragUpdateDetails` at the top of the scroll extent. Does **not** install or modify any `ScrollPhysics`/`ScrollBehavior` — a local `NotificationListener<ScrollNotification>` is enough.

---

## `LayrzRefreshVisual`

The loading visual painted by `LayrzRefreshIndicator` (and reused, unadorned, by the fallback button's own loading state).

```dart
const LayrzRefreshVisual({
  required this.state,
  required this.dragProgress,
  this.size = 32.0,
  super.key,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `state` | `LayrzRefreshState` | — | Required. Drives which painting mode: a fill-in-proportion ring pre-trigger, or a rotating indeterminate arc once refreshing/settling. |
| `dragProgress` | `double` | — | Required. Only used while `.idle`/`.armed`; ignored once committed. |
| `size` | `double` | `32.0` | Diameter of the visual. |

Built independently of `LayrzProgressBar` — ships a ring shape rather than a bar, with its own `CustomPainter`.

---

## `LayrzRefreshFallbackButtonMode` enum

| Value | Description |
|---|---|
| `.auto` | Shows the button exactly when `LayrzPlatform.isTouchOS` is `false` — the default; no application code has to remember to wire up its own fallback. |
| `.enabled` | Always shows the button, regardless of `LayrzPlatform.isTouchOS`. Use for a surface known to be pointer-driven even on a touch OS. |
| `.disabled` | Never shows the button. Use when the caller supplies its own refresh affordance elsewhere. |

`.auto` is a static, one-shot OS check (not a live capability signal) — it never changes after app start, so there's no listener to install/tear down. Mobile web still correctly gets pull-only behavior, since Android/iOS browsers report their native `TargetPlatform` from `defaultTargetPlatform`.

---

## Behavior notes

- **Three entry points, one controller call**: `LayrzRefreshController.refresh()` (button/shortcut/app logic), the optional drag gesture (`LayrzRefreshGestureDetector`), and the optional fallback button — all funnel into the exact same `refresh(onRefresh)` call and state machine.
- **v1 has no resistance/overscroll physics** — `dragProgress` is a linear mapping of drag distance to `triggerDistance`.
- **Reduce-motion**: checked on every build via `MediaQuery.disableAnimationsOf` — an OS setting change mid-refresh is honored immediately; reveal/retract animations jump straight to end values, and the spin controller stops ticking.
- **Accessibility**: `LayrzRefreshVisual` sets `liveRegion: true` and announces `'Refreshing'` while spinning, `null` otherwise; wrapped with `container: true` so its label/live-region doesn't merge with an ancestor node (relevant since the fallback button can float a second `LayrzRefreshVisual` alongside the pull indicator).
- **Layout**: the indicator lives in a `Stack` with `StackFit.passthrough` — `child` is the sole non-positioned child and determines the stack's size; the indicator and fallback button float as `Positioned` overlays and never resize or displace `child`.

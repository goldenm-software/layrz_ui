# LayrzScrollbar — API Reference

Source: `lib/src/scrollbar/src/`
- `LayrzScrollbar` class — `scrollbar.dart`
- `LayrzScrollBehavior` class — `scroll_behavior.dart`

Constants: `lib/src/constants/src/scrollbar.dart` — `kLayrzScrollbarThickness`, `kLayrzScrollbarRadius`, `kLayrzScrollbarCrossAxisMargin`, `kLayrzScrollbarMainAxisMargin`.

> **Note on the wiki page** (`wiki/Widgets/LayrzScrollbar.md`): it documents `LayrzScrollbar` as a `StatelessWidget` with caller-configurable `thumbColor`/`trackColor`/`thickness`/`radius`/`trackVisibility` parameters. **The actual shipped source is a `StatefulWidget` with a much smaller surface** (`child` + optional `controller` only) and hover-driven internal color state. This reference follows the source, per this skill's authoring rule that code wins.

---

## Examples

```dart
// Wrap a scrollable directly
LayrzScrollbar(
  controller: _scrollController,
  child: ListView(
    controller: _scrollController,
    children: [...],
  ),
)

// Fall back to PrimaryScrollController (no explicit controller)
LayrzScrollbar(
  child: SingleChildScrollView(
    child: MyContent(),
  ),
)

// App-wide default (no code needed beyond LayrzApp itself)
LayrzApp(
  home: LayrzLayout(
    body: ListView(children: [...]), // gets a LayrzScrollbar via LayrzScrollBehavior
  ),
)

// Per-subtree opt-out
ScrollConfiguration(
  behavior: const ScrollBehavior(),
  child: SingleChildScrollView(child: MyContent()), // no scrollbar
)
```

---

## Constructor — `LayrzScrollbar`

```dart
const LayrzScrollbar({
  required this.child,
  this.controller,
  super.key,
});
```

---

## Properties — `LayrzScrollbar`

| Property | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | — | Required. The scrollable widget to decorate (typically `SingleChildScrollView`, `ListView`, or `CustomScrollView`). |
| `controller` | `ScrollController?` | `null` | Should be the same controller attached to `child`'s own `Scrollable`. `null` falls back to `PrimaryScrollController`. |

No other constructor parameters exist. Visual constants (not caller-configurable): thickness `kLayrzScrollbarThickness = 8.0`; radius `kLayrzScrollbarRadius = Radius.circular(4.0)`; `crossAxisMargin`/`mainAxisMargin = 0.0`.

---

## `LayrzScrollBehavior` class

```dart
const LayrzScrollBehavior();
```

Extends `ScrollBehavior`, overrides `buildScrollbar(BuildContext, Widget, ScrollableDetails)`:

- Gated on **platform**: only `TargetPlatform.windows`, `.linux`, `.macOS` get a `LayrzScrollbar`. `.android`, `.iOS`, `.fuchsia` return `child` unchanged (native scroll feedback).
- Gated on **axis**: only vertical (`AxisDirection.down`/`.up`) scrollables are wrapped. Horizontal scrollables return `child` unchanged regardless of platform.
- When both gates pass, wraps `child` in `LayrzScrollbar(controller: details.controller, child: child)`.

Installed by default inside `LayrzApp` (no `scrollBehavior` parameter needed). Pass `scrollBehavior: const ScrollBehavior()` to `LayrzApp` to disable app-wide, or wrap a subtree in `ScrollConfiguration(behavior: const ScrollBehavior(), child: ...)` to disable locally.

---

## Behavior notes

- **Hover-driven color**: `_LayrzScrollbarState` tracks hover via `MouseRegion.onEnter`/`onExit`. Thumb color is `tokens.colors.fg3` while hovering, `tokens.colors.fg4` at rest. Track color is always `tokens.colors.sf3`, but `trackVisibility` (passed to the underlying `RawScrollbar`) is only `true` while hovering — the track is invisible at rest.
- **Thumb is always visible** (`thumbVisibility: true` on the underlying `RawScrollbar`), regardless of hover — only the track toggles.
- **Built on `RawScrollbar`** (`package:flutter/widgets.dart`) — no Material dependency.
- **Platform-specific behavior**: desktop (Linux/Windows/macOS) and web get the persistent thumb; mobile (iOS/Android) relies on native scroll feedback via `LayrzScrollBehavior`'s platform gate.

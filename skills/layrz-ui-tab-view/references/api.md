# LayrzTabView — API Reference

Source: `lib/src/tabs/src/tab_view.dart`
- `LayrzTabView` class
- `_LayrzTabPill` — internal per-tab pill widget (not exported)
- Companion: `tab.dart` — `LayrzTab` (see the dedicated `layrz-ui-tab` skill)

---

## Examples

```dart
// Scrollable strip (default)
LayrzTabView(
  tabs: [
    LayrzTab(labelText: 'Overview', child: OverviewPane()),
    LayrzTab(labelText: 'Details', child: DetailsPane()),
  ],
)

// Expanded (evenly distributed), no scrolling
LayrzTabView(
  isScrollable: false,
  tabs: [
    LayrzTab(labelText: 'Palette', child: PalettePicker()),
    LayrzTab(labelText: 'Wheel', child: WheelPicker()),
  ],
)

// initialIndex + onTabChanged
LayrzTabView(
  initialIndex: 1,
  onTabChanged: (index) => debugPrint('Active tab: $index'),
  tabs: tabs,
)

// Padding around the strip, zero content gap
LayrzTabView(
  padding: const EdgeInsets.all(8),
  contentGap: 0,
  tabs: tabs,
)
```

---

## Constructor

```dart
LayrzTabView({
  super.key,
  required this.tabs,
  this.initialIndex = 0,
  this.onTabChanged,
  this.isScrollable = true,
  this.padding,
  this.contentGap,
}) : assert(tabs.isNotEmpty, 'LayrzTabView needs at least one tab.');
```

Note: this is a non-`const` constructor (the assert on a runtime-evaluated `tabs.isNotEmpty` prevents `const`).

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `tabs` | `List<LayrzTab>` | required | Must be non-empty — asserted. |
| `initialIndex` | `int` | `0` | Clamped into `[0, tabs.length - 1]`, never throws. No effect after first build. |
| `onTabChanged` | `ValueChanged<int>?` | `null` | Fires only on a user tap on a non-selected tab. |
| `isScrollable` | `bool` | `true` | `true`: content-sized pills in a start-aligned scrollable row. `false`: pills share width evenly via `Expanded`, no scrolling. |
| `padding` | `EdgeInsets?` | `null` | Applied around the tab strip. `null` ⇒ no padding. |
| `contentGap` | `double?` | `null` (→ `tokens.spacing.sp3`) | Vertical gap between strip and content. Pass `0` to butt content against the strip. |

---

## Styling reference (read-only — not configurable per instance)

| State | Fill | Notes |
|---|---|---|
| Idle | `tokens.colors.sf1` | Opaque |
| Selected | `tokens.colors.primary` | |
| Hover (unselected) | `tokens.colors.sf3` | |
| Pressed (unselected) | `tokens.colors.sf4` | |

- Corner radius: `tokens.radius.br2`
- Minimum pill height: `kLayrzButtonHeight` (45px)
- Horizontal padding: `tokens.spacing.sp3` (matches `LayrzButton`)
- Label font size: `kLayrzButtonFontSize` (14px); weight `w600` selected, `w400` idle
- Leading/trailing icon size: `kLayrzButtonIconSize` (22px)
- Label color: selected uses a luminance check against the fill (`fg1` if light, `sf1` if dark); unselected uses `fg1` while keyboard-focused, `fg2` otherwise
- Gap between leading/label/trailing and between adjacent pills: `tokens.spacing.sp2`

---

## Companion widgets

- **`LayrzTab`** — the per-tab descriptor consumed by `tabs`. See the dedicated `layrz-ui-tab` skill and its `references/api.md`.

---

## Behavior notes

- **Selection is internal `State`** — `_selectedIndex`, initialized from `initialIndex.clamp(...)` in `initState`, re-clamped in `didUpdateWidget` if the tab list shrinks below the current index.
- **Tap handling**: `_handleTap` is a no-op if the tapped index is already selected; otherwise it calls `setState` and then `onTabChanged?.call(index)` — in that order, so the rebuild is already scheduled before the callback runs.
- **Pill semantics**: each pill is `Semantics(button: true, selected: ..., label: tab.labelText, onTap: ..., excludeSemantics: true)`, wrapped in `SelectionContainer.disabled` (labels are not drag-selectable body text) and `Focus` for keyboard focus tracking.
- **Interaction states vary color only, never geometry (D15)** — height, padding, and corner radius are byte-identical across idle/hover/press/selected.
- **Light mode only**, consistent with the rest of layrz_ui (decision D7).

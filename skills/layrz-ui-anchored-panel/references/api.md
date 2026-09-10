# LayrzAnchoredPanel — API Reference

Source: `lib/src/overlays/src/anchored_panel.dart` (widget), `anchored_panel_layout_delegate.dart` (positioning + width/alignment enums), `anchored_panel_border.dart` (border descriptor). Side vocabulary (`LayrzPreferredSide`) lives in `lib/src/positioning/src/preferred_side.dart`, shared with `LayrzTooltip`.

- `LayrzAnchoredPanel` class — `anchored_panel.dart` line 55
- `LayrzAnchoredPanelBuilder` typedef — `anchored_panel.dart` line 12
- `LayrzAnchoredPanelLayoutDelegate` class — `anchored_panel_layout_delegate.dart` line 70
- `LayrzAnchoredPanelWidthPolicy` enum — `anchored_panel_layout_delegate.dart` line 9
- `LayrzAnchoredPanelWidthBounds` class — `anchored_panel_layout_delegate.dart` line 21
- `LayrzAnchoredPanelAlignment` enum — `anchored_panel_layout_delegate.dart` line 318
- `LayrzAnchoredPanelBorder` class — `anchored_panel_border.dart` line 21
- `LayrzPreferredSide` enum — `lib/src/positioning/src/preferred_side.dart` line 6

---

## Examples

```dart
// Basic input-style panel (match anchor width)
LayrzAnchoredPanel(
  builder: (context, controller) => LayrzTextInput(
    value: selectedValue,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: options.map((option) => _buildOption(option)).toList(),
  ),
)

// Icon button with content-sized panel
LayrzAnchoredPanel(
  widthPolicy: .contentSized,
  widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 150, maxWidth: 250),
  builder: (context, controller) => LayrzButton(
    labelText: 'More',
    icon: MdiIcons.dotsVertical,
    style: .filledFab,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: Column(mainAxisSize: MainAxisSize.min, children: [_MenuItem('Edit'), _MenuItem('Delete')]),
)

// Scrollable content with max height
LayrzAnchoredPanel(
  maxHeight: 300,
  builder: (context, controller) => LayrzButton(
    labelText: 'Select',
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: Column(children: largeList.map(_buildItem).toList()),
)

// Cover-anchor ("elevated field") mode
LayrzAnchoredPanel(
  coverAnchor: true,
  builder: (context, controller) => LayrzTextInput(
    value: value,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: _buildOptionList(),
)

// Bordered panel echoing an error state
LayrzAnchoredPanel(
  border: LayrzAnchoredPanelBorder(
    color: context.tokens.colors.danger,
    width: context.tokens.border.base,
  ),
  builder: (context, controller) => trigger,
  child: content,
)

// External controller
final panelController = MenuController();
LayrzAnchoredPanel(
  controller: panelController,
  builder: (context, _) => LayrzButton(labelText: 'Trigger', onTap: panelController.open),
  child: _buildPanelContent(),
);
panelController.open();
panelController.close();
```

---

## Constructor

```dart
const LayrzAnchoredPanel({
  required this.builder,
  required this.child,
  this.widthPolicy = LayrzAnchoredPanelWidthPolicy.matchAnchor,
  this.widthBounds = const LayrzAnchoredPanelWidthBounds(minWidth: 160.0, maxWidth: 320.0),
  this.maxHeight,
  this.gap = 4.0,
  this.alignment = LayrzAnchoredPanelAlignment.start,
  this.preferredSide = LayrzPreferredSide.bottom,
  this.controller,
  this.onOpen,
  this.onClose,
  this.childFocusNode,
  this.onFlipped,
  this.panelSemanticLabel,
  this.coverAnchor = false,
  this.minHeight,
  this.border,
  super.key,
});
```

```dart
typedef LayrzAnchoredPanelBuilder = Widget Function(
  BuildContext context,
  MenuController controller,
);
```

```dart
const LayrzAnchoredPanelWidthBounds({
  required this.minWidth,
  required this.maxWidth,
}) : assert(minWidth > 0),
     assert(maxWidth > 0),
     assert(maxWidth >= minWidth);
```

```dart
const LayrzAnchoredPanelBorder({
  required this.color,
  required this.width,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `builder` | `LayrzAnchoredPanelBuilder` | required | Builds the anchor/trigger with access to the `MenuController`; wire it directly (`onTap: controller.isOpen ? controller.close : controller.open`). |
| `child` | `Widget` | required | Panel content. Constrained by `maxHeight`/overlay bounds and wrapped in a `SingleChildScrollView` — content taller than the constraint scrolls. |
| `widthPolicy` | `LayrzAnchoredPanelWidthPolicy` | `.matchAnchor` | `.matchAnchor` = width equals anchor width. `.contentSized` = width sized to content, clamped to `widthBounds`. |
| `widthBounds` | `LayrzAnchoredPanelWidthBounds` | `minWidth: 160.0, maxWidth: 320.0` | Only used when `widthPolicy` is `.contentSized`. |
| `maxHeight` | `double?` | `null` | Maximum content height in logical pixels. `null` constrains only by overlay bounds minus padding. |
| `gap` | `double` | `4.0` | Space between anchor and panel on the perpendicular axis. Ignored when `coverAnchor` is `true`. |
| `alignment` | `LayrzAnchoredPanelAlignment` | `.start` | Cross-axis alignment relative to the resolved side; clamped into overlay bounds. |
| `preferredSide` | `LayrzPreferredSide` | `.bottom` | Side of the anchor the panel prefers. Flips unconditionally to the opposite side if it doesn't fit — no second fit test. Ignored when `coverAnchor` is `true`. |
| `controller` | `MenuController?` | `null` | External programmatic control. `null` = panel owns its own. **Must never be swapped** for a different non-null instance across rebuilds — debug-only `assert` guard; in **release**, a swap is silently ignored (original controller stays in effect), by deliberate design (see Behavior notes). |
| `onOpen` | `VoidCallback?` | `null` | Fires before the overlay is shown. |
| `onClose` | `VoidCallback?` | `null` | Fires after the panel is removed from the overlay. |
| `childFocusNode` | `FocusNode?` | `null` | Passed to the anchor for keyboard interaction; focus returns here when the panel closes. Caller keeps it alive for the panel's lifetime. |
| `onFlipped` | `void Function(bool flippedUp)?` | `null` | Reports `true` when the panel landed opposite `preferredSide`, `false` when it landed on `preferredSide`. For `.bottom` this is exactly "above"/"below". Never invoked when `coverAnchor` is `true`. |
| `panelSemanticLabel` | `String?` | `null` | When set, wraps the panel overlay in a `Semantics` node with this label. Must be caller-supplied for localization. `null` adds no label. |
| `coverAnchor` | `bool` | `false` | `true` positions the panel directly over the anchor (same top-left corner, clamped into overlay bounds) instead of on `preferredSide` — `preferredSide`/`gap` are ignored and `onFlipped` never fires. The "elevated field" illusion when paired with `.matchAnchor`. |
| `minHeight` | `double?` | `null` | Floor for the panel's content height, clamped so it never exceeds the computed maximum (`maxHeight`/overlay bounds). `null` = no floor beyond content and `maxHeight`. |
| `border` | `LayrzAnchoredPanelBorder?` | `null` | Optional border painted around the panel's own decorated box (the box clamped to `maxHeight`), not around `child`. `null` paints no border. Painted with `strokeAlign: BorderSide.strokeAlignOutside` so it never changes occupied geometry (D15). |

### `LayrzAnchoredPanelWidthBounds`

| Property | Type | Notes |
|---|---|---|
| `minWidth` | `double` | Required, must be > 0. Panel never narrower than this. |
| `maxWidth` | `double` | Required, must be > 0 and ≥ `minWidth`. Panel never wider than this. |

### `LayrzAnchoredPanelBorder`

| Property | Type | Notes |
|---|---|---|
| `color` | `Color` | Required. Typically a semantic token, e.g. `tokens.colors.primary` (focus) or `tokens.colors.danger` (error). |
| `width` | `double` | Required. Typically `tokens.border.base`. Extends outward (`strokeAlignOutside`) — never changes panel size. |

`copyWith({Color? color, double? width})` returns a modified copy. Implements value equality (`==`/`hashCode`) and a descriptive `toString()`.

---

## `LayrzAnchoredPanelWidthPolicy` enum

| Value | Description |
|---|---|
| `.matchAnchor` | Panel width exactly equals the anchor widget's width. Default; suitable for input fields. |
| `.contentSized` | Panel width sized to content, clamped to `[widthBounds.minWidth, widthBounds.maxWidth]`. Suitable for icon buttons or small anchors. |

Both policies are further clamped to the space actually available in the overlay.

## `LayrzAnchoredPanelAlignment` enum

The cross axis is horizontal when the panel is above/below the anchor, vertical when left/right — the same axis-relative convention as `CrossAxisAlignment`.

| Value | Description |
|---|---|
| `.start` | Leading cross-axis edge aligns with the anchor's leading edge (left on a vertical side, top on a horizontal side). Not yet `Directionality`-aware — always means the left edge regardless of text direction. |
| `.center` | Cross-axis centers align. |
| `.end` | Trailing cross-axis edge aligns with the anchor's trailing edge (right on a vertical side, bottom on a horizontal side). Same RTL caveat as `.start`. |

## `LayrzPreferredSide` enum

Shared with `LayrzTooltip`. Source: `lib/src/positioning/src/preferred_side.dart`.

| Value | Description |
|---|---|
| `.top` | Place the surface above the anchor. |
| `.bottom` | Place the surface below the anchor. Default for `LayrzAnchoredPanel`. |
| `.left` | Place the surface to the left of the anchor. |
| `.right` | Place the surface to the right of the anchor. |

`LayrzPreferredSideExtension` adds `.opposite` (the flip target), `.isVertical` (`top`/`bottom`), and `.isHorizontal` (`left`/`right`).

---

## Behavior notes

- **Positioning algorithm.** Panel is placed on `preferredSide`, separated by `gap`. If it doesn't fit there, it flips **unconditionally** to the opposite side — there is no second fit test and no third fallback. When neither side fits, it lands on the opposite side regardless and is clamped into the overlay bounds on both axes (for the default `.bottom`, an over-tall panel clamps to the overlay's **top** edge, not the anchor's bottom edge).
- **`matchAnchor` + horizontal `preferredSide` is a discouraged combination.** `matchAnchor` fixes width to the anchor's own width, but a horizontal side needs a full extra anchor-width of clear space beside the anchor — rarely available. Width is still safely clamped, so it never overflows, but the panel usually renders narrower than the anchor. Prefer `.contentSized` with a horizontal `preferredSide`.
- **RTL gap.** `alignment`'s `.start`/`.end` are not yet `Directionality`-aware.
- **Controller swap is release-silent by design, not an oversight.** A debug `assert` catches a swapped non-null `controller`. A release build strips the assert, so the swap is silently ignored — the *original* controller stays in effect. This was deliberately reverted from a `throw` (tried under DESIGN-146): a `StateError` thrown from `didUpdateWidget` mid-rebuild, through this widget's real tree (`RawMenuAnchor`/`InheritedNotifierElement`/`Focus` layers), left the framework's `_InactiveElements` bookkeeping inconsistent and broke every later `didUpdateWidget` in the same element tree. The silent no-op is the lesser failure mode. A caller needing a different controller must construct a new `LayrzAnchoredPanel`, not swap this parameter.
- **`border` must target the panel, not `child`.** Content inside the panel's `SingleChildScrollView` has its height constraint relaxed to unbounded along the scroll axis — a hand-rolled bordered box inside `child` would size to the full uncapped content height instead of the panel's actual capped viewport. `border` paints on the correctly-clamped decorated box instead.
- **`TextFieldTapRegion` wrapping.** The panel overlay is wrapped in `TextFieldTapRegion` so a tap on panel content is never treated as "outside" a nearby `EditableText` anchor (e.g. `LayrzComboBoxInput`'s own field) — without it, `EditableText`'s unconditional-for-mouse tap-outside handling would unfocus the field before the tap on a panel option reaches pointer-up.
- **Keyboard and accessibility.** Escape closes the panel and returns focus to the anchor; Tab/arrow keys traverse into panel content; outside taps close via `TapRegion`; panel content keeps its own semantics, with the outer container transparent to a11y tools unless `panelSemanticLabel` is set.

---

## Differences from `LayrzDropdownMenu`

| Aspect | `LayrzAnchoredPanel` | `LayrzDropdownMenu` |
|---|---|---|
| Width sizing | Configurable (`.matchAnchor` or `.contentSized` with bounds) | Fixed `[160, 320]` |
| Content type | Arbitrary `Widget` | Sealed hierarchy (`LayrzDropdownEntry`, `LayrzDropdownLabel`) |
| Positioning | Any of 4 sides, with flip + optional `coverAnchor` | Below/above only |
| Typical consumer | `LayrzSelectInput`, `LayrzComboBoxInput`, `LayrzDurationInput` | Standalone action menus |

## Placement in the UI

Used by `LayrzSelectInput` (desktop), `LayrzComboBoxInput` (desktop), `LayrzSearchInput.icon` mode (desktop), `LayrzDurationInput` (desktop). On compact viewports (`context.isCompact`, width < 960px) these inputs use `LayrzBottomSheet` instead.

## Related

- `LayrzBottomSheet` — the compact-viewport counterpart for the same picker inputs.
- `LayrzDropdownMenu` — sealed-entry sibling for standalone action menus.
- `LayrzContextMenu` — pointer-anchored sibling; its layout delegate deliberately does not reuse this one (side-of-rect vs. pointer-point anchoring).

---
name: layrz-ui-anchored-panel
description: Use LayrzAnchoredPanel in a layrz_ui Flutter widget. Apply when building the desktop presentation layer for picker inputs — a floating panel anchored to any of the four sides of a trigger widget, with matchAnchor/contentSized width policies, an optional cover-anchor "elevated field" mode, and an optional border.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.matchAnchor`, `.start`, `.bottom`) — never the fully-qualified form (`LayrzAnchoredPanelWidthPolicy.matchAnchor`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- The desktop presentation layer for a picker input's option list — dropdown/select lists, combobox filtered results, an icon button's small menu.
- Use `widthPolicy: .matchAnchor` (default) for input fields where the panel should match the field's own width.
- Use `widthPolicy: .contentSized` with `widthBounds` for icon buttons or other small anchors where the panel should size to its content instead of the anchor.
- Use `coverAnchor: true` for the "elevated field" illusion — the panel exactly covers the anchor (same top-left, same width under `.matchAnchor`), reading as though the anchor itself grew a dropdown rather than a separate floating surface.
- Use `border` to paint a border around the panel's own decorated/clamped box (e.g. a focus or error ring) instead of hand-rolling one inside `child`, which would size to the *uncapped* scroll content instead of the panel's real viewport.
- **Do not use** for a menu with a fixed sealed entry model — use `LayrzDropdownMenu` (tap-triggered) or `LayrzContextMenu` (pointer-triggered) instead; both restrict content to their own entry hierarchies for a standardized look.
- **Do not use** on compact viewports for picker inputs — `LayrzSelectInput`/`LayrzDurationInput`/`LayrzComboBoxInput` already switch to `LayrzBottomSheet` automatically via `context.isCompact`; this panel is the desktop half of that pair.

---

## Minimal usage

```dart
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
```

---

## Key behaviors

- **Builder receives `MenuController`** — wire it directly: `onTap: controller.isOpen ? controller.close : controller.open`. The panel never wraps the anchor, so its gestures are never lost to a gesture-arena conflict.
- `preferredSide` (default `.bottom`) flips **unconditionally** to the opposite side when it doesn't fit — there is no second fit test. When neither side fits, the panel lands on the opposite side anyway and is clamped into the overlay.
- `matchAnchor` combined with a horizontal `preferredSide` (`.left`/`.right`) is **not recommended** — width is still clamped safely, but the panel usually renders narrower than the anchor since a horizontal side needs a full extra anchor-width of clear space beside it. Prefer `.contentSized` for a horizontal `preferredSide`.
- `controller` must **never be swapped** across rebuilds. Unlike `LayrzDropdownMenu`, this is an **assert-only** guard even conceptually in release — a release-mode swap is silently ignored (the original controller stays in effect), not thrown; this was a deliberate reversion after a thrown `StateError` corrupted the framework's element tree mid-rebuild.
- `border` paints around the panel's own clamped decorated box, **not** around `child` — content inside the panel's `SingleChildScrollView` has its height relaxed to unbounded, so a border drawn inside `child` would size to the wrong (uncapped) height.
- `minHeight` gives the panel a floor so a fixed-height header (e.g. a search field) inside `child` never looks cramped, even when the rest of the content is shorter.
- `onFlipped` reports `true` when the panel landed on the side opposite `preferredSide` — for the default `.bottom`, this is exactly "above" vs. "below". Use it to adapt corner radius on the anchor-adjacent side.

---

## Common patterns

```dart
// 1. Icon button trigger with content-sized panel
LayrzAnchoredPanel(
  widthPolicy: .contentSized,
  widthBounds: const LayrzAnchoredPanelWidthBounds(minWidth: 150, maxWidth: 250),
  builder: (context, controller) => LayrzButton(
    labelText: LayrzUiL10n.of(context).more,
    icon: MdiIcons.dotsVertical,
    style: .filledFab,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: Column(mainAxisSize: MainAxisSize.min, children: menuItems),
)

// 2. Scrollable content with a max height and a floor
LayrzAnchoredPanel(
  maxHeight: 300,
  minHeight: 80,
  builder: (context, controller) => LayrzButton(
    labelText: LayrzUiL10n.of(context).select,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: Column(children: largeList.map(_buildItem).toList()),
)

// 3. "Elevated field" illusion — panel covers the anchor exactly
LayrzAnchoredPanel(
  coverAnchor: true,
  builder: (context, controller) => LayrzTextInput(
    value: value,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: _buildOptionList(),
)

// 4. Panel with an error-state border, echoing the anchor field's own state
LayrzAnchoredPanel(
  border: LayrzAnchoredPanelBorder(
    color: context.tokens.colors.danger,
    width: context.tokens.border.base,
  ),
  builder: (context, controller) => LayrzTextInput(
    value: value,
    errors: errors,
    onTap: controller.isOpen ? controller.close : controller.open,
  ),
  child: _buildOptionList(),
)

// 5. Flip-aware corner rounding
LayrzAnchoredPanel(
  onFlipped: (flippedUp) => setState(() => _panelAbove = flippedUp),
  builder: (context, controller) => trigger,
  child: content,
)
```

---

## Sizing policy quick reference

| `widthPolicy` | Width behavior | Best for |
|---|---|---|
| `.matchAnchor` (default) | Equals the anchor's own width | Input fields whose dropdown should match the field |
| `.contentSized` | Sized to content, clamped to `widthBounds` | Icon buttons, compact/narrow anchors |

Both policies additionally clamp the final width to the space actually available in the overlay, so the panel shrinks rather than overflows on a narrow viewport.

---

## Usage conventions

- Localize any text inside `child` or the trigger built by `builder` via `LayrzUiL10n.of(context).<key>` — never hardcode strings.
- Pick `widthPolicy` by anchor shape, not by habit: a text-like input almost always wants `.matchAnchor`; an icon-only trigger almost always wants `.contentSized`.
- Don't hand-roll a bordered `Container` inside `child` to indicate focus/error state — pass `border: LayrzAnchoredPanelBorder(...)` instead so it paints on the correctly-clamped box.
- Reach for `coverAnchor: true` only when the visual goal is genuinely "the field grew its own dropdown" — for an ordinary detached panel, leave it `false` (the default) and use `preferredSide`/`gap` instead.
- Never construct a new `MenuController` on every rebuild when passing `controller` explicitly — hold it in `State` like any other controller.

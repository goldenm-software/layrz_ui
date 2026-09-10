---
name: layrz-ui-tappable
description: Use LayrzTappable in a layrz_ui Flutter widget. Apply when wrapping any child with the standard hover/press surface treatment — the layrz_ui equivalent of Material's InkWell, without ink. Covers tap/long-press/secondary-tap, disabled state, and custom idle/hover/pressed surface colors.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values passed alongside it (e.g. `.zero` on a `BorderRadius` is not an enum, but neighbouring layrz_ui enums in the same widget tree follow this rule) — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any custom tappable surface that needs hover/press feedback but isn't already a `LayrzButton` — list rows, cards, grid cells, custom menu items.
- Building a new composite interactive widget from scratch — `LayrzTappable` is the primitive nearly every other interactive layrz_ui widget composes internally.
- Whenever you need `onSecondaryTap` (right-click) support, which `LayrzButton` does not expose.
- **Do not use** for a standard button with a label/icon — use `LayrzButton` instead; it already wraps this treatment plus sizing, tooltip, and busy-state support.
- **Do not use** when the surface needs keyboard activation/tab focus — `LayrzTappable` deliberately owns no `FocusNode`. Compose your own `Focus`/`FocusNode` around it, or use a widget that already provides one.

---

## Minimal usage

```dart
LayrzTappable(
  onTap: onRowTap,
  borderRadius: BorderRadius.circular(context.tokens.radius.r2),
  child: Padding(
    padding: EdgeInsets.all(context.tokens.spacing.sp3),
    child: Text(title),
  ),
)
```

---

## Key behaviors

- **Idle is opaque `sf1` by default, not transparent.** With no `color:` given, an idle `LayrzTappable` paints `tokens.colors.sf1` under its child. That reads as invisible over a plain page background but is a real opaque fill over anything else (a solid-colour bar, another surface). Pass `color: const Color(0x00000000)` explicitly when idle must be genuinely transparent.
- **A transparent idle color must share its hover color's hue.** Literal `Color(0x00000000)` has black RGB channels regardless of alpha, so animating from it to an opaque, lighter hover tone produces a visible "black blink" mid-transition (`Color.lerp` ramps the black channels up alongside alpha). Prefer `hoverColor.withValues(alpha: 0)` as the idle `color`, paired with that same `hoverColor` passed explicitly.
- **`onTap` is deduplicated across a double-tap** by default (`collapseDoubleTap: true`) — two physical taps in quick succession invoke `onTap` once, not twice. Set `collapseDoubleTap: false` only when a second tap on the *same already-selected* target is itself a distinct, legitimate gesture (e.g. re-picking a date-range endpoint).
- **No focus of its own.** `LayrzTappable` wires no `FocusNode`/`Focus` — wrap it yourself if the surface needs keyboard activation or a tab stop.
- **Disabled suppresses all three gestures** (`onTap`, `onLongPress`, `onSecondaryTap`) and paints a disabled tint (`fg3` at 12% alpha) — no need to null out callbacks manually when toggling `disabled`.
- **Full hit area:** the entire `borderRadius` region is tappable (`HitTestBehavior.opaque`), including visually transparent parts of the surface.
- Only colour, opacity, and cursor vary across states — geometry (size, padding, border width) never changes, per decision D15. No ripple, splash, or scale animation.

---

## Common patterns

```dart
// 1. Transparent idle surface with a correctly-hued hover (no "black blink")
LayrzTappable(
  color: context.tokens.colors.sf3.withValues(alpha: 0),
  hoverColor: context.tokens.colors.sf3,
  onTap: onSelect,
  borderRadius: BorderRadius.circular(context.tokens.radius.r2),
  child: rowContent,
)

// 2. List row with long-press and secondary-tap (context menu)
LayrzTappable(
  onTap: onOpen,
  onLongPress: onShowContextMenu,
  onSecondaryTap: onShowContextMenu,
  child: rowContent,
)

// 3. Disabled row — gestures and hover/press feedback are suppressed automatically
LayrzTappable(
  disabled: !entry.enabled,
  onTap: onSelect,
  child: rowContent,
)

// 4. Re-tappable target (double-tap must not collapse)
LayrzTappable(
  collapseDoubleTap: false,
  onTap: () => pickUpEndpoint(cellDate),
  child: dayCell,
)
```

---

## Pitfalls

- Forgetting `borderRadius` when the child itself has rounded corners causes the painted surface and the child's own shape to visibly mismatch on hover/press — always pass the same radius the child uses.
- Relying on the default `color` when compositing over a non-page background (e.g. inside another solid-filled surface) paints an unwanted opaque disc — pass an explicit transparent `color` there.
- Composing a keyboard-activatable control on top of `LayrzTappable` without adding your own `Focus`/`FocusNode` silently drops the tab stop — this widget will never add one for you.
- Wrapping `LayrzTappable`'s `child` in a `SelectableRegion` and expecting double-tap-to-select text to work is a known limitation: the internal `GestureDetector`'s tap recognizer still wins the gesture arena over `SelectableRegion`'s, regardless of `collapseDoubleTap`.
- Passing both a literal transparent `color: Color(0x00000000)` and a distinctly-hued `hoverColor` reproduces the black-blink artifact — match their hues (see Key behaviors) rather than using pure black-at-zero-alpha.

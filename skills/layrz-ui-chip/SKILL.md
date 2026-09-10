---
name: layrz-ui-chip
description: Use LayrzChip in a layrz_ui Flutter widget. Apply when rendering a static, visual-only compact label — tags, categories, filter badges, status indicators — with .filled/.outlined styles and info/success/warning/danger/context/custom semantic colors, plus an optional delete affordance.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.outlined`, `.danger`) — never the fully-qualified form (`LayrzChipStyle.outlined`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Tag lists, categories, filter badges, and status indicators — any compact, non-interactive label.
- A dismissible label (e.g. a removable filter or selected tag) via `onDelete`.
- Multiple chips together — pair with `LayrzChipGroup` for scrolling or `+N` overflow handling.
- **Do not use** for selection control (single or multi choice) — use `LayrzSelectInput` or `LayrzMultiSelectInput` instead; `LayrzChip` has no selected/active state.
- **Do not use** as a tappable action button — the chip body itself is not tappable; only the optional delete icon responds to input. Use `LayrzButton` for actions.
- **Do not use** for a corner-overlay indicator — use `LayrzBadge` instead.

---

## Minimal usage

```dart
LayrzChip(labelText: 'Flutter')
```

---

## Key behaviors

- The chip itself has no tap, hover, focus, or selection state — it is static. Only the optional delete icon (rendered when `onDelete` is non-null) responds to hover, press, and taps.
- `color` is only honored when `type == .custom` — an assertion throws if `color` is passed with any other `type`.
- Accent color resolution tries `type`'s token color first, then falls back to `color`, then to `tokens.colors.primary` — in practice this means: non-custom `type` always uses its token color (ignoring `color`), and `.custom` uses `color` (or primary if `color` is null).
- Border radius is always `tokens.radius.r1` — a rounded box, not a pill. Chip size and spacing are fixed and not configurable.
- `computeWidth(BuildContext)` returns the chip's intrinsic rendered width; `LayrzChipGroup` uses it internally to decide overflow in `.compact` mode.

---

## Common patterns

```dart
// 1. Basic status chip
LayrzChip(
  labelText: 'Active',
  type: .success,
)

// 2. Dismissible filter chip, outlined
LayrzChip(
  labelText: 'Remove me',
  onDelete: () => setState(() => labels.remove('Remove me')),
  type: .warning,
  style: .outlined,
)

// 3. Custom color
LayrzChip(
  labelText: 'Custom color',
  type: .custom,
  color: const Color(0xFF9C27B0),
)

// 4. Chip list inside LayrzChipGroup (see layrz-ui-chip-group skill)
LayrzChipGroup(
  chips: [
    LayrzChip(labelText: 'Flutter'),
    LayrzChip(labelText: 'Dart'),
  ],
)
```

---

## Usage conventions

- Use plain string literals or `LayrzUiL10n.of(context).<key>` for `labelText` — never hardcode application copy that belongs in a localization layer.
- Omit `onDelete` for a read-only label; pass a callback only when the chip should be dismissible.
- Default `type` is `.custom` (falling back to `tokens.colors.primary` when `color` is also unset) — set an explicit semantic `type` (`.info`/`.success`/`.warning`/`.danger`/`.context`) whenever the chip communicates status rather than a generic tag.
- Do not pass `color` unless `type` is `.custom` — the constructor asserts against it.
- For more than a handful of chips in a constrained width, use `LayrzChipGroup` with `.compact` behavior instead of hand-rolling overflow logic.

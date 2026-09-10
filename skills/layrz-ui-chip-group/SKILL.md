---
name: layrz-ui-chip-group
description: Use LayrzChipGroup in a layrz_ui Flutter widget. Apply when laying out multiple LayrzChip widgets — scrolling row via .none (default), or width-clamped with a +N overflow indicator via .compact.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.compact`) — never the fully-qualified form (`LayrzChipGroupBehavior.compact`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Displaying a list of tags, filter badges, or dynamic label collections without hand-rolling overflow or scroll handling.
- `.none` (default) — an unconstrained horizontal row that scrolls when chips overflow. No width constraint required.
- `.compact` — chips clamped to available width; the remainder collapses into a single `+N` chip whose tooltip lists the hidden labels. Use inside a card, sidebar, or any fixed-width container.
- **Do not use** for a single chip — construct `LayrzChip` directly.
- **Do not use** `.compact` mode inside an unbounded `Column`/unconstrained width — it asserts on a non-finite `maxWidth`; wrap it in a `SizedBox`, `Expanded`, or other width-constraining widget first.

---

## Minimal usage

```dart
LayrzChipGroup(
  chips: [
    LayrzChip(labelText: 'Flutter'),
    LayrzChip(labelText: 'Dart'),
    LayrzChip(labelText: 'Material Design'),
  ],
)
```

---

## Key behaviors

- `.compact` **requires a finite `maxWidth` constraint** — it asserts otherwise (e.g. inside an unbounded `Column`). Constrain it with a `SizedBox(width: ...)` or let a parent like `Expanded` provide the bound.
- `.compact` measures each chip via `computeWidth()` to decide what fits — one text layout per chip per build. Avoid it for very large chip lists (100+) in hot rebuild scenarios; prefer `.none` with scrolling or paginate instead.
- The `+N` overflow chip (`.compact` only) is always context-colored (`type: .context`, not configurable) with `N` clamped to 1–9. Hovering or long-pressing it shows a `LayrzTooltip` listing the hidden labels, one per line. Tapping it does nothing — it is purely informational.
- `alignment` is honored only by `.none`; `.compact` always produces left-aligned output because its layout is overflow-dependent.
- Chips render in the order provided — there is no reordering, dragging, or sorting built in.

---

## Common patterns

```dart
// 1. Default scrolling row
LayrzChipGroup(
  chips: tags.map((t) => LayrzChip(labelText: t)).toList(),
)

// 2. Compact mode with a fixed width and +N overflow
SizedBox(
  width: 300,
  child: LayrzChipGroup(
    chips: [
      LayrzChip(labelText: 'Tag 1'),
      LayrzChip(labelText: 'Tag 2'),
      LayrzChip(labelText: 'Tag 3'),
      LayrzChip(labelText: 'Tag 4'),
      LayrzChip(labelText: 'Tag 5'),
    ],
    behavior: .compact,
  ),
)

// 3. Custom spacing
LayrzChipGroup(
  chips: chips,
  spacing: 12,
)

// 4. Centered alignment (.none only)
LayrzChipGroup(
  chips: chips,
  alignment: Alignment.center,
)
```

---

## Usage conventions

- Default to `.none` for simple, low-friction lists; reach for `.compact` only when the layout genuinely needs a fixed width with overflow collapse (a card, a table cell, a sidebar).
- Build the `chips` list from domain data with `.map(...).toList()` rather than hardcoding a fixed set, so the group scales with real content.
- Leave `spacing` at its default (`null` → `tokens.spacing.sp2`, 8lp) unless the surrounding layout has a documented reason for a different gap.
- Don't wrap `.compact` mode in a `LayoutBuilder`/`Expanded` combination that could hand it an infinite width — verify the ancestor provides a finite constraint.

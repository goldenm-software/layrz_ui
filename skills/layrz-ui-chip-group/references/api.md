# LayrzChipGroup — API Reference

Source: `lib/src/chips/src/chip_group.dart`
- `LayrzChipGroup` class
- `LayrzChipGroupBehavior` enum — `lib/src/chips/src/chip_group_behavior.dart`

---

## Examples

```dart
// Default .none — scrolls horizontally on overflow
LayrzChipGroup(
  chips: [
    LayrzChip(labelText: 'Flutter'),
    LayrzChip(labelText: 'Dart'),
    LayrzChip(labelText: 'Material Design'),
  ],
)

// .compact — clamps to a finite width, collapses overflow into +N
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
    behavior: LayrzChipGroupBehavior.compact,
  ),
)

// Custom spacing, zero gap
LayrzChipGroup(
  chips: chips,
  spacing: 0,
)

// Alignment (.none only)
LayrzChipGroup(
  chips: chips,
  alignment: Alignment.center,
  behavior: LayrzChipGroupBehavior.none,
)
```

---

## Constructor

```dart
const LayrzChipGroup({
  super.key,
  required this.chips,
  this.behavior = LayrzChipGroupBehavior.none,
  this.spacing,
  this.alignment = Alignment.centerLeft,
});
```

No asserts in the constructor itself; `.compact` asserts at build time (inside `LayoutBuilder`) that `constraints.maxWidth != double.infinity`.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `chips` | `List<LayrzChip>` | — | **Required.** The chips to display, rendered in the order given. |
| `behavior` | `LayrzChipGroupBehavior` | `.none` | Layout behavior for overflow handling. |
| `spacing` | `double?` | `null` | Space between chips in logical pixels. When null, defaults to `tokens.spacing.sp2` (8lp). Pass `0` for no spacing. |
| `alignment` | `Alignment` | `Alignment.centerLeft` | Horizontal/vertical alignment of the chip row. Only honored by `.none`; `.compact` ignores it and is always left-aligned. |

---

## `LayrzChipGroupBehavior` enum

| Value | Behavior | Width requirement |
|---|---|---|
| `.none` | Chips render on a single horizontal row inside a `SingleChildScrollView` that scrolls when they overflow. No clipping, no overflow indicator. **Default.** | None — works with unbounded width. |
| `.compact` | Chips are measured and laid out within available width; the remainder collapses into a trailing `+N` chip (N clamped 1–9) whose `LayrzTooltip` lists the hidden labels, one per line. | **Requires a finite `maxWidth`** — asserts otherwise. |

---

## Behavior notes

- **`.compact` measurement algorithm**: for each chip in order, `chip.computeWidth(context)` (plus `spacing` for non-first chips) is accumulated into `takenWidth`. Before the last chip, the loop also reserves `requiredRemainingWidth` (the `+9` overflow chip's own measured width) so there's always room to render the indicator if needed; the last chip skips that reservation. The first chip that would exceed `constraints.maxWidth` (including the reserved overflow width) triggers the cutoff — every prior chip is shown, and a `+$clampedHiddenCount` chip replaces the rest.
- **Overflow chip styling**: always `LayrzChip(style: .filled, type: .context)` — this is hardcoded, not configurable via `LayrzChipGroup`'s own parameters.
- **Overflow chip tooltip**: wraps the `+N` chip in `LayrzTooltip(contentText: hiddenLabels.join('\n'))`, so hovering (desktop) or long-pressing (touch) reveals every hidden chip's label.
- **Performance caveat**: `.compact` mode costs one full text layout per chip per build (via `computeWidth`). For very large lists (100+ chips) in hot rebuild scenarios, prefer `.none` with scrolling, or paginate the chip list before passing it in.
- **No reordering**: `LayrzChipGroup` has no drag-and-drop or sort support — chips always render in the order of the `chips` list.

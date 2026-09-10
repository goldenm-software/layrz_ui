# LayrzRow — API Reference

Source: `lib/src/grid/src/row.dart`
- `LayrzRow` class

Related: `LayrzCol` (`lib/src/grid/src/col.dart`, see the `layrz-ui-col` skill), `LayrzConstrainedView` (page-level width constraint, not covered by this skill).

---

## Examples

```dart
// Two-column responsive layout
LayrzRow(
  children: [
    LayrzCol(xs: 12, md: 6, child: Text('Left column')),
    LayrzCol(xs: 12, md: 6, child: Text('Right column')),
  ],
)

// Three-column grid with explicit spacing
LayrzRow(
  spacing: 16,
  children: [
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 1'))),
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 2'))),
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 3'))),
  ],
)

// Center-aligned row content
LayrzRow(
  mainAxisAlignment: .center,
  children: [
    LayrzCol(xs: 6, child: Text('Centered')),
  ],
)

// Wrapping example: three xs:12/sm:5 columns
LayrzRow(
  children: [
    LayrzCol(xs: 12, sm: 5, child: Box1()),
    LayrzCol(xs: 12, sm: 5, child: Box2()),
    LayrzCol(xs: 12, sm: 5, child: Box3()),
  ],
)
// xs (<600px): three stacked visual rows (12+12>12 each time)
// sm (600–959px): two visual rows — 5+5=10 fits, third (5) wraps to its own row
```

---

## Constructor

```dart
const LayrzRow({
  super.key,
  required this.children,
  this.mainAxisAlignment = MainAxisAlignment.start,
  this.crossAxisAlignment = CrossAxisAlignment.start,
  this.spacing,
});
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `children` | `List<LayrzCol>` | — | Required. May be empty (renders `SizedBox.shrink()`). Grouped into visual rows by greedy span-sum wrapping. |
| `mainAxisAlignment` | `MainAxisAlignment` | `MainAxisAlignment.start` | Horizontal alignment of columns within each visual row. Ignored when `crossAxisAlignment` is `.stretch`. |
| `crossAxisAlignment` | `CrossAxisAlignment` | `CrossAxisAlignment.start` | Vertical alignment of columns. `.stretch` requires a bounded parent height — asserts/throws in an unbounded context. |
| `spacing` | `double?` | `null` | Gap between columns in a visual row **and** between wrapped visual rows, in logical pixels. `null` reads `context.tokens.spacing.sp2` (theme-aware). Pass `0` explicitly for a flush layout. |

---

## Behavior notes

- **Greedy line wrapping**: columns are placed left-to-right; a new visual row starts the instant adding the next column's resolved span would push the running total over 12. `[7, 7]` → two rows (14 > 12); `[4, 4, 4]` → one row (12 = 12).
- **Two-width rule**: breakpoint band selection always reads `MediaQuery.sizeOf(context).width` (the viewport) via `context.tokens.breakpoints.bandAt(width)` — never the row's own measured box. Pixel-width division for sizing columns, separately, uses the row's own `LayoutBuilder`-measured width (`constraints.maxWidth`), falling back to viewport width only when the parent is unbounded horizontally. This means a `LayrzRow` inside a narrow container on a wide screen selects the wide-screen breakpoint's spans but divides a narrow pixel width by them — narrower columns than the same spans would produce at that breakpoint's "native" width. This is the same behavior as CSS Grid / Bootstrap.
- **Spacing is bidirectional**: the same `spacing` value governs both the horizontal gap between columns in one visual row and the vertical gap between stacked visual rows.
- **Column width formula**: for a visual row of `n` columns, each column's pixel width = `(rowWidth - spacing * (n - 1)) * span / 12`.
- **No Material dependency**: built from `Row`, `Column`, and `LayoutBuilder` only.
- **`ResponsiveRow.builder` has no equivalent** — `layrz_theme`'s factory constructor for generated children was deliberately not ported; use `List.generate(...)` inline for `children` instead.

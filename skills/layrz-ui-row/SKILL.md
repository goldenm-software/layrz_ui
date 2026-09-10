---
name: layrz-ui-row
description: Use LayrzRow in a layrz_ui Flutter widget. Apply when arranging LayrzCol children in a 12-column responsive grid — greedy line wrapping, viewport-driven breakpoint selection, and theme-aware spacing.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Alignment parameters use native Flutter enums (`MainAxisAlignment`, `CrossAxisAlignment`) with their own dot-shorthand values (e.g. `.start`, `.stretch`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any responsive multi-column layout: dashboards, form rows, card grids, side-by-side content that should stack on mobile.
- Wrap `LayrzCol` children directly — `LayrzRow` composes them into a 12-column grid with greedy line wrapping.
- Use `spacing: 0` explicitly for a flush, adjacent-column layout with no gaps.
- **Do not use** for a single-axis list with no breakpoint-driven span logic — use a plain `Row`/`Column`/`Wrap` instead; `LayrzRow` exists specifically for breakpoint-cascading spans.
- **Do not use** for page-level width constraint/centering — use `LayrzConstrainedView` for the Bootstrap `.container` pattern; `LayrzRow` only arranges columns, it does not constrain or center itself.

---

## Minimal usage

```dart
LayrzRow(
  children: [
    LayrzCol(xs: 12, md: 6, child: LeftPanel()),
    LayrzCol(xs: 12, md: 6, child: RightPanel()),
  ],
)
```

---

## Key behaviors

- **Greedy line wrapping**: columns are grouped left-to-right into visual rows; a new visual row starts the instant the running span total would exceed 12. `[7, 7]` wraps into two rows; `[4, 4, 4]` stays in one.
- **Two independent widths**: breakpoint selection always uses `MediaQuery.sizeOf(context).width` (the viewport), never the row's own box width — this is standard CSS Grid/Bootstrap semantics. Pixel sizing, separately, uses the row's own measured width. A narrow sidebar on a wide screen selects wide-screen spans but divides a narrow pixel width by them, producing narrower columns than you might expect.
- `spacing` defaults to `context.tokens.spacing.sp2` (theme-aware) when `null` — applies both between columns in a visual row **and** between wrapped visual rows.
- `crossAxisAlignment: .stretch` requires a bounded height from the parent — it throws in an unbounded-height context (e.g. a bare `Column` with no `Expanded`/fixed height).
- Empty `children` renders a zero-sized `SizedBox.shrink()` — never assumes at least one column.

---

## Common patterns

```dart
// 1. Three-column grid, custom spacing
LayrzRow(
  spacing: 16,
  children: [
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 1'))),
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 2'))),
    LayrzCol(xs: 12, sm: 6, md: 4, child: LayrzCard(child: Text('Card 3'))),
  ],
)

// 2. Asymmetric 8-4 split, sidebar stacks on mobile
LayrzRow(
  children: [
    LayrzCol(xs: 12, md: 8, child: MainContent()),
    LayrzCol(xs: 12, md: 4, child: Sidebar()),
  ],
)

// 3. Flush layout, no gaps
LayrzRow(
  spacing: 0,
  children: [
    LayrzCol(xs: 6, child: Text('Left')),
    LayrzCol(xs: 6, child: Text('Right')),
  ],
)

// 4. Stretch children to equal height (requires a bounded-height parent)
SizedBox(
  height: 200,
  child: LayrzRow(
    crossAxisAlignment: .stretch,
    children: [
      LayrzCol(xs: 6, child: LayrzCard(child: Text('A'))),
      LayrzCol(xs: 6, child: LayrzCard(child: Text('B'))),
    ],
  ),
)
```

---

## Pitfalls

- **Don't wrap `LayrzRow` in `SingleChildScrollView(scrollDirection: .horizontal)` expecting it to stay fixed-width** — breakpoint selection reads the viewport, not the scroll view's width, so this does not create an isolated narrow grid; use a plain `Row`/fixed-width columns instead if that's the goal.
- **`crossAxisAlignment: .stretch` in an unbounded parent throws** — always give the row a bounded height (an ancestor `Expanded`, `SizedBox`, or `ConstrainedBox`) before using `.stretch`.
- **Don't hardcode pixel gaps between rows/columns** — pass `spacing` (or leave it `null` for the theme default) rather than adding manual `SizedBox`es between `LayrzCol` children; manual gaps double up with the row's own spacing.
- **A `LayrzRow` inside a narrow parent on a wide screen does not "go mobile"** — because breakpoint selection is viewport-driven, not container-driven, a `LayrzRow` inside a 400px sidebar on a 1920px display still selects the `xl` band. Don't rely on shrinking a container to force a narrower breakpoint's spans.
- **Non-`LayrzCol` children are not supported** — `children` is typed `List<LayrzCol>`; wrap any other widget in a `LayrzCol` first, even a single one, or the grid's span/wrap logic has nothing to compute against.

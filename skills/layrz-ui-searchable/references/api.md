# LayrzSearchable — API Reference

Source: `lib/src/find_in_page/src/layrz_searchable.dart`
- `LayrzSearchable` class (`StatelessWidget`)

---

## Examples

```dart
// Basic wrap of a custom-painted label
LayrzSearchable(
  text: 'Revenue by quarter',
  child: CustomPaint(painter: MyChartAxisLabelPainter()),
)

// A realistic chart legend
class RevenueChartLegend extends StatelessWidget {
  const RevenueChartLegend({super.key, required this.seriesLabels});

  final List<String> seriesLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final label in seriesLabels)
          LayrzSearchable(
            text: label,
            child: CustomPaint(
              size: const Size(160, 20),
              painter: LegendEntryPainter(label: label),
            ),
          ),
      ],
    );
  }
}
```

---

## Constructor

```dart
const LayrzSearchable({
  super.key,
  required this.text,
  required this.child,
});
```

No asserts — every combination of parameters is valid.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `text` | `String` | **required** | The text a find query should be able to match against — typically the exact string `child` paints, though this widget cannot verify that; a mismatch just means the query and the on-screen text disagree. |
| `child` | `Widget` | **required** | The custom-painted (or otherwise semantics-invisible) content this widget makes findable. Wrapped in `ExcludeSemantics` so it never contributes semantics of its own alongside `text`. |

---

## Implementation

```dart
@override
Widget build(BuildContext context) {
  return Semantics(
    label: text,
    child: ExcludeSemantics(child: child),
  );
}
```

A `Semantics` node carrying `text` as its `label`, wrapping `child` in `ExcludeSemantics` — the entire mechanism.

---

## When you need this

Wrap content in `LayrzSearchable` only when it has no semantics of its own to find text against — in practice, content painted directly (`CustomPaint` with a `CustomPainter`/`TextPainter`, or any other mechanism bypassing Flutter's own text-widget semantics contribution):

- Chart axis labels or data-point annotations drawn via a custom painter.
- Canvas-rendered text in a game or diagram view.
- Any other hand-painted label with no backing `RenderParagraph`/`RenderEditable`.

### You do NOT need this for

| Widget | Why it's already findable |
|---|---|
| `Text` | Contributes its own semantics label automatically from its `InlineSpan` content. |
| `RichText` | Same — semantics come from the underlying `RenderParagraph`. |
| `LayrzTextInput` (and everything built on it) | Backed by `EditableText`/`RenderEditable`, which contributes its own value to the semantics tree. |

---

## Behavior notes

- **Why the highlight is a whole-node box.** `resolveWordHighlights` (the mechanism resolving per-word highlight rectangles for a match) needs a `RenderParagraph`/`RenderEditable` to measure word boundaries against. `LayrzSearchable` content has neither, so word-level resolution is impossible — the same fallback used for any other unresolvable match applies: the match's whole bounding rect is painted as the highlight instead.
- **Accessibility side effect.** Wrapping previously semantics-invisible content in `LayrzSearchable` is very often also an accessibility fix, not just a find-in-page one — content assistive technology cannot read (no semantics label) is exactly the same content find-in-page cannot locate.
- **Material-free construction.** Built entirely from `Semantics` and `ExcludeSemantics` (`package:flutter/widgets.dart`).
- **Works without a `LayrzFindInPageHost`.** `LayrzSearchable` has no dependency on the host itself — it functions correctly even outside one (there's just nothing to be found by).

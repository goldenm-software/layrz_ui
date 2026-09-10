---
name: layrz-ui-searchable
description: Use LayrzSearchable in a layrz_ui Flutter widget. Apply when wrapping custom-painted text — chart axis labels, canvas-drawn annotations, any CustomPainter-based label with no RenderParagraph/RenderEditable of its own — so it becomes findable by LayrzFindInPageHost's Ctrl/Cmd+F search.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Wrapping content painted directly via `CustomPainter`/`TextPainter` — a chart axis label, a canvas-rendered annotation, a hand-painted legend entry — that has no backing `RenderParagraph`/`RenderEditable`, so find-in-page's semantics-tree walk would otherwise never see it.
- **Do not use** around `Text`, `RichText`, or anything `EditableText`-backed (`LayrzTextInput` and everything built on it) — these already contribute their own semantics label automatically; wrapping them is redundant (harmless, but pointless).
- **Do not use** as a general-purpose accessibility wrapper for non-text content (icons, images) — its `text` becomes the *only* semantics label for the whole subtree (the child is `ExcludeSemantics`-wrapped), which is correct for a text-representing painter but wrong for content that should announce something else.

---

## Minimal usage

```dart
LayrzSearchable(
  text: 'Revenue by quarter',
  child: CustomPaint(painter: MyChartAxisLabelPainter()),
)
```

---

## Key behaviors

- **Only for content the semantics tree can't already see.** `Text`/`RichText`/`EditableText`-backed widgets already contribute their own semantics and need no wrapper.
- **One label, one node.** `child` is wrapped in `ExcludeSemantics`, so the find walk sees exactly the `text` this widget supplies for the whole subtree — never whatever semantics `child` might otherwise contribute.
- **Whole-node highlight, not word-level.** Because no `RenderParagraph`/`RenderEditable` backs this content, word-level highlight geometry can never be resolved for a match found here — the find highlight is always a single box around the whole widget, never per-word boxes.
- **Caller-declared, unverified correspondence.** `text` is whatever the caller says the content represents — this widget has no way to confirm `child` actually paints exactly that string. A mismatch just means the query and the on-screen text disagree.
- Wrapping already-findable content (`Text`, `RichText`, `LayrzTextInput`) is harmless but adds nothing.

---

## Common patterns

```dart
// 1. A custom chart legend with per-entry custom-painted labels
Column(
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
)

// 2. A single canvas-drawn axis label
LayrzSearchable(
  text: axisLabel,
  child: CustomPaint(painter: AxisLabelPainter(axisLabel)),
)
```

---

## Usage conventions

- Reach for this wrapper specifically when auditing for find-in-page gaps — a component that fails to show up under Ctrl+F is very often also invisible to assistive technology, since both read from the same semantics tree. Fixing one usually fixes the other.
- Keep `text` in exact sync with what the painter actually draws; a caller-side change to the painted label that forgets to update `text` produces a silent, hard-to-spot mismatch — nothing here validates it.
- Do not reach for this to fix a missing accessibility label on interactive content (a tappable custom-painted button, say) — `Semantics` with `button: true` and the appropriate flags is the correct tool there; `LayrzSearchable` is text-only.

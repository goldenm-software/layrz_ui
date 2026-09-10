---
name: layrz-ui-timeline
description: Use LayrzTimeline in a layrz_ui Flutter widget. Apply when rendering a vertical spine of dated events — one-sided or two-sided card layout, auto-collapsing to one-sided below the compact breakpoint, built from a caller-owned List<LayrzTimelineEntry>.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.start`, `.end`) — never the fully-qualified form (`LayrzTimelineSide.start`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A chronological event history: order tracking, audit log, activity feed, shipment status.
- Use the default two-sided layout (`twoSided: true`) on wide viewports when entries benefit from visual grouping/contrast by side.
- Pass `twoSided: false` to force one-sided at any width — the simpler default for most lists.
- **Do not use** for a linear step-by-step wizard/progress indicator with completed/active/pending states — this widget has no such vocabulary; build a stepper component instead.
- **Do not use** for editable/reorderable lists — `LayrzTimeline` has no built-in editing; rebuild `entries` yourself to add, remove, or reorder.

---

## Minimal usage

```dart
LayrzTimeline(
  entries: [
    LayrzTimelineEntry(
      labelText: 'Order placed',
      timestampText: 'Aug 26, 2026',
      icon: MdiIcons.cartCheck,
    ),
    LayrzTimelineEntry(
      labelText: 'Shipped',
      descriptionText: 'Left the warehouse in Miami, FL',
      timestampText: 'Aug 27, 2026',
      accentColor: tokens.colors.info,
    ),
  ],
)
```

---

## Key behaviors

- **The two-sided layout auto-collapses to one-sided below `context.isCompact` (viewport < 960px), by default.** This is not an opt-in — a two-sided timeline on a phone-width viewport either wraps card text into unreadable stacks or visually merges the columns into the spine, silently losing the meaning the two-sidedness carried.
- `twoSided: false` forces one-sided at any width. `isCompactOverride: false` force two-sided *below* the breakpoint — exists primarily for testing the auto-collapse without faking a real viewport resize; not for ordinary use.
- **Reading order always follows `entries`' list order (chronology), never visual left-right placement.** Each two-sided row carries an explicit `OrdinalSortKey` so a screen reader walks entries in chronological order regardless of which side a card lands on.
- `entries` is a plain, caller-owned list — order determines both visual top-to-bottom order and chronological reading order. `LayrzTimeline` does not parse or sort `timestampText`.
- Markers are purely decorative (excluded from semantics); the entry's own `Semantics` node carries label + description + timestamp concatenated.
- Per WCAG 1.4.1, `accentColor` is never the only thing distinguishing an entry — vary `icon` or text content too if the entry needs to stand out.
- Shares no layout or marker code with a stepper component — a timeline entry has no completed/active/pending state machine.

---

## Common patterns

```dart
// Force one-sided at every width
LayrzTimeline(entries: entries, twoSided: false)

// Explicit side placement (two-sided layout only)
LayrzTimeline(
  entries: [
    LayrzTimelineEntry(labelText: 'Customer note', side: .start),
    LayrzTimelineEntry(labelText: 'Agent reply', side: .end),
  ],
)

// Entry with extra content below the description
LayrzTimelineEntry(
  labelText: 'Invoice generated',
  descriptionText: 'Invoice #4821 for \$240.00',
  timestampText: '2 hours ago',
  content: LayrzButton(labelText: 'Download PDF', onTap: downloadInvoice),
)

// Testing the auto-collapse without a real viewport resize
LayrzTimeline(entries: entries, isCompactOverride: true)
```

---

## Usage conventions

- Sort `entries` yourself before passing them — `LayrzTimeline` never reorders by `timestampText`.
- Format `timestampText` consistently with the rest of your app (e.g. relative "2 hours ago" vs. absolute "Aug 27, 2026") — it is opaque display text to this widget.
- To add/remove/reorder an entry, rebuild the `entries` list and pass a new one — there is no built-in editing API.
- Leave `side` null on ordinary entries to let sides alternate automatically; use `side` only when you need a specific grouping (e.g. customer messages always on `.start`, agent replies always on `.end`).
- Don't rely on `accentColor` alone to convey an entry's importance — pair it with a distinct `icon` or wording.

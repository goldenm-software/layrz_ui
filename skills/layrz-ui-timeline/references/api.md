# LayrzTimeline — API Reference

Source: `lib/src/timelines/src/timeline.dart`
- `LayrzTimeline` class (`StatelessWidget`)
- `lib/src/timelines/src/timeline_entry.dart` — `LayrzTimelineEntry` model
- `lib/src/timelines/src/timeline_side.dart` — `LayrzTimelineSide` enum
- `lib/src/timelines/src/timeline_marker.dart` — `LayrzTimelineMarker`
- `lib/src/timelines/src/timeline_connector_painter.dart` — connector painting
- `lib/src/timelines/src/timeline_one_sided_surface.dart` / `timeline_two_sided_surface.dart` — the two layout surfaces

---

## Examples

```dart
// Basic timeline
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

// One-sided at every width
LayrzTimeline(entries: entries, twoSided: false)

// Explicit side placement
LayrzTimeline(
  entries: [
    LayrzTimelineEntry(labelText: 'Customer note', side: LayrzTimelineSide.start),
    LayrzTimelineEntry(labelText: 'Agent reply', side: LayrzTimelineSide.end),
  ],
)

// Entry with extra composed content
LayrzTimelineEntry(
  labelText: 'Invoice generated',
  descriptionText: 'Invoice #4821 for \$240.00',
  timestampText: '2 hours ago',
  content: LayrzButton(labelText: 'Download PDF', onTap: downloadInvoice),
)

// Force two-sided below the compact breakpoint (testing only)
LayrzTimeline(entries: entries, isCompactOverride: false)
```

---

## Constructor

### `LayrzTimeline`

```dart
const LayrzTimeline({
  required this.entries,
  this.twoSided = true,
  this.isCompactOverride,
  super.key,
});
```

### `LayrzTimelineEntry`

```dart
const LayrzTimelineEntry({
  required this.labelText,
  this.descriptionText,
  this.timestampText,
  this.icon,
  this.accentColor,
  this.side,
  this.content,
});
```

---

## Properties

### `LayrzTimeline`

| Property | Type | Default | Notes |
|---|---|---|---|
| `entries` | `List<LayrzTimelineEntry>` | required | Order is both visual top-to-bottom order and chronological/semantics reading order. Not parsed or sorted by `timestampText`. |
| `twoSided` | `bool` | `true` | Whether to render the two-sided layout when the viewport is not compact. Does not override the compact-breakpoint collapse. |
| `isCompactOverride` | `bool?` | `null` | Overrides the `context.isCompact` derivation. See the auto-collapse behavior below. |

### `LayrzTimelineEntry`

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String` | required | Always rendered, always included in the semantics label. |
| `descriptionText` | `String?` | `null` | Optional longer supporting text below `labelText`. No description line renders when null. |
| `timestampText` | `String?` | `null` | Optional caller-formatted date/time text. Opaque display text — not parsed or used for sorting. |
| `icon` | `IconData?` | `null` | Icon rendered inside the marker. A plain dot renders when null. |
| `accentColor` | `Color?` | `null` | Accent for the marker and connector. Per WCAG 1.4.1, never the sole distinguishing feature — pair with `icon` or text. |
| `side` | `LayrzTimelineSide?` | `null` | Which side the card renders on, two-sided layout only. `null` alternates automatically by position. No effect in one-sided layout. |
| `content` | `Widget?` | `null` | Extra widget rendered below the description line (e.g. an attachment chip or action button). |

`LayrzTimelineEntry` is `@immutable` with `copyWith`, `==`/`hashCode`.

---

## `LayrzTimelineSide` enum

| Value | Description |
|---|---|
| `.start` | Renders the entry's content card to the left of the spine. |
| `.end` | Renders the entry's content card to the right of the spine. |

Has no effect in the one-sided form (including the automatic below-breakpoint collapse) — every entry renders on the same side there regardless of `side`.

---

## Companion widgets

The `timelines` barrel (`lib/src/timelines/timelines.dart`) also exports:

- **`LayrzTimelineMarker`** — the circular per-entry marker both layouts render. Always excluded from semantics (decorative); the entry's own `Semantics` node carries the full meaning.
- **`LayrzTimelineConnector`** (painting logic in `timeline_connector_painter.dart`) — a single vertical line segment between adjacent markers. Has no "progressed"/"neutral" state, unlike a stepper connector — a timeline has no active/completed step to progress through.
- **`LayrzTimelineOneSidedSurface`** / **`LayrzTimelineTwoSidedSurface`** — the two layout surfaces `LayrzTimeline` selects between. Exported independently for callers who need one directly, though ordinary use goes through `LayrzTimeline`.

---

## Design tokens used

- **Spacing**: `sp3` (gap between rows and between the marker column and the card).
- **Colors**: `fg3` (default neutral marker when no `accentColor` set), `sf2` (card background), `fg1`/`fg2`/`fg3` (label/description/timestamp text).
- **Typography**: `label` (entry label, timestamp), `body` (entry description).

---

## Behavior notes

- **Auto-collapse below the compact breakpoint is a default, not an opt-in.** Below `context.isCompact` (viewport < 960px), the two-sided layout renders one-sided regardless of `twoSided: true`, because a two-sided timeline either wraps card text into unreadable stacks or visually merges into the spine at phone width. Override with `isCompactOverride: false` (primarily for testability, not ordinary use) or with `twoSided: false` to force one-sided everywhere.
- **Reading order is chronological, not visual.** In the two-sided layout, cards zig-zag left/right, but an explicit `OrdinalSortKey` on each row's `Semantics` node ensures a screen reader always walks entries in `entries`' list order.
- **No shared code with a stepper component.** At most the connector-line *painting approach* (a plain colored line) is similar — duplicated, not imported. Stepper markers encode a linear completed/active/pending state machine; timeline entries are arbitrary dated events with no such vocabulary.
- **No built-in editing.** `entries` is a plain, caller-owned list — add/remove/reorder by rebuilding the list passed in.

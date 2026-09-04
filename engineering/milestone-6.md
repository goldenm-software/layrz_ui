# Milestone 6: Data, Feedback, and Display Primitives

## Goal

Build a batch of standalone data-display and feedback primitives pulled forward as prerequisites
for M4/M5 work: a calendar surface, a progress indicator, a timeline, a tree view, a notification
badge, and a refresh-loading affordance. Kenny's framing for the batch: *"M4 requires few things
for M5 and M6, that's why we're here."* These rows are not misfiled — each is a genuine M6-phase
component whose existence M4/M5 items depend on, pulled forward and built now rather than blocking
on a strict milestone order.

This is the **fifth components milestone** after M1 Foundation, M2 Core Primitives, M3 Inputs, and
M4/M5 (Pickers, Layout, Navigation, Feedback — filed under their own milestone documents). M6
components are independent of each other and of the M5 navigation/feedback family — none of them
import from `lib/src/steppers/` or from each other's modules, by deliberate ruling (see Decisions
Made below).

The milestone shipped in two batches: an initial five (`DESIGN-64`/`88`/`89`/`90`/`93`) plus a
second batch of three (`DESIGN-69`/`91`/`92`, released as part of `0.0.20`) that landed later as
further M6 Data-display/Feedback additions, bringing the milestone to eight items total.

## Status

| # | Item | Status |
|---|---|---|
| 1 | DESIGN-64: LayrzCalendar (month/week/day views, event display, disabled dates) | Merged · Review required |
| 2 | DESIGN-88: LayrzProgressBar (determinate + indeterminate linear indicator) | Merged · Review required |
| 3 | DESIGN-89: LayrzTimeline (one-sided / two-sided dated event spine) | Merged · Review required |
| 4 | DESIGN-93: LayrzTreeView / LayrzSliverTreeView (expand/collapse, dual selection modes, keyboard nav) | Merged · Review required |
| 5 | DESIGN-90: LayrzBadge / LayrzBadgeVisual (notification indicator, 99+ overflow) | Merged · Review required |
| 6 | DESIGN-92: LayrzAccordion (single controlled disclosure panel over SDK `Expansible`) | Merged · Review required |
| 7 | DESIGN-69: LayrzAiMarker (icon-only AI-disclosure marker with animated accent glint) | Merged · Review required |
| 8 | DESIGN-91: LayrzSkeleton (loading placeholder built from caller-composed shape primitives) | Merged · Review required |

**Note**: This table is the authoritative record of M6 work items, kept in step with the code in
the same commit. All eight rows are implemented, tested, and merged to `development`; none has yet
been reviewed by the maintainer on a real device — that is what `Review required` signals. Rows
6-8 (`DESIGN-92`, `DESIGN-69`, `DESIGN-91`) are the second batch, released as part of `0.0.20`. The
Notion ⚒️ Progress database is the shared, publicly linkable view of this same status (rows are
identified as `DESIGN-N` for cross-reference).

`LayrzRefreshIndicator` (Kenny's naming ruling, superseding the plan's proposed
`LayrzRefreshView`) and `LayrzPageTransitions` are filed under `milestone-5.md` instead of here —
see that file's DESIGN-95 and DESIGN-81 rows respectively. Both shipped in the same batch as the
five rows above but were Notion-filed against M5, not M6; this milestone does not duplicate them.

## Definition of Done

- All 8 items above complete and merged to `development`
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M6 tests
- Coverage floor (per CI) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- All M6 components integrated with theme system (LayrzTheme, tokens, state resolution)
- Wiki pages created for all M6 components, registered in `wiki/Widgets/_Sidebar.md`

---

## Work Items

### 1. LayrzCalendar (DESIGN-64)

**Status**: Merged · Review required

**What it does**:
- Calendar surface with month, week, and day navigation, event display (single- and multi-day), and
  disabled-date support — **all three `LayrzCalendarMode` values render and are reachable** from the
  header's view-mode switcher, a second pass over the month-only surface this milestone originally
  shipped
- `LayrzCalendarController` mirrors `LayrzStepperController`'s ownership contract: caller-supplied
  controllers are caller-disposed, internal ones are calendar-disposed, and the instance must never
  be swapped mid-lifecycle; it also gained `nextWeek`/`previousWeek`/`nextDay`/`previousDay` for the
  two new surfaces, stepped via calendar-field arithmetic (never `Duration`) to stay DST-safe
- Header renders previous/next/today navigation plus a view-mode switcher (month/week/day); the
  previous/next buttons' label and dispatched callback are now mode-aware rather than always
  stepping by month
- Month view gained a configurable `firstDayOfWeek` (**default changed to `DateTime.sunday`, a
  breaking change** from the previous hardcoded Monday-first grid), a tappable day-of-month number
  (`dayNumberOpensDayView`) and a tappable ISO 8601 week-number gutter (`showWeekNumbers`), both
  navigating to day/week view respectively
- Multi-day events render as one continuous bar per week row (month view) or per visible range
  (week/day view's all-day band), with lane assignment stable across the whole month rather than
  re-derived per row
- The month grid's per-cell event cap is now derived from measured cell height rather than a fixed
  constant (`kLayrzCalendarMaxVisibleEvents` removed); overflow is a tappable "+N" chip
- Week and day views render a fixed 24-row hour axis, with overlapping timed events split evenly
  into columns and a demoted fill for covered events
- Month names and AM/PM markers are now localizable via a new `LayrzUiL10nMonthsMixin` namespace,
  and a `LayrzTimeFormat` enum (`amPm`/`h24`, default `h24`) selects the week/day surfaces' clock
  convention

**Constraints**:
- **Display-only, no selection.** No `onDaySelected`, no return value — tapping a day cell's
  background or an event chip does nothing. The day number, "+N" chip, and week-number gutter are
  the exceptions, and all three only navigate the calendar's own internal view state
- **No year view** despite `engineering/decisions.md`'s D11 naming one of four original scope
  candidates — this milestone ships three of the four
- Disabled-date styling and "no events that day" remain distinct render paths that never share a
  branch

**API contract**: See [wiki LayrzCalendar page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzCalendar).

---

### 2. LayrzProgressBar (DESIGN-88)

**Status**: Merged · Review required

**What it does**:
- Linear progress bar with determinate (`value` in `[0.0, 1.0]`) and indeterminate (`value: null`)
  modes
- Determinate mode fills from empty to full — the opposite direction of `LayrzButtonIndicator`'s
  countdown depletion, a deliberate divergence
- Colors follow the `LayrzChipType` semantic convention (info/success/warning/danger/context/custom)

**Constraints**:
- Display-only — not interactive; a draggable variant is `LayrzSlider`'s responsibility
- No circular/ring variant in this pass
- Reduce-motion freezes the indeterminate sweep rather than looping

**API contract**: See [wiki LayrzProgressBar page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzProgressBar).

---

### 3. LayrzTimeline (DESIGN-89)

**Status**: Merged · Review required

**What it does**:
- Vertical spine of dated `LayrzTimelineEntry` events, rendered one-sided or two-sided
- Two-sided layout **auto-collapses to one-sided below `context.isCompact`** (viewport < 960px) by
  default — a two-sided layout at phone width either wraps card text unreadably or visually merges
  into the spine, so this is not opt-in. Overridable via `twoSided: false` (force one-sided always)
  or `isCompactOverride: false` (force two-sided below the breakpoint, mainly for tests)
- Reading order always follows entry list order (chronology), never visual left/right placement —
  enforced via an explicit `OrdinalSortKey` per row in the two-sided layout

**Constraints**:
- Deliberately shares no layout or marker code with `LayrzStepper` — only the connector-line
  *painting approach* (a plain colored line) is similar, and it is duplicated, not imported, per
  the batch's ruling that `LayrzTimeline` must not depend on `lib/src/steppers/`
- No built-in editing — `entries` is a plain caller-owned list
- Markers are purely decorative and excluded from semantics; an entry's `accentColor` is never the
  sole distinguishing feature (WCAG 1.4.1)

**API contract**: See [wiki LayrzTimeline page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzTimeline).

---

### 4. LayrzTreeView / LayrzSliverTreeView (DESIGN-93)

**Status**: Merged · Review required

**What it does**:
- Hierarchical tree with expand/collapse (built on the SDK's `TreeSliver`/`TreeSliverController`)
  and optional multi-node selection
- `LayrzTreeNode<T>` uses an explicit caller-supplied `id` for identity, rather than the SDK's
  fragile content-equality lookup
- **Both selection modes ship, per Kenny's ruling** (§5.2 of the batch plan; the plan itself left
  this an open question between two reviewers): `LayrzTreeSelectionMode.independent` (default) and
  `.cascading` (with a third, partial/indeterminate parent state). `independent` is the default as
  the more conservative choice for a design-system primitive
- **Keyboard navigation, ruled in during the verdict round**: Up/Down move across visible rows,
  Right expands-or-descends, Left collapses-or-ascends. Arrow keys move a separate
  `LayrzTreeController.activeId` cursor and never mutate selection — the active row renders as a
  color-only outline change (D15), composing independently of selected/partially-selected styling

**Constraints**:
- `children` is fixed at construction — no async/lazy-loading contract for children appearing
  after first expand
- `LayrzTreeView` (box form) is a thin `CustomScrollView` wrapper; the tree itself is implemented
  exactly once, in `LayrzSliverTreeView`

**API contract**: See [wiki LayrzTreeView page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzTreeView).

---

### 5. LayrzBadge / LayrzBadgeVisual (DESIGN-90)

**Status**: Merged · Review required

**What it does**:
- Notification indicator: `LayrzBadge` overlays a corner of a child via `Positioned` (no layout
  reflow); `LayrzBadgeVisual` is the bare, unpositioned form for inline use (e.g.
  `LayrzLayoutRailItem`)
- Content priority: `count` (formatted number) > `icon` > bare presence dot
- **Overflow ruled by Kenny (§5.6)**: counts above 99 render as exactly `99+`, never a raw large
  number and never configurable
- Colors follow the `LayrzChipType` semantic convention, matching `LayrzBadgeType`'s vocabulary to
  it deliberately

**Constraints**:
- `label` is a **required** parameter on `LayrzBadge`, forcing every caller to supply an
  accessible description — a bare "3" read aloud next to an unlabelled icon is meaningless
- `LayrzBadgeVisual` intentionally attaches no `Semantics` of its own; a caller using it directly
  (not via `LayrzBadge`) owns merging its own semantics

**API contract**: See [wiki LayrzBadge page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzBadge).

---

### 6. LayrzAccordion (DESIGN-92)

**Status**: Merged · Review required

**What it does**:
- Single, Material-free disclosure panel wrapping the SDK's `Expansible` for the expand/collapse
  animation and height interpolation — a styling and interaction wrap, not a ground-up
  implementation
- Fully controlled: `expanded` is the single source of truth and `onExpansionChanged` is the only
  way the widget asks its caller to change it; no internal toggle can drift from what the caller
  believes is showing
- Whole-header hit target — the leading icon, title, and chevron together form one tap and
  keyboard (Space/Enter) target, not a chevron-only affordance
- `Expansible` is configured with `maintainState: false`, so the collapsed body is genuinely absent
  from the widget tree, not merely hidden — a screen reader never encounters it while collapsed
- Reveal animation uses `LayrzMotionTokens.easingEmphasized`; the header's own geometry (corner
  radius, border fade) is driven by that same animation rather than a separately-timed
  `AnimatedContainer`, which previously caused a visible "blink" on expand/collapse (see Decisions
  Made below)

**Constraints**:
- Single panel, not a group — multi-accordion coordination (only one open at a time), nesting one
  accordion inside another's body, and a free-form header slot are all explicit v1 non-goals
- Header hover/press/focus states vary colour only, never size or padding (D15); the
  expand/collapse height change is the widget's function, not an interaction state

**API contract**: See [wiki LayrzAccordion page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzAccordion).

---

### 7. LayrzAiMarker (DESIGN-69)

**Status**: Merged · Review required

**What it does**:
- Icon-only marker disclosing that nearby content was generated or assisted by AI: two overlapping
  sparkle glyphs on a fixed 30×30 logical-pixel rounded container filled with
  `tokens.colors.aiAccent`
- `LayrzAiMarker.wrap(child:, position:)` overlays the marker on a corner of `child` without
  affecting `child`'s layout footprint, mirroring `LayrzBadge`'s overlay pattern
- Two independent animations — a staggered star-burst twinkle and a slow orbiting glow shadow —
  each on its own `AnimationController` so neither ticker drags the other's pace; both switch off
  entirely under reduced motion
- Disclosure text is **not caller-configurable**: the `Semantics` label and `LayrzTooltip` text
  both always come from `LayrzUiL10n.of(context)` (`aiGeneratedLabel` / `aiGeneratedTooltip`), so
  two call sites can never disclose the same fact in two different strings

**Constraints**:
- No `text`/`label`/`tooltip` override parameter and no `size` parameter — star placement, glyph
  size, and the disclosure copy are fixed by deliberate ruling, not an oversight
- A sighted user who never triggers a screen reader or the tooltip sees only a bare sparkle with no
  visible text in the moment — an owned, accepted trade-off, not a defect

**API contract**: See [wiki LayrzAiMarker page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzAiMarker).

---

### 8. LayrzSkeleton (DESIGN-91)

**Status**: Merged · Review required

**What it does**:
- Loading placeholder built from caller-composed shape primitives (`LayrzSkeletonBox`,
  `LayrzSkeletonCircle`, `LayrzSkeletonLine`) arranged into whatever layout matches the real content
  that will eventually replace them — `LayrzSkeleton` does not know how to render any shape itself
- One shared `AnimationController` drives the shimmer for every descendant primitive via
  `LayrzSkeletonScope` (an `InheritedWidget`), so the whole subtree shimmers in phase; a primitive
  used standalone falls back to a self-owned ticker
- No-reflow by design: `LayrzSkeleton` imposes no sizing of its own, deferring entirely to
  `child`'s intrinsic size, so the loading state occupies exactly the box the real content will
  occupy
- `LayrzSkeletonLine.matchTextStyle` derives a line's height from a real `TextStyle`'s line-box
  metrics, so a text placeholder matches the rendered line height of what it stands in for
- Reduced motion suppresses the `AnimationController` entirely (no scheduled frames), re-evaluated
  on every rebuild so an OS-level toggle takes effect without remounting

**Constraints**:
- Not a "wrap your real widget and we'll silhouette it" component — the caller owns composition of
  the shape primitives entirely
- The whole `child` subtree is wrapped in one outer `Semantics(label: 'Loading')` node (with
  `ExcludeSemantics` beneath it), so a screen reader announces "Loading" once per skeleton, never
  once per shape primitive

**API contract**: See [wiki LayrzSkeleton page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzSkeleton).

---

## Dependencies

- **M1 (Tokens, Theme)**: LayrzTheme, LayrzThemeData, LayrzTokens, token resolution
- **M2 (Chips)**: `LayrzChipType`'s semantic-color convention, mirrored by `LayrzProgressBarType`
  and `LayrzBadgeType`
- **M3 (Stepper)**: `LayrzStepperController`'s controller-ownership pattern, mirrored by
  `LayrzCalendarController`, `LayrzRefreshController`, and `LayrzTreeController` — pattern reused,
  code not shared
- **Cross-cutting**: none of the eight M6 components in this file depend on each other or on
  `lib/src/steppers/` — see Decisions Made below

## Decisions Made

- **TreeView selection mode default**: `independent`, not `cascading` — the batch's implementation
  plan left this an explicitly open question (two reviewers disagreed); Kenny ruled both modes ship
  side by side, with `independent` as the default, as the more conservative choice for a
  design-system primitive. See `.claude/pipeline/RULINGS.md`.
- **Badge overflow**: `99+` for counts above 99 — ruled by Kenny after the plan left this open,
  rejecting both an uncapped raw number and a caller-configurable cap.
- **Timeline/Stepper non-coupling**: `LayrzTimeline` must not import from `lib/src/steppers/`,
  even for the visually similar connector-line painting, because `LayrzStepper` was still `Pending
  review by team` at implementation time and a connector is too small a surface to justify coupling
  two otherwise-unrelated modules.
- **TreeView keyboard navigation implemented now, not deferred**: found missing during the verdict
  round (the module shipped `activeId`/`setActive`/`getActiveId` with zero keyboard primitives
  behind them) and ruled in immediately, including the active-row visual threaded through
  `LayrzTreeRowStyleSpec.resolve` — see `.claude/pipeline/RULINGS.md` for the full history.
- **Accordion header/body animation coupling**: `LayrzAccordion`'s header geometry (corner radius
  collapsing to zero, border fade) is driven by the same eased reveal animation as the body's
  expand/collapse, not by a separately-timed `AnimatedContainer` on the hover duration — the
  original approach forced a choice between a sluggish hover and a header whose corners snapped to
  their expanded state before the body finished revealing, visible as a "blink" on both expand and
  collapse.
- **AiMarker disclosure text is not a constructor parameter**: `LayrzAiMarker` has no
  `text`/`label`/`tooltip` override — both the `Semantics` label and the `LayrzTooltip` text always
  come from `LayrzUiL10n`, so the AI-disclosure copy cannot drift between call sites or fall out of
  translation.

## Metrics

- **Coverage**: see `flutter test --coverage` for the current repository figure at release time;
  this milestone must not take it downward.
- **Breaking changes**: None — all eight components are net-new modules.

## Notes

- **One concept per file, enforced across all eight modules**: each ships its own controller,
  style-spec, and (where applicable) painter files, rather than a single god-file per component.
- **Interaction-state compliance (D15)**: `LayrzTreeView`'s active-row outline and hover states vary
  color only, never geometry.
- **Semantic-color convention reused, not reinvented**: `LayrzProgressBarType` and `LayrzBadgeType`
  both mirror `LayrzChipType`'s info/success/warning/danger/context/custom vocabulary rather than
  each introducing their own.
- **Accessibility**: every component in this milestone ships real `Semantics` — merged
  announcements on `LayrzBadge` and `LayrzCalendarDayCell`, live-region announcements on
  `LayrzProgressBar` and `LayrzRefreshIndicator`'s visual, depth/expansion/selection state on
  `LayrzTreeRow`, expansion state on `LayrzAccordion`'s header, a mandatory disclosure label and
  tooltip on `LayrzAiMarker`, and a single collapsed `Semantics(label: 'Loading')` announcement on
  `LayrzSkeleton` — rather than being deferred as a follow-up row the way several M3 inputs were.

---

**Milestone 6 started**: 2026-08-28
**Last updated**: 2026-09-04
**Related documents**: [Roadmap](roadmap.md), [Milestone 5](milestone-5.md),
[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

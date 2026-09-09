# Milestone 8: Utilities & Tweaks

## Goal

Track small, standalone utility components and behavioural tweaks that don't belong to any of the
component-family milestones (M1-M6) — a home for "M8 Utilities & Tweaks"-phase Notion items, the
same way M9 holds cross-cutting Quality of Life work. The first item in this milestone is
`LayrzConnectionIndicator`, a Material-free port of `layrz_theme`'s `TelemetryIndicator`.

This milestone is scoped narrowly on purpose: it exists to hold `DESIGN-209` today, not to
pre-populate a full roadmap of utility work. Additional items are added here as they are planned
and filed in Notion, not invented ahead of time.

## Status

| # | Item | Status |
|---|---|---|
| 1 | DESIGN-209: LayrzConnectionIndicator (Material-free port of `layrz_theme`'s `TelemetryIndicator` — 5-state elapsed-time model, `.dot`/`.full` render modes, independent `LayrzConnectionTimes` config type with no `layrz_models` dependency) | Merged · Review required |

**Note**: This table is the authoritative record of M8 work items, kept in step with the code in
the same commit. The Notion ⚒️ Progress database is the shared, publicly linkable view of this
same status (rows are identified as `DESIGN-N` for cross-reference).

## Definition of Done

- The items above complete and merged to `development`
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M8 tests
- Coverage floor (per CI) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- Wiki page created for `LayrzConnectionIndicator`, registered in `wiki/Widgets/_Sidebar.md`

---

## Work Items

### 1. LayrzConnectionIndicator (DESIGN-209)

**Status**: Merged · Review required

**Domain**: Feedback

**What it does**:
- Material-free, modernized port of `layrz_theme`'s `TelemetryIndicator`
- Resolves a 5-state model (online/idle/offline/disconnected/no-data) purely from elapsed time
  since a `receivedAt` timestamp, via the standalone `resolveLayrzConnectionState` function
- Two render modes: `.dot` (a small colored `LayrzBadgeVisual` dot wrapped in a `LayrzTooltip`
  announcing the state and a humanized "time ago" string) and `.full` (the state color wraps a
  caller-supplied `child` as a colored pill chrome)
- Re-renders once a minute via an internally owned, dispose-safe `Timer.periodic` so the indicator
  stays live without the caller polling it
- Defines its own `LayrzConnectionTimes` config type (online/idle thresholds) instead of depending
  on `layrz_models`' `Connection` class — `layrz_ui` gains no new dependency; downstream packages
  bind their own `Connection` model to `LayrzConnectionTimes` via an extension, outside this
  package's concern

**Constraints**:
- Only the online/idle boundaries are configurable; the 30-day offline→disconnected boundary and
  the no-data state are fixed constants
- `.dot` must not receive a `child`; `.full` requires one — both enforced via constructor asserts
- Clock source is plain `DateTime.now()` (overridable via an optional `clock` parameter for
  testability), not a timezone-database dependency

**API contract**: See
[wiki LayrzConnectionIndicator page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzConnectionIndicator).

---

## Dependencies

- **M2 (Chips)**: `LayrzBadgeVisual` (used in `.dot` mode), `LayrzTooltip`

## Planned (not yet started)

Other Utilities & Tweaks items may be filed against this milestone as they are planned in Notion.
None are scheduled or scoped yet beyond `DESIGN-209` above — this section is a placeholder for
future rows, not a commitment.

## Notes

- **Why a milestone of its own**: `DESIGN-209` was originally recorded under `milestone-9.md`
  (Quality of Life) but its Notion "Phase" is "M8 Utilities & Tweaks", a distinct milestone from M9
  — this document corrects that filing so the record matches Notion's phase assignment.

---

**Milestone 8 started**: 2026-09-09
**Last updated**: 2026-09-09
**Related documents**: [Roadmap](roadmap.md), [Milestone 9](milestone-9.md),
[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

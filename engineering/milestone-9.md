# Milestone 9: Quality of Life

## Goal

Track quality-of-life improvements that fall outside the component-by-component milestones
(M1-M6) — behavioural refinements to existing surfaces rather than new visual primitives. The
first item in this milestone is `LayrzForm`, a password-manager autofill wrapper that closes a
platform-integration gap no earlier milestone scoped.

This milestone is scoped narrowly on purpose: it exists to hold `DESIGN-101` today, not to
pre-populate a full roadmap of QoL work. Additional items are added here as they are planned and
filed in Notion, not invented ahead of time.

## Status

| # | Item | Status |
|---|---|---|
| 1 | DESIGN-101: LayrzForm (behavioural password-manager autofill wrapper wiring `finishAutofillContext`) | Merged · Review required |
| 2 | DESIGN-110: Motion token standardization (cap `dDialog` at 250ms/`kPageTransitionDuration`; migrate hardcoded durations in `button_indicator`/`refresh_indicator` to motion tokens; point dropdown-menu/context-menu fade curves at the emphasized `easeInOutCirc` token) | Merged · Review required |
| 3 | DESIGN-209: LayrzConnectionIndicator (Material-free port of `layrz_theme`'s `TelemetryIndicator` — 5-state elapsed-time model, `.dot`/`.full` render modes, independent `LayrzConnectionTimes` config type with no `layrz_models` dependency) | Merged · Review required |

**Note**: This table is the authoritative record of M9 work items, kept in step with the code in
the same commit. The Notion ⚒️ Progress database is the shared, publicly linkable view of this
same status (rows are identified as `DESIGN-N` for cross-reference).

## Definition of Done

- The items above complete and merged to `development`
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M9 tests
- Coverage floor (per CI) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- `LayrzForm` integrated with theme system where applicable (LayrzTheme, tokens, state resolution)
- Wiki page created for `LayrzForm`, registered in `wiki/Widgets/_Sidebar.md`

---

## Work Items

### 1. LayrzForm (DESIGN-101)

**Status**: Merged · Review required

**Domain**: Inputs

**What it does**:
- Behavioural wrapper around a form's input fields that integrates with the platform's
  password-manager autofill flow — no visual surface of its own, purely a coordination layer
- Wires `TextInput.finishAutofillContext()` at the appropriate point in the form's lifecycle so
  the OS-level password manager is correctly notified that an autofill session has concluded
  (e.g. on successful submission), rather than leaving credentials pending in an open autofill
  context indefinitely
- Composes with existing `layrz_ui` text inputs rather than introducing a new input primitive

**Constraints**:
- Behavioural only — `LayrzForm` renders no chrome, no borders, no spacing of its own; it is a
  wrapper, not a new visual component
- Scope is the autofill-context lifecycle, not general form state management (validation
  orchestration, field-level error aggregation, etc. remain out of scope for this item)

**API contract**: See [wiki LayrzForm page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzForm).

---

### 2. Motion Token Standardization (DESIGN-110)

**Status**: Merged · Review required

**Domain**: Cross-cutting (Buttons, Menus, Refresh)

**What it does**:
- Hygiene pass over hardcoded animation durations/curves scattered across components, replacing
  them with the shared `LayrzMotionTokens` (`lib/src/tokens/src/motion.dart`)
- Caps `dDialog` at 250ms (`kPageTransitionDuration`)
- Migrates `button_indicator`'s hardcoded 1500ms to `dIndeterminate` and `refresh_indicator`'s
  hardcoded 200ms to `dTransition`
- Points the symmetric dropdown-menu and context-menu fade curves at the emphasized
  `easeInOutCirc` token instead of a locally hardcoded curve

**Constraints**:
- Enter/exit easing asymmetry and gesture-driven linear curves are deliberately preserved, not
  swept into the standardization
- No new visual surface — durations/curves only; no widget's layout, chrome, or public API changed

**Touches**: `lib/src/buttons/src/button_indicator.dart`, `lib/src/context_menu/src/context_menu.dart`,
`lib/src/menus/src/dropdown_menu.dart`, `lib/src/refresh/src/refresh_indicator.dart`,
`lib/src/tokens/src/motion.dart`

---

### 3. LayrzConnectionIndicator (DESIGN-209)

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

- **M3 (Inputs)**: `LayrzForm` wraps existing text input components; it does not introduce a new
  input primitive of its own

## Planned (not yet started)

Other Quality of Life items may be filed against this milestone as they are planned in Notion.
None are scheduled or scoped yet beyond `DESIGN-101`/`DESIGN-110` above — this section is a
placeholder for future rows, not a commitment.

## Notes

- **Why a milestone of its own**: `DESIGN-101` did not fit the component-by-component shape of
  M1-M6 (each of those tracks new visual primitives), so it is filed under its own
  "Quality of Life" milestone rather than force-fit into an unrelated components list. `DESIGN-110`
  (a cross-cutting motion-token hygiene pass touching Buttons, Menus, and Refresh) fits the same
  rationale — it is a behavioural/consistency refinement across existing surfaces, not a new
  component.

---

**Milestone 9 started**: 2026-09-04
**Last updated**: 2026-09-09
**Related documents**: [Roadmap](roadmap.md), [Milestone 6](milestone-6.md),
[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

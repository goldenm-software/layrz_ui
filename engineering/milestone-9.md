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

**Note**: This table is the authoritative record of M9 work items, kept in step with the code in
the same commit. The Notion ⚒️ Progress database is the shared, publicly linkable view of this
same status (rows are identified as `DESIGN-N` for cross-reference).

## Definition of Done

- The item above complete and merged to `development`
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

## Dependencies

- **M3 (Inputs)**: `LayrzForm` wraps existing text input components; it does not introduce a new
  input primitive of its own

## Planned (not yet started)

Other Quality of Life items may be filed against this milestone as they are planned in Notion.
None are scheduled or scoped yet beyond `DESIGN-101` above — this section is a placeholder for
future rows, not a commitment.

## Notes

- **Why a milestone of its own**: `DESIGN-101` did not fit the component-by-component shape of
  M1-M6 (each of those tracks new visual primitives), so it is filed under its own
  "Quality of Life" milestone rather than force-fit into an unrelated components list.

---

**Milestone 9 started**: 2026-09-04
**Last updated**: 2026-09-04
**Related documents**: [Roadmap](roadmap.md), [Milestone 6](milestone-6.md),
[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

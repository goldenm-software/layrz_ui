# Milestone 4: Pickers

## Goal

Build the M4 picker component family: date, time, and month selection widgets (single-valued and
range variants), plus the multi-select and dual-list inputs deferred from M3 (D61), plus the
remaining media/appearance pickers (color, file, icon, emoji, avatar, dynamic avatar).

This is the **third components milestone** after M1 Foundation, M2 Core Primitives, and M3 Inputs.
M4 establishes the shared day/month grid primitives, the strftime-style formatter, and the
adaptive-container picker pattern (anchored panel / bottom sheet, D52/D70) that every picker in this
milestone and beyond builds on.

## Status

| # | Item | Status |
|---|---|---|
| 41 | LayrzMultiSelectInput (searchable multi-value picker) | TO DO · own batch, not DateTime-related |
| 43 | LayrzDualListInput (two-panel available/selected picker) | TO DO |
| 45 | LayrzDateInput (single date, commit on tap) | Review required |
| 46 | LayrzDateRangeInput (contiguous date range, in-panel Save) | Review required |
| 47 | LayrzTimeInput (single time, commit on tap) | Review required |
| 48 | LayrzTimeRangeInput (start + end time, in-panel Save) | Review required |
| 49 | LayrzDateTimeInput (date + time, `tabbed`/`stepped` presentation, in-panel Save) | Review required |
| 50 | LayrzDateTimeRangeInput (date + time range, in-panel Save) | Review required |
| 51 | LayrzDateTimeSteppedInput | Covered by DESIGN-49 — collapsed into its `stepped` presentation mode, not a separate widget |
| 52 | LayrzMonthInput (single month, commit on tap) | Review required |
| 53 | LayrzMonthRangeInput (contiguous or arbitrary month selection, in-panel Save) | Review required |
| 54 | LayrzColorInput (wheel + palette color picker) | TO DO · blocked, see note |
| 55 | LayrzFileInput (file upload picker) | TO DO |
| 56 | LayrzIconInput (Solar icon set picker) | TO DO |
| 57 | LayrzEmojiInput (Unicode emoji picker) | TO DO |
| 58 | LayrzAvatarInput (image avatar picker) | TO DO |
| 59 | LayrzDynamicAvatarInput (URL/base64/icon/emoji avatar picker) | TO DO · blocked, see note |

**Note**: This table is the authoritative record of M4 work items, kept in step with the code in the
same commit. It was sourced by querying the Notion ⚒️ Progress database for every row with
`Phase = "M4 Pickers"` (18 DESIGN rows; a 19th M4-phase row, DESIGN-146, is a `LayrzAnchoredPanel`
follow-up already resolved per D71 and is not a Pickers deliverable, so it is not listed above).
Rows 45–53 (eight widget classes covering nine rows, DESIGN-41 excluded) shipped in this batch — see
`engineering/decisions.md` D74 (S5 exception to D72) and D75 (the batch's settled calls: container,
commit boundary, no `intl`, typed ranges, contiguity policy, endpoint-adjust selection) for the full
reasoning. **DESIGN-51 (`LayrzDateTimeSteppedInput`) is recorded as *covered by* DESIGN-49, not
Removed** — its own row body already noted its parameters are identical to `LayrzDateTimeInput`, and
this batch settled that open question by making it a presentation mode (`tabbed` vs `stepped`) on one
widget rather than a second widget. **DESIGN-41 (`LayrzMultiSelectInput`) is explicitly out of this
batch** — it is not DateTime-related and was split into its own batch per the maintainer's own
scoping of this run; its Notion row is left untouched. Row 48 (`LayrzTimeRangeInput`) already existed
as a Notion DESIGN row prior to this batch (created 2026-08-17); it was folded into this batch
because the old layrz_theme family has a `ThemedTimeRangePicker`, the roadmap lists it as an M4
deliverable, and `wiki/Widgets/LayrzTimeRangeInput.md` already existed as a spec page.

## M4 is NOT complete when this batch ships

Eight rows remain, all `TO DO`: `LayrzMultiSelectInput` (41), `LayrzDualListInput` (43),
`LayrzColorInput` (54), `LayrzFileInput` (55), `LayrzIconInput` (56), `LayrzEmojiInput` (57),
`LayrzAvatarInput` (58), `LayrzDynamicAvatarInput` (59) — Emoji, Icon, File, Avatar, Dynamic Avatar,
and Color inputs, plus MultiSelect and DualList carried over from M3 (D61). `LayrzColorInput`
additionally carries a real blocker (`flex_color_picker` 3.8.0 is Material-built — 23 Material
imports, 2 Cupertino — so its wheel and palette must be written from scratch rather than wrapping
that package), and `LayrzDynamicAvatarInput` is blocked until `LayrzAvatarInput`, `LayrzIconInput`,
and `LayrzEmojiInput` ship, since it composes all three.

## Definition of Done

- All 18 M4 Pickers-domain Notion rows above resolved (`Done` or, for DESIGN-51, correctly recorded
  as covered by DESIGN-49 rather than a separate deliverable) — 10 resolved as of this batch
  (DESIGN-45–53 in `Review required`, DESIGN-51 covered), 8 remaining `TO DO`
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M4 tests
- Coverage floor (90%) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns
  empty
- All new public code documented per CLAUDE.md rule #1
- All M4 components integrated with theme system (LayrzTheme, tokens, state resolution) and the
  adaptive anchored-panel/bottom-sheet container (D52/D70)

---

## Work Items — DateTime Picker Batch (this run)

### DESIGN-45–53 (eight widget classes, nine rows)

**Status**: Review required (all eight)

**What shipped**: `LayrzDateInput`, `LayrzDateRangeInput`, `LayrzTimeInput`, `LayrzTimeRangeInput`,
`LayrzDateTimeInput` (with `LayrzDateTimeSteppedInput`/DESIGN-51 collapsed in as a `stepped`
presentation mode alongside the default `tabbed` mode), `LayrzDateTimeRangeInput`, `LayrzMonthInput`,
`LayrzMonthRangeInput`.

**Shared infrastructure built alongside them**:
- Day grid and month grid primitives (`lib/src/pickers/src/shared/`) — grid math, cell rendering,
  weekday header, week-number gutter, time fields panel
- Typed value/range classes: `LayrzMonth`, `LayrzTimeOfDay`, `LayrzDateRange`, `LayrzMonthRange`
- Range-selection contiguity policy objects: `LayrzContiguousRangePolicy`,
  `LayrzArbitraryRangePolicy`
- House `strftime`-style formatter (`lib/src/formatting/`), replacing any `intl` dependency
- New `LayrzUiL10n` keys: picker namespace (`lib/src/l10n/src/namespaces/pickers.dart`), weekday
  initials and abbreviations, abbreviated month names, seconds label, range separator,
  first-day-of-week default
- `sameZoneDate`/`sameZoneDateTime` exported from the calendar module for picker use — see D74

**Decisions embedded**: D52/D70 (adaptive container), D74 (S5 calendar-zone export), D75 (commit
boundary model, no-`intl` formatting, typed ranges, contiguity policy, endpoint-adjust selection,
keyboard nav, 24h default, text-only time entry, frozen `LayrzInputChrome`)

**Notion tracking corrections applied in this batch**: the stale `Blocker` field
("Localisation strategy undecided") was cleared on all eight in-scope rows — it was resolved once the
l10n keys above were added. The stale `Primitive` field ("composes LayrzTextInput") was also cleared
on all eight rows — every M4 picker composes `LayrzInputChrome` directly, per D63; the same stale
claim is also present in `roadmap.md:95` and in the wiki picker spec pages, both **outside this unit's
file list and reported rather than corrected here.**

---

### DESIGN-41, 43 — Deferred from M3 (D61)

**Status**: TO DO

Scoped to a separate batch per the maintainer's explicit instruction that DESIGN-41
(`LayrzMultiSelectInput`) is not DateTime-related and should not ride along with this batch.
`LayrzDualListInput` (DESIGN-43) has not been started.

---

### DESIGN-54–59 — Media/Appearance Pickers

**Status**: TO DO (all six)

Not started in this batch. `LayrzColorInput` (54) carries a real blocker: `flex_color_picker` 3.8.0
pulls in 23 Material and 2 Cupertino imports, so its wheel and palette selection UI must be
implemented from scratch rather than wrapping that package, per this repository's Material/Cupertino
invariant. `LayrzDynamicAvatarInput` (59) is blocked on `LayrzAvatarInput`, `LayrzIconInput`, and
`LayrzEmojiInput` shipping first, since it composes all three by design.

---

## Dependencies

- **M1 (Tokens, Theme)**: LayrzTheme, LayrzThemeData, LayrzTokens, token resolution
- **M2 (Buttons, Alerts)**: LayrzButton for in-panel Cancel/Save actions
- **M3 (Inputs)**: `LayrzInputChrome` (shared, frozen), `LayrzAnchoredPanel`, `LayrzBottomSheet`,
  `LayrzNumberInput` (time-field text entry and step behavior)
- **Calendar module**: `sameZoneDate`/`sameZoneDateTime`, exported for picker use under the narrow
  D74 exception to D72; no other calendar-module internals are shared

---

## Decisions Made (D74–D75)

Both recorded in `engineering/decisions.md`:

- **D74** (Amendment to D72): `sameZoneDate`/`sameZoneDateTime` exported from the calendar module for
  picker use — a narrow exception that does not reopen D72 for the grid, controller, or surfaces
- **D75** (M4 DateTime Pickers Batch): container, commit-boundary model, no-`intl` formatting, typed
  ranges, contiguity policy, endpoint-adjust range selection, keyboard navigation, and the frozen-chrome
  outcome for this batch

---

## Notes

- **Notion is the phase source, this table is the status source of truth**: per `CLAUDE.local.md`,
  this Status table is authoritative above the Notion Progress database and the wiki. Notion rows are
  identified as `DESIGN-N` for cross-reference.
- **No checkboxes**: per `CLAUDE.md`, status lives in the table above only; every work item below uses
  plain bullets.
- **M4 is a multi-batch milestone**: the DateTime picker batch recorded here is the first of at least
  three remaining sub-batches (MultiSelect/DualList, media/appearance pickers) before M4 as a whole is
  done.

---

**Milestone 4 started**: 2026-09-02
**Last updated**: 2026-09-02
**Related documents**: [Roadmap](roadmap.md), [Decisions D74–D75](decisions.md#d74),
[Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

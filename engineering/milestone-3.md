# Milestone 3: Inputs

## Goal

Build the input component family and shared input infrastructure for M3 and beyond. Focus on eight specialized input widgets, plus foundational components (`LayrzBottomSheet`, `LayrzAnchoredPanel`, `LayrzSelectItem<T>`) that enable the picker-surface pattern across the system.

This is the **second components milestone** after M1 Foundation and M2 Core Primitives. M3 establishes the input contract and form patterns that consuming apps will use to build data-entry forms.

## Status

| # | Item | Status |
|---|---|---|
| 1 | LayrzTextAreaInput (multiline text over shared chrome) | Merged · Review required |
| 2 | LayrzComboBoxInput (editable with suggestions, adaptive overlay) | Merged · Review required |
| 3 | LayrzNumberInput (numeric with step buttons, decimal formatting) | Merged · Review required |
| 4 | LayrzCheckboxInput and LayrzSwitchInput (separate boolean components) | Merged · Review required |
| 5 | LayrzRadioInput (option group with responsive grid layout) | Merged · Review required |
| 6 | LayrzSelectInput (read-only picker, adaptive overlay) | In progress · one fix from done |
| 7 | LayrzSearchInput (inline or overlay search with mode enum) | Merged · Review required |
| 8 | LayrzDurationInput (hours/minutes/seconds picker, unit-capped) | In progress · blocked behind DESIGN-6 |
| 9 | LayrzStepper (horizontal wizard flow with controller) | Merged · Review required |
| 10 | LayrzBottomSheet (modal/persistent sheet, mobile half of D52) | Merged · Review required |
| 11 | LayrzAnchoredPanel (smart overlay with flip and width control) | Merged (as prerequisite) · Review required |
| 12 | LayrzSelectItem<T> (shared item type for radio/select/combobox) | Merged (as supporting work) · Review required |
| 13 | LayrzSlider (single-value slider, drag/tap/keyboard, DESIGN-86) | In progress · implemented and tested on `feat/inputs/DESIGN-86`, not yet merged |

**Note**: This table is the authoritative record of M3 work items, kept in step with the code in the same commit. Rows 1–5 and 7–12 are merged into `development` and marked `Review required`. Rows 6, 8, and 13 are in active development. The Notion ⚒️ Progress database is the shared, publicly linkable view of this same status (rows are identified as `DESIGN-N` for cross-reference).

### Outstanding Accessibility Work

Nine input component suites have zero semantics assertions despite ~70 tests. These are tracked as M3 follow-up rows DESIGN-115–DESIGN-123:

- DESIGN-115: `textarea_input_a11y_test.dart` (0 / 15 assertions)
- DESIGN-116: `number_input_a11y_test.dart` (0 / 13 assertions)
- DESIGN-117: `switch_input_a11y_test.dart` (0 / 10 assertions)
- DESIGN-118: `checkbox_input_a11y_test.dart` (0 / 9 assertions)
- DESIGN-119: `avatar_a11y_test.dart` (0 / 9 assertions)
- DESIGN-120: `alert_a11y_test.dart` (0 / 8 assertions)
- DESIGN-121: `bottom_sheet_a11y_test.dart` (0 / 5 assertions)
- DESIGN-122: `stepper_a11y_test.dart` (was 1 / 11 assertions) — superseded by the 2026-08-27 stepper redesign, which rewrote the test suite (now 12 `testWidgets`, including new coverage of a compact error-step row that had no prior test at all) against the new wide/compact layouts and their new semantics surface (expand/collapse, lock affordance) as part of that unit rather than as a separate follow-up
- DESIGN-123: `anchored_panel_a11y_test.dart` (0 / 4 assertions)

These are non-blocking for M3 release but represent outstanding accessibility debt that must be addressed before the next milestone.

## Definition of Done

- 10 main M3 rows complete and merged to `development`
- 2 supporting rows complete and merged (`LayrzAnchoredPanel`, `LayrzSelectItem<T>`)
- 1 prerequisite complete and merged (`LayrzBottomSheet`)
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M3 tests
- Coverage floor (90%) not breached (current: 90.44%)
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- All M3 components integrated with theme system (LayrzTheme, tokens, state resolution)
- Nine outstanding a11y suites identified and tracked as follow-up rows

---

## Work Items

### 1. LayrzTextAreaInput (DESIGN-34)

**Status**: Merged · Review required

**What it does**:
- Multiline text input over shared chrome, sibling to `LayrzTextInput` (decision D55)
- Variable-height field: `minLines: 3`, `maxLines: 10`, then scrolls
- Supports character counter via existing `LayrzInputErrorBlock` mechanism
- `keyboardType: multiline`, `textInputAction: newline` — Enter inserts newline, does not submit
- Full text selection and magnifier support (gesture controls, dragging handles, platform-specific magnifier on touch)

**API contract**: See [wiki LayrzTextAreaInput page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzTextAreaInput) for constructor documentation.

**Architecture**: Shares text-selection plumbing with `LayrzTextInput` via library-private `LayrzEditableField` and cached selection controls, avoiding duplication of ~600 lines of wiring. `LayrzInputChrome.variableHeight` aligns the trailing cluster to the top of tall fields.

---

### 2. LayrzComboBoxInput (DESIGN-35)

**Status**: Merged · Review required

**What it does**:
- Editable field with suggestion overlay (decision D52: anchored panel on desktop, bottom sheet below md breakpoint)
- Overlay width matches the field (classic web combobox pattern)
- Free-form entry by default: any typed text is a valid value, submitted on Enter or blur (decision D59, opt-out via `allowFreeForm: false`)
- Field retains focus while overlay is open; arrow keys highlight options, Enter commits
- Case-insensitive prefix matching from the start of each option
- Escape closes without changing value

**Constraints**:
- Uses `RawMenuAnchor` directly for overlay control (not `RawAutocomplete`, which fights custom positioning)
- Width parameter: `widthPolicy: matchAnchor` on the panel
- Filtering is case-insensitive prefix matching (can be disabled via `enableAutocomplete: false`)

**Decisions embedded**:
- D52: Adaptive surface (overlay/sheet boundary at md)
- D53: `LayrzSelectItem<T>` for items
- D59: Free-form opt-out

---

### 3. LayrzNumberInput (DESIGN-36)

**Status**: Merged · Review required

**What it does**:
- Numeric input supporting both `int` and `double` values
- Step buttons flanking the field (±): `hideStepButtons` suppresses them
- Decimal separator configurable: dot or comma (caller-supplied, not locale-derived)
- `minimum`, `maximum` clamp the buttons; typed input passes through (errors are caller-owned per D34)
- `format` callback for custom number formatting (optional `inputRegExp` when format is set)
- `maximumDecimalDigits` default 4, capped at 15

**Design decisions**:
- Step buttons are **outside** the field border, not inside a suffix (prevents competition with error/lock/help icons)
- Bounds clamp only the buttons, not typed values (allows validation to be caller-owned)
- No `intl` dependency added; formatting is optional via callback

**Usable bare and narrow**, without a label — DESIGN-44 `LayrzDurationInput` embeds one per visible time unit inside its picker panel.

---

### 4. LayrzCheckboxInput and LayrzSwitchInput (DESIGN-38)

**Status**: Merged · Review required

**What it does**:
- Two separate boolean inputs (decision D54, not one style enum)
- **Checkbox**: 20×20 box, `MdiIcons.check` when checked
- **Switch**: 52×28 pill track, 24×24 thumb sliding left/right
- Both animate on `tokens.motion.dTransition` (200ms)
- Labels are trailing and tappable; label and control form one tap target
- Boolean only; tristate is pinned `false` via a getter

**Accessibility (WCAG 1.4.1)**:
- Checkbox: state conveyed by checkmark glyph presence, not colour alone
- Switch: state conveyed by thumb position (left/right), not colour alone
- Tests assert the glyph/position specifically

**Why split**: Checkbox and switch share no paint code. Splitting keeps each component's concern clear and avoids the `asField` / `asSwitch` style enum from layrz_theme (D27/D28 trimming).

---

### 5. LayrzRadioInput (DESIGN-39)

**Status**: Merged · Review required

**What it does**:
- Radio button group with responsive grid layout (decision D58: per-breakpoint integer spans 1–12, matching `LayrzCol`)
- Built on `RawRadio` + `RadioGroup` from `widgets.dart` (Material-free, design-agnostic)
- Arrow keys move within the group; labels are tappable
- Items use shared `LayrzSelectItem<T>` (D53)

**Layout**:
```dart
LayrzRadioInput<Plan>(
  xs: 12,   // 1 per row on phones
  sm: 6,    // 2 per row
  md: 4,    // 3 per row
  lg: 3,    // 4 per row
  xl: 2,    // 6 per row
)
```

Grid layout uses real `LayrzRow` + `LayrzCol`, cascading fallback (unset breakpoint inherits the next smaller).

**Architecture**: Does **not** compose `LayrzTextInput` — a radio group is not a text field. Keeps only the contract's spirit: group `labelText`, `errors`, `hideDetails`, `padding`, `disabled`.

---

### 6. LayrzSelectInput (DESIGN-40)

**Status**: In progress · one fix from done

**What it does**:
- Read-only picker field (no typed input, unlike combobox)
- Adaptive surface: anchored overlay on desktop, bottom sheet below md
- Optional search filtering
- Optional un-select via `canUnselect`
- Searchable attributes customizable per item via `LayrzSelectItem<T>.searchableAttributes`
- Arrow/Enter/Escape keyboard navigation

**Current blocker**: A real bug was fixed during development — the anchor's `GestureDetector` wrapped only the selected-label `Text`, which is empty when nothing is selected, creating a zero hit area. Fixed by moving the detector outside the chrome and wrapping content in `SizedBox(width: double.infinity)`.

**Outstanding work**:
- 20 failing tests: surface-content assertions and a11y semantics
- Suggested approach: take one failing surface-content test, read the first exception (not the assertion), check for explicit viewport (1600×1200 for panel, 400×800 for sheet)

---

### 7. LayrzSearchInput (DESIGN-42)

**Status**: Merged · Review required

**What it does**:
- Two presentation forms, selected by `LayrzSearchInputMode` enum (decision D56)
- **field**: inline `LayrzTextInput` with magnifier prefix, × clear suffix (appears when query is non-empty)
- **icon**: collapsed magnifier button that opens an anchored overlay containing the field
- **auto** (default): selects between them from available constraints/breakpoint
- Debounce defaults to 300ms, configurable
- Escape closes the overlay form

**Why mode enum**: Forces developers to choose responsive behavior explicitly (inline or overlay), without requiring hand-rolled `LayoutBuilder` at every call site. The `auto` member is the point: responsive search without boilerplate.

**Dropped from layrz_theme**: `position { left, right }` — overlay direction is computed from available space, not declared.

---

### 8. LayrzStepper (DESIGN-87, redesigned 2026-08-27)

**Status**: Merged · Review required

**What it does**:
- Owns the whole flow: header, current step body, back/next actions (decision D57)
- `LayrzStep` is a data class carrying `labelText`, `body` (Widget), an optional `state` override, and an optional identity `icon`
- `LayrzStepperController` for programmatic navigation (e.g., advance only after async save)
- Step states: `upcoming / active / completed / error` (trimmed per D27/D28); `completed`, `active`, and `error` steps are all tappable, only `upcoming` is locked
- **Redesigned to run full page width, per two dedicated layouts instead of one branching widget:**
  - **Wide** (`stepper_wide.dart`) — full-width row of equal-width flex cells, each stacking a fixed-height indicator+connector band over a label band, so a two-line label cannot shift its own indicator out of alignment with the others (the bug that motivated the redesign)
  - **Compact** (`stepper_compact.dart`) — vertical accordion, exactly one step's body open at a time driven by `currentIndex`, plus a persistent "Step X of Y" counter above the stack; `AnimatedSize` drives the expand/collapse, the library's first use of that widget
- `bool? isCompact` override on `LayrzStepper` forces either layout regardless of viewport, for testing and for callers that need to override the viewport-based default
- `stepper.dart` itself is now a 222-line coordinator (down from 484) that owns the controller lifecycle and delegates all layout painting to the two layout files and to `LayrzStepIndicator`

**Accessibility (WCAG 1.4.1)**:
- Completed steps carry `MdiIcons.check`, error steps carry `MdiIcons.alertCircle` — state is never colour-only; this override beats any caller-supplied `LayrzStep.icon`
- Semantics labels include position and state (*"Step 2 of 3, Shipping, completed"*), built from `LayrzUiL10nSteppersMixin.steppersStepCounterLabel` / `steppersStateLabel` so both layouts announce identically
- An `upcoming` (locked) step now carries a non-colour lock glyph (`MdiIcons.lockOutline`) in both layouts, closing a pre-existing gap where a locked step was distinguished by colour and a thin border alone
- Connector lines and numbered circles are excluded from semantics as decorative
- `ExcludeFocus` keeps a collapsed compact-layout step's body out of the tab order — a new precedent in this library for hiding collapsed content from keyboard navigation
- Button labels resolve from `LayrzUiL10nSteppersMixin`

**Architecture**: Full stepper (not header-only) was deliberate despite being heavier. The accepted cost is that navigation-button layout is baked in, so escape hatches can be added later if consumers need custom actions. See decision D57's 2026-08-27 update for the full reasoning behind the redesign, including why "collapse to a summary string" was not a viable reading of D57's own flow-ownership decision, the declined step-count ceiling, and why the two layout widgets stay unexported while `LayrzStepIndicator` is exported.

**Wiki**: documented for the first time at `wiki/Widgets/LayrzStepper.md`, registered in `wiki/Widgets/_Sidebar.md` under Inputs — there was no page for this widget before this redesign.

**2026-08-27 batch note**: this redesign shipped alongside a batch of four other rows, closed as follows —
- **DESIGN-87** (this redesign) and **DESIGN-122** (the a11y test rewrite) — closed, covered above.
- **DESIGN-161** (`LayrzComboBoxInput`'s mobile sheet had no search field or accessible name) and **DESIGN-162** (`LayrzTappable.onTap` fired twice on a double-tap) — both closed; see `CHANGELOG.md`'s Unreleased section for what shipped.
- **DESIGN-146** (`LayrzAnchoredPanel.controller`'s no-swap contract is debug-only) — closed as a **reversal**: option 2 (throw in release) was implemented, measured to corrupt the framework's `_InactiveElements` bookkeeping, and reverted to option 3 (debug-only assert, honestly documented). See decision D71.
- **DESIGN-153** (`LayrzEditableField`'s null→caller-supplied `focusNode` swap) was investigated as part of this batch and **closed as NOT-A-BUG, not fixed**. The skipped test's premise was a harness artefact — its `pumpThemed`-based swap trigger never fires `didUpdateWidget` at all — not a defect in the widget. Under a valid harness, all three swap directions (null→external, external→null, external→different-external) pass unmodified. No code changed as a result; this row does not appear in `CHANGELOG.md`.

---

### 9. LayrzDurationInput (DESIGN-44)

**Status**: In progress · blocked behind DESIGN-6

**What it does**:
- Time duration picker: days, hours, minutes, seconds (decision D60)
- Each unit capped to its natural range: hour [0, 23], minute [0, 59], second [0, 59], day [0, ∞)
- Configurable `visibleUnits` — shows all four by default
- Result: exactly one field representation per `Duration` (no ambiguity like minute: 90 → 1h30m)
- Adaptive surface: anchored overlay on desktop, `LayrzBottomSheet` below md (D52)
- Picker panel holds one `LayrzNumberInput` per visible unit, plus a reset action
- Field displays humanised summary, localised through `LayrzUiL10nDurationMixin`

**Outstanding work**:
- Wire the adaptive surface (D52 follow-through) — currently opens a bottom sheet at every width
- Use `LayrzAnchoredPanel` with `widthPolicy: contentSized`
- Remove `prefix: SizedBox.shrink()` lock hack once DESIGN-40 lands
- Revert the public `suppressReadOnlyLock` once DESIGN-40 lands (only DESIGN-44 uses it)
- 5 failing tests (mostly picker-opening assertions, likely resolved by adaptive wiring)

---

### Supporting Work

**LayrzSelectItem<T>** (supporting work, not a user-facing component):
- Shared data container for items in `LayrzRadioInput`, `LayrzComboBoxInput`, `LayrzSelectInput`
- Four fields: `labelText`, `T? value`, `Widget? child`, `Set<String> searchableAttributes`
- Simplifies three separate item types down to one

**LayrzAnchoredPanel** (new module `lib/src/overlays/`):
- Smart overlay container that flips above/below based on available space
- Width control via `widthPolicy { matchAnchor, contentSized }`
- Built on `RawMenuAnchor` + `Align` + layout delegate (from `LayrzDropdownMenu`'s flip logic, lifted and reused)
- Shared infrastructure enabling D52 (adaptive picker surfaces)

**LayrzBottomSheet** (prerequisite, DESIGN-97):
- Mobile half of D52: modal or persistent bottom sheet
- Built on `RawDialogRoute` + `DraggableScrollableSheet` + `PopScope`
- Full scope: `snapSizes`, `showDragHandle`, expand-on-drag behavioural affordances
- Focus management (into sheet on open, back to invoker on close) and reduce-motion support
- Shared infrastructure enabling D52

**LayrzInputChrome** (enhanced):
- Variable-height mode via `variableHeight` constructor parameter
- Swaps fixed `SizedBox(height: contentHeight)` for `ConstrainedBox`
- Aligns trailing cluster (shortcut → suffix → lock → help → error) to top instead of vertically centring on tall fields

---

## Dependencies

- **M1 (Tokens, Theme)**: LayrzTheme, LayrzThemeData, LayrzTokens, token resolution
- **M2 (Buttons, Alerts)**: LayrzButton for actions, LayrzAlert for inline feedback
- **M3 Internal**: LayrzInputChrome (shared), LayrzEditableField (library-private, shared text-selection wiring)
- **M4 (Pickers)**: MultiSelect and DualList deferred per D61

---

## Decisions Made (D52–D61)

All ten are recorded in `engineering/decisions.md`:

- **D52** (Picker Surfaces Adaptive): Desktop overlay flips up/down, mobile uses bottom sheet at md boundary
- **D53** (`LayrzSelectItem<T>`): Minimal shared item type — labelText, value, child, searchableAttributes
- **D54** (Checkbox and Switch Separate): Two components, not one with `asField` style
- **D55** (Multiline is Sibling): `LayrzTextAreaInput` over shared chrome, `LayrzTextInput`'s API unchanged
- **D56** (`LayrzSearchInputMode` enum): field / icon / auto, no boolean `asField` flag
- **D57** (`LayrzStepper` Owns Flow): Full stepper (header + body + actions), not header-only indicator
- **D58** (Responsive Grids): Integer spans 1–12 per breakpoint, mirroring `LayrzCol`, no `Sizes` enum
- **D59** (Combobox Free-Form Opt-Out): Default true, set `allowFreeForm: false` to lock to options
- **D60** (Duration Units Capped): Day/hour/minute/second, each capped to natural range, one representation per Duration
- **D61** (M3 Scope Trim): `LayrzMultiSelectInput` and `LayrzDualListInput` moved to M4

---

## Metrics

- **Coverage**: 90.44% (against 90% CI floor, <1 point headroom)
- **Next release**: 0.0.13 (once DESIGN-40 and DESIGN-44 land)
- **Breaking changes**: None in public APIs; D55 ensures `LayrzTextInput` is byte-identical to 0.0.12

---

## Notes

- **One concept per file**: Eight separate input widgets, not one god component. Supporting work extracted into library-private modules.
- **Interaction state compliance (D15)**: All inputs vary colour/opacity on hover/press/focus; never size or padding.
- **Adaptive breakpoint**: `isCompact` (< 960px) is the boundary for all D52 decisions (picker surfaces, search modes, stepper header collapse).
- **Accessibility debt**: Nine a11y suites identified with zero semantics assertions. Follow-up rows DESIGN-115–DESIGN-123 are non-blocking for M3 release but represent outstanding work.

---

**Milestone 3 started**: 2026-08-21  
**Last updated**: 2026-08-21  
**Related documents**: [Roadmap](roadmap.md), [Decisions D52–D61](decisions.md#d52), [Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

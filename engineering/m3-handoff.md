# M3 Inputs — session handoff

**Date:** 2026-08-21
**`development` at:** `1fdd2c4`, green, pullable
**Scope:** 9 M3 rows + DESIGN-97 as prerequisite. 8 of 10 merged.

---

## Status

| Row | Component | State |
|---|---|---|
| DESIGN-97 | `LayrzBottomSheet` | Merged · `Review required` |
| DESIGN-34 | `LayrzTextAreaInput` | Merged · `Review required` |
| DESIGN-35 | `LayrzComboBoxInput` | Merged · `Review required` |
| DESIGN-36 | `LayrzNumberInput` | Merged · `Review required` |
| DESIGN-38 | `LayrzCheckboxInput` + `LayrzSwitchInput` | Merged · `Review required` |
| DESIGN-39 | `LayrzRadioInput` | Merged · `Review required` |
| DESIGN-42 | `LayrzSearchInput` | Merged · `Review required` |
| DESIGN-87 | `LayrzStepper` | Merged · `Review required` |
| **DESIGN-40** | **`LayrzSelectInput`** | **In progress** — one fix from done |
| **DESIGN-44** | **`LayrzDurationInput`** | **In progress** — blocked behind DESIGN-40 |

Moved out of M3 → `M4 Pickers`: DESIGN-41 `LayrzMultiSelectInput`, DESIGN-43 `LayrzDualListInput`.

Also landed as supporting work: `LayrzSelectItem<T>`, `LayrzAnchoredPanel` (`lib/src/overlays/`),
variable-height `LayrzInputChrome`, and the shared internal `editable_field.dart`.

---

## Resume here

### 1. DESIGN-40 `LayrzSelectInput` — branch `feat/inputs/DESIGN-40-select-rebased`

Everything architectural is **done and verified**: the custom `_SelectInputDialogRoute` is deleted,
`LayrzAnchoredPanel` is wired with `widthPolicy: matchAnchor`, the surface layout is fixed with
`LimitedBox(maxHeight: 300)` (bounds only in unbounded contexts, so panel *and* sheet lay out),
the anchor is built from `LayrzInputChrome` with `suppressReadOnlyLock: true`, and
`git diff development -- lib/src/inputs/src/text_input.dart` is **empty**.

**Last pushed:** `3f44947`. Test state at handoff: **2152 passing / 20 failing** overall —
`select_input_test.dart` 7 passing / 10 failing, `select_input_a11y_test.dart` 0 / 10.

**A real bug was found and fixed here** (worth knowing, it would have shipped): the anchor's
`GestureDetector` wrapped only the selected-label `Text`, which is `''` when nothing is selected —
**zero hit area, so an unselected select field was untappable on a device**, not just in tests. Now
fixed: detector moved outside the chrome, `HitTestBehavior.opaque`, and `contentChild` wrapped in
`SizedBox(width: double.infinity)`. All 37 tests now reach the anchor and can open the surface.

**What is left:** the 20 remaining failures are surface-content assertions and a11y semantics
checks. Suggested order when resuming:

1. Take one failing surface-content test and read its first thrown exception (not the assertion) —
   `flutter test test/inputs/select_input_test.dart --plain-name "<name>"`. Earlier rounds showed
   consequential errors (`parentData dirty`, un-laid-out `RenderBox`) masking a first real cause.
2. Check each test sets an explicit viewport — 1600×1200 for the panel path, 400×800 for the sheet
   path. Without one it takes the mobile path (see gotcha 1).
3. The 10 a11y failures are almost certainly the milestone-wide semantics gap below, not
   Select-specific — consider folding them into that follow-up row rather than fixing here.
4. Add a test that taps a field with **no value set** and asserts the surface opens — that is the
   case the zero-width bug broke, and nothing covered it.

### 2. DESIGN-44 `LayrzDurationInput` — branch `feat/DESIGN-44-finish`

**Deliberately held until DESIGN-40 merges**, so it consumes the chrome flag rather than
implementing a second one. Branch off fresh `development` afterwards.

Done and correct: `LayrzDurationUnit { day, hour, minute, second }`; per-unit capping (day
unbounded, hour 0–23, minute 0–59, second 0–59) giving exactly one field representation per
`Duration`, with a round-trip test; `LayrzDurationPickerPanel` extracted as shared content;
`LayrzUiL10nDurationMixin` in its own `duration.dart` namespace.

Still to do:
- **Wire the adaptive surface (D52).** It currently opens a bottom sheet at *every* width — a
  desktop user gets a sheet on a 27-inch monitor. Use `LayrzAnchoredPanel` with
  `widthPolicy: contentSized` (four labelled number fields with flanking `−`/`+` need more than
  anchor width; ~320–400 was proposed, validate against real content). **Do not push a route** —
  `LayrzAnchoredPanel` is a widget that owns its overlay via `RawMenuAnchor`.
- **Remove the `prefix: SizedBox.shrink()` lock hack.** It cannot work — the lock renders in the
  *trailing* cluster. Use the chrome's `suppressReadOnlyLock` once DESIGN-40 lands, and add a test
  asserting no lock icon.
- **Revert the public `suppressReadOnlyLock` added to `text_input.dart`.** That component ships in
  0.0.12; its public API must stay byte-identical.
- **Un-export `LayrzDurationPickerPanel`** from the barrel — it was made public only for test
  access. Tests can import `package:layrz_ui/src/inputs/src/...` directly.
- Fix the 5 failing tests (mostly picker-opening; likely resolved by the adaptive wiring).

---

## Approved follow-up: a11y suites assert semantics

**Create a new M3 row for this.** An audit found **nine** `*_a11y_test.dart` files with **zero**
semantics assertions — ~70 tests that pass against a widget exposing nothing to a screen reader:

```
textarea_input_a11y_test.dart   0 / 15      alert_a11y_test.dart          0 / 8
number_input_a11y_test.dart     0 / 13      bottom_sheet_a11y_test.dart   0 / 5
switch_input_a11y_test.dart     0 / 10      anchored_panel_a11y_test.dart 0 / 4
checkbox_input_a11y_test.dart   0 / 9       stepper_a11y_test.dart        1 / 11
avatar_a11y_test.dart           0 / 9
```

(`alert` and `avatar` predate M3, so this is not new — M3 added to it.)

Model to copy: **`button_a11y_test.dart` — 29 semantics assertions across 20 tests.** Also good:
`dropdown_menu_a11y_test.dart` (10/4), `card_a11y_test.dart` (9/8).

Agreed approach: **when the real assertions reveal a component that genuinely does not expose
semantics, fix the component and report each one.** Likely candidates — `LayrzSwitchInput` with no
`toggled` state, `LayrzBottomSheet` with no dialog role.

Idiom: `tester.ensureSemantics()` with `addTearDown(handle.dispose)`, then
`tester.getSemantics(...)` with `matchesSemantics(...)`. Without `ensureSemantics()` the tree is
not built and every matcher fails — which is why several attempts were rewritten into render
checks instead.

---

## Documentation debt (not started)

- **`wiki/Widgets/` pages for 9 components.** Only `LayrzSelectItem.md` and
  `LayrzAnchoredPanel.md` exist. Agents were told to skip the wiki because the submodule is not
  initialised inside worktrees; do this in one pass from the main checkout where it is live.
  A salvaged `LayrzSelectItem.md` sits in the session scratchpad.
- **`engineering/milestone-3.md`** does not exist. Use the `## Status` table format from
  `milestone-5.md` (`| # | Item | Status |`).
- **`engineering/decisions.md`** — append **D52–D61** (see the Notion row comments, which carry
  the full reasoning for each).
- **`wiki/Input-Contract.md` is stale** — it still cites `surface2`/`surface3` (removed by D49,
  now the `sf1`–`sf4` ramp) and claims spacing is 4/8/16/24/32 (D46 made it 6/10/14/20/32).
- **Showroom sections** for all 9 components — deliberately out of scope this milestone.

---

## Decisions made (D52–D61)

- **D52** Picker surfaces are adaptive: anchored overlay on desktop, `LayrzBottomSheet` below `md`
  (< 960px). No dialog anywhere in M3 — DESIGN-96/99 are **not** needed.
- **D53** `LayrzSelectItem<T>` = `labelText`, `T? value`, `Widget? child`, `searchableAttributes`.
  Rendering is the consumer's job. Dropped `icon`/`leading`/`content`/`onTap`/`isRemoved`.
- **D54** Checkbox and switch are separate components; the `asField` style is dropped.
- **D55** Multiline is a sibling over shared chrome; `LayrzTextInput`'s public API is unchanged.
- **D56** `LayrzSearchInputMode { auto, icon, field }`.
- **D57** `LayrzStepper` owns the whole flow and takes a controller.
- **D58** Responsive option grids use `LayrzCol`'s `xs/sm/md/lg/xl` int spans (follow-through on D9).
- **D59** Combobox free-form is opt-out via `allowFreeForm` (default true).
- **D60** Duration units configurable and capped.
- **D61** M3 scope trim: MultiSelect and DualList → M4.

---

## Gotchas worth not rediscovering

1. **The default test viewport is 800×600, which is COMPACT.** `context.isCompact` is < 960px, so
   any test without an explicit viewport exercises the **mobile** path. Cost two agents several
   rounds on `LayrzStepper`, where the component was correct and the tests asserted a layout branch
   it was properly not rendering. Fix:
   `tester.view.physicalSize = const Size(1600, 1200); tester.view.devicePixelRatio = 1.0;
   addTearDown(tester.view.reset);` — the tearDown is not optional or the size leaks.
2. **The pre-commit hook does NOT run tests.** `tool/checks.sh` runs `flutter analyze` plus the
   import guards only. Two branches were pushed green-hooked carrying 35 and 7 failing tests.
3. **Dart generics are reified.** `find.byType(RawRadio)` resolves to `RawRadio<dynamic>` and will
   not match `RawRadio<String?>`. Use `find.byWidgetPredicate((w) => w is RawRadio)`.
4. **`tester.tap(find.byType(SomeInput))` taps the widget's CENTRE** — label + field + error area —
   which often misses the interactive field. Tap `EditableText`, `LayrzInputChrome`, or visible text.
5. **Use three-dot diffs.** `git diff development..<branch>` compares tips and reports files added
   to `development` after the branch point as *deletions*. This aborted a merge on a false alarm.
6. **`pump_themed.dart` builds a fresh `OverlayEntry` every call**, so its subtree rebuilds from
   scratch and `didUpdateWidget` never fires for anything under it. Blocks any test that needs a
   widget *update* (see the skipped `LayrzStepper` controller-swap test).
7. **`LayrzAnchoredPanel` is a widget, not a route.** Two components tried pushing a custom route
   and hit `route.overlayEntries.isNotEmpty: is not true`. Working example:
   `lib/src/inputs/src/search_input.dart:241`.
8. **Overlay content IS findable in tests** — `test/overlays/anchored_panel_test.dart` does it with
   plain `pumpThemed` + tap + `pumpAndSettle` + `find.text`, including rect comparison at lines 78-79.
9. **Give every parallel agent `isolation: "worktree"`.** Three agents sharing the main checkout
   collided and had to have their work salvaged as patches.

---

## Release

`0.0.12` → **`0.0.13`** once DESIGN-40 and DESIGN-44 land. Nothing breaking: `LayrzTextInput`'s
public API is byte-identical by design (D55). Coverage is **90.44%** against a 90% CI floor —
under half a point of headroom, so check the delta before each remaining merge.

## Branch inventory

Merged and safe to delete: `DESIGN-34-textarea`, `DESIGN-35-combobox-rebased-final`,
`DESIGN-36-number`, `DESIGN-38-checkbox-switch`, `DESIGN-39-radio-rebased`,
`DESIGN-40-select-item`, `DESIGN-42-search-rebased`, `DESIGN-87-stepper`,
`overlays/anchored-panel`, `sheets/DESIGN-97`, `fix/steppers/controller-and-assertion`.

Stale duplicates, ignore: `DESIGN-35-combobox`, `DESIGN-35-combobox-rebased`, `DESIGN-39-radio`,
`DESIGN-42-search`, `DESIGN-40-select`, `feat/inputs/internal-lock-suppression` (empty).

**Active:** `feat/inputs/DESIGN-40-select-rebased`, `feat/DESIGN-44-finish`.

Unrelated pre-existing risk: **`feat/layout/DESIGN-61-review` has ~1065 staged-but-uncommitted
insertions across 9 layout files, local only, in a stale worktree** — one `git worktree remove`
from being lost. Never triaged.

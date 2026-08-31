# Changelog

## 0.0.16

**Seven new components land together: `LayrzCalendar`, `LayrzProgressBar`, `LayrzTimeline`, `LayrzTreeView`, `LayrzBadge`, `LayrzRefreshIndicator` and `LayrzPageTransitions`.** These were built as prerequisites that M4 depends on, which is why they carry M5/M6 phase assignments rather than M4 ones.

`LayrzCalendar` now ships all three modes. Day view is a single column over a fixed 24-row 00:00–23:00 hour axis; week view is seven such columns sharing one axis and one all-day/multi-day band; month view is unchanged in shape. The mode switcher is unlocked — `LayrzCalendarMode.week` and `.day` are reachable, not stubbed. Navigation follows the active mode: `LayrzCalendarController` gains `nextWeek`, `previousWeek`, `nextDay`, and `previousDay`, so the arrows step by the unit actually on screen — previously every arrow moved by a month and announced itself as such, even while week mode was showing. Disabled dates and single-day events render as before; multi-day entries now get stable per-month lane packing, so a bar holds one lane index across every week row it spans, with a worthwhile accepted consequence: a day can show blank reserved lanes above its content, because lower lanes are held by entries occupying that day in a different week of the same month. Correct and deliberate, not a layout bug. Overlapping timed events in week and day split their column evenly, with the later start drawn over a demoted rendering of what it covers. Grid lines still come from a `divider`-coloured container with each cell inset by `tokens.border.stroke1`, so every line is exactly one stroke wide — per-cell borders produced double-width interior lines against a single-width outer edge — and today's ring remains a deliberate accent, not a grid line. Month names and AM/PM markers are now localized via `LayrzUiL10nMonthsMixin`, closing the gap that shipped with pass 1.

**`LayrzCalendar` also gains a new interaction surface.** `LayrzCalendar.onTap` (`void Function(DateTime)?`) returns midnight in month view and a 15-minute-snapped time in week/day — the snap governs the returned value, not the hit target. `LayrzCalendarEntry.onTap` is a `VoidCallback?` on the **entry** itself, wired per entry at construction, with deliberately no `onEntryTap` on the calendar — the intended pattern is that an app extends `LayrzCalendarEntry` with its own fields and wires `onTap` on the subclass, so the handler already has the app's object in scope without a cast. Two caveats worth knowing before they're hit in practice: `onTap` is excluded from `==`/`hashCode` (closures compare by identity), and since the base `==` only checks `runtimeType`, two instances of the *same* subclass differing only in fields that subclass added compare **equal** unless the subclass overrides `==`/`hashCode` itself (`super == other` plus `Object.hash(super.hashCode, myField)`); and `LayrzCalendarEntry.onTap` cannot be cleared through `copyWith` — it is fixed at construction, so turning interactivity off means rebuilding the entries. `isPreview` on `LayrzCalendarEntry` renders a ghosted outline with translucent fill for a provisional event, participating normally in lane packing and overlap ordering. `dayNumberOpensDayView` (default `true`) and `showWeekNumbers` (default `true`, an ISO 8601 week-number gutter, each row tappable to open week view, numbered by the ISO week of each row's own first day — ISO defines weeks as Monday-start while the calendar's own default is Sunday-first, and the numbering follows the ISO convention regardless) round out navigation. Text is no longer selectable anywhere in the calendar.

How many events a cell shows is now derived from measured cell height rather than a fixed cap — `kLayrzCalendarMaxVisibleEvents` (previously a hardcoded 3) is removed. The `+N` overflow chip is tappable and opens day view for that date. `LayrzCalendarDayCell`'s `reservedMultiDaySlots` (a bare `int`) became `reservedLaneIndices` (a `Set<int>`), a constructor change needed to express sparse lane occupancy — a cell can reserve lane 2 without reserving lane 1.

`LayrzTimeFormat { amPm, h24 }` is new, defaulting to `h24`, and governs the hour axis and time rendering in week and day views. Month view is unaffected either way — month cells render titles, never times.

**BREAKING: `LayrzCalendar.firstDayOfWeek` defaults to `DateTime.sunday`, not `DateTime.monday`.** The parameter is new — the shipped code had no override and was hardcoded Monday-first — but the default chosen for it does not match what was already running, so any caller who passes nothing sees a different grid after upgrading, in both month and week views. Migration for a caller that wants the old grid: pass `firstDayOfWeek: DateTime.monday` explicitly. This is flagged as breaking on the same footing as 0.0.15's `LayrzStepper.direction` entry despite `LayrzCalendar` never having reached pub.dev either — 0.0.16 is still unreleased (pub.dev is on 0.0.15), so no published consumer is actually affected, but the grid a caller sees does change from what pass 1 of this same entry shipped, and that is worth recording plainly rather than silently.

`LayrzProgressBar` covers both formats via `LayrzProgressFormat { linear, circular }` — linear at 16 logical pixels with a `radius.r1` rounded-box corner (the design system prefers rounded boxes over pills), circular at 50×50 with a 4px stroke, both caller-overridable. Determinate and indeterminate work in both formats; `value: null` is indeterminate and `value: 0.0` is determinate-at-zero, and those stay distinct. The indeterminate sweep now runs on a new `LayrzMotionTokens.dIndeterminate` (1500ms), matching `LayrzButtonIndicator`'s cycle so two loading affordances on one screen do not visibly disagree — it previously borrowed `dDialog` (300ms), which read as frantic.

`LayrzTreeView` (and `LayrzSliverTreeView`) builds on the SDK's `TreeSliver`/`TreeSliverNode`/`TreeSliverController` rather than a hand-rolled tree engine. `selectionMode` ships **both** `independent` (the default) and `cascading`, the latter with a partial/indeterminate state; the selection layer lives in its own file with zero imports from the SDK tree types, so either mode can change without reworking the integration. Arrow keys navigate: Up/Down across visible rows, Right expands or descends, Left collapses or ascends — and they never mutate selection. Selection is marked by the checkbox alone; there is no row background fill.

`LayrzRefreshIndicator` is **loading-affordance-first**: the programmatic `refresh()` is the primary API and the drag gesture is optional and touch-only, because a drag needs a finger and this library is desktop-first. The indicator floats over its child in a `Stack` and never displaces list content. A built-in fallback refresh button appears when `LayrzPlatform.isTouchOS` is false, so a desktop user is never left without a way to refresh — `LayrzRefreshFallbackButtonMode { auto, enabled, disabled }` overrides it. A mouse wheel cannot fire a refresh: the overscroll read is gated on a real drag.

`LayrzTimeline` renders events on both sides of a vertical spine and **auto-collapses to one-sided below `context.isCompact` by default**, not behind a flag — two columns straddling a spine are unreadable at phone width. Screen-reader traversal follows the `entries` list order regardless of which side a card lands on visually.

`LayrzBadge` overlays a child or renders inline, with a number, an icon, or a bare dot. Counts above 99 render as `99+`. `label` is required, deliberately, so every call site supplies an accessible description — the badge and its anchor announce as one merged idea ("Notifications, 3 unread"), never a detached number.

`LayrzPageTransitions` provides `fade`, `slide`, `scale`, `rotation` and `none` as bare builder functions. **No `go_router` dependency is added** — `PageRouteBuilder.transitionsBuilder` and go_router's `CustomTransitionPage.transitionsBuilder` are the identical type, so one function serves both. `LayrzApp` gains `pageTransitionType` (default `fade`), applied automatically to routes `LayrzApp` builds itself; router-based callers read the ambient value via `LayrzApp.pageTransitionTypeOf(context)` and apply it to their own route builders, which is documented rather than pretended otherwise.

`LayrzButton` gains `tooltipPosition`, defaulting to `LayrzPreferredSide.bottom`, threaded through the main constructor and all six semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`). Previously every button built its own tooltip internally with no position argument, so it always opened downward — a button sitting near the top of its content had its tooltip cover whatever was below it on hover. Not breaking: the default reproduces the old behaviour exactly.

**BREAKING: `LayrzChipStyle.filledTonal` is removed.** `LayrzChipStyle` now has exactly `filled` and `outlined`, and the default is `filled`. Any caller passing `LayrzChipStyle.filledTonal` must choose one of the two remaining values.

**BREAKING: `LayrzProgressBarType` is renamed to `LayrzProgressType`.** Call sites are unaffected — the `type:` parameter keeps its meaning and its position, and the new format axis is a separate additive `format:` parameter. Only code that names the enum explicitly in a type annotation needs updating.

**`LayrzScaffoldShell` becomes hinge-aware, splitting its list and detail panes on a foldable device's own physical seam instead of an arbitrary breakpoint (decision D73).** A new `resolveFoldSplit` (`lib/src/scaffold/src/fold_split.dart`) reads `MediaQuery.displayFeaturesOf`, maps each `DisplayFeature`'s bounds — reported in whole-view coordinates — into the shell's own local box via a `RenderBox` walk, and hands back a `LayrzFoldSplit` describing the axis and the two pane extents. That mapping step is load-bearing, not defensive: on a Galaxy Z Flip 3, treating view-space bounds as already shell-local misplaces the divider by a measured **49.9dp in portrait** and **110.0dp in landscape**, where `LayrzLayout`'s 178px rail compounds the offset. A vertical hinge now forces the side-by-side split regardless of the shell's resolved band — this is what fixes an unfolded Z Fold's ~904dp portrait width, which sits below the 960dp `sm`→`md` threshold and previously got the narrow list-plus-sheet presentation despite having ample room for two real panes. `LayrzBreakpointTokens` itself is untouched; the fold override sits above `bandAt`'s outcome, not inside it. The resulting panes are legitimately asymmetric where a rail has already eaten part of one side — measured at 282.9dp / 502.9dp in the landscape case above — and the implementation does not force them equal. `DisplayFeatureType.cutout` is always excluded (a real Z Flip 3 reports a camera cutout at `LTRB(192, 0, 219, 36)`, and splitting there would be a bug, not a feature), and `DisplayFeatureState.postureHalfOpened` is treated exactly like `postureFlat` — a Pixel 10 Pro Fold emulator boots directly into `postureHalfOpened` with a viewport identical to `postureFlat` in every measured respect, so excluding it would have quietly sent that device back to the narrow layout.

**A horizontal seam never produces a split, full stop — only a vertical seam (one taller than it is wide) ever does.** An earlier pass built a stacked top/bottom layout for a horizontal seam plus a rule that promoted the detail into a `LayrzBottomSheet` whenever the keyboard opened, and both were deleted after testing on real hardware. On a Z Flip in portrait, the promotion destroyed the very focus that had opened the keyboard, which closed the keyboard, which reverted the promotion, which restored focus and reopened the keyboard — an oscillation that made typing in the detail pane impossible. On a Z Fold in portrait the same keyboard rule never even fired, since a vertical seam had no presentation switch tied to it, so the shell simply collapsed to a crushed, unusably short layout with nothing guarding it. `resolveFoldSplit` (`lib/src/scaffold/src/fold_split.dart`) now classifies a horizontal seam's axis purely for documentary value and then always returns `null` for it, falling through to the shell's ordinary `bandAt` behavior exactly as if no `DisplayFeature` had been reported.

**A new `kLayrzFoldMinSplitHeight` (`480.0`) gates the vertical split on the shell's own height, and this single guard is what makes the split retract when the keyboard opens — no keyboard-aware code exists anywhere in the fold path.** A vertical seam can map to two comfortably wide panes on a shell that is nonetheless far too short to use — measured on a Z Flip rotated to landscape, whose 502.9dp-wide panes sit on a shell only 411.4dp tall — so `minSplitHeight` guards the shell's main axis, a distinct concern from the existing `minPaneExtent` cross-axis pane-width guard. The valuable side effect: a Z Fold in portrait measures `731.9dp` tall with the keyboard down and `435.0dp` with it up, straddling the 480dp threshold in exactly the right direction, so the split simply disappears the moment the keyboard opens and reappears when it closes — the same outcome the deleted keyboard-promotion rule was chasing, produced here as a consequence of the shell getting shorter rather than a presentation switch keyed off `MediaQuery.viewInsetsOf`.

**When more than one vertical seam qualifies at once, `resolveFoldSplit` picks the one nearest `kLayrzFoldPreferredListFraction` (`1/3`) of the shell's width, not simply the first.** This matters on the Galaxy Z TriFold (shipped hardware), whose inner display reports two qualifying seams at once. The remaining seam is absorbed into the detail pane and only the chosen seam's divider is drawn; a tie is broken toward the leading-most candidate, deterministically, so the result never depends on the order `MediaQuery.displayFeaturesOf` happens to report seams in.

The shell's split stays fully live — reactive to a fold appearing or disappearing, a posture change, or a rotation — rather than resolved once and frozen. Decision D73 exists specifically to state why this does not conflict with D69's decide-once rule: D69 governs modal routes, which cache a page widget and cannot safely re-resolve it; the fold split is an inline, route-free rearrangement of already-mounted panes, the same kind of live input `bandAt` already was under D37. Every transition this adds (popping the narrow sheet when a fold appears, when posture changes, when the shell rotates) goes through the same post-frame discipline that already guards the 0.0.14 `setState`-during-build crash class, so that crash class does not come back.

`ListPanel` gains an optional `width` (`lib/src/scaffold/src/list_panel.dart`), defaulting to the existing fixed `300`. This is **not breaking** — no existing caller passes it, and the fold split is the only caller that does, sizing the leading pane to the mapped seam position instead of the panel's usual fixed width. The whole feature is additive: a non-foldable device reports no usable `DisplayFeature`, `resolveFoldSplit` returns `null`, and the shell's existing width/narrow behaviour is byte-for-byte unchanged.

## 0.0.15

**`LayrzStepper` is rebuilt to actually run at full page size, and its compact mode is no longer a single line of text (BREAKING on narrow viewports).** The stepper's own design intent was always to run full-width, header spanning the whole section with steps connected by a line — but the shipped wide layout scrolled horizontally instead of spanning, and its step indicator and label lived in one centre-aligned `Column`, so a step whose label wrapped to two lines grew taller than its neighbours and visibly shifted its own circle out of line with the rest — the literal bug this redesign exists to fix. The wide layout (`stepper_wide.dart`) is now a row of equal-width flex cells; each cell stacks a fixed-height indicator-and-connector band over a label band, so the indicator band's height can never depend on the label band's content, and no label, however long, can shift an indicator out of alignment with its neighbours. Labels wrap to 2 lines with an ellipsis and no recovery affordance — a truncated label stays truncated, deliberately. **The breaking part:** below the 960px compact breakpoint, the header previously collapsed to a single non-interactive line, `"Step X of Y"`, and nothing else — no indicators, no labels, no way to see or reach any step but the current one. It is replaced by `stepper_compact.dart`, a vertical accordion: every step renders as a header row, and only the active step's body expands inline beneath its own header via `AnimatedSize` (the first use of `AnimatedSize` in this library). Exactly one step is ever open, driven by `currentIndex` — this is explicitly not a general-purpose accordion, and locked (`upcoming`) steps can never be opened no matter how many times they are tapped. A persistent "Step X of Y" counter still renders above the stack, so the fast at-a-glance answer to "how much is left" is not lost to the new, more informative layout. Any consumer relying on the old one-line compact summary, or on `LayrzStepper` fitting inside a fixed-height box smaller than its content, will see a visibly different — and taller — result on narrow viewports.

Two smaller, additive changes ride along: `LayrzStep` gains an optional `icon`, an identity glyph shown in the indicator while `upcoming` or `active` — but it is always overridden by the state glyph (`MdiIcons.check` / `MdiIcons.alertCircle`) once a step becomes `completed` or `error`, per decision D57's unamended WCAG 1.4.1 clause, so adding an identity icon cannot make a step's status colour-only. And `error` steps are now genuinely tappable in both layouts, matching a promise `LayrzStepperState.error`'s own doc comment already made ("can be jumped to for correction") that the previously-shipped code did not keep. See decision D57's 2026-08-27 update for the full reasoning, including why no maximum step count is enforced and why the two layout widgets (`LayrzStepperWideHeader`, `LayrzStepperCompactLayout`) stay unexported while the indicator they share, `LayrzStepIndicator`, is exported.

**`LayrzStepper.direction` replaces the `bool? isCompact` override, and is now required — this change is not breaking for any released consumer.** The redesign above shipped `isCompact` in this same Unreleased batch, and it never reached pub.dev, so there is no shipped caller to break. It is still worth a dedicated entry because the API it replaces was wrong in a way that was caught immediately: `isCompact` let the stepper fall back to deriving its layout from `context.isCompact` (viewport width) whenever the override was left `null`, and that inference is exactly what produced the showroom's own overflow — a demo page labelled "wide" that, on a narrow window, silently rendered the compact accordion inside a box sized for the wide header, and overflowed. An implicit width-derived layout switch inside a component whose caller believes they already chose a layout is a trap, not a convenience. `LayrzStepper` now takes a required `direction: LayrzStepperDirection` (`horizontal` or `vertical`) and reads `context.isCompact` nowhere at all. A caller reproducing the old derived behaviour writes it explicitly:

```dart
direction: context.isCompact
    ? LayrzStepperDirection.vertical
    : LayrzStepperDirection.horizontal,
```

`LayrzStepperDirection` is a new enum at `lib/src/steppers/src/stepper_direction.dart`, exported from `steppers.dart` alongside the rest of the stepper API.

**`LayrzComboBoxInput`'s mobile bottom sheet gains a search field and an accessible name (DESIGN-161).** The sheet previously rendered nothing but a bare, unfiltered option list — no search field, no `Semantics`, no heading, no label of any kind — which was a usability defect before it was an accessibility one: a combobox exists specifically because its option list is too long to scroll comfortably, and the mobile sheet had lost the only way to narrow it. `BottomSheetContent` (`combobox_surface.dart`) now mirrors `LayrzSelectInputSurface`: it owns its own live search field that filters the options pool as the user types, and wraps itself in a `Semantics` node naming what is being picked — the field's own label, invisible behind the modal barrier while the sheet is open, is otherwise the only thing that ever named this content.

**`LayrzTappable.onTap` no longer fires twice on a double-tap (DESIGN-162).** With only `onTap` wired, `GestureDetector`'s tap recognizer resolved each tap of a double-tap independently and fired the callback once per tap — measured at exactly 2 calls for 2 taps. The obvious-looking fix, giving the `GestureDetector` a real `onDoubleTap` recognizer so the arena treats the two taps as one gesture, was tried and rejected: it made `onTap` fire **zero** times on a double-tap instead of once, and it cost every single tap in the library a full `kDoubleTapTimeout` (300ms) of added latency waiting to see if a second tap was coming. The shipped fix is a per-`State` `Timer` cooldown instead — `onTap` fires immediately on the first tap of a pair (no added latency) and a second tap inside the cooldown window is swallowed, so a double-tap collapses to exactly one call and a single tap is exactly as fast as before. **Not fixed, and not claimed to be fixed:** double-tap-to-select on text inside an active `LayrzTappable` (via an ancestor `SelectableRegion`) remains unavailable. This is a pre-existing limitation, not a side effect this change restores — the `GestureDetector`'s tap recognizer still wins the gesture arena over `SelectableRegion`'s own recognizer regardless of what the callback does afterward, so the fix that makes `onTap` well-behaved cannot also un-claim the gesture arena.

**`LayrzAnchoredPanel.controller`'s no-swap contract stays debug-only, and now says so honestly (DESIGN-146).** The contract has always been enforced by a debug-only `assert` in `didUpdateWidget`, silently compiled out in release — so a release-mode controller swap was previously undocumented as a silent no-op, contradicting a doc comment that implied the assertion always held. Making it throw in release was tried and measured, not just discussed: throwing from `didUpdateWidget` mid-rebuild through this widget's real tree corrupted the framework's own `_InactiveElements` bookkeeping badly enough to fail 7 unrelated tests. Since no caller anywhere in this library ever passes a controller to `LayrzAnchoredPanel`, that trade — a corrupted element tree for a hypothetical caller against a properly documented no-op for zero current ones — was rejected. The doc comment now states plainly that a release-mode swap is silently ignored. See decision D71 for the measurement and the rationale not to revisit it without re-confirming the hazard is gone.

**`LayrzSlider` — a Material-free, single-value slider.** `LayrzSlider` (`lib/src/inputs/src/slider/`) picks a numeric value from a continuous or quantised `[min, max]` range by dragging or tapping a horizontal track, or via the keyboard once focused. There is no `RawSlider` in the Flutter SDK, so the track, thumb, hit-testing, drag handling, quantisation, and keyboard interaction are all hand-built on `GestureDetector` and `CustomPaint`. The track paints at 8 logical pixels; the thumb is a 28px rounded square whose elevation varies with interaction state (flush and shadowless at rest, rising slightly on hover/press) rather than its size, per D15. `divisions` quantises the value to the nearest step. A value label above the track is always visible by default (`showValueLabel`), and a small drag-only bubble additionally appears directly above the thumb while dragging, its tail pointing down at the thumb, painted outside the track's layout box so its appearance never reflows the control. Keyboard support covers Left/Down/Right/Up (one step) and Home/End (min/max). A `Semantics` node exposes `slider: true`, an announced value, and `increase`/`decrease` actions for screen-reader operation. Per decision D63, `LayrzSlider` is a control with a label, not a bordered field — it does not compose `LayrzTextInput` or `LayrzInputChrome`, matching the checkbox/switch/radio family. The invisible hit region is 44 logical pixels tall over a 36px painted area, so touch slightly above or below the thin track still registers.

**`LayrzDialog` — a Material-free modal dialog.** `LayrzDialog` (`lib/src/dialogs/`) is a centered, size-bounded panel behind a modal barrier, built on `RawDialogRoute` with no Material dependency. It offers named `title`, `content`, and `actions` slots for the common "title + body + confirm/cancel" shape, plus a `child` escape hatch for layouts none of those slots can express (an assertion enforces choosing one or the other, not both). A close ("X") affordance sits at the trailing edge of the title row when dismissible, or floats over the panel's top-right corner when there is no title row. Dismissing restores focus to whatever invoked the dialog. `canDismiss` (default: inferred — `true` with no `actions`, `false` when `actions` is supplied) gates four dismiss routes together as a single switch: barrier tap, Escape, the X icon, and the system/Android back gesture. When `actions` is present and `canDismiss` stays `false`, the X icon is not rendered at all, rather than shown disabled — a decision-bearing dialog is meant to be answered through its own actions, not half-escaped through a stray click. Opening a second `LayrzDialog` while one is already open is not supported in this version and asserts rather than silently stacking two barriers.

**`LayrzResponsiveModal` — one call, dialog or sheet depending on viewport.** `LayrzResponsiveModal` resolves to a `LayrzDialog` on wide viewports and a `LayrzBottomSheet` on narrow ones (the same `isCompact` / 960px boundary as elsewhere), decided once at `show()` call time and never re-evaluated — resizing the window mid-route does not swap the surface, a deliberate non-goal recorded in D69 with 0.0.14's `LayrzScaffoldShell` breakpoint-crash as the shipped precedent for the failure this avoids. A single `builder` supplies content for both branches; the dialog branch receives it through its own `child` escape hatch rather than the structured `title`/`content`/`actions` slots, so a caller wanting those slots calls `LayrzDialog.show` directly instead.

**`LayrzModalRoute` — the sheet's double-pop guard, now shared.** The barrier, reduce-motion handling, and — most importantly — the four-site `isCurrent` guard before every `Navigator.pop()` that fixed 0.0.14's release-only data-loss bug (a fast double tap on the barrier popping the caller's own page along with the sheet) are extracted from `LayrzBottomSheet`'s route into a new shared base, `LayrzModalRoute`. `LayrzBottomSheet`'s route and `LayrzDialog`'s route both extend it now, so any future modal surface inherits the guard by construction instead of re-typing it. This changed no public API and no behaviour of the shipped sheet — all existing `test/sheets/` tests pass unmodified.

**`LayrzBottomSheet` gains `canDismiss`, and the system/Android back gesture is now actually handled.** `LayrzBottomSheet.show` had no back-gesture handling at all despite its own doc comment claiming otherwise — that comment shipped in 0.0.14 describing a `PopScope` that had never been implemented. A new `canDismiss` parameter, defaulting to `true` (every existing caller is unaffected), now gates the barrier tap, Escape, drag-to-dismiss, and a real `PopScope` for the back gesture, together as one switch — mirroring `LayrzDialog`'s own `canDismiss` contract as closely as the sheet's shape allows. It composes with `isPersistent` on a separate axis rather than collapsing into it: `isPersistent` decides whether a barrier exists at all, `canDismiss` decides whether whatever routes do exist are allowed to act, so a persistent, non-dismissible sheet has no barrier to gate but still blocks Escape/back/drag, and a modal, non-dismissible sheet additionally paints a barrier that does not dismiss on tap. The drag handle keeps rendering and keeps resizing the sheet across its snap points either way — only a drag past the dismiss threshold is disabled, snapping back to the nearest snap point instead of popping. `LayrzResponsiveModal.canDismiss` now reaches both branches instead of only the dialog: previously a caller passing `canDismiss: false` got a non-dismissable dialog on a wide viewport and a freely-dismissable sheet on a narrow one, silently, since the flag was dropped on the sheet branch entirely.

**`LayrzBottomSheet` gains an `actions` slot.** A new optional `actions` parameter renders a right-aligned button row, pinned below the builder's content as a sibling in the sheet's own `Column` rather than nested inside its scroll view — matching how `LayrzDialog`'s own `title`/`actions` stay outside its content scroll area — so a tall builder scrolls independently while `actions` stays fixed at the bottom, and reachable above the on-screen keyboard rather than behind it. An action's own callback can dismiss the sheet even when `canDismiss: false`, the same "answered, not escaped" path the dialog's actions already have. Unlike the dialog, `actions`'s presence does not change `canDismiss`'s default: the sheet's `builder` can already contain its own buttons with or without this parameter, so `actions` is a weaker dismissibility signal here than it is for a dialog whose only way to offer a decision is that slot. No close ("X") affordance is added — a sheet is still dismissed only by swiping, tapping the barrier, or its own content.

**`LayrzBottomSheet.show`'s default `snapSizes` is now derived from `minSize`/`maxSize` instead of hardcoded.** The default was the literal `[0.5, 0.95]`, valid only against the method's own default `maxSize` of `0.95`. A caller narrowing `maxSize` — `maxSize: 0.5`, say — without also supplying `snapSizes` got a default snap point above their own ceiling, and `DraggableScrollableSheet` asserted on open. The default is now computed from the actual `minSize`/`maxSize` range, and the bounds/ascending-order checks run on that effective list regardless of whether it came from the caller or the derivation, closing the one path that previously went unchecked. Untouched defaults still produce `[0.5, 0.95]` exactly, so no existing caller's behaviour changes.

**Touch-only text-selection tooling (DESIGN-147).** The magnifier, drag handles, and selection action menu are now gated to Android and iOS — via web or native — everywhere they appear: the five inputs behind `editable_field.dart`, `LayrzLayout`'s expanded and drawer `SelectableRegion`s, and `DetailPane`'s `SelectableRegion`. The gate is a new getter, `LayrzPlatform.isTouchOS`, which reads `defaultTargetPlatform` directly instead of routing through `LayrzPlatform.current` — `current` short-circuits on `kIsWeb`, which is exactly why the previous `!LayrzPlatform.isMobile` predicate on the magnifier silently lost it on mobile web; `isTouchOS` fixes that latent bug at its source in the same change. **The consequence is real and is recorded honestly, not glossed over**: on native desktop and desktop web, this removes the selection action menu — this package's de facto replacement for right-click copy/paste — leaving keyboard shortcuts (Ctrl+C/Cmd+C, etc.) as the only remaining route to copy or paste selected text on a mouse-driven desktop app. Decision D67 records the team vote behind this, the milder alternative that was knowingly set aside, and the touchscreen-laptop edge case this predicate does not cover.

**`wiki/Input-Contract.md` corrected.** It previously described every `Layrz*Input` as composing `LayrzTextInput` as a shared base — the opposite of D63, which forbids that pattern precisely because it had already produced three shipped defects (dropped `errors`, a search input that could show no error at all, a duplicated border). The page now describes each input composing its own editing primitive and `LayrzInputChrome` directly, and calls out `LayrzSlider` alongside the checkbox/switch/radio family as excluded from the input-chrome contract entirely.

### Breaking

**`LayrzStepper.isCompact` is deleted; `direction` is required in its place.** See the dedicated entry above. Not breaking for any released consumer — `isCompact` was introduced earlier in this same Unreleased batch and never shipped to pub.dev.

**`useRootNavigator` removed from `LayrzBottomSheet.show`.** Every modal surface now always presents on the root navigator; this is intrinsic rather than caller-configurable. Under a `go_router` `ShellRoute`, whose nested navigator is built inside the page body, a non-root presentation put the sheet's overlay inside the page's own subtree, where its barrier failed to cover chrome such as a top bar — only one value was ever actually correct, so the parameter offered a choice that should not have existed. `LayrzDialog` and `LayrzResponsiveModal` ship for the first time in this entry with the same root-navigator behaviour built in from the start, so this break is scoped to `LayrzBottomSheet`, the one surface with prior published callers.

## 0.0.14

**Bottom sheets now respect the system bars and the keyboard.** `LayrzBottomSheet`'s surface still runs edge-to-edge under the status and navigation bars, but its content is inset clear of them — previously the first field was clipped under the status bar and the last one sat behind the navigation bar. When the keyboard opens, the sheet shrinks to the space remaining above it and pins itself there: its expansion controls go inert for as long as the keyboard is up, since there is nothing left to expand into, while drag-to-dismiss keeps working so a sheet can still be swiped away mid-typing. Closing the keyboard restores the sheet's exact previous size rather than snapping it to full height.

**`LayrzScaffoldShell`'s narrow detail sheet is presented on the root navigator.** It was pushed to the nearest navigator instead, which — under a `go_router` `ShellRoute`, whose nested navigator is built inside the page body — placed the sheet's overlay *inside* the page's `SelectableRegion`. Two consequences went with it: a gesture on the sheet's own text could resolve against the page content behind it, selecting a list row instead; and the sheet's barrier was bounded by the page body, so it never covered the top bar. Both are fixed by the same change.

**`DetailPane` content is selectable in its own scope.** Text in the detail pane can now be selected and copied — in the side-by-side layout and in the narrow sheet alike — scoped to the pane, so a selection there can no longer reach the page behind it.

### Fixed

- `LayrzLayout` did not resize for the keyboard: the body was anchored to a viewport that never shrank, so an open keyboard covered page content with nothing to scroll to. The body's available height is now reduced by the keyboard inset and the inset is zeroed for its subtree, in both the rail and drawer presentations (see decision D65).
- A phantom leading gap — the height of the status bar — appeared above the first item of any scrollable in the page body on Android. The top bar consumed the status-bar inset for itself without removing it from the `MediaQuery` the body received, so a `ListView` with no explicit padding applied it a second time. Fixed for both the drawer and expanded presentations.
- `LayrzScaffoldShell` threw `setState() or markNeedsBuild() called during build` when the viewport crossed the compact breakpoint with its detail sheet open.
- Tapping a bottom sheet's barrier twice in quick succession popped the route underneath it as well as the sheet. In a release build this silently dismissed the caller's own page.
- `LayrzSearchInput` in icon mode announced its label twice to screen readers: the panel field's hint and the trigger button's label are the same string by construction, and the hint was contributing its own accessible name.
- Every `LayrzTappable` row in `LayrzScaffoldShell`'s list rendered 6 logical pixels shorter than its own row. The row's outer margin was subtracted from a fixed `itemExtent` rather than adding space between rows, leaving an unstyled gap and an undersized tap target.
- `LayrzTextTheme` font sizes were reduced: `display` 40→30, `title` 20→18, `body` 16→14, `label` 14→12.

### Breaking

**`isCompact` no longer varies input padding.** `LayrzInputChrome` previously used a larger internal padding on compact viewports (14px, versus 10px on wide) to keep touch targets comfortable on mobile. That branch is removed: padding is now 10px by default and 6px with `dense: true`, identically on every viewport. Field heights are correspondingly flat at 43px default and 35px dense, where compact fields were previously 55px. **Every input now renders below the 44–48px minimum commonly recommended for touch targets, on mobile as well as desktop.** This was accepted deliberately in favour of a uniform, denser scale; a caller who needs larger targets on mobile must now size around the field rather than relying on the chrome. Decision D66 records the measured heights and the trade-off, and supersedes its own earlier rationale for keeping the compact branch.

**Icon size no longer tracks the type scale.** `LayrzInputChrome` derived its icon size from `LayrzTextTheme.body.fontSize`, so icons grew and shrank with the type scale. It is now a fixed value. A future change to `body` will not propagate to input icons.

## 0.0.13

**The picker inputs now share one elevated panel, and its border sits on the panel instead of inside it.** `LayrzAnchoredPanel` gains an optional `border`, of type `LayrzAnchoredPanelBorder`, painted around the box that wraps its scroll view — the box actually bounded by `maxHeight`. Before, each caller hand-rolled a bordered container *inside* that scroll view, where `SingleChildScrollView` relaxes its child's height to unbounded: with 30 items in a 300px-capped panel the border box measured 1260px, so the stroke ran 960px past the visible edge and cut horizontally through a list row. `LayrzSelectInput` and `LayrzSearchInput` both drop their own bordered box and consume the panel's. The border is painted with `strokeAlignOutside`, so it occupies no layout space and the panel's rect is unchanged.

**`LayrzComboBoxInput` is rebuilt on `LayrzAnchoredPanel`, and the open panel's first row is the live text input.** The hand-rolled `RawMenuAnchor`, its private layout delegate, and its own background and shadow are gone; `LayrzComboBoxInput` now covers its anchor exactly as `LayrzSelectInput` does. Typing continues into the panel with no character loss and no caret jump — the closed field and the panel row are one element, reparented rather than rebuilt. The panel row draws no border of its own (a bordered box inside an already-bordered panel read as a search bar floating in a dropdown), with its padding compensated so the text stays aligned with the closed field.

**`LayrzDurationInput` gets the same panel chrome, fills the anchor's width, and stays open while you edit it.** The panel matches the anchor's width instead of a fixed 280–480 band, and its unit fields wrap to additional rows rather than shrinking below a usable minimum. Tapping a field's `+`/`−` control, or typing into one, no longer dismisses the panel: every field edit and the Reset button previously shared a single `onChanged` callback that the owner treated as "close", so the panel closed on every keystroke. Reset now has its own `onReset` callback and is the only thing that closes it.

**Label and error text move outside the anchor on `LayrzComboBoxInput`.** Both were rendered inside the widget handed to `LayrzAnchoredPanel` as its anchor, so the anchor's rect included the label and the panel opened 24 logical pixels too high, covering the label instead of the field. They now compose around the anchor, matching `LayrzSelectInput` and `LayrzDurationInput`.

### Fixed

- `LayrzDurationInput`'s closed field rendered its summary as blank for any non-null value. The summary text was wrapped in its own padding inside `LayrzInputChrome`'s fixed-height content box, leaving about 4 logical pixels of paintable height — the text was present and correct, and invisible.
- `LayrzDurationInput` never styled itself as errored. It passed `readOnly: true` into its own style resolution, and `readOnly` outranks `error` in the resolver's precedence, so the danger border and fill could never paint however many errors were supplied. `LayrzDurationInput` exposes no `readOnly` parameter — the flag described an internal fact about the field and silently discarded the caller's error state.
- `LayrzDurationInput`'s field cropped its rounded corners square on the left. The chrome paints an opaque fill flush against the outer container's physical edge, and the outer clip does not reshape a child's own square-cornered fill sitting inside its bounds. The chrome now carries the inset-corrected radius on its outer-facing corners, matching `LayrzNumberInput`'s step caps and `LayrzSelectInput`'s caret.
- `LayrzDurationInput`'s unit fields rendered as decimals (`2.0` hours) and accepted a typed decimal separator. They now render as integers and reject fractional entry at the formatter.
- The error footer on `LayrzSelectInput` and `LayrzComboBoxInput` was gated on `labelText` being non-null, so a field with an error and no label showed no error text at all.
- Text selection is disabled inside checkbox, radio and input chrome content, so a page-wide `SelectableRegion` no longer selects control labels.

### Breaking

**`LayrzComboBoxInput` no longer shows a custom-value confirmation row.** The open panel previously rendered a `Use "…"` row above the suggestions, which committed the typed text when tapped. It is gone: the typed text is already the value, reported live through `onChanged`, and the options below are suggestions rather than a choice that must be made. Free-form entry is otherwise unchanged, and `allowFreeForm` keeps its meaning. Keyboard navigation shifts accordingly — arrow-down now lands on the first suggestion instead of on the confirmation row.

**`LayrzDurationInput`'s panel no longer sizes itself to its content.** It matches the anchor's width. A caller relying on the previous 280–480 logical-pixel band will see a panel as wide as the field.

**`EdgeInsets? padding` removed from all 10 input widgets — replaced by `dense: true` for the density use case, with no replacement for anything else.** `LayrzTextInput`, `LayrzTextAreaInput`, `LayrzSearchInput`, `LayrzNumberInput`, `LayrzSelectInput`, `LayrzDurationInput`, `LayrzComboBoxInput`, `LayrzCheckboxInput`, `LayrzSwitchInput`, and `LayrzRadioInput` all lose their public `padding` parameter. The 7 chrome-owning widgets in that list (all but the checkbox, switch, and radio) gain a new `bool dense` parameter (default `false`) instead: `dense: true` shrinks the field's internal padding from 14px compact / 10px wide down to 10px compact / 6px wide, for dense data-entry contexts — tables of similar fields, admin/ops consoles, filter bars. `LayrzCheckboxInput`, `LayrzSwitchInput`, and `LayrzRadioInput` have no chrome and no `dense` — they simply lose `padding` with no replacement, for API uniformity across the input family. **If a caller was passing `padding` for anything other than reproducing the default or requesting a denser field — an arbitrary value like `EdgeInsets.all(16)` — there is no migration path; the override must be deleted.** This is a pre-1.0 (0.0.13) breaking change, so no deprecation cycle was offered. Migration: replace `padding:` with `dense: true` where the intent was a denser field; delete `padding:` entirely everywhere else. See decision D66 for the full rationale, including the accepted trade-offs on tap-target sizing and on `LayrzComboBoxInput`'s panel-row inset.

**`isRequired` removed from `LayrzSearchInput`.** `LayrzSearchInput` dropped its `labelText` parameter, and `isRequired` existed only to render a required marker (`*`) next to that label — with no label, it had nothing to mark and had already become a no-op. There is no replacement; delete the parameter from any call site.

---

**`LayrzSelectInput`: the field is now the searcher — a deliberate, maintainer-directed spec change, not a bug fix.** `LayrzSelectInput` was behaving correctly as specified: it was a strictly *controlled* component whose field rendered `value` directly, and a caller that did not feed an updated `value` back after `onChanged` saw no visible update on selection — the contract working as designed, reproduced on both the desktop and mobile presentation, with `onChanged` firing exactly once in every case. The maintainer chose to change that contract anyway, knowingly. The field is now editable and is the searcher when `enableSearch` is `true` (the default): there is no longer a separate search box inside the opened surface, and typing directly into the field filters the list live, showing the selected item's label while idle, the typed query while typing, and reverting to the label on blur if nothing was picked. Both `enableSearch` values now self-display from internal state — a pick updates the field's own display immediately, whether or not the caller feeds an updated `value` back — and the dropdown chevron moved out of `suffixSlot` to an external sibling, following `LayrzNumberInput`'s step-button composition, so a caller-supplied suffix no longer displaces it (or is displaced by it). See the Breaking section for the full migration note.

**Text wrapping by default — no silent truncation.** The type scale (`LayrzTextTheme`) no longer bakes `overflow: TextOverflow.ellipsis` into text styles. Text now wraps by default in unbounded space. Components that require fixed-height rendering (buttons, badges, fields, chrome elements) explicitly set `maxLines: 1` and `overflow: TextOverflow.ellipsis` at the render site. This is a **behavioural breaking change**: code that was previously silent-truncating with an ellipsis will now wrap, potentially growing layouts.

The change improves correctness by refusing to hide layout bugs. When a button label is too long, it previously rendered as "Long Label…" silently, hiding the problem. Now it wraps to two lines, alerting the developer to either re-size the button, re-word the label, or explicitly add truncation. See decision D51 for the rationale and three critical facts about how Flutter's text rendering (TextPainter, RichText, Text) actually works — removing the silent truncation from the type scale was essential to correct them.

**Shared `LayrzPreferredSide` for anchored surfaces; `LayrzAnchoredPanel` places on any of four sides.** The tooltip's four-value side vocabulary (`top`/`bottom`/`left`/`right`) moves out of the tooltip module into a new package-level type, `LayrzPreferredSide`, exported from the root barrel. `LayrzTooltip` and `LayrzAnchoredPanel` both now consume it. `LayrzAnchoredPanel` gains a `preferredSide` parameter and can place its panel on any of the four sides (previously vertical-only), with an unconditional flip to the opposite side when the preferred side does not fit. `LayrzSearchInput` gains its own `preferredSide` parameter, forwarded to its panel.

**`LayrzComboBoxInput`: desktop overflow, a completely non-functional mobile sheet, and a double (in practice, up to quadruple) `onChanged`/`onSubmit` fire per selection, all fixed.** The desktop overlay overflowed by exactly `row count × row height − cap` pixels because its own `Container` re-applied the same height cap the enclosing layout delegate already applied, clamping the scrollable's content to its viewport and leaving it unable to scroll. On mobile, the compact combobox opened a `ListView` inside `LayrzBottomSheet`'s own same-axis scrollable — unbounded height, an immediate assertion, and a frame that never completed, for any option count including as few as two. Both are now: the overlay's `SingleChildScrollView` is bounded only by the outer layout delegate and free to scroll past it; the mobile surface is a plain `Column` wrapped in its own `SingleChildScrollView`, with the bottom sheet passed `scrollable: false` so it hands over its `ScrollController` instead of double-wrapping. Fixing the mobile crash also exposed (previously unreachable, because the frame never completed) a selection committing twice, and a separate, deeper cause behind that: `onChanged` fired via both an explicit call and the text controller's own change listener, which itself fires on selection-only echoes from `EditableText`'s internal resync — up to four `onChanged` calls for one selection on a focused field. Fixed by deduplicating on the field's actual text value. See the Breaking section for the two behavioural consequences.

### Breaking

**`LayrzSelectInput` is no longer a strictly controlled component — BREAKING spec change, recorded as such because it must not be mistaken for a bug fix:**
- **The field is now editable and is the searcher** when `enableSearch` is `true` (the default). Previously the field's content was a read-only `Text`; it is now a genuine `LayrzEditableField`. The panel's own search box (and its two internal controllers) is gone entirely — search now happens by typing into the field itself, on both the desktop anchored-panel and mobile bottom-sheet presentations.
- **The field self-displays from its own internal state, on both `enableSearch` values.** A pick (tap, Enter, or arrow-key selection) updates the field's display immediately, whether or not the caller feeds an updated `value` back on the next build. A caller-supplied `value` change is still honored — it reconciles the internal state without clobbering a query the user is actively typing — but is no longer required for a pick to be visible. This is the actual fix for the symptom that motivated this change: a caller that never wires `value` back from `onChanged` previously saw the field never update after a selection; it now does.
- **`enableSearch: false` changes too, even though it is not the default.** It stays a pure picker (not editable), but it now also self-displays from internal state instead of rendering `value` directly — for consistency, so the widget has one display model instead of two.
- **The dropdown chevron moved out of `suffixSlot` to an external sibling.** Before, a caller-supplied `suffixIcon`/`suffix`/`suffixText` silently displaced the widget's own chevron (and vice versa) — the widget's own affordance occupied the caller's slot whenever the caller left it empty. Both slots are now always free for the caller, and the chevron renders alongside whatever the caller supplies. Follows `LayrzNumberInput`'s external-step-button composition.
- **`LayrzInputChrome.readOnly` is now always passed as `false`.** It was already inert before this change — its only observable consequence anywhere in the chrome was the lock icon, and `LayrzSelectInput` already suppressed that via `suppressReadOnlyLock: true` — so no caller-visible rendering depended on it. Documented here because a test asserting `chrome.readOnly == true` will now see `false`.
- **The whole chrome stays tappable, matching pre-redesign behavior.** `LayrzEditableField`'s own tap handling only claims the text content's hit region (the same as `LayrzComboBoxInput`), which would otherwise have narrowed the field's clickable area to the text strip alone — tapping the floating label, or any other padding inside the chrome, would silently do nothing. A `LayrzTappable` fallback around the chrome region (transparent, so it adds no visual tint of its own — the chrome's existing state-driven styling is unaffected) opens the surface for a tap anywhere else in the chrome, while a tap on the text itself still places the cursor, drags to select a range, and long-presses to show touch selection handles exactly as before.
- **Migration:** no parameter renames or removals — the public constructor is unchanged. Callers that already fed `value` back from `onChanged` (the common case) see no behavioral difference beyond the freed suffix slot and the chrome-tap narrowing above. Callers that did not feed `value` back will now see the field actually reflect the user's pick, where before it silently did not.

**Text overflow behaviour** (no API change, no compile-time failure):
- `Text` widgets with no explicit `overflow` that sit in height-constrained space now wrap instead of truncating. Examples: alert titles, tooltip content.
- Components that already set `overflow` explicitly are unchanged (button labels, chip labels, and navigator items all use `RichText` with explicit truncation set).
- **Input error text is now capped at `maxLines: 2` with `overflow: TextOverflow.ellipsis`.** Previously treated as wrappable, device testing revealed that unbounded error text growth reflows the form below. Two lines of validation messaging is legible and useful (e.g., "Must be at least 8 characters, Must contain uppercase letter"), while unlimited growth degrades UX. Consumers relying on longer error messages rendering in full must truncate at the call site or refactor error display.
- Call sites do NOT fail at compile time; the layout simply grows or overflows visibly.
- Wrapped text may push parent layouts, causing reflow of pages. Callers must verify their layouts still fit and re-size or explicitly truncate where space is genuinely limited.
- Migration: No code changes required for text that was already wrapping. For text that grows unexpectedly, add `maxLines: 1, overflow: TextOverflow.ellipsis` to the `Text()` call, or wrap it in a constrained container.

**`LayrzTooltipPosition` removed (no deprecation, no alias)**, replaced by `LayrzPreferredSide` (new type, exported from the root barrel at `package:layrz_ui/layrz_ui.dart`):
- Same four values (`top`, `bottom`, `left`, `right`) and the same semantics as before. `LayrzTooltip.position` still takes the same four values, now under the new type name.
- `positionDelegate`'s signature changes with it — it takes a `LayrzPreferredSide` now, since it is publicly exported.
- Migration: rename `LayrzTooltipPosition` to `LayrzPreferredSide` at every call site. There is no alias; stale call sites fail to compile by design.

**`LayrzAnchoredPanel` — new parameter, a width-clamp fix, and a fallback-placement change:**
- Gains `preferredSide`, of type `LayrzPreferredSide`, **defaulting to `LayrzPreferredSide.bottom`** — existing call sites do not move and keep today's rendering.
- The panel's width is now clamped to the overlay's available width. A `contentSized` panel on a viewport narrower than its `maxWidth` now **shrinks instead of overflowing**. This changes rendering for existing callers on narrow viewports.
- When a panel fits on **neither** the preferred side nor its opposite, it now lands on the opposite side (previously it stayed on the preferred side and clamped there). Observable as: a panel too tall for the viewport now clamps to the overlay's **top** instead of its **bottom**. Reachable today via `duration_input.dart` (`maxHeight: 400`) on a short viewport.
- `LayrzAnchoredPanelAlignment` is now documented as **cross-axis** alignment rather than strictly horizontal. The values and their behaviour on vertical sides (`top`/`bottom`) are unchanged; they additionally now mean top/middle/bottom when the panel is placed on a horizontal side (`left`/`right`).

**`LayrzSearchInput` gains `preferredSide`**, of type `LayrzPreferredSide`, **defaulting to `LayrzPreferredSide.right`** — this changes where the icon-mode search panel opens relative to its trigger button. Only applies in icon mode; field mode has no panel and ignores it.

**`LayrzComboBoxInput.maxOptionsToDisplay` removed — no deprecation, no alias.** Every caller that passed it, including one that deliberately chose a non-default count, fails to compile now. It is replaced by a single fixed rule with no caller-facing control at all: the desktop overlay's option list is capped at 300 logical pixels and scrolls past that; a caller that needs the panel taller or shorter than 300px has no way to ask for it. This is a genuine capability loss, not just a mechanical rename — it existed specifically because `maxOptionsToDisplay` was already silently broken for any value other than the default (it multiplied by a `48.0` row-height constant that never matched the actual ~36px rendered row height, and the resulting cap was applied twice, which is what caused the overflow above) and a deprecation cycle would have kept forwarding a value that was already lying about what it did. Migration: delete the argument. There is no replacement parameter.

**`LayrzComboBoxInput.onChanged` no longer fires on a same-value re-selection.** Previously every commit (selecting an option, whether or not its text differs from what is already shown) called `onChanged` directly, so re-selecting the currently-displayed option still fired it. `onChanged` now fires only when the field's text actually changes, matching its documented contract ("fired when the input value changes") rather than "fired on every commit." A caller relying on `onChanged` for "the user made a selection," including a same-value reselection, will see fewer calls after this change and must switch to `onSubmit`, which is unconditional and fires on every commit — same value or not — and was already available before this change.

---

## 0.0.12

**Text selection actions and page-wide toolbar.** `LayrzTextInput` adds an `actions` parameter to customize the text selection toolbar actions (copy, cut, paste, select all). Pass `null` for all four built-in actions, `const {}` to suppress the toolbar, or a custom set of `LayrzSelectableAction` instances. Page-wide text selection (via `SelectableRegion` under `LayrzLayout`) now displays a copy-only toolbar. The field automatically filters actions based on state (obscured fields never offer copy/cut; read-only fields never offer cut/paste). See decision D50 for design details and the five Flutter text selection traps encountered.

**Input family: `dense` parameter removed.** The `dense` parameter is entirely removed from `LayrzTextInput` and all picker-style inputs (`LayrzDateInput`, `LayrzTimeInput`, `LayrzSelectInput`, etc.). Only one density remains: uniform `pd2` (8 logical pixels) padding on all sides. Callers needing tighter geometry use the `padding:` parameter explicitly. This is a **breaking change** for any consumer code using `dense:`. See decision D47 for full context and the removal rationale.

**Token system refactor: spacing and radius to semantic level ramps.** Both `LayrzSpacingTokens` and `LayrzRadiusTokens` move from ad-hoc pixel-named members to five semantic levels (1–5) sharing the value scale 4, 8, 16, 24, 32 — consistent with the pre-existing shadow elevation pattern. This is a **breaking change** requiring migration of every spacing and radius call site. See decision D46 for full context and migration guide.

**Icon set migration to Material Design Icons.** Migrates the system-wide icon source from the Solar set (`layrz_icons`) to Material Design Icons (`flutter_material_design_icons`), aligning with industry standards while retaining `layrz_icons` for the planned `LayrzIconInput` widget.

**Navigation panel unification and layout constants refactor.** The rail and drawer navigation panels were merged into a single internal widget (`LayrzLayoutNavigatorPanel`), eliminating ~770 lines of ~91%-identical code. The logo block was rewritten to be edge-to-edge with aspect-ratio scaling. Ten hardcoded layout design constants were removed as they were unused outside their definitions. This is a **breaking change** for any consumer code referencing the deleted constants. See decision D48 for full context. Note: `LayrzLayoutRail` and `LayrzLayoutDrawer` were never exported, so their internal removal is not a public API break; only the constant removals affect external consumers.

### Breaking

**Input family (`LayrzTextInput` and all picker-style inputs)**:
- **Removed entirely** (no deprecation, no aliases — all stale call sites MUST fail at compile time): `dense` parameter.
- **Removed as side effect**: `kLayrzLayoutSearchFieldPaddingHorizontal` (was 10.0, not on the token ramp), `kLayrzTextInputDenseIconSize` (was 14.0).
- **Abstraction deleted**: `InputDensitySpec` class from `lib/src/inputs/src/input_density.dart` (91 lines).
- **Default padding**: All inputs now use `pd2` (8 logical pixels uniformly) as the default padding. The `padding:` parameter remains for custom overrides.
- **Migration**: Remove all `dense: true` and `dense: false` call sites. If custom padding is needed, pass `padding: EdgeInsets.all(…)` explicitly.

**Spacing tokens (`LayrzSpacingTokens`)**:
- **Removed entirely** (no deprecation, no aliases — all stale call sites MUST fail at compile time): `base`, `sp4`, `sp6`, `sp8`, `sp10`, `sp12`, `sp14`, `sp16`, `sp20`, `sp24`, `sp28`, `sp32`, `sp36`, `sp40`, `sp44`, `sp48`, `margin`, `reducedMargin`, `padding`, `spacingSize`, `sizedBox`.
- **Added as final fields** (in `copyWith`, `==`, `hashCode`): `sp1` (4.0), `sp2` (8.0), `sp3` (16.0), `sp4` (24.0), `sp5` (32.0). **Note**: `sp4` existed in the old scheme at 4.0; it now means 24.0. This silent-failure hazard necessitated complete removal of the old member first, then introduction of the new one.
- **Added as derived getters** (NOT in `copyWith`, `==`, `hashCode`): `pd1`…`pd5` and `mg1`…`mg5`, each returning `EdgeInsets.all(spN)`. These exist for call-site clarity; padding and margin intent is now explicit in the token name.
- **Migration table** (all 23 old members):
  - `sp4` (4.0) → `sp1`
  - `sp6` (6.0) → `sp2`
  - `sp8`–`sp10` (8.0–10.0) → `sp2`
  - `sp12`–`sp14` (12.0–14.0) → `sp3`
  - `sp16` (16.0) → `sp3`
  - `sp20` (20.0) → `sp4`
  - `sp24` (24.0) → `sp4`
  - `sp28` (28.0) → `sp5`
  - `sp32` (32.0) → `sp5`
  - `sp36`, `sp40`, `sp44`, `sp48` (36.0–48.0) → `sp5` [clamps to 32; 23 call sites tighten spacing by 1/3]
  - `base`, `padding`, `margin` → `sp2` (8.0)
  - `reducedMargin` → `mg1` (4.0)
  - `spacingSize` → `Size(sp2, sp2)` inline
  - `sizedBox` → `SizedBox.square(dimension: sp2)` inline

**Radius tokens (`LayrzRadiusTokens`)**:
- **Removed entirely** (no deprecation, no aliases): `base`, `r8`, `r10`, `r12`, `r14`, `r16`, `r20`, `r24`, `borderRadius` getter.
- **Added as final fields** (in `copyWith`, `==`, `hashCode`): `r1` (4.0), `r2` (8.0), `r3` (16.0), `r4` (24.0), `r5` (32.0). **Note**: `r12` existed at 12.0; it now does not exist, and `r3` (16.0) is the nearest match.
- **Retained unchanged**: `full` (999.0, pill shape), `innerRadius()`, `innerRadiusValue()`.
- **Added as derived getters** (NOT in `copyWith`, `==`, `hashCode`): `br1`…`br5`, each returning `BorderRadius.circular(rN)`.
- **Migration table** (all 8 old members):
  - `r8`, `r10` → `r2` (8.0)
  - `r12`–`r16` → `r3` (16.0) [16 call sites see visibly rounder corners]
  - `r20`, `r24` → `r4` (24.0)
  - `base`, `borderRadius` → `r2` (8.0)

**Layout constants**: 
- **Removed entirely** (no deprecation, no aliases — all stale call sites MUST fail at compile time): Six logo design constants (`kLayrzLayoutLogoTileSize`, `kLayrzLayoutLogoTileRadius`, `kLayrzLayoutLogoGap`, `kLayrzLayoutLogoWidthFactor`, `kLayrzLayoutLogoHeight`, `kLayrzLayoutLogoLeftPadding`) and four search-field constants (`kLayrzLayoutSearchFieldHeight`, `kLayrzLayoutSearchFieldInternalPaddingHorizontal`, `kLayrzLayoutSearchFieldFontSize`, `kLayrzLayoutSearchFieldIconSize`).
- **Rationale**: All ten constants were unused outside their definitions (internal to the now-merged rail/drawer panels). Their removal simplifies the token landscape and retires two off-ramp hardcoded values: `kLayrzLayoutSearchFieldInternalPaddingHorizontal` (10.0) and `kLayrzLayoutLogoLeftPadding` (6.0), neither on the 4/8/16/24/32 spacing ramp.
- **Retained unchanged**: `kLayrzLayoutRailPaddingHorizontal`, `kLayrzLayoutRailPaddingVertical`, `kLayrzLayoutLogoBottomPadding`. Note: Rail padding constants now apply to both rail and drawer presentations; renaming them would introduce a second breaking change, making them candidates for a future breaking release.

**Surface color tokens: collapse to `sf1`–`sf4` numbered ramp, remove pure white.**
- **Removed entirely** (no deprecation, no aliases): `colors.background`, `colors.surface`, `colors.surface2`, `colors.surface3`, constant `kLightBackgroundColor`.
- **Added as final fields** (in `copyWith`, `==`, `hashCode`): `sf1` (#FCFCFC), `sf2` (#F7F7F7), `sf3` (#F0F0F0), `sf4` (#E8E8E8). All surfaces now use numbered ramp logic.
- **Migration table** (all 4 old members):
  - `background` → `sf1` (#FCFCFC) — canvas/scaffold background
  - `surface` → `sf1` (#FCFCFC) — on-canvas fills (cards, dialogs, panels, alerts); elevation shadows separate layers
  - `surface2` → `sf2` (#F7F7F7) — nested surfaces (e.g. input fields inside a card); value unchanged
  - `surface3` → `sf3` (#F0F0F0)
- **New step**: `sf4` (#E8E8E8) added for deepest nesting with maximum contrast.
- **Rendering change**: Pure white (#FFFFFF) is no longer used anywhere. All elevation shadows and backgrounds now render against the light gray (#FCFCFC) canvas, improving consistency. Default `LayrzShadowTokens.surfaceColor` updated from white to #FCFCFC; `LayrzAvatar` background updated similarly.
- **Rationale**: The collapse removes redundancy (old `background` and `surface` both mapped to similar values); the ramp adds structure (numbered 1–4 mirrors the pre-existing elevation and semantic level pattern). See decision D49 for full context.

### Changed

- **All icons now use `flutter_material_design_icons` (^3.1.0+7447) instead of `layrz_icons`.** Every component that previously rendered `LayrzIcons.solarOutlineXxx` now uses `MdiIcons.xxx`. This is a visual change to icon appearance, as the Solar and MDI glyph sets differ. Components affected:
  - `LayrzButton` and `LayrzDropdownEntry` semantic factories (save/cancel/info/show/edit/delete) now use MDI icons
  - `LayrzAlert` types (info/success/warning/danger/context) now use MDI icons
  - `LayrzLayout` drawer trigger and navigation examples now use MDI
  - All widget examples and documentation pages updated to reflect the new icons
  
  Reference decision D45.

- **`layrz_icons` dependency remains** but is no longer the system-wide icon source. It is retained exclusively for the planned `LayrzIconInput` widget, which browses the full Solar catalogue. The dependency version is pinned at `^1.1.1` (co-constrained with `layrz_sdk`); this will remain until `layrz_sdk` upgrades to `layrz_icons: ^2.0.0`.

### Dependencies Added

- **`flutter_material_design_icons: ^3.1.0+7447`** — Pure icon-font package providing Material Design Icons. No Material or Cupertino coupling; purely a font and constant library. All components now import icons from this package.

---

## 0.0.11

**Touch behaviour, and a drawer that reads as depth.** Reworks how tooltips behave under a finger, corrects coordinate and scaling faults that only surface on a real device, and rebuilds the mobile drawer transition so the page floats above a flat backdrop.

### Added

- **Drag gestures and back-button handling for the `LayrzLayout` drawer.** A 20px edge strip (`kLayrzLayoutDrawerEdgeDragWidth`) drags the drawer open while it is closed, and the visible page sliver drags it shut while it is open; both track the finger and settle by fling velocity (`kLayrzLayoutDrawerDragSettleVelocity`, 365 px/s) or by whether the gesture passed the halfway point. The system back button now closes an open drawer instead of popping the route, via `PopScope`. Reference decision D44.

- **Field errors surface in a tap tooltip below the sm breakpoint.** On compact widths there is no room for an error line beneath the field, so the error is reachable by tapping instead. Reference DESIGN-80 and decision D41.

- **`LayrzLayout` honours the safe area.** The top bar and drawer surfaces paint edge-to-edge beneath notches, status bars and home indicators so their fill reaches the physical screen edge, while their content stays inset. The body slot is deliberately not inset — the page owns its own edges. Reference DESIGN-82 and decision D42.

### Changed

- **The mobile drawer no longer slides in over the page; the page moves out of the way.** It scales to 0.88 anchored at `Alignment.centerLeft`, translates right by the 260px drawer width, and gains `radius.r16` corners with `shadow.elevation4`, so it reads as a card floating above the drawer. The drawer panel lost its own shadow and now renders flat, and the full-screen scrim is gone along with `kLayrzLayoutDrawerScrimOpacity` — with the drawer painted behind the page, a scrim can never be seen. This is a visible behaviour change. Reference decision D44.

- **The drawer trigger is a 40x40 button with hover and press states** (`colors.surface3` on hover, `colors.surface2` on press), replacing a bare 24px icon that had no feedback and a hit target below the touch minimum. Only colour varies across states; geometry is held constant per decision D15. The top bar logo is left-aligned rather than centred.

- **`@Preview` requires a top-level function tear-off for `theme:`.** Use `layrzPreviewLightTheme`; `LayrzPreviewTheme.light` is a static method and the widget-preview code generator cannot serialize it. Every bundled preview now also declares a `size:`, because the preview harness supplies unbounded width, which forces the intrinsic and dry-layout measurement that a `Row` with `Expanded` or an embedded `LayoutBuilder` cannot answer.

### Fixed

- **Touch tooltips stay open until tapped away.** They previously vanished the instant a long-press was released, because the gesture that opens them ends with a pointer-up event. Dismissal now runs through a global pointer route gated on mouse presence and fires on pointer-down. Reference DESIGN-77.

- **Tooltips are positioned in the overlay's coordinate space rather than the window's.** The anchor was resolved with `localToGlobal` and no `ancestor:`, and the bounds came from `MediaQuery`, while the surface is placed by a `Positioned` inside the `OverlayPortal`'s overlay child. Inside a scrollable the two spaces diverged by the scroll offset, so it was applied twice and the tooltip drifted at twice the distance the anchor moved — measured on device at ratios of 2.00 across three pages, with the error growing linearly from zero at the top of a page.

- **The drawer transition no longer relays out the page on every frame.** The sliver's gesture region animated a `Positioned` offset, and mutating one marks `RenderStack` dirty for layout, so the whole body subtree — including long scrollables — was laid out every frame. Profiling on device measured `LAYOUT` at 795ms against `PAINT`'s 205ms, with UI frames peaking at 48.8ms. The region is now offset with `Transform.translate`, which is paint-and-hit-test only; the drawer subtree is built once outside the `AnimatedBuilder` instead of being reallocated per frame; and the page content and drawer panel each get a `RepaintBoundary`.

- **Button labels render at the measured text scale.** Reference DESIGN-78.

- **Alert touch presses receive the hover treatment**, so a press registers visually on a device with no pointer. Reference DESIGN-79.

- **The drawer closes when a navigation item is tapped**, while section labels leave it open.

### Known issues

- **Widget previews do not render.** The preview harness installs no `LayrzUiL10n`, so any preview of a widget that reads `context.l10n` fails during build. Bounding every preview's size cleared the earlier layout assertions, but this remains.

## 0.0.10

**The application shell.** Adds `LayrzLayout` and `LayrzScaffoldShell` — the two components that turn the primitives into an application — plus a Material-free scrollbar the package installs for you.

### Added

- **`LayrzLayout`** — the application shell, and the resolution of decision D8's long-open question of which single layout design ships. Two presentations, resolved from `LayoutBuilder` constraints via `tokens.breakpoints.bandAt(...)` rather than the viewport, so the layout reacts to its own box: `expanded` at md/lg/xl renders a 178px labelled rail beside the body slot, capping and centring body content at 1440 on xl; `drawer` at sm/xs replaces the rail with a 56px top bar and moves navigation into a 260px off-canvas drawer.

  It holds **no application state** — `LayrzNavigatorPage.isSelected` carries the active flag, so the consumer declares which entry is current rather than passing a selected id down. The navigator hierarchy is deliberately trimmed to two subtypes: `LayrzNavigatorPage` and `LayrzNavigatorLabel`. layrz_theme's `Action`, `Widget` and `Separator` items are dropped, as are breadcrumbs, the user role line and the org switcher. `LayrzNavigatorLabel` renders as a full-bleed band with an optional `color` that tints it at `tonalOpacity` flattened over the surface. The user block opens a dropdown supplied via `userMenuItems`, so no tap callback is routed through the layout, and notifications appear as a labelled footer row. `logo` is a required `String` — a `LayrzImage` source rather than a widget, so the layout can guarantee the image's width, height and fit. A search field filters navigator pages by `labelText` while preserving the section label of any section that still matches. Nothing in the component pushes a `Navigator` route. Reference DESIGN-61 and decision D37.

- **`LayrzScaffoldShell<T>`** — adaptive list-detail shell, driven by two builders: `onBuild` returns a `LayrzScaffoldTile` describing one row, and `onDetailsBuild` renders the entire detail area including its own header. A `LayrzScaffoldController<T>` is **required** and owns which item is open, so the detail view can be driven from outside the widget; the consumer owns its lifecycle and the shell never disposes it. Two panes at md/lg/xl, a single pane with a back affordance at sm/xs, swapped by internal state rather than a `Navigator` push.

  `LayrzScaffoldTile` is an `abstract base class` exposing `titleRichText`, `subtitleRichText` and `actions`, so consumers can subclass it around their own domain object and override `==`/`hashCode` for precise change detection; `LayrzScaffoldValueTile` is a concrete value-equality implementation for simple lists. Search reports through `onSearch` and the shell does **not** filter — a shell generic over `T` cannot know which fields are searchable. There is no grouping. Reference DESIGN-62 and decision D37.

- **`LayrzScrollbar`** and **`LayrzScrollBehavior`** — a Material-free scrollbar built on `RawScrollbar`, since `Scaffold`-era `Scrollbar` is Material and `CupertinoScrollbar` is Cupertino. The thumb is always visible and rounded; the track appears only on hover. Vertical scrollables only, and only on pointer platforms — a permanently visible thumb on a touch device reads as broken.

- **`LayrzDropdownLabel.color`** — optional tint for a menu section's label band. When null the band keeps its neutral `surface3` fill, so existing menus are unchanged.

### Changed

- **`LayrzApp` now installs `LayrzScrollBehavior` when `scrollBehavior` is null.** This is a visible behaviour change: scroll views that previously had no scrollbar will now show one. Pass an explicit `scrollBehavior` to opt out.

- **`LayrzTextInput.dense` now scales the icon size, the text style and the content height, not only the padding.** Previously `dense` reduced vertical padding while the icon stayed at the global `IconTheme` size of 24 and the text stayed at body size, so a dense field was not meaningfully compact and its text could clip. Density is now resolved in one place (`InputDensitySpec`) covering padding, icon size, hint style, editable style and content height together. Existing dense fields will render visibly more compact; non-dense fields are unchanged.

## 0.0.9

**The input family's foundation, plus localization.** Adds `LayrzTextInput` — the component every other `Layrz*Input` will compose — and the `LayrzUiL10n` localization contract it depends on.

### Breaking

- **`LayrzAvatar` no longer depends on `layrz_sdk`.** The `avatar` parameter is removed and replaced with `source: LayrzAvatarSource?`. The sealed hierarchy `LayrzAvatarSource` contains four concrete types: `LayrzAvatarUrl`, `LayrzAvatarBase64`, `LayrzAvatarIcon`, and `LayrzAvatarEmoji`. All four variants hold their data directly (URL string, base64 string, `IconData`, emoji string) rather than wrapping SDK types. Migration: replace `Avatar(type: AvatarType.url, url: '...')` with `LayrzAvatarUrl('...')`, `Avatar(type: AvatarType.base64, base64: '...')` with `LayrzAvatarBase64('...')`, `Avatar(type: AvatarType.icon, icon: icon)` with `LayrzAvatarIcon(icon.iconData)` (convert SDK `LayrzIcon` to `IconData`), and `Avatar(type: AvatarType.emoji, emoji: '...')` with `LayrzAvatarEmoji('...')`. The `.image()`, `.icon()`, `.emoji()`, and `.initials()` named constructors are unchanged.

- **`layrz_icons` remains at `^1.1.1`.** Although layrz_ui no longer depends on layrz_sdk directly, the `layrz_ui_extensions` package must depend on both layrz_ui and layrz_sdk to provide the `Avatar` → `LayrzAvatarSource` conversion — and layrz_sdk 4.4.3 pins `layrz_icons: ^1.1.1`. Decision D30's exit condition (raise to 2.x once layrz_sdk upgrades) therefore remains unmet.

### Added

- **`LayrzTextInput`** — Material-free single-line text field built directly on `EditableText`, and the base of the entire input family. Every future `Layrz*Input` composes it rather than reimplementing field chrome, so its label, slots, help affordance, error display and focus decoration are the chrome of every input in the system. Reference DESIGN-33 and decision D32.

  Key API notes: **at least one of `labelText` or `hintText` is required** (a debug assertion enforces it) — a search field wants only a hint, a form field only a label, and both together is valid. Each of the prefix and suffix slots accepts **at most one** of `prefixIcon` / `prefix` / `prefixText` (and the suffix equivalents), asserted in debug. `errors` is a caller-owned `List<String>` rendered joined with `", "` on a single line in bold `w700` — there is no `validator` and the widget never self-validates. `maxLength` renders a `"12/50"` counter right-aligned opposite the error message, which stays neutral `fg3` even when errors are present. `disabled` blocks all interaction; `readOnly` still fires `onTap`, which is what picker-style inputs depend on. `shortcut` renders a `⌘K`-style badge but binds nothing (see DESIGN-71) and is hidden entirely on mobile.

- **`LayrzUiL10n`** — The localization contract for the design system: 133 keys across 17 namespace mixins, each supplying an English default. Ships with `LayrzUiL10nDefault`, `LayrzUiL10nDelegate` and a `context.l10n` accessor, wired automatically by `LayrzApp` so the package works with zero configuration. Consumers extend `LayrzUiL10n` and override only the keys they need; keys added in later versions inherit their English default rather than breaking the subclass. Reference DESIGN-73.

  Integration note: a consumer's own delegate must be declared `LocalizationsDelegate<LayrzUiL10n>`, **never** over a subclass. `LocalizationsDelegate.type` is the key `Localizations.of` looks up, so a subclass-typed delegate is never found and every string silently falls back to English with no error.

- **`LayrzTooltip.titleText`** — Optional title rendered above the tooltip content in a heavier weight. Purely additive; existing tooltips are unchanged.

- **Showroom section for inputs** — The example app gains a `LayrzTextInput` section covering field states, label and hint variants, all three slot forms including arbitrary widgets, error display, the help affordance, `dense`, the shortcut badge and a numeric field.

### Changed

- **Type scale adjusted** — `display` is now 40px at `w700` (was 45px at `w800`), `headline` is `w600` (was `w700`), and `label` is `w400` (was `w300`). `title` (16px `w600`) and `body` (14px `w400`) are unchanged. This is a visual change to every component reading `tokens.typography`, not an API change.

- **`formatLayrzShortcut` moved to a new `keyboard` module** — Relocated from `lib/src/menus/src/` now that it has a second consumer, and given its first test suite. Non-breaking for consumers, who reach it through the root barrel.

### Design Notes

- **Text selection is deliberately deferred.** `LayrzTextInput` passes `null` for both `selectionControls` and `contextMenuBuilder`, which makes `EditableText` skip the selection overlay entirely while caret placement, drag-selection and keyboard selection continue to work. Selection handles, the copy/paste toolbar and the mobile magnifier are tracked separately as DESIGN-74. Material supplies these normally and its implementation cannot be used.

- **Field geometry is deterministic.** Height resolves from the icon size, so a field with icons is exactly as tall as one without, and every interaction state renders at identical height and border width per decision D15. Caller-supplied slot widgets are constrained to that height so a picker passing a colour swatch or avatar cannot stretch the field.

- **Decision D35 was retracted.** It amended D15 to permit dashed borders on modal states. The dashed border was removed before release — it never rendered, because the painter drew beneath an opaque fill — so the amendment defends nothing and D15 stands unamended. References D32, D33 and D34.

- **The i18n binding lives in a separate package.** `layrz_ui_i18n` (`goldenm-software/layrz_ui_i18n`) adapts `LayrzUiL10n` to the `layrz_i18n` engine. It is not published from this repository, and `layrz_ui` deliberately carries no dependency on any translation engine.

---

## 0.0.8

**Final M2 core primitives.** Adds three remaining M2 components and amends the dropdown menu implementation.

### Breaking

- **`LayrzDropdownEntry.color` is now `Color?` instead of `LayrzColorSwatch?`** — The swatch type was originally justified because pressed and hovered states read `accent.shade100` and `accent.shade700`. Those states are now neutral opaque tokens, so no shades are read anywhere. Passing token swatches still compiles and renders identically (each swatch is constructed with shade500 as its primary value), so most callers need no change. Only code that *reads* the field back expecting a swatch (e.g., `entry.color.shade700`) will break at compile time. Reference decision D29.

### Added

- **`LayrzDropdownLabel.color`** — Optional `Color?` parameter that fills the label's tonal band. Null keeps the neutral `surface3` fill, so existing menus are visually unchanged. Paired with D29's dropdown entry colour simplification.
- **`LayrzDropdownEntry` semantic factories** — Six convenience factories preset icon and semantic colour to match action semantics: `.save()` (icon `solarOutlineInboxIn`, colour `tokens.colors.success`), `.cancel()` (icon `solarOutlineCloseSquare`, colour `tokens.colors.danger`), `.info()` (icon `solarOutlineInfoSquare`, colour `tokens.colors.info`), `.show()` (icon `solarOutlineEyeScan`, colour `tokens.colors.info`), `.edit()` (icon `solarOutlinePenNewSquare`, colour `tokens.colors.warning`), `.delete()` (icon `solarOutlineTrashBinMinimalisticN2`, colour `tokens.colors.danger`). All factories accept optional `icon` and `color` overrides. Semantic type is resolved to token colour at build time via a private enum, never exposed as public API.
- **`LayrzButtonGroup`** — Responsive group of dropdown items rendering as a row of buttons or collapsed into a single dropdown trigger. Takes `items: List<LayrzDropdownItem>` (entries and labels). In row mode (above `md` breakpoint), `LayrzDropdownEntry` items convert to labelled `LayrzButton` instances; `LayrzDropdownLabel` items are silently skipped. In dropdown mode, all items pass through to `LayrzDropdownMenu` unchanged. Mode driven by a nullable `bool useDropdown` parameter. The `triggerHintText` parameter is required and serves as the trigger's stable accessible name. Reference DESIGN-31 and the model inversion: items are the source of truth, not derived from buttons.

- **`LayrzButtonGroup.builder`** — Variant constructor allowing a custom trigger widget. Identical to the default constructor except the trigger is built via `builder: (context, controller)` instead of the hardcoded `triggerHintText` / `triggerIcon`. Row mode is identical for both constructors. Gesture-arena warning: wire the controller directly to the trigger's `onTap`, do not wrap in `GestureDetector`.

- **`LayrzAvatar`** — Static display component rendering a layrz_sdk `Avatar` by type (URL, base64, icon, emoji), with initials as the fallback when the avatar is null or missing. Always a rounded box using the `r12` radius token, consistent with `LayrzCard` and `LayrzAlert`, and carries a fixed `tokens.shadow.compact1` drop shadow in all render modes. No interaction affordances; callers wrap if needed. Initials algorithm is deterministic but not locale-aware (no Unicode segmentation). Reference decision D31.

- **`LayrzImage`** — Image widget resolving network URLs, data-URIs, bare base64, and asset paths. Includes SVG support via flutter_svg and a bounded cache for decoded base64 bytes. Uses `ImageSource` to detect and parse the source type automatically.

- **Dependencies: layrz_sdk and flutter_svg** — New dependencies to support avatar models and SVG rendering. layrz_sdk requires `layrz_icons: ^1.1.1`, so the package constraint is downgraded from `^2.0.0` to `^1.1.1`. All 20 used IconData symbols are identical in both versions, verified byte-for-byte. Reference decision D30.

### Changed

- **`layrz_icons` constraint lowered from `^2.0.0` to `^1.1.1`** — Required by layrz_sdk 4.4.3. All used symbols are identical across versions. Exit condition: raise constraint back to `^2.0.0` once layrz_sdk upgrades.

### Design Notes

- **D29** documents the post-mortem on `LayrzDropdownEntry.color`. The lesson: when an API's original constraint is removed, actively audit the dependency graph for surviving references to that constraint and remove them. The swatch type should not have survived the interaction-state redesign.

- **D30** records the dependency trade-off: layrz_sdk brings 18 transitive dependencies (including `dio`, `layrz_i18n`, `layrz_logging`, `web_socket_channel`), and flutter_svg adds the vector graphics chain. All verified Material-free. Exit condition explicit: revert to `^2.0.0` once layrz_sdk advances.

- **D31** documents that `LayrzAvatar` is static display-only, following the same pattern as `LayrzChip` per decision D28. No interaction affordances, no elevation parameter — but the avatar always carries a fixed `tokens.shadow.compact1` drop shadow. Callers own interaction logic.

---

## 0.0.7

**First components from Milestone 2.** Adds four M2 primitives: selectable text, visual chips, chip grouping, and dropdown menu.

### Added

- **`LayrzText`** — Material-free drop-in replacement for Flutter's `Text` that makes text selectable and copyable via `SelectableRegion` with `emptyTextSelectionControls`. Supports both `LayrzText(String)` and `LayrzText.rich(InlineSpan)` constructors mirroring `Text` exactly. Keyboard selection (Ctrl+A) and copy (Ctrl+C) work without additional UI. Resolves null `style` to `tokens.typography.body` rather than inherited `DefaultTextStyle`; drag handles and context menu deferred until Material-free `TextSelectionControls` exists. Reference decision D28 and DESIGN-28.

- **`LayrzChip`** — static, visual-only compact label with optional leading icon and optional delete affordance. Three styles (`filled`, `outlined`, `filledTonal`) and six semantic types (`info`, `success`, `warning`, `danger`, `context`, `custom`). Chip is a label, not a control: no tap, hover, focus, or selected state; only the delete affordance is interactive. Reference decision D28 and DESIGN-29.

- **`LayrzChipGroup`** — horizontal layout of multiple chips with two overflow behaviors. `LayrzChipGroupBehavior.none` (default) renders a single scrollable row. `LayrzChipGroupBehavior.compact` clamps to available width and collapses the remainder into a `+N` indicator chip whose tooltip lists the hidden labels. Caveat: `compact` measures each chip individually, so the `+N` may appear one chip early or late; it costs one text layout per chip per build.

- **`LayrzDropdownMenu`** — menu surface anchored to a trigger widget, built on `RawMenuAnchor` from `package:flutter/widgets.dart`. The trigger is supplied via `builder: (context, controller)` and wires itself through the controller; the menu installs no gesture handling of its own. Items are a sealed hierarchy of `LayrzDropdownEntry` and `LayrzDropdownLabel`, ensuring standardization on rendering. Entries support an optional colour dot (driven by a `LayrzColorSwatch`), an optional icon, `enabled` state, and a **display-only** `Set<LogicalKeyboardKey>` shortcut hint rendered with platform-native glyphs and hidden entirely on iOS and Android. `LayrzDropdownMenuAlignment` offers `start`/`center`/`end` horizontal positioning relative to the trigger. Escape, arrow-key traversal, and outside-tap dismissal are handled by `RawMenuAnchor`. No exit animation — `RawMenuAnchor` tears the overlay down synchronously. Reference DESIGN-30 and milestone-2 item 9.

### Changed

- **`LayrzText` is now a `StatelessWidget`** — public API is unchanged. Its former `State` only duplicated `SelectableRegion`'s own focus-node ownership, so the redundant `State`/`Element` per instance was removed. A caller-supplied `focusNode` remains caller-owned and is never disposed by the widget.

### Design Notes

- **D28** documents the architectural decisions for text, chips, and the sealed item hierarchy (which extends to dropdown). See `engineering/decisions.md#d28`.
- `LayrzText` uses `SelectableRegion` with `emptyTextSelectionControls` from Flutter 3.47 to enable keyboard selection and copy (Ctrl+A, Ctrl+C) without Material imports. When `focusNode` is supplied, the caller owns and must manage its lifetime; `LayrzText` never disposes it.
- `LayrzChip` uses `tokens.radius.full` for pill-shaped border radius and is static by design — no tap, hover, focus, or selection state; only the delete affordance is interactive.
- `LayrzChipGroup.compact` mode measures each chip individually via `LayrzChip.computeWidth()` (using `TextPainter`) to determine when to show the `+N` overflow indicator. This costs one text layout per chip per build; avoid in hot lists.
- **`LayrzDropdownMenu` interaction states:** Dropdown entries render at `surface` at rest, `surface2` on hover and focus, and `surface3` when pressed. Interaction states are neutral and fully opaque because `Colors.transparent` is transparent *black* and lerping from it flashes dark mid-transition. See decision DESIGN-30.

---

## 0.0.6

**Breaking: component enum trimming.** Two design votes removed unused style variants.

### Breaking
- **`LayrzButtonStyle` trimmed from 12 to 6 values** — only `elevated`, `elevatedFab`, `outlined`, `outlinedFab`, `outlinedTonal`, `outlinedTonalFab` remain. Removed: `filled`, `filledFab`, `filledTonal`, `filledTonalFab`, `text`, `fab`. See decision D27 and DESIGN-20.
- **`LayrzAlertStyle` trimmed from 5 to 2 values** — only `layrz`, `filledIcon` remain. Removed: `filledTonal`, `filled`, `outlined`. Consequence: all alerts now render in split-panel layout. See decision D27 and DESIGN-22.
- **Semantic factory signature change** — six button factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`) replace the `isElevated` boolean with an exposed `style:` parameter defaulting to `LayrzButtonStyle.elevated`. The `isFab` parameter remains. `isElevated` is no longer a parameter. Factories map the given style to its Fab twin via a new `asFab` getter on the enum extension. Example: `LayrzButton.save(labelText: 'Save', onTap: _save, style: LayrzButtonStyle.outlined)`.
- **`kLayrzAlertIconBoxSize` and `kLayrzAlertIconSize` removed** — orphaned by the alert style trim. Only `kLayrzAlertFilledIconSize` remains.

### Added
- `LayrzButtonStyle.asFab` enum extension — maps a regular style to its Fab twin (e.g., `outlined.asFab` → `outlinedFab`). Used internally by semantic factories.

### Changed
- `LayrzButton` semantic factories now expose the `style:` parameter for controlling button emphasis via style choice rather than a boolean. Developers explicitly pass `style: LayrzButtonStyle.outlined` for quiet buttons.
- All `LayrzAlert` instances now render in split-panel layout (the old `.layrz` and `.filledIcon` styles were the two split-panel options; the removed styles were single-panel).

### Design Rule (Not Enforced in Code)
- Button labels should be concise; do not rely on `TextOverflow.ellipsis` / `maxLines: 1` to truncate long text. This is design guidance only, not a runtime constraint.

---

## 0.0.5

**Breaking: every import path changes.** A single barrel replaces the fourteen per-domain entrypoints.

```dart
// Before (0.0.4)
import 'package:layrz_ui/buttons.dart';
import 'package:layrz_ui/theme.dart';
import 'package:layrz_ui/tokens.dart';

// After (0.0.5)
import 'package:layrz_ui/layrz_ui.dart';
```

### Breaking
- The fourteen per-domain entrypoints (`alerts.dart`, `app.dart`, `buttons.dart`, `cards.dart`, `constants.dart`, `extensions.dart`, `fonts.dart`, `grid.dart`, `platform.dart`, `state.dart`, `theme.dart`, `tokenizer.dart`, `tokens.dart`, `tooltips.dart`) are removed. Import `package:layrz_ui/layrz_ui.dart` instead; it exports all of them.
- Deferred imports were the one benefit of the per-domain split, and they apply only to web and Android. layrz_ui targets all six Flutter platforms, so the split was not earning its complexity. Recorded as D26; D19 is superseded.

### Changed
- `package:layrz_ui/preview.dart` is unchanged and remains a separate opt-in import. It is deliberately not exported by the root barrel.
- Implementation files move to `lib/src/<module>/src/` behind a per-module barrel at `lib/src/<module>/<module>.dart`. This is internal layout only; consumers import the root barrel.

## 0.0.4

**Documentation-only release.** No API changes, no code changes, no migration required. If you're using 0.0.3, you already have all the features described here.

### Documentation
- README corrected: removed examples for removed APIs (`LayrzThemeMode`, `context.isDark`, `LayrzThemeData.dark()`, `kDarkBackgroundColor`, `kAccentColor`, grid breakpoint constants `kExtraSmallGrid` et al., and the old fifteen-name text scale). Installation and usage examples moved to the GitHub wiki for sustained maintenance alongside the per-widget pages.
- Wiki corrected across seven pages (`Getting-Started`, `Theming`, `LayrzTokenizer`, `LayrzAlert`, `LayrzTooltip`, and two legacy examples) to reflect the five-style text scale (`display`, `headline`, `title`, `body`, `label`) that replaced the fifteen-name scale in 0.0.3.
- Progress tracking moved from a private GitHub Project to a public Notion board, linked from the README.

## 0.0.3

### Breaking
- The text scale collapses from fifteen styles to five: `display`, `headline`, `title`, `body`, `label`. All `*Large`, `*Medium` and `*Small` names are removed with no aliases; each new name carries the former `Medium` values.
- Font weights now carry hierarchy: `display` w800, `headline` w700, `title` w600, `body` w400, `label` w300. Previously all styles painted at regular weight regardless of the tag.
- `layrzTooltipPositionDelegate` is renamed to `positionDelegate`.
- Breakpoints move from compile-time constants (`kExtraSmallGrid`, etc.) onto the theme as `LayrzBreakpointTokens`, permitting per-app override. Add `context.breakpoint` to retrieve the active band from viewport width.
- Grid breakpoints are now viewport-driven; the `useScreenWidth` escape hatch is removed. A row always selects spans from `MediaQuery.sizeOf(context).width`, then divides its own measured pixel width by the selected span count. The two widths routinely differ for grids inside narrow containers on large screens, matching CSS Grid and Bootstrap.
- `kLayrzButtonTooltipVerticalOffset` is removed; button tooltips now use `LayrzTooltip` with `kLayrzTooltipOffset`.

### Added
- `LayrzTooltip` — a Material-free tooltip composed on `Overlay`, with `LayrzTooltipPosition` (top/bottom/left/right) positioning. Content is `contentText` or `contentRichText`; never covers its anchor, flips at viewport edges, and leaves the wrapped widget's layout and hit-testing untouched.
- `LayrzAlert` and `LayrzAlertIcon` — inline status callout with six severities (`info`, `success`, `warning`, `danger`, `context`, `custom`) and five visual styles (`.layrz`, `.filledTonal`, `.filled`, `.outlined`, `.filledIcon`), resolved through `LayrzAlertStyleSpec`.
- `LayrzAlert.onTap` makes alerts interactive: tap, Enter or Space activate the callback; hover and focus trigger a paint-only surface lift and shadow appears at elevation 2, while press settles the surface and shadow steps to elevation 1.
- `LayrzCard` — a styled surface with fixed 16u padding, token radius, and elevation (int 1–5) selecting the shadow ramp. Optionally interactive via `onTap`.
- `LayrzRow`, `LayrzCol` and `LayrzConstrainedView` — a 12-column responsive grid. Columns declare span per breakpoint (1–12) as plain ints, cascading downward when a band is unset. Rows greedily wrap columns and size them by available width. `LayrzConstrainedView` centres and clamps a column to `maxWidth` with internal vertical spacing.
- `Color.flattenOn` and `Color.isOpaque` on `LayrzColorExtensions` — flatten a translucent colour onto a background for pixel-perfect compositing; test colour opacity without inspecting alpha directly.
- `LayrzFontHandler.resolveFamilyForWeight` — resolves a font family for a specific weight. Defaults to `resolveFamily`, preserving compatibility; handlers like `LayrzGoogleFontsHandler` override it to return weight-specific families.

### Changed
- Font weights across the scale: `display` w800, `headline` w700, `title` w600, `body` w400, `label` w300 (was w100). The `title` step moves from w500.
- `LayrzButton` now composes `LayrzTooltip` instead of its own private tooltip implementation.

### Fixed
- Font weights render correctly. Every style previously resolved to a single-face family, so all weights painted at regular. Font families are now resolved per weight via `resolveFamilyForWeight`, and every weight the scale uses is preloaded; web showroom no longer flashes fallback text.
- `LayrzButton`'s pressed state activates correctly under fast mobile taps.
- Icon tree-shaking disabled for web release builds to prevent runtime errors.

## 0.0.2

### Breaking
- `lib/layrz_ui.dart` is removed; import specific domain entrypoints instead — e.g. `import 'package:layrz_ui/buttons.dart';` or `import 'package:layrz_ui/theme.dart';` in place of a single `import 'package:layrz_ui/layrz_ui.dart';`.
- Semantic colour tokens are now `LayrzColorSwatch` rather than `Color`; the base values moved from the 600 to the 500 palette shade, so semantic colours are visibly brighter.
- `contrastColor` now uses Material's brightness threshold instead of the stricter WCAG crossover; labels on `success`, `danger` and `info` backgrounds change from black to white.

### Added
- `LayrzButton` — the first component with twelve styles (`filled`, `elevated`, `filledTonal`, `outlined`, `outlinedTonal`, `text`, each with a Fab counterpart), built only on `package:flutter/widgets.dart`.
- Six semantic factories on `LayrzButton`: `.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`, each with an `isElevated` flag.
- `LayrzButtonType` — `success`, `info`, `context`, `danger`, `warning`, `custom`; a `color` override applies only to `custom`.
- `LayrzButtonController` — one controller drives many buttons so a whole view shares one busy state, with a cooldown duration that auto-clears on expiry and an anti-flash floor preventing very short busy states from strobing.
- `LayrzColorSwatch` — a Material-free equivalent of `MaterialColor` giving every semantic colour a full tonal range from `shade50` through `shade900`.
- A compact shadow ramp, `compact1`–`compact5`, for small components alongside the existing surface `elevation` ramp.
- `Color.opposite` as a shorthand alias for `contrastColor`.
- `LayrzRadiusTokens.innerRadiusValue` for computing concentric inner radii.

### Changed
- The package adopts the Flutter SDK layout: entrypoints at the top of `lib/`, implementation under `lib/src/`.
- `elevation1` now has a real vertical offset; it previously computed to zero and was invisible.

## 0.0.1

### Added
- `LayrzApp` and `LayrzApp.router` — drop-in `WidgetsApp` replacements with zero Material or Cupertino dependency.
- A complete immutable design-token system: `LayrzTokens` aggregating `LayrzColorTokens`, `LayrzTextTheme`, `LayrzSpacingTokens`, `LayrzRadiusTokens`, `LayrzShadowTokens`, `LayrzBorderTokens` and `LayrzMotionTokens`.
- `LayrzTokenizer` — a thin façade over the tokens, kept in sync with direct `theme.tokens` access.
- `LayrzThemeExtension<T>` — a Material-free equivalent of `ThemeExtension<T>`, so components can attach theme-scoped data; retrieved with `extension<T>()` / `maybeExtension<T>()` or `context.themeExtension<T>()`.
- `LayrzPreviewTheme` for Flutter 3.47 widget previews, exposed via `package:layrz_ui/preview.dart`.
- `LayrzFontHandler` with a `LayrzGoogleFontsHandler` implementation (google_fonts `TextStyle` APIs only, never `*TextTheme()`).
- The `WidgetState` / `WidgetStateProperty` / `WidgetStatesController` family re-exported from `package:flutter/widgets.dart`.
- `LayrzPlatform` for platform detection, `LayrzColorExtensions`, `LayrzContextExtensions`, and the responsive grid + duration + colour constants.
- A CI pipeline enforcing analyze, tests, formatting, the Material/Cupertino invariant, a google_fonts guard, a test-mirror structure check and a coverage ratchet.
- `public_member_api_docs` enforcement, so every public member ships documented.

### Fixed
- `LayrzTheme` extends `InheritedTheme` and implements `wrap()`, so the theme survives Overlay and route boundaries — dialogs, tooltips, menus and dropdowns can resolve `LayrzTheme.of(context)`.

### Changed
- Light mode only. `LayrzThemeData.dark()`, `LayrzThemeMode`, `context.isDark` and the dark token variants were removed; `errorColor` is now `dangerColor`. The accent colour was removed entirely.
- The theme now loads its font automatically rather than relying on the host app.
- Base border radius is 8.0 (layrz_theme used 10.0).

### Documentation
- `engineering/` holds the architecture, decision log, token spec and milestone plans; per-component usage documentation lives in the GitHub wiki.

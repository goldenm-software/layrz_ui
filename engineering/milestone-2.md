# Milestone 2: Core Primitives

## Goal

Build foundational interactive widgets that most other components depend on: buttons, tooltips, chips, alerts, avatars, responsive layout, and checkbox state animations.

This is the **first components milestone** after M1 Foundation. All M2 components establish UI patterns and state-management conventions that downstream components (M3–M6) will follow.

## Status

| # | Item | Status |
|---|---|---|
| 1 | LayrzButton with ten styles and six semantic factories | In Progress |
| 2 | LayrzActionButton and LayrzActionsButtons | Todo |
| 3 | LayrzTooltip on RawTooltip | Todo |
| 4 | LayrzChip and LayrzChipGroup | Todo |
| 5 | LayrzAlert (inline status callout) | Todo |
| 6 | LayrzAvatar and LayrzImage | Todo |
| 7 | LayrzResponsiveRow / LayrzResponsiveCol responsive grid | Todo |
| 8 | LayrzAnimatedCheckbox | Todo |

**Note**: This table tracks the 8 work items in M2 at the strategic level. GitHub Project 9 tracks individual components and supporting types at finer granularity. Both describe the same milestone work at different decomposition levels. When any item completes, both the Status table above and the corresponding GitHub Project item must be updated together in the same commit.

## Definition of Done

- All 8 items below complete
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M2 tests
- Coverage floor (90%) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- Every widget has `@Preview` annotations (rule #3)
- All M2 components integrated with theme system (LayrzTheme, tokens, state resolution)
- Wiki pages created/updated for all M2 components
- GitHub Project issue #21 (LayrzButton) closed with merged PR

---

## Deferred Structural Work: Per-Domain Library Entrypoints

**See decision D19** in `engineering/decisions.md`. After LayrzButton (#21) ships, a follow-up refactoring will restructure the package to use per-domain import entrypoints (e.g., `import 'package:layrz_ui/buttons.dart';` instead of `import 'package:layrz_ui/layrz_ui.dart';` for all imports). This restructure is intentionally deferred so that both the component and the package structure can be reviewed independently without creating a diff larger than ~5,000 lines.

- **Timing**: Begins after #21 merges; estimated to land in early M2 or mid-M2
- **Impact**: All imports in lib/, test/, example/, and the wiki will change; CLAUDE.md and engineering/architecture.md will be rewritten to reflect the new layout
- **Sub-decisions open**: Physical layout strategy (lib/src/<module>/ vs lib/<module>/src/) and whether to keep a convenience root barrel for backward compatibility
- **Scope**: One new standalone PR; no dependencies on M2 components themselves

---

## Work Items

### 1. LayrzButton with Ten Styles and Six Semantic Factories

**What changes**:
- Create `lib/buttons/src/button.dart` — `LayrzButton` widget
- Implement ten style variants via parameter
- Implement six semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`)
- Material-free construction: RawTooltip → FocusableActionDetector → MouseRegion → GestureDetector → AnimatedContainer
- Create `lib/buttons/buttons.dart` barrel with re-exports

**API contract**:

`LayrzButton` constructor:
- `labelText` (String, required) — the only label form; no Widget label parameter
- `icon` (IconData?, optional) — from layrz_icons 2.0.0 (bare IconData constants)
- `onTap` (VoidCallback?, nullable) — null disables the button; also respects `isDisabled` flag
- `isDisabled` (bool, default false) — explicit disable flag; either `onTap: null` OR `isDisabled: true` disables
- `color` (Color?, optional) — overrides the accent, defaulting to tokens.colors.primary
- `style` (LayrzButtonStyle, required or with sensible default) — one of the ten variants
- `isLoading` (ValueListenable<bool>?, optional) — externally-owned loading state; nullable for callers that don't need it
- `isCooldown` (ValueListenable<bool>?, optional) — externally-owned cooldown state; nullable for callers that don't need it
- `height` (double, default 40) — button height in logical pixels
- `width` (double?, optional) — if null, width is calculated from content
- `iconSize` (double, default 22) — icon size in logical pixels
- `iconSeparatorSize` (double, default 8) — spacing between icon and text
- `fontSize` (double, default 14) — label text font size
- `hintText` (String?, optional) — tooltip text; shown via RawTooltip on hover/long-press
- `tooltipEnabled` (bool, default true) — whether tooltips are shown

**Semantic factories**:

Each factory takes:
- `labelText` (String, required) — button label
- `onTap` (VoidCallback, required) — callback
- `isFab` (bool, default false) — when true, renders the compact icon-only FAB variant; otherwise the full regular variant. This is a layout choice and applies on any platform.
- `isLoading` (ValueListenable<bool>?, optional)
- `isCooldown` (ValueListenable<bool>?, optional)
- `isDisabled` (bool, default false)

| Factory | Icon | Semantic Color | Style (Regular → FAB) |
|---|---|---|---|
| `.save()` | `solarOutlineInboxIn` | `success` (green) | `filledTonal` → `filledTonalFab` |
| `.cancel()` | `solarOutlineCloseSquare` | `danger` (red) | `outlined` → `outlinedFab` |
| `.info()` | `solarOutlineInfoSquare` | `info` (blue) | `filledTonal` → `filledTonalFab` |
| `.show()` | `solarOutlineEyeScan` | `info` (blue) | `filledTonal` → `filledTonalFab` |
| `.edit()` | `solarOutlinePenNewSquare` | `warning` (orange) | `outlined` → `outlinedFab` |
| `.delete()` | `solarOutlineTrashBinMinimalisticN2` | `danger` (red) | `filledTonal` → `filledTonalFab` |

**Ten style variants**:

| Pair | Regular | FAB | Visual Treatment |
|---|---|---|---|
| 1 | `.filled` | `.filledFab` | Solid background, no shadow |
| 2 | `.filledTonal` | `.filledTonalFab` | Semi-transparent background (20% opacity on semantic color) |
| 3 | `.elevated` | `.elevatedFab` | Solid background with drop shadow |
| 4 | `.outlined` | `.outlinedFab` | Transparent background with border |
| 5 | `.outlinedTonal` | `.outlinedTonalFab` | Transparent background with semi-transparent border |

**Loading and cooldown states**:
- `isLoading` and `isCooldown` are externally-owned `ValueListenable<bool>?` — the caller owns the state object and the button listens for changes
- Neither parameter requires the button to manage timers, durations, or callbacks
- When `isLoading` is true: a single indeterminate progress bar/spinner is shown; the button is disabled; no countdown is displayed
- When `isCooldown` is true: the same indeterminate bar is shown (with different tint); the button is disabled; **no countdown timer is displayed** — the caller manages the duration and decides when to clear `isCooldown`
- `cooldownDuration`, `showCooldownRemainingDuration`, and `onCooldownFinish` are **not** implemented. Whoever owns the `ValueListenable<bool>` decides the duration and when cooldown ends
- `.legacyLoading()` is **not** ported from ThemedButton
- `onLongPress` and `customLongPressDuration` are **not** ported

**Material-free construction**:

The button is built without Material imports via this layer stack (inside-out):
1. `Semantics` — accessibility and semantic meaning
2. `RawTooltip` (from package:flutter/widgets.dart, Flutter 3.47) — for hintText; asserts an Overlay ancestor (provided by LayrzApp via WidgetsApp)
3. `FocusableActionDetector` — focus handling and keyboard navigation
4. `MouseRegion` — cursor and hover detection
5. `GestureDetector` — tap and long-press gestures
6. `AnimatedContainer` — visual state transitions (colour, shadow, opacity, border colour)

**D15 compliance** (Interaction States via Geometry Invariants):

Hover, press, focus, and disabled states vary only:
- Colour (background and text)
- Border colour
- Shadow (elevation)
- Opacity
- Cursor

They do **not** vary:
- Width or height (geometry is computed once, outside interaction resolution)
- Border width (constant per style)
- Padding or margin

This prevents reflow and flicker during state changes.

**Dependencies**:
- M1: LayrzTheme, tokens, state resolution (WidgetState, WidgetStateProperty)
- `layrz_icons: ^2.0.0` — added to pubspec.yaml (2.0.0 provides bare IconData constants)

**Files affected**:
- `lib/buttons/` (new module)
- `lib/buttons/buttons.dart` (barrel, new)
- `lib/buttons/src/button.dart` (new, ~300–400 lines)
- `lib/buttons/src/button_style.dart` (new, enums and style definitions)
- `lib/layrz_ui.dart` (update to export buttons barrel)
- `pubspec.yaml` (add layrz_icons dependency)
- `test/buttons/button_test.dart` (tests)
- `wiki/Widgets/LayrzButton.md` (wiki page, update with resolved spec)

**Acceptance criteria**:
- Constructor has every parameter documented (rule #1)
- All ten styles render correctly with appropriate visual treatment
- All six semantic factories render with correct icons and colours
- Loading state shows spinner and disables interaction; no countdown
- Cooldown state shows spinner with different tint and disables interaction; no countdown
- Hover state varies colour, shadow, opacity, and cursor only — no geometry change (D15)
- Press state varies colour only (D15)
- Focus state adds visual indicator (outline or shadow change)
- Disabled state grays out and shows `not-allowed` cursor
- FAB variants render icon-only with appropriate sizing
- RawTooltip shows hintText on hover (with caveat that Overlay ancestor is required)
- `flutter analyze` clean, tests green (coverage >90%), Material/Cupertino grep empty
- `@Preview` annotations present at bottom of button.dart file
- Wiki page documents final API, examples, and RawTooltip caveat

---

### 2. LayrzActionButton and LayrzActionsButtons

**Brief description**:

`LayrzActionButton` — icon-only button for toolbar/action contexts. May be implemented as a factory on LayrzButton or a standalone widget; implementation-time decision.

`LayrzActionsButtons` — horizontal group of action buttons (typically 2–4 buttons) with spacing. Wrapper around a Row of LayrzActionButton instances.

**Dependencies**: M1 (LayrzTheme, tokens), M2.1 (LayrzButton).

**Files affected**:
- `lib/buttons/src/action_button.dart` (new)
- `lib/buttons/src/actions_buttons.dart` (new)
- `lib/buttons/buttons.dart` (update barrel)
- `test/buttons/action_button_test.dart` (tests)

---

### 3. LayrzTooltip on RawTooltip

**Brief description**:

`LayrzTooltip` wraps `RawTooltip` from package:flutter/widgets.dart (Flutter 3.47+). Provides a styled tooltip with theme-aware positioning, animation, and text formatting.

Replaces the temporary use of RawTooltip in LayrzButton with a proper tooltip component.

**Dependencies**: M1 (LayrzTheme, tokens), Flutter 3.47 (RawTooltip).

**Files affected**:
- `lib/tooltips/` (new module)
- `lib/tooltips/tooltips.dart` (barrel, new)
- `lib/tooltips/src/tooltip.dart` (new)
- `test/tooltips/tooltip_test.dart` (tests)

---

### 4. LayrzChip and LayrzChipGroup

**Brief description**:

`LayrzChip` — compact label widget with optional leading/trailing icon, delete action, or selection state.

`LayrzChipGroup` — container for multiple chips with optional grouping behaviour (none, single select, multi-select).

**Dependencies**: M1 (LayrzTheme, tokens, WidgetState), M2.1 (LayrzButton for delete action).

**Files affected**:
- `lib/chips/` (new module)
- `lib/chips/chips.dart` (barrel, new)
- `lib/chips/src/chip.dart` (new)
- `lib/chips/src/chip_group.dart` (new)
- `test/chips/chip_test.dart` (tests)

---

### 5. LayrzAlert (Inline Status Callout)

**Brief description**:

`LayrzAlert` — inline status message widget for info, success, warning, danger, context, or custom severity. Five visual styles:
- `.layrz` — filled background
- `.filledTonal` — semi-transparent background
- `.filled` — solid background
- `.outlined` — border only
- `.filledIcon` — icon-centric layout

Replaces ThemedAlert from layrz_theme.

**Dependencies**: M1 (LayrzTheme, tokens).

**Files affected**:
- `lib/alerts/` (new module)
- `lib/alerts/alerts.dart` (barrel, new)
- `lib/alerts/src/alert.dart` (new)
- `test/alerts/alert_test.dart` (tests)

---

### 6. LayrzAvatar and LayrzImage

**Brief description**:

`LayrzAvatar` — circular or rounded-square user avatar from image URL, base64-encoded image, or initials fallback.

`LayrzImage` — optimized image widget with fallback, placeholder, and error states. Used as a building block by LayrzAvatar and M4 inputs.

**Dependencies**: M1 (LayrzTheme, tokens).

**Files affected**:
- `lib/avatars/` (new module)
- `lib/avatars/avatars.dart` (barrel, new)
- `lib/avatars/src/avatar.dart` (new)
- `lib/avatars/src/image.dart` (new)
- `test/avatars/avatar_test.dart` (tests)

---

### 7. LayrzResponsiveRow / LayrzResponsiveCol Responsive Grid

**Brief description**:

`LayrzResponsiveRow` — 12-column responsive grid container (wraps Row internally). Children are `LayrzResponsiveCol` instances.

`LayrzResponsiveCol` — column definition within a responsive row. Specifies width at each breakpoint (xs, sm, md, lg, xl).

Example:
```dart
LayrzResponsiveRow(
  children: [
    LayrzResponsiveCol(xs: 12, sm: 6, md: 4, child: ...),
    LayrzResponsiveCol(xs: 12, sm: 6, md: 8, child: ...),
  ],
)
```

Breakpoints use constants from `lib/constants/src/grid.dart` (kExtraSmallGrid, etc.).

**Dependencies**: M1 (constants, tokens).

**Files affected**:
- `lib/grid/` (new module)
- `lib/grid/grid.dart` (barrel, new)
- `lib/grid/src/responsive_row.dart` (new)
- `lib/grid/src/responsive_col.dart` (new)
- `test/grid/responsive_row_test.dart` (tests)

---

### 8. LayrzAnimatedCheckbox

**Brief description**:

Stateful checkbox widget with smooth animation. Integrates with M3 LayrzCheckboxInput (as a separate component or as a factory on the input).

Animation covers state change, unchecked → checked → unchecked transitions.

**Dependencies**: M1 (LayrzTheme, tokens, WidgetState), Flutter animations (single_tick_provider, transition_builder, etc.).

**Files affected**:
- `lib/checkboxes/` (new module)
- `lib/checkboxes/checkboxes.dart` (barrel, new)
- `lib/checkboxes/src/animated_checkbox.dart` (new)
- `test/checkboxes/animated_checkbox_test.dart` (tests)

---

## Acceptance Criteria

M2 is complete when all the following criteria are satisfied:

- **Item 1 (LayrzButton)**: Constructor documented, ten styles render correctly, six semantic factories render with icons and colours, loading/cooldown states externally-owned via ValueListenable, D15 interaction states verified (no geometry changes), RawTooltip caveat noted, `flutter analyze` clean, tests green, `@Preview` annotations present
- **Item 2 (LayrzActionButton/ActionsButtons)**: Icon-only rendering, horizontal grouping, spacing consistent with theme tokens
- **Item 3 (LayrzTooltip)**: Wraps RawTooltip, theme-aware positioning, animated display, RawTooltip requirement of Overlay ancestor documented
- **Item 4 (LayrzChip/ChipGroup)**: Chip styling, delete action, group selection behaviour, state management via WidgetState
- **Item 5 (LayrzAlert)**: Five visual styles, semantic types (info, success, warning, danger, context), icon integration
- **Item 6 (LayrzAvatar/LayrzImage)**: Avatar from URL/base64/initials, image fallback, placeholder rendering
- **Item 7 (LayrzResponsiveRow/Col)**: 12-column grid, breakpoint-specific widths, responsive adaptation
- **Item 8 (LayrzAnimatedCheckbox)**: Animation on state change, smooth transitions
- **All tests pass**: `flutter test` reports 100% pass
- **Coverage floor maintained**: `flutter test --coverage` reports >90% coverage (current baseline 97.21%)
- **Invariant verified**: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- **All code documented**: Every public member has doc comments per rule #1
- **All visual components have @Preview**: Annotations at bottom of widget files
- **Wiki updated**: Pages created for all M2 components with API, examples, and design rationale
- **GitHub Project updated**: All items moved to Done
- **engineering/milestone-2.md Status table updated**: All items marked Done

---

## Explicit Non-Goals

The following **are out of scope** for M2:

- **Any M3+ components** (inputs, pickers, etc.) — M3 and beyond
- **Dark theme** — layrz_ui targets light mode only; see decision D7 in engineering/decisions.md
- **Accessibility audit** — baseline WCAG coverage via Semantics is in place; comprehensive audit is deferred
- **Performance optimization** — measure after all M2 components exist

---

**Milestone 2 plan finalized**: 2026-08-15

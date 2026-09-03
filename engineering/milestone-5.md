# Milestone 5: Layout, Navigation, and Feedback

## Goal

Build structural and feedback widgets for app shells, routing, and user notifications. Focus on three core layout components: `LayrzLayout` (application shell), `LayrzScaffoldShell<T>` (list-detail shell), and `LayrzScrollbar` (Material-free scrollbar), followed by tab navigation, snackbars, dialogs, and notification items.

This is the **fourth components milestone** after M1 Foundation, M2 Core Primitives, M3 Input Fields, and M4 Pickers. M5 components establish navigation patterns and feedback conventions that consuming apps will use to structure their UI.

## Status

| # | Item | Status |
|---|---|---|
| 1 | LayrzLayout (application shell with sidebar/drawer nav, drawer floating-page reveal transition, flat navigator items, user menu, notifications) | Done |
| 2 | LayrzScaffoldShell<T> (adaptive list-detail shell, container-driven breakpoints) | Done |
| 2a | DESIGN-140: LayrzScaffoldShell mobile refinement (narrow band detail in modal bottom sheet, selection persistence across breakpoint crossing) | In progress |
| 2b | Foldable-hinge-aware LayrzScaffoldShell (D73: only a vertical seam splits, mapped via RenderBox into the shell's own local box; a horizontal seam never splits; a `kLayrzFoldMinSplitHeight` shell-height gate retracts the split when the keyboard opens; multiple qualifying seams (Z TriFold) pick the one nearest 1/3 of the shell's width; `cutout` features ignored, `postureHalfOpened` supported like `postureFlat`) | In progress |
| 3 | LayrzScrollbar (Material-free on RawScrollbar, installed by default in LayrzApp) | Done |
| 4 | LayrzTabView and LayrzTab (horizontal tabs with Material 3 styling) | Todo |
| 5 | LayrzSnackbar and LayrzSnackbarMessenger (transient feedback) | Todo |
| 6 | Dialogs on RawDialogRoute (general, alert, confirmation) | Todo |
| 7 | LayrzAboutDialog | Todo |
| 8 | DESIGN-81: Page transitions (`LayrzPageTransitions`: fade, slide, scale, rotation, none — shared builders for both `PageRouteBuilder.transitionsBuilder` and go_router's `CustomTransitionPage.transitionsBuilder`) | Merged · Review required |
| 9 | LayrzNotificationItem (notification display in nav footer) | Todo |
| 10 | DESIGN-95: LayrzRefreshIndicator (loading affordance for a refresh lifecycle; programmatic `LayrzRefreshController.refresh()` is the primary API, drag-to-refresh is an optional touch-only affordance) | Merged · Review required |

**Note**: This table is the authoritative record of M5 work items, kept in step with the code in the same commit. Each row's status is updated when the item completes. The Notion ⚒️ Progress database is the shared, publicly linkable view of this same status (rows are identified as `DESIGN-N` for cross-reference). Items 1-3 were delivered ahead of formal M5 planning; they are marked Done and documented in detail in the wiki.

## Definition of Done

- All 10 items below complete
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M5 tests
- Coverage floor (90%) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- All M5 components integrated with theme system (LayrzTheme, tokens, state resolution)
- Wiki pages created/updated for all M5 components

---

## Work Items

### 1. LayrzLayout (Application Shell with Navigation)

**Status**: Done

**What it does**:
- Top-level application scaffold with navigation rail and body content
- Two presentations resolved by container width via `LayoutBuilder` + `bandAt()`:
  - **Expanded** (md/lg/xl): 178px labelled sidebar, body content centred at xl
  - **Drawer** (sm/xs): 56px top bar with off-canvas 260px drawer
- Single flat navigation list: `LayrzNavigatorPage` (page + icon + label + active flag) and `LayrzNavigatorLabel` (section band)
- User block with avatar, name, and `RawMenuAnchor` dropdown from `userMenuItems`
- Notifications footer row with `RawMenuAnchor` dropdown panel (never a route)
- Search field filters pages by `labelText`, preserving section labels whose section still matches

**Constraints**:
- No automatic breadcrumb rendering, no route-to-label binding
- `logo` is a required `String` (image source), not a widget
- Consumer owns active page via `LayrzNavigatorPage.isSelected`; layout does not push routes
- No persistent vs. transient item distinction; single flat list

**API contract**: See [wiki LayrzLayout page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzLayout) for full constructor and parameter documentation.

---

### 2. LayrzScaffoldShell<T> (Adaptive List-Detail Shell)

**Status**: Done

**What it does**:
- Generic list-detail shell, driven by `onBuild` (returns `LayrzScaffoldTile`) and `onDetailsBuild(T)` (renders detail area)
- Two presentations resolved by container width:
  - **Expanded** (md/lg/xl): Two panes side-by-side (list left, detail right)
  - **Narrow** (sm/xs): List always visible; detail in modal `LayrzBottomSheet` (DESIGN-140 un-deferred the mobile bottom-sheet presentation)
- `LayrzScaffoldController<T>` (mandatory) holds opened item for external detail toggle
- `LayrzScaffoldTile` (abstract base class) enforces `titleRichText`, `subtitleRichText`, `actions` getters; `LayrzScaffoldValueTile` provides value-equality concrete implementation
- Search reports through `onSearch` callback; consumer owns filtering (shell does not filter)
- No grouping, no detail tabs, no docked inspector; detail area is opaque to shell

**Constraints**:
- Rows are NOT keyed by tile; consumer owns key strategy
- Narrow band requires a `Navigator` ancestor (e.g. inside `LayrzApp`); a debug assert fires if missing
- Sheet is not customizable: always uses `LayrzBottomSheet` defaults (initialSize 0.5, snaps [0.5, 0.95], maxSize 0.95, drag handle on)
- Selection persistence survives breakpoint crossing; no new public parameters added to the constructor
- All state (selected item, search text) driven by `LayrzScaffoldController` and callbacks

**API contract**: See [wiki LayrzScaffoldShell page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzScaffoldShell) for full generic contract and examples.

---

### 3. LayrzScrollbar (Material-Free Scrollbar)

**Status**: Done

**What it does**:
- Material-free scrollbar built on `RawScrollbar` (not `Scrollbar`, which is Material)
- Thumb always visible and rounded; track hidden until hover
- `LayrzScrollBehavior` decorates every vertical scrollable; `LayrzApp` installs it by default when `scrollBehavior` is null
- Horizontal scrollables and touch platforms exempt
- This is a visible behaviour change for consuming apps that had no scrollbars before; opt out via explicit `scrollBehavior`

**Constraints**:
- Vertical scrollables only; horizontal and touch exempt
- Installed by default in LayrzApp; not opt-in per-widget
- No Material coupling despite Material SDK having `Scrollbar`

**API contract**: See [wiki LayrzScrollbar page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzScrollbar) for configuration and opt-out guidance.

---

### 4. LayrzTabView and LayrzTab (Horizontal Tabs)

**What it does**:
- Material 3-styled horizontal tabs without Material import
- Support for text-only, icon-only, and icon+text variants
- Customizable tab styles (filled, outlined, etc.) via tokens
- Indicator animation and transition

**Acceptance Criteria**:
- Port from layrz_theme's ThemedTabView and ThemedTab
- Material-free construction using CustomPaint or stacked containers
- Tests cover all tab variants and state transitions
- Wiki page covers API, usage, and styling customization

---

### 5. LayrzSnackbar and LayrzSnackbarMessenger (Transient Feedback)

**What it does**:
- Material-free toast-like notification at the bottom of the screen
- Supports text, actions (buttons), and optional icons
- Automatic dismiss after timeout, or manual dismiss via action
- `LayrzSnackbarMessenger` provides show/hide API via `ScaffoldMessenger`-style context extension

**Acceptance Criteria**:
- Port ThemedSnackbar family
- Test show/hide lifecycle and timeout
- Support custom styling via tokens (background, text color, shadow)
- Wiki page covers positioning, timeout config, and action handling

---

### 6. Dialogs on RawDialogRoute (General, Alert, Confirmation)

**What it does**:
- Three dialog factories: general (`show()`), alert (confirmation with Yes/No), and destructive confirmation (warning, Confirm/Cancel)
- Material-free construction on `RawDialogRoute` and overlay primitives
- Intrinsic sizing with optional max width constraint
- Keyboard: Escape closes, Tab cycles focus, Enter confirms

**Acceptance Criteria**:
- Port ThemedAlertDialog, ThemedConfirmationDialog, and general dialog builder
- Material-free modal backdrop (ScaleTransition + FadeTransition on overlay)
- Test keyboard navigation and result callbacks
- Wiki page covers factory API and styling

---

### 7. LayrzAboutDialog

**What it does**:
- Standard about dialog showing app version, company name, license links
- Scrollable content area for long license text

**Acceptance Criteria**:
- Port ThemedAboutDialog
- Support version string, company info, custom license content
- Test layout and scrolling
- Wiki page documents constructor and usage

---

### 8. DESIGN-81: Page Transitions (`LayrzPageTransitions`)

**Status**: Merged · Review required

**What it does**:
- Material-free page transitions built on `FadeTransition`, `SlideTransition`, `ScaleTransition`,
  and `RotationTransition` from `widgets.dart`
- Ships the full union of named transitions: `fade` (default), `slide`, `scale`, `rotation`, `none`
  — corrected from this row's original parenthetical, which only described fade+scale; the shipped
  surface is all five
- `LayrzTransitionBuilder` is a plain typedef matching both `PageRouteBuilder.transitionsBuilder`
  and go_router's `CustomTransitionPage.transitionsBuilder` structurally, so the same builder
  function serves both call sites with zero adapter code and no `go_router` dependency added to the
  package
- `LayrzPageTransitions.durationOf(context)` resolves the matching duration token
  (`tokens.motion.dPageTransition`, 250ms) for the route's own `transitionDuration` parameter
- Every builder delegates to `none` when `MediaQuery.disableAnimationsOf` reports reduced motion

**Default**: `fade` — ratified by Kenny (`.claude/pipeline/RULINGS.md`), overriding the
implementation plan's `none` recommendation.

**API contract**: See [wiki LayrzPageTransition page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzPageTransition).

---

### 9. LayrzNotificationItem (Notifications in Nav Footer)

**What it does**:
- Display notification badge or indicator in the LayrzLayout footer
- Support for count badges, icons, and dot indicators
- `RawMenuAnchor` dropdown panel for detailed notifications

**Acceptance Criteria**:
- Port ThemedNotificationItem
- Support badge count, custom icons, and visibility toggles
- Test dropdown panel open/close
- Wiki page documents badge styling and dropdown content

---

### 10. DESIGN-95: LayrzRefreshIndicator (Refresh Loading Affordance)

**Status**: Merged · Review required

**What it does**:
- Reports a refresh lifecycle (`idle → armed → refreshing → settling → idle`) above a scrollable
  region via `LayrzRefreshController` (state machine) and `LayrzRefreshVisual` (the painted ring)
- **The programmatic `LayrzRefreshController.refresh()` call is the primary, always-available
  API** — not a test hook layered under a gesture. The optional `LayrzRefreshGestureDetector`
  (touch-only, wired by default via `enableDragGesture: true`) is a second entry point into the
  exact same controller call, for drag-to-refresh on touch devices
- No custom `ScrollPhysics`/`ScrollBehavior` installed — the drag gesture reads
  `OverscrollNotification`s via a local `NotificationListener`

**Naming**: Kenny ruled to **keep `LayrzRefreshIndicator`** (`.claude/pipeline/RULINGS.md`),
overriding the plan's `LayrzRefreshView` recommendation, which had been proposed on the premise
that the gesture-first framing this reframe demoted was still primary.

**Non-goals (v1)**: no resistance/overscroll physics curve (linear drag-to-progress mapping only);
no platform branching on `LayrzPlatform`; no sliver support.

**API contract**: See [wiki LayrzRefreshIndicator page](https://github.com/goldenm-software/layrz_ui/wiki/LayrzRefreshIndicator).

---

## Dependencies

- **M1 (Tokens, Theme)**: LayrzTheme, LayrzThemeData, LayrzTokens, token resolution
- **M2 (Buttons, Alerts)**: LayrzButton for dialog actions, LayrzAlert for inline feedback
- **M3 (Inputs)**: LayrzTextInput for search in LayrzScaffoldShell
- **M4 (Pickers)**: Date/time inputs for dialog options (not blocking M5 ship)

## Notes

- **Container-driven breakpoints**: LayrzLayout and LayrzScaffoldShell use `LayoutBuilder` constraints + `bandAt()`, NOT viewport breakpoints. This differs from LayrzRow/LayrzCol (viewport-driven).
- **LayrzApp scrollbar behaviour is a visible change**: Apps now get scrollbars on vertical scrollables. Opt out with an explicit `scrollBehavior`.
- **Breakpoint constants**: Both use the same `kExtraSmallGrid`, `kSmallGrid`, etc. from constants.dart for consistency.

---

**Milestone 5 started**: 2026-08-19  
**Last updated**: 2026-08-19  
**Related documents**: [Roadmap](roadmap.md), [Decisions D37 & D8](decisions.md#d8), [Component Catalog](https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog)

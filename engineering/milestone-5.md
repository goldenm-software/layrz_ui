# Milestone 5: Layout, Navigation, and Feedback

## Goal

Build structural and feedback widgets for app shells, routing, and user notifications. Focus on three core layout components: `LayrzLayout` (application shell), `LayrzScaffoldShell<T>` (list-detail shell), and `LayrzScrollbar` (Material-free scrollbar), followed by tab navigation, snackbars, dialogs, and notification items.

This is the **fourth components milestone** after M1 Foundation, M2 Core Primitives, M3 Input Fields, and M4 Pickers. M5 components establish navigation patterns and feedback conventions that consuming apps will use to structure their UI.

## Status

| # | Item | Status |
|---|---|---|
| 1 | LayrzLayout (application shell with sidebar/drawer nav, flat navigator items, user menu, notifications) | Done |
| 2 | LayrzScaffoldShell<T> (adaptive list-detail shell, container-driven breakpoints) | Done |
| 3 | LayrzScrollbar (Material-free on RawScrollbar, installed by default in LayrzApp) | Done |
| 4 | LayrzTabView and LayrzTab (horizontal tabs with Material 3 styling) | Todo |
| 5 | LayrzSnackbar and LayrzSnackbarMessenger (transient feedback) | Todo |
| 6 | Dialogs on RawDialogRoute (general, alert, confirmation) | Todo |
| 7 | LayrzAboutDialog | Todo |
| 8 | Page transitions (PageRouteBuilder.transitionsBuilder + FadeTransition, ScaleTransition) | Todo |
| 9 | LayrzNotificationItem (notification display in nav footer) | Todo |

**Note**: This table is the authoritative record of M5 work items, kept in step with the code in the same commit. Each row's status is updated when the item completes. The Notion ⚒️ Progress database is the shared, publicly linkable view of this same status (rows are identified as `DESIGN-N` for cross-reference). Items 1-3 were delivered ahead of formal M5 planning; they are marked Done and documented in detail in the wiki.

## Definition of Done

- All 9 items below complete
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass on all M5 tests
- Coverage floor (90%) not breached
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- Every visual component has `@Preview` annotations (rule #3)
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
  - **Narrow** (sm/xs): Single pane with back affordance; consumer toggles between list and detail
- `LayrzScaffoldController<T>` (mandatory) holds opened item for external detail toggle
- `LayrzScaffoldTile` (abstract base class) enforces `titleRichText`, `subtitleRichText`, `actions` getters; `LayrzScaffoldValueTile` provides value-equality concrete implementation
- Search reports through `onSearch` callback; consumer owns filtering (shell does not filter)
- No grouping, no detail tabs, no docked inspector; detail area is opaque to shell

**Constraints**:
- Rows are NOT keyed by tile; consumer owns key strategy
- Mobile bottom-sheet presentation deferred; narrow fallback is single-pane + back
- Mobile deep-linking and restoration are consumer-owned
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

### 8. Page Transitions (PageRouteBuilder + FadeTransition, ScaleTransition)

**What it does**:
- Material-free page transitions using `PageRouteBuilder.transitionsBuilder` with FadeTransition and ScaleTransition from `widgets.dart`
- Support for multiple transition styles (fade, slide, scale, none)
- Configurable duration and curve

**Acceptance Criteria**:
- Implement transition factory functions (e.g., `fadeTransition()`, `scaleTransition()`)
- Test transition duration and curve application
- Verify Material-free construction (no PageTransitionsBuilder import)
- Wiki page documents available transitions and customization

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

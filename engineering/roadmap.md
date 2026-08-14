# layrz_ui Roadmap

This document describes the milestones from M1 (Milestone 1) through M7, their goals, sequencing, and dependencies. Progress on each milestone is tracked in the repository's GitHub Project.

## Overview

layrz_ui is a clean-break rewrite of the Material-free design system. Unlike a port of `layrz_theme` (57,000+ lines across 24 domains with 70+ public components), layrz_ui starts from a foundation-only architecture, building systematically from tokens upward. The codebase will use separate files under `<module>/src/` with export-only barrels, not the `part`/`part of` style of the predecessor.

### Scale Context

`layrz_theme` spans ~57,000 lines across 24 domains with 70+ public components:
- **inputs**: 22,982 lines across 28 part files
- **layout**: 8,400 lines
- **buttons**: 4,128 lines
- **table**: 3,938 lines
- **table2**: 2,412 lines
- **map**: 2,758 lines
- Plus 17 other domains (dialogs, pickers, tooltips, chips, alerts, avatars, etc.)

layrz_ui will eventually reach comparable scope, but via intentional, tested, incremental growth — not copy-paste.

## Sequencing Rationale

Foundation must come before components because:

1. **Token churn** — if tokens change shape mid-way, all components built on them must be refactored. Settling tokens early avoids thrashing existing work.
2. **Infrastructure first** — CI/linting/docs enforcement (M1 items 9–10) must be in place before accepting component contributions, so all code meets standards from day one.
3. **Theme boundary safety** — the `InheritedTheme.wrap()` issue (M1 item 1) must be fixed before building dialogs and overlays, which cross route/Overlay boundaries and lose theme context without wrap().
4. **Testability** — M1 items 11–12 close the test gap; without this, later components ship untested.

---

## Milestone 1: Foundation

**Goal**: Establish the token system, enforce code standards, fix theme-boundary safety, and provide the primitive infrastructure upon which all later components depend.

**Deliverables**: Zero components. Instead: token definitions, token API, theming extensions, preview support, CI pipeline, and a test foundation.

**Definition of done**: All 12 items below complete, CI fully green, and zero Material/Cupertino imports in lib/.

**Unblocks**: M2 and beyond. All downstream milestones depend on M1 tokens, CI guards, and the InheritedTheme wrap() fix.

See [**milestone-1.md**](milestone-1.md) for the detailed 12-item plan, execution order, and acceptance criteria.

---

## Milestone 2: Core Primitives

**Goal**: Build foundational interactive widgets that most other components depend on.

**Deliverables**:
- `LayrzButton` with semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`)
- `LayrzActionButton` and `LayrzActionsButtons`
- `LayrzTooltip` on `RawTooltip`
- `LayrzChip` and `LayrzChipGroup`
- `LayrzAlert` (inline status callout)
- `LayrzAvatar` and `LayrzImage`
- Responsive grid: `LayrzRow` / `LayrzCol` with 12-column breakpoints
- `LayrzAnimatedCheckbox`

**Unblocks**: M3 (inputs depend on button feedback), M4 (pickers use tooltips and buttons), M5 (dialogs and nav use buttons and alerts).

**Dependencies**: M1 (tokens, CI, theme wrap).

---

## Milestone 3: Input Fields

**Goal**: Full suite of user-input widgets with consistent error handling, validation styling, and field containers.

**Deliverables**:
- `LayrzTextInput` (single-line and multiline textarea)
- `LayrzNumberInput` (with min/max, step buttons, decimal formatting)
- `LayrzPasswordInput` (strength indicator, show/hide)
- `LayrzCheckboxInput` (checkbox, switch, dropdown styles)
- `LayrzRadioInput` on `RawRadio`
- `LayrzSwitch` on `ToggleableStateMixin`
- `LayrzSelectInput` (single-value dropdown)
- `LayrzMultiSelectInput` (multi-value dropdown)
- `LayrzSearchInput` (inline or expandable)
- `LayrzDualListInput` (two-panel available/selected)
- `LayrzDurationInput` (timeout, interval, shift length)
- Support types: `LayrzSelectItem`, field-error display, input-container styling

**Unblocks**: M4 (pickers are specialized inputs), M6 (table cells use inputs for inline editing).

**Dependencies**: M1 (tokens, CI, WidgetStateProperty), M2 (buttons for field actions, alerts for errors).

---

## Milestone 4: Pickers (Inputs with Selection Surfaces)

**Goal**: Specialized input widgets for date, time, and selection of complex types.

**Naming note**: The group name "Pickers" refers to the **interaction pattern** — inputs that open a selection surface on tap. All components in this milestone are named `Layrz*Input` and compose `LayrzTextInput` internally, rendered read-only. None are named `*Picker`; that suffix from layrz_theme is retired entirely. See [`input-contract.md`](input-contract.md) for the shared input family contract.

**Deliverables**:
- Date input (single date)
- Date range input
- Time input (single time-of-day)
- Time range input (start + end)
- Datetime input (single date+time, tabbed dialog)
- Datetime range input (start + end datetimes)
- Datetime stepped input (calendar first, then time)
- Month input (grid with year nav)
- Month range input (consecutive or arbitrary)
- Emoji input (single emoji, full or filtered groups)
- Icon input (from Solar icon set)
- File input (system file browser, returns base64 + bytes)
- Avatar input (system image picker, returns base64)
- Dynamic avatar input (URL, base64 upload, icon, or emoji)
- Color input (hand-rolled replacement for flex_color_picker)

**Unblocks**: M5 (dialogs and sheets), M6 (table column filters).

**Dependencies**: M1 (tokens, theme), M2 (buttons, buttons in picker footers), M3 (text input for combobox autocomplete in select pickers).

---

## Milestone 5: Layout, Navigation, and Feedback

**Goal**: Structural and feedback widgets for app shells, routing, and user notifications.

**Deliverables**:
- `LayrzAppBar` (top navigation)
- Navigation variants: side nav, bottom nav, mini nav, dual nav
- `LayrzNavigatorItem` types (page, action, widget, separator, label)
- `LayrzScaffoldShell` (adaptive list-detail shell with internal pane/sheet swap)
- `LayrzTabView` and `LayrzTab` (horizontal tabs)
- `LayrzSnackbar` and `LayrzSnackbarMessenger` (transient feedback)
- Dialogs on `RawDialogRoute` (general, alert, confirmation)
- `LayrzAboutDialog`
- Page transitions on `PageTransitionsBuilder`
- `LayrzNotificationItem`

**Unblocks**: M6 (tables live in scaffolds), M7 ecosystem features.

**Dependencies**: M1 (tokens, theme), M2 (buttons, alerts), M4 (pickers in dialog options).

---

## Milestone 6: Data Display

**Goal**: Widgets for displaying and exploring structured data.

**Deliverables**:
- `LayrzTable<T>` (data table with columns, sorting, search, multiselect, row actions)
- `LayrzCalendar` (month view with event rendering)
- Grid delegate helpers (adaptive layouts)
- Table support types: column definitions, controller, row actions, selection state

**Unblocks**: M7 ecosystem (analytics dashboards, reports).

**Dependencies**: M1 (tokens, theme), M2 (buttons for actions), M3 (text inputs for search/filter), M4 (date pickers for range filters).

---

## Milestone 7: Blocked / Deferred

**Goal**: Components that have external dependencies preventing them from shipping in earlier milestones.

**Items**:
- **Map** — requires a flutter_map replacement (none exists in pure Dart; blocked upstream)
- **Code editor** — requires a code_text_field replacement
- **Code snippet** — requires a flutter_highlight replacement
- **Model-bound inputs** — inputs tied to layrz_models (dynamic credentials, etc.) — deferred until layrz_models is decoupled from Material
- **Colorblindness filter** — awaiting upstream canvas/shader support
- **LML language tooling** — awaiting design finalization

---

## Key Decisions

### Naming: Clean Break

layrz_ui uses `Layrz*` prefix (e.g., `LayrzButton`, `LayrzTextInput`), not `Themed*`. This is a deliberate clean break from `layrz_theme`. Consuming apps must rename every widget; there is no one-line-import migration path.

**Rationale**: The scope of Material deprecation and the frequency of token changes early in M1 make compatibility aliases more liability than help.

### layrz_models Coupling: Deferred

19 files in `layrz_models` import Material. Components bound to those models (dynamic credentials input, sensor cards, etc.) are deferred until the models are decoupled.

**Rationale**: Pulling layrz_models in as a dependency now would force Material back into the transitive closure, breaking the invariant.

### Fonts: google_fonts with TextStyle API Only

layrz_ui depends on `google_fonts: ^8.2.1` but uses only the `TextStyle`-returning APIs, never the `*TextTheme()` family (which is Material-coupled).

**Rationale**: google_fonts' Material import is dead code only. Risk: when Material leaves core in late 2026, google_fonts may migrate onto material_ui, forcing a transitivity decision then.

---

## Infrastructure Status

- **Flutter SDK**: 3.47.0 stable (framework revision 4cf2416426)
- **Dart SDK**: 3.13.0
- **SDK constraint**: `>=3.13.0 <4.0.0` (Flutter `>=3.47.0`)
- **CI**: Not yet implemented (M1 item 9)
- **Analysis**: `public_member_api_docs` not yet enabled (M1 item 10)

### Flutter 3.47 Material Decoupling Context

As of Flutter 3.47:
- `material_ui` 1.0.0 and `cupertino_ui` are standalone pub packages
- The SDK's `material.dart` is NOT yet deprecated (no `@Deprecated` markers)
- Formal deprecation is the November 2026 stable release
- Removal from core is late 2026
- Migration tool for apps: `dart fix --apply --code=migrate_design_widgets`

See [**flutter-347-audit.md**](flutter-347-audit.md) for the complete inventory of raw primitives available in 3.47.

---

**Roadmap last updated**: 2026-08-13

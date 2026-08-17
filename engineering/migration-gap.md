# layrz_ui Migration Gap Analysis

## Purpose and Method

This document is a mechanical enumeration of every public symbol in `layrz_theme`, cross-referenced against `layrz_ui`'s 33 wiki pages and 30 GitHub Project items. An earlier partial inventory undercounted the actual surface; this document supersedes it as the completeness reference and identifies blocking decisions, dependency incompatibilities, and scope ambiguities that must be resolved before migration can proceed.

The inventory was produced by:
1. Reading `layrz_theme`'s public exports across all modules
2. Checking against [`layrz_ui` wiki pages](https://github.com/goldenm-software/layrz_ui/wiki)
3. Cross-referencing GitHub Project items and closed scope decisions
4. Classifying each symbol by migration path: `port` (implement in layrz_ui), `drop` (remove entirely), `blocked` (awaiting decision or external blocker), `needs decision` (scope unconfirmed)

---

## Headline Numbers

### layrz_theme public surface, by domain group

- **Inputs**: 49 symbols (text, password, number, select, multiselect, dual-list, search, combobox, date/datetime pickers with variations, duration, file, avatar pickers, emoji, icon, color, checkbox, radio, dynamic avatar, dynamic credentials)
- **Buttons**: 5 symbols (ThemedButton + 6 semantic factories; ThemedActionButton + 6 factories)
- **Chips**: 4 symbols (ThemedChip, ThemedChipGroup, style enum, behavior enum)
- **Alerts**: 4 symbols (ThemedAlert, icon, type enum, style enum)
- **Subtotal (Forms & Feedback)**: 62 symbols

- **Layout & Navigation**: 14 symbols (ThemedLayout, styles, bars, app bars, navigator items and hierarchy) — *Note: 6 symbols (styles, bars) are being dropped per D8*
- **Scaffolds & Views**: 3 symbols (ThemedScaffoldView, cell, license)
- **Tabs**: 3 symbols (ThemedTab, ThemedTabView, style enum)
- **Views**: 3 symbols (ThemedAboutDialog + function, WorkInProgressView)
- **Snackbar**: 6 symbols (ThemedSnackbar, messenger, behavior, position enums)
- **Tooltips**: 2 symbols (ThemedTooltip, position enum)
- **Subtotal (Layout & Presentation)**: 31 symbols

- **Table**: 10 symbols (@Deprecated; migrate to table2)
- **Table2**: 11 symbols (ThemedTable2<T>, controller, column config, 5 event types, on-tap behavior)
- **Widgets**: 6 symbols (ThemedImage, ThemedCalendar + modes and entries)
- **Helpers**: 9 symbols (parse base64, file → byte array, color validation, swatch generation, theme color resolution, info dialogs, etc.)
- **Responsive Grid**: 4 symbols (LayrzRow, LayrzCol, Sizes enum, extension) — *Note: 2 symbols (Sizes, SizesExt) are being dropped per D9*
- **Map Subsystem**: 13 symbols (buttons, layers, dialogs, controller, events, helpers, constants)
- **Subtotal (Data & Display)**: 53 symbols

- **Theme Data & Tokens**: 9 symbols (LayrzTokenizer with 5 extensions covering color, shadow, radius, spacing, border)
- **Theme Generation**: 4 symbols (generateLightTheme, generateDarkTheme, font handler, border) — *Note: generateDarkTheme is being dropped per D7 (light mode only)*
- **Extensions & Utilities**: 8 symbols (num sizing, DateTime, Duration humanization, ORM helpers, page transitions, grid delegates, file, state utils, i18n, styling)
- **Color Blindness**: 7 symbols (filter extension + 6 filter functions) — *Note: Now in scope pending D2 audit (D10)*
- **Constants**: ~4 symbols (font, list padding, system UI styles; missing from layrz_ui)
- **Branded Assets**: 2 symbols (Layo widget, LayoEmotions enum)
- **Other**: 5 symbols (FileType, platform checks, language/locale support)
- **Subtotal (Theme & Internals)**: 39 symbols

**Total layrz_theme public surface: 187 symbols**

### layrz_ui current state

- **33 wiki pages**: LayrzButton, LayrzTextInput, LayrzSnackbar, LayrzCard, LayrzLayout (placeholder), LayrzAlert, LayrzChip, LayrzSelect, LayrzMultiSelect, LayrzDatePicker, LayrzDateRangePicker, LayrzDateTime, LayrzDateTimeRange, LayrzTimePicker, LayrzTimeRange, LayrzNumberInput, LayrzPasswordInput, LayrzFileInput, LayrzAvatarPicker, LayrzEmojiPicker, LayrzIconPicker, LayrzColorPicker, LayrzCheckbox, LayrzRadio, LayrzSearch, LayrzCombobox, LayrzDynamicAvatar, LayrzDynamicCredentials, LayrzTable, LayrzTooltip, LayrzTab, and two unscoped placeholders.
- **30 GitHub Project items**: mostly aligned with wiki coverage.
- **Implemented lib/**: ~940 lines
  - LayrzApp, LayrzApp.router (entry points)
  - LayrzThemeMode (enum)
  - LayrzTheme (InheritedWidget)
  - LayrzThemeData, LayrzTextTheme (theme data classes)
  - LayrzColorExtensions, LayrzContextExtensions (extensions)
  - LayrzPlatform (enum)
  - ~11 constants (breakpoints, animation durations, etc.)

**Status**: only LayrzButton, LayrzTextInput, and LayrzSnackbar have team-confirmed scope. LayrzCard has confirmed intent with an open parameter list. LayrzLayout is a placeholder. The remaining 28 are derived from layrz_theme and awaiting formal scope confirmation.

---

## Already Covered (33 Components)

Listed by domain, with scope status.

### Confirmed scope (team-approved, parameters final or near-final)

- **LayrzButton** (`lib/src/button/` → 6 semantic factories: `.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete` — note: `.legacyLoading()` from layrz_theme is deliberately NOT carried over)
- **LayrzTextInput** (`lib/src/text_input/`)
- **LayrzSnackbar** (`lib/src/snackbar/`)

### Confirmed intent, parameters pending

- **LayrzCard** (structure known; parameter list unresolved)

### Placeholder or derived (pending formal scope confirmation)

- LayrzAlert, LayrzChip, LayrzSelect, LayrzMultiSelect, LayrzDatePicker, LayrzDateRangePicker, LayrzDateTime, LayrzDateTimeRange, LayrzTimePicker, LayrzTimeRange, LayrzNumberInput, LayrzPasswordInput, LayrzFileInput, LayrzAvatarPicker, LayrzEmojiPicker, LayrzIconPicker, LayrzColorPicker, LayrzCheckbox, LayrzRadio, LayrzSearch, LayrzCombobox, LayrzDynamicAvatar, LayrzDynamicCredentials, LayrzTable, LayrzTooltip, LayrzTab, LayrzLayout (28 total)

All 28 derived pages reference layrz_theme symbols but have not received formal scope sign-off from the product/design team. Implementation order is not established; wiki pages are reference for engineering only.

---

## MISSING — Mapping layrz_theme → layrz_ui Gaps

Organized by domain. For each entry: layrz_theme symbol, kind (class/enum/extension/typedef/function/constant/mixin), source file, and classification (port/drop/blocked/needs decision) with reason. Proposed target names in `LaTeXlike syntax` indicate names not yet team-approved.

### Layout and Navigation Chrome

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedLayout` | class | `lib/src/layout/layout.dart` | needs decision | LayrzLayout is a placeholder in Milestone 1. Scope unconfirmed on single layout design selection and navigator item types. See D8 in [decisions.md](decisions.md). |
| `ThemedLayoutStyle` | enum (dual, sidebar, mini) | `lib/src/layout/layout.dart` | **drop** | Dropped by D8 (LayrzLayout ships exactly one layout design). Multiple desktop presentations are out of scope for Milestone 1. |
| `ThemedMobileLayoutStyle` | enum (appBar, bottomBar) | `lib/src/layout/layout.dart` | **drop** | Dropped by D8 (LayrzLayout ships exactly one layout design). Multiple mobile presentations are out of scope for Milestone 1. |
| `ThemedDualBar` | class | `lib/src/layout/src/bars/dual.dart` | **drop** | Dropped by D8. Dual bar presentation not carried over in single-design approach. |
| `ThemedSidebar` | class | `lib/src/layout/src/bars/side.dart` | **drop** | Dropped by D8. Sidebar presentation not carried over in single-design approach. |
| `ThemedMiniBar` | class | `lib/src/layout/src/bars/mini.dart` | **drop** | Dropped by D8. Mini bar presentation not carried over in single-design approach. |
| `ThemedBottomBar` | class | `lib/src/layout/src/bars/bottom.dart` | **drop** | Dropped by D8. Bottom bar presentation not carried over in single-design approach. |
| `ThemedAppBar` | class | `lib/src/layout/src/appbar/desktop.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedMobileAppBar` | class | `lib/src/layout/src/appbar/mobile.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedAppBarAvatar` | class | `lib/src/layout/src/parts/avatar.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedNotificationIcon` | class | `lib/src/layout/src/parts/notification.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedNotificationLocation` | enum (appBar, miniBar, bottomBar, sideBar, custom) | `lib/src/layout/src/parts/notification.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedCustomNotificationLocation` | class | `lib/src/layout/src/parts/notification.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| abstract `ThemedNavigatorItem` | abstract class | `lib/src/layout/src/models.dart` | needs decision | Navigator item types to be confirmed per D11. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedNavigatorPage` | class extends ThemedNavigatorItem | `lib/src/layout/src/models.dart` | needs decision | Depends on ThemedNavigatorItem scope. Subject to D8. |
| `ThemedNavigatorAction` | class extends ThemedNavigatorItem | `lib/src/layout/src/models.dart` | needs decision | Depends on ThemedNavigatorItem scope. Subject to D8. |
| `ThemedNavigatorWidget` | class extends ThemedNavigatorItem | `lib/src/layout/src/models.dart` | needs decision | Depends on ThemedNavigatorItem scope. Subject to D8. |
| `ThemedNavigatorSeparator` | class extends ThemedNavigatorItem | `lib/src/layout/src/models.dart` | needs decision | Depends on ThemedNavigatorItem scope. Subject to D8. |
| `ThemedNavigatorLabel` | class extends ThemedNavigatorItem | `lib/src/layout/src/models.dart` | needs decision | Depends on ThemedNavigatorItem scope. Subject to D8. |
| `ThemedNotificationItem` | class | `lib/src/layout/src/models.dart` | needs decision | Scope pending. Subject to LayrzLayout's single-design scope decision (D8). |
| `ThemedSeparatorType` | enum | `lib/src/layout/src/models.dart` | needs decision | Depends on navigator item scope. Subject to D8. |
| typedef `ThemedNavigatorPushFunction` | typedef | `lib/src/layout/layout.dart` | needs decision | Depends on layout scope. Subject to D8. |
| typedef `ThemedNavigatorPopFunction` | typedef | `lib/src/layout/layout.dart` | **needs decision — typo opportunity** | IMPORTANT: This symbol is misspelled in layrz_theme as `ThemdNavigatorPopFunction` (missing the "e"). D8 offers an opportunity to correct it to `LayrzNavigatorPopFunction` in layrz_ui. Scope depends on navigator types decision. |

**Layout decision note (D8)**: Decision D8 clarifies that LayrzLayout ships exactly ONE layout design in Milestone 1. The multiple presentations (dual, sidebar, mini desktop; appBar, bottomBar mobile) are **dropped** from scope. Future design variants can be added in later releases. The single design's specific form and navigator item types remain to be scoped.

---

### Feedback and Display

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedAlert` → `LayrzAlert` | class | `lib/src/alerts/src/alert.dart` | port | LayrzAlert wiki exists; formal scope confirmed in D11. D27: style trim from 5 to 2 (layrz, filledIcon). |
| `ThemedAlertIcon` → `LayrzAlertIcon` | class | `lib/src/alerts/src/icon.dart` | port | Required by LayrzAlert. Part of LayrzAlert family (D11). |
| `ThemedAlertType` → `LayrzAlertType` | enum (info, success, warning, danger, context, custom) | `lib/src/alerts/src/type.dart` | port | Required by LayrzAlert. Part of LayrzAlert family (D11). |
| `ThemedAlertStyle` → `LayrzAlertStyle` | enum (layrz, filledIcon) | `lib/src/alerts/src/style.dart` | port | Required by LayrzAlert. Part of LayrzAlert family (D11). D27: trim from 5 to 2 values; removed filledTonal, filled, outlined. |
| `ThemedChip` → `LayrzChip` | class | `lib/src/chips/src/chip.dart` | port | LayrzChip wiki exists; formal scope confirmed in D11. |
| `ThemedChipGroup` → `LayrzChipGroup` | class | `lib/src/chips/src/group.dart` | port | Required by LayrzChip. Part of LayrzChip family (D11). |
| `ThemedChipStyle` → `LayrzChipStyle` | enum (filled, outlined, elevated) | `lib/src/chips/src/chip.dart` | port | Required by LayrzChip. Part of LayrzChip family (D11). |
| `ThemedChipGroupBehavior` → `LayrzChipGroupBehavior` | enum (none, single, multi) | `lib/src/chips/src/group.dart` | port | Required by LayrzChipGroup. Part of LayrzChip family (D11). |
| `ThemedTooltip` → `LayrzTooltip` | class | `lib/src/tooltips/src/custom_tooltip.dart` | port | LayrzTooltip wiki exists; formal scope confirmed in D11. Prevents default Flutter tooltip. |
| `ThemedTooltipPosition` → `LayrzTooltipPosition` | enum (top, bottom, left, right) | `lib/src/tooltips/src/custom_tooltip.dart` | port | Required by LayrzTooltip. Part of LayrzTooltip family (D11). |
| `ThemedImage` → `LayrzImage` | class | `lib/src/helpers/src/get_image.dart` | port | **CRITICAL**: Owns private base64 image cache that `LayrzDynamicAvatar` delegates to. Cannot implement avatar-bound components without `LayrzImage` or equivalent cache. |

---

### Scaffolds, Tabs and Views

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedScaffoldView` → `LayrzScaffoldShell` | class | `lib/src/scaffolds/src/sidebar.dart` | port | Scope confirmed in D11; merged into single adaptive component. ThemedScaffoldView and ThemedScaffoldCell retired (not ported one-to-one). |
| `ThemedScaffoldCell` → `LayrzScaffoldShell` | (retired) | `lib/src/scaffolds/src/cell.dart` | (merged) | Folded into LayrzScaffoldShell; not separate public API. |
| `ThemedLicense` → `LayrzLicense` | class | `lib/src/views/views.dart` | needs decision | Scope unconfirmed. Separate component from layout infrastructure; scope still open. |
| `ThemedTab` → `LayrzTab` | class | `lib/src/tabs/src/tab.dart` | port | LayrzTab wiki exists; formal scope confirmed in D11. |
| `ThemedTabView` → `LayrzTabView` | class | `lib/src/tabs/src/view.dart` | port | Required by LayrzTab. Part of LayrzTab subsystem (D11). |
| `ThemedTabStyle` → `LayrzTabStyle` | enum (underline, filledTonal) | `lib/src/tabs/src/style.dart` | port | Required by LayrzTab. Part of LayrzTab subsystem (D11). |
| `ThemedAboutDialog` | class | `lib/src/views/src/about.dart` | needs decision | Scope unconfirmed. |
| function `showThemedAboutDialog` | function | `lib/src/views/src/about.dart` | needs decision | Scope unconfirmed; depends on ThemedAboutDialog. |
| `WorkInProgressView` | class | `lib/src/widgets/src/wip.dart` | drop | Placeholder widget; not a production component. Remove on migration. |

---

### Data Display: Calendar, Table, CodeSnippet

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedCalendar` → `LayrzCalendar` | class (1,039 lines) | `lib/src/widgets/src/calendar.dart` | **port — FULL REFACTOR** | Scope confirmed in D11. Four view modes (day, week, month, year) to be ported. **WARNING**: Dependency on `package:table_calendar` (Material-built, 14 Material imports). Full architecture refactor required; cannot be a 1:1 port. Requires Material-free alternative or rewrite. |
| `ThemedCalendarMode` → `LayrzCalendarMode` | enum (day, week, month, year) | `lib/src/widgets/src/calendar.dart` | port | Required by LayrzCalendar. Part of LayrzCalendar subsystem (D11). |
| `ThemedCalendarEntry` → `LayrzCalendarEntry` | class | `lib/src/widgets/src/calendar.dart` | port | Required by LayrzCalendar. Part of LayrzCalendar subsystem (D11). |
| `ThemedCalendarRangeEntry` → `LayrzCalendarRangeEntry` | class | `lib/src/widgets/src/calendar.dart` | port | Required by LayrzCalendar. Part of LayrzCalendar subsystem (D11). |
| `ThemedCodeSnippet` | class | `lib/src/widgets/src/snippet.dart` | needs decision | Scope unconfirmed; syntactic highlighting deferred. |
| `ThemedTable` | class (with @Deprecated) | `lib/src/table/src/table.dart` | drop | Superseded by ThemedTable2. Do not port. |
| `ThemedColumn` | class (with @Deprecated) | `lib/src/table/src/column.dart` | drop | Superseded by table2 column config. Do not port. |

---

### Data Display: Table2 (Replacement Table API)

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedTable2<T>` → `LayrzTable<T>` | generic class | `lib/src/table2/src/table.dart` | port | LayrzTable wiki exists; formal scope confirmed in D11; preferred table API going forward. |
| `ThemedColumn2<T>` → `LayrzColumn<T>` | generic class | `lib/src/table2/src/column.dart` | port | Required by LayrzTable<T>. Part of LayrzTable subsystem (D11). |
| `ThemedTable2Controller<T>` → `LayrzTableController<T>` | generic class | `lib/src/table2/src/controller.dart` | port | Controller for table state and events. Part of LayrzTable subsystem (D11). |
| typedef `ThemedTable2ControllerListener` → `LayrzTableControllerListener` | typedef | `lib/src/table2/src/controller.dart` | port | Event listener callback type. Part of LayrzTable subsystem (D11). |
| abstract `ThemedTable2Event<T>` → `LayrzTableEvent<T>` | abstract class | `lib/src/table2/src/events.dart` | port | Base class for table events. Part of LayrzTable subsystem (D11). |
| `ThemedTable2SortEvent<T>` → `LayrzTableSortEvent<T>` | class | `lib/src/table2/src/events.dart` | port | Sort event. Part of LayrzTable subsystem (D11). |
| `ThemedTable2OnSortEvent<T>` → `LayrzTableOnSortEvent<T>` | class | `lib/src/table2/src/events.dart` | port | On-sort callback event. Part of LayrzTable subsystem (D11). |
| `ThemedTable2SearchEvent<T>` → `LayrzTableSearchEvent<T>` | class | `lib/src/table2/src/events.dart` | port | Search event. Part of LayrzTable subsystem (D11). |
| `ThemedTable2OnSearchEvent<T>` → `LayrzTableOnSearchEvent<T>` | class | `lib/src/table2/src/events.dart` | port | On-search callback event. Part of LayrzTable subsystem (D11). |
| `ThemedTable2RefreshEvent<T>` → `LayrzTableRefreshEvent<T>` | class | `lib/src/table2/src/events.dart` | port | Refresh event. Part of LayrzTable subsystem (D11). |
| `ThemedTable2OnTapBehavior` → `LayrzTableOnTapBehavior` | enum (none, copyToClipboard) | `lib/src/table2/src/on_tap_behavior.dart` | port | Cell tap behavior. Part of LayrzTable subsystem (D11). |

---

### Responsive Grid System

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `Sizes` | enum (col1 through col12) | `lib/src/grid/src/sizes.dart` | **drop** | Dropped by D9 (responsive grid drops Sizes enum). Replaced by plain integer column counts with debug assertion. `ResponsiveCol` now takes `int cols` instead of `Sizes size`. |
| extension `SizesExt` on Sizes | extension | `lib/src/grid/src/sizes.dart` | **drop** | Dropped by D9. No longer needed since column counts are plain integers. |
| `ResponsiveRow` → `LayrzRow` | class + `.builder` factory | `lib/src/grid/src/row.dart` | port | Formal scope confirmed in D11. 12-column grid container. layrz-theme:responsive-row skill applies. |
| `ResponsiveCol` → `LayrzCol` | class | `lib/src/grid/src/col.dart` | port | Formal scope confirmed in D11. Column sizing within LayrzRow. Now takes `int cols` instead of `Sizes size`. layrz-theme:responsive-col skill applies. **API change**: `ResponsiveCol(size: Sizes.col6)` → `LayrzCol(cols: 6)`. |
| **Breakpoint constants** (5 total) | constants | `lib/src/theme/src/constants.dart` | port | kExtraSmallGrid (600), kSmallGrid (960), kMediumGrid (1264), kLargeGrid (1904), implicit extra-large (>1904). Already ported. |

---

### Input Support Types (Not Yet Documented in Wiki)

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedSelectItem` → `LayrzSelectItem` | class | `lib/src/inputs/src/utilities/select_item.dart` | port | Formal scope confirmed in D11. Required by LayrzSelectInput and other select-type inputs. |
| `ThemedFieldDisplayError` → `LayrzFieldDisplayError` | class | `lib/src/inputs/src/utilities/field_error.dart` | port | Used across all input widgets. Formal scope confirmed in D11. |
| `ThemedInputLikeContainer` → `LayrzInputLikeContainer` | class | `lib/src/inputs/src/utilities/input_like_container.dart` | port | Used as base container for inputs. Formal scope confirmed in D11. |
| `DialogSelectInput` | class | `lib/src/inputs/src/general/select_input.dart` | port | Internal support type for select inputs. |
| `SelectInputResult` | class | `lib/src/inputs/src/general/select_input.dart` | port | Return type for select operations. |
| `Month` | enum | `lib/src/inputs/src/pickers/month/single.dart` | port | Month enumeration; used by month-related pickers. |
| `ThemedMonth` | class | `lib/src/inputs/src/pickers/month/single.dart` | port | Month value holder. |
| `NamedIcon` | class | `lib/src/inputs/src/pickers/general/icon.dart` | port | Icon wrapper with name metadata; used by ThemedIconPicker. |
| `ThemedDateTimeRangeDialog` | class | `lib/src/inputs/src/pickers/datetime/range.dart` | port | Internal dialog for date/time range pickers. |
| `ThemedCheckboxInputStyle` | enum (field, switch, flutterCheckbox) | `lib/src/inputs/src/general/checkbox_input.dart` | port | Rendering variants for ThemedCheckboxInput. |
| `ThemedDecimalSeparator` | enum | `lib/src/inputs/src/general/number_input.dart` | port | Decimal point vs. comma locale config. |
| `ThemedSearchPosition` | enum (top, center, bottom) | `lib/src/inputs/src/general/search_input.dart` | port | Search bar placement variant. |
| `ThemedComboboxPosition` | enum (top, bottom) | `lib/src/inputs/src/general/text_input.dart` | port | Combobox dropdown placement. |
| extension `ThemedUnitTranslation` | extension on Map<String, String> | `lib/src/inputs/src/general/duration_input.dart` | port | Duration unit translations (hours, minutes, seconds). |
| typedef `ThemedDynamicAvatarOnChanged` | typedef | `lib/src/inputs/src/general/dynamic_avatar_input.dart` | port | Callback type for avatar changes. |
| typedef `CredentialOnChanged` | typedef | `lib/src/inputs/src/general/dynamic_credentials_input.dart` | port | Callback type for credential changes. |
| typedef `OnSearch` | typedef | `lib/src/inputs/src/general/search_input.dart` | port | Callback type for search events. |
| typedef `EmojiTapCallback` | typedef | `lib/src/inputs/src/pickers/general/emoji.dart` | port | Callback for emoji selection. |
| typedef `ThemedDynamicFieldConfigurationBlockOnChanged` | typedef | `lib/src/inputs/src/dynamic_configurable/block.dart` | port | Callback for dynamic field block changes. |

**Important note**: Existing wiki pages incorrectly reference `SelectItem`, `FieldError`, and `InputLikeContainer` without the `Themed` prefix. Correct the wiki to use actual symbol names on next review.

---

### Button Factories (D11 Scope Confirmation)

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedButton` → `LayrzButton` | class | `lib/src/buttons/src/button.dart` | port | Formal scope confirmed in D11. **Six semantic factories** (`.primary`, `.secondary`, `.icon`, `.fab`, `.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`). Note: `.legacyLoading()` exists in layrz_theme but is **deliberately not carried over** to layrz_ui. The wiki's list of six factories is correct. |
| `ThemedActionButton` → `LayrzActionButton` | class | `lib/src/buttons/src/action_button.dart` | port | Related button widget with six semantic factories (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`). Formal scope pending; related to LayrzButton scope. |

---

### Dynamic Configurable Subsystem

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedDynamicConfigurableBlock` | class (563 lines) | `lib/src/inputs/src/dynamic_configurable/block.dart` | blocked | Requires Avatar, AvatarInput from layrz_models. Blocked by D10 (layrz_models audit pending). See [decisions.md](decisions.md). |
| `ThemedDynamicConfigurableDialog` | class (194 lines) | `lib/src/inputs/src/dynamic_configurable/dialog.dart` | blocked | Depends on ThemedDynamicConfigurableBlock and D10. |
| `ThemedDynamicCredentialsInput` → `LayrzDynamicCredentialsInput` | class | `lib/src/inputs/src/general/dynamic_credentials_input.dart` | **port — scheduled late** | Formal scope confirmed in D11. Depends on layrz_models schema types. Gated on D10 (layrz_models audit). Implementation scheduled after Milestone 2 initial release. |

---

### Code Editor Subsystem

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedCodeEditor` | class (632 lines) | `lib/src/inputs/src/code_editor.dart` | blocked | Depends on `package:code_text_field` (1.1.0) and `package:flutter_highlight` (0.7.0). Architecture review required; Material-built status needs verification. |
| `LayrzSupportedLanguage` | enum | `lib/src/inputs/src/code_editor.dart` | blocked | Depends on ThemedCodeEditor scope. |
| `ThemedCodeError` | class | `lib/src/inputs/src/code_editor.dart` | blocked | Depends on ThemedCodeEditor scope. |
| LML highlight mode (`lml` constant) | Mode constant | `lib/src/languages/lml/` | blocked | Language definition; depends on flutter_highlight. |

---

### Map Subsystem (Blocked on Architecture)

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `ThemedMapButton` | class | `lib/src/map/src/button.dart` | **blocked** | **flutter_map 8.3.0 is architecturally Material-built** (14 Material imports). Entire map subsystem must be rewritten or dropped. |
| `ThemedMapDragButton` | class | `lib/src/map/src/button.dart` | blocked | Depends on ThemedMapButton. |
| `ThemedTileLayer` | class (502 lines) | `lib/src/map/src/layers/tile.dart` | blocked | Integrates Google Street View, Mapbox, HERE; blocked by flutter_map. |
| `ThemedMapToolbar` | class | `lib/src/map/src/layers/toolbar.dart` | blocked | Depends on ThemedMapButton and ThemedTileLayer. |
| `ThemedMapToolbarFlow` | enum | `lib/src/map/src/layers/toolbar.dart` | blocked | Depends on ThemedMapToolbar. |
| `ThemedChangeLayerDialog` | class | `lib/src/map/src/dialogs/change_layer.dart` | blocked | Depends on map layer system. |
| `ThemedMapController` | class | `lib/src/map/src/events/controller.dart` | blocked | Depends on flutter_map. |
| abstract `ThemedMapEvent` | abstract class | `lib/src/map/src/events/events.dart` | blocked | Base for map event hierarchy. |
| `ThemedMapEvent.StartGoogleStreetView` | class extends ThemedMapEvent | `lib/src/map/src/events/events.dart` | blocked | Depends on map events. |
| `ThemedMapEvent.StopGoogleStreetView` | class extends ThemedMapEvent | `lib/src/map/src/events/events.dart` | blocked | Depends on map events. |
| typedef `ThemedMapButtonDragCallback` | typedef | `lib/src/map/src/button.dart` | blocked | Callback for map button drag. |
| typedef `ThemedMapButtonDragNullCallback` | typedef | `lib/src/map/src/button.dart` | blocked | Nullable variant of drag callback. |
| function `subdivideLayersPerSource` | function | `lib/src/map/src/helpers.dart` | blocked | Helper for layer subdivision. |
| constant `kGoldenMHeadquarters` | const LatLng | `lib/src/map/src/constants.dart` | blocked | Default map location. |
| constant `kDefaultLayer` | const TileLayer | `lib/src/map/src/constants.dart` | blocked | Default map layer. |
| constant `kMinZoom` | const double | `lib/src/map/src/constants.dart` | blocked | Map minimum zoom. |
| constant `kMaxZoom` | const double | `lib/src/map/src/constants.dart` | blocked | Map maximum zoom. |

**Map subsystem decision**: The entire map subsystem is blocked on `flutter_map` 8.3.0's Material architecture. Options: (1) rewrite map widget from scratch using raw canvas/gestures; (2) accept flutter_map's Material dependency and relax the no-Material policy for maps only; (3) drop maps entirely. See [decisions.md](decisions.md) and [flutter-347-audit.md](flutter-347-audit.md).

---

### Theme Internals and Tokens

**D7 NOTE (Light Mode Only)**: Decision D7 changes the token architecture from dual light/dark to **light mode only**. This means:
- `generateDarkTheme()` is **dropped** (see classification below)
- All tokens are now concrete light-mode values, not semantic role placeholders
- Any "light/dark dual" requirement in the token classification is **withdrawn**
- Token names and values need not abstract away from specific light-mode colors

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `LayrzTokenizer` | class with static `.of(context)` | `lib/src/tokenizer/tokenizer.dart` | port | Provides runtime access to design tokens. Five extensions below. Light mode only (D7). |
| extension `ColorTokenizer` on LayrzTokenizer | extension | `lib/src/tokenizer/src/colors.dart` | port | Getters: `.info`, `.success`, `.warning`, `.error`, `.danger`, `.context`, `.primary`, `.tonalOpacity`. Light mode only (D7). |
| extension `ShadowTokenizer` on LayrzTokenizer | extension | `lib/src/tokenizer/src/shadows.dart` | port | Getter: `.shadow()` function. Light mode only (D7). |
| extension `RadiusTokenizer` on LayrzTokenizer | extension | `lib/src/tokenizer/src/radius.dart` | port | Getters: `.radius`, `.borderRadius()`, `.innerRadius()`. Light mode only (D7). |
| extension `SpacerTokenizer` on LayrzTokenizer | extension | `lib/src/tokenizer/src/spacers.dart` | port | Getters: `.spacing`, `.spacingSize()`, `.sizedBox()`, `.margin()`, `.reducedMargin()`, `.padding()`. Light mode only (D7). |
| extension `BorderTokenizer` on LayrzTokenizer | extension | `lib/src/tokenizer/src/border.dart` | port | Getter: `.borderWidth`. Light mode only (D7). |
| `ThemedFontHandler` | class | `lib/src/theme/src/font.dart` | port | Functions: `preloadFont()`, `generateFont()`. |
| `ThemedInputBorder` | class | `lib/src/theme/src/utilities.dart` | port | Border configuration for input widgets. |
| `ThemedPlatform` | class | `lib/src/theme/src/platform.dart` | needs decision | Platform-specific theme behavior; scope unclear. |
| function `generateLightTheme` | function | `lib/src/theme/src/light_theme.dart` | port | Generates LayrzThemeData for light mode. Sole theme generation function (D7). |
| function `generateDarkTheme` | function | `lib/src/theme/src/dark_theme.dart` | **drop** | Dropped by D7 (light mode only). LayrzThemeData.dark() removal is pending code work. |
| `RoundedRectangleSeekbarShape` | class | `lib/src/theme/src/custom_painters/thumb_shape.dart` | port | Custom shape for slider/progress widgets. |

**Token system note**: LayrzTokenizer structure differs from what [design-tokens.md](design-tokens.md) currently assumes. Reconciling the two is a product decision. See [decisions.md](decisions.md). **With D7 (light mode only), design-tokens.md's dual light/dark requirement is withdrawn.**

**Missing constants from layrz_ui**:
- `kLayrzFont` (Open Sans via Google Fonts)
- `kListViewPadding`
- ~~`kDarkSystemUiOverlayStyle`~~ (dropped per D7; light mode only)
- `kLightSystemUiOverlayStyle`

These must be added to `lib/src/constants/` before any widget depending on them can be fully ported.

---

### Extensions and Utilities

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| extension `NumToSizedBox` on num | extension | `lib/src/extensions/src/separator.dart` | port | Getters: `.w` (width), `.width`, `.h` (height), `.height`, `.wh` (square), `.square`. |
| extension `DateTimeExtension` on DateTime | extension | `lib/src/extensions/src/datetime.dart` | **blocked — gated on D10** | Getters/methods: `.secondsSinceEpoch`, `.thisWeek`, `.lastWeek`, `.thisMonth`, `.lastMonth`, `.standard`, `.format(String pattern, LayrzAppLocalizations i18n)` (strftime-style). Depends on LayrzAppLocalizations from layrz_models. Gated on D10 audit. |
| `ThemedHumanizeOptions` | class | `lib/src/utilities/src/duration/config.dart` | **blocked — gated on D10** | Configuration for Duration humanization. Depends on LayrzAppLocalizations. Gated on D10 audit. |
| abstract `ThemedHumanizeLanguage` | abstract class | `lib/src/utilities/src/duration/config.dart` | **blocked — gated on D10** | Language definition for humanize. Depends on LayrzAppLocalizations. Gated on D10 audit. |
| `ThemedHumanizedDurationLanguage` | class extends ThemedHumanizeLanguage | `lib/src/utilities/src/duration/config.dart` | **blocked — gated on D10** | Concrete language implementation. Depends on LayrzAppLocalizations. Gated on D10 audit. |
| `ThemedUnits` | enum | `lib/src/utilities/src/duration/enums.dart` | **blocked — gated on D10** | Unit enumeration (years, months, days, hours, minutes, seconds). Depends on LayrzAppLocalizations. Gated on D10 audit. |
| extension `HumanizeDuration` on Duration | extension | `lib/src/utilities/src/duration/extension.dart` | **blocked — gated on D10** | Humanizes Duration to string. Depends on LayrzAppLocalizations. Gated on D10 audit. |
| `ThemedOrm` | class | `lib/src/extensions/src/orm.dart` | port | ORM-like helper; scope unclear. Formal scope to be confirmed. |
| extension `ThemedOrm` on BuildContext | extension | `lib/src/extensions/src/orm.dart` | port | Adds `.orm` getter to BuildContext. Formal scope confirmed in D11. |
| `ThemedPageTransition` | typedef | `lib/src/extensions/src/page_builder.dart` | port | Page transition curve/duration configuration. Formal scope confirmed in D11. |
| `ThemedPageBuilder` | typedef | `lib/src/extensions/src/page_builder.dart` | port | Page builder for transitions. Formal scope confirmed in D11. |
| `ThemedGridDelegateWithFixedHeight` | class | `lib/src/extensions/src/grid_fixed_height.dart` | port | Grid layout delegate with fixed row height. Formal scope confirmed in D11. |
| `ThemedFile` | class | `lib/src/file.dart` | port | File wrapper with utilities. Formal scope confirmed in D11. |
| mixin `VxStateUtilsMixin` | mixin | `lib/src/mixins/src/vx_state.dart` | drop | VxState integration; separate concern. Drop on migration. |
| extension `I18nExtension` on BuildContext | extension | `lib/src/extensions/src/i18n.dart` | **blocked — gated on D10** | Provides `.i18n` getter for LayrzAppLocalizations. Depends on LayrzAppLocalizations from layrz_models. Gated on D10 audit. |
| extension `StylingExtension` on BuildContext | extension | `lib/src/extensions/src/styling.dart` | port | Provides `.style` getter for text styling utilities. Formal scope confirmed in D11. |
| extension `ThemedColorExtensions` on Color | extension | `lib/src/extensions/src/color.dart` | port | Color manipulation helpers. Already ported as LayrzColorExtensions in layrz_ui. Formal scope confirmed in D11. |

**Helper functions** (all in `lib/src/helpers/`):
- `useBlack(Color)` → bool | port | Determines if black text should overlay a color.
- `validateColor(String)` → Color? | port | Parses hex string to Color.
- `getPrimaryColor(BuildContext)` → Color | port | Resolves theme primary color.
- `getAccentColor(BuildContext)` → Color | port | Resolves theme accent color.
- `getThemeColor(BuildContext, String key)` → Color | port | Resolves named theme color.
- `generateSwatch(Color)` → MaterialColor | port | Generates color swatch from base color.
- `generateContainerElevation(Color, int level)` → Color | port | Computes container fill color by elevation level.
- `openInfoDialog(BuildContext, String message)` → Future<void> | port | Opens info dialog.
- `parseFileToBase64(File)` → String | port | Converts file to base64. |
- `parseFileToByteArray(File)` → Uint8List | port | Converts file to byte array. |

**Platform-conditional exports** (two implementations, separate native and web):
- `save_file` (native: file_saver; web: browser API) | port | Save file to disk.
- `pick_file` (native: file_picker; web: browser API) | port | Open file picker.

---

### Accessibility

**IMPORTANT (D10 / D11): Colorblind support is CONFIRMED IN SCOPE.** All seven symbols below are classified as "port" (implementation confirmed). However, they depend on `ColorblindMode` from layrz_models, which gates them on the **reopened D10 audit** of layrz_models' Material coupling. Once D10 audit confirms layrz_models' Material use is dead code (like google_fonts), colorblind support can proceed immediately. If Material coupling is load-bearing, colorblind support will be re-deferred pending decoupling work.

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| extension `ColorblindFilter` on ColorblindMode | extension | `lib/src/colorblindness/src/filter.dart` | **port — gated on D10** | Provides filter transformation. Depends on ColorblindMode from layrz_models. Formal scope confirmed in D11; implementation gated on D10 (layrz_models audit). |
| function `protanopiaFilter(Color)` → Color | function | `lib/src/colorblindness/src/propanopia.dart` | **port — gated on D10** | Red-blind filter. Formal scope confirmed in D11; gated on D10. |
| function `protanomalyFilter(Color)` → Color | function | `lib/src/colorblindness/src/propanomaly.dart` | **port — gated on D10** | Red-weak filter. Formal scope confirmed in D11; gated on D10. |
| function `deuteranopiaFilter(Color)` → Color | function | `lib/src/colorblindness/src/deuteranopia.dart` | **port — gated on D10** | Green-blind filter. Formal scope confirmed in D11; gated on D10. |
| function `deuteranomalyFilter(Color)` → Color | function | `lib/src/colorblindness/src/deuteranomaly.dart` | **port — gated on D10** | Green-weak filter. Formal scope confirmed in D11; gated on D10. |
| function `tritanopiaFilter(Color)` → Color | function | `lib/src/colorblindness/src/tritanopia.dart` | **port — gated on D10** | Blue-blind filter. Formal scope confirmed in D11; gated on D10. |
| function `tritanomalyFilter(Color)` → Color | function | `lib/src/colorblindness/src/tritanomaly.dart` | **port — gated on D10** | Blue-weak filter. Formal scope confirmed in D11; gated on D10. |

---

### Branded Assets

| Symbol | Kind | Source | Classification | Reason |
|--------|------|--------|-----------------|--------|
| `Layo` | widget | `lib/src/layo.dart` | port | SVG asset widget; branded asset, name unchanged (not Layrz-prefixed). Formal scope confirmed in D11. |
| `LayoEmotions` | enum (12 values: angry, dead, happy, idea, standard, love, question, sleep, warning, bolivariano, mrLayo, layo404) | `lib/src/layo.dart` | port | Emotion variants for Layo. Formal scope confirmed in D11. |

---

## The Structural Blocker: Re-exported layrz_models Types & D10 Audit

`layrz_theme`'s root barrel (`lib/layrz_theme.dart`) re-exports **five types from layrz_models** as public API:

1. **`LayrzAppLocalizations`** (i18n type)
2. **`Avatar`** (domain type)
3. **`AvatarInput`** (input configuration type)
4. **`AppThemedAsset`** (asset reference type)
5. **`ColorblindMode`** (accessibility enum)

Plus one type from `package:file_picker`:
6. **`FileType`** (file picker enum)

### Consequences

**Localisation is NOT a separate concern to invent.** `context.i18n` resolves to LayrzAppLocalizations, a layrz_models type. Any app migrating to layrz_ui loses these five re-exported types unless layrz_ui re-exports them or an alternative is provided. This creates a breaking change.

**What depends on LayrzAppLocalizations (i18n)**:
- `DateTimeExtension.format(String pattern, LayrzAppLocalizations)` — **blocked, gated on D10 audit**
- `HumanizeDuration.humanize(LayrzAppLocalizations)` — **blocked, gated on D10 audit**
- Every input widget's `translations: Map<String, String>` parameter — affected
- Extension `I18nExtension on BuildContext` returns LayrzAppLocalizations — **blocked, gated on D10 audit**
- All menu/dialog/tooltip/label strings in widgets — affected

**What depends on Avatar and AvatarInput**:
- `ThemedDynamicAvatarInput` widget accepts AvatarInput — **blocked, gated on D10 audit**
- `ThemedAvatar` stores Avatar domain objects — **blocked, gated on D10 audit**

**What depends on ColorblindMode**:
- Seven colorblindness filter functions and ColorblindFilter extension — **port (D11 confirmed), gated on D10 audit** (see Accessibility section)

### Decision D10 Impact

Decision D10 **reopens D2** and calls for an audit of layrz_models' Material coupling. The audit will determine whether layrz_models' 19 Material imports are:
1. **Dead code** (like google_fonts per D3) — layrz_ui can depend on layrz_models immediately; all 40+ symbols unblock
2. **Load-bearing** — requires decoupling effort upstream; colorblind (and potentially other features) remain deferred pending the decoupling

The highest-leverage decision by far. When the audit completes, it will finalize the scope for:
- Colorblind support (7 symbols, formally confirmed in D11)
- DateTimeExtension and HumanizeDuration (7 symbols)
- Avatar-bound inputs (ThemedDynamicAvatarInput, avatars)
- Localisation (i18n via context.i18n, input translations)
- Dynamic credential inputs (formal scope D11, implementation scheduled late)

See [decisions.md](decisions.md) for full context on D2 deferral, D3 (google_fonts audit), and D10 (reopening D2).

---

## Dependency-Blocked Summary

The packages that gate implementation, with audit verdicts from [flutter-347-audit.md](flutter-347-audit.md):

| Package | Version | Status | Reason | Blocked Symbols |
|---------|---------|--------|--------|-----------------|
| `package:flutter_map` | 8.3.0 | **architecturally Material-built** | 14 Material imports; core design conflict | Map subsystem (13 symbols) |
| `package:flex_color_picker` | 3.8.0 | **architecturally Material-built** | 23 Material + 2 Cupertino imports | ThemedColorPicker (must write from scratch) |
| `package:code_text_field` | 1.1.0 | **needs re-verification** | Audit incomplete; Material-built status unclear | ThemedCodeEditor (632 lines) |
| `package:flutter_highlight` | 0.7.0 | **needs re-verification** | Audit incomplete; Material-built status unclear | Code syntax highlighting |
| `package:layrz_models` | 3.24.7 | **deferred under D2** | Domain types (Avatar, ColorblindMode, LayrzAppLocalizations, etc.) | 40+ symbols incl. i18n, accessibility, dynamic inputs |
| `package:google_fonts` | (latest) | **import-coupled only, accepted** | Dead import in a single file; no Material/Cupertino imports; safe to use | kLayrzFont constant |
| `package:sync_scroll_controller` | 1.0.1 | **import-coupled only, needs version check** | Dart 2 SDK upper bound (`<3.0.0`) may conflict with Flutter >=3.29.0 | ThemedTable2 multi-header sync |
| `package:two_dimensional_scrollables` | 0.3.9 | **clean and directly usable** | No Material/Cupertino imports; pure widgets | ThemedTable2 (internal scrolling) |

**Architectural conflicts** (Material-built, cannot use):
- flutter_map (map subsystem must be rewritten or dropped)
- flex_color_picker (color picker must be written from scratch)
- code_text_field, flutter_highlight (need verification; may need re-implementation)

**Soft blockers** (decision-deferred, not architectural conflict):
- layrz_models (D2 — choice to defer or integrate)

---

## Known Errors in Existing Documentation

Corrections needed for wiki pages on next review:

1. **Three misnamed support types** (already flagged above):
   - Wiki calls it `SelectItem` → actual symbol: `ThemedSelectItem`
   - Wiki calls it `FieldError` → actual symbol: `ThemedFieldDisplayError`
   - Wiki calls it `InputLikeContainer` → actual symbol: `ThemedInputLikeContainer`

2. **ThemedButton semantic factories — CORRECTION TO EXISTING DOCUMENT**:
   - Earlier doc erroneously stated that `.legacyLoading()` must be added
   - Actual decision (D11): Six semantic factories only (`.save`, `.cancel`, `.info`, `.show`, `.edit`, `.delete`)
   - `.legacyLoading()` from layrz_theme is deliberately dropped in layrz_ui
   - The wiki's original list of six is correct

3. **Misspelled typedef in layrz_theme** (opportunity to fix):
   - layrz_theme: `ThemdNavigatorPopFunction` (missing "e")
   - Recommended layrz_ui: `LayrzNavigatorPopFunction` (clean break, correct spelling)

4. **Component Catalog is not exhaustive**:
   - Earlier inventory counted ~70 symbols; actual layrz_theme public surface is ~180
   - This document (migration-gap.md) supersedes the partial catalog

---

## Document Structure Summary

This document is organized into the following sections:

1. **Purpose and Method** — what this is and how it was produced
2. **Headline Numbers** — counts by domain and current layrz_ui state
3. **Already Covered** — 33 components with wiki pages, scope status
4. **MISSING** — detailed mapping of 183 layrz_theme symbols:
   - Layout and Navigation Chrome (21 symbols)
   - Feedback and Display (11 symbols)
   - Scaffolds, Tabs and Views (9 symbols)
   - Data Display: Calendar, Table, CodeSnippet (7 symbols)
   - Data Display: Table2 (11 symbols)
   - Responsive Grid System (5 symbols)
   - Input Support Types (21 symbols)
   - Button Factories (2 symbols)
   - Dynamic Configurable Subsystem (3 symbols)
   - Code Editor Subsystem (4 symbols)
   - Map Subsystem (13 symbols)
   - Theme Internals and Tokens (11 symbols)
   - Extensions and Utilities (15 functions/extensions + 8 helpers)
   - Accessibility (7 symbols)
   - Branded Assets (2 symbols)
5. **The Structural Blocker** — D2 (layrz_models integration) and re-exported types
6. **Dependency-Blocked Summary** — packages with architecture conflicts or version constraints
7. **Known Errors in Existing Documentation** — corrections for wiki
8. **This section** — structural outline

### Total Symbol Inventory

**Reclassifications from decisions D7–D11:**

- From "needs decision" to "drop" (6): ThemedLayoutStyle, ThemedMobileLayoutStyle, ThemedDualBar, ThemedSidebar, ThemedMiniBar, ThemedBottomBar
- From "port" to "drop" (2): Sizes, SizesExt
- From "blocked by D2" to "port — gated on D10" (7): ColorblindFilter + 6 filter functions
- From "blocked by D2" to "port — scheduled late" (1): ThemedDynamicCredentialsInput
- From "needs decision" to "port (merged)" (2): ThemedScaffoldView, ThemedScaffoldCell → LayrzScaffoldShell
- From "needs decision" to "port" (4): ThemedCalendar family (4 symbols)

**Updated Symbol Inventory:**

- **Ported or ready to port**: 74 symbols (62 + 7 + 1 + 6 - 2)
  - Includes 7 colorblind symbols reclassified from "blocked" to "port — gated on D10"
  - Includes 1 dynamic credentials symbol reclassified from "blocked" to "port — scheduled late"
  - Includes 6 symbols from "needs decision" to "port" (scaffolds and calendar)
  - Less 2 grid symbols (Sizes, SizesExt) reclassified to "drop"
- **Needs decision (scope unconfirmed)**: 51 symbols (63 - 6 - 2 - 4; layout and views)
- **Blocked by D2 / gated on D10 audit** (not "blocked"): 32 symbols (40 - 7 - 1)
  - DateTimeExtension, HumanizeDuration (6 symbols), I18nExtension, ThemedDynamicConfigurableBlock (2 symbols)
- **Blocked by architecture (Material-built dependencies)**: 17 symbols (unchanged)
- **Dropped (deprecated, placeholder, or out of scope)**: 10 symbols (2 + 6 + 2)
  - WorkInProgressView + VxStateUtilsMixin (2 original)
  - Layout presentations (6): ThemedLayoutStyle, ThemedMobileLayoutStyle, ThemedDualBar, ThemedSidebar, ThemedMiniBar, ThemedBottomBar
  - Responsive grid enum (2): Sizes, SizesExt

**Grand total: 184 symbols** across 15 domain sections.

---

## Next Steps

1. **Execute D10 audit on layrz_models** — determine if Material imports are dead code (like google_fonts) or load-bearing
2. **Finalize LayrzLayout single design** — decide which single layout design and which navigator item types
3. **Audit flutter_highlight and code_text_field** — determine if Material-built or rewritable
4. **Decide on map subsystem** — rewrite, accept Material dependency, or drop?
5. **Finalize parameter scopes** for the 28 remaining wiki pages (LayrzAlert, LayrzChip, LayrzSelect, etc.)
6. **Update wiki pages** for three support types (SelectItem, FieldError, InputLikeContainer) to match actual symbol names
7. **Add missing constants** to layrz_ui (kLayrzFont, kListViewPadding, system UI overlay styles)
8. **Reconcile LayrzTokenizer** with [design-tokens.md](design-tokens.md)
9. **Plan LayrzCalendar refactor** — address Material dependency in package:table_calendar

**Decisions finalized (D7–D11):**
- D7: Light mode only (dark mode dropped for now)
- D8: LayrzLayout ships exactly one layout design
- D9: Responsive grid drops Sizes enum in favor of plain integers
- D10: Reopen D2, audit layrz_models Material coupling
- D11: Component scope confirmations (confirm 40+ symbols across forms, feedback, scaffolds, data display, utilities, accessibility, branded assets)

All roadmap items, decisions, and audit findings are cross-referenced in [decisions.md](decisions.md), [roadmap.md](roadmap.md), [flutter-347-audit.md](flutter-347-audit.md), and [design-tokens.md](design-tokens.md).

# Flutter 3.47 Audit for layrz_ui

## Toolchain Versions

- **Flutter**: 3.47.0 stable (framework revision 4cf2416426, engine 59d54a2b28)
- **Dart**: 3.13.0, stable channel
- **SDK Installation**: /home/mochi/develop/flutter
- **SDK Constraint**: `>=3.8.0 <4.0.0` (Dart), `>=3.29.0` (Flutter)

## Material and Cupertino Decoupling Status

As of Flutter 3.47, the framework is in **Phase 1 of a three-phase deprecation and removal plan** for Material and Cupertino design libraries.

### Upstream Timeline and Phases

- **Phase 1 (December 2025)**: Shared core logic moved from Material and Cupertino down into the widgets library. Status: **underway in 3.47**.
- **Phase 2 (2026)**: Design libraries moved into standalone pub packages (`material_ui` and `cupertino_ui`) published by the verified publisher flutter.dev. Deprecation markers added to framework-bundled versions. Status: **material_ui 1.0.0 published as of brief date 2026-08-13**; `cupertino_ui` also available.
- **Phase 3 (late 2026)**: Material and Cupertino removed from core framework entirely.

### Material Deprecation Status in 3.47

The SDK's `material.dart` header contains **no `@Deprecated` markers** as of the brief date. Formal deprecation is scheduled for the **November 2026 stable release**. Removal from core is **late 2026**.

### Four In-Progress Work Areas

1. **System UI** — Redefining boundaries between design libraries and platform for text selection and page transitions.
2. **Code Organization** — Creating more design-agnostic raw widget abstractions in the style of `RawRadio`.
3. **Theme** — A shared base theme abstraction and re-evaluating the overall theming system.
4. **Infrastructure Migration** — Moving 200+ tests and CI workflows to the independent pub packages.

**Note**: The "style-neutral core widget catalog" mentioned in the release announcement is groundwork, **not a delivered API surface**. Do not rely on it for component development.

### Migration Tool

Dart provides `dart fix --apply --code=migrate_design_widgets` for Material apps transitioning to material_ui.

---

## Available Primitives in Flutter 3.47

The following design-agnostic primitives are available in the widgets library for layrz_ui to build upon:

| Primitive | Location | Purpose in layrz_ui |
|-----------|----------|-------------------|
| RawRadio | `/packages/flutter/lib/src/widgets/raw_radio.dart:44` | Generic radio base; layrz_ui builds LayrzRadio on this |
| RawTooltip | `/packages/flutter/lib/src/widgets/raw_tooltip.dart:237` | Tooltip mechanics without design coupling |
| RawMenuAnchor | `/packages/flutter/lib/src/widgets/raw_menu_anchor.dart:221` | Dropdown/menu positioning |
| RawMenuAnchorGroup | `/packages/flutter/lib/src/widgets/raw_menu_anchor.dart:908` | Menu grouping |
| RawMenuOverlayInfo | `/packages/flutter/lib/src/widgets/raw_menu_anchor.dart:45` | Menu overlay state |
| RawAutocomplete | `/packages/flutter/lib/src/widgets/autocomplete.dart:172` | Autocomplete base |
| RawScrollbar | `/packages/flutter/lib/src/widgets/scrollbar.dart:984` | Scrollbar without platform styling |
| RawMagnifier | `/packages/flutter/lib/src/widgets/magnifier.dart:450` | Magnifier for text selection |
| RawDialogRoute | `/packages/flutter/lib/src/widgets/routes.dart:2593` | Dialog routing without Material theming |
| showGeneralDialog | `/packages/flutter/lib/src/widgets/routes.dart:2760` | Generic dialog presentation |
| RawKeyboardListener | `/packages/flutter/lib/src/widgets/raw_keyboard_listener.dart:41` | Keyboard events without Material |
| RawGestureDetector | `/packages/flutter/lib/src/widgets/gesture_detector.dart:1318` | Low-level gesture detection |
| RawImage | `/packages/flutter/lib/src/widgets/basic.dart:6733` | Undecorated image rendering |
| RawView | `/packages/flutter/lib/src/widgets/view.dart:336` | Platform view wrapper |
| ToggleableStateMixin | `/packages/flutter/lib/src/widgets/toggleable.dart:37` | Provides `positionController`, `reactionController`, `positionHoverFade`, `reactionFocusFade`, and abstract `buildToggleable()` / `buildToggleableWithChild()` methods. Essential for radio, checkbox, and switch. |
| ToggleablePainter (abstract) | `/packages/flutter/lib/src/widgets/toggleable.dart:409` | Exposes `position`, `reaction`, `reactionFocusFade`, `reactionHoverFade`, `activeColor`, `inactiveColor`, and `paintRadialReaction()`. Use for custom toggle painting. |
| EditableText | `/packages/flutter/lib/src/widgets/editable_text.dart` | Foundation for text input without Material styling |
| TextSelectionControls (abstract) | `/packages/flutter/lib/src/widgets/text_selection.dart:97` | Customizable text selection handles |
| TextSelectionToolbarLayoutDelegate | `/packages/flutter/lib/src/widgets/text_selection_toolbar_layout_delegate.dart:26` | Layout for text selection toolbar |
| SystemContextMenu | `/packages/flutter/lib/src/widgets/system_context_menu.dart:57` | Platform context menu integration |
| Overlay | `/packages/flutter/lib/src/widgets/overlay.dart:479` | Overlay stack for modals, menus, tooltips |
| OverlayEntry | `/packages/flutter/lib/src/widgets/overlay.dart:109` | Single overlay entry |
| OverlayPortal | `/packages/flutter/lib/src/widgets/overlay.dart:1869` | Portal-based overlay |
| OverlayPortalController | `/packages/flutter/lib/src/widgets/overlay.dart:1685` | Portal controller |
| ModalBarrier | `/packages/flutter/lib/src/widgets/modal_barrier.dart:128` | Scrim/barrier for modals |
| FocusNode | `/packages/flutter/lib/src/widgets/focus_manager.dart:456` | Focus management |
| FocusScope | `/packages/flutter/lib/src/widgets/focus_scope.dart` | Focus scope container |
| FocusTraversalPolicy (abstract) | `/packages/flutter/lib/src/widgets/focus_traversal.dart:185` | Custom focus traversal |
| Actions | `/packages/flutter/lib/src/widgets/actions.dart:729` | Intent system without Material |
| Shortcuts | `/packages/flutter/lib/src/widgets/shortcuts.dart:1004` | Key binding without Material |
| FocusableActionDetector | `/packages/flutter/lib/src/widgets/actions.dart:1171` | Combines focus, actions, and shortcuts |
| PageRoute (abstract) | `/packages/flutter/lib/src/widgets/routes.dart` | Base for custom page transitions |
| PageRouteBuilder | `/packages/flutter/lib/src/widgets/pages.dart:89` | Build custom page routes |
| PageTransitionsBuilder (abstract) | `/packages/flutter/lib/src/widgets/page_transitions_builder.dart:18` | Custom page transition mechanics |
| RouteObserver | `/packages/flutter/lib/src/widgets/routes.dart:2433` | Route lifecycle observation |
| Icon, IconTheme, IconThemeData, IconData, ImageIcon | Exported from `widgets.dart` | Icon rendering and theming |
| InheritedTheme (abstract) | `/packages/flutter/lib/src/widgets/inherited_theme.dart:36` | Base for custom theme inheritance; subclassed by Material's Theme and Cupertino's CupertinoTheme; provides the `wrap()` mechanism |
| WidgetState | `/packages/flutter/lib/src/widgets/widget_state.dart:142` | State class for custom stateful widgets |
| SelectableRegion | `/packages/flutter/lib/src/widgets/selection_container.dart:37` | Enables text selection and copy within a child tree; wraps RichText children to make them selectable by drag or keyboard (Ctrl+A, Ctrl+C) |
| emptyTextSelectionControls | `/packages/flutter/lib/src/widgets/text_selection.dart` | No-op implementation of `TextSelectionControls`; satisfies `SelectableRegion`'s required `selectionControls` parameter when drag handles and context menus are not needed. Used by LayrzText. |

---

## Confirmed Absent Primitives (Must Hand-Roll)

The following do not exist in the SDK and layrz_ui must implement custom equivalents:

| Primitive | Reason | layrz_ui Strategy |
|-----------|--------|-------------------|
| RawCheckbox | No checkbox primitive exists | Implement LayrzCheckbox on ToggleableStateMixin |
| RawSwitch | No switch primitive exists | Implement LayrzSwitch on ToggleableStateMixin |
| RawSlider | No slider primitive exists | Implement LayrzSlider with custom painting |
| RawChip | No chip primitive exists | Implement LayrzChip as a custom widget |
| RawButton / ButtonStyleButton | No generic button primitive exists | Implement LayrzButton with GestureDetector + custom state |
| ThemeExtension\<T\> | Material-only feature | Use InheritedWidget or InheritedTheme subclass instead |
| FocusRing / focus-highlight primitive | No focus ring primitive exists | Implement custom focus indicators using FocusNode and custom painting |

---

## Design-Agnostic Intent — SDK Documentation Evidence

The following quotes from Flutter SDK documentation confirm the design-agnostic intent and justify using raw primitives for custom design systems:

### From page_transitions_builder.dart:18
> "...a custom transition works in any design system"

This acknowledges that PageTransitionsBuilder is intended for any design system, not just Material.

### From widget_state.dart:142
> "...states are [not limited to the Material design system or library]"

This explicitly states that WidgetState is suitable for building custom design systems.

### From app.dart lines 1052, 1060, 1068
> "...button for their design systems" (repeated in context of customization)

Acknowledges that apps may build custom buttons appropriate to their design system.

---

## Widget Previews API (Stable in 3.47)

The `package:flutter/widget_previews.dart` library provides a preview system for viewing widgets without launching a device. **CRITICAL DEFECT**: The CLAUDE.md file documents rules using non-existent `@widgetPreview` annotation and `WidgetPreview` class.

### API Surface (What Exists)

Located in `/home/mochi/develop/flutter/packages/flutter/lib/src/widget_previews/`:

- **@Preview** — Base annotation class (line 66) with fields:
  - `group` — preview grouping
  - `name` — preview name
  - `size` — Size
  - `textScaleFactor` — text scaling
  - `wrapper` — WidgetWrapper function
  - `theme` — PreviewTheme function
  - `brightness` — Brightness
  - `localizations` — PreviewLocalizations

- **MultiPreview** — Abstract class (line 244) for multiple preview variants

- **PreviewBuilder** — Final class (line 264) with:
  - `addWrapper(WidgetWrapper)` — add a wrapper
  - `build(BuildContext)` — build the preview

- **PreviewThemeData** — Abstract class (line 397) with `apply(BuildContext, Widget)`

- **MultiPreviewThemeData** — Final class (line 407) that layers multiple themes in sequence

- **PreviewLocalizationsData** — Class (line 329) with:
  - `locale`, `supportedLocales`, `localizationsDelegates`
  - `localeListResolutionCallback`, `localeResolutionCallback`

- **Typedefs**:
  - `PreviewTheme = PreviewThemeData Function()`
  - `WidgetWrapper = Widget Function(Widget)`
  - `PreviewLocalizations`

### Known Defect

**CRITICAL**: There is **NO** `@widgetPreview` annotation and **NO** `WidgetPreview` class anywhere in the Flutter SDK or pub cache. CLAUDE.md rule #3 documents this non-existent API with example code that will fail to compile:

```dart
import 'package:flutter/widget_preview.dart';  // ← Correct: widget_previews (plural)

@widgetPreview  // ← DOES NOT EXIST
Widget previewMyWidget() => LayrzApp(...);
```

**Correct import**: `package:flutter/widget_previews.dart` (plural)

**Correct annotation**: Use `@Preview(...)` instead, with explicit parameters like:

```dart
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Light Theme', brightness: Brightness.light)
Widget previewMyWidget() => LayrzApp(...);
```

**Action Required**: Update CLAUDE.md rule #3 to document the actual `@Preview` API and correct the import statement before implementing preview support in layrz_ui.

---

## Re-Audit Triggers

The following dates require re-checking of this audit:

1. **November 2026 stable release**: Material.dart will receive `@Deprecated` markers. Check for any breaking changes in widgets library as Phase 2 begins in earnest. Re-verify that all raw primitives still have stable APIs.

2. **Late 2026 (removal phase)**: Material and Cupertino will be removed from core. At this point:
   - Verify that layrz_ui's lib/ still has zero Material/Cupertino imports
   - Check whether any transitive dependencies have been forced to adopt material_ui or cupertino_ui
   - Update SDK constraints to the new minimum Flutter version if necessary
   - Review whether the widget previews API has stabilized or changed

3. **Ongoing (quarterly)**: Monitor the four work areas (System UI, Code Organization, Theme, Infrastructure Migration) for new raw primitives or API stabilizations that could improve layrz_ui's foundation.

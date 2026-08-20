# Dependency Policy and Material Coupling Audit

## The Material Coupling Invariant

```
grep -r "package:flutter/material\|package:flutter/cupertino" lib/
```

This command **must** always return empty. layrz_ui is Material-free and Cupertino-free.

## Critical Distinction: Import-Coupled vs. Architecturally Material-Built

**IMPORTANT**: A package whose own source imports `material.dart` puts Material in the consuming app's compile graph **even though layrz_ui's lib/ stays clean** (because layrz_ui does not directly import it).

This distinction is crucial:

- **Architecturally Material-Built** — The package is designed to provide Material components, requires Material's design decisions at runtime, and offers Material components as its primary API. Replacing these requires a different package or re-implementing the abstraction. Example: `flex_color_picker`, which has Material UI widgets as its public API.

- **Import-Coupled Only** — The package's source imports `material.dart` or uses Material symbols, but layrz_ui does not call the Material-dependent code paths. Example: `google_fonts` TextTheme methods, which are dead code when layrz_ui uses only the `GoogleFonts.getFont()` TextStyle API.

Remedies differ:
- **Architecturally Material-Built** → Must be replaced or declared incompatible.
- **Import-Coupled Only** → Can be accepted if layrz_ui avoids the Material code paths, and the grep invariant passes.

---

## layrz_ui Current Dependency Graph

### Direct Dependencies
- `flutter` (core, including widgets.dart and dart:ui)

### Transitive via `flutter`
- `characters`, `collection`, `material_color_utilities`, `meta`, `vector_math`, `sky_engine`

**Status**: Verified clean. No Material, Cupertino, material_ui, or cupertino_ui packages in the graph.

---

## Audited Packages from layrz_theme

This section documents every package that layrz_theme depends on, its verdict, and the consequence for layrz_ui.

### Genuinely Material-Built (Architectural Coupling — Replacement Required)

#### flex_color_picker 3.8.0

**Verdict**: ❌ **Must be replaced** — Architecturally Material

**Evidence**: 23 files import `material.dart`, 2 import `cupertino.dart`. The package is designed to provide Material Design color pickers.

- `lib/src/widgets/tonal_palette_colors.dart` — Material widget
- `lib/src/universal_widgets/*.dart` — Material-coupled color pickers

**Consequence**: Any layrz_ui color picker must be implemented from scratch, without depending on flex_color_picker.

---

#### flutter_map 8.3.0

**Verdict**: ❌ **Must be replaced** — Architecturally Material

**Evidence**: 14 files import Material. The package's gesture handling and UI overlays are Material-coupled.

- `lib/src/map/inherited_model.dart` — Material inheritance patterns
- `lib/src/map/controller/map_controller.dart` — Material-dependent lifecycle
- `lib/src/gestures/positioned_tap_detector_2.dart` — Material gesture detection

**Consequence**: Any layrz_ui map component must use a different mapping library or implement mapping from lower-level gesture and rendering primitives.

---

### Import-Coupled Only (Acceptable if Unused)

#### google_fonts 8.2.1

**Verdict**: ✅ **Accepted** — Import-coupled only; layrz_ui avoids Material code paths

**Detailed Analysis**:

google_fonts resolves to version 8.2.1 in layrz_theme's pubspec.lock (latest as of brief date: 8.2.1). It declares no dependency on `material_ui`. The package imports `material.dart` in 28 files.

**Critical Finding** — Dead Imports:

- `lib/src/google_fonts_base.dart` (346 lines, the core font-loading engine):
  - Line 7: `import 'package:flutter/material.dart';`
  - **Grep for Material symbols**: `grep -n 'TextTheme\|ThemeData\|Theme\.of\|Typography\|ColorScheme\|MaterialApp' google_fonts_base.dart` returns **nothing**
  - What it actually uses: `kIsWeb` and `debugPrint` from `foundation`, `rootBundle`/`AssetManifest`/`FontLoader` from `services`, `sha256` from `crypto`, `http`
  - **Verdict**: Dead import

- `lib/src/google_fonts_all_parts.dart` (15,502 lines):
  - Imports Material with no Material symbols used anywhere
  - **Verdict**: Dead import

- `lib/src/google_fonts_parts/part_*.dart` (1,893 files total):
  - Material used ONLY inside `*TextTheme()` method families
  - Example pattern: `textTheme ??= ThemeData.light().textTheme; return TextTheme(...);`
  - There are 1,893 `TextStyle`-returning static methods (require **zero** Material)
  - There are 1,893 `TextTheme`-returning static methods (require Material)
  - **layrz_theme call pattern**: `GoogleFonts.getFont(name)`, `GoogleFonts.ubuntu()`, `GoogleFonts.jetBrainsMono()`, `GoogleFonts.pendingFonts()`
  - **Grep in layrz_theme**: `grep -rn 'GoogleFonts.*TextTheme' lib/` returns **empty**
  - **Verdict**: layrz_theme uses **only** TextStyle-returning methods; TextTheme methods are unreachable

**Changelog Note**: google_fonts changelog from 8.0.0 through 8.2.1 contains no Material decoupling work.

**Consequence**: layrz_ui **can safely depend on google_fonts ^8.2.1** for runtime fonts. The Material imports are dead code for our use case. The grep invariant in layrz_ui's lib/ will pass (because we don't import google_fonts with Material). However, Material will exist in the transitive compile graph via google_fonts' imports.

**Rationale for acceptance**: Material remains in the Flutter SDK until late 2026, so its presence in the compile graph costs nothing today. The font-loading engine is robust and widely used, and re-implementing it would be a 300+ line undertaking with no Material coupling benefit. When Material is removed from core, google_fonts must migrate. **See review trigger below**.

---

### Clean (No Material or Cupertino Coupling)

#### layrz_icons 1.1.1 (retained for future LayrzIconInput)

**Verdict**: ✅ **Clean**

**Evidence**: Imports `package:flutter/widgets.dart` only. No Material or Cupertino anywhere.

- `LayrzIcon` class; icons are static getters on `LayrzIconsClasses`
- 14,572 public icon getters across 8 font families (materialDesignIcons, fontAwesomeBrands, fontAwesomeSolid, fontAwesomeRegular, solarBold, solarBroken, solarLinear, solarOutline)
- `class_enum.dart` — 14,578 lines (icon mapping)
- `mapping.dart` — 14,585 lines (enum generation)

**Consequence**: Safe to depend on. Aligns with layrz_ui's design-system-agnostic foundation.

**Deprecation Note**: As of M2, layrz_ui's icon rendering has migrated to `flutter_material_design_icons` (see below). This dependency is retained exclusively for the planned `LayrzIconInput` widget, which browses the full Solar icon catalogue. The dependency is no longer the system-wide icon source.

**Version Note**: `layrz_ui` pinned `layrz_icons` to `^1.1.1` (not `^2.0.0`) to co-resolve with `layrz_sdk ^4.4.3`, which requires `layrz_icons: ^1.1.1`. This is intentional and verified:
- All 20 `LayrzIcons.*` symbols used across `lib/`, `test/`, and `example/lib/` (before the M2 migration) exist in both 1.1.1 and 2.0.0 with identical names and signatures.
- `LayrzIcon` and `LayrzFamily` class definitions are byte-for-byte identical between the two versions.
- Both versions import ONLY `package:flutter/widgets.dart` — no Material or Cupertino coupling.
- 1.1.1 declares `sdk: >=3.12.0 <4.0.0` and `flutter: >=3.44.0`, which are looser constraints than layrz_ui's own `sdk: >=3.13.0 <4.0.0` and `flutter: >=3.47.0`, so it imposes no additional constraint.

**Exit condition**: Raise back to `^2.0.0` once `layrz_sdk` moves to `layrz_icons: ^2.0.0`.

---

#### flutter_material_design_icons 3.1.0+7447

**Verdict**: ✅ **Clean** — Widgets-only; system-wide icon source

**Evidence**: Pure icon-font package importing only `package:flutter/widgets.dart`. No Material or Cupertino anywhere. Ships `IconData` constants and font assets only.

- `IconData` constants for Material Design Icons (MDI) icon set (7,447 icons)
- Font asset files only; no Material widgets or Material-coupled logic

**Consequence**: Safe to depend on. This is the new system-wide icon source for layrz_ui, replacing the Solar set as the primary icon vocabulary. All components that previously used `LayrzIcons.solarOutlineXxx` now use `MdiIcons.xxx` from this package. This does not violate the Material-free invariant because the package is purely a font and constant library — it contains no Material design decisions, no Material widgets, and no Material runtime coupling.

**Rationale**: Material Design Icons is a neutral, comprehensive icon vocabulary maintained by Google. Unlike Material components (which impose design patterns), the icon set is a pure asset that aligns with layrz_ui's design-system-agnostic foundation. Icon selection is independent of the Flutter design system in use.

**Verdict**: ✅ **Accepted** — Widgets-only imports; used for `Avatar` model

**Evidence**: The package imports ONLY `package:flutter/widgets.dart` and pure-Dart packages (dio, freezed_annotation, json_annotation, layrz_i18n, layrz_logging, web_socket_channel).

**Transitive Dependencies Added** (18 new packages):
- **Direct from layrz_sdk**: dio, freezed_annotation, json_annotation, layrz_i18n, layrz_logging, web_socket_channel
- **From flutter_svg direct dependency** (2.3.0): vector_graphics, vector_graphics_codec, vector_graphics_compiler, path_parsing, petitparser, xml, and platform integrations (jni, objective_c, etc.)
- **Transitive from the above**: mime, web_socket, path_provider, ffi, and platform-specific packages

Full list of new packages:
```
dio 5.11.0, dio_web_adapter 2.2.1, flutter_svg 2.3.0, freezed_annotation 3.1.0, json_annotation 4.12.0,
layrz_i18n 1.0.1, layrz_logging 1.5.1, mime 2.0.0, path_parsing 1.1.0, petitparser 7.0.2,
vector_graphics 1.2.3, vector_graphics_codec 1.1.13, vector_graphics_compiler 1.3.0,
web_socket 1.0.1, web_socket_channel 3.0.3, xml 7.0.1
```
(plus platform-specific transitive deps: jni, jni_flutter, jni_util, objective_c, path_provider and its variants, plugin_platform_interface)

**Consequence**: layrz_ui now depends on layrz_sdk for data models (Avatar, etc.) and gains Material-free HTTP (dio), JSON support (freezed_annotation + json_annotation), i18n integration (layrz_i18n), logging (layrz_logging), and WebSocket support (web_socket_channel). The grep invariant remains clean; all new dependencies are widgets-only or pure-Dart.

---

#### flutter_svg 2.3.0

**Verdict**: ✅ **Clean**

**Evidence**: SVG rendering library. No Material or Cupertino imports.

**Consequence**: Safe to depend on. Added to support SVG-based branches of the forthcoming `LayrzImage` component.

---

#### layrz_state 1.0.2

**Verdict**: ✅ **Clean**

**Evidence**: Pure Dart state management package. No Flutter imports at all.

**Consequence**: Safe to depend on.

---

#### file_picker 10.3.10

**Verdict**: ✅ **Clean**

**Evidence**: Platform-agnostic file picking. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### flutter_svg 2.2.4

**Verdict**: ✅ **Clean**

**Evidence**: SVG rendering. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### url_launcher 6.3.2

**Verdict**: ✅ **Clean**

**Evidence**: Platform integration. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### permission_handler 12.0.1

**Verdict**: ✅ **Clean**

**Evidence**: Platform-agnostic permissions. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### pointer_interceptor 0.10.1+2

**Verdict**: ✅ **Clean**

**Evidence**: Low-level pointer mechanics. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### flutter_timezone 5.1.0

**Verdict**: ✅ **Clean**

**Evidence**: Timezone data. No Material or Cupertino imports.

**Consequence**: Safe to depend on.

---

#### Pure Dart (Always Safe)

- `intl` — i18n and localization
- `collection` — data structures
- `material_color_utilities` — color math (no design coupling)
- `emojis` — emoji data

**Verdict**: ✅ **Clean** — all safe to use.

---

## Pending Re-Verification

The following packages have low Material import counts and require detailed forensic analysis before being confirmed clean. They are **not yet approved** for layrz_ui but are candidates pending verification.

### flutter_highlight 0.7.0

- **Import count**: 1 (lib/flutter_highlight.dart)
- **Required check**: Is the Material import dead (unused) like google_fonts, or is it load-bearing?
- **How to verify**: `grep -A5 -B5 "import.*material" lib/flutter_highlight.dart`, then search the file for Material symbols (ThemeData, Theme.of, TextTheme, etc.)
- **Consequence if clean**: Can be used for syntax highlighting
- **Consequence if coupled**: Must find alternative or defer

### code_text_field 1.1.0

- **Import count**: 3 files
  - `lib/src/code_field/code_field.dart`
  - `code_controller.dart`
  - `lib/src/code_modifiers/code_modifier.dart`
- **Required check**: Are these Material-dependent (theme, styling) or just import-coupled?
- **How to verify**: For each file, check whether the code calls Material symbols or just imports without using them
- **Consequence if clean**: Can be used for code editing
- **Consequence if coupled**: Must re-implement or find alternative

### layrz_models 3.24.7

- **Import count**: 19 files across the package
- **Required check**: Are the imports in the root barrel (layrz_models.dart) or in specific converters/sensors that layrz_ui might not use?
- **How to verify**: Check which specific APIs layrz_ui would call from layrz_models. Verify whether Material is only used in converters for dynamic credentials or other Material-specific features
- **Status**: This is currently **OUT OF SCOPE** for Milestone 1 (foundation only), so verification can be deferred
- **Consequence if clean**: Can support model-bound components
- **Consequence if coupled**: Model-bound components deferred until layrz_models decouples upstream

---

## Approval Criteria for New Dependencies

Before adding any new package to layrz_ui, verify the following:

1. **Material/Cupertino Imports**: Run `grep -r "import.*material\|import.*cupertino" <package>/lib/`. Result must be empty **or** all imports must be dead code verified via manual spot-check.

2. **layrz_ui's lib/ Remains Clean**: After adding the new dependency, run `grep -r "package:flutter/material\|package:flutter/cupertino" lib/`. Result must remain empty.

3. **Transitive Graph**: Check the new package's pubspec.lock or package page. Does it depend on material_ui, cupertino_ui, or anything Material-built? If yes, it is architecturally coupled and must be rejected.

4. **Functional Alignment**: Is the package solving a problem that requires its implementation? If it's for color picking, file uploading, or gestures, verify that:
   - The package does not lock layrz_ui into a design system
   - layrz_ui can wrap or customize the component to match its design tokens
   - There is an exit path if the package is deprecated or incompatible

5. **Test Coverage**: Any new dependency that affects visual rendering or user interaction must have test coverage in layrz_ui showing that it integrates correctly with the theme system.

---

## RECORDED RISK: google_fonts Material Migration (Review Trigger)

**Date Identified**: 2026-08-13  
**Consequence**: High — affects all text rendering in layrz_ui  
**Status**: Mitigated today, monitored for late 2026

**Context**: google_fonts depends on Material only via dead imports. Material will be removed from the Flutter SDK in late 2026. When that happens, google_fonts must migrate. If it migrates onto `material_ui` (pub.dev/packages/material_ui), then layrz_ui inherits a transitive material_ui dependency, which **will violate the grep invariant**.

**Action**: Add a review trigger to the 2026-08-13 calendar:
- Monitor google_fonts changelog for Material deprecation work
- If google_fonts adopts material_ui, create a new decision (D5) to either:
  - Re-implement font loading without google_fonts
  - Accept material_ui as a transitive dependency and re-evaluate the design-system-agnostic goal
  - Depend on material_ui directly and provide Material-aware text component wrappers

**Monitoring**: Check github.com/google/fonts/tree/main/packages/google_fonts quarterly for migration announcements.

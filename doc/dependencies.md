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

#### layrz_icons 1.1.0

**Verdict**: ✅ **Clean**

**Evidence**: Imports `package:flutter/widgets.dart` only. No Material or Cupertino anywhere.

- `LayrzIcon` class; icons are static getters on `LayrzIconsClasses`
- 14,572 public icon getters across 8 font families (materialDesignIcons, fontAwesomeBrands, fontAwesomeSolid, fontAwesomeRegular, solarBold, solarBroken, solarLinear, solarOutline)
- `class_enum.dart` — 14,578 lines (icon mapping)
- `mapping.dart` — 14,585 lines (enum generation)

**Consequence**: Safe to depend on. Aligns with layrz_ui's design-system-agnostic foundation.

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

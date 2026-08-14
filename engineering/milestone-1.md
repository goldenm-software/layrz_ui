# Milestone 1: Foundation

## Goal

Establish the token system, enforce code standards, fix theme-boundary safety, and provide the primitive infrastructure upon which all later components depend.

This is a **foundation-only** milestone with **zero components**. Success means the package ships a complete, tested token layer, enforced CI guards, and the critical InheritedTheme migration that unblocks all downstream work.

## Status

| # | Item | Status |
|---|---|---|
| 1 | Migrate LayrzTheme to extend InheritedTheme with wrap() | Done |
| 2 | Correct CLAUDE.md rule #3 to the real `@Preview` API | Done |
| 3 | Semantic color tokens | Done |
| 4 | Typography, spacing, radius, shadow, border, motion tokens | Done |
| 5 | LayrzThemeExtension mechanism | Todo |
| 6 | WidgetState/WidgetStatesController state-resolution layer | Done |
| 7 | lib/fonts/ with LayrzFontHandler | Done |
| 8 | LayrzPreviewTheme and Preview support | Todo |
| 9 | CI pipeline at .github/workflows | Todo |
| 10 | Enable `public_member_api_docs` | Todo |
| 11 | Close the test gap | Done |
| 12 | Update CHANGELOG.md and commit pubspec version bumps | Todo |

**Note**: This table tracks the 12 work items in `engineering/milestone-1.md`. GitHub Project 9 tracks 17 M1 Foundation modules at finer granularity. Both describe the same milestone work at different decomposition levels. When any item completes, both the Status table above and the corresponding GitHub Project item must be updated together.

## Definition of Done

- All 12 work items below complete
- `flutter analyze` reports zero issues
- `flutter test` reports 100% pass (test gap closed)
- Invariant verified: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- All new public code documented per CLAUDE.md rule #1
- CHANGELOG.md contains meaningful M1 summary
- pubspec version bumps committed as separate `chore` commit

---

## Work Items

### Phase 1: Blocking Fixes

These two items must be done first; all later work depends on them.

#### 1. Migrate LayrzTheme to extend InheritedTheme with wrap()

**What changes**:
- `lib/theme/src/theme.dart`: `LayrzTheme` changes from `extends InheritedWidget` to `extends InheritedTheme`
- Implement `InheritedTheme.wrap(BuildContext, Widget)` to return `LayrzTheme(...)` wrapping the given widget
- Keep `of()` and `maybeOf()` working identically

**Files affected**:
- `lib/theme/src/theme.dart`

**Why it matters**:
When a widget crosses an Overlay boundary (dialogs, tooltips, menus, dropdowns) or a route boundary, the InheritedWidget chain is interrupted. Without `wrap()`, the theme context is lost downstream of the boundary. This breaks every dialog, tooltip, and menu built later in M2–M5.

`InheritedTheme` is a subclass of `InheritedWidget` that solves this by being installed at the route level, not inline. The `wrap()` method tells the route system how to restore the theme when crossing boundaries.

**Concrete failure mode without wrap()**:
```
LayrzDialog(
  // Inside this dialog, LayrzTheme.of(context) returns null → crash.
  child: LayrzButton(...),
)
```

**Verification**:
- Write a test: build a `LayrzDialog` (once it exists) containing a widget that calls `LayrzTheme.of(context)`. Without wrap(), this crashes. With wrap(), it succeeds.
- For M1, write a simpler test: wrap a `Builder` in an `OverlayEntry`, call `LayrzTheme.of()` inside the builder. Should not crash.

---

#### 2. Correct CLAUDE.md rule #3 to the real `@Preview` API

**What changes**:
- `CLAUDE.md`, rule #3: Replace all references to `@widgetPreview` and `WidgetPreview` with the real API.

**Correction**:
```dart
// OLD (incorrect — these don't exist)
import 'package:flutter/widget_preview.dart';
@widgetPreview
Widget previewMyWidget() => LayrzApp(...);

// CORRECT
import 'package:flutter/widget_previews.dart';
@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewMyWidget() => LayrzApp(...);
```

The real API in Flutter 3.47:
- Import: `package:flutter/widget_previews.dart` (plural)
- Annotation: `@Preview(...)` with named fields: `group`, `name`, `size`, `textScaleFactor`, `wrapper`, `theme`, `brightness`, `localizations`
- Theme type: `PreviewThemeData` (abstract base class) — layrz_ui provides `LayrzPreviewTheme extends PreviewThemeData` (must extend, not implement, because `PreviewThemeData` is declared `abstract base class` in the SDK)

**Files affected**:
- `CLAUDE.md`

**Verification**:
- The corrected rule can be followed without errors when writing preview code

---

### Phase 2: Enforcement (CI + Linting)

These two items must land immediately after blocking fixes so all later contributions are guarded.

#### 9. CI pipeline at .github/workflows

**What changes**:
- Create `.github/workflows/` directory
- Add workflow file(s) implementing four checks:

1. **flutter analyze** — runs `flutter analyze` on lib/. Must exit 0.
2. **flutter test** — runs `flutter test` on all test files. Must exit 0.
3. **format check** — runs `dart format --set-exit-if-changed lib/` and fails if any files would be reformatted.
4. **Material/Cupertino guard** — runs `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` and fails if the output is non-empty.

*Optional bonus*: Add a check that lib/ never calls `GoogleFonts.*TextTheme()` (to prevent Material coupling through transitive google_fonts risk).

**Files affected**:
- `.github/workflows/` (new directory)
- `.github/workflows/analyze-test-format.yaml` (or similar name)

**Why it matters**:
Without CI, code quality degrades immediately. The Material/Cupertino guard and the format check prevent silent invariant violations.

**Verification**:
- Commit a Material import to lib/, push, watch the CI fail
- Run locally: `dart format --set-exit-if-changed lib/` should exit 0 and not reformat anything

---

#### 10. Enable `public_member_api_docs` in analysis_options.yaml

**What changes**:
- `analysis_options.yaml`: add or uncomment `public_member_api_docs: true` rule

**Files affected**:
- `analysis_options.yaml`

**Why it matters**:
CLAUDE.md rule #1 mandates documenting every public argument. Without the linter enabled, violations go unseen until code review.

**Verification**:
- Add a public class with an undocumented field to lib/
- Run `flutter analyze` — expect an error about missing doc comment
- Remove the field, run again — zero errors

---

### Phase 3: Token System (The Heart of M1)

#### 3. Semantic color tokens

**What changes**:
- Create `lib/tokens/` module (new)
- `lib/tokens/tokens.dart` barrel
- `lib/tokens/src/colors.dart` — define semantic color tokens (primary, accent, surface, background, foreground at multiple levels, danger, success, warning, info, overlay, etc.)

**Token API** (reference design; see `design-tokens.md` for full detail):
```dart
class LayrzColorTokens {
  final Color primary;
  final Color accent;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color background;
  final Color fg1;  // foreground level 1 (highest contrast)
  final Color fg2;
  final Color fg3;
  final Color fg4;  // foreground level 4 (lowest contrast)
  final Color danger;
  final Color success;
  final Color warning;
  final Color info;
  final Color overlay;
  final Color divider;
  // ... more
}
```

**Files affected**:
- `lib/tokens/` (new module)
- `lib/tokens/tokens.dart` (barrel, new)
- `lib/tokens/src/colors.dart` (new)
- `lib/theme/src/theme_data.dart` — update to hold a `LayrzColorTokens` field

**Why it matters**:
Colors are the most fundamental design decision. All components will read colors from tokens, not hardcodes. This centralizes theming and makes light/dark switching trivial.

**Verification**:
- `LayrzThemeData.light()` has all color tokens set and initialized to sensible defaults
- A test: read `LayrzTheme.of(context).colors.primary` in light theme and verify it returns the expected primary color

---

#### 4. Typography, spacing, radius, shadow, border, and motion tokens

**What changes**:
- `lib/tokens/src/typography.dart` — text styles, font sizes, line heights, weights
- `lib/tokens/src/spacing.dart` — margin, padding grid (4, 6, 8, 10, 12, 14, 16, 20, 24, etc.)
- `lib/tokens/src/radius.dart` — border radii (8, 10, 12, 14, 16, 20, etc.)
- `lib/tokens/src/shadow.dart` — elevation levels and corresponding shadow definitions
- `lib/tokens/src/border.dart` — stroke widths, border side definitions
- `lib/tokens/src/motion.dart` — durations (hover, press, page transition, etc.) and easing curves

**Token classes**:
- `LayrzTypographyTokens`
- `LayrzSpacingTokens`
- `LayrzRadiusTokens`
- `LayrzShadowTokens`
- `LayrzBorderTokens`
- `LayrzMotionTokens`

These are aggregated into a top-level `LayrzTokens` class.

**Files affected**:
- `lib/tokens/src/typography.dart` (new)
- `lib/tokens/src/spacing.dart` (new)
- `lib/tokens/src/radius.dart` (new)
- `lib/tokens/src/shadow.dart` (new)
- `lib/tokens/src/border.dart` (new)
- `lib/tokens/src/motion.dart` (new)
- `lib/tokens/src/tokens.dart` — aggregate all into `LayrzTokens`
- `lib/tokens/tokens.dart` (barrel, update)
- `lib/theme/src/theme_data.dart` — add `tokens` field

**Why it matters**:
These tokens define the visual language: how tight or loose the spacing is, how rounded or sharp the corners are, how fast animations feel. They are all interdependent (spacing scales with breakpoints, radii with component sizes). Treating them as a unified system prevents inconsistency.

**Verification**:
- `LayrzTokens.spacing.sp8` is a `double` representing 8.0 logical pixels
- `LayrzTokens.radius.r12` is a `double`
- `LayrzTokens.motion.dHover` is a `Duration`
- Light theme tokens are correctly initialized with sensible defaults

---

#### 5. LayrzThemeExtension mechanism (custom theme values for components)

**What changes**:
- Create `lib/theme/src/theme_extension.dart` — define `LayrzThemeExtension<T>` interface
- Implement a registry mechanism so components can store custom data on `LayrzThemeData` without modifying core theme fields

**Design rationale**:
`ThemeExtension<T>` is Material-only (part of `package:flutter/material.dart`). For the design system to be Material-free, we need our own extension mechanism. Later components (especially M2+ inputs and M4 pickers) will need to store per-component token overrides or state without polluting `LayrzThemeData`.

**Token API** (sketch):
```dart
abstract class LayrzThemeExtension<T> {
  LayrzThemeExtension<T> copyWith();
  LayrzThemeExtension<T> lerp(LayrzThemeExtension<T>? other, double t);
}

// On LayrzThemeData:
class LayrzThemeData {
  final Map<Type, LayrzThemeExtension<dynamic>> extensions = {};
  T? extension<T extends LayrzThemeExtension<T>>() => extensions[T] as T?;
}
```

**Files affected**:
- `lib/theme/src/theme_extension.dart` (new)
- `lib/theme/src/theme_data.dart` — add extensions map and accessor
- `lib/theme/theme.dart` (barrel, update)

**Why it matters**:
This mechanism is not immediately used in M1, but is prerequisite for M2+ components that need to store theme-scoped data (e.g., button style variants, input label positioning rules, table column styles).

**Verification**:
- Create a dummy extension class, store it on a `LayrzThemeData`, retrieve it via `maybeExtension<T>()`
- Extensions are retrievable and immutable

---

#### 6. WidgetState/WidgetStatesController state-resolution layer

**What changes**:
- Create `lib/state/` module (new)
- `lib/state/state.dart` — a documented `show` re-export of `WidgetState`, `WidgetStateProperty`, and related types from `package:flutter/widgets.dart`

**Resolved Question** (Decision D13):
`WidgetStateProperty`, `WidgetStatesController`, and the complete state family are **material-free and exported from `package:flutter/widgets.dart`** in Flutter 3.47. Verification against the installed SDK confirms no Material dependency. Therefore, there is no need to hand-roll replacements; re-export only.

**Why it matters**:
All interactive components (buttons, inputs, chips, etc.) respond to hover, press, focus, disabled states. The SDK provides a design-system-agnostic `WidgetStateProperty<T>` interface and `WidgetStateColor`, `WidgetStateTextStyle`, and other convenience implementations. Rather than hand-rolling our own, we re-export the SDK types and use them directly in M2+ components.

**Files affected**:
- `lib/state/` (new module)
- `lib/state/state.dart` (barrel with re-exports only)
- `lib/state/src/widget_state.dart` (documentation file only)

**Verification**:
- `flutter analyze` on lib/state/; must be clean
- Tests verify that `WidgetStateColor.resolve()` and `WidgetStateProperty<T>` work as expected

---

### Phase 4: Supporting Infrastructure

#### 7. lib/fonts/ with LayrzFontHandler

**What changes**:
- Create `lib/fonts/` module (new)
- `lib/fonts/src/font_handler.dart` — interface `LayrzFontHandler` providing TextStyle-API methods for font loading
- Implementation using `google_fonts` (TextStyle APIs only, never `*TextTheme()`)
- Support runtime font selection by name

**Token API**:
```dart
abstract class LayrzFontHandler {
  TextStyle apply(TextStyle base, {String? fontFamily, double? fontSize});
  TextStyle load(String fontName);
  // ... more as needed
}

// Concrete implementation
class GoogleFontsHandler implements LayrzFontHandler {
  // Uses google_fonts.GoogleFonts.* TextStyle methods only
}
```

**Files affected**:
- `lib/fonts/` (new module)
- `lib/fonts/fonts.dart` (barrel, new)
- `lib/fonts/src/font_handler.dart` (new)
- `lib/fonts/src/google_fonts_handler.dart` (new)
- `pubspec.yaml` — dependency on `google_fonts: ^8.2.1` (likely already present)

**Why it matters**:
Components need a consistent way to apply fonts. google_fonts is the standard source, but we abstract it so the rest of the system doesn't directly depend on its API.

**Verification**:
- `LayrzFontHandler.load('inter')` returns a `TextStyle` with the appropriate font
- No `GoogleFonts.*TextTheme()` calls anywhere (the CI guard from M1 item 9 enforces this)

---

#### 8. LayrzPreviewTheme and Preview support

**What changes**:
- Create `lib/preview/` module (new)
- `lib/preview/src/preview_theme.dart` — `LayrzPreviewTheme extends PreviewThemeData` with light theme only
- Update CLAUDE.md rule #3 example to show how to use it

**Token API**:
```dart
class LayrzPreviewTheme extends PreviewThemeData {
  static PreviewThemeData light() => LayrzPreviewTheme(...);
  
  @override
  Widget apply(BuildContext context, Widget widget) =>
    LayrzTheme(data: ..., child: widget);
}
```

**Why `extends` not `implements`**: `PreviewThemeData` is declared as `abstract base class` in the SDK (`package:flutter/widget_previews.dart`). Only `extends` is valid for `base class` types.

**Example usage** (from corrected CLAUDE.md rule #3):
```dart
@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewMyButton() => LayrzButton(...);
```

**Files affected**:
- `lib/preview/` (new module)
- `lib/preview/preview.dart` (barrel, new)
- `lib/preview/src/preview_theme.dart` (new)
- `CLAUDE.md` — rule #3 already corrected in item 2 above

**Why it matters**:
Flutter 3.47's widget preview system is production-ready. Previews let developers see visual widgets without launching a device. `LayrzPreviewTheme` makes previews one-liners.

**Verification**:
- Write a simple stateless widget with a `@Preview` annotation pointing to `LayrzPreviewTheme.light`
- Open the preview in an IDE (VS Code with Flutter extension) or run `flutter test --preview`

---

### Phase 5: Test Coverage (Close the Gap)

#### 11. Close the test gap

**What changes**:
- Write tests for all M1 infrastructure, matching the structure of lib/:
  - `test/theme/` — LayrzTheme.of(), theme propagation, InheritedTheme.wrap() across Overlay boundaries
  - `test/constants/` — color, grid, duration, app constants exist and are sensible
  - `test/extensions/` — LayrzColorExtensions, LayrzContextExtensions
  - `test/platform/` — LayrzPlatform enum, platform detection
  - `test/tokens/` — all token classes construct, copyWith works, immutability verified
  - `test/tokenizer/` — LayrzTokenizer.of() and maybeOf() work, both access paths stay in sync
  - `test/app/` — LayrzApp and LayrzApp.router construct and install theme
  - `test/state/` — WidgetState and WidgetStateProperty re-exports are accessible

**Critical test**:
```dart
testWidgets('LayrzTheme survives Overlay boundary via wrap()', (tester) async {
  // This test verifies M1 item 1 (InheritedTheme.wrap fix).
  // Build LayrzTheme -> OverlayEntry -> LayrzTheme.of() inside overlay.
  // Should not crash.
});
```

**Files affected**:
- `test/src/` (new directory structure, mirrors lib/src/)
- Multiple `*_test.dart` files (one test file per module)

**Why it matters**:
Test coverage is mandatory per CLAUDE.md rule #2. With one test file covering only theme basics, M1 ships untested. Closing the gap now means future components inherit a tested foundation.

**Verification**:
- `flutter test --coverage` reports > 80% coverage on lib/
- All testWidgets pass
- The Overlay boundary test specifically passes

---

### Phase 6: Release (Final Step)

#### 12. Update CHANGELOG.md and commit pubspec version bumps

**What changes**:
- `CHANGELOG.md` — replace the 3-line placeholder with a meaningful M1 summary
- `pubspec.yaml` and `example/pubspec.yaml` — version bumps are already modified (currently uncommitted); commit them as a separate `chore` commit

**CHANGELOG.md template**:
```markdown
## 0.1.0

### Added
- Complete token system (colors, typography, spacing, radius, shadow, border, motion)
- LayrzThemeExtension mechanism for custom component theme data
- WidgetStateProperty and WidgetStatesController state-resolution layer
- LayrzFontHandler abstraction over google_fonts
- LayrzPreviewTheme for Flutter 3.47 widget previews
- Full test coverage of core infrastructure
- CI pipeline (flutter analyze, flutter test, format check, Material/Cupertino guard)
- public_member_api_docs enforcement

### Fixed
- LayrzTheme now extends InheritedTheme with wrap() for Overlay boundary safety

### Changed
- CLAUDE.md rule #3 corrected to use the real @Preview API (not @widgetPreview)

### Documentation
- docs/ directory with README, roadmap, and detailed M1 plan
```

**Commits** (two separate commits):
1. All code changes from items 1–11 as a single `feat` commit with title like `feat: implement milestone 1 foundation`
2. pubspec version bumps and CHANGELOG as a separate `chore` commit with title like `chore: bump version to 0.1.0 and close M1`

**Files affected**:
- `CHANGELOG.md`
- `pubspec.yaml`
- `example/pubspec.yaml`

**Verification**:
- `git log` shows two commits, both with proper formatting
- `pubspec.yaml` version is 0.1.0 or higher
- CHANGELOG.md is no longer a placeholder

---

## Explicit Non-Goals

The following **are out of scope** for M1:

- **Any components** (buttons, inputs, dialogs, etc.) — M2 and beyond
- **Anything touching layrz_models** — deferred until models are Material-free
- **Map, code editor, code snippet** — M7 blocked/deferred (upstream dependencies)
- **Comprehensive documentation** of every API (CLAUDE.md and rule #1 enforce doc comments; full API docs are a later task)
- **Performance or bundle-size optimization** — measure after components exist

---

## Blocking Fixes: InheritedTheme.wrap() Detail

### The Problem

When a widget is rendered inside an Overlay (used by dialogs, tooltips, dropdown menus) or crosses a route boundary, the InheritedWidget lookup chain is broken. Any descendant trying to call `LayrzTheme.of(context)` will not find the theme because the context is "below" the Overlay/route boundary.

### Example Failure

```dart
showDialog(
  context: context,
  builder: (_) => LayrzDialog(
    child: Builder(
      builder: (innerContext) {
        // This crashes because theme is not in innerContext's inheritance chain:
        final theme = LayrzTheme.of(innerContext);  // → AssertionError
        return LayrzButton(child: Text('...')); // Never reached
      },
    ),
  ),
);
```

### The Solution

`InheritedTheme` is a special subclass of `InheritedWidget` that implements `wrap(BuildContext, Widget)`. The platform's route system calls `wrap()` automatically when crossing a route boundary, ensuring the theme is reinstalled below the boundary.

```dart
class LayrzTheme extends InheritedTheme {
  @override
  Widget wrap(BuildContext context, Widget child) {
    return LayrzTheme(
      data: data,
      child: child,
    );
  }
  // ... rest of the class
}
```

With this fix, the dialog example works:

```dart
showDialog(
  context: context,
  builder: (_) => LayrzDialog(
    child: Builder(
      builder: (innerContext) {
        // Now succeeds because wrap() reinstalled the theme:
        final theme = LayrzTheme.of(innerContext);
        return LayrzButton(child: Text('...'));
      },
    ),
  ),
);
```

### When wrap() is Called

- `Navigator.push()` and `Navigator.pop()`
- `showDialog()`, `showBottomSheet()`, `showGeneralDialog()`
- Any use of `OverlayEntry` directly
- PageRoute transitions

---

## Acceptance Criteria

M1 is complete when all the following criteria are satisfied:

- **Item 1**: LayrzTheme extends InheritedTheme; wrap() implemented; Overlay boundary test passes
- **Item 2**: CLAUDE.md rule #3 corrected; @Preview (not @widgetPreview) documented; LayrzPreviewTheme extends (not implements) PreviewThemeData
- **Item 9**: CI pipeline active; all four checks (analyze, test, format, Material guard) pass
- **Item 10**: `public_member_api_docs: true` in analysis_options.yaml; `flutter analyze` enforces it
- **Item 3**: LayrzColorTokens defined with all light-theme colors; LayrzThemeData.tokens field exists; all colors initialized
- **Item 4**: All six token classes (LayrzTextTheme, spacing, radius, shadow, border, motion) defined; aggregated into LayrzTokens; all light-theme values initialized
- **Item 5**: LayrzThemeExtension interface defined; extensions map on LayrzThemeData; accessor works
- **Item 6**: WidgetState family re-exported from package:flutter/widgets.dart (verified material-free per D13); tests verify state resolution works
- **Item 7**: LayrzFontHandler interface; GoogleFontsHandler implementation; no `*TextTheme()` calls in lib/
- **Item 8**: LayrzPreviewTheme extends PreviewThemeData; light theme only; @Preview example in CLAUDE.md working
- **Item 11**: test/ mirrors lib/ structure; > 80% coverage; Overlay boundary test included; all testWidgets and tests pass; both token access paths (direct and tokenizer) synchronized
- **Item 12**: CHANGELOG.md meaningful; pubspec version bumped; two separate commits created
- **Invariant**: `grep -r "package:flutter/material\|package:flutter/cupertino" lib/` returns empty
- **All code documented**: `flutter analyze` reports zero public API doc violations
- **All tests pass**: `flutter test` reports 100% pass rate

---

**Milestone 1 plan finalized**: 2026-08-13

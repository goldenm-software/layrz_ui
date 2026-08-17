# layrz_ui — Claude Code Instructions

## What this project is

`layrz_ui` is a **Material-free, Cupertino-free** Flutter design system — a drop-in replacement for `layrz_theme`. It is built exclusively on `package:flutter/widgets.dart` and `dart:ui`. No `package:flutter/material.dart` or `package:flutter/cupertino.dart` imports are ever allowed anywhere under `lib/`.

Verify this invariant after every change:
```
grep -r "package:flutter/material\|package:flutter/cupertino" lib/
```
The output must always be empty.

---

## Project structure

Each module has two parts:
- A top-level entrypoint barrel at `lib/<module>.dart` containing **only** `export` statements
- Implementation files under `lib/src/<module>/`, one file per concern

Consumers import each domain directly, e.g., `import 'package:layrz_ui/buttons.dart';`. There is no root barrel combining all modules.

```
lib/
  app.dart                       # Entrypoint barrel — re-exports from src/app/
  buttons.dart                   # Entrypoint barrel — re-exports from src/buttons/
  constants.dart                 # Entrypoint barrel — re-exports from src/constants/
  extensions.dart                # Entrypoint barrel — re-exports from src/extensions/
  fonts.dart                     # Entrypoint barrel — re-exports from src/fonts/
  platform.dart                  # Entrypoint barrel — re-exports from src/platform/
  preview.dart                   # Top-level preview entrypoint (deliberate exception; re-exports LayrzPreviewTheme)
  state.dart                     # Entrypoint barrel — re-exports from src/state/
  theme.dart                     # Entrypoint barrel — re-exports from src/theme/
  tokenizer.dart                 # Entrypoint barrel — re-exports from src/tokenizer/
  tokens.dart                    # Entrypoint barrel — re-exports from src/tokens/
  src/
    app/
      app.dart                   # LayrzApp, LayrzApp.router
    buttons/
      layrz_button.dart          # LayrzButton component + factories
    constants/
      colors.dart                # kPrimaryColor, kLightBackgroundColor
      grid.dart                  # kExtraSmallGrid … kLargeGrid breakpoints
      durations.dart             # kHoverDuration, kPageTransitionDuration
      app.dart                   # kAppTitle and other app-level defaults
    extensions/
      color.dart                 # LayrzColorExtensions on Color
      context.dart               # LayrzContextExtensions on BuildContext
    fonts/
      font.dart                  # LayrzFont, LayrzFontSource
      font_handler.dart          # LayrzFontHandler interface
      google_fonts_handler.dart  # LayrzGoogleFontsHandler implementation
    platform/
      platform.dart              # LayrzPlatform enum
    preview/
      preview_theme.dart         # LayrzPreviewTheme (extends PreviewThemeData)
    state/
      widget_state.dart          # Documentation + re-exports from package:flutter/widgets.dart
    theme/
      theme.dart                 # LayrzTheme (InheritedTheme)
      theme_data.dart            # LayrzThemeData (holds LayrzTokens)
      theme_extension.dart       # LayrzThemeExtension<T> (custom component theme data)
    tokens/
      tokens.dart                # LayrzTokens aggregate
      colors.dart                # LayrzColorTokens
      typography.dart            # LayrzTextTheme
      spacing.dart               # LayrzSpacingTokens
      radius.dart                # LayrzRadiusTokens
      shadow.dart                # LayrzShadowTokens
      border.dart                # LayrzBorderTokens
      motion.dart                # LayrzMotionTokens
    tokenizer/
      tokenizer.dart             # LayrzTokenizer (thin façade over tokens)
.github/
  workflows/
    checks.yaml                  # CI gates: analyze, test, Material/Cupertino guard, GoogleFonts guard, coverage (90% floor)
    publish.yaml                 # Release workflow: tag validation, pub.dev publication, GitHub release, web showroom build
tool/
  deploy_web.py                  # Deploy web showroom to hosting after release
example/
  lib/main.dart                  # Example app (must use LayrzApp, not MaterialApp)
  Makefile                       # run-linux / run-android / run-ios / run-windows / run-macos
Makefile                         # Root — delegates to example/ via $(MAKE) -C example <target>
```

**To add a new module**, create:
- `lib/<module>.dart` — entrypoint barrel with only `export` statements
- `lib/src/<module>/` — directory containing implementation files
- Export from the root barrel if the module is part of public API

---

## Documentation Directory

Documentation is split between repository documentation (`engineering/`) and widget documentation (GitHub wiki):

### Repository Documentation (`engineering/`)

Engineering documentation lives in `engineering/` (singular). The Pub layout convention uses singular directory names: `lib`, `test`, `doc`, `example`, `tool`, `bin`. This directory was named `engineering/` (rather than `doc/`) to avoid triggering Pub's warning about plural `docs` directories, and to keep `doc/` available for dartdoc's generated API documentation.

- `doc/api/` — `dartdoc` generates API documentation here
- Markdown documentation is authored in `engineering/`, reviewed in pull requests alongside the code, and serves as the source of truth for architecture and design decisions

**Repository engineering files** (9 files):
- `README.md` — index and quick start
- `roadmap.md` — M1–M7 overview
- `milestone-1.md` — detailed foundation plan
- `architecture.md` — codebase organization and patterns
- `design-tokens.md` — token system specification
- `flutter-347-audit.md` — Flutter 3.47 widget inventory
- `dependencies.md` — dependency audit and Material decoupling strategy
- `decisions.md` — architectural and policy decisions
- `migration-gap.md` — gap analysis for layrz_theme → layrz_ui migration

### Widget Documentation (GitHub Wiki)

The GitHub wiki (`wiki/`) is a git submodule tracking [goldenm-software/layrz_ui.wiki.git](git@github.com:goldenm-software/layrz_ui.wiki.git):
- All per-component documentation (28 widget pages)
- Input contract and component catalog
- Cross-cutting topic pages (Home, Getting Started, Theming, Design Tokens, Component Catalog, etc.) live at the wiki root; per-widget pages live in `wiki/Widgets/` subdirectory and must be registered in `wiki/Widgets/_Sidebar.md` to appear in navigation
- Wiki pushes go live immediately (no PR review)
- Cross-links from wiki to repo docs use absolute GitHub URLs: `https://github.com/goldenm-software/layrz_ui/blob/main/engineering/architecture.md`
- `wiki/` is excluded from package distribution via `.pubignore`

**Key distinction**: `engineering/` holds engineering documentation (architecture, decisions, audit); `wiki/` holds user-facing widget documentation.

### NEW WIDGET DOCUMENTATION GOES IN THE WIKI

When you add a new widget, document it in `wiki/Widgets/` (not `engineering/`), and register it in `wiki/Widgets/_Sidebar.md` so it appears in the navigation sidebar.

---

## Progress Tracking

**Progress page:** https://layrz.notion.site/3bf1a14cf90480c996cad105cdc60d80?v=3bf1a14cf90480118d09000c19185bd6

**Authoritative record:** Each `engineering/milestone-N.md` contains a `## Status` table recording the current state of work items, milestone by milestone. These tables are the source of truth, kept in step with the code in the same commit. The Notion page above is the shared, publicly linkable view of the same status.

**GitHub Issues remain enabled** — but **only** as the inbound bug channel for package users. `pubspec.yaml:6` declares `issue_tracker: https://github.com/goldenm-software/layrz_ui/issues`, which `pub.dev` surfaces as "View/report issues". External bug reports are welcome there; internal planning is not.

**GitHub Project 9 is retired.** It is no longer used for internal planning.

### Conventions

- **Checkboxes are forbidden everywhere.** Status lives in the milestone Status tables only. Work items and acceptance criteria stay as plain-bullet specifications (`-`) without checkboxes.
- The **Component Catalog** in the wiki (https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog) holds the mapping from layrz_theme to layrz_ui only — target name, milestone assignment (planning metadata, allowed), which SDK primitive it builds on, and blockers. **Completion status is not tracked in the wiki.**

---

## CRITICAL rules — always follow these

### 1. Document EVERY argument at 100%

Every public constructor, function, and method parameter **must** have a `///` doc comment. No exceptions. Undocumented parameters will be rejected.

```dart
// WRONG
class MyWidget extends StatelessWidget {
  final Color color;
  final double size;
  ...
}

// CORRECT
class MyWidget extends StatelessWidget {
  /// The fill color applied to the widget's background.
  final Color color;

  /// The width and height of the widget in logical pixels.
  final double size;
  ...
}
```

This applies to:
- All class fields
- All constructor parameters (named and positional)
- All function/method parameters
- All factory constructors and their parameters
- All enum values

### 2. Full test coverage

Testing is a hard requirement, not guidance. Every public API — widget, extension, helper, utility — **must** have corresponding tests. No code ships without tests.

- Widgets → `testWidgets` in `test/`
- Pure functions / extensions → `test()` in `test/`
- Mirror the `lib/src/<module>/` directory structure under `test/<module>/` (entrypoint barrels are exempt)
- Test all named constructors and factories independently
- Test edge cases: null-safe fields, empty inputs, boundary values
- Every visual component additionally requires accessibility tests

The convention of mirroring `lib/src/<module>/` structure under `test/<module>/` is now **enforced by code review**, not by CI. It remains a required pattern, but the `tool/check_test_mirror.sh` script that enforced it in CI has been removed. Maintain this structure on every PR.

**CI enforces a 90% coverage floor** via the shared `goldenm-software/layrz-actions/check-dart` action, which runs:
1. **flutter analyze** — linting must be clean
2. **flutter test --coverage** — all tests pass and coverage is reported
3. **Material/Cupertino guard** (`grep` inline) — no Material or Cupertino imports in lib/
4. **GoogleFonts TextTheme guard** (`grep` inline) — no Material-coupled font methods
5. **Coverage floor at 90%** — shared action enforces minimum coverage; current coverage is 95.7%, so up to ~6 percentage points of drift are permitted before the floor triggers

**Local-only convention**: `dart format` is **not** a CI gate. Code formatting is a local-development concern, not a pipeline gate. Run `dart format -w lib/ test/` before committing.

### 3. Use @Preview for visual widgets

For stateless or lightly-stateful widgets, add `@Preview` annotations (Flutter 3.47+) at the bottom of the widget file so it can be previewed without launching a device. Previews use the Flutter widget preview system with `LayrzPreviewTheme`.

```dart
import 'package:flutter/widget_previews.dart';
import 'package:layrz_ui/preview.dart';

@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewMyWidget() => MyWidget(color: kPrimaryColor, size: 48);
```

The real API in Flutter 3.47:
- **Import**: `package:flutter/widget_previews.dart` (plural)
- **Annotation**: `@Preview(...)` with named fields: `group`, `name`, `size`, `textScaleFactor`, `wrapper`, `theme`, `brightness`, `localizations`
- **Theme type**: `PreviewThemeData` (abstract base class in the SDK)
- **layrz_ui integration**: `LayrzPreviewTheme extends PreviewThemeData` (must extend because the SDK declares it as `abstract base class`, not an interface). Light theme only; dark mode is out of scope per decision D7.

**Important**: The `theme:` parameter accepts a tear-off: `@Preview(theme: LayrzPreviewTheme.light)`, not an instance. `LayrzPreviewTheme.light` is a static method that returns a `PreviewThemeData`.

Rules:
- Only add previews for **visual** widgets (skip helpers, extensions, enums, data classes).
- Use `LayrzPreviewTheme.light` as a tear-off in the `@Preview` annotation.
- Add a single `@Preview` annotation for the light theme.
- Each preview function returns the widget directly (no need to wrap in LayrzApp; the theme callback handles it).

### 4. One concern per file — always split, never pile

**Never put multiple unrelated things in a single file.** When a domain grows, split it.

Examples of what belongs in separate files:
- Each widget in its own file under `lib/src/<domain>/`
- Each category of constants in its own file under `lib/src/constants/`
- Each extension target (Color, BuildContext, String…) in its own file under `lib/src/extensions/`
- Data classes, enums, and helpers each in their own file

A domain always has:
```
lib/<domain>.dart              ← entrypoint barrel, only re-exports
lib/src/<domain>/
  <thing_a>.dart
  <thing_b>.dart
```

The barrel file must contain **only** `export` statements — no logic, no classes.

**Note**: `lib/preview.dart` is a deliberately placed top-level barrel (outside the module's src/ directory) to keep preview infrastructure opt-in. See decision D18 in `engineering/decisions.md` for the original rationale. D18 was superseded by D19's restructure (2026-08-16), which made every module a top-level entrypoint; the preview exception now blends with the standard pattern.

---

## Coding conventions

- **No Material/Cupertino** — use `Container`, `DecoratedBox`, `GestureDetector`, `CustomPaint`, `RichText`, etc. instead.
- **No comments explaining what the code does** — only document *why* when the reason is non-obvious. Arg docs are mandatory (rule #1); inline comments explaining logic are not.
- **Immutable data classes** — annotate with `@immutable`, implement `==` and `hashCode` via `Object.hash`, provide `copyWith`.
- **Theming** — always read colors and styles from `LayrzTheme.of(context)` / `context.theme`. Never hardcode design values inside widgets.
- **Responsive grid** — use the breakpoint constants from `package:layrz_ui/constants.dart` (`kExtraSmallGrid`, etc.).
- **Platform checks** — use `LayrzPlatform` from `platform.dart`, not `Platform` from `dart:io` directly.
- **Interaction states** — hover, press, focus, and disabled states must vary colour, border colour, shadow, opacity, and cursor only; never size, border width, padding, margin, or scale. Geometry changes cause flicker and reflow. See decision D15 in `engineering/decisions.md`.
- **Cross-module imports use `package:layrz_ui/`** — for any import within `lib/` or from `test/` and `example/lib/` into the package, use the absolute form `import 'package:layrz_ui/constants/constants.dart';` instead of relative paths. Same-module imports within `src/` may remain relative. Exemption: relative imports within `test/` for test-local helpers (like `import '../helpers/pump_themed.dart';`) are required and correct, since the package URI space covers only `lib/`. See decision D20 in `engineering/decisions.md`.
- **SDK constraint** — Dart `>=3.13.0 <4.0.0` / Flutter `>=3.47.0`. These minima are required: `RawTooltip`, `RawMenuAnchor`, `RawRadio`, and the stable `@Preview` API exist only in 3.47; lowering the floor would silently break them. Do not raise without checking the CI environment.

### Light Mode Only

**layrz_ui targets light mode only.** Dark mode is out of scope and has been removed entirely. See decision D7 in `engineering/decisions.md` for the rationale.

Specifically removed from the codebase:
- `LayrzThemeData.dark()` factory constructor
- `LayrzThemeMode` enum and `LayrzApp.darkTheme`, `LayrzApp.themeMode` parameters
- `context.isDark` extension
- `kDarkBackgroundColor` constant
- `errorColor` field (renamed to `dangerColor` for semantic clarity)
- All dark-theme token variants

The decision was made to not architect for dark mode; adding it later will require revisiting every token and every component that assumed a single light palette.

---

## Running the example

```bash
make run-linux     # Linux desktop
make run-android   # Android
make run-ios       # iOS
make run-windows   # Windows desktop
make run-macos     # macOS desktop
```

All commands are delegated via `$(MAKE) -C example <target>`.

---

## Running tests

```bash
flutter test                   # from repo root
flutter test --coverage        # with coverage report
```

Tests live under `test/` and mirror the structure of `lib/src/`. For example:
- `lib/src/tokens/colors.dart` → `test/tokens/colors_test.dart`
- `lib/src/theme/theme.dart` → `test/theme/theme_test.dart`

---

## Adding a new widget (checklist)

1. Create `lib/src/<domain>/<widget_name>.dart` — one widget per file
2. Create (or update) the barrel `lib/<domain>.dart` with only `export` statements (create this file if the domain is new)
3. Ensure the barrel exports the new widget
4. Document every argument (see rule #1)
5. Write tests in `test/<domain>/<widget_name>_test.dart` (see rule #2)
6. Add `@Preview` annotations at the bottom of the widget file if applicable (see rule #3)
7. Run `flutter analyze` — must be clean
8. Run `flutter test` — must be green
9. Verify no material/cupertino imports crept in

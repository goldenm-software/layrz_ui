# layrz_ui — Claude Code Instructions

## What this project is

`layrz_ui` is a **Material-free, Cupertino-free** Flutter design system — a drop-in replacement for `layrz_theme`. It is built exclusively on `package:flutter/widgets.dart` and `dart:ui`. No `package:flutter/material.dart` or `package:flutter/cupertino.dart` imports are ever allowed anywhere under `lib/`.

Verify this invariant after every change:
```
grep -r "package:flutter/material\|package:flutter/cupertino" lib/
```
The output must always be empty.

### This is a Dart-only project

The only published package in this repository is the Dart package declared in the root `pubspec.yaml`. Version bumps, releases and dependency work concern **that file and no other**.

**`pyproject.toml` at the repo root must be ignored.** It declares `layrz-ui-tools`, an unrelated helper package that exists solely for `tool/deploy_web.py`, and its version is independent of layrz_ui's. Never bump it as part of a layrz_ui release, and never treat this repository as a Python project because that file exists.

Likewise, `example/pubspec.yaml` and `.widget_preview/pubspec.yaml` are not published packages — leave their versions alone. Only `example/pubspec.lock` is ever synced after a release bump, and only when it actually changes.

**The version is self-managed — CI never injects it.** No workflow runs `sed` (or anything equivalent) to write the version into `pubspec.yaml` at deploy time, so a release means editing that `version:` line by hand and committing it. Do not go looking for CI-managed version substitution; there is none.

**layrz_ui_i18n binding:** Localization support is provided via `layrz_ui_i18n`, a separate package published in [goldenm-software/layrz_ui_i18n](https://github.com/goldenm-software/layrz_ui_i18n). It depends on `layrz_ui >= 0.0.9` where `LayrzUiL10n` was introduced.

---

## Project structure

Each module has a consistent structure:
- A per-module barrel at `lib/src/<module>/<module>.dart` containing **only** `export` statements
- Implementation files under `lib/src/<module>/src/`, one file per concern
- A root barrel at `lib/layrz_ui.dart` exporting all 14 modules as the blessed consumer import

Consumers import the root barrel, e.g., `import 'package:layrz_ui/layrz_ui.dart';` then use `LayrzButton`, `LayrzTextInput`, etc. See [decision D26](engineering/decisions.md#d26) for the rationale.

```
lib/
  layrz_ui.dart                  # Root barrel — exports all 14 modules
  src/
    alerts/
      alerts.dart                # Per-module barrel — re-exports from src/
      src/
        alert.dart               # LayrzAlert component
        alert_icon.dart          # LayrzAlertIcon helper
    app/
      app.dart                   # Per-module barrel
      src/
        app.dart                 # LayrzApp, LayrzApp.router
    buttons/
      buttons.dart               # Per-module barrel
      src/
        layrz_button.dart        # LayrzButton component + factories
    cards/
      cards.dart                 # Per-module barrel
      src/
        card.dart                # LayrzCard component
    constants/
      constants.dart             # Per-module barrel
      src/
        colors.dart              # kPrimaryColor, kLightBackgroundColor
        durations.dart           # kHoverDuration, kPageTransitionDuration
        app.dart                 # kAppTitle and other app-level defaults
    extensions/
      extensions.dart            # Per-module barrel
      src/
        color.dart               # LayrzColorExtensions on Color
        context.dart             # LayrzContextExtensions on BuildContext
    fonts/
      fonts.dart                 # Per-module barrel
      src/
        font.dart                # LayrzFont, LayrzFontSource
        font_handler.dart        # LayrzFontHandler interface
        google_fonts_handler.dart # LayrzGoogleFontsHandler implementation
    grid/
      grid.dart                  # Per-module barrel
      src/
        row.dart                 # LayrzRow (ResponsiveRow)
        col.dart                 # LayrzCol (ResponsiveCol)
    platform/
      platform.dart              # Per-module barrel
      src/
        platform.dart            # LayrzPlatform enum
    state/
      state.dart                 # Per-module barrel
      src/
        widget_state.dart        # Re-exports from package:flutter/widgets.dart
    theme/
      theme.dart                 # Per-module barrel
      src/
        theme.dart               # LayrzTheme (InheritedTheme)
        theme_data.dart          # LayrzThemeData (holds LayrzTokens)
        theme_extension.dart     # LayrzThemeExtension<T> (custom component theme data)
    tokenizer/
      tokenizer.dart             # Per-module barrel
      src/
        tokenizer.dart           # LayrzTokenizer (thin façade over tokens)
    tokens/
      tokens.dart                # Per-module barrel
      src/
        colors.dart              # LayrzColorTokens
        typography.dart          # LayrzTextTheme
        spacing.dart             # LayrzSpacingTokens
        radius.dart              # LayrzRadiusTokens
        shadow.dart              # LayrzShadowTokens
        border.dart              # LayrzBorderTokens
        motion.dart              # LayrzMotionTokens
        tokens.dart              # LayrzTokens aggregate
    tooltips/
      tooltips.dart              # Per-module barrel
      src/
        tooltip.dart             # LayrzTooltip component
.github/
  workflows/
    checks.yaml                  # CI gates: analyze, test, Material/Cupertino guard, GoogleFonts guard, coverage floor
    publish.yaml                 # Release workflow: tag validation, pub.dev publication, GitHub release, web showroom build
tool/
  deploy_web.py                  # Deploy web showroom to hosting after release
example/
  lib/main.dart                  # Example app (must use LayrzApp, not MaterialApp)
  Makefile                       # run-linux / run-android / run-ios / run-windows / run-macos
Makefile                         # Root — delegates to example/ via $(MAKE) -C example <target>
```

**To add a new module**, create:
- `lib/src/<module>/<module>.dart` — per-module barrel with only `export` statements
- `lib/src/<module>/src/` — directory containing implementation files
- Update `lib/layrz_ui.dart` to export the new module

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

## Branching

### Always branch from `development`, never from `main`

`main` is the **stable / released** branch: it is what gets published to pub.dev, not what gets worked on. `development` is the **working branch** — the base for every `feat`/`fix`/`chore` branch and the target of every PR.

Before creating a branch:
```
git checkout development && git pull
```

Then create and push your feature branch. The only thing that ever touches `main` is a release PR from `development`.

**Branch naming convention:** `{type}/{module}/{brief-name-or-notion-id}` with types `feat`, `fix`, `chore`. Examples:
- `feat/navigation/DESIGN-30`
- `fix/text/stateless-layrz-text`
- `chore/alerts/trim-unused-styles`

Notion row IDs follow the format `DESIGN-NN`, e.g. `DESIGN-20`, `DESIGN-30`.

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

#### Two traps that make a green suite prove nothing

**1. Set an explicit viewport in every `testWidgets`.** `context.isCompact` is `< 960px` and Flutter's default test surface is **800×600**, so a test that sets no viewport silently exercises the **compact** branch only. A wide-layout assertion then fails against correct code, and a "renders without error" assertion passes without ever reaching the desktop path.

```dart
tester.view.physicalSize = const Size(1600, 1200);  // or Size(400, 800) for compact
tester.view.devicePixelRatio = 1.0;
addTearDown(tester.view.reset);   // without this the size leaks into later tests
```

For anything branching on `isCompact`, **assert both directions** — the expected layout present *and* the other absent, at a wide size and a narrow one. A test that only checks the expected form is present also passes against a widget rendering both. Better still, pair a *narrow* viewport with an `isCompact: false` override (and vice versa), which additionally proves the override wins over the derived value.

**2. `SemanticsHandle` must be disposed with `try`/`finally`, never `addTearDown`.** On the pinned Flutter SDK, `addTearDown(handle.dispose)` does **not** dispose before `_endOfTestVerifications` runs, and every test using it fails with *"A SemanticsHandle was active at the end of the test."* Bisected against a minimal repro. Match the existing suites:

```dart
final handle = tester.ensureSemantics();
try {
  // ... assertions ...
} finally {
  handle.dispose();
}
```

And assert **real properties** via `matchesSemantics(...)` — never `expect(semantics, isNotNull)`, never `expect(() => x.dispose(), returnsNormally)`, never a bare `expect(find.byType(Foo), findsOneWidget)` as a test's substantive assertion. Prefer dumping the semantics tree over `find.bySemanticsLabel`, which has produced a false green here. Each of these patterns has shipped tests in this repo that verify nothing while reading as a safety net.

The convention of mirroring `lib/src/<module>/` structure under `test/<module>/` is now **enforced by code review**, not by CI. It remains a required pattern, but the `tool/check_test_mirror.sh` script that enforced it in CI has been removed. Maintain this structure on every PR.

**CI enforces a coverage floor** via the shared `goldenm-software/layrz-actions/check-dart` action, which runs:
1. **flutter analyze** — linting must be clean
2. **flutter test --coverage** — all tests pass and coverage is reported
3. **Material/Cupertino guard** (`grep` inline) — no Material or Cupertino imports in lib/
4. **GoogleFonts TextTheme guard** (`grep` inline) — no Material-coupled font methods
5. **Coverage floor** — the shared action enforces a minimum coverage threshold. Run `flutter test --coverage` to see where the repository currently stands; aim to maintain or improve coverage on every change, and never let a change take it downward

**Local-only convention**: `dart format` is **not** a CI gate. Code formatting is a local-development concern, not a pipeline gate. Run `dart format -w lib/ test/` before committing.

### 3. One concern per file — always split, never pile

**Never put multiple unrelated things in a single file.** When a domain grows, split it.

Examples of what belongs in separate files:
- Each widget in its own file under `lib/src/<domain>/`
- Each category of constants in its own file under `lib/src/constants/`
- Each extension target (Color, BuildContext, String…) in its own file under `lib/src/extensions/`
- Data classes, enums, and helpers each in their own file

A module always has:
```
lib/src/<domain>/<domain>.dart ← per-module barrel, only re-exports
lib/src/<domain>/src/
  <thing_a>.dart
  <thing_b>.dart
```

The barrel file must contain **only** `export` statements — no logic, no classes. All modules are exported from the root barrel at `lib/layrz_ui.dart`, which is the blessed consumer import.

### 4. `LayrzInputChrome` is IMMUTABLE — never modify it

`lib/src/inputs/src/shared/input_chrome.dart` is **frozen**. It is the shared chrome behind every input in the library — text, textarea, number, password, search, select, combobox, duration, and every input added later. A change there lands in all of them at once, and nothing in the test suite will tell you which one you broke.

**This freeze covers that ONE file, not the `lib/src/inputs/` tree.** The other files under `inputs/` — `duration_input.dart`, `select_input.dart`, `combobox_input.dart`, `search_input.dart`, `number_input.dart` and the rest — are normal code, editable like anything else with the usual care and tests. Do not treat the whole directory as read-only; that over-application has caused real work to be skipped.

**Do not add a parameter to it. Do not change its layout. Do not change how it resolves style, precedence, or state. Do not "just" add an optional flag with a safe default.**

An optional parameter with a default is still a change to the shared contract, and "it defaults to the old behaviour" is the argument that makes these changes feel free. They are not free.

**The only condition under which it may be modified** is an extreme one: a defect that genuinely cannot be fixed from the calling input, where every workaround available to that input has been tried and shown not to work. That bar is deliberately high, and the burden of proof is on whoever wants to change the file — not on whoever objects.

**Before proposing any change to it, you must first demonstrate that the calling input cannot solve the problem itself.** In practice it almost always can:

- **Wrong colour, border, or state styling?** The caller is passing the wrong thing. Check the style-spec precedence — `disabled > readOnly > error > pressed > hover/focused > default`. A higher-precedence flag hardcoded by the caller silently discards everything below it. A real case: `LayrzDurationInput` hardcoded `readOnly: true` into its own style resolution, so `errors` could never paint a danger border, even though the errors were being passed correctly. The fix was one line in the caller.
- **Need the label or footer positioned outside the anchor?** Compose it in the caller. Select, ComboBox and Duration all hoist label and error text into a `Column` around the chrome, so the chrome's own box stays the anchor's rect. That is why the anchored panel lands on the field and not 24px above it.
- **Need content the chrome doesn't render?** Pass it as the `child`, or place it as an external sibling. `LayrzNumberInput`'s step buttons and `LayrzDurationInput`'s clock affordance both live outside the chrome for exactly this reason.
- **Need the chrome to know something it currently renders?** It cannot, and that is the accepted limitation. `labelText` is a single field that both carries the value and triggers the render — there is no way to supply one without the other, because the label row is the first child of the same `Column` that becomes the panel's anchor. Passing a label to suppress its render would reintroduce the anchor-offset bug. Work around it in the caller, or accept it.

If you believe you have hit the extreme condition, **stop and report it. Do not edit the file.** Say what the defect is, which caller-side workarounds you tried, and why each failed. It is a decision for the maintainer, never for an agent.

---

## Coding conventions

- **No Material/Cupertino** — use `Container`, `DecoratedBox`, `GestureDetector`, `CustomPaint`, `RichText`, etc. instead.
- **No comments explaining what the code does** — only document *why* when the reason is non-obvious. Arg docs are mandatory (rule #1); inline comments explaining logic are not.
- **Immutable data classes** — annotate with `@immutable`, implement `==` and `hashCode` via `Object.hash`, provide `copyWith`.
- **Theming** — always read colors and styles from `LayrzTheme.of(context)` / `context.theme`. Never hardcode design values inside widgets.
- **Responsive breakpoints** — the system is `LayrzBreakpointTokens` (`lib/src/tokens/src/breakpoints.dart`), which defines the `LayrzBreakpoint` bands `xs`/`sm`/`md`/`lg`/`xl` with thresholds at 600/960/1264/1904px. Read them through the `BuildContext` extensions in `lib/src/extensions/src/context.dart`: `context.breakpoint` for the specific band, and `context.isCompact` for the compact/wide decision (`true` for `xs`+`sm`, i.e. viewport < 960px). `context.isCompact` is the single source of truth for responsive sizing decisions across the design system. There are no `kExtraSmallGrid`/`kLargeGrid` constants and no `constants/src/grid.dart` file — do not look for them.
- **`context.isCompact` is width-based; `LayrzPlatform.isMobile` is OS-based. Never substitute one for the other.** A narrow desktop window is compact; a landscape tablet is not. Use `isCompact` for layout and sizing, and the `LayrzPlatform` getters for platform behaviour (keyboard shortcuts, touch affordances).
- **Platform checks** — use `LayrzPlatform` from `platform.dart`, not `Platform` from `dart:io` directly.
- **Interaction states** — hover, press, focus, and disabled states must vary colour, border colour, shadow, opacity, and cursor only; never size, border width, padding, margin, or scale. Geometry changes cause flicker and reflow. See decision D15 in `engineering/decisions.md`.
- **Cross-module imports use `package:layrz_ui/src/`** — within `lib/`, use the absolute form `import 'package:layrz_ui/src/constants/constants.dart';` to reach other modules' per-module barrels, never relative paths. Same-module imports within `src/` may remain relative. Consumers in `test/` and `example/lib/` import the root barrel `import 'package:layrz_ui/layrz_ui.dart';`. Exemption: relative imports within `test/` for test-local helpers (like `import '../helpers/pump_themed.dart';`) are required and correct, since the package URI space covers only `lib/`. See decision D20 in `engineering/decisions.md`.
- **SDK constraint** — Dart `>=3.13.0 <4.0.0` / Flutter `>=3.47.0`. These minima are required: `RawTooltip`, `RawMenuAnchor`, and `RawRadio` exist only in 3.47; lowering the floor would silently break them. Do not raise without checking the CI environment.

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

1. Create `lib/src/<domain>/src/<widget_name>.dart` — one widget per file
2. Create (or update) the per-module barrel `lib/src/<domain>/<domain>.dart` with only `export` statements (create this file if the domain is new)
3. Ensure the per-module barrel exports the new widget
4. Update `lib/layrz_ui.dart` to export the module (if new)
5. Document every argument (see rule #1)
6. Write tests in `test/<domain>/<widget_name>_test.dart` (see rule #2)
7. Run `flutter analyze` — must be clean
8. Run `flutter test` — must be green
9. Verify no material/cupertino imports crept in

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

Each module lives directly under `lib/` as `lib/<module>/`. Every module has a barrel
`<module>.dart` at its root that contains **only** `export` statements, and all
implementation files live under `<module>/src/`.

```
lib/
  layrz_ui.dart                  # Root barrel — re-exports all module barrels
  app/
    app.dart                     # Barrel
    src/
      app.dart                   # LayrzApp, LayrzApp.router
  theme/
    theme.dart                   # Barrel
    src/
      theme.dart                 # LayrzTheme (InheritedTheme)
      theme_data.dart            # LayrzThemeData (holds LayrzTokens + IconThemeData)
  tokens/
    tokens.dart                  # Barrel
    src/
      tokens.dart                # LayrzTokens aggregate
      colors.dart                # LayrzColorTokens
      typography.dart            # LayrzTextTheme
      spacing.dart               # LayrzSpacingTokens
      radius.dart                # LayrzRadiusTokens
      shadow.dart                # LayrzShadowTokens
      border.dart                # LayrzBorderTokens
      motion.dart                # LayrzMotionTokens
  tokenizer/
    tokenizer.dart               # Barrel
    src/
      tokenizer.dart             # LayrzTokenizer (thin façade over tokens)
  fonts/
    fonts.dart                   # Barrel
    src/
      font.dart                  # LayrzFont, LayrzFontSource
      font_handler.dart          # LayrzFontHandler interface
      google_fonts_handler.dart  # LayrzGoogleFontsHandler implementation
  state/
    state.dart                   # Barrel (re-exports WidgetState family)
    src/
      widget_state.dart          # Documentation + re-exports from package:flutter/widgets.dart
  constants/
    constants.dart               # Barrel
    src/
      colors.dart                # kPrimaryColor, kLightBackgroundColor
      grid.dart                  # kExtraSmallGrid … kLargeGrid breakpoints
      durations.dart             # kHoverDuration, kPageTransitionDuration
      app.dart                   # kAppTitle and other app-level defaults
  platform/
    platform.dart                # Barrel
    src/
      platform.dart              # LayrzPlatform enum
  extensions/
    extensions.dart              # Barrel
    src/
      color.dart                 # LayrzColorExtensions on Color
      context.dart               # LayrzContextExtensions on BuildContext
example/
  lib/main.dart                  # Example app (must use LayrzApp, not MaterialApp)
  Makefile                       # run-linux / run-android / run-ios / run-windows / run-macos
Makefile                         # Root — delegates to example/ via $(MAKE) -C example <target>
```

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
- Wiki pages are authored flat at the root with no subdirectories
- Wiki pushes go live immediately (no PR review)
- Cross-links from wiki to repo docs use absolute GitHub URLs: `https://github.com/goldenm-software/layrz_ui/blob/main/engineering/architecture.md`
- `wiki/` is excluded from package distribution via `.pubignore`

**Key distinction**: `engineering/` holds engineering documentation (architecture, decisions, audit); `wiki/` holds user-facing widget documentation.

### NEW WIDGET DOCUMENTATION GOES IN THE WIKI

When you add a new widget, document it in the wiki, not in `engineering/`.

---

## Progress Tracking

Progress is tracked in **both** the GitHub Project and the engineering documentation (`engineering/milestone-N.md`). Both must be kept in step.

- The GitHub Project (number 9 in `goldenm-software` org, linked to `goldenm-software/layrz_ui`) is the authoritative per-module status record
- Each `engineering/milestone-N.md` contains a `## Status` table near the top that mirrors the project's state at the milestone level
- When work on a project item completes, update **both** the GitHub Project status field and the corresponding row in the milestone document's Status table in the same commit
- **Checkboxes are forbidden everywhere.** Status lives in the GitHub Project field and the milestone Status tables only. Work items and acceptance criteria stay as plain-bullet specifications (`-`) without checkboxes.
- The **Component Catalog** in the wiki (https://github.com/goldenm-software/layrz_ui/wiki/Component-Catalog) holds the mapping from layrz_theme to layrz_ui only — target name, milestone assignment (planning metadata, allowed), which SDK primitive it builds on, and blockers. **Completion status is not tracked in the wiki.**

### Granularity: GitHub Project vs. Milestone Documents

The GitHub Project tracks 17 M1 Foundation **modules** (each component, theme piece, token type, etc.), while `engineering/milestone-1.md` groups them into 12 **work items** by functionality. Both describe the same milestone at different decomposition levels:
- The milestone Status table is the strategic view; it shows when major feature areas are complete
- The GitHub Project is the operational view; it tracks individual modules so you know what needs to be done next

### Project Location

**GitHub Projects v2**, number 9 in the `goldenm-software` organization, linked to `goldenm-software/layrz_ui`:  
https://github.com/orgs/goldenm-software/projects/9  
Status: Private

Components are tracked as **plain draft items** (not Issues).

### Custom Fields

- **Phase** (single select): `M1 Foundation`, `M2 Core primitives`, `M3 Inputs`, `M4 Pickers`, `M5 Layout & navigation`, `M6 Data display`, `M7 Blocked`
- **Domain** (single select): Foundation, Theme, Buttons, Inputs, Pickers, Layout, Navigation, Feedback, Data, Grid, Blocked
- **Primitive** (text): Flutter SDK primitive used (e.g. `RawTooltip`, `RawRadio`, `ToggleableStateMixin`) or `hand-rolled` for custom implementations
- **Blocker** (text): blocking dependency, if any

### Important: Phase ≠ Milestone

Documentation refers to **milestones M1–M7**; the Project field recording them is **`Phase`**, NOT `Milestone`. GitHub reserves `Milestone` (along with `Labels`, `Repository`, and `Linked pull requests`) as built-in fields derived only from real Issues — they cannot be used on draft items. So `Phase` in the Project is the tracking mechanism; it maps to the M1–M7 references in `engineering/roadmap.md` and the Component Catalog in the wiki.

### Project Workflow: Draft-to-Issue Conversion

Items follow two conversion paths based on work state:

**For upcoming work** (not yet started): Convert one item at a time when you begin work on it.
1. Convert **that one item** to a real Issue in the project (button in the item's details panel: "Convert to issue")
2. Create a branch: `feat/<domain>/<component-name>` — e.g., `feat/inputs/text-input`
3. Reference the newly-created issue number in your PR title or body: `Closes #N` — GitHub will auto-link and close the issue when the PR merges
4. The issue's Phase, Domain, Primitive, and Blocker fields remain intact after conversion

**For completed work** (already shipped): Bulk conversion and closure happens to make the board legible — showing what the team has finished. Shipped Milestone 1 items (M1 Foundation) were converted to Issues #2–#13 and closed with a "Delivered by" commit trail.

**Do not bulk-convert upcoming work.** Convert individually as work begins. See decision D16 in `engineering/decisions.md` for the rationale and the distinction between the two paths.

### Working an item end to end

An item moves from the board to Done through four stages. Two skills automate the process; this section describes the workflow so it survives the skills and so a human can follow it manually.

**Start** — `/start-todo-process <item-title>`. Converts the named draft item(s) to Issues, sets Status to **In Progress**, and creates the working branch. Multiple items in one invocation are one unit of work sharing one branch; separate branches means separate invocations.

**Build** — Do the work. Tests are mandatory (rule #2). A new widget also needs a wiki page (see D6), not an `engineering/` file.

**Commit** — `/commit`. Split changes into logical, semantic commits in conventional format.

**Complete** — `/complete-todo-process`. Runs `flutter analyze`, `flutter test`, format check, and the Material/Cupertino invariant; opens the PR with `Closes #N` lines for every linked issue; merges; verifies each issue is closed and the project Status moved to Done; updates the corresponding row in `engineering/milestone-N.md` Status table; deletes the branch.

#### Traps — learned the hard way

- **Nothing sets Status to In Progress.** The project's enabled automations cover *item added*, *item closed*, *pull request merged*, *auto-close issue*, *pull request linked to issue*, and *auto-add sub-issues*. None of them sets In Progress. Skip the start step and an item being actively worked still reads as untouched on the board.
- **You cannot approve your own pull request.** GitHub refuses it and there is no admin override. It is not a blocker here only because neither `main` nor `development` has branch protection — which also means the checks in the **Complete** stage are the only gate on either branch.
- **Do not trust the board automation.** The API does not expose which value each automation writes, so Status must be verified after merging and set by hand if it did not move.
- **Both trackers must move together.** Update the GitHub Project status and the milestone Status table in the same commit.
- **Convert one item at a time.** A previous concurrent run corrupted this project, duplicating an item three times and attaching bodies to the wrong components.

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
- Mirror the `lib/<module>/src/` directory structure under `test/<module>/` (export-only barrels are exempt)
- Test all named constructors and factories independently
- Test edge cases: null-safe fields, empty inputs, boundary values
- Every visual component additionally requires accessibility tests

CI will eventually enforce three gates via Milestone 1 item 9: tests pass, the mirror-file structure check, and a coverage ratchet that never decreases. The ratchet was chosen over a fixed percentage target so it works from the current baseline without backfill, and so untested code naturally penalises itself.

### 3. Use @Preview for visual widgets

For stateless or lightly-stateful widgets, add `@Preview` annotations (Flutter 3.47+) at the bottom of the widget file so it can be previewed without launching a device. Previews use the Flutter widget preview system with `LayrzPreviewTheme` (planned for Milestone 1).

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
- **layrz_ui integration**: `LayrzPreviewTheme` extends `PreviewThemeData` (must extend because the SDK declares it as `abstract base class`, not an interface) with a light variant only

Rules:
- Only add previews for **visual** widgets (skip helpers, extensions, enums, data classes).
- Use `LayrzPreviewTheme.light` as the theme callback once available in M1.
- Add a single `@Preview` annotation for the light theme.
- Each preview function returns the widget directly (no need to wrap in LayrzApp; the theme callback handles it).

### 4. One concern per file — always split, never pile

**Never put multiple unrelated things in a single file.** When a domain grows, split it.

Examples of what belongs in separate files:
- Each widget in its own file under `lib/<domain>/src/`
- Each category of constants in its own file under `lib/constants/src/`
- Each extension target (Color, BuildContext, String…) in its own file under `lib/extensions/src/`
- Data classes, enums, and helpers each in their own file

A domain folder always has:
```
lib/<domain>/
  <domain>.dart       ← barrel, only re-exports
  src/
    <thing_a>.dart
    <thing_b>.dart
```

The barrel file must contain **only** `export` statements — no logic, no classes.

---

## Coding conventions

- **No Material/Cupertino** — use `Container`, `DecoratedBox`, `GestureDetector`, `CustomPaint`, `RichText`, etc. instead.
- **No comments explaining what the code does** — only document *why* when the reason is non-obvious. Arg docs are mandatory (rule #1); inline comments explaining logic are not.
- **Immutable data classes** — annotate with `@immutable`, implement `==` and `hashCode` via `Object.hash`, provide `copyWith`.
- **Theming** — always read colors and styles from `LayrzTheme.of(context)` / `context.theme`. Never hardcode design values inside widgets.
- **Responsive grid** — use the breakpoint constants from `src/constants/grid.dart` (`kExtraSmallGrid`, etc.).
- **Platform checks** — use `LayrzPlatform` from `platform.dart`, not `Platform` from `dart:io` directly.
- **Interaction states** — hover, press, focus, and disabled states must vary colour, border colour, shadow, opacity, and cursor only; never size, border width, padding, margin, or scale. Geometry changes cause flicker and reflow. See decision D15 in `engineering/decisions.md`.
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

Tests live under `test/` and mirror the structure of `lib/`. For example:
- `lib/tokens/src/colors.dart` → `test/tokens/colors_test.dart`
- `lib/theme/src/theme.dart` → `test/theme/theme_test.dart`

---

## Adding a new widget (checklist)

1. Create `lib/<domain>/src/<widget_name>.dart` — one widget per file
2. Create (or update) the barrel `lib/<domain>/<domain>.dart` with only `export` statements
3. Export from `lib/layrz_ui.dart`
4. Document every argument (see rule #1)
5. Write tests in `test/<domain>/<widget_name>_test.dart` (see rule #2)
6. Add `@Preview` annotations at the bottom of the widget file if applicable (see rule #3)
7. Run `flutter analyze` — must be clean
8. Run `flutter test` — must be green
9. Verify no material/cupertino imports crept in

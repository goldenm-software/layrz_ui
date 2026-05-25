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
      app.dart                   # LayrzApp, LayrzApp.router, LayrzThemeMode
  theme/
    theme.dart                   # Barrel
    src/
      theme.dart                 # LayrzTheme (InheritedWidget)
      theme_data.dart            # LayrzThemeData, LayrzTextTheme
  constants/
    constants.dart               # Barrel
    src/
      colors.dart                # kPrimaryColor, kAccentColor, background colors
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

Every new widget, extension, helper, or utility **must** have corresponding tests. No code ships without tests.

- Widgets → `testWidgets` in `test/`
- Pure functions / extensions → `test()` in `test/`
- Mirror the `lib/src/` directory structure under `test/src/`
- Test both light and dark theme variants wherever theming is involved
- Test all named constructors and factories independently
- Test edge cases: null-safe fields, empty inputs, boundary values

### 3. Use WidgetPreview where applicable

For stateless or lightly-stateful widgets, add a `WidgetPreview` at the bottom of the widget file so it can be previewed without launching a device:

```dart
import 'package:flutter/widget_preview.dart';

@widgetPreview
Widget previewMyWidget() => LayrzApp(
  home: MyWidget(color: kPrimaryColor, size: 48),
  theme: LayrzThemeData.light(),
);
```

Rules:
- Only add previews for **visual** widgets (skip helpers, extensions, enums, data classes).
- Each preview must wrap its subject in `LayrzApp` so `LayrzTheme` is available.
- Add a light **and** dark variant when the widget is theme-sensitive.

### 4. One concern per file — always split, never pile

**Never put multiple unrelated things in a single file.** When a domain grows, split it.

Examples of what belongs in separate files:
- Each widget in its own file under `src/<domain>/src/`
- Each category of constants in its own file under `src/constants/`
- Each extension target (Color, BuildContext, String…) in its own file under `src/extensions/`
- Data classes, enums, and helpers each in their own file

A domain folder always has:
```
src/<domain>/
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
- **SDK constraint** — `>=3.8.0 <4.0.0` / Flutter `>=3.29.0`. Do not raise without checking the CI environment.

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

Tests live under `test/` and mirror the structure of `lib/src/`.

---

## Adding a new widget (checklist)

1. Create `lib/src/<domain>/src/<widget_name>.dart` — one widget per file
2. Create (or update) the barrel `lib/src/<domain>/<domain>.dart` with only `export` statements
3. Export from `lib/layrz_ui.dart`
4. Document every argument (see rule #1)
5. Write tests in `test/src/<domain>/<widget_name>_test.dart` (see rule #2)
6. Add a `WidgetPreview` at the bottom of the widget file if applicable (see rule #3)
7. Run `flutter analyze` — must be clean
8. Run `flutter test` — must be green
9. Verify no material/cupertino imports crept in

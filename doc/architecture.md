# Architecture

This document describes how layrz_ui is organized, the patterns used across the codebase, and the design decisions that shape the system.

## The No-Material Invariant

The single most important constraint: **layrz_ui must never import Material or Cupertino.** Anywhere. Ever.

```bash
grep -r "package:flutter/material\|package:flutter/cupertino" lib/
```

This invariant is enforced by:
- **CI guard** (Milestone 1 item 9): CI fails immediately if the invariant is broken
- **Developer awareness**: This document and [CLAUDE.md](../CLAUDE.md) make the consequence clear
- **Dependency audit**: The `[dependencies.md](dependencies.md)` document tracks whether transitive dependencies are Material-coupled

If you need to add a dependency, check [dependencies.md](dependencies.md) first. If it imports Material or Cupertino, it breaks the invariant and cannot be added.

## Module and File Layout

layrz_ui uses **one concern per file** and a consistent barrel-export pattern.

### Standard Structure

Every module under `lib/<module>/` has exactly this layout:

```
lib/<module>/
  <module>.dart              # Barrel — export only, no logic
  src/
    <implementation_1>.dart  # One file per concern
    <implementation_2>.dart
    ...
```

The barrel file contains **only** `export` statements and is the public API. Implementation files live under `src/` and are never imported directly by consumers.

### Current Modules (Milestone 1)

- **app** — `LayrzApp` and `LayrzThemeMode`
- **theme** — `LayrzTheme` (InheritedWidget) and `LayrzThemeData` with `LayrzTextTheme`
- **constants** — Brand colors, breakpoints, durations, app defaults
- **extensions** — Convenience getters on `Color` and `BuildContext`
- **platform** — `LayrzPlatform` enum for runtime platform detection

### When to Add a New Module

Create a new module when:
- You are adding 3+ related files that belong together (e.g., a new component category)
- The module is large enough to benefit from organization (approaching 300+ lines of implementation)
- The concern is distinct from existing modules (e.g., tokens, state, fonts)

Do not create a module for a single widget or utility — add it to the most related existing module instead.

## Theming Architecture: InheritedTheme and the wrap() Fix

### The Problem: Theme Loss Across Boundaries

`LayrzTheme` currently extends plain `InheritedWidget`. This works for the main widget tree, but **fails when widgets cross boundary transitions**:

1. **Overlay boundaries**: Dialogs, tooltips, dropdowns, and menus render into an `Overlay`, which sits outside the normal widget tree. An `InheritedWidget` lookup from inside the overlay fails — the chain is broken.
2. **Route boundaries**: When you push a new route (e.g., `Navigator.push`), the new route's tree is separate. Without special handling, the theme is not propagated.

**Concrete failure mode:**

```dart
// Inside LayrzDialog, which renders via showGeneralDialog():
LayrzButton(
  onTap: () { /* user expects dark theme colors here */ },
  child: Text('Click me'),
)
// But LayrzTheme.of(context) crashes because the context is inside an Overlay,
// outside the LayrzTheme's inheritance chain.
```

### The Solution: Extend InheritedTheme with wrap()

Flutter provides `InheritedTheme` (abstract class in `package:flutter/widgets.dart`) specifically to solve this. Material's `Theme` and Cupertino's `CupertinoTheme` both subclass it.

**How it works:**

```dart
// Design sketch — not current code
abstract class InheritedTheme extends InheritedWidget {
  /// Called by the route system to wrap a widget tree with this theme.
  /// Return a tree that has this theme available to all descendants.
  Widget wrap(BuildContext context, Widget widget);
}
```

When you push a route or show a dialog, the system calls `wrap()` on every `InheritedTheme` in the ancestor chain. The wrapping restores the theme for the new context.

**layrz_ui's implementation (Milestone 1, item 1):**

```dart
// Design sketch
class LayrzTheme extends InheritedTheme {
  final LayrzThemeData data;

  const LayrzTheme({
    required this.data,
    required super.child,
  });

  @override
  Widget wrap(BuildContext context, Widget widget) {
    // Return a new LayrzTheme wrapping the given widget.
    // The route system will call this when entering a new route.
    return LayrzTheme(
      data: data,
      child: widget,
    );
  }

  static LayrzThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayrzTheme>()?.data
        ?? (throw Error());
  }

  @override
  bool updateShouldNotify(LayrzTheme oldWidget) => data != oldWidget.data;
}
```

Once this is done, dialogs, overlays, and new routes automatically preserve the theme. No special handling needed in components.

## LayrzThemeExtension<T>: Custom Component Tokens

### The Problem: No Material, No ThemeExtension<T>

`ThemeExtension<T>` is a Material-only feature (defined in `package:flutter/material.dart`). It allows components to store their own theme data on the theme without modifying the core `ThemeData` class.

Without it, layrz_ui would have two bad choices:
1. Add every component's theme data directly to `LayrzThemeData` (bloats core theme)
2. Let components hardcode their style values (breaks consistency and dark/light switching)

### The Solution: Hand-Rolled Extension Registry

**Milestone 1, item 5** defines `LayrzThemeExtension<T>`, a similar mechanism for Material-free systems:

```dart
// Design sketch
abstract class LayrzThemeExtension<T> {
  /// Return a copy with some fields changed.
  LayrzThemeExtension<T> copyWith();
  
  /// Linearly interpolate between two extensions.
  LayrzThemeExtension<T> lerp(LayrzThemeExtension<T>? other, double t);
}
```

On `LayrzThemeData`:

```dart
// Design sketch
class LayrzThemeData {
  /// Map of extension type → extension instance.
  final Map<Type, LayrzThemeExtension<dynamic>> extensions = {};

  /// Retrieve a custom extension by type.
  T? extension<T extends LayrzThemeExtension<T>>() {
    return extensions[T] as T?;
  }
}
```

**Later components use it like this:**

```dart
// In a button or input widget:
final buttonExtension = LayrzTheme.of(context).extension<LayrzButtonExtension>();
final cornerRadius = buttonExtension?.borderRadius ?? 10.0;
```

Each component defines its own extension class, stores it on the theme if needed, and retrieves it at build time. No core theme bloat. Light and dark themes can have different extensions.

## Widget State Resolution Layer: WidgetState and WidgetStatesController

### The Pattern: Centralized State Management for Interactive Widgets

All interactive components (buttons, inputs, chips, toggles) respond to:
- **pressed** — user is actively tapping/clicking
- **hovered** — pointer is over the widget (desktop/web)
- **focused** — widget has keyboard focus
- **disabled** — widget is disabled (readonly, invisible action, etc.)

Rather than each component independently detecting and storing this state, layrz_ui provides a centralized resolver:

**Milestone 1, item 6** creates `lib/state/` with:

```dart
// Design sketch
class LayrzWidgetStateProperty<T> {
  final T? defaultValue;
  final Map<WidgetState, T> stateValues;

  /// Resolve the value for the given set of states.
  T resolve(Set<WidgetState> states) {
    for (final state in states) {
      if (stateValues.containsKey(state)) return stateValues[state]!;
    }
    return defaultValue!;
  }
}
```

**Usage in a component:**

```dart
// Design sketch
class LayrzButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final Color pressedColor;
  
  // Internally:
  final colorProperty = LayrzWidgetStateProperty<Color>(
    defaultValue: color,
    stateValues: {
      WidgetState.hovered: hoverColor,
      WidgetState.pressed: pressedColor,
    },
  );
}
```

### Open Question: WidgetStateProperty Availability

**Is `WidgetStateProperty` exported from `package:flutter/widgets.dart` in Flutter 3.47?**

The design-agnostic description in the SDK docs suggests it should be. However, if it is Material-only, layrz_ui must implement its own equivalent. This will be clarified during Milestone 1 implementation.

See [flutter-347-audit.md](flutter-347-audit.md) for details on what's available in the SDK.

## Preview Architecture: LayrzPreviewTheme

### The Real API: @Preview and PreviewThemeData

**Milestone 1, item 2** corrects [CLAUDE.md](../CLAUDE.md) rule #3 to document the real widget preview API, which is NOT `@widgetPreview`.

In Flutter 3.47, the preview system is defined in `package:flutter/widget_previews.dart`:

- **Annotation**: `@Preview(name: 'Light', theme: LayrzPreviewTheme.light, brightness: Brightness.light)`
- **Theme type**: `PreviewThemeData` (interface with `apply(BuildContext, Widget)` method)

**layrz_ui's contribution:**

```dart
// Design sketch
class LayrzPreviewTheme implements PreviewThemeData {
  final LayrzThemeData themeData;
  
  const LayrzPreviewTheme(this.themeData);
  
  static final light = LayrzPreviewTheme(LayrzThemeData.light());
  static final dark = LayrzPreviewTheme(LayrzThemeData.dark());

  @override
  Widget apply(BuildContext context, Widget widget) {
    return LayrzTheme(data: themeData, child: widget);
  }
}
```

**Component usage:**

```dart
// Design sketch
import 'package:flutter/widget_previews.dart';

@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
  brightness: Brightness.light,
)
Widget previewLayrzButton() {
  return LayrzButton(
    onTap: () {},
    child: const Text('Click me'),
  );
}

@Preview(
  name: 'Dark',
  theme: LayrzPreviewTheme.dark,
  brightness: Brightness.dark,
)
Widget previewLayrzButtonDark() {
  return LayrzButton(
    onTap: () {},
    child: const Text('Click me'),
  );
}
```

Previews can be viewed inline in supporting IDEs without launching a device.

## How Components Consume Theme

**Rule: Never hardcode design values inside widgets.**

Every color, spacing, duration, and styling value must come from the theme:

```dart
// WRONG
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF001E60),  // Hardcoded! Dark theme doesn't work.
      child: ...,
    );
  }
}

// CORRECT
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = LayrzTheme.of(context);
    return Container(
      color: theme.primaryColor,  // Resolves from light or dark theme.
      child: ...,
    );
  }
}
```

Or use the convenience extension:

```dart
// Also CORRECT
class MyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.theme.primaryColor,  // Same, via BuildContext extension.
      child: ...,
    );
  }
}
```

For colors, use `LayrzTheme.of(context)` or `context.theme`. For more complex tokens (spacing, typography, shadows), use the token system (described in [design-tokens.md](design-tokens.md)).

## Icon and Font Layers

### Icons: layrz_icons Package

Icons come from `layrz_icons` 1.1.0, a pure-Dart package that provides:

- Class `LayrzIcon` (the icon widget)
- Static getters on `LayrzIconsClasses` covering 14,572+ icons across 8 font families
- Families: Material Design Icons, Font Awesome (brands, solid, regular), Solar (bold, broken, linear, outline)

No special setup needed. Use icons directly:

```dart
LayrzIcon(
  icon: LayrzIconsClasses.soloBold.check,
  size: 24,
  color: context.theme.successColor,
)
```

### Fonts: google_fonts (TextStyle API Only)

layrz_ui depends on `google_fonts: ^8.2.1` but **uses TextStyle-returning APIs only**, never the `*TextTheme()` family (which import Material).

**Milestone 1, item 7** defines a `LayrzFontHandler` interface that provides:

```dart
// Design sketch
abstract class LayrzFontHandler {
  /// Get a TextStyle for the given font name and size.
  TextStyle getFont(String fontName, {double? fontSize});
  
  /// Get a TextStyle from a collection.
  TextStyle getFontFromCollection(String collection, String name);
}
```

Implementation uses `GoogleFonts.getFont(name)` to load fonts at runtime by name, supporting dynamic font selection while keeping Material out of the transitive closure.

## Primitives: What We Build On vs. What We Hand-Roll

The Flutter SDK offers many design-agnostic raw widgets. layrz_ui builds on them where they exist, and hand-rolls where they don't.

### Built On (Available in widgets.dart)

- **RawRadio** — Radio button base
- **RawTooltip** — Tooltip mechanics
- **RawMenuAnchor / RawMenuAnchorGroup** — Dropdown/menu positioning
- **RawScrollbar** — Scrollbar without Material theming
- **RawAutocomplete** — Autocomplete base
- **RawMagnifier** — Text selection magnifier
- **RawDialogRoute / showGeneralDialog** — Dialog routing
- **RawKeyboardListener** — Keyboard input
- **ToggleableStateMixin / ToggleablePainter** — State management for toggles (checkbox, switch, radio animations)
- **EditableText / TextSelectionControls** — Text input without Material styling
- **Overlay / OverlayEntry / OverlayPortal / ModalBarrier** — Modal/overlay infrastructure
- **FocusNode / FocusScope / FocusTraversalPolicy** — Focus management
- **Actions / Shortcuts / FocusableActionDetector** — Keyboard action binding
- **PageRoute / PageRouteBuilder / PageTransitionsBuilder** — Custom page transitions
- **InheritedTheme** — Theme inheritance across route/overlay boundaries
- **WidgetState** — State management for interactive widgets
- **Icon / IconTheme / IconData / ImageIcon** — Icon rendering

See [flutter-347-audit.md](flutter-347-audit.md) for the complete inventory and technical details.

### Hand-Rolled (Not Available)

- **LayrzButton** — No `RawButton` exists
- **LayrzCheckbox** — No `RawCheckbox`; build on `ToggleableStateMixin`
- **LayrzSwitch** — No `RawSwitch`; build on `ToggleableStateMixin`
- **LayrzSlider** — No `RawSlider`; custom painting
- **LayrzChip** — No `RawChip`
- **Focus ring** — No focus-ring primitive; custom painting with `FocusNode`

## Summary: Architectural Layers

```
lib/
  layrz_ui.dart                  ← Root barrel
  
  app/                           ← App shell
    app.dart
    src/app.dart                 (LayrzApp, LayrzThemeMode)
  
  theme/                         ← Theme system (core)
    theme.dart
    src/theme.dart               (LayrzTheme extends InheritedTheme [M1 item 1])
    src/theme_data.dart          (LayrzThemeData, LayrzTextTheme)
    src/theme_extension.dart     (LayrzThemeExtension<T> [M1 item 5])
  
  state/                         ← Widget state resolution [M1 item 6]
    state.dart
    src/widget_states_controller.dart
  
  tokens/                        ← Design token system [M1 items 3–4]
    tokens.dart
    src/colors.dart
    src/typography.dart
    src/spacing.dart
    src/radius.dart
    src/shadow.dart
    src/border.dart
    src/motion.dart
    src/tokens.dart
  
  fonts/                         ← Font loading [M1 item 7]
    fonts.dart
    src/font_handler.dart
  
  constants/                     ← Brand defaults
    constants.dart
    src/colors.dart              (Layrz brand colors only)
    src/durations.dart
    src/grid.dart
    src/app.dart
  
  extensions/                    ← Convenience getters
    extensions.dart
    src/color.dart
    src/context.dart
  
  platform/                      ← Platform detection
    platform.dart
    src/platform.dart
  
  (M2–M7 components here)
```

Each module depends only on lower layers. Core theme has no dependencies on any component. This keeps the theme system simple and stable while components are added incrementally.

---

**Last updated**: 2026-08-13

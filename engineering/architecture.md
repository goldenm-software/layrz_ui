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

Every module has exactly this layout:

```
lib/src/<module>/<module>.dart # Per-module barrel — export only, no logic
lib/src/<module>/src/
  <implementation_1>.dart      # One file per concern
  <implementation_2>.dart
  ...
```

The per-module barrel at `lib/src/<module>/<module>.dart` contains **only** `export` statements. Implementation files live under `lib/src/<module>/src/` and are never imported directly by consumers. All modules are exported from the root barrel `lib/layrz_ui.dart`, which is the blessed consumer import. See [decision D26](decisions.md) for the rationale.

### Current Modules (Milestone 1 and Beyond)

- **alerts** — `LayrzAlert`, `LayrzAlertIcon`, alert styling and types
- **app** — `LayrzApp` entry point and app shell
- **buttons** — `LayrzButton` with semantic factories
- **cards** — `LayrzCard` component
- **theme** — `LayrzTheme` (InheritedTheme with wrap()) and `LayrzThemeData`
- **tokens** — Complete design token system: `LayrzColorTokens`, `LayrzTextTheme`, `LayrzSpacingTokens`, `LayrzRadiusTokens`, `LayrzShadowTokens`, `LayrzBorderTokens`, `LayrzMotionTokens`, aggregated in `LayrzTokens`
- **tokenizer** — `LayrzTokenizer` façade providing lookup access to tokens
- **state** — Re-exports of `WidgetState`, `WidgetStateProperty`, and related types from `package:flutter/widgets.dart`
- **fonts** — `LayrzFontHandler` interface with `LayrzGoogleFontsHandler` implementation for runtime font loading
- **constants** — Brand colors, breakpoints, durations, app defaults
- **extensions** — Convenience getters on `Color` and `BuildContext`
- **grid** — `LayrzRow` (responsive 12-column grid container) and `LayrzCol` (column with responsive spans)
- **platform** — `LayrzPlatform` enum for runtime platform detection
- **preview** — `LayrzPreviewTheme` for Flutter 3.47+ widget preview integration
- **tooltips** — `LayrzTooltip` and positioning types

### When to Add a New Module

Create a new module when:
- You are adding 3+ related files that belong together (e.g., a new component category)
- The module is large enough to benefit from organization (approaching 300+ lines of implementation)
- The concern is distinct from existing modules (e.g., tokens, state, fonts)

Do not create a module for a single widget or utility — add it to the most related existing module instead.

## Theming Architecture: InheritedTheme and the wrap() Fix

### The Problem: Theme Loss Across Boundaries

Without proper handling, `InheritedWidget` lookups fail when widgets cross boundary transitions. `LayrzTheme` now extends `InheritedTheme` to solve this problem. This section explains the issue and the solution.

1. **Overlay boundaries**: Dialogs, tooltips, dropdowns, and menus render into an `Overlay`, which sits outside the normal widget tree. An `InheritedWidget` lookup from inside the overlay fails — the chain is broken.
2. **Route boundaries**: When you push a new route (e.g., `Navigator.push`), the new route's tree is separate. Without special handling, the theme is not propagated.

**Concrete failure mode:**

```dart
// Inside LayrzDialog, which renders via showGeneralDialog():
LayrzButton(
  onTap: () { /* user expects theme colors here */ },
  child: Text('Click me'),
)
// Before the fix: LayrzTheme.of(context) would crash because the context is inside
// an Overlay, outside the LayrzTheme's inheritance chain.
// With wrap(): succeeds and theme colors are resolved correctly.
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

**Status**: Implemented in [M1 item 5](milestone-1.md) (`lib/theme/src/theme_extension.dart`).

### The Problem: No Material, No ThemeExtension<T>

`ThemeExtension<T>` is a Material-only feature (defined in `package:flutter/material.dart`). It allows components to store their own theme data on the theme without modifying the core `ThemeData` class.

Without it, layrz_ui would have two bad choices:
1. Add every component's theme data directly to `LayrzThemeData` (bloats core theme)
2. Let components hardcode their style values (breaks consistency and theming)

### The Solution: Hand-Rolled Extension Registry

**Milestone 1, item 5** implements `LayrzThemeExtension<T>`, a similar mechanism for Material-free systems. The key design choice is the self-bounded generic `T extends LayrzThemeExtension<T>`, which makes the type itself the lookup key and ensures type safety:

```dart
/// Base contract for custom component theme data.
abstract class LayrzThemeExtension<T extends LayrzThemeExtension<T>> {
  /// Return the type of this extension (used as the map key).
  Object get type => T;
  
  /// Return a copy with some fields changed.
  T copyWith();
  
  /// Linearly interpolate between two extensions.
  T lerp(covariant LayrzThemeExtension<T>? other, double t);
}
```

On `LayrzThemeData`:

```dart
class LayrzThemeData {
  /// Map of extension type → extension instance.
  final Map<Object, LayrzThemeExtension<dynamic>> extensions;

  /// Retrieve a custom extension by type (asserts if not found).
  T extension<T extends LayrzThemeExtension<T>>() {
    assert(extensions.containsKey(T));
    return extensions[T]! as T;
  }

  /// Retrieve a custom extension by type, returning null if not found.
  T? maybeExtension<T extends LayrzThemeExtension<T>>() {
    return extensions[T] as T?;
  }
}
```

**Usage in M2+ components:**

```dart
// In a button or input widget:
final buttonExtension = LayrzTheme.of(context).maybeExtension<LayrzButtonExtension>();
final cornerRadius = buttonExtension?.borderRadius ?? 10.0;
```

### Key Properties

- **Self-bounded generics make type keys sound**: The constraint `T extends LayrzThemeExtension<T>` prevents type mismatches at the lookup site. You cannot accidentally ask for the wrong type.
- **Extensions are immutable**: Every extension implements `copyWith()` for safe modification and `lerp()` for animations. Themes remain predictable across state changes.
- **Automatic propagation across boundaries**: Because extensions live on `LayrzThemeData` and `LayrzTheme` implements `InheritedTheme.wrap()`, extensions automatically flow through Overlay and route boundaries. No special plumbing needed.
- **No core theme bloat**: Components define their own extension classes in their modules. `LayrzThemeData` stays focused on universal tokens (colors, spacing, typography).

### Design Comparison to Material

Material's `ThemeExtension<T>` uses a similar approach but with slightly different accessor names (`extension<T>()` vs Material's `maybeExtension<T>()`). layrz_ui mirrors the pair convention used by `LayrzTheme` itself: `of()` (asserts) / `maybeOf()` (nullable).

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

### Resolution: WidgetStateProperty is Available

**[M1 item 6](milestone-1.md)** confirmed that `WidgetStateProperty`, `WidgetState`, and the complete state family are exported from `package:flutter/widgets.dart` in Flutter 3.47 and are **material-free**. layrz_ui re-exports them via `lib/state/` without hand-rolling replacements.

See [flutter-347-audit.md](flutter-347-audit.md) for details on what's available in the SDK.

## Preview Architecture: LayrzPreviewTheme

**Status**: Implemented in [M1 item 8](milestone-1.md) (`lib/preview/src/preview_theme.dart` with top-level barrel `lib/preview.dart`). Light theme only; dark mode is out of scope per [decision D7](decisions.md).

### The Real API: @Preview and PreviewThemeData

**Milestone 1, item 2** corrected [CLAUDE.md](../CLAUDE.md) rule #3 to document the real widget preview API, which is NOT `@widgetPreview`.

In Flutter 3.47, the preview system is defined in `package:flutter/widget_previews.dart`:

- **Annotation**: `@Preview(name: 'Light', theme: LayrzPreviewTheme.light)`
- **Theme type**: `PreviewThemeData` (abstract base class, not interface — must be `extends`, not `implements`)

**layrz_ui's contribution** (light theme only):

```dart
/// Preview theme for light mode. Integrates with Flutter 3.47's @Preview annotation system.
final class LayrzPreviewTheme extends PreviewThemeData {
  final LayrzThemeData _themeData;
  
  const LayrzPreviewTheme(this._themeData);
  
  /// Tear-off for use as @Preview(theme: LayrzPreviewTheme.light).
  static PreviewThemeData light() => LayrzPreviewTheme(LayrzThemeData.light());

  @override
  Widget apply(BuildContext context, Widget widget) {
    // Wrap the widget with the full theme hierarchy.
    return LayrzTheme(
      data: _themeData,
      child: DefaultTextStyle(
        style: _themeData.typography.body1,
        child: IconTheme(
          data: _themeData.iconThemeData,
          child: ColoredBox(
            color: _themeData.tokens.colors.background,
            child: widget,
          ),
        ),
      ),
    );
  }
}
```

**Component usage:**

```dart
import 'package:flutter/widget_previews.dart';
import 'package:layrz_ui/preview.dart';

@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzButton() {
  return LayrzButton(
    onTap: () {},
    child: const Text('Click me'),
  );
}
```

Previews can be viewed inline in supporting IDEs without launching a device. The `apply()` method reproduces the full theme nesting that `LayrzApp` uses, ensuring previewed widgets see the same design-token context as production code.

### Top-Level Entrypoint Pattern

Every module has a top-level entrypoint at `lib/<module>.dart`. This design follows the Flutter SDK convention of per-domain imports (e.g., `import 'package:flutter/widgets.dart';`). See [decision D19](decisions.md) for the restructure rationale. The `lib/preview.dart` module uses the same pattern for consistency, though it was originally (D18) designed as an exception to keep preview infrastructure opt-in.

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
      color: theme.colors.primary,  // Resolves from theme tokens.
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
      color: context.theme.colors.primary,  // Same, via BuildContext extension.
      child: ...,
    );
  }
}
```

For colors, use `LayrzTheme.of(context)` or `context.theme`. For more complex tokens (spacing, typography, shadows), use the token system (described in [design-tokens.md](design-tokens.md)).

## Icon and Font Layers

### Icons: flutter_material_design_icons Package (Primary)

The layrz_ui design system renders icons from `flutter_material_design_icons` (^3.1.0), a pure-font package providing Material Design Icons:

- 7,447 icon constants as bare `IconData` (not wrapped)
- Imported as `package:flutter_material_design_icons/flutter_material_design_icons.dart`
- Accessed as `MdiIcons.<name>` (e.g., `MdiIcons.checkCircleOutline`)

No special setup needed. Use icons directly:

```dart
Icon(
  MdiIcons.checkCircleOutline,
  size: 24,
  color: context.theme.colors.success,
)
```

This package is Material-free; it is purely a font and constant library with no Material widgets or design coupling.

### Icons: layrz_icons Package (Legacy, Retained for Future LayrzIconInput)

`layrz_icons` 1.1.0 is no longer the system-wide icon source. It is retained exclusively for the planned `LayrzIconInput` widget, which provides a searchable icon picker browsing the full Solar catalogue:

- Class `LayrzIcon` (the icon widget)
- Static getters on `LayrzIconsClasses` covering 14,572+ icons across 8 font families
- Families: Material Design Icons, Font Awesome (brands, solid, regular), Solar (bold, broken, linear, outline)

See the `LayrzIconInput` documentation for usage in that picker context.

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
  layrz_ui.dart                  ← Root barrel — exports all 14 modules [D26]
  preview.dart                   ← Preview system (deliberate exception; top-level)
  
  src/
    app/
      app.dart                   ← Per-module barrel
      src/
        app.dart                 (LayrzApp)
    
    theme/                       [M1 item 1]
      theme.dart                 ← Per-module barrel
      src/
        theme.dart               (LayrzTheme extends InheritedTheme)
        theme_data.dart          (LayrzThemeData)
        theme_extension.dart     (LayrzThemeExtension<T> [M1 item 5])
    
    preview/                     [M1 item 8]
      preview.dart               ← Per-module barrel
      src/
        preview_theme.dart       (LayrzPreviewTheme extends PreviewThemeData)
    
    state/                       [M1 item 6]
      state.dart                 ← Per-module barrel
      src/
        widget_state.dart        (re-exports from package:flutter/widgets.dart)
    
    tokens/                      [M1 items 3–4]
      tokens.dart                ← Per-module barrel
      src/
        colors.dart
        typography.dart
        spacing.dart
        radius.dart
        shadow.dart
        border.dart
        motion.dart
        tokens.dart
    
    tokenizer/                   [M1 items 3–4]
      tokenizer.dart             ← Per-module barrel
      src/
        tokenizer.dart           (LayrzTokenizer)
    
    fonts/                       [M1 item 7]
      fonts.dart                 ← Per-module barrel
      src/
        font.dart
        font_handler.dart
        google_fonts_handler.dart
    
    constants/
      constants.dart             ← Per-module barrel
      src/
        colors.dart              (Layrz brand colors only)
        durations.dart
        grid.dart
        app.dart
    
    extensions/
      extensions.dart            ← Per-module barrel
      src/
        color.dart
        context.dart
    
    platform/
      platform.dart              ← Per-module barrel
      src/
        platform.dart
    
    grid/                        [M2 grid components]
      grid.dart                  ← Per-module barrel
      src/
        row.dart
        col.dart
    
    buttons/                     [M2 component category example]
      buttons.dart               ← Per-module barrel
      src/
        button.dart
        button_style.dart
    
    (M2–M7 other components here)
```

Each module depends only on lower layers. Core theme has no dependencies on any component. This keeps the theme system simple and stable while components are added incrementally.

**Note on import patterns**: Consumers import the root barrel `import 'package:layrz_ui/layrz_ui.dart';`. Within `lib/`, cross-module imports use the per-module barrel form `import 'package:layrz_ui/src/<module>/<module>.dart';`. See decisions D20 and D26 for rationale.

---

**Last updated**: 2026-08-16 (D26 root barrel restoration and module restructure documentation)

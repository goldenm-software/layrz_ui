# Design Tokens

This document specifies the design token system for layrz_ui — the semantic values (colors, typography, spacing, motion, etc.) that all components use, ensuring consistency across light and dark themes.

## Design Principles

1. **Semantic Over Literal** — Token names reflect *purpose* (primary, danger, success), not color names (blue, red, green). This allows swapping brand colors at runtime without renaming tokens.

2. **Light and Dark** — Every token that depends on brightness (colors, shadows) must resolve differently in light and dark themes. Tokens are never hardcoded to a single color value.

3. **No Hardcoded Values in Components** — All design decisions (colors, spacing, animations) come from tokens. Components never have `const Color(0xFF...)` or `Duration(milliseconds: 150)` inline.

4. **Composability** — Complex tokens (shadows, text styles) are built from simpler ones. Typography combines font family, size, weight, line height; shadows combine blur, spread, color.

5. **Consistency** — All tokens scale proportionally (e.g., spacing uses a base unit of 4px; all multiples are multiples of 4).

## Token Categories and Specifications

### Color Tokens

#### Palette Structure

Colors are organized into three categories:

**1. Semantic Brand Colors**
- `primary` — Primary brand color used for interactive elements, focus states, and prominent calls-to-action
- `accent` — Secondary brand color for emphasis or special states (e.g., warnings, highlights)

**2. Surface and Background**
- `surface` — Card, dialog, and elevated container backgrounds
- `surface2` — Secondary elevated surface (e.g., nested cards, popovers)
- `surface3` — Tertiary elevated surface for deepest nesting
- `background` — Scaffold / canvas background (behind all surfaces)

**3. Text and Foreground**
- `fg1` — Highest contrast text color (labels, body text); used on light backgrounds in light theme
- `fg2` — Medium-high contrast (secondary text, borders)
- `fg3` — Medium contrast (placeholders, disabled text)
- `fg4` — Lowest contrast (hints, very subtle text)

**4. Semantic Status Colors**
- `danger` — Error, destructive action, critical alerts
- `success` — Positive confirmation, valid input, good status
- `warning` — Caution, non-critical alerts
- `info` — Informational, neutral alerts

**5. Structural Colors**
- `divider` — Borders, separators, divider lines
- `overlay` — Scrim / modal backdrop color (semi-transparent)

#### Token Resolution

Colors are accessed via `LayrzTheme.of(context).colors`:

```dart
// Design sketch
class LayrzColorTokens {
  final Color primary;
  final Color accent;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color background;
  final Color fg1;
  final Color fg2;
  final Color fg3;
  final Color fg4;
  final Color danger;
  final Color success;
  final Color warning;
  final Color info;
  final Color divider;
  final Color overlay;
}
```

In a light theme:
- `fg1` = dark navy (high contrast on white surfaces)
- `background` = off-white (#FCFCFC)
- `overlay` = rgba(0, 0, 0, 0.5)

In a dark theme:
- `fg1` = light gray (high contrast on dark surfaces)
- `background` = dark gray (#282828)
- `overlay` = rgba(0, 0, 0, 0.8)

#### Use in Components

```dart
// Design sketch — component using color tokens
class LayrzButton extends StatelessWidget {
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = LayrzTheme.of(context).colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: colors.primary,  // Resolves to Layrz navy in light, Layrz orange in dark
        child: ...,
      ),
    );
  }
}
```

### Typography Tokens

Typography tokens define text scales for all text in the system. They combine font family, size, weight, and line height.

#### Token Structure

```dart
// Design sketch
class LayrzTypographyTokens {
  // Display styles (hero text, splash screens)
  final TextStyle displayLarge;   // 57px
  final TextStyle displayMedium;  // 45px
  final TextStyle displaySmall;   // 36px
  
  // Headline styles (section headings)
  final TextStyle headlineLarge;  // 32px
  final TextStyle headlineMedium; // 28px
  final TextStyle headlineSmall;  // 24px
  
  // Title styles (card titles, dialog titles)
  final TextStyle titleLarge;     // 22px
  final TextStyle titleMedium;    // 16px
  final TextStyle titleSmall;     // 14px
  
  // Body styles (paragraph text, descriptions)
  final TextStyle bodyLarge;      // 16px
  final TextStyle bodyMedium;     // 14px
  final TextStyle bodySmall;      // 12px
  
  // Label styles (buttons, input labels, badges)
  final TextStyle labelLarge;     // 14px
  final TextStyle labelMedium;    // 12px
  final TextStyle labelSmall;     // 11px
}
```

These names mirror Material's TextTheme for familiarity. Font family and color are resolved from theme.

#### Use in Components

```dart
// Design sketch
class LayrzCard extends StatelessWidget {
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = LayrzTheme.of(context);
    return Container(
      color: theme.colors.surface,
      child: Column(
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

### Spacing Tokens

Spacing tokens define a consistent grid for margins, padding, and gaps.

#### Token Structure

```dart
// Design sketch
class LayrzSpacingTokens {
  // Base: 4px grid
  final int sp4 = 4;
  final int sp6 = 6;
  final int sp8 = 8;
  final int sp10 = 10;
  final int sp12 = 12;
  final int sp14 = 14;
  final int sp16 = 16;
  final int sp20 = 20;
  final int sp24 = 24;
  final int sp28 = 28;
  final int sp32 = 32;
  final int sp36 = 36;
  final int sp40 = 40;
  final int sp44 = 44;
  final int sp48 = 48;
}
```

All spacing values are multiples of 4, making them harmonious and easy to reason about.

#### Use in Components

```dart
// Design sketch
class LayrzButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = LayrzTheme.of(context).tokens.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sp16.toDouble(),
        vertical: spacing.sp12.toDouble(),
      ),
      child: ...,
    );
  }
}
```

### Radius Tokens

Radius tokens define border radius values for rounded corners.

#### Token Structure

```dart
// Design sketch
class LayrzRadiusTokens {
  final double r8 = 8.0;
  final double r10 = 10.0;
  final double r12 = 12.0;
  final double r14 = 14.0;
  final double r16 = 16.0;
  final double r20 = 20.0;
  final double r24 = 24.0;
  final double full = 999.0;  // Fully rounded (pill shape)
}
```

#### Use in Components

```dart
// Design sketch
class LayrzCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = LayrzTheme.of(context).tokens.radius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(radius.r12)),
      ),
      child: ...,
    );
  }
}
```

### Shadow and Elevation Tokens

Shadow tokens define drop shadow and elevation definitions. Elevation levels map to shadow properties.

#### Token Structure

```dart
// Design sketch
class LayrzShadowTokens {
  // Elevation level to shadow mapping
  final List<BoxShadow> elevation1;
  final List<BoxShadow> elevation2;
  final List<BoxShadow> elevation3;
  final List<BoxShadow> elevation4;
  final List<BoxShadow> elevation5;
  
  // Each elevation has blur, spread, and color appropriate to light/dark
}
```

Example for light theme:
- `elevation1`: blur 1px, offset (0, 1), color rgba(0,0,0,0.08)
- `elevation3`: blur 8px, offset (0, 3), color rgba(0,0,0,0.12)
- `elevation5`: blur 16px, offset (0, 5), color rgba(0,0,0,0.15)

Dark theme elevations use lighter colors and often stronger blur (backgrounds are darker, so shadows must be more visible).

#### Use in Components

```dart
// Design sketch
class LayrzCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shadows = LayrzTheme.of(context).tokens.shadow;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: shadows.elevation3,
      ),
      child: ...,
    );
  }
}
```

### Border Tokens

Border tokens define stroke widths and border side definitions.

#### Token Structure

```dart
// Design sketch
class LayrzBorderTokens {
  // Stroke widths
  final double stroke1 = 1.0;
  final double stroke2 = 2.0;
  final double stroke3 = 3.0;
  
  // Pre-defined borders (stroke + color)
  final BorderSide light;  // stroke1, divider color
  final BorderSide normal; // stroke2, divider color
  final BorderSide thick;  // stroke3, divider color
}
```

#### Use in Components

```dart
// Design sketch
class LayrzTextInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final borders = LayrzTheme.of(context).tokens.border;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borders.light.color),
      ),
      child: ...,
    );
  }
}
```

### Motion Tokens

Motion tokens define durations and easing curves for animations.

#### Token Structure

```dart
// Design sketch
class LayrzMotionTokens {
  // Standard durations (milliseconds)
  final Duration dHover = Duration(milliseconds: 100);
  final Duration dPress = Duration(milliseconds: 80);
  final Duration dTransition = Duration(milliseconds: 200);
  final Duration dPageTransition = Duration(milliseconds: 250);
  final Duration dDialog = Duration(milliseconds: 300);
  
  // Standard curves
  final Curve easing = Curves.easeInOut;
  final Curve easingEnter = Curves.easeOut;
  final Curve easingExit = Curves.easeIn;
}
```

#### Use in Components

```dart
// Design sketch
class LayrzButton extends StatefulWidget {
  @override
  State<LayrzButton> createState() => _LayrzButtonState();
}

class _LayrzButtonState extends State<LayrzButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final motion = LayrzTheme.of(context).tokens.motion;
    _controller = AnimationController(
      duration: motion.dHover,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = LayrzTheme.of(context).tokens.motion;
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _controller, curve: motion.easing),
        ),
        child: ...,
      ),
    );
  }
}
```

## Token Composition and LayrzThemeData

All token categories are aggregated into a top-level `LayrzTokens` class:

```dart
// Design sketch
class LayrzTokens {
  final LayrzColorTokens colors;
  final LayrzTypographyTokens typography;
  final LayrzSpacingTokens spacing;
  final LayrzRadiusTokens radius;
  final LayrzShadowTokens shadow;
  final LayrzBorderTokens border;
  final LayrzMotionTokens motion;
}
```

And `LayrzThemeData` holds a `tokens` field:

```dart
// Design sketch
class LayrzThemeData {
  final LayrzTokens tokens;
  // ... other fields
}
```

Component access pattern:

```dart
// Preferred: all tokens via LayrzTheme.of(context).tokens.*
final tokens = LayrzTheme.of(context).tokens;
final color = tokens.colors.primary;
final spacing = tokens.spacing.sp16;

// Or via extension:
final color = context.theme.tokens.colors.primary;
```

## State Variants: Hover, Press, Focus, Disabled

Tokens can vary by widget state (hover, press, focus, disabled). Rather than defining a separate token for each state, use `WidgetStateProperty<T>` to map states to token values:

```dart
// Design sketch
class LayrzButton extends StatefulWidget {
  // ...
  final colorProperty = LayrzWidgetStateProperty<Color>(
    defaultValue: tokens.colors.primary,
    stateValues: {
      WidgetState.hovered: tokens.colors.primary.withValues(alpha: 0.9),
      WidgetState.pressed: tokens.colors.primary.withValues(alpha: 0.8),
      WidgetState.disabled: tokens.colors.fg4,
    },
  );
}
```

This avoids explosion of token definitions while keeping state behavior consistent.

## Optional: material_color_utilities for Tonal Palettes

The `material_color_utilities` package (pure Dart, no Material import) provides tonal palette generation. A single brand color can be expanded into a full tonal palette:

```dart
// Design sketch — optional feature
import 'package:material_color_utilities/material_color_utilities.dart';

// Given kPrimaryColor (#001E60), generate 5 tonal levels
final brandColor = kPrimaryColor;
final scheme = CorePalette.of(brandColor.value);
final tonal2 = Color(scheme.primary.tone(20));  // Darkest
final tonal3 = Color(scheme.primary.tone(30));
// ...
final tonal7 = Color(scheme.primary.tone(70));  // Lightest
```

**Tradeoff**: Using material_color_utilities increases dependency bloat and adds an indirect Material coupling (though the package itself is Material-free). **Decision deferred** — document as optional, evaluate during M2 when components need tonal variants.

## Relationship to lib/constants and lib/extensions

### lib/constants/src/colors.dart

Currently holds only four constants:
- `kPrimaryColor` — Layrz brand blue (#001E60)
- `kAccentColor` — Layrz brand orange (#FF8200)
- `kLightBackgroundColor` — Off-white (#FCFCFC)
- `kDarkBackgroundColor` — Dark gray (#282828)

**After Milestone 1:** These remain, but serve as **brand defaults only**. The token system (via `LayrzColorTokens`) provides the actual runtime values. `LayrzThemeData.light()` and `LayrzThemeData.dark()` read from these constants to initialize color tokens.

### lib/constants/src/durations.dart

Currently holds two constants:
- `kHoverDuration` — 100ms
- `kPageTransitionDuration` — 250ms

**After Milestone 1:** These become part of `LayrzMotionTokens`. The constants remain as defaults but are superseded by the token system.

### Extensions (context.dart)

Currently provides:
- `context.theme` — shortcut for `LayrzTheme.of(context)`
- `context.isDark` — true if dark theme
- `context.primaryColor` — shortcut for `theme.primaryColor`
- `context.titleStyle`, `subtitleStyle`, `bodyStyle` — pre-computed text styles

**After Milestone 1:** No change to existing accessors, but new accessors will be added as needed for common token access patterns.

## Comparison with layrz_theme Tokenizer

### layrz_theme Tokenizer Structure (Reference)

layrz_theme provides five tokenizer extensions:
- `ColorTokenizer` — hardcoded semantic colors (info, success, warning, error, etc.)
- `ShadowTokenizer` — elevation → shadow mapping
- `RadiusTokenizer` — border radius constants
- `SpacerTokenizer` — spacing constants
- `BorderTokenizer` — stroke widths and border definitions

Each is accessed via `LayrzTokenizer.of(context).info`, etc.

### How layrz_ui Differs

1. **Immutable vs. Extensions** — layrz_theme uses method-based extensions for lazy evaluation. layrz_ui uses immutable token classes (simpler, faster, testable without context)
2. **Unified Access** — layrz_theme has five separate tokenizer extensions. layrz_ui aggregates all into `LayrzTokens`, accessed via `LayrzTheme.of(context).tokens.*`
3. **Theme-Scoped** — layrz_theme can return different tokens based on context (e.g., `if (isDarkTheme) return darkColor`). layrz_ui builds theme-specific token instances at `LayrzThemeData.light()` / `.dark()` creation time
4. **No Material Coupling** — layrz_theme's `ColorTokenizer` reads from `Theme.of(context)` (Material). layrz_ui provides its own complete token set independent of Material
5. **Type Safety** — layrz_theme uses map-based access (e.g., `tokenizer['color.primary']`). layrz_ui uses strongly-typed field access (e.g., `tokens.colors.primary`)

## Naming Conventions

Token names follow these rules:

- **Category prefix** — Color tokens: `colors.primary`, spacing: `spacing.sp16`, radius: `radius.r12`
- **Semantic names** — Never use color values in names (not `colors.blue`, use `colors.primary`)
- **Consistent scaling** — Spacing multiples of 4, radius multiples of 2, durations in explicit units (ms)
- **Abbreviated suffixes** — `sp` for spacing, `r` for radius, `d` for duration
- **fg1–fg4** — Foreground levels for text, ordered by contrast (1 = highest)
- **surface / surface2 / surface3** — Elevation levels for nested containers

## Acceptance Criteria

For Milestone 1, the token system must meet these criteria:

- All color tokens defined for light and dark themes
- Typography tokens cover all text styles (display, headline, title, body, label)
- Spacing tokens are multiples of 4 (4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48)
- Radius tokens include common sizes and a "full" option
- Shadow tokens define at least 3 elevation levels per theme
- Border tokens include stroke widths and pre-defined borders
- Motion tokens cover hover, press, transition, page transition, dialog durations
- Test: `LayrzTheme.of(context).tokens.colors.primary` resolves correctly in light and dark
- Test: `LayrzTheme.of(context).tokens.spacing.sp8` returns 8
- Test: All tokens are immutable and never null
- Documentation: Every token has a comment explaining its purpose and usage

---

**Last updated**: 2026-08-13

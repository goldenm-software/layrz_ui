# Design Tokens

This document specifies the design token system for layrz_ui — the semantic values (colors, typography, spacing, motion, etc.) that all components use, ensuring consistency in the light theme (dark mode is out of scope).

## Design Principles

1. **Semantic Over Literal** — Token names reflect *purpose* (primary, danger, success), not color names (blue, red, green). This allows swapping brand colors at runtime without renaming tokens.

2. **Light Theme Only** — All tokens define light theme values. Dark mode is out of scope for now. This choice was made knowingly; adding dark mode later will require revisiting every token and every component that assumed a single palette.

3. **No Hardcoded Values in Components** — All design decisions (colors, spacing, animations) come from tokens. Components never have `const Color(0xFF...)` or `Duration(milliseconds: 150)` inline.

4. **Composability** — Complex tokens (shadows, text styles) are built from simpler ones. Typography combines font family, size, weight, line height; shadows combine blur, spread, color.

5. **Consistency** — All tokens scale proportionally. The spacing scale (4, 6, 8, 10, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48) is optimized for common layout needs, balancing grid alignment with practical sizing.

## Token Categories and Specifications

### Color Tokens

#### Palette Structure

Colors are organized into three categories:

**1. Semantic Brand Colors**
- `primary` — Primary brand color used for interactive elements, focus states, and prominent calls-to-action

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
  // Brand colors
  final Color primary;
  
  // Surface colors (elevation levels)
  final Color background;
  final Color surface;
  final Color surface2;
  final Color surface3;
  
  // Text and foreground colors
  final Color fg1;  // Highest contrast
  final Color fg2;  // Medium-high contrast
  final Color fg3;  // Medium contrast
  final Color fg4;  // Lowest contrast
  
  // Semantic status colors
  final Color danger;
  final Color success;
  final Color warning;
  final Color info;
  
  // Contextual and structural colors
  final Color contextual;  // Neutral/informational (avoids 'context' naming collision)
  final Color divider;
  final Color overlay;
  
  // Opacity for tonal fills
  final double tonalOpacity;
}
```

In the light theme:
- `fg1` = dark navy (high contrast on white surfaces)
- `background` = off-white (#FCFCFC)
- `overlay` = rgba(0, 0, 0, 0.5)
- `tonalOpacity` = 0.2 (20% alpha for filledTonal variant fills)

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
        color: colors.primary,  // Resolves to Layrz brand color in light theme
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
  // Base unit: 8 pixels
  final double base = 8.0;
  
  // Spacing scale
  final double sp4 = 4.0;
  final double sp6 = 6.0;
  final double sp8 = 8.0;
  final double sp10 = 10.0;
  final double sp12 = 12.0;
  final double sp14 = 14.0;
  final double sp16 = 16.0;
  final double sp20 = 20.0;
  final double sp24 = 24.0;
  final double sp28 = 28.0;
  final double sp32 = 32.0;
  final double sp36 = 36.0;
  final double sp40 = 40.0;
  final double sp44 = 44.0;
  final double sp48 = 48.0;
  
  // Convenience accessors
  Size get spacingSize => Size(base, base);
  Widget get sizedBox => SizedBox.fromSize(size: spacingSize);
  EdgeInsets get margin => EdgeInsets.all(base);
  EdgeInsets get reducedMargin => EdgeInsets.all(base / 2);
  EdgeInsets get padding => EdgeInsets.all(base);
}
```

All spacing values are stored as `double`, allowing fine-grained pixel control and eliminating the need for `.toDouble()` conversions at call sites.

#### Use in Components

```dart
// Design sketch
class LayrzButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = LayrzTheme.of(context).tokens.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sp16,
        vertical: spacing.sp12,
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
  // Base radius
  final double base = 8.0;
  
  // Predefined radii
  final double r8 = 8.0;
  final double r10 = 10.0;
  final double r12 = 12.0;
  final double r14 = 14.0;
  final double r16 = 16.0;
  final double r20 = 20.0;
  final double r24 = 24.0;
  final double full = 999.0;  // Fully rounded (pill shape)
  
  // Convenience accessors
  BorderRadius get borderRadius => BorderRadius.circular(base);
  BorderRadius innerRadius({
    required double outerRadius,
    required double spacer,
  });  // Computes visually consistent inner radius for nested containers
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

Shadow tokens define drop shadow and elevation definitions. Elevation levels (0–5) map to shadows using a mathematical algorithm to ensure consistency.

#### Token Structure and Algorithm

```dart
// Design sketch
class LayrzShadowTokens {
  // Elevation level getters
  final List<BoxShadow> elevation1;
  final List<BoxShadow> elevation2;
  final List<BoxShadow> elevation3;
  final List<BoxShadow> elevation4;
  final List<BoxShadow> elevation5;
  
  // Builder method for custom elevation and radius
  BoxDecoration elevation({
    double elevation = 1,
    double? radius,
    Color? color,
    bool reverse = false,
    bool hideOnElevationZero = false,
  });
}
```

The algorithm computes shadow properties from elevation level:
- **Opacity**: `0.06 + (0.12 - 0.06) * t` where `t = clamp(elevation, 0, 5) / 5`
  - elevation 0: opacity 0.06
  - elevation 5: opacity 0.12
- **Blur radius**: `3 * elevation + 2`
  - elevation 1: blur 5
  - elevation 3: blur 11
  - elevation 5: blur 17
- **Spread**: always 0
- **Offset**: `Offset(0, elevation - 1)` pixels down (reversible for pressed states)
  - elevation 1: offset (0, 0)
  - elevation 3: offset (0, 2)
  - elevation 5: offset (0, 4)
- **Outline at elevation 0**: 1px border with outlineColor (black at 10% opacity), unless `hideOnElevationZero` is true

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
  // Base stroke width
  final double base = 1.5;
  
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
  final LayrzTextTheme typography;
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

The `material_color_utilities` package (pure Dart, no Material import) provides tonal palette generation for light theme. A single brand color can be expanded into a full tonal palette:

```dart
// Design sketch — optional feature
import 'package:material_color_utilities/material_color_utilities.dart';

// Given kPrimaryColor (#001E60), generate tonal levels for light theme
final brandColor = kPrimaryColor;
final scheme = CorePalette.of(brandColor.value);
final tonal3 = Color(scheme.primary.tone(30));
final tonal5 = Color(scheme.primary.tone(50));
final tonal7 = Color(scheme.primary.tone(70));  // Lightest
```

**Tradeoff**: Using material_color_utilities increases dependency bloat and adds an indirect Material coupling (though the package itself is Material-free). **Decision deferred** — document as optional, evaluate during M2 when components need tonal variants.

**Note**: Since dark mode is out of scope, material_color_utilities now only needs to generate a light tonal palette.

## Relationship to lib/constants and lib/extensions

### lib/constants/src/colors.dart

Currently holds two constants:
- `kPrimaryColor` — Layrz brand blue (#001E60)
- `kLightBackgroundColor` — Off-white (#FCFCFC)

**After Milestone 1:** These remain as **brand defaults only**. The token system (via `LayrzColorTokens`) provides the actual runtime values. `LayrzThemeData.light()` reads from these constants to initialize color tokens. The accent color was removed entirely (see decision D14). Dark mode has been removed from scope entirely (see decision D7).

### lib/constants/src/durations.dart

Currently holds two constants:
- `kHoverDuration` — 100ms
- `kPageTransitionDuration` — 250ms

**After Milestone 1:** These become part of `LayrzMotionTokens`. The constants remain as defaults but are superseded by the token system.

### Extensions (context.dart)

Currently provides:
- `context.theme` — shortcut for `LayrzTheme.of(context)`
- `context.primaryColor` — shortcut for `theme.primaryColor`
- `context.titleStyle`, `subtitleStyle`, `bodyStyle` — pre-computed text styles

**After Milestone 1:** No change to existing accessors, but new accessors will be added as needed for common token access patterns. Dark-theme conditionals have been removed (light mode only).

## Comparison with layrz_theme Tokenizer

### layrz_theme Tokenizer Structure (Reference)

layrz_theme provides a `LayrzTokenizer` class accessed via `LayrzTokenizer.of(context)`, backed by five extension getters:
- `ColorTokenizer` — semantic color getters (primary, success, warning, danger, info, error)
- `ShadowTokenizer` — elevation → shadow mapping
- `RadiusTokenizer` — border radius constants
- `SpacerTokenizer` — spacing constants
- `BorderTokenizer` — stroke widths and border definitions

Each extension reads from Material's `Theme.of(context)` when possible, with layrz_theme-specific semantic values otherwise.

### How layrz_ui Differs

1. **Immutable Token Storage** — layrz_theme's tokenizer is context-bound; tokens are computed on-demand via getters. layrz_ui stores tokens as immutable classes on `LayrzThemeData`, making them testable without `BuildContext` and overridable per theme instance.

2. **Two Access Paths** — layrz_ui provides both:
   - Direct: `context.theme.tokens.colors.primary`
   - Façade: `LayrzTokenizer.of(context).primary`
   The façade preserves call-site compatibility with layrz_theme consuming apps, easing migration.

3. **Unified Token Aggregate** — layrz_theme has five separate tokenizer extensions (each a different `extension on Theme`). layrz_ui aggregates all into a single `LayrzTokens` instance, with `LayrzTokenizer` as a thin stateless wrapper. This prevents drift between access paths.

4. **No Material Coupling** — layrz_theme's `ColorTokenizer` reads from Material's `Theme.of(context)`. layrz_ui is Material-free: it defines its own complete token set, with `LayrzThemeData.light()` as the single wiring point where defaults are set.

5. **Type Safety and Discoverability** — layrz_theme uses method-based access (`tokenizer.primary`, `tokenizer.success`, etc.). layrz_ui uses field-based access on immutable classes (`tokens.colors.primary`), which enables IDE autocomplete and compile-time error checking. No map-based string keys.

6. **Semantic Color Renaming** — layrz_theme used `error` and `danger` as separate colors with slightly different meanings. layrz_ui consolidates to `danger` only, clarifying the semantic intent. Similarly, the old `context` color (which collided with `BuildContext` in widget code) is renamed `contextual`.

## Naming Conventions

Token names follow these rules:

- **Category prefix** — Color tokens: `colors.primary`, spacing: `spacing.sp16`, radius: `radius.r12`
- **Semantic names** — Never use color values in names (not `colors.blue`, use `colors.primary`)
- **Consistent scaling** — Spacing from 4 to 48 pixels (not all multiples), radius from 8 to 24 pixels, durations in explicit units (ms)
- **Abbreviated suffixes** — `sp` for spacing, `r` for radius, `d` for duration
- **fg1–fg4** — Foreground levels for text, ordered by contrast (1 = highest)
- **surface / surface2 / surface3** — Elevation levels for nested containers

## Acceptance Criteria

For Milestone 1, the token system must meet these criteria:

- All color tokens defined for light theme, including `primary`, `surface` (three levels), `fg1`–`fg4`, `danger`, `success`, `warning`, `info`, `contextual`, `divider`, `overlay`, and `tonalOpacity`
- Typography tokens (`LayrzTextTheme`) cover all 15 text styles: display (3 sizes), headline (3), title (3), body (3), label (3)
- Spacing tokens are defined as `double` and include: `base`, `sp4`, `sp6`, `sp8`, `sp10`, `sp12`, `sp14`, `sp16`, `sp20`, `sp24`, `sp28`, `sp32`, `sp36`, `sp40`, `sp44`, `sp48`, plus convenience accessors (`spacingSize`, `sizedBox`, `margin`, `reducedMargin`, `padding`)
- Radius tokens include: `base`, `r8`, `r10`, `r12`, `r14`, `r16`, `r20`, `r24`, `full` (pill shape), plus `borderRadius` getter and `innerRadius()` method
- Shadow tokens define 5 elevation levels (1–5) using the mathematical algorithm, plus a builder method for custom elevation and radius
- Border tokens include: `base`, `stroke1`, `stroke2`, `stroke3`, and pre-defined borders (`light`, `normal`, `thick`)
- Motion tokens cover hover, press, transition, page transition, dialog durations, plus standard easing curves
- Test: `LayrzTheme.of(context).tokens.colors.primary` resolves correctly in light theme
- Test: `LayrzTokenizer.of(context).primary` also resolves to the same value (both access paths in sync)
- Test: `LayrzTheme.of(context).tokens.spacing.sp8` returns 8.0 as a `double`
- Test: All tokens are immutable and never null
- Documentation: Every token has a doc comment explaining its purpose and usage

---

**Last updated**: 2026-08-13

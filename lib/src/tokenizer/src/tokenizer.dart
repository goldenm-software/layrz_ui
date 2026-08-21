import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/theme/theme.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable tokenizer providing semantic access to the layrz_ui design system tokens.
///
/// [LayrzTokenizer] is the primary facade for accessing design tokens in widgets.
/// It provides both group getters (for accessing all tokens of a category) and
/// flat shortcuts (for common single-value access patterns).
///
/// There are two main access patterns:
///
/// 1. **Group getters** for accessing all tokens in a category:
///    ```dart
///    final colors = tokenizer.colors;
///    final spacing = tokenizer.spacingTokens;
///    final motion = tokenizer.motion;
///    ```
///
/// 2. **Flat shortcuts** for common single-value access (matching layrz_theme):
///    ```dart
///    final primary = tokenizer.primary;
///    final baseSpacing = tokenizer.spacing;
///    final borderWidth = tokenizer.borderWidth;
///    ```
///
/// Note on naming: [spacingTokens] is the group getter to avoid collision with
/// the flat [spacing] scalar shortcut, which returns the base spacing unit.
/// Similarly, [radiusTokens] avoids collision with [radius].
@immutable
class LayrzTokenizer {
  /// The immutable token set backing this tokenizer.
  final LayrzTokens tokens;

  /// Creates a new [LayrzTokenizer] with the given token set.
  const LayrzTokenizer(this.tokens);

  /// Resolves the tokens from the nearest [LayrzTheme] ancestor.
  ///
  /// Throws an assertion error if there is no [LayrzTheme] ancestor.
  static LayrzTokenizer of(BuildContext context) {
    return LayrzTokenizer(LayrzTheme.of(context).tokens);
  }

  /// Resolves the tokens from the nearest [LayrzTheme] ancestor, or null if none exists.
  static LayrzTokenizer? maybeOf(BuildContext context) {
    final themeData = LayrzTheme.maybeOf(context);
    return themeData != null ? LayrzTokenizer(themeData.tokens) : null;
  }

  // ===== GROUP GETTERS =====
  // These return the full token category objects. Named to avoid collision with
  // flat shortcuts (e.g., spacingTokens vs. spacing).

  /// All color tokens (brand, surface, foreground, semantic, structural).
  LayrzColorTokens get colors => tokens.colors;

  /// All typography tokens (15 text styles: display, headline, title, body, label).
  LayrzTextTheme get typography => tokens.typography;

  /// All spacing tokens (base unit plus 15 predefined values).
  ///
  /// Named [spacingTokens] to avoid collision with the [spacing] scalar shortcut.
  LayrzSpacingTokens get spacingTokens => tokens.spacing;

  /// All radius tokens (base unit plus 8 predefined values, including pill).
  ///
  /// Named [radiusTokens] to avoid collision with the [radius] scalar shortcut.
  LayrzRadiusTokens get radiusTokens => tokens.radius;

  /// All shadow tokens (elevation levels 0–5 with computed blur and opacity).
  ///
  /// Named [shadowTokens] to avoid collision with the [shadow] method shortcut.
  LayrzShadowTokens get shadowTokens => tokens.shadow;

  /// All border tokens (stroke widths and pre-built border sides).
  LayrzBorderTokens get border => tokens.border;

  /// All motion tokens (durations and easing curves).
  LayrzMotionTokens get motion => tokens.motion;

  /// All breakpoint tokens (band thresholds for responsive design).
  LayrzBreakpointTokens get breakpointTokens => tokens.breakpoints;

  // ===== FLAT SHORTCUTS FOR COLOR TOKENS =====

  /// Primary brand color used for interactive elements and prominent actions.
  Color get primary => tokens.colors.primary;

  /// Semantic color for positive confirmations and good status.
  Color get success => tokens.colors.success;

  /// Semantic color for cautions and non-critical alerts.
  Color get warning => tokens.colors.warning;

  /// Semantic color for errors, destructive actions, and critical alerts.
  Color get danger => tokens.colors.danger;

  /// Semantic color for informational and neutral alerts.
  Color get info => tokens.colors.info;

  /// Contextual color used for neutral status and informational elements.
  Color get contextual => tokens.colors.contextual;

  /// Alpha value applied to tonal/filledTonal fills.
  double get tonalOpacity => tokens.colors.tonalOpacity;

  // ===== FLAT SHORTCUTS FOR SPACING TOKENS =====

  /// Base spacing unit (default 8 pixels).
  ///
  /// Use [spacingTokens] to access all spacing values (sp4, sp8, sp16, etc.).
  double get spacing => tokens.spacing.sp2;

  /// [EdgeInsets] with all sides set to [spacing].
  EdgeInsets get margin => tokens.spacing.mg2;

  /// [EdgeInsets] with all sides set to half of [spacing].
  EdgeInsets get reducedMargin => tokens.spacing.mg1;

  /// [EdgeInsets] with all sides set to [spacing].
  EdgeInsets get padding => tokens.spacing.pd2;

  /// A [SizedBox] with width and height set to spacing level 2 (8 pixels).
  Widget get sizedBox => SizedBox.square(dimension: tokens.spacing.sp2);

  // ===== FLAT SHORTCUTS FOR RADIUS TOKENS =====

  /// Base radius value (default 8 pixels).
  ///
  /// Use [radiusTokens] to access all radius values (r8, r12, r16, etc.).
  double get radius => tokens.radius.r2;

  /// [BorderRadius] with all corners set to [radius].
  BorderRadius get borderRadius => tokens.radius.br2;

  /// Computes a visually consistent inner radius for nested borders.
  ///
  /// See [LayrzRadiusTokens.innerRadius] for details.
  BorderRadius innerRadius({
    required double outerRadius,
    required double spacer,
  }) => tokens.radius.innerRadius(outerRadius: outerRadius, spacer: spacer);

  // ===== FLAT SHORTCUTS FOR SHADOW TOKENS =====

  /// Generates a [BoxDecoration] with elevation-based shadow.
  ///
  /// See [LayrzShadowTokens.elevation] for details on parameters and behavior.
  BoxDecoration shadow({
    double elevation = 1,
    double? radius,
    Color? color,
    Color? shadowColor,
    bool reverse = false,
    bool hideOnElevationZero = false,
  }) => tokens.shadow.elevation(
    elevation: elevation,
    radius: radius,
    color: color,
    shadowColor: shadowColor,
    reverse: reverse,
    hideOnElevationZero: hideOnElevationZero,
  );

  // ===== FLAT SHORTCUTS FOR BORDER TOKENS =====

  /// Base border width (default 1.5 pixels).
  ///
  /// Use [border] to access all border tokens (stroke1, stroke2, stroke3, light, normal, thick).
  double get borderWidth => tokens.border.base;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LayrzTokenizer && runtimeType == other.runtimeType && tokens == other.tokens;

  @override
  int get hashCode => runtimeType.hashCode ^ tokens.hashCode;
}

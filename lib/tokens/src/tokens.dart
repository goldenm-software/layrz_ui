import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/fonts/fonts.dart';

import 'border.dart';
import 'colors.dart';
import 'motion.dart';
import 'radius.dart';
import 'shadow.dart';
import 'spacing.dart';
import 'typography.dart';

/// Immutable aggregate of all design tokens for the layrz_ui design system.
///
/// [LayrzTokens] holds all semantic color, typography, spacing, radius, shadow,
/// border, and motion tokens. It is the single source of truth for design values
/// and is typically accessed via [LayrzTheme.of(context).tokens] once the theme
/// integration is complete.
///
/// The [LayrzTokens.light] factory is the single wiring point where derived tokens
/// are seeded consistently: [LayrzShadowTokens] is seeded with [LayrzColorTokens.surface]
/// and [LayrzRadiusTokens.base], [LayrzBorderTokens] is seeded with [LayrzColorTokens.divider],
/// and [LayrzTextTheme] is constructed with [LayrzColorTokens.fg1] as the text color.
@immutable
class LayrzTokens {
  /// All color tokens (brand, surface, foreground, semantic, structural).
  final LayrzColorTokens colors;

  /// All typography tokens (15 text styles: display, headline, title, body, label).
  final LayrzTextTheme typography;

  /// All spacing tokens (base unit plus 15 predefined values).
  final LayrzSpacingTokens spacing;

  /// All radius tokens (base unit plus 8 predefined values, including pill).
  final LayrzRadiusTokens radius;

  /// All shadow tokens (elevation levels 0–5 with computed blur and opacity).
  final LayrzShadowTokens shadow;

  /// All border tokens (stroke widths and pre-built border sides).
  final LayrzBorderTokens border;

  /// All motion tokens (durations and easing curves).
  final LayrzMotionTokens motion;

  /// Creates a new [LayrzTokens] with all token categories explicitly set.
  const LayrzTokens({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.shadow,
    required this.border,
    required this.motion,
  });

  /// Light theme tokens using Layrz brand defaults.
  ///
  /// Wires all derived tokens consistently:
  /// - [LayrzColorTokens.light] is seeded with [primaryColor]
  /// - [LayrzShadowTokens] is seeded with the resulting [colors.surface] and [radius.base]
  /// - [LayrzBorderTokens] is seeded with [colors.divider]
  /// - [LayrzTextTheme.defaults] is constructed with [colors.fg1] as the text color
  ///   and the provided font specifications
  ///
  /// This factory ensures that color palette, shadows, borders, and typography
  /// are never inconsistent with each other.
  ///
  /// Note: This factory takes [LayrzFont] objects, not string names. For the convenience
  /// of accepting a string [fontName] and wrapping it into a Google Font, use
  /// [LayrzThemeData.light] instead, which is the public API entry point.
  ///
  /// Parameters:
  ///   - [primaryColor]: The primary brand color (default: [kPrimaryColor]).
  ///   - [titleFont]: The font used for display, headline, and title styles.
  ///   - [bodyFont]: The font used for body and label styles.
  ///   - [fontHandler]: The handler that resolves fonts and preloads their bytes.
  ///     Defaults to [LayrzGoogleFontsHandler], ensuring fonts load from Google Fonts.
  factory LayrzTokens.light({
    Color primaryColor = kPrimaryColor,
    LayrzFont titleFont = kLayrzFont,
    LayrzFont bodyFont = kLayrzFont,
    LayrzFontHandler fontHandler = const LayrzGoogleFontsHandler(),
  }) {
    // Build color tokens first — they seed other tokens
    final colorTokens = LayrzColorTokens.light(
      primary: primaryColor,
    );

    // Build spacing and radius (independent of colors)
    const spacingTokens = LayrzSpacingTokens();
    const radiusTokens = LayrzRadiusTokens();

    // Build derived tokens seeded from colors and radius
    final shadowTokens = LayrzShadowTokens(
      surfaceColor: colorTokens.surface,
      baseRadius: radiusTokens.base,
    );

    final borderTokens = LayrzBorderTokens(dividerColor: colorTokens.divider);

    // Build typography seeded from colors and font settings
    final typographyTokens = LayrzTextTheme.defaults(
      textColor: colorTokens.fg1,
      titleFont: titleFont,
      bodyFont: bodyFont,
      fontHandler: fontHandler,
    );

    // Motion is independent
    const motionTokens = LayrzMotionTokens();

    return LayrzTokens(
      colors: colorTokens,
      typography: typographyTokens,
      spacing: spacingTokens,
      radius: radiusTokens,
      shadow: shadowTokens,
      border: borderTokens,
      motion: motionTokens,
    );
  }

  /// Returns a copy of this tokens object with the given token categories replaced.
  LayrzTokens copyWith({
    LayrzColorTokens? colors,
    LayrzTextTheme? typography,
    LayrzSpacingTokens? spacing,
    LayrzRadiusTokens? radius,
    LayrzShadowTokens? shadow,
    LayrzBorderTokens? border,
    LayrzMotionTokens? motion,
  }) {
    return LayrzTokens(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      shadow: shadow ?? this.shadow,
      border: border ?? this.border,
      motion: motion ?? this.motion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTokens &&
          runtimeType == other.runtimeType &&
          colors == other.colors &&
          typography == other.typography &&
          spacing == other.spacing &&
          radius == other.radius &&
          shadow == other.shadow &&
          border == other.border &&
          motion == other.motion;

  @override
  int get hashCode => Object.hash(colors, typography, spacing, radius, shadow, border, motion);
}

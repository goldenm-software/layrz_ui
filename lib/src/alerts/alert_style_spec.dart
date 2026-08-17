import 'package:flutter/widgets.dart';

import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';

import 'alert_style.dart';

/// Immutable specification of visual properties for a [LayrzAlert] in a given style.
///
/// A [LayrzAlertStyleSpec] holds only paint properties: colors for background,
/// border, icon chip, text, and icons. It is computed by [resolve] from a style,
/// tokens, and accent color.
@immutable
class LayrzAlertStyleSpec {
  /// The fill color of the alert background.
  final Color backgroundColor;

  /// The color of the alert border.
  final Color borderColor;

  /// The width of the alert border in logical pixels.
  final double borderWidth;

  /// The fill color of the icon chip container (for non-filledIcon styles).
  ///
  /// For [LayrzAlertStyle.filledIcon], the icon chip background is the accent color
  /// (left panel), not this field.
  final Color iconChipBackground;

  /// The color of the icon glyph.
  final Color iconColor;

  /// The color of the title text.
  final Color titleColor;

  /// The color of the description text.
  final Color bodyColor;

  /// Creates a new [LayrzAlertStyleSpec].
  const LayrzAlertStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.iconChipBackground,
    required this.iconColor,
    required this.titleColor,
    required this.bodyColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzAlertStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? iconChipBackground,
    Color? iconColor,
    Color? titleColor,
    Color? bodyColor,
  }) {
    return LayrzAlertStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      iconChipBackground: iconChipBackground ?? this.iconChipBackground,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      bodyColor: bodyColor ?? this.bodyColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAlertStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          iconChipBackground == other.iconChipBackground &&
          iconColor == other.iconColor &&
          titleColor == other.titleColor &&
          bodyColor == other.bodyColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    iconChipBackground,
    iconColor,
    titleColor,
    bodyColor,
  );

  /// Resolves a [LayrzAlertStyleSpec] from a style, accent color, tokens, and interaction state.
  ///
  /// [style] determines which visual treatment to apply (e.g., layrz, filledTonal, filled).
  /// [accent] is the primary color for the alert (semantic color or custom).
  /// [tokens] provides design values like surface colors, borders, and opacity rules.
  /// [isInteractive] indicates whether the alert has an [onTap] callback. When true,
  ///   opaque backgrounds are applied to prevent shadows from bleeding through
  ///   translucent or transparent fills. When false, original fills are preserved.
  static LayrzAlertStyleSpec resolve({
    required LayrzAlertStyle style,
    required Color accent,
    required LayrzTokens tokens,
    required bool isInteractive,
  }) {
    final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);
    final contrast = accent.contrastColor;

    switch (style) {
      case LayrzAlertStyle.layrz:
        return LayrzAlertStyleSpec(
          backgroundColor: tokens.colors.surface,
          borderColor: tonal,
          borderWidth: tokens.border.base,
          iconChipBackground: tonal,
          iconColor: accent,
          titleColor: tokens.colors.fg1,
          bodyColor: tokens.colors.fg2,
        );

      case LayrzAlertStyle.filledTonal:
        // For interactive alerts, composite the translucent tint into an opaque colour
        // to prevent shadows from bleeding through. For inert alerts, keep translucency.
        final backgroundColor = isInteractive ? Color.alphaBlend(tonal, tokens.colors.surface) : tonal;
        return LayrzAlertStyleSpec(
          backgroundColor: backgroundColor,
          borderColor: const Color(0x00000000),
          borderWidth: 0.0,
          iconChipBackground: const Color(0x00000000),
          iconColor: accent,
          titleColor: accent,
          bodyColor: accent,
        );

      case LayrzAlertStyle.filled:
        return LayrzAlertStyleSpec(
          backgroundColor: accent,
          borderColor: accent,
          borderWidth: tokens.border.base,
          iconChipBackground: const Color(0x00000000),
          iconColor: contrast,
          titleColor: contrast,
          bodyColor: contrast,
        );

      case LayrzAlertStyle.outlined:
        // For interactive alerts, use opaque surface background to prevent shadows
        // from bleeding through. For inert alerts, keep full transparency.
        final backgroundColor = isInteractive ? tokens.colors.surface : const Color(0x00000000);
        return LayrzAlertStyleSpec(
          backgroundColor: backgroundColor,
          borderColor: accent,
          borderWidth: tokens.border.base,
          iconChipBackground: const Color(0x00000000),
          iconColor: accent,
          titleColor: accent,
          bodyColor: accent,
        );

      case LayrzAlertStyle.filledIcon:
        return LayrzAlertStyleSpec(
          backgroundColor: tokens.colors.surface,
          borderColor: const Color(0x00000000),
          borderWidth: 0.0,
          iconChipBackground: accent,
          iconColor: contrast,
          titleColor: tokens.colors.fg1,
          bodyColor: tokens.colors.fg2,
        );
    }
  }
}

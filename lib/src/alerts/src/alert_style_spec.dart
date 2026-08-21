import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

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

  /// The fill color of the icon chip container.
  ///
  /// Not used by [LayrzAlert] since both remaining styles are split-panel;
  /// this field is retained for API stability.
  final Color iconChipBackground;

  /// The background color of the left panel in split-panel layouts.
  ///
  /// All [LayrzAlertStyle] values are split-panel, so this field is always used
  /// to define the left panel's background color.
  final Color leftPanelColor;

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
    required this.leftPanelColor,
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
    Color? leftPanelColor,
    Color? iconColor,
    Color? titleColor,
    Color? bodyColor,
  }) {
    return LayrzAlertStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      iconChipBackground: iconChipBackground ?? this.iconChipBackground,
      leftPanelColor: leftPanelColor ?? this.leftPanelColor,
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
          leftPanelColor == other.leftPanelColor &&
          iconColor == other.iconColor &&
          titleColor == other.titleColor &&
          bodyColor == other.bodyColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    iconChipBackground,
    leftPanelColor,
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
        // Split-panel layout: tonal left panel (soft background) with solid accent border.
        // Icon is accent at full strength for severity signal.
        // For interactive alerts, flatten the tonal left panel to prevent shadows
        // from bleeding through the translucent fill.
        final leftPanel = isInteractive ? tonal.flattenOn(tokens.colors.sf2) : tonal;
        return LayrzAlertStyleSpec(
          backgroundColor: tokens.colors.sf2,
          borderColor: accent,
          borderWidth: tokens.border.base,
          iconChipBackground: const Color(0x00000000),
          leftPanelColor: leftPanel,
          iconColor: accent,
          titleColor: tokens.colors.fg1,
          bodyColor: tokens.colors.fg2,
        );

      case LayrzAlertStyle.filledIcon:
        // Split-panel layout: solid accent left panel with solid accent border.
        // Icon uses contrast color for high visibility on the strong background.
        return LayrzAlertStyleSpec(
          backgroundColor: tokens.colors.sf2,
          borderColor: accent,
          borderWidth: tokens.border.base,
          iconChipBackground: const Color(0x00000000),
          leftPanelColor: accent,
          iconColor: contrast,
          titleColor: tokens.colors.fg1,
          bodyColor: tokens.colors.fg2,
        );
    }
  }
}

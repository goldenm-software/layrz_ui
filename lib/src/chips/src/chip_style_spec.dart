import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'chip_style.dart';

/// Immutable specification of visual properties for a [LayrzChip] in a given style.
///
/// A [LayrzChipStyleSpec] holds only paint properties: colors for background,
/// border, and content. It is computed by [resolve] from a style, tokens, and
/// accent color. Since chips are static (no interaction states), the spec is
/// a pure function of style and accent.
@immutable
class LayrzChipStyleSpec {
  /// The fill color of the chip background.
  final Color backgroundColor;

  /// The color of the chip border.
  final Color borderColor;

  /// The width of the chip border in logical pixels.
  final double borderWidth;

  /// The color of the chip content (label and icons).
  final Color contentColor;

  /// Creates a new [LayrzChipStyleSpec].
  const LayrzChipStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.contentColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzChipStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? contentColor,
  }) {
    return LayrzChipStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      contentColor: contentColor ?? this.contentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzChipStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          contentColor == other.contentColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    contentColor,
  );

  /// Resolves a [LayrzChipStyleSpec] from a style, accent color, and tokens.
  ///
  /// [style] determines which visual treatment to apply (filled, outlined, filledTonal).
  /// [accent] is the primary color for the chip (semantic color or custom).
  /// [tokens] provides design values like surface colors, borders, and opacity rules.
  static LayrzChipStyleSpec resolve({
    required LayrzChipStyle style,
    required Color accent,
    required LayrzTokens tokens,
  }) {
    final contrast = accent.contrastColor;

    switch (style) {
      case LayrzChipStyle.filled:
        return LayrzChipStyleSpec(
          backgroundColor: accent,
          borderColor: const Color(0x00000000),
          borderWidth: 0,
          contentColor: contrast,
        );

      case LayrzChipStyle.outlined:
        return LayrzChipStyleSpec(
          backgroundColor: const Color(0x00000000),
          borderColor: accent,
          borderWidth: tokens.border.stroke1,
          contentColor: accent,
        );
    }
  }

  /// Resolves the color for a delete icon in a given state.
  ///
  /// The delete icon uses the content color in normal and hovered states,
  /// and slightly darkened/adjusted in the pressed state to provide tactile feedback.
  static Color resolveDeleteIconColor({
    required Color contentColor,
    required bool isPressed,
  }) {
    if (isPressed) {
      // On press, darken the icon slightly for tactile feedback (no opacity change).
      return contentColor.withOpacityValue(0.8);
    }
    return contentColor;
  }
}

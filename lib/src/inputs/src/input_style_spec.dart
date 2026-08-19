import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a [LayrzTextInput] in a given interaction state.
///
/// A [LayrzInputStyleSpec] holds only paint properties: fill color, border color, border width,
/// text color, and whether to use a dashed border. It is computed by [resolve] from interaction
/// states and tokens.
@immutable
class LayrzInputStyleSpec {
  /// The fill color of the input background.
  final Color backgroundColor;

  /// The color of the input border.
  final Color borderColor;

  /// The width of the input border in logical pixels.
  final double borderWidth;

  /// The color of the input text.
  final Color textColor;

  /// Whether the border should be rendered as dashed (true) or solid (false).
  final bool isDashed;

  /// Creates a new [LayrzInputStyleSpec].
  const LayrzInputStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.isDashed,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzInputStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? textColor,
    bool? isDashed,
  }) {
    return LayrzInputStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      textColor: textColor ?? this.textColor,
      isDashed: isDashed ?? this.isDashed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzInputStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          textColor == other.textColor &&
          isDashed == other.isDashed;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    textColor,
    isDashed,
  );

  /// Resolves a [LayrzInputStyleSpec] from interaction states and tokens.
  ///
  /// **State precedence:** disabled > readOnly > error > pressed > hover/focused > default
  ///
  /// | State | Fill | Border (always 1.5) | Text | Dashed |
  /// |---|---|---|---|---|
  /// | rest | `surface2` | transparent | `fg1` | false |
  /// | hover | `surface3` | transparent | `fg1` | false |
  /// | focus | `surface2` | `colors.primary` | `fg1` | false |
  /// | error | `colors.danger.shade50` | `colors.danger` | `fg1` | false |
  /// | disabled | `surface2` | `divider` | `fg4` | true |
  /// | read-only | `surface2` | `divider` | `fg1` | false |
  ///
  /// Geometry (height, padding, border width) is byte-identical across states and must not
  /// be affected by this method (per decision D15).
  static LayrzInputStyleSpec resolve({
    required Set<WidgetState> states,
    required LayrzTokens tokens,
    required bool hasErrors,
    bool readOnly = false,
  }) {
    final isDisabled = states.contains(WidgetState.disabled);

    // Precedence: disabled > readOnly > error > pressed > hover/focused > default
    if (isDisabled) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg4,
        isDashed: true,
      );
    }

    if (readOnly) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );
    }

    if (hasErrors) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.danger.shade50,
        borderColor: tokens.colors.danger,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );
    }

    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);
    final isFocused = states.contains(WidgetState.focused);

    if (isFocused) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.primary,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );
    }

    if (isPressed || isHovered) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface3,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );
    }

    // Default state
    return LayrzInputStyleSpec(
      backgroundColor: tokens.colors.surface2,
      borderColor: const Color(0x00000000),
      borderWidth: tokens.border.base,
      textColor: tokens.colors.fg1,
      isDashed: false,
    );
  }
}

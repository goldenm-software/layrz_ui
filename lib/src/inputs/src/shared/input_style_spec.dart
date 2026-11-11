import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a [LayrzTextInput] in a given interaction state.
///
/// A [LayrzInputStyleSpec] holds only paint properties: fill color, border color, border width,
/// and text color. It is computed by [resolve] from interaction states and tokens.
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

  /// Creates a new [LayrzInputStyleSpec].
  const LayrzInputStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzInputStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? textColor,
  }) {
    return LayrzInputStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      textColor: textColor ?? this.textColor,
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
          textColor == other.textColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    textColor,
  );

  /// Resolves a [LayrzInputStyleSpec] from interaction states and tokens.
  ///
  /// **State precedence:** disabled > readOnly > error > pressed > hover/focused > default
  ///
  /// Fills come from [LayrzTokens.input] ([LayrzInputColorTokens]):
  ///
  /// | State | Fill | Border (always 1.5) | Text |
  /// |---|---|---|---|
  /// | rest | `input.idle` | transparent | `fg1` |
  /// | hover | `hoverOverlay` over `input.idle` | transparent | `fg1` |
  /// | pressed | `pressedOverlay` over `input.idle` | transparent | `fg1` |
  /// | focus | `input.focused` | `colors.primary` | `colors.primary` |
  /// | error | `input.error` | `colors.danger` | `colors.danger` |
  /// | error + hover/pressed | overlay over `input.error` | `colors.danger` | `colors.danger` |
  /// | disabled | `input.disabled` | transparent | `fg4` |
  /// | read-only | `input.idle` | transparent | `fg1` |
  ///
  /// Hover and pressed are translucent overlays composited on top of the current base fill, so
  /// they never depend on a specific background color.
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
    final input = tokens.input;

    // Precedence: disabled > readOnly > error > pressed > hover/focused > default
    if (isDisabled) {
      return LayrzInputStyleSpec(
        backgroundColor: input.disabled,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg4,
      );
    }

    if (readOnly) {
      return LayrzInputStyleSpec(
        backgroundColor: input.idle,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );
    }

    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);
    final isFocused = states.contains(WidgetState.focused);

    if (hasErrors) {
      final base = input.error;
      final fill = isPressed
          ? Color.alphaBlend(input.pressedOverlay, base)
          : isHovered
          ? Color.alphaBlend(input.hoverOverlay, base)
          : base;
      return LayrzInputStyleSpec(
        backgroundColor: fill,
        borderColor: tokens.colors.danger,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.danger,
      );
    }

    if (isFocused) {
      return LayrzInputStyleSpec(
        backgroundColor: input.focused,
        borderColor: tokens.colors.primary,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.primary,
      );
    }

    if (isPressed || isHovered) {
      return LayrzInputStyleSpec(
        backgroundColor: Color.alphaBlend(isPressed ? input.pressedOverlay : input.hoverOverlay, input.idle),
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );
    }

    return LayrzInputStyleSpec(
      backgroundColor: input.idle,
      borderColor: const Color(0x00000000),
      borderWidth: tokens.border.base,
      textColor: tokens.colors.fg1,
    );
  }
}

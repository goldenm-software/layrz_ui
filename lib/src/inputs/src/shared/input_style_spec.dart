import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
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
  /// | State | Fill | Border (always 1.5) | Text |
  /// |---|---|---|---|
  /// | rest | `surface2` | transparent | `fg1` |
  /// | hover | `surface3` | transparent | `fg1` |
  /// | focus | `surface2` | `colors.primary` | `fg1` |
  /// | error | tonal `colors.danger` over `sf2` | `colors.danger` | `colors.danger` |
  /// | disabled | `surface2` | transparent | `fg4` |
  /// | read-only | `surface2` | transparent | `fg1` |
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
        backgroundColor: tokens.colors.sf2,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg4,
      );
    }

    if (readOnly) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );
    }

    if (hasErrors) {
      // The error fill differs by theme. On light it is a fixed near-white pink
      // (#FFEBEE) — the historical value, and lighter than any danger-over-surface
      // blend can reach, so it is a literal here rather than a derivation. On dark
      // that pale wash is invisible, so dark uses a tonal danger tint over the
      // resting surface instead. This single spec is the only place the error fill
      // is resolved, so the literal lives here alone.
      final backgroundColor = tokens.brightness == Brightness.dark
          ? tokens.colors.danger.withOpacityValue(0.16).flattenOn(tokens.colors.sf2)
          : const Color(0xFFFFEBEE);
      return LayrzInputStyleSpec(
        backgroundColor: backgroundColor,
        borderColor: tokens.colors.danger,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.danger,
      );
    }

    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);
    final isFocused = states.contains(WidgetState.focused);

    if (isFocused) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: tokens.colors.primary,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.primary,
      );
    }

    if (isPressed || isHovered) {
      return LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf3,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );
    }

    // Default state
    return LayrzInputStyleSpec(
      backgroundColor: tokens.colors.sf2,
      borderColor: const Color(0x00000000),
      borderWidth: tokens.border.base,
      textColor: tokens.colors.fg1,
    );
  }
}

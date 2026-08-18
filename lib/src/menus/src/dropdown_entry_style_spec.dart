import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Immutable specification of visual properties for a [LayrzDropdownEntry] in a given interaction state.
///
/// A [LayrzDropdownEntryStyleSpec] holds only paint properties: colors for background,
/// label, and icon. It is computed by [resolve] from interaction states, tokens, and accent color.
@immutable
class LayrzDropdownEntryStyleSpec {
  /// The background fill color of the entry.
  final Color backgroundColor;

  /// The text color of the entry label.
  final Color labelColor;

  /// The color of the icon glyph (if present).
  final Color iconColor;

  /// Creates a new [LayrzDropdownEntryStyleSpec].
  const LayrzDropdownEntryStyleSpec({
    required this.backgroundColor,
    required this.labelColor,
    required this.iconColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzDropdownEntryStyleSpec copyWith({
    Color? backgroundColor,
    Color? labelColor,
    Color? iconColor,
  }) {
    return LayrzDropdownEntryStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      labelColor: labelColor ?? this.labelColor,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzDropdownEntryStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          labelColor == other.labelColor &&
          iconColor == other.iconColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    labelColor,
    iconColor,
  );

  /// Resolves a [LayrzDropdownEntryStyleSpec] from interaction states and tokens.
  ///
  /// [enabled] determines whether the entry is interactive.
  /// [states] provides the current interaction state set (hovered, pressed, focused, etc.).
  /// [tokens] provides design values like colors, opacity rules, and radii.
  ///
  /// Backgrounds use neutral surface colors, never accent tints. The color semantic (if any)
  /// is carried by the entry's optional color dot, not by the row background. Text and icons
  /// remain fg1 across all enabled states; only disabled state changes them to fg3.
  ///
  /// Resting backgrounds are opaque [surface] to prevent dark-flash artifacts when animating
  /// to [surface2] on hover (opaque-to-opaque interpolation avoids lerping through black).
  ///
  /// Precedence: disabled > pressed > hovered/focused > default.
  static LayrzDropdownEntryStyleSpec resolve({
    required bool enabled,
    required Set<WidgetState> states,
    required LayrzTokens tokens,
  }) {
    // Disabled takes precedence over all other states
    if (!enabled) {
      return LayrzDropdownEntryStyleSpec(
        backgroundColor: tokens.colors.surface,
        labelColor: tokens.colors.fg3,
        iconColor: tokens.colors.fg3,
      );
    }

    // Pressed state — uses surface3 for a deeper neutral highlight
    if (states.contains(WidgetState.pressed)) {
      return LayrzDropdownEntryStyleSpec(
        backgroundColor: tokens.colors.surface3,
        labelColor: tokens.colors.fg1,
        iconColor: tokens.colors.fg1,
      );
    }

    // Hovered or focused state — uses surface2 for a light neutral highlight
    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      return LayrzDropdownEntryStyleSpec(
        backgroundColor: tokens.colors.surface2,
        labelColor: tokens.colors.fg1,
        iconColor: tokens.colors.fg1,
      );
    }

    // Default state — opaque surface background matches the panel, normal text
    return LayrzDropdownEntryStyleSpec(
      backgroundColor: tokens.colors.surface,
      labelColor: tokens.colors.fg1,
      iconColor: tokens.colors.fg1,
    );
  }
}

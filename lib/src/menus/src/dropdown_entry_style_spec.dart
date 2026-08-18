import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
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

  /// Resolves a [LayrzDropdownEntryStyleSpec] from interaction states, tokens, and colors.
  ///
  /// [enabled] determines whether the entry is interactive.
  /// [states] provides the current interaction state set (hovered, pressed, focused, etc.).
  /// [tokens] provides design values like colors, opacity rules, and radii.
  /// [accent] is the primary color swatch for the entry (default primary or custom for destructive entries).
  ///
  /// Precedence: disabled > pressed > hovered/focused > default.
  static LayrzDropdownEntryStyleSpec resolve({
    required bool enabled,
    required Set<WidgetState> states,
    required LayrzTokens tokens,
    required LayrzColorSwatch accent,
  }) {
    // Disabled takes precedence over all other states
    if (!enabled) {
      return LayrzDropdownEntryStyleSpec(
        backgroundColor: const Color(0x00000000),
        labelColor: tokens.colors.fg3,
        iconColor: tokens.colors.fg3,
      );
    }

    // Pressed state
    if (states.contains(WidgetState.pressed)) {
      return LayrzDropdownEntryStyleSpec(
        backgroundColor: accent.shade100,
        labelColor: accent.shade700,
        iconColor: accent.shade700,
      );
    }

    // Hovered or focused state
    if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
      final tonal = accent.shade500.withOpacityValue(tokens.colors.tonalOpacity);
      final flattenedBackground = tonal.flattenOn(tokens.colors.surface);

      return LayrzDropdownEntryStyleSpec(
        backgroundColor: flattenedBackground,
        labelColor: tokens.colors.fg1,
        iconColor: tokens.colors.fg1,
      );
    }

    // Default state
    return LayrzDropdownEntryStyleSpec(
      backgroundColor: const Color(0x00000000),
      labelColor: tokens.colors.fg1,
      iconColor: tokens.colors.fg1,
    );
  }
}

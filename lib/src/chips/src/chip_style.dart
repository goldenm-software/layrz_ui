/// Enumeration of visual style variants for [LayrzChip].
///
/// Each variant represents a distinct visual treatment combining fill and border
/// properties. Chips are static labels with no interactive state changes.
enum LayrzChipStyle {
  /// Solid fill with accent color, no border.
  ///
  /// The background uses the full accent color at maximum opacity.
  /// Content color contrasts with the background.
  filled,

  /// Outlined only, no fill, accent-colored border.
  ///
  /// The background is transparent and the border provides visual definition.
  /// Content color matches the accent.
  outlined,

  /// Subtle tonal fill at [LayrzTokens.colors.tonalOpacity], no border.
  ///
  /// The background uses the accent color with reduced opacity for a softer look.
  /// Content color matches the accent.
  filledTonal;

  /// Whether this style renders a visible border.
  ///
  /// Only [outlined] has a border; [filled] and [filledTonal] do not.
  bool get hasBorder => switch (this) {
    outlined => true,
    _ => false,
  };

  /// Whether this style uses a tonal (semi-transparent) background fill.
  ///
  /// Only [filledTonal] uses reduced opacity; [filled] and [outlined] do not.
  bool get isTonal => switch (this) {
    filledTonal => true,
    _ => false,
  };
}

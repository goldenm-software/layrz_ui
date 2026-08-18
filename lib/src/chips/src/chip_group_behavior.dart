/// Enumeration of layout behaviors for [LayrzChipGroup].
///
/// Determines how chips are arranged and how overflow is handled when the
/// group width is constrained.
enum LayrzChipGroupBehavior {
  /// Chips render on a single horizontal row that scrolls when they overflow.
  ///
  /// This is the default behavior — provides unlimited horizontal scrolling
  /// space without requiring a finite max-width constraint.
  none,

  /// Chips are clamped to the available width; the remainder collapses into a trailing `+N` chip.
  ///
  /// When the available width cannot fit all chips, visible chips are shown up to the
  /// constraint, and any remaining chips are collapsed into a single `+N` chip whose
  /// tooltip lists the hidden labels. The `N` is clamped to 1–9.
  ///
  /// This behavior requires a finite max-width constraint; [LayrzChipGroup] will assert
  /// if [maxWidth] is infinite.
  compact,
}

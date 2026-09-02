/// Enumeration of visual style variants for [LayrzButton].
///
/// Each variant represents a distinct visual treatment combining fill, border,
/// and shadow properties. Variants are paired with Fab (floating action button)
/// equivalents that differ only in layout (square vs. rectangular).
enum LayrzButtonStyle {
  /// Solid opaque accent fill, no border, no shadow.
  ///
  /// Used for actions that feel prominent or primary. Visual hierarchy comes
  /// from the solid fill alone — the fill ladder darkens on hover and press.
  /// Content color contrasts with background.
  filled,

  /// Fab variant of [filled] — identical styling, square layout.
  filledFab,

  /// Outlined only, no fill or shadow, primary accent border.
  ///
  /// Used for secondary actions that must coexist with primary actions.
  /// Border provides visual definition without fill.
  outlined,

  /// Fab variant of [outlined] — identical styling, square layout.
  outlinedFab,

  /// No fill, no border, no shadow — accent-coloured content only.
  ///
  /// Used for the lowest-emphasis actions, where even an outline would be
  /// too heavy. This is the replacement for the removed tonal styles.
  text,

  /// Fab variant of [text] — identical styling, square layout.
  textFab;

  /// Whether this style is a floating action button (Fab) variant.
  ///
  /// Fab variants differ from their base style only in layout—they are always
  /// square and icon-only, rendered at [kLayrzButtonHeight] × [kLayrzButtonHeight].
  bool get isFab => switch (this) {
    filledFab || outlinedFab || textFab => true,
    _ => false,
  };

  /// Whether this style renders a visible border.
  ///
  /// Bordered styles use the accent color and help define the button's edges
  /// when fill is minimal or absent.
  bool get hasBorder => switch (this) {
    outlined || outlinedFab => true,
    _ => false,
  };

  /// Returns the Fab (square, icon-only) variant of this style.
  ///
  /// Maps non-Fab styles to their Fab counterparts:
  /// - [filled] → [filledFab]
  /// - [outlined] → [outlinedFab]
  /// - [text] → [textFab]
  ///
  /// For an already-Fab style, returns itself unchanged (identity-safe).
  /// This getter enables semantic factories to honour [isFab] by applying
  /// this transformation when needed.
  LayrzButtonStyle get asFab => switch (this) {
    filled => filledFab,
    filledFab => filledFab,
    outlined => outlinedFab,
    outlinedFab => outlinedFab,
    text => textFab,
    textFab => textFab,
  };
}

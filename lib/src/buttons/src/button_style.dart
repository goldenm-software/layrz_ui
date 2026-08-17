/// Enumeration of visual style variants for [LayrzButton].
///
/// Each variant represents a distinct visual treatment combining fill, border,
/// and shadow properties. Variants are paired with Fab (floating action button)
/// equivalents that differ only in layout (square vs. rectangular).
enum LayrzButtonStyle {
  /// Solid fill with primary color and elevation shadow, no border.
  ///
  /// Used for actions that feel "raised" or prominent. Shadow depth provides
  /// visual hierarchy. Content color contrasts with background.
  elevated,

  /// Fab variant of [elevated] — identical styling, square layout.
  elevatedFab,

  /// Outlined only, no fill or shadow, primary accent border.
  ///
  /// Used for secondary actions that must coexist with primary actions.
  /// Border provides visual definition without fill.
  outlined,

  /// Fab variant of [outlined] — identical styling, square layout.
  outlinedFab,

  /// Subtle tonal fill at [kLayrzButtonOutlinedTonalOpacity], primary accent border.
  ///
  /// Combines outlined and tonal aesthetics for flexible secondary actions.
  outlinedTonal,

  /// Fab variant of [outlinedTonal] — identical styling, square layout.
  outlinedTonalFab;

  /// Whether this style is a floating action button (Fab) variant.
  ///
  /// Fab variants differ from their base style only in layout—they are always
  /// square and icon-only, rendered at [kLayrzButtonHeight] × [kLayrzButtonHeight].
  bool get isFab => switch (this) {
    elevatedFab || outlinedFab || outlinedTonalFab => true,
    _ => false,
  };

  /// Whether this style uses a tonal (semi-transparent) background fill.
  ///
  /// Tonal styles reduce visual weight by applying opacity to the accent color
  /// background rather than using a fully opaque color.
  bool get isTonal => switch (this) {
    outlinedTonal || outlinedTonalFab => true,
    _ => false,
  };

  /// Whether this style renders a visible border.
  ///
  /// Bordered styles use the accent color and help define the button's edges
  /// when fill is minimal or absent.
  bool get hasBorder => switch (this) {
    outlined || outlinedFab || outlinedTonal || outlinedTonalFab => true,
    _ => false,
  };

  /// Whether this style includes an elevation shadow.
  ///
  /// Shadowed styles use [LayrzTokens.shadow.elevation1] to create visual depth.
  bool get hasShadow => switch (this) {
    elevated || elevatedFab => true,
    _ => false,
  };

  /// Returns the Fab (square, icon-only) variant of this style.
  ///
  /// Maps non-Fab styles to their Fab counterparts:
  /// - [elevated] → [elevatedFab]
  /// - [outlined] → [outlinedFab]
  /// - [outlinedTonal] → [outlinedTonalFab]
  ///
  /// For an already-Fab style, returns itself unchanged (identity-safe).
  /// This getter enables semantic factories to honour [isFab] by applying
  /// this transformation when needed.
  LayrzButtonStyle get asFab => switch (this) {
    elevated => elevatedFab,
    elevatedFab => elevatedFab,
    outlined => outlinedFab,
    outlinedFab => outlinedFab,
    outlinedTonal => outlinedTonalFab,
    outlinedTonalFab => outlinedTonalFab,
  };
}

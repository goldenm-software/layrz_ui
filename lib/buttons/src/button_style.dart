/// Enumeration of visual style variants for [LayrzButton].
///
/// Each variant represents a distinct visual treatment combining fill, border,
/// and shadow properties. Variants are paired with Fab (floating action button)
/// equivalents that differ only in layout (square vs. rectangular).
enum LayrzButtonStyle {
  /// Solid fill with primary color, no border or shadow.
  ///
  /// Used for primary actions that demand attention. Content color is derived
  /// from the background color for contrast.
  filled,

  /// Fab variant of [filled] — identical styling, square layout.
  filledFab,

  /// Solid fill with primary color and elevation shadow, no border.
  ///
  /// Used for actions that feel "raised" or prominent. Shadow depth provides
  /// visual hierarchy. Content color contrasts with background.
  elevated,

  /// Fab variant of [elevated] — identical styling, square layout.
  elevatedFab,

  /// Subtle tonal fill at [LayrzTokens.colors.tonalOpacity], primary accent color, no border.
  ///
  /// The primary action for most contexts. Lower visual weight than [filled]
  /// while remaining clear and tappable.
  filledTonal,

  /// Fab variant of [filledTonal] — identical styling, square layout.
  filledTonalFab,

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
  outlinedTonalFab,

  /// Fully transparent background and border, content in accent color, no shadow.
  ///
  /// The lowest-emphasis button style. Used for tertiary or minimal-weight actions.
  /// Hover and press states add a subtle tonal fill for feedback.
  text,

  /// Fab variant of [text] — identical styling, square layout.
  ///
  /// Icon-only square button at [kLayrzButtonHeight] × [kLayrzButtonHeight].
  /// The label supplies the tooltip and accessible name.
  fab;

  /// Whether this style is a floating action button (Fab) variant.
  ///
  /// Fab variants differ from their base style only in layout—they are always
  /// square and icon-only, rendered at [kLayrzButtonHeight] × [kLayrzButtonHeight].
  bool get isFab => switch (this) {
    filledFab || elevatedFab || filledTonalFab || outlinedFab || outlinedTonalFab || fab => true,
    _ => false,
  };

  /// Whether this style uses a tonal (semi-transparent) background fill.
  ///
  /// Tonal styles reduce visual weight by applying opacity to the accent color
  /// background rather than using a fully opaque color.
  bool get isTonal => switch (this) {
    filledTonal || filledTonalFab || outlinedTonal || outlinedTonalFab => true,
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
}

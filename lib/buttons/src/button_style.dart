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
}

/// Extension on [LayrzButtonStyle] providing computed properties about the style.
extension LayrzButtonStyleX on LayrzButtonStyle {
  /// Whether this style is a floating action button (Fab) variant.
  ///
  /// Fab variants differ from their base style only in layout—they are always
  /// square and icon-only, rendered at [kLayrzButtonHeight] × [kLayrzButtonHeight].
  bool get isFab =>
      this == LayrzButtonStyle.filledFab ||
      this == LayrzButtonStyle.elevatedFab ||
      this == LayrzButtonStyle.filledTonalFab ||
      this == LayrzButtonStyle.outlinedFab ||
      this == LayrzButtonStyle.outlinedTonalFab;

  /// Whether this style uses a tonal (semi-transparent) background fill.
  ///
  /// Tonal styles reduce visual weight by applying opacity to the accent color
  /// background rather than using a fully opaque color.
  bool get isTonal =>
      this == LayrzButtonStyle.filledTonal ||
      this == LayrzButtonStyle.filledTonalFab ||
      this == LayrzButtonStyle.outlinedTonal ||
      this == LayrzButtonStyle.outlinedTonalFab;

  /// Whether this style renders a visible border.
  ///
  /// Bordered styles use the accent color and help define the button's edges
  /// when fill is minimal or absent.
  bool get hasBorder =>
      this == LayrzButtonStyle.outlined ||
      this == LayrzButtonStyle.outlinedFab ||
      this == LayrzButtonStyle.outlinedTonal ||
      this == LayrzButtonStyle.outlinedTonalFab;

  /// Whether this style includes an elevation shadow.
  ///
  /// Shadowed styles use [LayrzTokens.shadow.elevation1] to create visual depth.
  bool get hasShadow => this == LayrzButtonStyle.elevated || this == LayrzButtonStyle.elevatedFab;
}

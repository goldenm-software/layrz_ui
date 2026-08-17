/// Visual style classification for [LayrzAlert].
///
/// This enum controls the appearance of the alert, determining how colors,
/// borders, backgrounds, and icon containers are rendered.
enum LayrzAlertStyle {
  /// Default Layrz style with neutral surface, severity-tinted border, and tinted icon chip.
  ///
  /// - Background: neutral surface
  /// - Border: severity-tinted with base border width
  /// - Icon chip: severity-tinted background
  /// - Icon/text: severity-tinted
  ///
  /// This is the flagship style and serves as the default.
  layrz,

  /// Tonal fill style with muted semantic color and matching text.
  ///
  /// - Background: tonal (semi-transparent semantic color)
  /// - Border: transparent, no border
  /// - Icon chip: transparent, no background
  /// - Icon/text: semantic color
  filledTonal,

  /// Solid fill style with semantic color and contrasting text.
  ///
  /// - Background: semantic color (solid)
  /// - Border: semantic color with base border width
  /// - Icon chip: transparent, no background
  /// - Icon/text: contrasting color (white or black)
  filled,

  /// Outlined style with semantic border and matching text.
  ///
  /// - Background: transparent
  /// - Border: semantic color with base border width
  /// - Icon chip: transparent, no background
  /// - Icon/text: semantic color
  outlined,

  /// Split-panel style with semantic color on left, neutral surface on right.
  ///
  /// - Left panel (icon): solid semantic color background
  /// - Right panel (content): neutral surface background
  /// - Border: semantic color with base border width
  /// - Icon: contrasting color
  /// - Text: neutral foreground
  filledIcon,
}

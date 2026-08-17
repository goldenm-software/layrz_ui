/// Visual style classification for [LayrzAlert].
///
/// This enum controls the appearance of the alert, determining how colors,
/// borders, backgrounds, and icon containers are rendered.
enum LayrzAlertStyle {
  /// Default Layrz style with neutral surface, severity-tinted border, and tinted icon chip.
  ///
  /// Split-panel layout: tonal left panel (soft background) with solid accent border.
  /// - Left panel: severity-tinted background
  /// - Right panel: neutral surface with title and description
  /// - Border: severity-tinted with base border width
  /// - Icon: severity-tinted
  /// - Text: neutral foreground
  ///
  /// This is the flagship style and serves as the default.
  layrz,

  /// Split-panel style with semantic color on left, neutral surface on right.
  ///
  /// Split-panel layout: solid accent left panel with solid accent border.
  /// - Left panel (icon): solid semantic color background
  /// - Right panel (content): neutral surface background
  /// - Border: semantic color with base border width
  /// - Icon: contrasting color (for high visibility on strong background)
  /// - Text: neutral foreground
  filledIcon,
}

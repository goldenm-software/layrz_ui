/// Semantic type classification for [LayrzButton] accent colors.
///
/// This enum controls which token color is applied to the button, allowing semantic
/// meaning to be expressed through color without needing to pass an explicit color value.
enum LayrzButtonType {
  /// Success semantic color — use `LayrzTokens.colors.success` for positive/affirmative actions.
  ///
  /// Applied by [LayrzButton.save] and [LayrzButton.delete] (in save context).
  success,

  /// Informational semantic color — use `LayrzTokens.colors.info` for neutral/auxiliary actions.
  ///
  /// Applied by [LayrzButton.info] and [LayrzButton.show].
  info,

  /// Contextual semantic color — use `LayrzTokens.colors.contextual` for context-dependent actions.
  ///
  /// Less common; for actions whose meaning depends on surrounding context.
  context,

  /// Danger semantic color — use `LayrzTokens.colors.danger` for destructive/warning actions.
  ///
  /// Applied by [LayrzButton.cancel] and [LayrzButton.delete].
  danger,

  /// Warning semantic color — use `LayrzTokens.colors.warning` for cautionary actions.
  ///
  /// Applied by [LayrzButton.edit].
  warning,

  /// Custom color — use an explicit `color` value passed to the constructor.
  ///
  /// The `color` parameter is only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` if `color` is null.
  custom,
}

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

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

/// Extension on [LayrzButtonType] for resolving semantic token colors.
///
/// This extension provides a mapping from button type to the corresponding
/// semantic color token, used by [LayrzButton] and dropdown menu entries
/// to maintain consistent accent colors across UI representations.
extension LayrzButtonTypeColor on LayrzButtonType {
  /// The semantic token colour for this type, or null for [LayrzButtonType.custom].
  ///
  /// Returns the appropriate token color for success, info, contextual, danger,
  /// and warning types. For [LayrzButtonType.custom], returns null, indicating
  /// that no semantic color should be applied and the button should defer to
  /// an explicit [color] parameter instead.
  ///
  /// Used to convert buttons to dropdown entries while preserving their semantic meaning.
  Color? semanticColor(LayrzTokens tokens) => switch (this) {
    LayrzButtonType.success => tokens.colors.success,
    LayrzButtonType.info => tokens.colors.info,
    LayrzButtonType.context => tokens.colors.contextual,
    LayrzButtonType.danger => tokens.colors.danger,
    LayrzButtonType.warning => tokens.colors.warning,
    LayrzButtonType.custom => null,
  };
}

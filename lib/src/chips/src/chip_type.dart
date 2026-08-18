import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Semantic type classification for [LayrzChip] accent colors.
///
/// This enum controls which token color is applied to the chip, allowing
/// semantic meaning to be expressed through color without needing to pass
/// explicit values.
enum LayrzChipType {
  /// Informational semantic type — use `LayrzTokens.colors.info` for neutral labels.
  info,

  /// Success semantic type — use `LayrzTokens.colors.success` for positive labels.
  success,

  /// Warning semantic type — use `LayrzTokens.colors.warning` for cautionary labels.
  warning,

  /// Danger semantic type — use `LayrzTokens.colors.danger` for destructive/critical labels.
  danger,

  /// Contextual semantic type — use `LayrzTokens.colors.contextual` for context-dependent labels.
  context,

  /// Custom type — use explicit `color` value from the [LayrzChip] constructor.
  ///
  /// The `color` parameter is only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` if both `type` is custom and `color` is null.
  custom;

  /// Returns the semantic color for this chip type.
  ///
  /// For non-custom types, returns the associated semantic color token.
  /// For custom type, returns null — the caller must provide an explicit color.
  Color? colorToken(LayrzTokens tokens) {
    switch (this) {
      case LayrzChipType.info:
        return tokens.colors.info.shade500;
      case LayrzChipType.success:
        return tokens.colors.success.shade500;
      case LayrzChipType.warning:
        return tokens.colors.warning.shade500;
      case LayrzChipType.danger:
        return tokens.colors.danger.shade500;
      case LayrzChipType.context:
        return tokens.colors.contextual.shade500;
      case LayrzChipType.custom:
        return null;
    }
  }
}

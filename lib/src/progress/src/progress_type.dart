import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Semantic type classification for [LayrzProgressBar] accent colors.
///
/// Mirrors the `LayrzChipType` convention (`lib/src/chips/src/chip_type.dart`)
/// so that semantic color selection reads the same way across every component
/// in the design system rather than inventing a second vocabulary.
///
/// Do not confuse this with `LayrzProgressFormat`, which selects the *shape*
/// (linear/circular) rather than the *color*.
enum LayrzProgressType {
  /// Informational semantic type — use `LayrzTokens.colors.info` for neutral progress.
  info,

  /// Success semantic type — use `LayrzTokens.colors.success` for positive progress.
  success,

  /// Warning semantic type — use `LayrzTokens.colors.warning` for cautionary progress.
  warning,

  /// Danger semantic type — use `LayrzTokens.colors.danger` for destructive/critical progress.
  danger,

  /// Contextual semantic type — use `LayrzTokens.colors.contextual` for context-dependent progress.
  context,

  /// Custom type — use explicit `color` value from the [LayrzProgressBar] constructor.
  ///
  /// The `color` parameter is only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` if both `type` is custom and `color` is null.
  custom;

  /// Returns the semantic color for this progress type.
  ///
  /// For non-custom types, returns the associated semantic color token.
  /// For custom type, returns null — the caller must provide an explicit color.
  Color? colorToken(LayrzTokens tokens) {
    switch (this) {
      case LayrzProgressType.info:
        return tokens.colors.info.shade500;
      case LayrzProgressType.success:
        return tokens.colors.success.shade500;
      case LayrzProgressType.warning:
        return tokens.colors.warning.shade500;
      case LayrzProgressType.danger:
        return tokens.colors.danger.shade500;
      case LayrzProgressType.context:
        return tokens.colors.contextual.shade500;
      case LayrzProgressType.custom:
        return null;
    }
  }
}

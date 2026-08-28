import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Semantic type classification for [LayrzBadge] accent colors.
///
/// Mirrors `LayrzChipType`'s convention deliberately (dossier §4.5, DESIGN-90's
/// Notion row): `LayrzChip` already made this choice, so this enum matches it
/// rather than inventing a second one. This keeps the semantic-color vocabulary
/// identical across chips and badges.
enum LayrzBadgeType {
  /// Informational semantic type — uses `LayrzTokens.colors.info` for neutral badges.
  info,

  /// Success semantic type — uses `LayrzTokens.colors.success` for positive badges.
  success,

  /// Warning semantic type — uses `LayrzTokens.colors.warning` for cautionary badges.
  warning,

  /// Danger semantic type — uses `LayrzTokens.colors.danger` for destructive/critical badges.
  ///
  /// This is the typical default for notification counts.
  danger,

  /// Contextual semantic type — uses `LayrzTokens.colors.contextual` for context-dependent badges.
  context,

  /// Custom type — uses the explicit `color` value passed to the badge constructor.
  ///
  /// The `color` parameter is only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` if both `type` is custom and `color` is null.
  custom;

  /// Returns the semantic color for this badge type.
  ///
  /// For non-custom types, returns the associated semantic color token.
  /// For custom type, returns null — the caller must provide an explicit color.
  Color? colorToken(LayrzTokens tokens) {
    switch (this) {
      case LayrzBadgeType.info:
        return tokens.colors.info.shade500;
      case LayrzBadgeType.success:
        return tokens.colors.success.shade500;
      case LayrzBadgeType.warning:
        return tokens.colors.warning.shade500;
      case LayrzBadgeType.danger:
        return tokens.colors.danger.shade500;
      case LayrzBadgeType.context:
        return tokens.colors.contextual.shade500;
      case LayrzBadgeType.custom:
        return null;
    }
  }
}

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/tokens.dart';
import 'package:layrz_icons/layrz_icons.dart';

/// Semantic type classification for [LayrzAlert] accent colors and icons.
///
/// This enum controls which token color and icon are applied to the alert,
/// allowing semantic meaning to be expressed through color and iconography
/// without needing to pass explicit values.
enum LayrzAlertType {
  /// Informational semantic type — use `LayrzTokens.colors.info` for neutral messages.
  ///
  /// Associated icon: [LayrzIcons.solarOutlineInfoSquare].
  info,

  /// Success semantic type — use `LayrzTokens.colors.success` for positive/affirmative messages.
  ///
  /// Associated icon: [LayrzIcons.solarOutlineCheckSquare].
  success,

  /// Warning semantic type — use `LayrzTokens.colors.warning` for cautionary messages.
  ///
  /// Associated icon: [LayrzIcons.solarOutlineDangerSquare].
  warning,

  /// Danger semantic type — use `LayrzTokens.colors.danger` for destructive/critical messages.
  ///
  /// Associated icon: [LayrzIcons.solarOutlineCloseSquare].
  danger,

  /// Contextual semantic type — use `LayrzTokens.colors.contextual` for context-dependent messages.
  ///
  /// Associated icon: [LayrzIcons.solarOutlineMenuDotsSquare].
  context,

  /// Custom type — use explicit `icon` and `color` values from the [LayrzAlert] constructor.
  ///
  /// The `color` and `icon` parameters are only honoured when `type == custom`.
  /// Defaults to `LayrzTokens.colors.primary` and [LayrzIcons.solarOutlineInfoSquare] if
  /// `color` and `icon` are null, respectively.
  custom;

  /// Returns the icon for this alert type.
  ///
  /// For non-custom types, returns the associated semantic icon.
  /// For custom type, returns null — the caller must provide an explicit icon.
  IconData? get icon {
    switch (this) {
      case LayrzAlertType.info:
        return LayrzIcons.solarOutlineInfoSquare;
      case LayrzAlertType.success:
        return LayrzIcons.solarOutlineCheckSquare;
      case LayrzAlertType.warning:
        return LayrzIcons.solarOutlineDangerSquare;
      case LayrzAlertType.danger:
        return LayrzIcons.solarOutlineCloseSquare;
      case LayrzAlertType.context:
        return LayrzIcons.solarOutlineMenuDotsSquare;
      case LayrzAlertType.custom:
        return null;
    }
  }

  /// Returns the semantic color for this alert type.
  ///
  /// For non-custom types, returns the associated semantic color token.
  /// For custom type, returns null — the caller must provide an explicit color.
  Color? colorToken(LayrzTokens tokens) {
    switch (this) {
      case LayrzAlertType.info:
        return tokens.colors.info.shade500;
      case LayrzAlertType.success:
        return tokens.colors.success.shade500;
      case LayrzAlertType.warning:
        return tokens.colors.warning.shade500;
      case LayrzAlertType.danger:
        return tokens.colors.danger.shade500;
      case LayrzAlertType.context:
        return tokens.colors.contextual.shade500;
      case LayrzAlertType.custom:
        return null;
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Semantic type classification for [LayrzSnackbar] icon and accent color.
///
/// This enum controls which token color and icon are applied to the snackbar's
/// white-card treatment, allowing severity to be expressed through color and
/// iconography without needing to pass explicit values. The color resolved by
/// [accentColor] is painted as **text/icon on a white card** (DESIGN-60 rework),
/// not as a filled surface — [LayrzSnackbarStyleSpec] is what decides which
/// paint role (icon, title, progress bar) each resolved color plays. It mirrors
/// [LayrzAlertType] (`lib/src/alerts/src/alert_type.dart`) for naming consistency
/// across the design system — note `.danger`, not `.error` (DESIGN-60 §16.1).
enum LayrzSnackbarType {
  /// Custom type — use explicit `icon` and `color` values from the [LayrzSnackbar] constructor.
  ///
  /// [icon] and [accentColor] both return null for this value; the caller must
  /// supply `icon` and `color` explicitly. [LayrzSnackbar]'s constructor asserts
  /// (in debug mode) that both are non-null when `type` is `custom`.
  custom,

  /// Success semantic type — positive/affirmative messages (e.g. "Saved").
  ///
  /// Associated icon: [MdiIcons.checkCircle]. Accent resolves from
  /// `LayrzTokens.colors.success` (darker step, legible as text/icon on the
  /// white card). This is the default [LayrzSnackbar.type].
  success,

  /// Danger semantic type — destructive/critical messages (e.g. "Failed to delete").
  ///
  /// Associated icon: [MdiIcons.alertCircle]. Accent resolves from
  /// `LayrzTokens.colors.danger` (darker step, legible as text/icon on the
  /// white card).
  danger,

  /// Warning semantic type — cautionary, non-critical messages.
  ///
  /// Associated icon: [MdiIcons.alert]. Accent resolves from
  /// `LayrzTokens.colors.warning` (darker step, legible as text/icon on the
  /// white card).
  warning,

  /// Informational semantic type — neutral, non-urgent messages.
  ///
  /// Associated icon: [MdiIcons.information]. Accent resolves from
  /// `LayrzTokens.colors.info` (darker step, legible as text/icon on the
  /// white card).
  info,

  /// Contextual semantic type — neutral status not tied to success/failure
  /// (e.g. "Undo" prompts).
  ///
  /// Associated icon: [MdiIcons.messageText]. Accent resolves from
  /// `LayrzTokens.colors.contextual` (darker step, legible as text/icon on the
  /// white card).
  context;

  /// Returns the icon for this snackbar type.
  ///
  /// For non-custom types, returns the associated semantic icon per the design
  /// spec (DESIGN-60 §Anatomy). For [custom], returns null — the caller must
  /// provide an explicit `icon`.
  IconData? get icon {
    switch (this) {
      case LayrzSnackbarType.custom:
        return null;
      case LayrzSnackbarType.success:
        return MdiIcons.checkCircle;
      case LayrzSnackbarType.danger:
        return MdiIcons.alertCircle;
      case LayrzSnackbarType.warning:
        return MdiIcons.alert;
      case LayrzSnackbarType.info:
        return MdiIcons.information;
      case LayrzSnackbarType.context:
        return MdiIcons.messageText;
    }
  }

  /// Returns the accent color for this snackbar type — painted as **text/icon on
  /// the white card**, not as a filled surface (DESIGN-60 rework; the first build's
  /// filled/full-color treatment was superseded by the white-card treatment).
  ///
  /// This is the same **darker** shade step the original filled treatment used —
  /// dark enough to clear roughly 4.5:1 contrast as white-on-color content, which
  /// also makes it read cleanly as colored text/icon on a white card, so the shade
  /// choice carries over unchanged even though its paint role changed.
  /// [tokens] supplies the live color tokens to resolve from, so custom themes are
  /// respected rather than hardcoding hex values.
  ///
  /// Resolution favours real tokens over the design spec's literal hex values;
  /// the spec's hexes (danger `#D32F2F`, success `#2E7D32`, warning `#E65100`,
  /// info `#1565C0`, context `#37474F`) are the fallback target only, and are
  /// matched here as closely as the token swatch allows:
  /// - `danger` → `tokens.colors.danger.shade700` (`#D32F2F`, exact match).
  /// - `success` → `tokens.colors.success.shade800` (`#2E7D32`, exact match).
  /// - `warning` → `tokens.colors.warning.shade600` (`#E65100` on the
  ///   `warningOrange` swatch used by `LayrzColorTokens.warning`, exact match).
  /// - `info` → `tokens.colors.info.shade800` (`#1565C0`, exact match).
  /// - `context` → `tokens.colors.contextual.shade800`. `LayrzColorTokens.contextual`
  ///   is the Material grey swatch (not blue-grey), so this does not reproduce the
  ///   spec's exact `#37474F` hex; it is the darkest available step on the token
  ///   that still clears contrast, kept in preference to hardcoding an off-token hex.
  ///
  /// For [custom], returns null — the caller must provide an explicit `color`.
  Color? accentColor(LayrzTokens tokens) {
    switch (this) {
      case LayrzSnackbarType.custom:
        return null;
      case LayrzSnackbarType.success:
        return tokens.colors.success.shade800;
      case LayrzSnackbarType.danger:
        return tokens.colors.danger.shade700;
      case LayrzSnackbarType.warning:
        return tokens.colors.warning.shade600;
      case LayrzSnackbarType.info:
        return tokens.colors.info.shade800;
      case LayrzSnackbarType.context:
        return tokens.colors.contextual.shade800;
    }
  }
}

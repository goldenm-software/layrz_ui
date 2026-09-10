import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';

import 'palette.dart';

/// Immutable semantic color tokens for the layrz_ui design system.
///
/// All colors are defined for light mode only. Colors are organized by purpose:
/// brand colors ([primary]), surface ramp ([sf1]–[sf4]),
/// foreground/text colors ([fg1]–[fg4]), semantic status colors ([danger], [success],
/// [warning], [info]), and structural colors ([divider], [overlay]).
///
/// Typically constructed via [LayrzColorTokens.light].
@immutable
class LayrzColorTokens {
  /// The primary brand color used for interactive elements and prominent actions.
  ///
  /// A single [Color]. Darker or lighter variants that widgets previously read
  /// from a swatch shade are derived from this base via
  /// `LayrzColorExtensions.darken` / `lighten` (or a tonal fill via
  /// `withOpacityValue` + `flattenOn`).
  final Color primary;

  /// The lightest surface step — the page canvas and the default fill for cards and panels.
  final Color sf1;

  /// The second surface step — used for raised containers on the canvas background.
  final Color sf2;

  /// The third surface step — used for nested containers and secondary elevations.
  final Color sf3;

  /// The darkest surface step — used for deepest nesting and maximum contrast surfaces.
  final Color sf4;

  /// The highest-contrast text color for labels and body text.
  final Color fg1;

  /// Medium-high contrast text color for secondary text and borders.
  final Color fg2;

  /// Medium contrast text color for placeholders and disabled text.
  final Color fg3;

  /// Lowest contrast text color for hints and very subtle text.
  final Color fg4;

  /// Semantic color for errors, destructive actions, and critical alerts.
  ///
  /// A single [Color]. Darker/tonal variants are derived from this base via
  /// `LayrzColorExtensions.darken` / `withOpacityValue` + `flattenOn`.
  final Color danger;

  /// Semantic color for positive confirmations, valid input, and good status.
  ///
  /// A single [Color]; darker/tonal variants are derived from it.
  final Color success;

  /// Semantic color for cautions, non-critical alerts, and warnings.
  ///
  /// A single [Color]; darker/tonal variants are derived from it.
  final Color warning;

  /// Semantic color for informational and neutral alerts.
  ///
  /// A single [Color]; darker/tonal variants are derived from it.
  final Color info;

  /// Contextual color used for neutral status and informational elements.
  /// Named distinctly from "context" to avoid collision-prone naming in widget code.
  ///
  /// A single [Color]; darker/tonal variants are derived from it.
  final Color contextual;

  /// The tint behind app-wide text selection and the find-in-page highlight.
  ///
  /// A single [Color] used as the primary selection tone — the app-wide
  /// text-selection highlight (see `LayrzThemeData.selectionColor`) and the
  /// find-spike's "current match" tint both derive from it. The find-spike's
  /// secondary "other matches" tint is derived from this same base (a lighter,
  /// lower-alpha variant), so selection and find-highlighting always read as the
  /// same visual language rather than two independently-tuned colors.
  ///
  /// First-class themeable: the dark theme overrides this single color and both
  /// consumers pick up the new hue automatically.
  final Color selectionColor;

  /// Color used for borders, dividers, and separator lines.
  final Color divider;

  /// Semi-transparent color used for modal scrims and overlays.
  final Color overlay;

  /// Alpha value applied to tonal fills to create visual distinction.
  final double tonalOpacity;

  /// Accent color for AI-generated or AI-assisted content markers.
  ///
  /// This is a standalone named handle — deliberately NOT a reuse of
  /// [LayrzColors.warning] or any other semantic status color — so it can
  /// evolve independently of them. It is set to a light blue
  /// (`#03A9F4`, matching [LayrzColors.lightBlue]'s 500 shade) rather than
  /// orange: orange is the semantic [warning] hue, and reusing it on an
  /// AI-disclosure marker reads as a caution/alert rather than a neutral
  /// "this was AI-assisted" signal. Blue carries no such semantic baggage in
  /// this design system, which is why it was chosen as the dedicated
  /// AI-accent hue.
  final Color aiAccent;

  /// Default color for `LayrzApp`'s debug-only tiled diagonal watermark
  /// (`LayrzAppBanner`).
  ///
  /// Deliberately a standalone, muted neutral gray — not a reuse of [danger]
  /// or any other semantic status color. A staging/debug watermark is not an
  /// error state, so it must not borrow the danger hue; sharing that color
  /// would make a build marker read as an alert. Used only as the fallback
  /// when the app-level banner config's own color override is `null`; a
  /// caller-supplied color always takes precedence.
  final Color watermark;

  /// Creates a new [LayrzColorTokens].
  const LayrzColorTokens({
    required this.primary,
    required this.sf1,
    required this.sf2,
    required this.sf3,
    required this.sf4,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.danger,
    required this.success,
    required this.warning,
    required this.info,
    required this.contextual,
    required this.selectionColor,
    required this.divider,
    required this.overlay,
    required this.tonalOpacity,
    required this.aiAccent,
    required this.watermark,
  });

  /// Light theme color tokens using Layrz brand defaults.
  ///
  /// [primary] defaults to [kLightPrimaryColor]. Every brand and semantic color
  /// is a single [Color] (the former swatch's 500 shade); widgets derive darker
  /// or tonal variants from these bases via `LayrzColorExtensions`.
  factory LayrzColorTokens.light({
    Color primary = kLightPrimaryColor,
  }) {
    return LayrzColorTokens(
      primary: primary,
      sf1: const Color(0xFFFCFCFC),
      sf2: const Color(0xFFF7F7F7),
      sf3: const Color(0xFFF0F0F0),
      sf4: const Color(0xFFE8E8E8),
      fg1: const Color(0xFF1A1A2E),
      fg2: const Color(0xFF4A4A5A),
      fg3: const Color(0xFF9E9E9E),
      fg4: const Color(0xFFC4C4C4),
      danger: Color(0xFFF44336),
      success: Color(0xFF4CAF50),
      warning: Color(0xFFEF6C00),
      info: Color(0xFF2196F3),
      contextual: Color(0xFF9E9E9E),
      selectionColor: Color(0xFF03A9F4),
      divider: const Color(0xFFE0E0E0),
      overlay: Color.fromRGBO(0, 0, 0, 0.5),
      tonalOpacity: 0.2,
      aiAccent: const Color(0xFF03A9F4),
      watermark: const Color(0xFF9E9E9E),
    );
  }

  /// BETA dark theme color tokens using Layrz brand defaults.
  ///
  /// [primary] defaults to [kDarkPrimaryColor] (the Layrz orange accent), kept as
  /// a single [Color]. The surface ramp ([sf1]–[sf4]) and foreground ramp
  /// ([fg1]–[fg4]) hold dark-appropriate values. Semantic status colors
  /// ([danger], [success], [warning], [info], [contextual]) and [selectionColor]
  /// currently reuse the same 500-shade hues as [LayrzColorTokens.light] for this
  /// beta — they are not yet independently tuned for dark surfaces, but because
  /// each is a plain [Color] a theme can now retune any of them freely.
  factory LayrzColorTokens.dark({
    Color primary = kDarkPrimaryColor,
  }) {
    return LayrzColorTokens(
      primary: primary,
      sf1: const Color(0xFF29272C),
      sf2: const Color(0xFF322F35),
      sf3: const Color(0xFF3C3941),
      sf4: const Color(0xFF47444D),
      fg1: const Color(0xFFECEEF3),
      fg2: const Color(0xFFB8BDCB),
      fg3: const Color(0xFF7A8194),
      fg4: const Color(0xFF4A5063),
      danger: Color(0xFFF44336),
      success: Color(0xFF4CAF50),
      warning: Color(0xFFEF6C00),
      info: Color(0xFF2196F3),
      contextual: Color(0xFF9E9E9E),
      selectionColor: Color(0xFF03A9F4),
      divider: const Color(0x14FFFFFF),
      overlay: Color.fromRGBO(0, 0, 0, 0.6),
      tonalOpacity: 0.24,
      aiAccent: const Color(0xFF03A9F4),
      watermark: const Color(0xFF3A3F4C),
    );
  }

  /// Returns a copy of this color tokens object with the given fields replaced.
  LayrzColorTokens copyWith({
    Color? primary,
    Color? sf1,
    Color? sf2,
    Color? sf3,
    Color? sf4,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Color? danger,
    Color? success,
    Color? warning,
    Color? info,
    Color? contextual,
    Color? selectionColor,
    Color? divider,
    Color? overlay,
    double? tonalOpacity,
    Color? aiAccent,
    Color? watermark,
  }) {
    return LayrzColorTokens(
      primary: primary ?? this.primary,
      sf1: sf1 ?? this.sf1,
      sf2: sf2 ?? this.sf2,
      sf3: sf3 ?? this.sf3,
      sf4: sf4 ?? this.sf4,
      fg1: fg1 ?? this.fg1,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      fg4: fg4 ?? this.fg4,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      contextual: contextual ?? this.contextual,
      selectionColor: selectionColor ?? this.selectionColor,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      tonalOpacity: tonalOpacity ?? this.tonalOpacity,
      aiAccent: aiAccent ?? this.aiAccent,
      watermark: watermark ?? this.watermark,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzColorTokens &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          sf1 == other.sf1 &&
          sf2 == other.sf2 &&
          sf3 == other.sf3 &&
          sf4 == other.sf4 &&
          fg1 == other.fg1 &&
          fg2 == other.fg2 &&
          fg3 == other.fg3 &&
          fg4 == other.fg4 &&
          danger == other.danger &&
          success == other.success &&
          warning == other.warning &&
          info == other.info &&
          contextual == other.contextual &&
          selectionColor == other.selectionColor &&
          divider == other.divider &&
          overlay == other.overlay &&
          tonalOpacity == other.tonalOpacity &&
          aiAccent == other.aiAccent &&
          watermark == other.watermark;

  @override
  int get hashCode => Object.hash(
    primary,
    sf1,
    sf2,
    sf3,
    sf4,
    fg1,
    fg2,
    fg3,
    fg4,
    danger,
    success,
    warning,
    info,
    contextual,
    selectionColor,
    divider,
    overlay,
    tonalOpacity,
    aiAccent,
    watermark,
  );
}

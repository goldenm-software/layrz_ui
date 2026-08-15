import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants/constants.dart';

/// Immutable semantic color tokens for the layrz_ui design system.
///
/// All colors are defined for light mode only. Colors are organized by purpose:
/// brand colors ([primary]), surface colors ([surface], [surface2], [surface3]),
/// foreground/text colors ([fg1]–[fg4]), semantic status colors ([danger], [success],
/// [warning], [info]), and structural colors ([divider], [overlay]).
///
/// Typically constructed via [LayrzColorTokens.light].
@immutable
class LayrzColorTokens {
  /// The primary brand color used for interactive elements and prominent actions.
  final Color primary;

  /// The scaffold / canvas background color drawn behind all surfaces.
  final Color background;

  /// The main surface color used for cards, dialogs, and elevated containers.
  final Color surface;

  /// A secondary surface color for nested containers and popovers.
  final Color surface2;

  /// The deepest nesting surface color for multi-level nested components.
  final Color surface3;

  /// The highest-contrast text color for labels and body text.
  final Color fg1;

  /// Medium-high contrast text color for secondary text and borders.
  final Color fg2;

  /// Medium contrast text color for placeholders and disabled text.
  final Color fg3;

  /// Lowest contrast text color for hints and very subtle text.
  final Color fg4;

  /// Semantic color for errors, destructive actions, and critical alerts.
  final Color danger;

  /// Semantic color for positive confirmations, valid input, and good status.
  final Color success;

  /// Semantic color for cautions, non-critical alerts, and warnings.
  final Color warning;

  /// Semantic color for informational and neutral alerts.
  final Color info;

  /// Contextual color used for neutral status and informational elements.
  /// Named distinctly from "context" to avoid collision-prone naming in widget code.
  final Color contextual;

  /// Color used for borders, dividers, and separator lines.
  final Color divider;

  /// Semi-transparent color used for modal scrims and overlays.
  final Color overlay;

  /// Alpha value applied to tonal/filledTonal fills to create visual distinction.
  final double tonalOpacity;

  /// Creates a new [LayrzColorTokens].
  const LayrzColorTokens({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.danger,
    required this.success,
    required this.warning,
    required this.info,
    required this.contextual,
    required this.divider,
    required this.overlay,
    required this.tonalOpacity,
  });

  /// Light theme color tokens using Layrz brand defaults.
  ///
  /// [primary] defaults to [kPrimaryColor].
  /// All other colors use semantic light theme values.
  factory LayrzColorTokens.light({
    Color primary = kPrimaryColor,
  }) {
    return LayrzColorTokens(
      primary: primary,
      background: kLightBackgroundColor,
      surface: const Color(0xFFFFFFFF),
      surface2: const Color(0xFFF7F7F7),
      surface3: const Color(0xFFF0F0F0),
      fg1: const Color(0xFF1A1A2E),
      fg2: const Color(0xFF4A4A5A),
      fg3: const Color(0xFF9E9E9E),
      fg4: const Color(0xFFC4C4C4),
      danger: const Color(0xFFE53935),
      success: const Color(0xFF43A047),
      warning: const Color(0xFFFB8C00),
      info: const Color(0xFF1E88E5),
      contextual: const Color(0xFF9E9E9E),
      divider: const Color(0xFFE0E0E0),
      overlay: Color.fromRGBO(0, 0, 0, 0.5),
      tonalOpacity: 0.2,
    );
  }

  /// Returns a copy of this color tokens object with the given fields replaced.
  LayrzColorTokens copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Color? danger,
    Color? success,
    Color? warning,
    Color? info,
    Color? contextual,
    Color? divider,
    Color? overlay,
    double? tonalOpacity,
  }) {
    return LayrzColorTokens(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      fg1: fg1 ?? this.fg1,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      fg4: fg4 ?? this.fg4,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      contextual: contextual ?? this.contextual,
      divider: divider ?? this.divider,
      overlay: overlay ?? this.overlay,
      tonalOpacity: tonalOpacity ?? this.tonalOpacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzColorTokens &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          background == other.background &&
          surface == other.surface &&
          surface2 == other.surface2 &&
          surface3 == other.surface3 &&
          fg1 == other.fg1 &&
          fg2 == other.fg2 &&
          fg3 == other.fg3 &&
          fg4 == other.fg4 &&
          danger == other.danger &&
          success == other.success &&
          warning == other.warning &&
          info == other.info &&
          contextual == other.contextual &&
          divider == other.divider &&
          overlay == other.overlay &&
          tonalOpacity == other.tonalOpacity;

  @override
  int get hashCode => Object.hash(
    primary,
    background,
    surface,
    surface2,
    surface3,
    fg1,
    fg2,
    fg3,
    fg4,
    danger,
    success,
    warning,
    info,
    contextual,
    divider,
    overlay,
    tonalOpacity,
  );
}

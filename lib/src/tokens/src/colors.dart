import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';

import 'color_swatch.dart';

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
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch primary;

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
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch danger;

  /// Semantic color for positive confirmations, valid input, and good status.
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch success;

  /// Semantic color for cautions, non-critical alerts, and warnings.
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch warning;

  /// Semantic color for informational and neutral alerts.
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch info;

  /// Contextual color used for neutral status and informational elements.
  /// Named distinctly from "context" to avoid collision-prone naming in widget code.
  /// A [LayrzColorSwatch] providing ten tonal shades indexed from 50 (lightest) to 900 (darkest).
  final LayrzColorSwatch contextual;

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
  /// [primary] defaults to [kPrimaryColor] and is wrapped in a [LayrzColorSwatch]
  /// that generates ten tonal shades algorithmically.
  /// All other colors use semantic light theme values with standard Material palettes.
  factory LayrzColorTokens.light({
    Color primary = kPrimaryColor,
  }) {
    return LayrzColorTokens(
      primary: LayrzColorSwatch.fromColor(primary),
      background: kLightBackgroundColor,
      surface: const Color(0xFFFFFFFF),
      surface2: const Color(0xFFF7F7F7),
      surface3: const Color(0xFFF0F0F0),
      fg1: const Color(0xFF1A1A2E),
      fg2: const Color(0xFF4A4A5A),
      fg3: const Color(0xFF9E9E9E),
      fg4: const Color(0xFFC4C4C4),
      // Semantic colors use the standard Material 500 shades and full swatch palettes
      // (50, 100, 200, …, 900) for consistent, familiar appearance. These values mirror
      // the Flutter Material palette to prevent unintended changes if later "tidied".
      danger: LayrzColorSwatch(
        0xFFF44336, // red 500
        <int, Color>{
          50: const Color(0xFFFFEBEE),
          100: const Color(0xFFFFCDD2),
          200: const Color(0xFFEF9A9A),
          300: const Color(0xFFE57373),
          400: const Color(0xFFEF5350),
          500: const Color(0xFFF44336),
          600: const Color(0xFFE53935),
          700: const Color(0xFFD32F2F),
          800: const Color(0xFFC62828),
          900: const Color(0xFFB71C1C),
        },
      ),
      success: LayrzColorSwatch(
        0xFF4CAF50, // green 500
        <int, Color>{
          50: const Color(0xFFE8F5E9),
          100: const Color(0xFFC8E6C9),
          200: const Color(0xFFA5D6A7),
          300: const Color(0xFF81C784),
          400: const Color(0xFF66BB6A),
          500: const Color(0xFF4CAF50),
          600: const Color(0xFF43A047),
          700: const Color(0xFF388E3C),
          800: const Color(0xFF2E7D32),
          900: const Color(0xFF1B5E20),
        },
      ),
      warning: LayrzColorSwatch(
        0xFFFF9800, // orange 500
        <int, Color>{
          50: const Color(0xFFFFF3E0),
          100: const Color(0xFFFFE0B2),
          200: const Color(0xFFFFCC80),
          300: const Color(0xFFFFB74D),
          400: const Color(0xFFFFA726),
          500: const Color(0xFFFF9800),
          600: const Color(0xFFFB8C00),
          700: const Color(0xFFF57C00),
          800: const Color(0xFFEF6C00),
          900: const Color(0xFFE65100),
        },
      ),
      info: LayrzColorSwatch(
        0xFF2196F3, // blue 500
        <int, Color>{
          50: const Color(0xFFE3F2FD),
          100: const Color(0xFFBBDEFB),
          200: const Color(0xFF90CAF9),
          300: const Color(0xFF64B5F6),
          400: const Color(0xFF42A5F5),
          500: const Color(0xFF2196F3),
          600: const Color(0xFF1E88E5),
          700: const Color(0xFF1976D2),
          800: const Color(0xFF1565C0),
          900: const Color(0xFF0D47A1),
        },
      ),
      contextual: LayrzColorSwatch(
        0xFF9E9E9E, // grey 500
        <int, Color>{
          50: const Color(0xFFFAFAFA),
          100: const Color(0xFFF5F5F5),
          200: const Color(0xFFEEEEEE),
          300: const Color(0xFFE0E0E0),
          400: const Color(0xFFBDBDBD),
          500: const Color(0xFF9E9E9E),
          600: const Color(0xFF757575),
          700: const Color(0xFF616161),
          800: const Color(0xFF424242),
          900: const Color(0xFF212121),
        },
      ),
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
      primary: primary == null
          ? this.primary
          : (primary is LayrzColorSwatch ? primary : LayrzColorSwatch.fromColor(primary)),
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      fg1: fg1 ?? this.fg1,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      fg4: fg4 ?? this.fg4,
      danger: danger == null
          ? this.danger
          : (danger is LayrzColorSwatch ? danger : LayrzColorSwatch(danger.toARGB32(), {50: danger})),
      success: success == null
          ? this.success
          : (success is LayrzColorSwatch ? success : LayrzColorSwatch(success.toARGB32(), {50: success})),
      warning: warning == null
          ? this.warning
          : (warning is LayrzColorSwatch ? warning : LayrzColorSwatch(warning.toARGB32(), {50: warning})),
      info: info == null
          ? this.info
          : (info is LayrzColorSwatch ? info : LayrzColorSwatch(info.toARGB32(), {50: info})),
      contextual: contextual == null
          ? this.contextual
          : (contextual is LayrzColorSwatch ? contextual : LayrzColorSwatch(contextual.toARGB32(), {50: contextual})),
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

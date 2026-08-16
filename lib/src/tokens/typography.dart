import 'package:flutter/widgets.dart';

import 'package:layrz_ui/fonts.dart';

/// Full text-style scale — mirrors the names from Material's TextTheme
/// so migration from layrz_theme is mechanical.
///
/// All 15 text styles (display, headline, title, body, label) at three sizes each
/// are defined with font family, size, weight, and line height. The font resolver
/// strategy follows the [LayrzTextTheme.defaults] factory parameters.
@immutable
class LayrzTextTheme {
  /// Largest display style. Typically used for hero text or splash screens.
  final TextStyle displayLarge;

  /// Medium display style.
  final TextStyle displayMedium;

  /// Small display style.
  final TextStyle displaySmall;

  /// Largest headline style. Used for page-level headings.
  final TextStyle headlineLarge;

  /// Medium headline style.
  final TextStyle headlineMedium;

  /// Small headline style. Used for section headings.
  final TextStyle headlineSmall;

  /// Largest title style. Used for dialog and card titles.
  final TextStyle titleLarge;

  /// Medium title style.
  final TextStyle titleMedium;

  /// Small title style.
  final TextStyle titleSmall;

  /// Largest body style. Used for prominent body copy.
  final TextStyle bodyLarge;

  /// Default body style. Used for most body text.
  final TextStyle bodyMedium;

  /// Small body style. Used for captions and supporting text.
  final TextStyle bodySmall;

  /// Largest label style. Used for button labels and input labels.
  final TextStyle labelLarge;

  /// Medium label style.
  final TextStyle labelMedium;

  /// Smallest label style. Used for tooltips and badges.
  final TextStyle labelSmall;

  /// Creates a new [LayrzTextTheme] with all text styles explicitly set.
  const LayrzTextTheme({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  /// Generates a default text theme using the given [textColor] and font families.
  ///
  /// [textColor] is applied to every style in the scale.
  ///
  /// [titleFont] is used for display, headline, and title styles; [bodyFont] is used
  /// for body and label styles.
  ///
  /// [fontHandler] resolves font family names and preloads font bytes. When not null,
  /// it provides [LayrzFontHandler.resolveFamily] for the family and
  /// [LayrzFontHandler.fallbacks] for the fallback list. When null (e.g., in unit tests),
  /// uses the font name directly and the layrz fallback constants, avoiding network calls.
  /// This is useful for tests that need to avoid GoogleFonts network calls.
  factory LayrzTextTheme.defaults({
    required Color textColor,
    LayrzFont titleFont = kLayrzFont,
    LayrzFont bodyFont = kLayrzFont,
    LayrzFontHandler? fontHandler,
  }) {
    // Resolve font families based on the handler
    final titleFamily = fontHandler != null ? fontHandler.resolveFamily(titleFont) : titleFont.name;
    final bodyFamily = fontHandler != null ? fontHandler.resolveFamily(bodyFont) : bodyFont.name;

    final titleFallbacks = fontHandler != null ? fontHandler.fallbacks : kLayrzFontFallbacks;
    final bodyFallbacks = fontHandler != null ? fontHandler.fallbacks : kLayrzFontFallbacks;

    TextStyle title(double size) => TextStyle(
      color: textColor,
      fontSize: size,
      fontFamily: titleFamily,
      fontFamilyFallback: titleFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    TextStyle body(double size) => TextStyle(
      color: textColor,
      fontSize: size,
      fontFamily: bodyFamily,
      fontFamilyFallback: bodyFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    return LayrzTextTheme(
      displayLarge: title(57),
      displayMedium: title(45),
      displaySmall: title(36),
      headlineLarge: title(32),
      headlineMedium: title(28),
      headlineSmall: title(24),
      titleLarge: title(22),
      titleMedium: title(16),
      titleSmall: title(14),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12),
      labelLarge: body(14),
      labelMedium: body(12),
      labelSmall: body(11),
    );
  }

  /// Returns a copy of this text theme with the given text styles replaced.
  LayrzTextTheme copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
  }) {
    return LayrzTextTheme(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      displaySmall: displaySmall ?? this.displaySmall,
      headlineLarge: headlineLarge ?? this.headlineLarge,
      headlineMedium: headlineMedium ?? this.headlineMedium,
      headlineSmall: headlineSmall ?? this.headlineSmall,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTextTheme &&
          runtimeType == other.runtimeType &&
          displayLarge == other.displayLarge &&
          displayMedium == other.displayMedium &&
          displaySmall == other.displaySmall &&
          headlineLarge == other.headlineLarge &&
          headlineMedium == other.headlineMedium &&
          headlineSmall == other.headlineSmall &&
          titleLarge == other.titleLarge &&
          titleMedium == other.titleMedium &&
          titleSmall == other.titleSmall &&
          bodyLarge == other.bodyLarge &&
          bodyMedium == other.bodyMedium &&
          bodySmall == other.bodySmall &&
          labelLarge == other.labelLarge &&
          labelMedium == other.labelMedium &&
          labelSmall == other.labelSmall;

  @override
  int get hashCode => Object.hash(
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
    titleLarge,
    titleMedium,
    titleSmall,
    bodyLarge,
    bodyMedium,
    bodySmall,
    labelLarge,
    labelMedium,
    labelSmall,
  );
}

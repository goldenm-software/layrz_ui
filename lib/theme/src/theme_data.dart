import 'package:flutter/widgets.dart';

import '../../constants/constants.dart';

/// Full text-style scale — mirrors the names from Material's TextTheme
/// so migration from layrz_theme is mechanical.
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
  /// [titleFontFamily] is used for display, headline, and title styles.
  /// [bodyFontFamily] is used for body and label styles.
  factory LayrzTextTheme.defaults({
    required Color textColor,
    String titleFontFamily = 'Ubuntu',
    String bodyFontFamily = 'Ubuntu',
  }) {
    TextStyle title(double size) => TextStyle(
          color: textColor,
          fontSize: size,
          fontFamily: titleFontFamily,
          overflow: TextOverflow.ellipsis,
          decoration: TextDecoration.none,
        );

    TextStyle body(double size) => TextStyle(
          color: textColor,
          fontSize: size,
          fontFamily: bodyFontFamily,
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
}

/// Immutable design tokens for the layrz_ui design system.
///
/// Consumed by [LayrzTheme.of] in every layrz_ui widget.
@immutable
class LayrzThemeData {
  /// Primary brand color (deep navy blue by default).
  final Color primaryColor;

  /// Accent / secondary brand color (vibrant orange by default).
  final Color accentColor;

  /// Canvas / scaffold background color.
  final Color backgroundColor;

  /// Surface color used for cards, dialogs, and elevated containers.
  final Color surfaceColor;

  /// Default text color drawn on [backgroundColor].
  final Color textColor;

  /// Muted / hint text color for placeholders and supporting text.
  final Color hintColor;

  /// Border and divider color.
  final Color borderColor;

  /// Error / danger semantic color.
  final Color errorColor;

  /// Success semantic color.
  final Color successColor;

  /// Warning semantic color.
  final Color warningColor;

  /// Overall brightness of this theme variant.
  final Brightness brightness;

  /// Full text-style scale for this theme.
  final LayrzTextTheme textTheme;

  /// Base icon theme applied via [IconTheme] at the root.
  final IconThemeData iconTheme;

  /// Border radius used consistently for rounded corners across all widgets.
  final double borderRadius;

  const LayrzThemeData({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.hintColor,
    required this.borderColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
    required this.brightness,
    required this.textTheme,
    required this.iconTheme,
    this.borderRadius = 10.0,
  });

  /// Convenience accessor — base body style used as [DefaultTextStyle] at the root.
  TextStyle get textStyle => textTheme.bodyMedium;

  /// Light theme using Layrz brand defaults.
  ///
  /// [primaryColor] overrides the default [kPrimaryColor].
  /// [accentColor] overrides the default [kAccentColor].
  factory LayrzThemeData.light({
    Color primaryColor = kPrimaryColor,
    Color accentColor = kAccentColor,
  }) {
    const textColor = Color(0xFF1A1A2E);
    final textTheme = LayrzTextTheme.defaults(textColor: textColor);
    return LayrzThemeData(
      primaryColor: primaryColor,
      accentColor: accentColor,
      backgroundColor: kLightBackgroundColor,
      surfaceColor: const Color(0xFFFFFFFF),
      textColor: textColor,
      hintColor: const Color(0xFF9E9E9E),
      borderColor: const Color(0xFFE0E0E0),
      errorColor: const Color(0xFFE53935),
      successColor: const Color(0xFF43A047),
      warningColor: const Color(0xFFFB8C00),
      brightness: Brightness.light,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: textColor, size: 24),
    );
  }

  /// Dark theme using Layrz brand defaults.
  ///
  /// [primaryColor] overrides the default [kPrimaryColor].
  /// [accentColor] overrides the default [kAccentColor].
  factory LayrzThemeData.dark({
    Color primaryColor = kPrimaryColor,
    Color accentColor = kAccentColor,
  }) {
    const textColor = Color(0xFFECEFF1);
    final textTheme = LayrzTextTheme.defaults(textColor: textColor);
    return LayrzThemeData(
      primaryColor: primaryColor,
      accentColor: accentColor,
      backgroundColor: kDarkBackgroundColor,
      surfaceColor: const Color(0xFF1E1E1E),
      textColor: textColor,
      hintColor: const Color(0xFF757575),
      borderColor: const Color(0xFF3A3A3A),
      errorColor: const Color(0xFFEF5350),
      successColor: const Color(0xFF66BB6A),
      warningColor: const Color(0xFFFFA726),
      brightness: Brightness.dark,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: textColor, size: 24),
    );
  }

  /// Returns a copy of this theme with the given fields replaced.
  LayrzThemeData copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    Color? hintColor,
    Color? borderColor,
    Color? errorColor,
    Color? successColor,
    Color? warningColor,
    Brightness? brightness,
    LayrzTextTheme? textTheme,
    IconThemeData? iconTheme,
    double? borderRadius,
  }) {
    return LayrzThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      hintColor: hintColor ?? this.hintColor,
      borderColor: borderColor ?? this.borderColor,
      errorColor: errorColor ?? this.errorColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      brightness: brightness ?? this.brightness,
      textTheme: textTheme ?? this.textTheme,
      iconTheme: iconTheme ?? this.iconTheme,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzThemeData &&
          primaryColor == other.primaryColor &&
          accentColor == other.accentColor &&
          backgroundColor == other.backgroundColor &&
          surfaceColor == other.surfaceColor &&
          textColor == other.textColor &&
          hintColor == other.hintColor &&
          borderColor == other.borderColor &&
          errorColor == other.errorColor &&
          successColor == other.successColor &&
          warningColor == other.warningColor &&
          brightness == other.brightness &&
          textTheme == other.textTheme &&
          iconTheme == other.iconTheme &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(
        primaryColor,
        accentColor,
        backgroundColor,
        surfaceColor,
        textColor,
        hintColor,
        borderColor,
        errorColor,
        successColor,
        warningColor,
        brightness,
        textTheme,
        iconTheme,
        borderRadius,
      );
}

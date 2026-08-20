import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/fonts/fonts.dart';

/// Five core text styles for the design system.
///
/// Rather than offering three sizes per category (display, headline, title, body, label),
/// this simpler scale provides one blessed size per category. Developers needing a variant
/// use [copyWith(fontSize:)] to be explicit about deviating from the design system.
///
/// The five styles are:
/// - [display]: 40px, w700 — for hero and splash screens
/// - [headline]: 24px, w600 — for page-level headings
/// - [title]: 20px, w600 — for dialog and card titles
/// - [body]: 16px, w400 — for body text and reading passages (web-equivalent to 1em)
/// - [label]: 14px, w400 — for labels, buttons, tooltips, and badges
///
/// All styles use the font families provided to [LayrzTextTheme.defaults].
@immutable
class LayrzTextTheme {
  /// Display style for hero text and splash screens.
  ///
  /// Characteristics: 40px, w700, title font family.
  final TextStyle display;

  /// Headline style for page-level headings.
  ///
  /// Characteristics: 24px, w600, title font family.
  final TextStyle headline;

  /// Title style for dialog and card titles.
  ///
  /// Characteristics: 20px, w600, title font family.
  final TextStyle title;

  /// Body style for body text and reading passages.
  ///
  /// Characteristics: 16px, w400, body font family.
  final TextStyle body;

  /// Label style for button labels, input labels, tooltips, and badges.
  ///
  /// Characteristics: 14px, w400, body font family.
  final TextStyle label;

  /// Creates a new [LayrzTextTheme] with all text styles explicitly set.
  const LayrzTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
  });

  /// Generates a default text theme using the given [textColor] and font families.
  ///
  /// [textColor] is applied to every style in the scale.
  ///
  /// [titleFont] is used for display, headline, and title styles; [bodyFont] is used
  /// for body and label styles.
  ///
  /// [fontHandler] resolves font family names and preloads font bytes. When not null,
  /// it provides [LayrzFontHandler.resolveFamilyForWeight] to select the correct family
  /// per weight and [LayrzFontHandler.fallbacks] for the fallback list. When null
  /// (e.g., in unit tests), uses the font name directly and the layrz fallback constants,
  /// avoiding network calls. This is useful for tests that need to avoid GoogleFonts
  /// network calls.
  factory LayrzTextTheme.defaults({
    required Color textColor,
    LayrzFont titleFont = kLayrzFont,
    LayrzFont bodyFont = kLayrzFont,
    LayrzFontHandler? fontHandler,
  }) {
    final titleFallbacks = fontHandler != null ? fontHandler.fallbacks : kLayrzFontFallbacks;
    final bodyFallbacks = fontHandler != null ? fontHandler.fallbacks : kLayrzFontFallbacks;

    /// Helper to resolve the font family for a given font and weight.
    String resolveTitleFamily(FontWeight weight) {
      if (fontHandler != null) {
        return fontHandler.resolveFamilyForWeight(titleFont, weight);
      }
      return titleFont.name;
    }

    /// Helper to resolve the font family for a given font and weight.
    String resolveBodyFamily(FontWeight weight) {
      if (fontHandler != null) {
        return fontHandler.resolveFamilyForWeight(bodyFont, weight);
      }
      return bodyFont.name;
    }

    TextStyle titleStyle(double size, FontWeight fontWeight) => TextStyle(
      color: textColor,
      fontSize: size,
      fontWeight: fontWeight,
      fontFamily: resolveTitleFamily(fontWeight),
      fontFamilyFallback: titleFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    TextStyle bodyStyle(double size, FontWeight fontWeight) => TextStyle(
      color: textColor,
      fontSize: size,
      fontWeight: fontWeight,
      fontFamily: resolveBodyFamily(fontWeight),
      fontFamilyFallback: bodyFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    return LayrzTextTheme(
      display: titleStyle(40, FontWeight.w700),
      headline: titleStyle(24, FontWeight.w600),
      title: titleStyle(20, FontWeight.w600),
      body: bodyStyle(16, FontWeight.w400),
      label: bodyStyle(14, FontWeight.w400),
    );
  }

  /// Returns a copy of this text theme with the given text styles replaced.
  LayrzTextTheme copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
  }) {
    return LayrzTextTheme(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzTextTheme &&
          runtimeType == other.runtimeType &&
          display == other.display &&
          headline == other.headline &&
          title == other.title &&
          body == other.body &&
          label == other.label;

  @override
  int get hashCode => Object.hash(
    display,
    headline,
    title,
    body,
    label,
  );
}

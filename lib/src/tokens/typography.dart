import 'package:flutter/widgets.dart';

import 'package:layrz_ui/fonts.dart';

/// Five core text styles for the design system.
///
/// Rather than offering three sizes per category (display, headline, title, body, label),
/// this simpler scale provides one blessed size per category. Developers needing a variant
/// use [copyWith(fontSize:)] to be explicit about deviating from the design system.
///
/// The five styles are:
/// - [display]: 45px, w800 — for hero and splash screens
/// - [headline]: 28px, w700 — for page-level headings
/// - [title]: 16px, w500 — for dialog and card titles
/// - [body]: 14px, w300 — for body text and reading passages
/// - [label]: 12px, w100 — for labels, buttons, tooltips, and badges
///
/// All styles use the font families provided to [LayrzTextTheme.defaults].
@immutable
class LayrzTextTheme {
  /// Display style for hero text and splash screens.
  ///
  /// Characteristics: 45px, w800, title font family.
  final TextStyle display;

  /// Headline style for page-level headings.
  ///
  /// Characteristics: 28px, w700, title font family.
  final TextStyle headline;

  /// Title style for dialog and card titles.
  ///
  /// Characteristics: 16px, w500, title font family.
  final TextStyle title;

  /// Body style for body text and reading passages.
  ///
  /// Characteristics: 14px, w300, body font family.
  final TextStyle body;

  /// Label style for button labels, input labels, tooltips, and badges.
  ///
  /// Characteristics: 12px, w100, body font family.
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

    TextStyle titleStyle(double size, {FontWeight fontWeight = FontWeight.w400}) => TextStyle(
      color: textColor,
      fontSize: size,
      fontWeight: fontWeight,
      fontFamily: titleFamily,
      fontFamilyFallback: titleFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    TextStyle bodyStyle(double size, {FontWeight fontWeight = FontWeight.w400}) => TextStyle(
      color: textColor,
      fontSize: size,
      fontWeight: fontWeight,
      fontFamily: bodyFamily,
      fontFamilyFallback: bodyFallbacks,
      overflow: TextOverflow.ellipsis,
      decoration: TextDecoration.none,
    );

    return LayrzTextTheme(
      display: titleStyle(45, fontWeight: FontWeight.w800),
      headline: titleStyle(28, fontWeight: FontWeight.w700),
      title: titleStyle(16, fontWeight: FontWeight.w500),
      body: bodyStyle(14, fontWeight: FontWeight.w300),
      label: bodyStyle(12, fontWeight: FontWeight.w100),
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

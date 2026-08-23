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
/// All styles carry no [TextStyle.overflow] property; text wraps by default. Components that
/// require truncation due to fixed height constraints must set [overflow] and [maxLines]
/// explicitly. This is a layout property, not a typography property.
///
/// All styles use the font families provided to [LayrzTextTheme.defaults].
@immutable
class LayrzTextTheme {
  /// Display style for hero text and splash screens.
  ///
  /// Characteristics: 40px, w700, title font family.
  /// No [overflow] is set; text wraps by default.
  final TextStyle display;

  /// Headline style for page-level headings.
  ///
  /// Characteristics: 24px, w600, title font family.
  /// No [overflow] is set; text wraps by default.
  final TextStyle headline;

  /// Title style for dialog and card titles.
  ///
  /// Characteristics: 20px, w600, title font family.
  /// No [overflow] is set; text wraps by default.
  final TextStyle title;

  /// Body style for body text and reading passages.
  ///
  /// Characteristics: 16px, w400, body font family.
  /// No [overflow] is set; text wraps by default.
  final TextStyle body;

  /// Label style for button labels, input labels, tooltips, and badges.
  ///
  /// Characteristics: 14px, w400, body font family.
  /// No [overflow] is set; text wraps by default.
  final TextStyle label;

  /// Creates a new [LayrzTextTheme] with all text styles explicitly set.
  const LayrzTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
  });

  /// Generates a default text theme using the given [textColor] and [font].
  ///
  /// [textColor] is applied to every style in the scale.
  ///
  /// [font] is used for all text styles. The font's style getters are merged with
  /// the size and colour applied by the theme.
  ///
  /// If [font] is null, defaults to [LayrzRobotoFont].
  /// This allows tests to pass no font and still get a working theme.
  factory LayrzTextTheme.defaults({
    required Color textColor,
    LayrzFont? font,
  }) {
    // Default to Roboto if no font is provided
    final fontResolved = font ?? const LayrzRobotoFont();

    return LayrzTextTheme(
      display: fontResolved.display.copyWith(fontSize: 40, color: textColor, decoration: TextDecoration.none),
      headline: fontResolved.headline.copyWith(fontSize: 24, color: textColor, decoration: TextDecoration.none),
      title: fontResolved.title.copyWith(fontSize: 20, color: textColor, decoration: TextDecoration.none),
      body: fontResolved.body.copyWith(fontSize: 16, color: textColor, decoration: TextDecoration.none),
      label: fontResolved.label.copyWith(fontSize: 14, color: textColor, decoration: TextDecoration.none),
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

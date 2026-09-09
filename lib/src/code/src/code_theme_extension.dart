import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';
import 'package:layrz_ui/src/theme/theme.dart';

/// The theme extension backing every layrz_ui code widget.
///
/// Code widgets (a read-only viewer, an editable editor, a diff view, …) are
/// **always rendered dark**, independent of the app's own light theme — this
/// mirrors how most code editors present source regardless of the host UI's
/// palette. [LayrzCodeThemeExtension.dark] is the single dark palette used
/// for that purpose, and is what every code widget falls back to when no
/// extension has been registered on [LayrzThemeData].
///
/// Register a custom instance (or a tweaked copy of [dark]) via
/// `LayrzThemeData(extensions: [...])` to recolor code widgets app-wide, or
/// retrieve the active one with `context.themeExtension<LayrzCodeThemeExtension>()`.
class LayrzCodeThemeExtension extends LayrzThemeExtension<LayrzCodeThemeExtension> {
  /// The background color painted behind the code area.
  final Color background;

  /// The default foreground color for plain, unclassified text
  /// ([LayrzHighlightScope.text]).
  final Color foreground;

  /// The background color of the line-number gutter.
  final Color gutterBackground;

  /// The color of the line numbers drawn in the gutter.
  final Color gutterForeground;

  /// The background color used to highlight the line the caret is on.
  final Color currentLineBackground;

  /// The color used to mark a line or span reported by a [LayrzCodeError].
  final Color errorColor;

  /// The color for [LayrzHighlightScope.keyword] tokens.
  final Color keyword;

  /// The color for [LayrzHighlightScope.builtin] tokens.
  final Color builtin;

  /// The color for [LayrzHighlightScope.function] tokens.
  ///
  /// Function tokens are additionally rendered bold — see [styleForScope].
  final Color function;

  /// The color for [LayrzHighlightScope.string] tokens.
  final Color string;

  /// The color for [LayrzHighlightScope.number] tokens.
  final Color number;

  /// The color for [LayrzHighlightScope.comment] tokens.
  final Color comment;

  /// The color for [LayrzHighlightScope.constant] tokens.
  final Color constant;

  /// The color for [LayrzHighlightScope.decorator] tokens.
  final Color decorator;

  /// The color for [LayrzHighlightScope.variable] tokens.
  final Color variable;

  /// Creates a new [LayrzCodeThemeExtension] with every field required.
  ///
  /// Prefer [LayrzCodeThemeExtension.dark] unless every color needs to be
  /// specified explicitly.
  const LayrzCodeThemeExtension({
    required this.background,
    required this.foreground,
    required this.gutterBackground,
    required this.gutterForeground,
    required this.currentLineBackground,
    required this.errorColor,
    required this.keyword,
    required this.builtin,
    required this.function,
    required this.string,
    required this.number,
    required this.comment,
    required this.constant,
    required this.decorator,
    required this.variable,
  });

  /// The default dark palette used by every layrz_ui code widget.
  ///
  /// Code widgets do not follow the app's light/dark mode — they are always
  /// dark, the same way most code editors are — so this is both the default
  /// and, in practice, the only palette most consumers ever need.
  const LayrzCodeThemeExtension.dark()
    : background = const Color(0xFF1A1A1A),
      foreground = const Color(0xFFECF0F1),
      gutterBackground = const Color(0xFF212121),
      gutterForeground = const Color(0xFF6B6B6B),
      currentLineBackground = const Color(0xFF252525),
      errorColor = const Color(0xFFE74C3C),
      keyword = const Color(0xFF9B59B6),
      builtin = const Color(0xFF5DADE2),
      function = const Color(0xFF3498DB),
      string = const Color(0xFFF1C40F),
      number = const Color(0xFF2ECC71),
      comment = const Color(0xFF7F8C8D),
      constant = const Color(0xFFE67E22),
      decorator = const Color(0xFF1ABC9C),
      variable = const Color(0xFF80DEEA);

  @override
  LayrzCodeThemeExtension copyWith({
    Color? background,
    Color? foreground,
    Color? gutterBackground,
    Color? gutterForeground,
    Color? currentLineBackground,
    Color? errorColor,
    Color? keyword,
    Color? builtin,
    Color? function,
    Color? string,
    Color? number,
    Color? comment,
    Color? constant,
    Color? decorator,
    Color? variable,
  }) {
    return LayrzCodeThemeExtension(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      gutterBackground: gutterBackground ?? this.gutterBackground,
      gutterForeground: gutterForeground ?? this.gutterForeground,
      currentLineBackground: currentLineBackground ?? this.currentLineBackground,
      errorColor: errorColor ?? this.errorColor,
      keyword: keyword ?? this.keyword,
      builtin: builtin ?? this.builtin,
      function: function ?? this.function,
      string: string ?? this.string,
      number: number ?? this.number,
      comment: comment ?? this.comment,
      constant: constant ?? this.constant,
      decorator: decorator ?? this.decorator,
      variable: variable ?? this.variable,
    );
  }

  @override
  LayrzCodeThemeExtension lerp(covariant LayrzCodeThemeExtension? other, double t) {
    if (other == null) {
      return this;
    }
    return LayrzCodeThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      gutterBackground: Color.lerp(gutterBackground, other.gutterBackground, t)!,
      gutterForeground: Color.lerp(gutterForeground, other.gutterForeground, t)!,
      currentLineBackground: Color.lerp(currentLineBackground, other.currentLineBackground, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      keyword: Color.lerp(keyword, other.keyword, t)!,
      builtin: Color.lerp(builtin, other.builtin, t)!,
      function: Color.lerp(function, other.function, t)!,
      string: Color.lerp(string, other.string, t)!,
      number: Color.lerp(number, other.number, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      constant: Color.lerp(constant, other.constant, t)!,
      decorator: Color.lerp(decorator, other.decorator, t)!,
      variable: Color.lerp(variable, other.variable, t)!,
    );
  }

  /// Returns the color assigned to a given [scope].
  ///
  /// [LayrzHighlightScope.text] resolves to [foreground]; every other scope
  /// resolves to its like-named field (e.g. [LayrzHighlightScope.string] to
  /// [string]).
  Color colorForScope(LayrzHighlightScope scope) {
    switch (scope) {
      case LayrzHighlightScope.text:
        return foreground;
      case LayrzHighlightScope.keyword:
        return keyword;
      case LayrzHighlightScope.builtin:
        return builtin;
      case LayrzHighlightScope.function:
        return function;
      case LayrzHighlightScope.string:
        return string;
      case LayrzHighlightScope.number:
        return number;
      case LayrzHighlightScope.comment:
        return comment;
      case LayrzHighlightScope.constant:
        return constant;
      case LayrzHighlightScope.decorator:
        return decorator;
      case LayrzHighlightScope.variable:
        return variable;
    }
  }

  /// Returns the [TextStyle] to render text carrying [scope], sized at
  /// [fontSize].
  ///
  /// The style is always JetBrains Mono ([LayrzJetBrainsMonoFont]), colored
  /// via [colorForScope]. [LayrzHighlightScope.function] is rendered bold —
  /// the only bold scope, matching layrz_theme's syntax highlighting — using
  /// the font's `display` style (weight `700`) rather than `body` (weight
  /// `400`). Every other scope uses `body`.
  ///
  /// JetBrains Mono is a **variable** font: weight is only respected via
  /// `TextStyle.fontVariations`, never `TextStyle.fontWeight` — the latter
  /// silently no-ops on this font. Both `display` and `body` already encode
  /// their weight as a `fontVariations: [FontVariation('wght', ...)]` entry,
  /// so selecting between them is sufficient; no extra override is needed.
  TextStyle styleForScope(LayrzHighlightScope scope, {required double fontSize}) {
    const font = LayrzJetBrainsMonoFont();
    final color = colorForScope(scope);
    final base = scope == LayrzHighlightScope.function ? font.display : font.body;
    return base.copyWith(fontSize: fontSize, color: color);
  }

  /// Builds a [TextStyle] for every [LayrzHighlightScope] value, sized at
  /// [fontSize].
  ///
  /// Convenient for feeding a syntax-highlighting controller's style
  /// resolver in one call rather than invoking [styleForScope] per scope.
  Map<LayrzHighlightScope, TextStyle> resolveStyles({required double fontSize}) {
    return {
      for (final scope in LayrzHighlightScope.values) scope: styleForScope(scope, fontSize: fontSize),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzCodeThemeExtension &&
          runtimeType == other.runtimeType &&
          background == other.background &&
          foreground == other.foreground &&
          gutterBackground == other.gutterBackground &&
          gutterForeground == other.gutterForeground &&
          currentLineBackground == other.currentLineBackground &&
          errorColor == other.errorColor &&
          keyword == other.keyword &&
          builtin == other.builtin &&
          function == other.function &&
          string == other.string &&
          number == other.number &&
          comment == other.comment &&
          constant == other.constant &&
          decorator == other.decorator &&
          variable == other.variable;

  @override
  int get hashCode => Object.hashAll([
    background,
    foreground,
    gutterBackground,
    gutterForeground,
    currentLineBackground,
    errorColor,
    keyword,
    builtin,
    function,
    string,
    number,
    comment,
    constant,
    decorator,
    variable,
  ]);

  @override
  String toString() =>
      'LayrzCodeThemeExtension(background: $background, foreground: $foreground, '
      'gutterBackground: $gutterBackground, gutterForeground: $gutterForeground, '
      'currentLineBackground: $currentLineBackground, errorColor: $errorColor, '
      'keyword: $keyword, builtin: $builtin, function: $function, string: $string, '
      'number: $number, comment: $comment, constant: $constant, decorator: $decorator, '
      'variable: $variable)';
}

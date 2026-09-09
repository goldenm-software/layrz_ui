import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/highlight/src/highlighter.dart';
import 'package:layrz_ui/src/highlight/src/language.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// A [TextEditingController] that paints its text with syntax highlighting.
///
/// This controller tokenizes its own [text] on every [buildTextSpan] call
/// using `LayrzSyntaxHighlighter.tokenize`, then asks [resolveStyle] for a
/// [TextStyle] per [LayrzHighlightScope] and merges it onto the base style
/// [EditableText] supplies. Merging (never replacing) preserves whatever
/// cursor/line-height metrics the base style carries — callers only need to
/// specify the *colors and weights* they want per scope.
///
/// This class intentionally imports only `package:flutter/widgets.dart`: it
/// has no dependency on any layrz_ui theme, so it can be reused as-is by
/// LayrzMarkdown or any other consumer that wants highlighted, editable
/// code text.
class LayrzHighlightingController extends TextEditingController {
  /// The language used to tokenize [text].
  final LayrzCodeLanguage language;

  /// Resolves the [TextStyle] to apply to text of a given
  /// [LayrzHighlightScope].
  ///
  /// This is a callback rather than a fixed style map so callers can source
  /// colors from any theme system (or none) without this controller taking
  /// a dependency on one.
  final TextStyle Function(LayrzHighlightScope scope) resolveStyle;

  /// Creates a [LayrzHighlightingController] that highlights [text] (or an
  /// empty string, if omitted) as [language], resolving each token's style
  /// via [resolveStyle].
  LayrzHighlightingController({
    required this.language,
    required this.resolveStyle,
    super.text,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;
    final tokens = LayrzSyntaxHighlighter.tokenize(text, language);

    if (composingRegionOutOfRange) {
      return TextSpan(style: style, children: _spansFor(tokens, text, style));
    }

    final composingStart = value.composing.start;
    final composingEnd = value.composing.end;

    final children = <TextSpan>[];
    for (final token in tokens) {
      final overlaps = token.start < composingEnd && token.end > composingStart;

      if (!overlaps) {
        children.add(_spanFor(token, text, style));
        continue;
      }

      // Split the token into up to three pieces so only the slice that
      // actually falls inside the IME composing range gets underlined,
      // mirroring how the base [TextEditingController.buildTextSpan]
      // splices `value.composing` across the plain text.
      final beforeEnd = composingStart.clamp(token.start, token.end);
      final insideEnd = composingEnd.clamp(token.start, token.end);
      final afterStart = insideEnd;

      if (beforeEnd > token.start) {
        children.add(_spanFor(token.copyWith(end: beforeEnd), text, style));
      }
      if (insideEnd > beforeEnd) {
        final composingStyle = _styleFor(
          token.scope,
          style,
        ).merge(const TextStyle(decoration: TextDecoration.underline));
        children.add(TextSpan(text: text.substring(beforeEnd, insideEnd), style: composingStyle));
      }
      if (token.end > afterStart) {
        children.add(_spanFor(token.copyWith(start: afterStart), text, style));
      }
    }

    return TextSpan(style: style, children: children);
  }

  /// Builds one [TextSpan] per [tokens] entry, each merging its scope style
  /// onto [baseStyle].
  List<TextSpan> _spansFor(List<LayrzHighlightToken> tokens, String source, TextStyle? baseStyle) {
    return [for (final token in tokens) _spanFor(token, source, baseStyle)];
  }

  /// Builds a single [TextSpan] for [token]'s slice of [source], with its
  /// scope style merged onto [baseStyle].
  TextSpan _spanFor(LayrzHighlightToken token, String source, TextStyle? baseStyle) {
    return TextSpan(
      text: source.substring(token.start, token.end),
      style: _styleFor(token.scope, baseStyle),
    );
  }

  /// Resolves and merges [scope]'s style onto [baseStyle], falling back to
  /// an empty [TextStyle] base when [baseStyle] is `null`.
  TextStyle _styleFor(LayrzHighlightScope scope, TextStyle? baseStyle) {
    final scopeStyle = resolveStyle(scope);
    return (baseStyle ?? const TextStyle()).merge(scopeStyle);
  }
}

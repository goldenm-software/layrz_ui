import 'package:layrz_ui/src/highlight/src/grammar.dart';
import 'package:layrz_ui/src/highlight/src/grammars/lcl.dart';
import 'package:layrz_ui/src/highlight/src/grammars/lml.dart';
import 'package:layrz_ui/src/highlight/src/grammars/plain.dart';
import 'package:layrz_ui/src/highlight/src/grammars/python.dart';
import 'package:layrz_ui/src/highlight/src/language.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// A language-agnostic, UI-free tokenizer.
///
/// `LayrzSyntaxHighlighter.tokenize` turns a source string into an ordered,
/// non-overlapping list of [LayrzHighlightToken]s covering the whole input.
/// It knows nothing about fonts, colors, or widgets — it is pure text
/// classification, safe to call from anywhere (including outside the
/// Flutter widget tree).
class LayrzSyntaxHighlighter {
  const LayrzSyntaxHighlighter._();

  /// Returns the [LayrzGrammar] backing [language].
  static LayrzGrammar grammarFor(LayrzCodeLanguage language) {
    switch (language) {
      case LayrzCodeLanguage.python:
        return pythonGrammar;
      case LayrzCodeLanguage.lcl:
        return lclGrammar;
      case LayrzCodeLanguage.lml:
        return lmlGrammar;
      case LayrzCodeLanguage.plain:
        return plainGrammar;
    }
  }

  /// Tokenizes [code] as [language] source, returning tokens in source
  /// order that are non-overlapping and together cover every character of
  /// [code].
  ///
  /// The scan is a single left-to-right pass: at each position, every rule
  /// of the language's grammar is tried in order and the first one whose
  /// [LayrzGrammarRule.pattern] matches *at that exact position*
  /// (`Pattern.matchAsPrefix`) wins.
  ///
  /// - A single-match rule (no `endPattern`) emits one token for the match
  ///   and advances past it.
  /// - A span rule (has an `endPattern`) emits one token running from the
  ///   start of the opening match to the end of the *first* `endPattern`
  ///   match found afterward — the search for `endPattern` starts just
  ///   after the opening delimiter, so an escaped or repeated delimiter is
  ///   not specially handled (matching `layrz_theme`'s own grammars, which
  ///   have the same property). If `endPattern` is never found, the span
  ///   runs to the end of [code]; this is a plain [String.indexOf] scan, so
  ///   an unterminated string or comment can never hang or throw.
  /// - If no rule matches at a position, that single character is emitted
  ///   as its own [LayrzHighlightScope.text] token and the scan advances by
  ///   one. Gaps are filled with explicit tokens (rather than left as
  ///   implicit holes) so a renderer can always assume the returned list is
  ///   a complete, contiguous partition of [code] — it never needs to
  ///   reconstruct untouched ranges itself.
  static List<LayrzHighlightToken> tokenize(String code, LayrzCodeLanguage language) {
    final grammar = grammarFor(language);
    final tokens = <LayrzHighlightToken>[];

    var pos = 0;
    final length = code.length;

    while (pos < length) {
      LayrzGrammarRule? matchedRule;
      Match? matchedMatch;

      for (final rule in grammar.rules) {
        final match = rule.pattern.matchAsPrefix(code, pos);
        if (match != null) {
          matchedRule = rule;
          matchedMatch = match;
          break;
        }
      }

      if (matchedRule == null || matchedMatch == null) {
        tokens.add(LayrzHighlightToken(scope: LayrzHighlightScope.text, start: pos, end: pos + 1));
        pos += 1;
        continue;
      }

      if (!matchedRule.isSpan) {
        final end = matchedMatch.end == matchedMatch.start ? matchedMatch.start + 1 : matchedMatch.end;
        tokens.add(LayrzHighlightToken(scope: matchedRule.scope, start: pos, end: end));
        pos = end;
        continue;
      }

      final searchFrom = matchedMatch.end;
      final endMatch = _firstMatchFrom(matchedRule.endPattern!, code, searchFrom);
      final spanEnd = endMatch != null ? endMatch.end : length;
      tokens.add(LayrzHighlightToken(scope: matchedRule.scope, start: pos, end: spanEnd));
      pos = spanEnd;
    }

    return tokens;
  }

  /// Returns the first match of [pattern] in [input] at or after [start],
  /// scanning index by index.
  ///
  /// This is used instead of [RegExp.firstMatch] on a substring so that
  /// match offsets remain relative to the original [input] and so lookahead
  /// in [pattern] (if any) still sees the real surrounding text. It always
  /// terminates in at most `input.length - start` iterations.
  static Match? _firstMatchFrom(RegExp pattern, String input, int start) {
    for (var i = start; i <= input.length; i++) {
      final match = pattern.matchAsPrefix(input, i);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}

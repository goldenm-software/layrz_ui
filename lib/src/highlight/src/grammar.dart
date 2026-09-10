import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/highlight/src/token.dart';

/// A single lexing rule of a [LayrzGrammar].
///
/// A rule is either:
/// - a **single-match rule** ([endPattern] is `null`): [pattern] matches the
///   entire token in one shot (e.g. a number literal, a keyword).
/// - a **span rule** ([endPattern] is non-null): [pattern] matches the
///   *opening* delimiter (e.g. a string's opening quote, a comment's opening
///   marker) and [endPattern] is searched for afterward to find where the
///   span closes. If [endPattern] is never found, the span runs to the end
///   of the input — it never throws and never loops.
@immutable
class LayrzGrammarRule {
  /// The semantic scope assigned to text matched by this rule.
  final LayrzHighlightScope scope;

  /// The pattern that recognizes where this rule starts matching.
  ///
  /// For a single-match rule this pattern matches the whole token. For a
  /// span rule it matches only the opening delimiter.
  final RegExp pattern;

  /// The pattern that closes a span opened by [pattern], or `null` if this
  /// rule is a single-match rule.
  final RegExp? endPattern;

  /// Creates a new [LayrzGrammarRule].
  ///
  /// [scope] and [pattern] are required. [endPattern] is omitted for a
  /// single-match rule and supplied for a span rule (a string or comment
  /// that runs from a begin pattern to an end pattern, possibly across
  /// multiple lines).
  const LayrzGrammarRule({
    required this.scope,
    required this.pattern,
    this.endPattern,
  });

  /// Whether this rule opens a multi-token span rather than matching a
  /// single token outright.
  bool get isSpan => endPattern != null;
}

/// An ordered set of lexing rules for one language.
///
/// Rules are tried in list order at each scan position; the first rule
/// whose [LayrzGrammarRule.pattern] matches at that position wins. Ordering
/// therefore matters — for example, a comment or string rule must precede a
/// keyword rule so that `# def` or `"def"` is not mistaken for the `def`
/// keyword.
@immutable
class LayrzGrammar {
  /// The rules that make up this grammar, in match-priority order.
  final List<LayrzGrammarRule> rules;

  /// Creates a new [LayrzGrammar] backed by [rules].
  const LayrzGrammar({required this.rules});
}

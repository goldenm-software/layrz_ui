import 'package:layrz_ui/src/highlight/src/grammar.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// The [LayrzGrammar] for Layrz Markup Language.
///
/// LML is plain template text: prose meant to be shown to an end user, with
/// mustache-style interpolation variables spliced in — `{{assetName}}`,
/// `{{ asset.name }}`. Highlighting exists only to make those variables pop
/// out of the surrounding text, so this grammar has exactly one rule: the
/// mustache-variable pattern, scoped as [LayrzHighlightScope.variable]
/// (ported from `layrz_theme`'s `lml/src/functions.dart`, which defines this
/// exact pattern under a `lclFunctions` constant — a distinct definition
/// from LCL's own despite the shared name).
///
/// Everything else — prose, punctuation, apostrophes, numbers, or any other
/// embedded text — is deliberately left unhighlighted and renders as plain
/// [LayrzHighlightScope.text]. This is a reversal of an earlier version of
/// this grammar, which also highlighted embedded LCL function calls,
/// quoted strings, numeric literals, and `True`/`False`/`None` constants.
/// In practice that treated ordinary prose as code: an apostrophe in "it's"
/// opened a string span, and any uppercase word that happened to match an
/// LCL function name (e.g. `COMPARE`) lit up as a function call. LML is now
/// treated as prose-with-variables only — LCL keeps its own grammar
/// ([lclGrammar]) for when LCL code is the thing being highlighted.
final LayrzGrammar lmlGrammar = LayrzGrammar(
  rules: [
    LayrzGrammarRule(
      scope: LayrzHighlightScope.variable,
      pattern: RegExp(r'\{\{[ \t]*[\w.]+[ \t]*\}\}'),
    ),
  ],
);

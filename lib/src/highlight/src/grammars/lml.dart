import 'package:layrz_ui/src/highlight/src/grammar.dart';
import 'package:layrz_ui/src/highlight/src/grammars/lcl.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// The [LayrzGrammar] for Layrz Markup Language.
///
/// LML is a superset of plain template text that can also embed LCL code
/// inline, so its grammar highlights both surfaces at once:
///
/// - Its own mustache-style interpolation variables, `{{ ... }}` (e.g.
///   `{{assetName}}`, `{{ asset.name }}`) — ported from `layrz_theme`'s
///   `lml/src/functions.dart`, which defines this exact pattern under a
///   `lclFunctions` constant that is a distinct definition from LCL's own
///   (the two live in unrelated `part of` scopes despite sharing a name).
///   Here it gets its own scope, [LayrzHighlightScope.variable], so it is
///   never confused with a function call.
/// - LCL's built-in function names ([lclFunctionNames]) — because LCL code
///   can be injected inside an LML document, and when it is, those calls
///   should highlight exactly as they do in LCL itself. Reusing
///   [lclFunctionNames] (rather than redeclaring the list) keeps LCL's
///   function surface as the single source of truth for both grammars.
///
/// Rule order matters: the mustache-variable rule runs first so an entire
/// `{{...}}` span — braces and inner content together — is captured as one
/// [LayrzHighlightScope.variable] token before the function-name rule ever
/// gets a chance to split it apart (a variable name can otherwise collide
/// with, or sit next to, an LCL function name).
final LayrzGrammar lmlGrammar = LayrzGrammar(
  rules: [
    LayrzGrammarRule(
      scope: LayrzHighlightScope.variable,
      pattern: RegExp(r'\{\{[ \t]*[\w.]+[ \t]*\}\}'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.function,
      pattern: RegExp(r'\b(' + lclFunctionNames.join('|') + r')\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.string,
      pattern: RegExp('"'),
      endPattern: RegExp('"'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.string,
      pattern: RegExp("'"),
      endPattern: RegExp("'"),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.constant,
      pattern: RegExp(r'\b(True|true|False|false|None|none)\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.number,
      pattern: RegExp(r'\b\d+(\.\d+)?\b'),
    ),
  ],
);

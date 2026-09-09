/// The set of languages the syntax-highlighting engine understands.
///
/// Each value maps to exactly one [LayrzGrammar] via
/// `LayrzSyntaxHighlighter.tokenize`. Adding a new language means adding a
/// value here, a grammar file under `lib/src/highlight/src/grammars/`, and a
/// branch in the highlighter's grammar lookup.
enum LayrzCodeLanguage {
  /// Python source code.
  ///
  /// Highlights comments, single- and triple-quoted strings, decorators,
  /// numbers (including hex literals), keywords, and common builtins.
  python,

  /// Layrz Compute Language, the formula language used by Layrz's computed
  /// sensors and triggers (e.g. `GET_SENSOR(...)`, `IF(...)`).
  ///
  /// Highlights its built-in function names, strings, numbers, and the
  /// `True`/`False`/`None` constants (case-insensitive, matching the
  /// language's own runtime).
  lcl,

  /// Layrz Markup Language, the templating language used to render dynamic
  /// text (e.g. case/report templates) with Layrz-provided placeholders.
  ///
  /// Highlights the same function-call surface as [lcl], plus strings,
  /// numbers, and constants.
  lml,
}

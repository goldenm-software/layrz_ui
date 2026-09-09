import 'package:layrz_ui/src/highlight/src/grammar.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// Python's reserved keywords recognized by this grammar.
const List<String> pythonKeywords = [
  'def',
  'class',
  'return',
  'if',
  'elif',
  'else',
  'for',
  'while',
  'in',
  'not',
  'and',
  'or',
  'import',
  'from',
  'as',
  'with',
  'try',
  'except',
  'finally',
  'raise',
  'pass',
  'break',
  'continue',
  'lambda',
  'yield',
  'global',
  'nonlocal',
  'assert',
  'del',
  'is',
  'async',
  'await',
];

/// Common Python builtin names recognized by this grammar.
///
/// `True`, `False`, and `None` are deliberately excluded here and matched by
/// the dedicated `constant` rule instead, so they render with
/// [LayrzHighlightScope.constant] rather than [LayrzHighlightScope.builtin] —
/// consistent with how LCL and LML classify their own boolean/none literals.
const List<String> pythonBuiltins = [
  'print',
  'len',
  'range',
  'int',
  'str',
  'float',
  'bool',
  'list',
  'dict',
  'set',
  'tuple',
  'type',
  'isinstance',
  'enumerate',
  'zip',
  'map',
  'filter',
  'open',
  'super',
  'object',
];

/// The [LayrzGrammar] for Python.
///
/// `layrz_theme` merely re-exports the `highlight` package's built-in
/// Python grammar (`export 'package:highlight/languages/python.dart'`), so
/// there is no source to port from — this grammar is authored from scratch
/// for `layrz_ui`.
///
/// Rule order is deliberate: comments and both string forms are checked
/// *before* keywords/builtins/decorators, so a keyword-looking substring
/// inside a comment or string (e.g. `# def` or `"def"`) is classified as
/// [LayrzHighlightScope.comment] / [LayrzHighlightScope.string] and never
/// re-matched as [LayrzHighlightScope.keyword].
final LayrzGrammar pythonGrammar = LayrzGrammar(
  rules: [
    LayrzGrammarRule(
      scope: LayrzHighlightScope.comment,
      pattern: RegExp(r'#[^\n]*'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.string,
      pattern: RegExp('"""'),
      endPattern: RegExp('"""'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.string,
      pattern: RegExp("'''"),
      endPattern: RegExp("'''"),
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
      scope: LayrzHighlightScope.decorator,
      pattern: RegExp(r'@\w+'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.number,
      pattern: RegExp(r'\b0x[0-9a-fA-F]+\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.number,
      pattern: RegExp(r'\b\d+(\.\d+)?\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.constant,
      pattern: RegExp(r'\b(True|False|None)\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.keyword,
      pattern: RegExp(r'\b(' + pythonKeywords.join('|') + r')\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.builtin,
      pattern: RegExp(r'\b(' + pythonBuiltins.join('|') + r')\b'),
    ),
  ],
);

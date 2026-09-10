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
  'sum',
  'round',
  'min',
  'max',
  'abs',
  'sorted',
  'reversed',
  'any',
  'all',
  'format',
  'repr',
  'hash',
  'id',
  'input',
  'next',
  'iter',
  'bytes',
  'frozenset',
  'callable',
  'getattr',
  'setattr',
  'hasattr',
  'divmod',
  'pow',
  'chr',
  'ord',
  'Optional',
  'List',
  'Dict',
  'Set',
  'Tuple',
  'Union',
  'Any',
  'Callable',
  'Iterator',
  'Iterable',
  'Sequence',
  'Mapping',
  'Type',
  'Generator',
  'Awaitable',
  'Coroutine',
  'AsyncIterator',
  'AsyncIterable',
  'Literal',
  'Final',
  'Annotated',
  'TypeVar',
  'Protocol',
  'NamedTuple',
  'TypedDict',
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
///
/// The ALL-UPPERCASE constant rule (`PRIMARY`, `MAX_SPEED`, ...) is placed
/// after comment/string/decorator/number/constant/keyword/builtin — matching
/// the convention that Python module-level constants are written in
/// `SCREAMING_SNAKE_CASE`. It comes last of the identifier-classifying rules
/// so it only ever claims an all-caps word that no earlier, more specific
/// rule already recognized: Python's keywords are lowercase and its builtins
/// are lowercase or CamelCase, so there is no collision in practice, but the
/// ordering keeps that guarantee explicit rather than incidental. This rule
/// is intentionally Python-only — LCL's function names are ALL-CAPS by
/// convention too (`GET_PARAM`, `COMPARE`) and are already correctly
/// [LayrzHighlightScope.function]-scoped by LCL's own grammar; adding this
/// rule there would wrongly recolor them as constants instead.
///
/// The [LayrzHighlightScope.functionCall] rule matches a bare identifier
/// immediately followed by `(` — a lookahead (`(?=\()`) that captures only
/// the name, not the paren — and is placed after
/// comment/string/decorator/number/constant/keyword/builtin/uppercase-
/// constant but *before* the operator rule. That ordering is what makes the
/// split work:
///
///  * A builtin call like `len(` or `sum(` is already claimed by the
///    builtin rule by the time this one runs, so it stays
///    [LayrzHighlightScope.builtin] (blue) and is never re-matched here.
///  * A keyword immediately followed by `(`, e.g. the `if` in `if (x):`,
///    is claimed by the keyword rule first and likewise never reaches this
///    rule.
///  * An ALL-UPPERCASE name followed by `(` is claimed by the uppercase-
///    constant rule first, so it stays [LayrzHighlightScope.constant].
///  * Everything left over — a non-builtin, non-keyword, non-all-caps
///    identifier directly followed by `(` — is a user-defined function,
///    both at its call site (`average(x)`) and at its `def average(...):`
///    definition site, since `def` itself is consumed separately by the
///    keyword rule. Those get [LayrzHighlightScope.functionCall] (green),
///    kept distinct from [LayrzHighlightScope.function] so LCL/LML builtin
///    function names — which use [LayrzHighlightScope.function] — are
///    unaffected by this Python-only rule.
///
/// The [LayrzHighlightScope.operator] rule is placed last of all, after
/// comments/strings/decorator/number/constant/keyword/builtin/uppercase-
/// constant/function-call, so an operator-looking substring inside a string
/// or comment (e.g. `"a == b"` or `# a -> b`) is never re-matched as
/// [LayrzHighlightScope.operator], and so it never competes with the number
/// rule's own handling of `.` in float literals, the decorator rule's
/// handling of `@`, or the function-call rule's lookahead on `(`.
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
    LayrzGrammarRule(
      scope: LayrzHighlightScope.constant,
      pattern: RegExp(r'\b[A-Z][A-Z0-9_]+\b'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.functionCall,
      pattern: RegExp(r'\b[A-Za-z_]\w*(?=\()'),
    ),
    LayrzGrammarRule(
      scope: LayrzHighlightScope.operator,
      pattern: RegExp(r'(==|!=|<=|>=|->|\*\*|//|[-+*/%=<>&|^~])'),
    ),
  ],
);

import 'package:layrz_ui/src/highlight/src/grammar.dart';
import 'package:layrz_ui/src/highlight/src/token.dart';

/// The built-in function names recognized by Layrz Compute Language.
///
/// Ported verbatim from `layrz_theme`'s
/// `lib/src/languages/lcl/src/functions.dart`. Also reused by the LML
/// grammar (`grammars/lml.dart`), matching how `layrz_theme` builds LML's
/// function highlighting from LCL's function list.
const List<String> lclFunctionNames = [
  'GET_PARAM',
  'GET_SENSOR',
  'CONSTANT',
  'GET_CUSTOM_FIELD',
  'COMPARE',
  'OR_OPERATOR',
  'AND_OPERATOR',
  'SUM',
  'SUBSTRACT',
  'MULTIPLY',
  'DIVIDE',
  'TO_BOOL',
  'TO_STR',
  'TO_INT',
  'TO_FLOAT',
  'CEIL',
  'FLOOR',
  'ROUND',
  'SQRT',
  'CONCAT',
  'NOW',
  'RANDOM',
  'RANDOM_INT',
  'GREATER_THAN_OR_EQUALS_TO',
  'GREATER_THAN',
  'LESS_THAN_OR_EQUALS_TO',
  'LESS_THAN',
  'DIFFERENT',
  'HEX_TO_STR',
  'STR_TO_HEX',
  'HEX_TO_INT',
  'INT_TO_HEX',
  'IS_PARAMETER_PRESENT',
  'IS_SENSOR_PRESENT',
  'INSIDE_RANGE',
  'OUTSIDE_RANGE',
  'GET_TIME_DIFFERENCE',
  'IF',
  'REGEX',
  'IS_NONE',
  'GET_DISTANCE_TRAVELED',
  'GET_PREVIOUS_SENSOR',
  'NOT',
  'CONTAINS',
  'STARTS_WITH',
  'ENDS_WITH',
  'PRIMARY_DEVICE',
  'SUBSTRING',
];

/// The [LayrzGrammar] for Layrz Compute Language.
///
/// Ported from `layrz_theme`'s `lib/src/languages/lcl/lcl.dart`. Rule order
/// follows the source `Mode.contains` list: function names first, then
/// double- and single-quoted strings, then the boolean/none constants, then
/// numbers.
final LayrzGrammar lclGrammar = LayrzGrammar(
  rules: [
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

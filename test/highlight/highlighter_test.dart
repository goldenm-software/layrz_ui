import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

/// Extracts just the scope sequence from [tokens], dropping offsets, for
/// terser assertions on tokenization shape.
List<LayrzHighlightScope> _scopes(List<LayrzHighlightToken> tokens) => [for (final t in tokens) t.scope];

/// Reconstructs the substrings each token in [tokens] covers from [source].
List<String> _texts(List<LayrzHighlightToken> tokens, String source) => [
  for (final t in tokens) source.substring(t.start, t.end),
];

void main() {
  group('LayrzSyntaxHighlighter.tokenize (LCL)', () {
    test('recognizes a function call, string, and number', () {
      const code = 'GET_SENSOR("speed", 10)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lcl);

      expect(_scopes(tokens), contains(LayrzHighlightScope.function));
      expect(_scopes(tokens), contains(LayrzHighlightScope.string));
      expect(_scopes(tokens), contains(LayrzHighlightScope.number));

      final functionToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.function);
      expect(code.substring(functionToken.start, functionToken.end), 'GET_SENSOR');

      final stringToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.string);
      expect(code.substring(stringToken.start, stringToken.end), '"speed"');

      final numberToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.number);
      expect(code.substring(numberToken.start, numberToken.end), '10');
    });

    test('recognizes constants True/False/None case-insensitively', () {
      for (final literal in ['True', 'true', 'False', 'false', 'None', 'none']) {
        final tokens = LayrzSyntaxHighlighter.tokenize(literal, LayrzCodeLanguage.lcl);
        expect(_scopes(tokens), contains(LayrzHighlightScope.constant), reason: 'for literal "$literal"');
      }
    });

    test('tokens cover the entire input contiguously', () {
      const code = 'IF(COMPARE(GET_SENSOR("x"), 1), "yes", "no")';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lcl);

      expect(tokens, isNotEmpty);
      expect(tokens.first.start, 0);
      expect(tokens.last.end, code.length);
      for (var i = 1; i < tokens.length; i++) {
        expect(tokens[i].start, tokens[i - 1].end, reason: 'gap between token $i and ${i - 1}');
      }
      expect(_texts(tokens, code).join(), code);
    });

    test('an unterminated string runs to end-of-input without hanging', () {
      const code = 'GET_SENSOR("unterminated';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lcl);

      final stringToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.string);
      expect(stringToken.end, code.length);
    });

    test('COMPARE and GET_PARAM stay function-scoped, unaffected by the Python functionCall split', () {
      const code = 'COMPARE(GET_PARAM("speed"), 10)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lcl);

      final functionTexts = _texts(tokens.where((t) => t.scope == LayrzHighlightScope.function).toList(), code);
      expect(functionTexts, containsAll(['COMPARE', 'GET_PARAM']));
      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.functionCall)));
    });
  });

  group('LayrzSyntaxHighlighter.tokenize (LML)', () {
    test('recognizes a mustache template variable as `variable`', () {
      const code = 'Hello {{assetName}}!';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      final variableToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.variable);
      expect(code.substring(variableToken.start, variableToken.end), '{{assetName}}');
    });

    test('recognizes a mustache variable with inner whitespace and dot access', () {
      const code = 'Owner: {{ asset.name }}';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      final variableToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.variable);
      expect(code.substring(variableToken.start, variableToken.end), '{{ asset.name }}');
    });

    test('tokens cover the entire input contiguously', () {
      const code = 'Hello {{assetName}}, welcome!';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);
      expect(_texts(tokens, code).join(), code);
    });

    test('tokenizes real prose correctly: only the two mustache spans are `variable`, and the '
        "apostrophe in \"it's\" does not open a string", () {
      const code = "The name of the asset is {{assetName}} and it's a great asset, message sent at {{executedAt}}.";
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      final variableTokens = tokens.where((t) => t.scope == LayrzHighlightScope.variable).toList();
      expect(_texts(variableTokens, code), ['{{assetName}}', '{{executedAt}}']);

      // The apostrophe in "it's" must NOT open a string span — everything
      // outside the two mustache variables is plain `text`.
      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.string)));

      final nonVariableTokens = tokens.where((t) => t.scope != LayrzHighlightScope.variable);
      expect(nonVariableTokens, isNotEmpty);
      for (final token in nonVariableTokens) {
        expect(token.scope, LayrzHighlightScope.text);
      }

      expect(_texts(tokens, code).join(), code);
    });

    test('an LCL function name embedded in LML prose is no longer highlighted as `function`', () {
      const code = 'Value is COMPARE and done';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.function)));

      final compareStart = code.indexOf('COMPARE');
      final compareToken = tokens.firstWhere((t) => t.start <= compareStart && t.end > compareStart);
      expect(compareToken.scope, LayrzHighlightScope.text);
    });

    test('a number in LML prose is plain text, not `number`', () {
      const code = 'There are 42 assets online';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.number)));
      expect(_scopes(tokens), everyElement(LayrzHighlightScope.text));
    });

    test('`True` in LML prose is plain text, not `constant`', () {
      const code = 'The result is True for this asset';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.constant)));
      expect(_scopes(tokens), everyElement(LayrzHighlightScope.text));
    });

    test('the mustache rule is the only rule: a bare `{{assetName}}` tokenizes as one `variable` token', () {
      const code = '{{assetName}}';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.variable);
    });
  });

  group('LayrzSyntaxHighlighter.tokenize (Python)', () {
    test('recognizes a comment to end of line', () {
      const code = '# this is a comment\nx = 1';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final commentToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.comment);
      expect(code.substring(commentToken.start, commentToken.end), '# this is a comment');
    });

    test('recognizes a multi-line triple-quoted string', () {
      const code = '"""\nline one\nline two\n"""';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.string);
      expect(tokens.single.start, 0);
      expect(tokens.single.end, code.length);
    });

    test('recognizes a single-quoted multi-line triple string variant', () {
      const code = "'''\nabc\n'''";
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.string);
      expect(tokens.single.end, code.length);
    });

    test('does NOT tokenize "def" inside a string as a keyword', () {
      const code = 'x = "def"';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.keyword)));
      final stringToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.string);
      expect(code.substring(stringToken.start, stringToken.end), '"def"');
    });

    test('does NOT tokenize "#def" inside a comment as a keyword', () {
      const code = '#def not a keyword';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.comment);
    });

    test('recognizes a real keyword outside strings/comments', () {
      const code = 'def foo():\n    return 1';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final keywordTokens = tokens.where((t) => t.scope == LayrzHighlightScope.keyword).toList();
      expect(_texts(keywordTokens, code), containsAll(['def', 'return']));
    });

    test('recognizes a decorator', () {
      const code = '@staticmethod\ndef foo(): pass';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final decoratorToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.decorator);
      expect(code.substring(decoratorToken.start, decoratorToken.end), '@staticmethod');
    });

    test('recognizes decimal and hex numbers', () {
      const code = 'x = 42 + 0x1F';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final numberTokens = tokens.where((t) => t.scope == LayrzHighlightScope.number).toList();
      expect(_texts(numberTokens, code), containsAll(['42', '0x1F']));
    });

    test('recognizes builtins distinctly from keywords', () {
      const code = 'print(len(x))';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final builtinTokens = tokens.where((t) => t.scope == LayrzHighlightScope.builtin).toList();
      expect(_texts(builtinTokens, code), containsAll(['print', 'len']));
    });

    test('recognizes sum and round as builtins', () {
      const code = 'total = sum(values)\navg = round(total / count, 2)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final builtinTokens = tokens.where((t) => t.scope == LayrzHighlightScope.builtin).toList();
      expect(_texts(builtinTokens, code), containsAll(['sum', 'round']));
    });

    test('recognizes the newly added builtin peers', () {
      const names = [
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
      ];
      for (final name in names) {
        final code = '$name(x)';
        final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);
        final builtinTokens = tokens.where((t) => t.scope == LayrzHighlightScope.builtin).toList();
        expect(_texts(builtinTokens, code), contains(name), reason: 'for builtin "$name"');
      }
    });

    test('recognizes typing module names as builtins', () {
      const code =
          'def f(x: Optional[int]) -> List[str]:\n    y: Dict[str, Any] = {}\n    z: Union[Callable, None] = None';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final builtinTokens = tokens.where((t) => t.scope == LayrzHighlightScope.builtin).toList();
      final builtinTexts = _texts(builtinTokens, code);
      expect(builtinTexts, containsAll(['Optional', 'List', 'Dict', 'Union', 'Callable', 'Any', 'int', 'str']));

      final operatorTokens = tokens.where((t) => t.scope == LayrzHighlightScope.operator).toList();
      expect(_texts(operatorTokens, code), contains('->'));
    });

    test('recognizes == and -> as operator tokens', () {
      const code = 'def f(x) -> int:\n    return x == 1';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final operatorTokens = tokens.where((t) => t.scope == LayrzHighlightScope.operator).toList();
      expect(_texts(operatorTokens, code), containsAll(['->', '==']));
    });

    test('recognizes / and - as operator tokens', () {
      const code = 'total / (count - 1)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final operatorTokens = tokens.where((t) => t.scope == LayrzHighlightScope.operator).toList();
      expect(_texts(operatorTokens, code), containsAll(['/', '-']));
    });

    test('does NOT tokenize == inside a string as an operator', () {
      const code = '"a == b"';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.operator)));
      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.string);
    });

    test('does NOT tokenize -> inside a comment as an operator', () {
      const code = '# a -> b';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.comment);
    });

    test('the . in a float literal stays part of the number, not an operator', () {
      const code = 'x = 3.14';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final numberToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.number);
      expect(code.substring(numberToken.start, numberToken.end), '3.14');

      // The `=` legitimately tokenizes as an operator; only the `.` inside
      // the float literal must NOT be split out as one.
      final operatorTokens = tokens.where((t) => t.scope == LayrzHighlightScope.operator).toList();
      expect(_texts(operatorTokens, code), isNot(contains('.')));
    });

    test('recognizes True/False/None as constants', () {
      const code = 'ok = True or False or None';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final constantTokens = tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList();
      expect(_texts(constantTokens, code), ['True', 'False', 'None']);
    });

    test('recognizes ALL-UPPERCASE identifiers as constants', () {
      for (final name in ['PRIMARY', 'LABEL', 'THRESHOLD', 'MAX_SPEED']) {
        final code = '$name = 1';
        final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);
        final constantTokens = tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList();
        expect(_texts(constantTokens, code), contains(name), reason: 'for identifier "$name"');
      }
    });

    test('tokenizes a module-level constants snippet correctly end to end', () {
      const code = 'PRIMARY = True\nLABEL = "sensor.speed"\nTHRESHOLD = 0x1F';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final constantTokens = tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList();
      expect(_texts(constantTokens, code), containsAll(['PRIMARY', 'LABEL', 'THRESHOLD', 'True']));

      final stringTokens = tokens.where((t) => t.scope == LayrzHighlightScope.string).toList();
      expect(_texts(stringTokens, code), contains('"sensor.speed"'));

      final numberTokens = tokens.where((t) => t.scope == LayrzHighlightScope.number).toList();
      expect(_texts(numberTokens, code), contains('0x1F'));

      final operatorTokens = tokens.where((t) => t.scope == LayrzHighlightScope.operator).toList();
      expect(operatorTokens, hasLength(3));
      expect(_texts(operatorTokens, code), everyElement('='));
    });

    test('does NOT miscatch mixed-case names or lowercase identifiers as constants', () {
      const code = 'def f(x: Optional[int]) -> List[str]:\n    count = 1\n    values = []';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final constantTexts = _texts(tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList(), code);
      expect(constantTexts, isNot(contains('Optional')));
      expect(constantTexts, isNot(contains('List')));
      expect(constantTexts, isNot(contains('count')));
      expect(constantTexts, isNot(contains('values')));

      final builtinTexts = _texts(tokens.where((t) => t.scope == LayrzHighlightScope.builtin).toList(), code);
      expect(builtinTexts, containsAll(['Optional', 'List']));

      // Unmatched source falls back to one-char `text` tokens (never a
      // single multi-char token per word), so `count`/`values` are proven
      // un-classified by confirming every character across each word's span
      // is individually `text`, not by reassembling the whole word from one
      // token.
      for (final word in ['count', 'values']) {
        final offset = code.indexOf(word);
        for (var i = offset; i < offset + word.length; i++) {
          final charToken = tokens.firstWhere((t) => t.start == i && t.end == i + 1);
          expect(charToken.scope, LayrzHighlightScope.text, reason: 'char "${code[i]}" of "$word"');
        }
      }
    });

    test('does NOT miscatch a single uppercase letter as a constant', () {
      const code = 'X = 1';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final constantTexts = _texts(tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList(), code);
      expect(constantTexts, isNot(contains('X')));

      final textToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'X');
      expect(textToken.scope, LayrzHighlightScope.text);
    });

    test('a Python keyword and builtin are unaffected by the constant rule', () {
      const code = 'def foo():\n    return len(values)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final defToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'def');
      expect(defToken.scope, LayrzHighlightScope.keyword);

      final lenToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'len');
      expect(lenToken.scope, LayrzHighlightScope.builtin);
    });

    test('an unterminated string runs to end-of-input without hanging', () {
      const code = 'x = "unterminated';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final stringToken = tokens.firstWhere((t) => t.scope == LayrzHighlightScope.string);
      expect(stringToken.end, code.length);
    });

    test('an unterminated triple-quoted string runs to end-of-input without hanging', () {
      const code = '"""\nunterminated triple string with no closing marker';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, hasLength(1));
      expect(tokens.single.scope, LayrzHighlightScope.string);
      expect(tokens.single.end, code.length);
    });

    test('tokens cover the entire input contiguously', () {
      const code = '''
# header comment
@decorator
def compute(x):
    """docstring"""
    return x + 1
''';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      expect(tokens, isNotEmpty);
      expect(tokens.first.start, 0);
      expect(tokens.last.end, code.length);
      for (var i = 1; i < tokens.length; i++) {
        expect(tokens[i].start, tokens[i - 1].end, reason: 'gap between token $i and ${i - 1}');
      }
      expect(_texts(tokens, code).join(), code);
    });

    test('empty input produces no tokens', () {
      final tokens = LayrzSyntaxHighlighter.tokenize('', LayrzCodeLanguage.python);
      expect(tokens, isEmpty);
    });

    test('recognizes the defined name in "def average(values):" as a functionCall', () {
      const code = 'def average(values):\n    return sum(values) / len(values)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final defToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'def');
      expect(defToken.scope, LayrzHighlightScope.keyword);

      final nameToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'average');
      expect(nameToken.scope, LayrzHighlightScope.functionCall);
    });

    test('recognizes a call to a user-defined function as functionCall', () {
      const code = 'result = average(x)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final callToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'average');
      expect(callToken.scope, LayrzHighlightScope.functionCall);
    });

    test('does NOT reclassify "len" as functionCall — builtins stay builtin', () {
      const code = 'count = len(values)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final lenToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'len');
      expect(lenToken.scope, LayrzHighlightScope.builtin);
      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.functionCall)));
    });

    test('does NOT reclassify "sum" or "round" as functionCall — builtins stay builtin', () {
      const code = 'total = sum(x)\navg = round(y)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final sumToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'sum');
      final roundToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'round');
      expect(sumToken.scope, LayrzHighlightScope.builtin);
      expect(roundToken.scope, LayrzHighlightScope.builtin);
    });

    test('does NOT reclassify a keyword immediately followed by "(" as functionCall', () {
      const code = 'if (x):\n    pass';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final ifToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'if');
      expect(ifToken.scope, LayrzHighlightScope.keyword);
      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.functionCall)));
    });

    test('an ALL-UPPERCASE name followed by "(" stays a constant, not functionCall', () {
      const code = 'MAX_SPEED(x)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final nameToken = tokens.firstWhere((t) => code.substring(t.start, t.end) == 'MAX_SPEED');
      expect(nameToken.scope, LayrzHighlightScope.constant);
      expect(_scopes(tokens), isNot(contains(LayrzHighlightScope.functionCall)));
    });
  });

  group('LayrzSyntaxHighlighter.grammarFor', () {
    test('returns a distinct grammar per language', () {
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.python), same(pythonGrammar));
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.lcl), same(lclGrammar));
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.lml), same(lmlGrammar));
    });
  });
}

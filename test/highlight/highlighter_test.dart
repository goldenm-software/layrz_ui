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
  });

  group('LayrzSyntaxHighlighter.tokenize (LML)', () {
    test('recognizes the same function names as LCL', () {
      const code = 'CONCAT(GET_PARAM("a"), GET_PARAM("b"))';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      final functionTokens = tokens.where((t) => t.scope == LayrzHighlightScope.function).toList();
      expect(functionTokens, hasLength(3));
      expect(_texts(functionTokens, code), ['CONCAT', 'GET_PARAM', 'GET_PARAM']);
    });

    test('tokens cover the entire input contiguously', () {
      const code = 'SUM(1, 2)';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);
      expect(_texts(tokens, code).join(), code);
    });

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

    test('recognizes an LCL function name injected inside LML as `function`', () {
      const code = 'Speed is {{assetName}}: value={{SUM(1, 2)}}';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      // `{{SUM(1, 2)}}` is not a bare `{{ identifier }}` mustache variable
      // (it contains parens and a comma), so the mustache rule does not
      // swallow it whole — the embedded LCL function name inside is free to
      // match the function-name rule instead.
      final functionTokens = tokens.where((t) => t.scope == LayrzHighlightScope.function).toList();
      expect(_texts(functionTokens, code), contains('SUM'));
    });

    test('mixes mustache variables and embedded LCL function calls in one document', () {
      const code = 'Report for {{assetName}}: total={{ GET_SENSOR("speed") }} check {{ CONCAT("a", "b") }}';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.lml);

      final variableTokens = tokens.where((t) => t.scope == LayrzHighlightScope.variable).toList();
      expect(_texts(variableTokens, code), contains('{{assetName}}'));

      final functionTokens = tokens.where((t) => t.scope == LayrzHighlightScope.function).toList();
      expect(_texts(functionTokens, code), containsAll(['GET_SENSOR', 'CONCAT']));

      final stringTokens = tokens.where((t) => t.scope == LayrzHighlightScope.string).toList();
      expect(_texts(stringTokens, code), containsAll(['"speed"', '"a"', '"b"']));

      expect(_texts(tokens, code).join(), code);
    });

    test('the mustache rule is tried before the function-name rule', () {
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

    test('recognizes True/False/None as constants', () {
      const code = 'ok = True or False or None';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.python);

      final constantTokens = tokens.where((t) => t.scope == LayrzHighlightScope.constant).toList();
      expect(_texts(constantTokens, code), ['True', 'False', 'None']);
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
  });

  group('LayrzSyntaxHighlighter.grammarFor', () {
    test('returns a distinct grammar per language', () {
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.python), same(pythonGrammar));
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.lcl), same(lclGrammar));
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.lml), same(lmlGrammar));
    });
  });
}

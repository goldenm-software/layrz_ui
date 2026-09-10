import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/highlight/highlight.dart';

void main() {
  group('LayrzSyntaxHighlighter.tokenize (plain)', () {
    test('every token is scoped as text', () {
      const code = 'anything {code} 123';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.plain);

      expect(tokens, isNotEmpty);
      for (final token in tokens) {
        expect(token.scope, LayrzHighlightScope.text);
      }
    });

    test('tokens cover the whole input contiguously with no gaps', () {
      const code = 'anything {code} 123';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.plain);

      expect(tokens.first.start, 0);
      expect(tokens.last.end, code.length);
      for (var i = 1; i < tokens.length; i++) {
        expect(tokens[i].start, tokens[i - 1].end, reason: 'gap between token $i and ${i - 1}');
      }

      final reconstructed = [for (final t in tokens) code.substring(t.start, t.end)].join();
      expect(reconstructed, code);
    });

    test('never emits keyword/string/number/comment scopes for content that would trigger them in other languages', () {
      const code = '# not a comment\ndef "not a string" 42 @not_a_decorator';
      final tokens = LayrzSyntaxHighlighter.tokenize(code, LayrzCodeLanguage.plain);

      expect(tokens, isNotEmpty);
      expect(tokens.every((t) => t.scope == LayrzHighlightScope.text), isTrue);
    });

    test('empty input produces no tokens', () {
      final tokens = LayrzSyntaxHighlighter.tokenize('', LayrzCodeLanguage.plain);
      expect(tokens, isEmpty);
    });

    test('grammarFor(plain) resolves to the empty plainGrammar', () {
      expect(LayrzSyntaxHighlighter.grammarFor(LayrzCodeLanguage.plain), same(plainGrammar));
      expect(plainGrammar.rules, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

void main() {
  group('LayrzHighlightToken', () {
    test('length returns end - start', () {
      const token = LayrzHighlightToken(scope: LayrzHighlightScope.keyword, start: 3, end: 7);
      expect(token.length, 4);
    });

    test('== and hashCode are structural', () {
      const a = LayrzHighlightToken(scope: LayrzHighlightScope.string, start: 0, end: 5);
      const b = LayrzHighlightToken(scope: LayrzHighlightScope.string, start: 0, end: 5);
      const c = LayrzHighlightToken(scope: LayrzHighlightScope.string, start: 0, end: 6);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces only the given fields', () {
      const original = LayrzHighlightToken(scope: LayrzHighlightScope.number, start: 1, end: 2);
      final copy = original.copyWith(end: 9);

      expect(copy.scope, LayrzHighlightScope.number);
      expect(copy.start, 1);
      expect(copy.end, 9);
    });

    test('copyWith with no arguments returns an equal token', () {
      const original = LayrzHighlightToken(scope: LayrzHighlightScope.comment, start: 4, end: 8);
      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('toString includes scope, start, and end', () {
      const token = LayrzHighlightToken(scope: LayrzHighlightScope.function, start: 0, end: 3);
      expect(token.toString(), contains('function'));
      expect(token.toString(), contains('0'));
      expect(token.toString(), contains('3'));
    });
  });
}

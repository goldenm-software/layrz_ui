import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layrz_ui/src/search/src/find_text_occurrences.dart';

void main() {
  group('findAllTextOccurrences', () {
    test('finds a single occurrence', () {
      final hits = findAllTextOccurrences('a mango here', 'mango', caseSensitive: false);
      expect(hits, [const TextRange(start: 2, end: 7)]);
    });

    test('finds every non-overlapping occurrence, advancing past each full match', () {
      final hits = findAllTextOccurrences('aaaa', 'aa', caseSensitive: false);
      expect(hits, [const TextRange(start: 0, end: 2), const TextRange(start: 2, end: 4)]);
    });

    test('returns an empty list when there is no occurrence', () {
      expect(findAllTextOccurrences('nothing here', 'mango', caseSensitive: false), isEmpty);
    });

    test('is case-insensitive by default, reporting offsets against the original-case haystack', () {
      final hits = findAllTextOccurrences('A MANGO label', 'mango', caseSensitive: false);
      expect(hits, [const TextRange(start: 2, end: 7)]);
    });

    test('caseSensitive: true requires an exact-case match', () {
      expect(findAllTextOccurrences('A MANGO label', 'mango', caseSensitive: true), isEmpty);
      expect(
        findAllTextOccurrences('A mango label', 'mango', caseSensitive: true),
        [const TextRange(start: 2, end: 7)],
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/table/src/sort.dart';

void main() {
  group('defaultSortCompare', () {
    group('numeric comparison', () {
      test('ascending orders smaller numeric string first', () {
        expect(defaultSortCompare('2', '10', ascending: true), lessThan(0));
      });

      test('descending orders larger numeric string first', () {
        expect(defaultSortCompare('2', '10', ascending: false), greaterThan(0));
      });

      test('equal numeric strings compare as 0', () {
        expect(defaultSortCompare('5', '5.0', ascending: true), 0);
      });

      test('handles negative and decimal numbers', () {
        expect(defaultSortCompare('-3.5', '-1.2', ascending: true), lessThan(0));
      });
    });

    group('H:M:S duration comparison', () {
      test('ascending orders the shorter duration first', () {
        expect(defaultSortCompare('0:01:00', '0:02:00', ascending: true), lessThan(0));
      });

      test('descending orders the longer duration first', () {
        expect(defaultSortCompare('0:01:00', '0:02:00', ascending: false), greaterThan(0));
      });

      test('M:S (two-part) durations compare correctly', () {
        expect(defaultSortCompare('1:30', '2:00', ascending: true), lessThan(0));
      });

      test('equal durations compare as 0', () {
        expect(defaultSortCompare('1:02:03', '1:02:03', ascending: true), 0);
      });
    });

    group('DateTime comparison', () {
      test('ascending orders the earlier date first', () {
        expect(defaultSortCompare('2024-01-01', '2024-06-01', ascending: true), lessThan(0));
      });

      test('descending orders the later date first', () {
        expect(defaultSortCompare('2024-01-01', '2024-06-01', ascending: false), greaterThan(0));
      });

      test('full ISO-8601 timestamps compare correctly', () {
        expect(
          defaultSortCompare('2024-01-01T10:00:00Z', '2024-01-01T12:00:00Z', ascending: true),
          lessThan(0),
        );
      });
    });

    group('case-insensitive string fallthrough', () {
      test('ascending orders alphabetically first string first', () {
        expect(defaultSortCompare('apple', 'banana', ascending: true), lessThan(0));
      });

      test('descending reverses the order', () {
        expect(defaultSortCompare('apple', 'banana', ascending: false), greaterThan(0));
      });

      test('comparison is case-insensitive', () {
        expect(defaultSortCompare('Apple', 'apple', ascending: true), 0);
        expect(defaultSortCompare('APPLE', 'banana', ascending: true), lessThan(0));
      });

      test('falls through to string comparison when only one side parses as numeric', () {
        // '5' parses numerically but 'five' does not, so numA/numB disagree
        // and the comparator must not treat this pair as numeric.
        expect(defaultSortCompare('5', 'five', ascending: true), isNot(0));
        expect(defaultSortCompare('5', 'five', ascending: true), '5'.toLowerCase().compareTo('five'.toLowerCase()));
      });

      test('falls through to string comparison when only one side parses as a duration', () {
        expect(
          defaultSortCompare('1:30', 'not-a-duration', ascending: true),
          '1:30'.toLowerCase().compareTo('not-a-duration'.toLowerCase()),
        );
      });

      test('falls through to string comparison when only one side parses as a DateTime', () {
        expect(
          defaultSortCompare('2024-01-01', 'not-a-date', ascending: true),
          '2024-01-01'.toLowerCase().compareTo('not-a-date'.toLowerCase()),
        );
      });

      test('a lone numeric-looking token is not misread as a duration', () {
        // '42' has no colon, so `_tryParseDuration` must reject it and fall
        // through to the numeric comparator instead.
        expect(defaultSortCompare('42', '7', ascending: true), greaterThan(0));
      });

      test('empty strings compare as equal', () {
        expect(defaultSortCompare('', '', ascending: true), 0);
      });
    });
  });

  group('sortByKeys (isolate-callable index sort, invoked directly here)', () {
    test('sorts ascending by precomputed sortKeys, returning index order', () {
      final params = SortKeysParams(sortKeys: ['3', '1', '2'], ascending: true);

      expect(sortByKeys(params), [1, 2, 0]);
    });

    test('sorts descending by precomputed sortKeys, returning index order', () {
      final params = SortKeysParams(sortKeys: ['3', '1', '2'], ascending: false);

      expect(sortByKeys(params), [0, 2, 1]);
    });

    test('the returned index order reorders arbitrary (non-String) items correctly', () {
      final items = [
        {'id': 3},
        {'id': 1},
        {'id': 2},
      ];
      final params = SortKeysParams(sortKeys: ['3', '1', '2'], ascending: true);

      final order = sortByKeys(params);
      final sorted = [for (final index in order) items[index]];

      expect(sorted.map((item) => item['id']), [1, 2, 3]);
    });

    test('an empty sortKeys list sorts to an empty index list', () {
      final params = SortKeysParams(sortKeys: const [], ascending: true);

      expect(sortByKeys(params), isEmpty);
    });

    test('a single-key list returns the single index unchanged', () {
      final params = SortKeysParams(sortKeys: const ['42'], ascending: true);

      expect(sortByKeys(params), [0]);
    });
  });

  group('sortIndexesOffThread (the isolate path via compute)', () {
    test('produces the same ascending index order as the direct call', () async {
      final params = SortKeysParams(sortKeys: ['3', '1', '2'], ascending: true);

      final result = await sortIndexesOffThread(params);

      expect(result, [1, 2, 0]);
    });

    test('produces the same descending index order as the direct call', () async {
      final params = SortKeysParams(sortKeys: ['3', '1', '2'], ascending: false);

      final result = await sortIndexesOffThread(params);

      expect(result, [0, 2, 1]);
    });
  });

  group('sortTableItems (isolate-callable customSort path, invoked directly here)', () {
    test('honors customSort ascending', () {
      final params = SortParams<int>(
        items: [3, 1, 2],
        ascending: true,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      expect(sortTableItems(params), [1, 2, 3]);
    });

    test('customSort receives the ascending flag and can invert it', () {
      final params = SortParams<int>(
        items: [1, 2, 3],
        ascending: false,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      expect(sortTableItems(params), [3, 2, 1]);
    });

    test('an empty items list sorts to an empty list', () {
      final params = SortParams<int>(
        items: const [],
        ascending: true,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      expect(sortTableItems(params), isEmpty);
    });

    test('a single-item list is returned unchanged', () {
      final params = SortParams<int>(
        items: const [42],
        ascending: true,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      expect(sortTableItems(params), [42]);
    });

    test('does not mutate the original items list in place', () {
      final original = [3, 1, 2];
      final params = SortParams<int>(
        items: original,
        ascending: true,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      sortTableItems(params);

      expect(original, [3, 1, 2]);
    });
  });

  group('sortTableItemsOffThread (the isolate path via compute, customSort)', () {
    test('honors customSort across the isolate boundary', () async {
      final params = SortParams<int>(
        items: [3, 1, 2],
        ascending: true,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      final result = await sortTableItemsOffThread(params);

      expect(result, [1, 2, 3]);
    });

    test('customSort receives the ascending flag across the isolate boundary', () async {
      final params = SortParams<int>(
        items: [1, 2, 3],
        ascending: false,
        customSort: (a, b, ascending) => ascending ? a.compareTo(b) : b.compareTo(a),
      );

      final result = await sortTableItemsOffThread(params);

      expect(result, [3, 2, 1]);
    });
  });
}

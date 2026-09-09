import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/table/src/events.dart';

void main() {
  group('LayrzTableSortEvent', () {
    test('carries the given columnKey and ascending payload', () {
      const event = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: false);

      expect(event.columnKey, const ValueKey('col'));
      expect(event.ascending, isFalse);
    });

    test('a null columnKey represents a cleared sort', () {
      const event = LayrzTableSortEvent<int>(columnKey: null, ascending: true);

      expect(event.columnKey, isNull);
    });

    test('equal when columnKey and ascending match', () {
      const a = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: true);
      const b = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: true);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when ascending differs', () {
      const a = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: true);
      const b = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: false);

      expect(a == b, isFalse);
    });

    test('unequal when columnKey differs', () {
      const a = LayrzTableSortEvent<int>(columnKey: ValueKey('col-a'), ascending: true);
      const b = LayrzTableSortEvent<int>(columnKey: ValueKey('col-b'), ascending: true);

      expect(a == b, isFalse);
    });

    test('toString reports both fields', () {
      const event = LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: true);

      expect(event.toString(), contains('col'));
      expect(event.toString(), contains('true'));
    });
  });

  group('LayrzTableSearchEvent', () {
    test('carries the given searchText payload', () {
      const event = LayrzTableSearchEvent<int>(searchText: 'query');

      expect(event.searchText, 'query');
    });

    test('an empty searchText represents a cleared filter', () {
      const event = LayrzTableSearchEvent<int>(searchText: '');

      expect(event.searchText, isEmpty);
    });

    test('equal when searchText matches', () {
      const a = LayrzTableSearchEvent<int>(searchText: 'abc');
      const b = LayrzTableSearchEvent<int>(searchText: 'abc');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when searchText differs', () {
      const a = LayrzTableSearchEvent<int>(searchText: 'abc');
      const b = LayrzTableSearchEvent<int>(searchText: 'xyz');

      expect(a == b, isFalse);
    });

    test('toString reports the searchText', () {
      const event = LayrzTableSearchEvent<int>(searchText: 'abc');

      expect(event.toString(), contains('abc'));
    });
  });

  group('LayrzTableSelectionEvent', () {
    test('carries the given selection payload', () {
      const event = LayrzTableSelectionEvent<int>(selection: {1, 2, 3});

      expect(event.selection, {1, 2, 3});
    });

    test('an empty selection represents nothing selected', () {
      const event = LayrzTableSelectionEvent<int>(selection: {});

      expect(event.selection, isEmpty);
    });

    test('equal when selections contain the same elements regardless of construction order', () {
      const a = LayrzTableSelectionEvent<int>(selection: {1, 2, 3});
      const b = LayrzTableSelectionEvent<int>(selection: {3, 2, 1});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when selection sizes differ', () {
      const a = LayrzTableSelectionEvent<int>(selection: {1, 2});
      const b = LayrzTableSelectionEvent<int>(selection: {1, 2, 3});

      expect(a == b, isFalse);
    });

    test('unequal when selection contents differ at the same size', () {
      const a = LayrzTableSelectionEvent<int>(selection: {1, 2});
      const b = LayrzTableSelectionEvent<int>(selection: {1, 3});

      expect(a == b, isFalse);
    });

    test('toString reports the selection', () {
      const event = LayrzTableSelectionEvent<int>(selection: {1});

      expect(event.toString(), contains('1'));
    });
  });

  group('LayrzTableColumnsEvent', () {
    test('carries the given columnOrder and hiddenColumns payload', () {
      final event = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b'), ValueKey('c')],
        hiddenColumns: {ValueKey('b')},
      );

      expect(event.columnOrder, [const ValueKey('a'), const ValueKey('b'), const ValueKey('c')]);
      expect(event.hiddenColumns, {const ValueKey('b')});
    });

    test('a key present in hiddenColumns and columnOrder is hidden; one absent from hiddenColumns is visible', () {
      final event = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('b')},
      );

      expect(event.columnOrder.contains(const ValueKey('a')), isTrue);
      expect(event.hiddenColumns.contains(const ValueKey('a')), isFalse);
      expect(event.hiddenColumns.contains(const ValueKey('b')), isTrue);
    });

    test('equal when columnOrder (in order) and hiddenColumns (as a set) match', () {
      final a = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('a'), ValueKey('b')},
      );
      final b = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('b'), ValueKey('a')},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when columnOrder differs in sequence, even with the same keys', () {
      final a = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('a'), ValueKey('b')},
      );
      final b = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('b'), ValueKey('a')],
        hiddenColumns: {ValueKey('a'), ValueKey('b')},
      );

      expect(a == b, isFalse);
    });

    test('unequal when columnOrder lengths differ', () {
      final a = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a')],
        hiddenColumns: {ValueKey('a')},
      );
      final b = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('a')},
      );

      expect(a == b, isFalse);
    });

    test('unequal when hiddenColumns differ', () {
      final a = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('a')},
      );
      final b = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a'), ValueKey('b')],
        hiddenColumns: {ValueKey('b')},
      );

      expect(a == b, isFalse);
    });

    test('toString reports both columnOrder and hiddenColumns', () {
      final event = LayrzTableColumnsEvent<int>(
        columnOrder: const [ValueKey('a')],
        hiddenColumns: {ValueKey('a')},
      );

      expect(event.toString(), contains('a'));
    });
  });

  group('LayrzTableRefreshEvent', () {
    test('carries no payload', () {
      const event = LayrzTableRefreshEvent<int>();

      expect(event, isA<LayrzTableRefreshEvent<int>>());
    });

    test('two refresh events are always equal', () {
      const a = LayrzTableRefreshEvent<int>();
      const b = LayrzTableRefreshEvent<int>();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a refresh event is not equal to an unrelated event subtype', () {
      const refresh = LayrzTableRefreshEvent<int>();
      const search = LayrzTableSearchEvent<int>(searchText: '');

      // ignore: unrelated_type_equality_checks
      expect(refresh == search, isFalse);
    });

    test('toString identifies the event', () {
      const event = LayrzTableRefreshEvent<int>();

      expect(event.toString(), 'LayrzTableRefreshEvent()');
    });
  });

  group('LayrzTableEvent sealed hierarchy', () {
    test('every concrete subclass is a LayrzTableEvent<T>', () {
      const events = <LayrzTableEvent<int>>[
        LayrzTableSortEvent<int>(columnKey: ValueKey('a'), ascending: true),
        LayrzTableSearchEvent<int>(searchText: ''),
        LayrzTableSelectionEvent<int>(selection: {}),
        LayrzTableColumnsEvent<int>(columnOrder: [], hiddenColumns: {}),
        LayrzTableRefreshEvent<int>(),
      ];

      for (final event in events) {
        expect(event, isA<LayrzTableEvent<int>>());
      }
    });

    test('a switch over the sealed type is exhaustive without a default case', () {
      String describe(LayrzTableEvent<int> event) => switch (event) {
        LayrzTableSortEvent<int>() => 'sort',
        LayrzTableSearchEvent<int>() => 'search',
        LayrzTableSelectionEvent<int>() => 'selection',
        LayrzTableColumnsEvent<int>() => 'columns',
        LayrzTableRefreshEvent<int>() => 'refresh',
      };

      expect(describe(const LayrzTableSortEvent<int>(columnKey: ValueKey('a'), ascending: true)), 'sort');
      expect(describe(const LayrzTableSearchEvent<int>(searchText: '')), 'search');
      expect(describe(const LayrzTableSelectionEvent<int>(selection: {})), 'selection');
      expect(describe(const LayrzTableColumnsEvent<int>(columnOrder: [], hiddenColumns: {})), 'columns');
      expect(describe(const LayrzTableRefreshEvent<int>()), 'refresh');
    });
  });
}

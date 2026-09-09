import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/controller.dart';
import 'package:layrz_ui/src/table/src/events.dart';

void main() {
  group('LayrzTableController construction', () {
    test('defaults to an empty columnOrder, no hidden columns, and minVisibleColumns 1', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);

      expect(controller.columnOrder, isEmpty);
      expect(controller.hiddenColumns, isEmpty);
      expect(controller.minVisibleColumns, 1);
      expect(controller.searchText, isEmpty);
      expect(controller.sortColumnKey, isNull);
      expect(controller.sortAscending, isTrue);
      expect(controller.selection, isEmpty);
    });

    test('seeds columnOrder and hiddenColumns from constructor arguments', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b], hiddenColumns: {b});
      addTearDown(controller.dispose);

      expect(controller.columnOrder, [a, b]);
      expect(controller.hiddenColumns, {b});
      expect(controller.visibleColumnKeys, {a});
    });

    test('honors a custom minVisibleColumns', () {
      final controller = LayrzTableController<int>(minVisibleColumns: 2);
      addTearDown(controller.dispose);

      expect(controller.minVisibleColumns, 2);
    });

    test('asserts minVisibleColumns is at least 1', () {
      expect(() => LayrzTableController<int>(minVisibleColumns: 0), throwsA(isA<AssertionError>()));
    });

    test('columnOrder and hiddenColumns getters are unmodifiable', () {
      final controller = LayrzTableController<int>(columnOrder: [const ValueKey('a')]);
      addTearDown(controller.dispose);

      expect(() => controller.columnOrder.add(const ValueKey('b')), throwsUnsupportedError);
      expect(() => controller.hiddenColumns.add(const ValueKey('b')), throwsUnsupportedError);
      expect(() => controller.selection.add(1), throwsUnsupportedError);
    });
  });

  group('sort', () {
    test('sets sortColumnKey and sortAscending and calls notifyListeners', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.sort(const ValueKey('col'), false);

      expect(controller.sortColumnKey, const ValueKey('col'));
      expect(controller.sortAscending, isFalse);
      expect(notified, 1);
    });

    test('emits a LayrzTableSortEvent with the correct payload', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.sort(const ValueKey('col'), true);
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [const LayrzTableSortEvent<int>(columnKey: ValueKey('col'), ascending: true)]);
    });
  });

  group('clearSort', () {
    test('resets sortColumnKey to null and sortAscending to true', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.sort(const ValueKey('col'), false);

      controller.clearSort();

      expect(controller.sortColumnKey, isNull);
      expect(controller.sortAscending, isTrue);
    });

    test('emits a LayrzTableSortEvent with a null columnKey', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.sort(const ValueKey('col'), false);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.clearSort();
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [const LayrzTableSortEvent<int>(columnKey: null, ascending: true)]);
    });
  });

  group('search', () {
    test('replaces searchText verbatim and calls notifyListeners', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.search('hello');

      expect(controller.searchText, 'hello');
      expect(notified, 1);
    });

    test('emits a LayrzTableSearchEvent with the new text', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.search('query');
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [const LayrzTableSearchEvent<int>(searchText: 'query')]);
    });

    test('an empty string clears the filter', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.search('query');

      controller.search('');

      expect(controller.searchText, isEmpty);
    });
  });

  group('setColumnVisible / toggleColumn', () {
    test('appends an unknown column to columnOrder when shown', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);

      controller.setColumnVisible(const ValueKey('new'), true);

      expect(controller.columnOrder, [const ValueKey('new')]);
      expect(controller.visibleColumnKeys, {const ValueKey('new')});
    });

    test('hiding a known visible column moves it into hiddenColumns without removing its order slot', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b]);
      addTearDown(controller.dispose);

      controller.setColumnVisible(a, false);

      expect(controller.columnOrder, [a, b]);
      expect(controller.hiddenColumns, {a});
      expect(controller.visibleColumnKeys, {b});
    });

    test('hiding an already-hidden column is a no-op: no notify, no event', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b], hiddenColumns: {a});
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setColumnVisible(a, false);

      expect(notified, 0);
      expect(controller.hiddenColumns, {a});
    });

    test('showing an already-visible column is a no-op: no notify, no event', () {
      const a = ValueKey('a');
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setColumnVisible(a, true);

      expect(notified, 0);
    });

    test('hiding an unknown column is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setColumnVisible(const ValueKey('ghost'), false);

      expect(notified, 0);
      expect(controller.hiddenColumns, isEmpty);
    });

    test('toggleColumn on an unknown column is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.toggleColumn(const ValueKey('ghost'));

      expect(notified, 0);
    });

    test('toggleColumn flips visibility of a known column', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b]);
      addTearDown(controller.dispose);

      controller.toggleColumn(a);
      expect(controller.hiddenColumns, {a});

      controller.toggleColumn(a);
      expect(controller.hiddenColumns, isEmpty);
    });

    test('emits a LayrzTableColumnsEvent on a successful visibility change', () async {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b]);
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.setColumnVisible(a, false);
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [
        LayrzTableColumnsEvent<int>(columnOrder: const [a, b], visibleColumnKeys: {b}),
      ]);
    });

    group('minVisibleColumns boundary', () {
      test('hiding the last visible column when minVisibleColumns is 1 is refused: no state change', () {
        const a = ValueKey('a');
        final controller = LayrzTableController<int>(columnOrder: [a]);
        addTearDown(controller.dispose);
        var notified = 0;
        controller.addListener(() => notified++);

        controller.setColumnVisible(a, false);

        expect(controller.hiddenColumns, isEmpty);
        expect(controller.visibleColumnKeys, {a});
        expect(notified, 0);
      });

      test('hiding the last visible column emits no event', () async {
        const a = ValueKey('a');
        final controller = LayrzTableController<int>(columnOrder: [a]);
        final events = <LayrzTableEvent<int>>[];
        final sub = controller.events.listen(events.add);

        controller.setColumnVisible(a, false);
        controller.dispose();
        await sub.cancel();

        expect(events, isEmpty);
      });

      test('with minVisibleColumns 2, hiding down to 1 visible column is refused', () {
        const a = ValueKey('a');
        const b = ValueKey('b');
        const c = ValueKey('c');
        final controller = LayrzTableController<int>(columnOrder: [a, b, c], hiddenColumns: {c}, minVisibleColumns: 2);
        addTearDown(controller.dispose);

        // Currently 2 visible (a, b). Hiding a would drop to 1 — refused.
        controller.setColumnVisible(a, false);

        expect(controller.hiddenColumns, {c});
        expect(controller.visibleColumnKeys, {a, b});
      });

      test('with minVisibleColumns 2, hiding down to exactly 2 is allowed', () {
        const a = ValueKey('a');
        const b = ValueKey('b');
        const c = ValueKey('c');
        final controller = LayrzTableController<int>(columnOrder: [a, b, c], minVisibleColumns: 2);
        addTearDown(controller.dispose);

        controller.setColumnVisible(c, false);

        expect(controller.hiddenColumns, {c});
        expect(controller.visibleColumnKeys, {a, b});
      });

      test('toggleColumn also respects the minVisibleColumns floor', () {
        const a = ValueKey('a');
        final controller = LayrzTableController<int>(columnOrder: [a]);
        addTearDown(controller.dispose);

        controller.toggleColumn(a);

        expect(controller.hiddenColumns, isEmpty);
      });
    });

    group('re-show restores last position', () {
      test('hiding a middle column then re-showing it returns it to its original slot', () {
        const a = ValueKey('a');
        const b = ValueKey('b');
        const c = ValueKey('c');
        final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
        addTearDown(controller.dispose);

        controller.setColumnVisible(b, false);
        expect(controller.columnOrder, [a, b, c]);

        controller.setColumnVisible(b, true);

        expect(controller.columnOrder, [a, b, c]);
        expect(controller.visibleColumnKeys, {a, b, c});
      });

      test('re-showing does not append the column to the end', () {
        const a = ValueKey('a');
        const b = ValueKey('b');
        const c = ValueKey('c');
        final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
        addTearDown(controller.dispose);

        controller.toggleColumn(a);
        controller.toggleColumn(a);

        expect(controller.columnOrder.first, a);
        expect(controller.columnOrder, [a, b, c]);
      });
    });
  });

  group('reorderColumn', () {
    test('moves a visible column to the target visible index', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
      addTearDown(controller.dispose);

      controller.reorderColumn(a, 2);

      expect(controller.columnOrder, [b, c, a]);
    });

    test('moving a column to its current index is a no-op', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b]);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.reorderColumn(a, 0);

      expect(notified, 0);
      expect(controller.columnOrder, [a, b]);
    });

    test('reordering a hidden column is a no-op', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b], hiddenColumns: {a});
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.reorderColumn(a, 1);

      expect(notified, 0);
      expect(controller.columnOrder, [a, b]);
    });

    test('reordering an unknown column is a no-op', () {
      const a = ValueKey('a');
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.reorderColumn(const ValueKey('ghost'), 0);

      expect(notified, 0);
    });

    test('clamps an out-of-range targetVisibleIndex to the last visible slot', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
      addTearDown(controller.dispose);

      controller.reorderColumn(a, 999);

      expect(controller.columnOrder, [b, c, a]);
    });

    test('clamps a negative targetVisibleIndex to the first visible slot', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
      addTearDown(controller.dispose);

      controller.reorderColumn(c, -5);

      expect(controller.columnOrder, [c, a, b]);
    });

    test('emits a LayrzTableColumnsEvent carrying the rebuilt order', () async {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b, c]);
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.reorderColumn(a, 1);
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [
        LayrzTableColumnsEvent<int>(columnOrder: const [b, a, c], visibleColumnKeys: {a, b, c}),
      ]);
    });

    test('a move across a hidden column preserves the hidden column anchor to its preceding visible neighbor', () {
      // Order: a, [hidden] h, b, c. h is anchored to a (the nearest
      // preceding visible key). Moving c to the front must carry h along
      // right after a, not strand it at its old numeric position.
      const a = ValueKey('a');
      const h = ValueKey('h');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, h, b, c], hiddenColumns: {h});
      addTearDown(controller.dispose);

      controller.reorderColumn(c, 0);

      expect(controller.columnOrder, [c, a, h, b]);
      expect(controller.visibleColumnKeys, {a, b, c});
      expect(controller.hiddenColumns, {h});
    });

    test('a hidden column anchored before every visible column ("start") stays first after reordering', () {
      const h = ValueKey('h');
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [h, a, b], hiddenColumns: {h});
      addTearDown(controller.dispose);

      controller.reorderColumn(b, 0);

      expect(controller.columnOrder, [h, b, a]);
    });

    test('multiple hidden columns anchored to the same visible key keep their relative order', () {
      const a = ValueKey('a');
      const h1 = ValueKey('h1');
      const h2 = ValueKey('h2');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, h1, h2, b], hiddenColumns: {h1, h2});
      addTearDown(controller.dispose);

      controller.reorderColumn(b, 0);

      expect(controller.columnOrder, [b, a, h1, h2]);
    });

    test('single visible column: any target index is a no-op (already at 0)', () {
      const a = ValueKey('a');
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.reorderColumn(a, 5);

      expect(notified, 0);
      expect(controller.columnOrder, [a]);
    });
  });

  group('syncColumns (membership sync)', () {
    LayrzColumn<int> column(Key key) => LayrzColumn<int>(key: key, headerText: '$key', valueBuilder: (i) => '$i');

    test('appends newly-seen keys in declaration order, starting visible', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      const a = ValueKey('a');
      const b = ValueKey('b');

      controller.syncColumns([column(a), column(b)]);

      expect(controller.columnOrder, [a, b]);
      expect(controller.visibleColumnKeys, {a, b});
    });

    test('drops stored order/visibility entries whose key is no longer present', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b], hiddenColumns: {b});
      addTearDown(controller.dispose);

      controller.syncColumns([column(a)]);

      expect(controller.columnOrder, [a]);
      expect(controller.hiddenColumns, isEmpty);
    });

    test('adds new columns and removes stale ones in the same call without misattribution', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b], hiddenColumns: {b});
      addTearDown(controller.dispose);

      // b removed, c added. a's state (visible) must be untouched, and the
      // hidden state that belonged to b must not leak onto c.
      controller.syncColumns([column(a), column(c)]);

      expect(controller.columnOrder, [a, c]);
      expect(controller.hiddenColumns, isEmpty);
      expect(controller.visibleColumnKeys, {a, c});
    });

    test('preserves existing order and hidden state for keys that remain', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      const c = ValueKey('c');
      final controller = LayrzTableController<int>(columnOrder: [a, b, c], hiddenColumns: {b});
      addTearDown(controller.dispose);

      controller.syncColumns([column(a), column(b), column(c)]);

      expect(controller.columnOrder, [a, b, c]);
      expect(controller.hiddenColumns, {b});
    });

    test('is a no-op (no notify, no event) when membership is already in sync', () {
      const a = ValueKey('a');
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.syncColumns([column(a)]);

      expect(notified, 0);
    });

    test('backfills visibility from newly-added keys when dropping stale keys breaches the floor', () {
      const a = ValueKey('a');
      const newCol = ValueKey('new');
      // Only 'a' remains and it is about to be dropped; minVisibleColumns 1
      // requires at least one visible column after the sync, so the newly
      // appended key must be used to backfill.
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);

      controller.syncColumns([column(newCol)]);

      expect(controller.columnOrder, [newCol]);
      expect(controller.visibleColumnKeys, {newCol});
    });

    test('emits a LayrzTableColumnsEvent when membership actually changes', () async {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a]);
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.syncColumns([column(a), column(b)]);
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [
        LayrzTableColumnsEvent<int>(columnOrder: const [a, b], visibleColumnKeys: {a, b}),
      ]);
    });

    test('an empty incoming column list drops every stored key', () {
      const a = ValueKey('a');
      const b = ValueKey('b');
      final controller = LayrzTableController<int>(columnOrder: [a, b]);
      addTearDown(controller.dispose);

      controller.syncColumns(<LayrzColumn<int>>[]);

      expect(controller.columnOrder, isEmpty);
      expect(controller.hiddenColumns, isEmpty);
    });
  });

  group('selection', () {
    test('selectItem adds an item and emits a LayrzTableSelectionEvent', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.selectItem(1);
      await pumpEventQueue();
      await sub.cancel();

      expect(controller.selection, {1});
      expect(events, [
        const LayrzTableSelectionEvent<int>(selection: {1}),
      ]);
    });

    test('selectItem on an already-selected item is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.selectItem(1);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectItem(1);

      expect(notified, 0);
    });

    test('deselectItem removes an item and emits a LayrzTableSelectionEvent', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.selectItem(1);
      controller.selectItem(2);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.deselectItem(1);
      await pumpEventQueue();
      await sub.cancel();

      expect(controller.selection, {2});
      expect(events, [
        const LayrzTableSelectionEvent<int>(selection: {2}),
      ]);
    });

    test('deselectItem on a non-selected item is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.deselectItem(1);

      expect(notified, 0);
    });

    test('toggleSelection selects when unselected and deselects when selected', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);

      controller.toggleSelection(1);
      expect(controller.selection, {1});

      controller.toggleSelection(1);
      expect(controller.selection, isEmpty);
    });

    test('selectAll replaces the selection with exactly the given items', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.selectItem(99);

      controller.selectAll([1, 2, 3]);

      expect(controller.selection, {1, 2, 3});
    });

    test('selectAll with the same set (any order) is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.selectAll([1, 2, 3]);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectAll([3, 2, 1]);

      expect(notified, 0);
    });

    test('clearSelection empties the selection and emits an empty-set event', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      controller.selectAll([1, 2]);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.clearSelection();
      await pumpEventQueue();
      await sub.cancel();

      expect(controller.selection, isEmpty);
      expect(events, [
        const LayrzTableSelectionEvent<int>(selection: {}),
      ]);
    });

    test('clearSelection on an already-empty selection is a no-op', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.clearSelection();

      expect(notified, 0);
    });
  });

  group('refresh', () {
    test('always calls notifyListeners', () {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.refresh();

      expect(notified, 1);
    });

    test('emits a LayrzTableRefreshEvent', () async {
      final controller = LayrzTableController<int>();
      addTearDown(controller.dispose);
      final events = <LayrzTableEvent<int>>[];
      final sub = controller.events.listen(events.add);

      controller.refresh();
      await pumpEventQueue();
      await sub.cancel();

      expect(events, [const LayrzTableRefreshEvent<int>()]);
    });
  });

  group('dispose', () {
    test('closes the events stream so it emits a done event and no further data', () async {
      final controller = LayrzTableController<int>();
      var isDone = false;

      final sub = controller.events.listen((_) {}, onDone: () => isDone = true);

      controller.dispose();
      await pumpEventQueue();
      await sub.cancel();

      expect(isDone, isTrue);
    });
  });
}

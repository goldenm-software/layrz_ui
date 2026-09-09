import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/table/src/table_header.dart';

import 'helpers/pump_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<LayrzColumn<TableTestRow>> threeColumns() => [
    LayrzColumn<TableTestRow>(key: const ValueKey('c1'), headerText: 'Col 1', valueBuilder: (r) => r.name),
    LayrzColumn<TableTestRow>(key: const ValueKey('c2'), headerText: 'Col 2', valueBuilder: (r) => '${r.amount}'),
    LayrzColumn<TableTestRow>(key: const ValueKey('c3'), headerText: 'Col 3', valueBuilder: (r) => r.name),
  ];

  Widget buildHeader({
    required List<LayrzColumn<TableTestRow>> columns,
    required LayrzTableController<TableTestRow> controller,
    LayrzTableRowScrollSync? scrollSync,
  }) {
    // LayrzTableHeader itself never listens to `controller` — inside the
    // real LayrzTable, the enclosing LayrzTableState does that and calls
    // setState on every controller change, which is what rebuilds the
    // header (and its per-column LayrzContextMenu.entries, whose `enabled`
    // flags read live controller state) on every mutation. Standing the
    // header up on its own without reproducing that wiring leaves it
    // showing the sort-menu entries computed at the very first build
    // forever; a ListenableBuilder here is what makes this fixture behave
    // like the real parent.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => LayrzTableHeader<TableTestRow>(
        columns: columns,
        controller: controller,
        columnWidths: {for (final c in columns) c.key: 150.0},
        scrollSync: scrollSync ?? LayrzTableRowScrollSync(),
      ),
    );
  }

  /// Finds the tap-to-sort [LayrzTappable] for the header cell labelled
  /// [headerText].
  ///
  /// Narrower than `find.text(headerText)`: the header cell's label sits
  /// inside a [LayrzTooltip], which mounts its own title/content [Text]
  /// copies of [headerText] into the overlay once shown (e.g. by a prior
  /// right-click's synthetic mouse-hover), making a bare `find.text` finder
  /// ambiguous. Anchoring on the ancestor [LayrzTappable] instead always
  /// resolves to exactly the one header cell that carries the tap-to-sort
  /// gesture, regardless of whether a tooltip is currently mounted.
  Finder headerCellFor(String headerText) =>
      find.ancestor(of: find.text(headerText), matching: find.byType(LayrzTappable)).first;

  group('LayrzTableHeader tap-to-sort', () {
    testWidgets('tapping a sortable header cycles ascending -> descending -> cleared', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      expect(controller.sortColumnKey, isNull);

      await tester.tap(headerCellFor('Col 1'));
      await tester.pumpAndSettle();
      expect(controller.sortColumnKey, const ValueKey('c1'));
      expect(controller.sortAscending, isTrue);

      // LayrzTappable collapses any second tap landing within
      // kDoubleTapTimeout of the first into a no-op double-tap; wait it out
      // so this reads as an independent tap rather than being swallowed.
      await tester.pump(kDoubleTapTimeout);
      await tester.tap(headerCellFor('Col 1'));
      await tester.pumpAndSettle();
      expect(controller.sortColumnKey, const ValueKey('c1'));
      expect(controller.sortAscending, isFalse);

      await tester.pump(kDoubleTapTimeout);
      await tester.tap(headerCellFor('Col 1'));
      await tester.pumpAndSettle();
      expect(controller.sortColumnKey, isNull);
    });

    testWidgets('tapping a non-sortable header does nothing', (tester) async {
      useWideViewport(tester);
      final columns = [
        LayrzColumn<TableTestRow>(
          key: const ValueKey('c1'),
          headerText: 'Col 1',
          valueBuilder: (r) => r.name,
          isSortable: false,
        ),
      ];
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.tap(find.text('Col 1'));
      await tester.pumpAndSettle();

      expect(controller.sortColumnKey, isNull);
    });
  });

  group('LayrzTableHeader drag handle viewport gating', () {
    testWidgets('drag handle is PRESENT on a wide viewport', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      expect(find.byType(Draggable<Key>), findsNWidgets(columns.length));
    });

    testWidgets('drag handle is ABSENT on a compact viewport', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      expect(find.byType(Draggable<Key>), findsNothing);
    });
  });

  group('LayrzTableHeader drag-to-reorder (wide only)', () {
    testWidgets('a completed drag updates both rendered order and controller order together', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      expect(controller.columnOrder, [const ValueKey('c1'), const ValueKey('c2'), const ValueKey('c3')]);

      final handleFinder = find.byType(Draggable<Key>).first;
      final targetCenter = tester.getCenter(find.text('Col 3'));

      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.columnOrder.first, isNot(const ValueKey('c1')));
      expect(controller.visibleColumnKeys.contains(const ValueKey('c1')), isTrue);
    });

    testWidgets('reorder operates on the visible column set; a hidden column stays anchored', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);
      controller.setColumnVisible(const ValueKey('c2'), false);

      // Header renders only the visible columns (c1, c3).
      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      final handleFinder = find.byType(Draggable<Key>).first;
      final targetCenter = tester.getCenter(find.text('Col 3'));

      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      // c2 stays hidden and its stored anchor relationship is preserved by
      // the controller (tested directly in U10); here we assert the header
      // never rendered it and visibility is untouched by the drag.
      expect(controller.hiddenColumns, contains(const ValueKey('c2')));
      expect(find.text('Col 2'), findsNothing);
    });

    testWidgets('a cancelled drag (released off any header cell) leaves order unchanged', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      final originalOrder = List.of(controller.columnOrder);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      final handleFinder = find.byType(Draggable<Key>).first;

      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));
      // Drop far outside any header cell / DragTarget.
      await gesture.moveTo(const Offset(10, 900));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.columnOrder, originalOrder);
    });

    testWidgets('dragging the active sort column moves it without changing sort state', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);
      controller.sort(const ValueKey('c1'), true);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      final handleFinder = find.byType(Draggable<Key>).first; // c1's handle
      final targetCenter = tester.getCenter(find.text('Col 3'));

      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.sortColumnKey, const ValueKey('c1'));
      expect(controller.sortAscending, isTrue);
      expect(controller.columnOrder.first, isNot(const ValueKey('c1')));
    });
  });

  group('LayrzTableHeader context menu (wide/desktop only)', () {
    testWidgets('right-click on wide opens Sort ascending/descending/Clear sort + Hide column', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.tap(headerCellFor('Col 1'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(find.text('Sort ascending'), findsOneWidget);
      expect(find.text('Sort descending'), findsOneWidget);
      expect(find.text('Clear sort'), findsOneWidget);
      expect(find.text('Hide column'), findsOneWidget);
    });

    testWidgets('Sort ascending / Sort descending / Clear sort each drive the controller', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.tap(headerCellFor('Col 1'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort ascending'));
      await tester.pumpAndSettle();

      expect(controller.sortColumnKey, const ValueKey('c1'));
      expect(controller.sortAscending, isTrue);

      await tester.tap(headerCellFor('Col 1'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort descending'));
      await tester.pumpAndSettle();

      expect(controller.sortColumnKey, const ValueKey('c1'));
      expect(controller.sortAscending, isFalse);

      await tester.tap(headerCellFor('Col 1'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear sort'));
      await tester.pumpAndSettle();

      expect(controller.sortColumnKey, isNull);
    });

    testWidgets('Hide column is disabled at the minVisibleColumns boundary', (tester) async {
      useWideViewport(tester);
      final columns = [
        LayrzColumn<TableTestRow>(key: const ValueKey('only'), headerText: 'Only', valueBuilder: (r) => r.name),
      ];
      final controller = LayrzTableController<TableTestRow>(
        columnOrder: columns.map((c) => c.key).toList(),
        minVisibleColumns: 1,
      );
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.tap(find.text('Only'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hide column'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Disabled entry must not have actually hidden the sole column.
      expect(controller.hiddenColumns, isEmpty);
    });

    testWidgets('Hide column works when above the minVisibleColumns floor', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(
        columnOrder: columns.map((c) => c.key).toList(),
        minVisibleColumns: 1,
      );
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.tap(find.text('Col 1'), buttons: kSecondaryMouseButton, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide column'));
      await tester.pumpAndSettle();

      expect(controller.hiddenColumns, contains(const ValueKey('c1')));
    });

    testWidgets('the context menu does NOT open on compact', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, buildHeader(columns: columns, controller: controller));

      await tester.longPress(find.text('Col 1'));
      await tester.pumpAndSettle();

      expect(find.text('Sort ascending'), findsNothing);
      expect(find.text('Hide column'), findsNothing);
    });
  });

  group('LayrzTableHeader semantics', () {
    testWidgets('drag-handle semantics are distinct from the header cell tap-to-sort semantics', (tester) async {
      useWideViewport(tester);
      final handle = tester.ensureSemantics();
      try {
        final columns = threeColumns();
        final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
        addTearDown(controller.dispose);

        await pumpTable(tester, buildHeader(columns: columns, controller: controller));

        // Matched by the Semantics widget's own declared `label`, not the
        // merged runtime SemanticsNode: the header cell's Semantics sits
        // above the LayrzTooltip's own Semantics (and, on wide, the drag
        // handle's), so the merged node's label is the concatenation of all
        // three. Anchoring on the widget-level predicate isolates the header
        // cell's own declaration, which is what "distinct from" asserts here.
        final headerCellSemantics = tester.getSemantics(
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Sort by Col 1'),
        );
        expect(
          headerCellSemantics,
          matchesSemantics(isButton: true, label: 'Sort by Col 1', hasTapAction: true),
        );

        final dragHandleSemantics = tester.getSemantics(
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Reorder Col 1 column'),
        );
        expect(
          dragHandleSemantics,
          matchesSemantics(
            label: 'Reorder Col 1 column',
            customActions: [
              CustomSemanticsAction(label: 'Move Col 1 left'),
              CustomSemanticsAction(label: 'Move Col 1 right'),
            ],
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('compact header cell exposes sort semantics with no drag-handle semantics present', (tester) async {
      useCompactViewport(tester);
      final handle = tester.ensureSemantics();
      try {
        final columns = threeColumns();
        final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
        addTearDown(controller.dispose);

        await pumpTable(tester, buildHeader(columns: columns, controller: controller));

        final headerCellSemantics = tester.getSemantics(
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Sort by Col 1'),
        );
        expect(
          headerCellSemantics,
          matchesSemantics(isButton: true, label: 'Sort by Col 1', hasTapAction: true),
        );
        expect(find.byType(Draggable<Key>), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });
}

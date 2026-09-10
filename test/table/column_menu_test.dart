import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/table/src/column_menu.dart';

import 'helpers/pump_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<LayrzColumn<TableTestRow>> threeColumns() => [
    LayrzColumn<TableTestRow>(key: const ValueKey('c1'), headerText: 'Col 1', valueBuilder: (r) => r.name),
    LayrzColumn<TableTestRow>(key: const ValueKey('c2'), headerText: 'Col 2', valueBuilder: (r) => '${r.amount}'),
    LayrzColumn<TableTestRow>(key: const ValueKey('c3'), headerText: 'Col 3', valueBuilder: (r) => r.name),
  ];

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('layrz-column-menu-trigger')));
    await tester.pumpAndSettle();
  }

  group('LayrzColumnMenu reflects controller state', () {
    testWidgets('checkboxMarked icon for visible columns, checkboxBlankOutline for hidden', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);
      controller.setColumnVisible(const ValueKey('c2'), false);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      final visibleEntry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Col 1'));
      final hiddenEntry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Col 2'));

      expect(visibleEntry.icon, MdiIcons.checkboxMarked);
      expect(hiddenEntry.icon, MdiIcons.checkboxBlankOutline);
    });

    testWidgets('reopening the menu shows the true current controller state, not a stale copy', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      var entry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Col 2'));
      expect(entry.icon, MdiIcons.checkboxMarked);

      // Close, mutate externally, then reopen.
      controller.setColumnVisible(const ValueKey('c2'), false);
      await tester.pumpAndSettle();

      // Menu is still open (state-driven, no shadow copy) and already reflects it.
      entry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Col 2'));
      expect(entry.icon, MdiIcons.checkboxBlankOutline);
    });

    testWidgets('toggling a visibility entry hides/shows the column via the controller', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      expect(controller.hiddenColumns, isEmpty);

      await tester.tap(find.widgetWithText(LayrzDropdownEntry, 'Col 2'));
      await tester.pumpAndSettle();

      expect(controller.hiddenColumns, contains(const ValueKey('c2')));

      await openMenu(tester);
      await tester.tap(find.widgetWithText(LayrzDropdownEntry, 'Col 2'));
      await tester.pumpAndSettle();

      expect(controller.hiddenColumns, isEmpty);
    });

    testWidgets('re-showing a column restores its last position, not appended to the end', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      controller.setColumnVisible(const ValueKey('c1'), false);
      expect(controller.columnOrder, [const ValueKey('c1'), const ValueKey('c2'), const ValueKey('c3')]);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);
      await tester.tap(find.widgetWithText(LayrzDropdownEntry, 'Col 1'));
      await tester.pumpAndSettle();

      expect(controller.columnOrder, [const ValueKey('c1'), const ValueKey('c2'), const ValueKey('c3')]);
      expect(controller.hiddenColumns, isEmpty);
    });
  });

  group('LayrzColumnMenu minVisibleColumns boundary', () {
    testWidgets('the toggle for the last visible column is disabled at the floor', (tester) async {
      useWideViewport(tester);
      final columns = [
        LayrzColumn<TableTestRow>(key: const ValueKey('only'), headerText: 'Only', valueBuilder: (r) => r.name),
      ];
      final controller = LayrzTableController<TableTestRow>(
        columnOrder: columns.map((c) => c.key).toList(),
        minVisibleColumns: 1,
      );
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      final entry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Only'));
      expect(entry.enabled, isFalse);

      await tester.tap(find.widgetWithText(LayrzDropdownEntry, 'Only'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.hiddenColumns, isEmpty);
    });

    testWidgets('a toggle above the floor stays enabled', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(
        columnOrder: columns.map((c) => c.key).toList(),
        minVisibleColumns: 1,
      );
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      final entry = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Col 1'));
      expect(entry.enabled, isTrue);
    });
  });

  group('LayrzColumnMenu compact reorder controls', () {
    testWidgets('on compact, Move up/Move down entries appear for visible columns', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      expect(find.text('Move Col 1 up'), findsOneWidget);
      expect(find.text('Move Col 1 down'), findsOneWidget);
      expect(find.text('Move Col 2 up'), findsOneWidget);
      expect(find.text('Move Col 2 down'), findsOneWidget);
    });

    testWidgets('Move down drives reorderColumn on compact', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      await tester.tap(find.text('Move Col 1 down'));
      await tester.pumpAndSettle();

      expect(controller.columnOrder.first, const ValueKey('c2'));
      expect(controller.columnOrder[1], const ValueKey('c1'));
    });

    testWidgets('the first visible column has Move up disabled; the last has Move down disabled', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      final firstUp = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Move Col 1 up'));
      final lastDown = tester.widget<LayrzDropdownEntry>(find.widgetWithText(LayrzDropdownEntry, 'Move Col 3 down'));

      expect(firstUp.enabled, isFalse);
      expect(lastDown.enabled, isFalse);
    });

    testWidgets('on wide, Move up/Move down entries do NOT appear', (tester) async {
      useWideViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      expect(find.text('Move Col 1 up'), findsNothing);
      expect(find.text('Move Col 1 down'), findsNothing);
      expect(find.textContaining('Reorder columns'), findsNothing);
    });

    testWidgets('a hidden column gets no reorder entries on compact', (tester) async {
      useCompactViewport(tester);
      final columns = threeColumns();
      final controller = LayrzTableController<TableTestRow>(columnOrder: columns.map((c) => c.key).toList());
      addTearDown(controller.dispose);
      controller.setColumnVisible(const ValueKey('c2'), false);

      await pumpTable(tester, LayrzColumnMenu<TableTestRow>(columns: columns, controller: controller));
      await openMenu(tester);

      expect(find.text('Move Col 2 up'), findsNothing);
      expect(find.text('Move Col 2 down'), findsNothing);
    });
  });
}

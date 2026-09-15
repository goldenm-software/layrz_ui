import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// Builds [names] into scaffold items, each searchable by its own name.
List<LayrzScaffoldItem<_TestItem>> _itemsOf(List<String> names) {
  return [
    for (final name in names)
      LayrzScaffoldItem<_TestItem>(
        key: ValueKey(name),
        item: _TestItem(name, name),
        tile: SizedBox(child: Text(name)),
        searchableStrings: {name},
      ),
  ];
}

/// Pumps a [LayrzScaffoldShell] at a WIDE viewport with nothing open, so the
/// shell renders its desktop default [LayrzTable] view rather than the
/// list/detail split — this is the layout under test (DESIGN-216's table
/// mode), where [LayrzScaffoldController]'s counts previously stayed stale.
Future<void> _pumpTableShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
}) async {
  addTearDown(tester.view.reset);
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;

  await pumpThemed(
    tester,
    SizedBox.expand(
      child: LayrzScaffoldShell<_TestItem>(
        controller: controller,
        items: items,
        itemExtent: 56.0,
        title: const Text("Title"),
        tableColumns: [
          LayrzColumn<_TestItem>(
            key: const ValueKey("name"),
            headerText: "Name",
            valueBuilder: (item) => item.name,
            width: 200,
          ),
        ],
        tableController: tableController,
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

/// Finds the desktop table's own search field (its `EditableText`), ready for
/// [WidgetTester.enterText]. In table mode (nothing open) there is no list
/// panel mounted, so this is unambiguous.
Finder _tableSearchField() {
  return find.descendant(
    of: find.byType(LayrzTable<_TestItem>),
    matching: find.byType(EditableText),
  );
}

void main() {
  group("LayrzScaffoldShell publishes item counts to its controller in wide/table mode", () {
    testWidgets("initial load sets totalCount and filteredCount to the full item count", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpTableShell(tester, items: items, controller: controller, tableController: tableController);
      // LayrzTable defers its first onFilteredCountChanged report to a
      // post-frame callback; settle it.
      await tester.pump();

      expect(controller.totalCount.value, 3, reason: "totalCount must reflect all items in table mode");
      expect(controller.filteredCount.value, 3, reason: "filteredCount must reflect all items before any search");
    });

    testWidgets("searching the table narrows filteredCount on the scaffold controller", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpTableShell(tester, items: items, controller: controller, tableController: tableController);
      await tester.pump();
      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);

      await tester.enterText(_tableSearchField(), "Al");
      await tester.pumpAndSettle();

      // Proves the SCAFFOLD controller (not just the table controller)
      // receives the narrowed count while the wide/table layout is showing.
      expect(controller.totalCount.value, 3, reason: "totalCount is unaffected by search");
      expect(controller.filteredCount.value, 1, reason: "filteredCount must narrow to the matching row");
    });

    testWidgets("clearing the table search restores filteredCount to totalCount", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpTableShell(tester, items: items, controller: controller, tableController: tableController);
      await tester.pump();

      await tester.enterText(_tableSearchField(), "Al");
      await tester.pumpAndSettle();
      expect(controller.filteredCount.value, 1);
      // ignore: avoid_print
      print("DEBUG after Al: tableController.searchText=${tableController.searchText}");

      await tester.enterText(_tableSearchField(), "");
      // ignore: avoid_print
      print("DEBUG right after enterText(''): tableController.searchText=${tableController.searchText}");
      await tester.pump();
      // ignore: avoid_print
      print("DEBUG after one pump: tableController.searchText=${tableController.searchText}");
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print("DEBUG after settle: tableController.searchText=${tableController.searchText}");

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);
    });
  });
}

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

/// Pumps a [LayrzScaffoldShell] at the given [size] with [items], at a wide viewport
/// by default so the list panel (and its search field) render alongside the detail pane.
///
/// [controller] must already be open (see each call site) — on a wide viewport
/// with nothing open, the shell shows its desktop default table instead of the
/// list panel, and the table has its own, unrelated `EditableText` search field
/// that does not drive [LayrzScaffoldController.filteredCount]/[LayrzScaffoldController.totalCount].
Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  Size size = const Size(1500, 950),
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  await pumpThemed(
    tester,
    SizedBox.expand(
      child: LayrzScaffoldShell<_TestItem>(
        controller: controller,
        items: items,
        itemExtent: 56.0,
        title: const Text('Title'),
        tableColumns: [
          LayrzColumn<_TestItem>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

/// Finds the list panel's own search field -- specifically its `EditableText`,
/// ready for [WidgetTester.enterText].
///
/// The desktop default table (see [LayrzScaffoldShell]) stays mounted behind
/// the split even while an item is open, and it has its own `LayrzSearchInput`
/// with no `hintText`, so a bare `find.byType(EditableText).first` can resolve
/// to the table's field instead of the list panel's -- typing there does not
/// drive [LayrzScaffoldController.filteredCount]. The list panel's field is
/// the only one built with `hintText: 'Search items'` (a widget property,
/// matched directly rather than via its rendered hint text, since that hint
/// only renders while the field is empty), so matching on that property
/// disambiguates the two and stays valid after text is entered.
Finder _listPanelSearchField() {
  return find.descendant(
    of: find.byWidgetPredicate((w) => w is LayrzSearchInput && w.hintText == 'Search items'),
    matching: find.byType(EditableText),
  );
}

void main() {
  group("LayrzScaffoldShell publishes item counts to its controller", () {
    testWidgets("initial load sets totalCount and filteredCount to the item count", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("Alpha"), builder: (_) => const Text("detail"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller, tableController: tableController);
      // The counts are published from a post-frame callback; settle it.
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);
    });

    testWidgets("searching narrows filteredCount while totalCount stays the same", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("Alpha"), builder: (_) => const Text("detail"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller, tableController: tableController);
      await tester.pump();
      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);

      await tester.enterText(_listPanelSearchField(), "Al");
      await tester.pump();
      // One more pump to let the search-triggered post-frame callback settle.
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 1);
    });

    testWidgets("clearing the search restores filteredCount to totalCount", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("Alpha"), builder: (_) => const Text("detail"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller, tableController: tableController);
      await tester.pump();

      await tester.enterText(_listPanelSearchField(), "Al");
      await tester.pump();
      await tester.pump();
      expect(controller.filteredCount.value, 1);

      await tester.enterText(_listPanelSearchField(), "");
      await tester.pump();
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);
    });

    testWidgets("replacing the items list updates both counts", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("Alpha"), builder: (_) => const Text("detail"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      var items = _itemsOf(["Alpha", "Beta"]);

      late StateSetter setOuterState;

      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setOuterState = setState;
            return SizedBox.expand(
              child: LayrzScaffoldShell<_TestItem>(
                controller: controller,
                items: items,
                itemExtent: 56.0,
                title: const Text('Title'),
                tableColumns: [
                  LayrzColumn<_TestItem>(
                    key: const ValueKey('c'),
                    headerText: 'C',
                    valueBuilder: (item) => '',
                    width: 200,
                  ),
                ],
                tableController: tableController,
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(controller.totalCount.value, 2);
      expect(controller.filteredCount.value, 2);

      setOuterState(() {
        items = _itemsOf(["Alpha", "Beta", "Gamma", "Delta"]);
      });
      await tester.pump();
      await tester.pump();

      expect(controller.totalCount.value, 4);
      expect(controller.filteredCount.value, 4);
    });

    testWidgets("filteredCount listener fires when the search narrows the results", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("Alpha"), builder: (_) => const Text("detail"));
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller, tableController: tableController);
      await tester.pump();

      var notifications = 0;
      controller.filteredCount.addListener(() => notifications++);

      await tester.enterText(_listPanelSearchField(), "Al");
      await tester.pump();
      await tester.pump();

      expect(notifications, greaterThan(0));
      expect(controller.filteredCount.value, 1);
    });
  });
}

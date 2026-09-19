import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for the desktop table `multiselectActionsBuilder`
/// checkbox-enablement tests.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// The two columns every test in this file renders.
List<LayrzColumn<_TestItem>> _columns() => [
  LayrzColumn<_TestItem>(
    key: const ValueKey("name"),
    headerText: "Name",
    valueBuilder: (item) => item.name,
    width: 200,
  ),
  LayrzColumn<_TestItem>(
    key: const ValueKey("id"),
    headerText: "ID",
    valueBuilder: (item) => item.id,
    width: 120,
  ),
];

const _items = [
  _TestItem("1", "Alpha"),
  _TestItem("2", "Bravo"),
];

/// Wraps [_items] into scaffold items.
List<LayrzScaffoldItem<_TestItem>> _scaffoldItems() => _items
    .map(
      (item) => LayrzScaffoldItem<_TestItem>(
        key: ValueKey(item.id),
        item: item,
        tile: SizedBox(child: Text(item.name)),
        searchableStrings: {item.name},
      ),
    )
    .toList();

/// Finds only the per-row [LayrzCheckboxInput] cells, excluding the header's
/// own select-all checkbox.
///
/// Mirrors `test/table/table_test.dart`'s own `rowCheckboxes()` helper:
/// [LayrzTable] renders the header's select-all checkbox as a sibling ahead
/// of every row's, so anchoring on the row [ListView] ancestor isolates the
/// row-owned checkboxes from it.
Finder _rowCheckboxes() => find.descendant(of: find.byType(ListView), matching: find.byType(LayrzCheckboxInput));

/// Pumps a [LayrzScaffoldShell] at [size], with [multiselectActionsBuilder]
/// passed straight through — its presence is what now enables the desktop
/// table's checkbox column.
///
/// A real [Navigator] ancestor is provided so a compact-viewport open (which
/// presents a detail sheet) never asserts, matching the pattern in
/// `scaffold_shell_table_default_test.dart`.
Future<void> _pumpShell(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
  List<LayrzButton> Function(List<_TestItem> selected)? multiselectActionsBuilder,
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final shell = SizedBox.expand(
    child: LayrzScaffoldShell<_TestItem>(
      controller: controller,
      items: _scaffoldItems(),
      itemExtent: 56.0,
      title: const Text("Title"),
      tableColumns: _columns(),
      tableController: tableController,
      multiselectActionsBuilder: multiselectActionsBuilder,
      onItemTap: (item) => controller.open(key: item.key, builder: (_) => Text("detail:${item.item.name}")),
    ),
  );

  await pumpThemed(
    tester,
    Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) => shell,
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

const _kWideSize = Size(1600, 1200);

void main() {
  group("LayrzScaffoldShell multiselectActionsBuilder checkbox enablement", () {
    testWidgets("a non-null multiselectActionsBuilder renders a checkbox column on the desktop table", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
      );

      // One checkbox per row, plus the header's own select-all checkbox.
      expect(_rowCheckboxes(), findsNWidgets(_items.length));
      expect(find.byType(LayrzCheckboxInput), findsNWidgets(_items.length + 1));

      controller.dispose();
    });

    testWidgets("tapping a row checkbox toggles that item into tableController.selection", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        multiselectActionsBuilder: (selected) => [LayrzButton.delete(labelText: "Delete", onTap: () {})],
      );

      expect(tableController.selection, isEmpty);

      await tester.tap(_rowCheckboxes().first);
      await tester.pumpAndSettle();

      expect(tableController.selection, hasLength(1));
      expect(tableController.selection.first.id, _items.first.id);

      await tester.tap(_rowCheckboxes().first);
      await tester.pumpAndSettle();

      expect(tableController.selection, isEmpty);

      controller.dispose();
    });

    testWidgets("multiselectActionsBuilder omitted (default null) renders no checkbox column", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      expect(find.byType(LayrzCheckboxInput), findsNothing);

      controller.dispose();
    });
  });
}

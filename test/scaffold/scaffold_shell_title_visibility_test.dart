import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object used to exercise the table-default view.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// The single column the table-default view renders.
List<LayrzColumn<_TestItem>> _columns() => [
  LayrzColumn<_TestItem>(
    key: const ValueKey("name"),
    headerText: "Name",
    valueBuilder: (item) => item.name,
    width: 200,
  ),
];

/// Wraps a single item into a scaffold item, so the shell has something to render.
List<LayrzScaffoldItem<_TestItem>> _scaffoldItems() => [
  LayrzScaffoldItem<_TestItem>(
    key: const ValueKey("1"),
    item: const _TestItem("1", "Alpha"),
    tile: const Text("Alpha"),
    searchableStrings: const {"Alpha"},
  ),
];

/// Pumps a [LayrzScaffoldShell] at [size] with a recognizable [title].
Future<void> _pumpShell(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
  required Widget title,
}) async {
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  await pumpThemed(
    tester,
    SizedBox.expand(
      child: LayrzScaffoldShell<_TestItem>(
        controller: controller,
        items: _scaffoldItems(),
        itemExtent: 56.0,
        title: title,
        tableColumns: _columns(),
        tableController: tableController,
        onItemTap: (item) => controller.open(key: item.key, builder: (_) => Text("detail:${item.item.name}")),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

const _kWideSize = Size(1600, 1200);
const _kCompactSize = Size(400, 800);

void main() {
  group("LayrzScaffoldShell title visibility (bug fix)", () {
    testWidgets("wide + nothing open (table/listing mode): title is visible", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        title: const Text("My Scaffold Title"),
      );

      // Nothing is open, so the shell is in default table (listing) mode.
      expect(controller.isOpen, isFalse);
      expect(find.byType(LayrzTable<_TestItem>), findsOneWidget);

      // The title must render above the table in this mode -- previously it
      // was only rendered once an item was opened (inside ListPanel's header).
      expect(find.text("My Scaffold Title"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("narrow (compact) layout: title is already visible", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kCompactSize,
        title: const Text("My Scaffold Title"),
      );

      expect(controller.isOpen, isFalse);
      // The narrow layout always shows the list panel, whose header renders
      // the title as-is -- this direction already worked before the fix.
      expect(find.text("My Scaffold Title"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("wide + item open: title is still visible in the split's list panel header", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        title: const Text("My Scaffold Title"),
      );

      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail"));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);
      // The default table stays mounted (covered) behind the split for
      // performance (see LayrzScaffoldShell._buildWideLayout), so its own
      // copy of the title also still exists in the tree alongside the
      // split's -- assert presence, not a single instance.
      expect(find.text("My Scaffold Title"), findsWidgets);

      controller.dispose();
    });
  });
}

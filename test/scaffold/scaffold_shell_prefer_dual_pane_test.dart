import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/list_panel.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for the `preferDualPane` tests.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// The single column every test in this file renders.
List<LayrzColumn<_TestItem>> _columns() => [
  LayrzColumn<_TestItem>(
    key: const ValueKey("name"),
    headerText: "Name",
    valueBuilder: (item) => item.name,
    width: 200,
  ),
];

const _items = [
  _TestItem("1", "Alpha"),
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

/// Pumps a [LayrzScaffoldShell] at [size], with a real [Navigator] ancestor so
/// a compact-viewport open (which presents a detail sheet) never asserts.
Future<void> _pumpShell(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
  bool preferDualPane = false,
  Widget? dualPaneEmptyState,
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
      preferDualPane: preferDualPane,
      dualPaneEmptyState: dualPaneEmptyState,
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
const _kCompactSize = Size(400, 800);

void main() {
  group("LayrzScaffoldShell.preferDualPane", () {
    testWidgets("false (default), wide, nothing open: shows the table, NOT the split", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      expect(find.byType(LayrzTable<_TestItem>), findsOneWidget);
      expect(find.byType(ListPanel<_TestItem>), findsNothing);
    });

    testWidgets("true, wide, nothing open: shows the split (NOT the table) with the built-in empty state", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        preferDualPane: true,
      );

      // Split shown...
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
      expect(find.text("Alpha"), findsWidgets);
      // ...and the table, while still mounted behind the split for
      // performance (see LayrzScaffoldShell._buildWideLayout's doc), is
      // covered and excluded from semantics/hit-testing -- assert that via
      // its IgnorePointer/ExcludeSemantics ancestor instead of type absence.
      final tableFinder = find.byType(LayrzTable<_TestItem>);
      expect(tableFinder, findsOneWidget);
      expect(
        find.ancestor(of: tableFinder, matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: tableFinder, matching: find.byWidgetPredicate((w) => w is ExcludeSemantics && w.excluding)),
        findsOneWidget,
      );
      // Built-in localized empty state present in the detail pane.
      expect(find.text("No item selected"), findsOneWidget);
    });

    testWidgets("true, wide, nothing open, custom dualPaneEmptyState: renders the custom widget, not the default", (
      tester,
    ) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        preferDualPane: true,
        dualPaneEmptyState: const Text("Pick a row to see its detail", key: Key("custom-empty")),
      );

      expect(find.byKey(const Key("custom-empty")), findsOneWidget);
      expect(find.text("Pick a row to see its detail"), findsOneWidget);
      expect(find.text("No item selected"), findsNothing);
    });

    testWidgets("true, wide, item open: the detail builder renders normally, empty state absent", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        preferDualPane: true,
      );

      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      await tester.pumpAndSettle();

      expect(find.text("detail:Alpha"), findsOneWidget);
      expect(find.text("No item selected"), findsNothing);
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
    });

    testWidgets("true, compact viewport: flag is ignored -- single-pane list, no split", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kCompactSize,
        preferDualPane: true,
      );

      // Single-pane list, exactly as with preferDualPane: false on compact.
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);
      // No enforced split content (the empty-state placeholder is a wide-split
      // concept only) and no table.
      expect(find.text("No item selected"), findsNothing);
      expect(find.byType(LayrzTable<_TestItem>), findsNothing);

      // Opening an item still goes through the bottom-sheet path, not a split.
      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));
      await tester.pumpAndSettle();
      expect(find.text("detail:Alpha"), findsOneWidget);
    });

    testWidgets("no close button is rendered in the list panel header, preferDualPane: false", (tester) async {
      // The list panel header renders `title` as-is with no close button in
      // either mode today (see LayrzScaffoldShell._buildWideSplit's doc) --
      // this asserts that stays true, so a regression that adds an
      // unconditional close button is caught here.
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      // Open an item so the split renders (with preferDualPane: false the
      // split only shows once something is open).
      controller.open(key: const ValueKey("1"), builder: (_) => const Text("detail:Alpha"));

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      // No icon-button-like affordance beside the title within the list
      // panel -- the header is just `title` verbatim, so a bare
      // `Text("Title")` inside `ListPanel` is the only widget rendered for it
      // (no adjacent close affordance to find). The title is scoped to the
      // panel because the covered-but-still-mounted table behind the split
      // (see LayrzScaffoldShell._buildWideLayout's doc) renders its own
      // "Title" too.
      final panelFinder = find.byType(ListPanel<_TestItem>);
      expect(panelFinder, findsOneWidget);
      expect(find.descendant(of: panelFinder, matching: find.text("Title")), findsOneWidget);
    });

    testWidgets("no close button is rendered in the list panel header, preferDualPane: true", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        preferDualPane: true,
      );

      final panelFinder = find.byType(ListPanel<_TestItem>);
      expect(panelFinder, findsOneWidget);
      expect(find.descendant(of: panelFinder, matching: find.text("Title")), findsOneWidget);
    });
  });
}

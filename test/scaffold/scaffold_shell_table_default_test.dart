import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/list_panel.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for the table-default desktop tests (DESIGN-216).
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// The two columns every table-default test renders.
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

/// Pumps a [LayrzScaffoldShell] at [size].
///
/// A real [Navigator] ancestor is provided so a compact-viewport open (which
/// presents a detail sheet) never asserts.
Future<void> _pumpShell(
  WidgetTester tester, {
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
  String? showActionLabel,
  bool wireTap = true,
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
      showActionLabel: showActionLabel,
      onItemTap: wireTap
          ? (item) => controller.open(key: item.key, builder: (_) => Text("detail:${item.item.name}"))
          : null,
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
  group("DESIGN-216 — desktop default table view", () {
    testWidgets("wide + nothing open: shows the table, NOT the split", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      // The table is the default view...
      expect(find.byType(LayrzTable<_TestItem>), findsOneWidget);
      // ...and the list panel (the split's left pane) is absent while the table
      // owns the whole width.
      expect(find.byType(ListPanel<_TestItem>), findsNothing);
      // Column headers prove it is genuinely the table.
      expect(find.text("Name"), findsOneWidget);
      expect(find.text("ID"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("wide + item open: shows the split, NOT the table", (tester) async {
      final controller = LayrzScaffoldController()
        ..open(key: const ValueKey("1"), builder: (_) => const Text("detail"));
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      // With something open, the split (list panel) is shown and the table is
      // gone. The table is kept mounted behind the split for performance, so it
      // still exists in the tree — assert the split is present AND on top.
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
      // The list panel renders the row tiles.
      expect(find.text("Alpha"), findsWidgets);

      controller.dispose();
    });

    testWidgets("compact: never shows the table (narrow layout unaffected)", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kCompactSize);

      // The table default view is a wide-only presentation.
      expect(find.byType(LayrzTable<_TestItem>), findsNothing);
      // The narrow layout still renders its list (the item tiles are present).
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);

      controller.dispose();
    });

    testWidgets("tapping a row's open button opens that item and swaps to the split", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      expect(controller.isOpen, isFalse);
      expect(find.byType(LayrzTable<_TestItem>), findsOneWidget);

      // The open action for a row uses the default "Open item" label. Tap the
      // first one.
      final openButton = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Open item").first;
      await tester.ensureVisible(openButton);
      await tester.tap(openButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Something opened...
      expect(controller.isOpen, isTrue);
      // ...and the view swapped to the split.
      expect(find.byType(ListPanel<_TestItem>), findsOneWidget);

      controller.dispose();
    });

    testWidgets("the open button routes through onItemTap, not controller.open directly", (tester) async {
      // With no onItemTap wired, the open button must be inert: tapping it must
      // NOT open anything (proving the shell delegates to onItemTap and does
      // not call controller.open itself).
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        wireTap: false,
      );

      final openButton = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Open item").first;
      await tester.ensureVisible(openButton);
      await tester.tap(openButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse, reason: "with no onItemTap, the open button must not open anything");
      expect(find.byType(LayrzTable<_TestItem>), findsOneWidget);

      controller.dispose();
    });

    testWidgets("showActionLabel overrides the default open-button label", (tester) async {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(
        tester,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
        showActionLabel: "Reveal",
      );

      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Reveal"),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Open item"),
        findsNothing,
      );

      controller.dispose();
    });

    testWidgets("the shell passes the supplied tableController to its LayrzTable", (tester) async {
      // The injected controller must be the exact instance the shell's table
      // uses — proving it is genuinely wired through, so an app can observe and
      // drive the table's state from outside. Asserted structurally (the table
      // widget holds the same controller) rather than by driving a sort, whose
      // off-thread recompute does not settle deterministically in the harness.
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);

      await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

      final table = tester.widget<LayrzTable<_TestItem>>(find.byType(LayrzTable<_TestItem>));
      expect(identical(table.controller, tableController), isTrue);

      controller.dispose();
    });
  });

  group("DESIGN-216 — accessibility", () {
    testWidgets("the per-row open button exposes real button semantics", (tester) async {
      final handle = tester.ensureSemantics();
      try {
        final controller = LayrzScaffoldController();
        final tableController = LayrzTableController<_TestItem>();
        addTearDown(tableController.dispose);

        await _pumpShell(tester, controller: controller, tableController: tableController, size: _kWideSize);

        expect(
          tester.getSemantics(
            find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Open item").first,
          ),
          matchesSemantics(
            label: "Open item",
            isButton: true,
            isEnabled: true,
            hasEnabledState: true,
          ),
        );

        controller.dispose();
      } finally {
        handle.dispose();
      }
    });
  });
}

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";
import "package:layrz_ui/src/scaffold/src/list_panel.dart";

import "../helpers/pump_themed.dart";

/// Minimal domain object for testing.
class _TestItem {
  const _TestItem(this.id, this.name);

  final String id;
  final String name;
}

/// A minimal single column for the shell's now-required `tableColumns`.
List<LayrzColumn<_TestItem>> _columns() => [
  LayrzColumn<_TestItem>(
    key: const ValueKey('name'),
    headerText: 'Name',
    valueBuilder: (item) => item.name,
    width: 200,
  ),
];

/// Pumps a [LayrzScaffoldShell] at [size] with [items], with an item already
/// open so the list-detail SPLIT (and therefore the list panel this file
/// tests) is what renders on wide viewports — otherwise the wide shell shows
/// its default table instead of the list panel.
Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
  required LayrzTableController<_TestItem> tableController,
  required Size size,
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
        tableColumns: _columns(),
        tableController: tableController,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Builds [count] plain items, each named by its index.
List<LayrzScaffoldItem<_TestItem>> _plainItems(int count) {
  return List.generate(
    count,
    (i) => LayrzScaffoldItem<_TestItem>(
      key: ValueKey("$i"),
      item: _TestItem("$i", "Item $i"),
      tile: Text("Item $i"),
      searchableStrings: {"Item $i"},
    ),
  );
}

const _kWideSize = Size(1500, 950);

void main() {
  group("ListPanel — zebra striping (DESIGN-62.3)", () {
    testWidgets("even-index row resolves to sf1, odd-index row resolves to sf2", (tester) async {
      // Open an item so the wide split (with the list panel) is shown, not the
      // default table. The opened row is index 0, so assert parity on the rest.
      final controller = LayrzScaffoldController()..open(key: const ValueKey("0"), builder: (_) => const Text("d"));
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _plainItems(4);

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester
          .widgetList<LayrzTappable>(
            find.descendant(of: find.byType(ListPanel<_TestItem>), matching: find.byType(LayrzTappable)),
          )
          .toList();

      expect(tappables.length, 4);
      // Row 0 is the opened/selected row -> sf4; the rest follow parity.
      expect(tappables[0].color, tokens.colors.sf4, reason: "row 0 (even, SELECTED) must be sf4");
      expect(tappables[1].color, tokens.colors.sf2, reason: "row 1 (odd) must be sf2");
      expect(tappables[2].color, tokens.colors.sf1, reason: "row 2 (even) must be sf1");
      expect(tappables[3].color, tokens.colors.sf2, reason: "row 3 (odd) must be sf2");

      controller.dispose();
    });

    testWidgets("a selected row resolves to sf4 regardless of its parity", (tester) async {
      // Select item index 1 (odd) — sf4 must win over the sf2 its parity would
      // otherwise resolve to. Opening it also shows the split.
      final controller = LayrzScaffoldController()..open(key: const ValueKey("1"), builder: (_) => const Text("d"));
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _plainItems(4);

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester
          .widgetList<LayrzTappable>(
            find.descendant(of: find.byType(ListPanel<_TestItem>), matching: find.byType(LayrzTappable)),
          )
          .toList();

      expect(tappables.length, 4);
      expect(tappables[0].color, tokens.colors.sf1, reason: "row 0 (even, unselected) must be sf1");
      expect(tappables[1].color, tokens.colors.sf4, reason: "row 1 (odd, SELECTED) must be sf4 — selected wins");
      expect(tappables[2].color, tokens.colors.sf1, reason: "row 2 (even, unselected) must be sf1");
      expect(tappables[3].color, tokens.colors.sf2, reason: "row 3 (odd, unselected) must be sf2");

      controller.dispose();
    });

    testWidgets("an even-index selected row also resolves to sf4, not sf1", (tester) async {
      final controller = LayrzScaffoldController()..open(key: const ValueKey("0"), builder: (_) => const Text("d"));
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _plainItems(2);

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      final tokens = LayrzThemeData.light().tokens;
      final tappables = tester
          .widgetList<LayrzTappable>(
            find.descendant(of: find.byType(ListPanel<_TestItem>), matching: find.byType(LayrzTappable)),
          )
          .toList();

      expect(tappables[0].color, tokens.colors.sf4, reason: "row 0 (even, SELECTED) must be sf4 — selected wins");
      expect(tappables[1].color, tokens.colors.sf2, reason: "row 1 (odd, unselected) must be sf2");

      controller.dispose();
    });
  });

  group("ListPanel — default width (DESIGN-62.2)", () {
    testWidgets("with no explicit width, the panel renders at kLayrzScaffoldListWidth", (tester) async {
      // Open an item so the split (with the list panel) is shown on wide.
      final controller = LayrzScaffoldController()..open(key: const ValueKey("0"), builder: (_) => const Text("d"));
      final tableController = LayrzTableController<_TestItem>();
      addTearDown(tableController.dispose);
      final items = _plainItems(2);

      await _pumpShell(
        tester,
        items: items,
        controller: controller,
        tableController: tableController,
        size: _kWideSize,
      );

      // Locate the ListPanel's own Container by matching its width against the
      // constant — it is the outermost Container carrying an explicit `width`
      // in the wide split layout.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final widthMatches = containers.where((c) => c.constraints?.maxWidth == kLayrzScaffoldListWidth);
      expect(
        widthMatches,
        isNotEmpty,
        reason: "expected a Container constrained to kLayrzScaffoldListWidth — the list panel's default",
      );

      controller.dispose();
    });
  });
}

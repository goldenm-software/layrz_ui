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
Future<void> _pumpShell(
  WidgetTester tester, {
  required List<LayrzScaffoldItem<_TestItem>> items,
  required LayrzScaffoldController controller,
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
      ),
    ),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  group("LayrzScaffoldShell publishes item counts to its controller", () {
    testWidgets("initial load sets totalCount and filteredCount to the item count", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller);
      // The counts are published from a post-frame callback; settle it.
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);
    });

    testWidgets("searching narrows filteredCount while totalCount stays the same", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller);
      await tester.pump();
      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);

      await tester.enterText(find.byType(EditableText).first, "Al");
      await tester.pump();
      // One more pump to let the search-triggered post-frame callback settle.
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 1);
    });

    testWidgets("clearing the search restores filteredCount to totalCount", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller);
      await tester.pump();

      await tester.enterText(find.byType(EditableText).first, "Al");
      await tester.pump();
      await tester.pump();
      expect(controller.filteredCount.value, 1);

      await tester.enterText(find.byType(EditableText).first, "");
      await tester.pump();
      await tester.pump();

      expect(controller.totalCount.value, 3);
      expect(controller.filteredCount.value, 3);
    });

    testWidgets("replacing the items list updates both counts", (tester) async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
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
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);
      final items = _itemsOf(["Alpha", "Beta", "Gamma"]);

      await _pumpShell(tester, items: items, controller: controller);
      await tester.pump();

      var notifications = 0;
      controller.filteredCount.addListener(() => notifications++);

      await tester.enterText(find.byType(EditableText).first, "Al");
      await tester.pump();
      await tester.pump();

      expect(notifications, greaterThan(0));
      expect(controller.filteredCount.value, 1);
    });
  });
}

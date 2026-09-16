import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("LayrzScaffoldShell", () {
    test("constructor accepts required parameters", () {
      final controller = LayrzScaffoldController();
      final items = <LayrzScaffoldItem<String>>[];
      final tableController = LayrzTableController<String>();

      final shell = LayrzScaffoldShell(
        items: items,
        controller: controller,
        itemExtent: 48.0,
        title: const Text('Title'),
        tableColumns: [
          LayrzColumn<String>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
      );

      expect(shell, isNotNull);
      controller.dispose();
      tableController.dispose();
    });

    test("with generic type parameter for items", () {
      final controller = LayrzScaffoldController();
      final items = <LayrzScaffoldItem<Map<String, dynamic>>>[];
      final tableController = LayrzTableController<Map<String, dynamic>>();

      final shell = LayrzScaffoldShell<Map<String, dynamic>>(
        items: items,
        controller: controller,
        itemExtent: 48.0,
        title: const Text('Title'),
        tableColumns: [
          LayrzColumn<Map<String, dynamic>>(
            key: const ValueKey('c'),
            headerText: 'C',
            valueBuilder: (item) => '',
            width: 200,
          ),
        ],
        tableController: tableController,
      );

      expect(shell, isNotNull);
      controller.dispose();
      tableController.dispose();
    });

    test("default values for optional parameters", () {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<String>();
      const title = Text('Title');
      final shell = LayrzScaffoldShell<String>(
        items: const [],
        controller: controller,
        itemExtent: 48.0,
        title: title,
        tableColumns: [
          LayrzColumn<String>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
      );

      expect(shell.footer, isNull);
      expect(shell.searchable, isTrue);
      // `title` is a required, non-nullable Widget on LayrzScaffoldShell --
      // there is no "default" for it, so this asserts the shell stored
      // exactly the widget instance passed in.
      expect(shell.title, same(title));
      expect(shell.preferDualPane, isFalse);
      expect(shell.dualPaneEmptyState, isNull);

      controller.dispose();
      tableController.dispose();
    });

    test("preferDualPane and dualPaneEmptyState can be provided", () {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<String>();
      final dualPaneEmptyState = Text("Nothing selected");

      final shell = LayrzScaffoldShell<String>(
        items: const [],
        controller: controller,
        itemExtent: 48.0,
        title: const Text('Title'),
        tableColumns: [
          LayrzColumn<String>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
        preferDualPane: true,
        dualPaneEmptyState: dualPaneEmptyState,
      );

      expect(shell.preferDualPane, isTrue);
      expect(shell.dualPaneEmptyState, same(dualPaneEmptyState));

      controller.dispose();
      tableController.dispose();
    });

    test("all optional parameters can be provided", () {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<String>();
      final footer = Container();
      final title = Text("Items");

      final shell = LayrzScaffoldShell<String>(
        items: const [
          LayrzScaffoldItem(
            key: ValueKey("a"),
            item: "a",
            tile: SizedBox(),
            searchableStrings: {"a"},
          ),
        ],
        controller: controller,
        onItemTap: (item) => controller.open(key: item.key, builder: (_) => const Text("detail")),
        footer: footer,
        searchable: false,
        title: title,
        itemExtent: 48.0,
        tableColumns: [
          LayrzColumn<String>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
      );

      expect(shell.footer, equals(footer));
      expect(shell.searchable, isFalse);
      expect(shell.title, equals(title));
      controller.dispose();
      tableController.dispose();
    });

    test("state is created correctly", () {
      final controller = LayrzScaffoldController();
      final tableController = LayrzTableController<String>();
      final shell = LayrzScaffoldShell<String>(
        items: const [],
        controller: controller,
        itemExtent: 48.0,
        title: const Text('Title'),
        tableColumns: [
          LayrzColumn<String>(key: const ValueKey('c'), headerText: 'C', valueBuilder: (item) => '', width: 200),
        ],
        tableController: tableController,
      );

      final state = shell.createState();
      expect(state, isNotNull);
      controller.dispose();
      tableController.dispose();
    });

    test("LayrzScaffoldItem equality is based on key only", () {
      const item1 = LayrzScaffoldItem(
        key: ValueKey("same-key"),
        item: "data1",
        tile: SizedBox(),
      );
      const item2 = LayrzScaffoldItem(
        key: ValueKey("same-key"),
        item: "data2",
        tile: SizedBox(),
      );
      const item3 = LayrzScaffoldItem(
        key: ValueKey("different-key"),
        item: "data1",
        tile: SizedBox(),
      );

      // Same key = equal
      expect(item1 == item2, isTrue);
      expect(item1.hashCode == item2.hashCode, isTrue);

      // Different key = not equal
      expect(item1 == item3, isFalse);
      expect(item1.hashCode == item3.hashCode, isFalse);
    });
  });
}

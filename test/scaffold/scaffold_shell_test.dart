import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("LayrzScaffoldShell", () {
    test("constructor accepts required parameters", () {
      final controller = LayrzScaffoldController();
      final items = <LayrzScaffoldItem<String>>[];

      final shell = LayrzScaffoldShell(
        items: items,
        controller: controller,
        onDetailsBuild: (item) => const SizedBox(),
        itemExtent: 48.0,
      );

      expect(shell, isNotNull);
      controller.dispose();
    });

    test("with generic type parameter for items", () {
      final controller = LayrzScaffoldController();
      final items = <LayrzScaffoldItem<Map<String, dynamic>>>[];

      final shell = LayrzScaffoldShell<Map<String, dynamic>>(
        items: items,
        controller: controller,
        onDetailsBuild: (item) => const SizedBox(),
        itemExtent: 48.0,
      );

      expect(shell, isNotNull);
      controller.dispose();
    });

    test("default values for optional parameters", () {
      final controller = LayrzScaffoldController();
      final shell = LayrzScaffoldShell<String>(
        items: const [],
        controller: controller,
        onDetailsBuild: (_) => const SizedBox(),
        itemExtent: 48.0,
      );

      expect(shell.footer, isNull);
      expect(shell.searchable, isTrue);
      expect(shell.title, isNull);

      controller.dispose();
    });

    test("all optional parameters can be provided", () {
      final controller = LayrzScaffoldController();
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
        onDetailsBuild: (_) => const Text("detail"),
        footer: footer,
        searchable: false,
        title: title,
        itemExtent: 48.0,
      );

      expect(shell.footer, equals(footer));
      expect(shell.searchable, isFalse);
      expect(shell.title, equals(title));
      controller.dispose();
    });

    test("state is created correctly", () {
      final controller = LayrzScaffoldController();
      final shell = LayrzScaffoldShell<String>(
        items: const [],
        controller: controller,
        onDetailsBuild: (_) => const SizedBox(),
        itemExtent: 48.0,
      );

      final state = shell.createState();
      expect(state, isNotNull);
      controller.dispose();
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

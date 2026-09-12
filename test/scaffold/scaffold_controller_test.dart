import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("LayrzScaffoldController", () {
    test("initial state is closed", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      expect(controller.openedKey, isNull);
      expect(controller.openedBuilder, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("initial state via initialOpenedKey sets openedKey but NOT isOpen (no builder yet)", () {
      // initialOpenedKey alone gives no builder, and isOpen is defined by
      // openedBuilder (not openedKey) so a create-form open with no key can
      // still read as open. The direct consequence: constructing with only a
      // key does not itself count as "open".
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController(
        initialOpenedKey: key,
      );
      addTearDown(controller.dispose);

      expect(controller.openedKey, key);
      expect(controller.openedBuilder, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("open sets both the key and the builder", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      final key = ValueKey("item1");
      Widget builder(BuildContext context) => const Text("detail");
      controller.open(key: key, builder: builder);

      expect(controller.openedKey, key);
      expect(controller.openedBuilder, same(builder));
      expect(controller.isOpen, isTrue);
    });

    test("open with NO key sets openedBuilder and leaves openedKey null, but isOpen is true", () {
      // The core "create new item" capability: key is optional, and isOpen keys
      // off the builder, so a keyless open (nothing to highlight in the list)
      // still reads as genuinely open.
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      Widget builder(BuildContext context) => const Text("new-form");
      controller.open(builder: builder);

      expect(controller.openedKey, isNull);
      expect(controller.openedBuilder, same(builder));
      expect(controller.isOpen, isTrue);
    });

    test("close clears both the key and the builder", () {
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.open(key: key, builder: (_) => const Text("detail"));
      controller.close();

      expect(controller.openedKey, isNull);
      expect(controller.openedBuilder, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("close clears a keyless open too", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.open(builder: (_) => const Text("new-form"));
      expect(controller.isOpen, isTrue);

      controller.close();

      expect(controller.openedKey, isNull);
      expect(controller.openedBuilder, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("open notifies listeners", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      final key = ValueKey("item1");
      controller.open(key: key, builder: (_) => const Text("detail"));
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("close notifies listeners", () async {
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.open(key: key, builder: (_) => const Text("detail"));
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.close();
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("opening the same key with an identical builder is a no-op", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      final key = ValueKey("item1");
      Widget builder(BuildContext context) => const Text("detail");
      controller.open(key: key, builder: builder);
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.open(key: key, builder: builder);
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("opening with the same identical builder and no key (both null) is a no-op", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      Widget builder(BuildContext context) => const Text("detail");
      controller.open(builder: builder);
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.open(builder: builder);
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("re-opening the same key with a NEW builder still takes effect", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      final key = ValueKey("item1");
      controller.open(key: key, builder: (_) => const Text("first"));
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      Widget secondBuilder(BuildContext context) => const Text("second");
      controller.open(key: key, builder: secondBuilder);
      await Future.microtask(() {});

      expect(notificationCount, greaterThan(0));
      expect(controller.openedBuilder, same(secondBuilder));
    });

    test("closing when already closed is a no-op", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.close();
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("dispose stops notifications", () async {
      final controller = LayrzScaffoldController();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.dispose();
      expect(
        () => controller.open(key: ValueKey("item1"), builder: (_) => const Text("detail")),
        throwsFlutterError,
      );
      expect(notificationCount, 0);
    });

    test("multiple listeners receive notifications", () async {
      final controller = LayrzScaffoldController();
      int count1 = 0;
      int count2 = 0;

      controller.addListener(() => count1++);
      controller.addListener(() => count2++);

      final key = ValueKey("item1");
      controller.open(key: key, builder: (_) => const Text("detail"));
      await Future.microtask(() {});

      expect(count1, 1);
      expect(count2, 1);
      controller.dispose();
    });

    test("listener can be removed", () async {
      final controller = LayrzScaffoldController();
      int callCount = 0;
      void listener() => callCount++;

      controller.addListener(listener);
      final key1 = ValueKey("item1");
      controller.open(key: key1, builder: (_) => const Text("detail"));
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.removeListener(listener);
      final key2 = ValueKey("item2");
      controller.open(key: key2, builder: (_) => const Text("detail"));
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.dispose();
    });

    test("close on already-closed controller is no-op", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.close();
      await Future.microtask(() {});
      expect(controller.isOpen, isFalse);
      expect(controller.openedKey, isNull);
    });

    test("openedKey and openedBuilder properties reflect current state", () async {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      expect(controller.openedKey, isNull);
      expect(controller.openedBuilder, isNull);
      expect(controller.isOpen, isFalse);

      final key1 = ValueKey("item1");
      Widget builder1(BuildContext context) => const Text("one");
      controller.open(key: key1, builder: builder1);
      expect(controller.openedKey, key1);
      expect(controller.openedBuilder, same(builder1));
      expect(controller.isOpen, isTrue);

      final key2 = ValueKey("item2");
      Widget builder2(BuildContext context) => const Text("two");
      controller.open(key: key2, builder: builder2);
      expect(controller.openedKey, key2);
      expect(controller.openedBuilder, same(builder2));
      expect(controller.isOpen, isTrue);
    });

    test(
      "SYNTHETIC/NO KEY: opening with no key at all still opens the detail pane via its builder, "
      "and highlights no row",
      () {
        // This is the core "create new item" capability: `key` is optional on
        // `open`, so a caller with no domain object yet (e.g. a "New category"
        // form) can open the detail pane with just a builder. `openedKey` staying
        // null is exactly what makes no list row highlight.
        final controller = LayrzScaffoldController();
        addTearDown(controller.dispose);

        Widget createFormBuilder(BuildContext context) => const Text("new-form");
        controller.open(builder: createFormBuilder);

        expect(controller.openedKey, isNull);
        expect(controller.openedBuilder, same(createFormBuilder));
        expect(controller.isOpen, isTrue);
      },
    );
  });

  group("totalCount / filteredCount", () {
    test("both notifiers default to 0", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      expect(controller.totalCount.value, 0);
      expect(controller.filteredCount.value, 0);
    });

    test("updateCounts sets both notifier values", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.updateCounts(total: 10, filtered: 4);

      expect(controller.totalCount.value, 10);
      expect(controller.filteredCount.value, 4);
    });

    test("filteredCount notifies only when its value changes", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.filteredCount.addListener(() => notifications++);

      controller.updateCounts(total: 10, filtered: 5);
      expect(notifications, 1);

      // Same filtered value (total changes) does not re-notify filteredCount.
      controller.updateCounts(total: 8, filtered: 5);
      expect(notifications, 1);

      controller.updateCounts(total: 8, filtered: 2);
      expect(notifications, 2);
    });

    test("totalCount notifies only when its value changes", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.totalCount.addListener(() => notifications++);

      controller.updateCounts(total: 10, filtered: 5);
      expect(notifications, 1);

      // Same total value (filtered changes) does not re-notify totalCount.
      controller.updateCounts(total: 10, filtered: 3);
      expect(notifications, 1);

      controller.updateCounts(total: 12, filtered: 3);
      expect(notifications, 2);
    });

    test("filteredCount equals totalCount when nothing is filtered out", () {
      final controller = LayrzScaffoldController();
      addTearDown(controller.dispose);

      controller.updateCounts(total: 7, filtered: 7);

      expect(controller.filteredCount.value, controller.totalCount.value);
    });

    test("dispose disposes the count notifiers", () {
      final controller = LayrzScaffoldController();

      controller.dispose();

      // A disposed ValueNotifier still allows reading its last .value (plain field
      // access), but rejects new listeners — the same contract LayrzTableController's
      // visibleCount/totalCount notifiers are held to. Asserting on addListener is
      // therefore the real signal that dispose() reached these notifiers at all.
      expect(() => controller.totalCount.addListener(() {}), throwsFlutterError);
      expect(() => controller.filteredCount.addListener(() {}), throwsFlutterError);
    });
  });
}

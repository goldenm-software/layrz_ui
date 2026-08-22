import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("LayrzScaffoldController", () {
    test("initial state is closed", () {
      final controller = LayrzScaffoldController();
      expect(controller.openedKey, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("initial state can be opened", () {
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController(
        initialOpenedKey: key,
      );
      expect(controller.openedKey, key);
      expect(controller.isOpen, isTrue);
    });

    test("open sets the key", () {
      final controller = LayrzScaffoldController();
      final key = ValueKey("item1");
      controller.open(key);
      expect(controller.openedKey, key);
      expect(controller.isOpen, isTrue);
    });

    test("close clears the key", () {
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController(
        initialOpenedKey: key,
      );
      controller.close();
      expect(controller.openedKey, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("open notifies listeners", () async {
      final controller = LayrzScaffoldController();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      final key = ValueKey("item1");
      controller.open(key);
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("close notifies listeners", () async {
      final key = ValueKey("item1");
      final controller = LayrzScaffoldController(
        initialOpenedKey: key,
      );
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.close();
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("opening same key is a no-op", () async {
      final controller = LayrzScaffoldController();
      final key = ValueKey("item1");
      controller.open(key);
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.open(key);
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("closing when already closed is a no-op", () async {
      final controller = LayrzScaffoldController();
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
        () => controller.open(ValueKey("item1")),
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
      controller.open(key);
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
      controller.open(key1);
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.removeListener(listener);
      final key2 = ValueKey("item2");
      controller.open(key2);
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.dispose();
    });

    test("close on already-closed controller is no-op", () async {
      final controller = LayrzScaffoldController();
      controller.close();
      await Future.microtask(() {});
      expect(controller.isOpen, isFalse);
      expect(controller.openedKey, isNull);
      controller.dispose();
    });

    test("openedKey property reflects current state", () async {
      final controller = LayrzScaffoldController();
      expect(controller.openedKey, isNull);
      expect(controller.isOpen, isFalse);

      final key1 = ValueKey("item1");
      controller.open(key1);
      expect(controller.openedKey, key1);
      expect(controller.isOpen, isTrue);

      final key2 = ValueKey("item2");
      controller.open(key2);
      expect(controller.openedKey, key2);
      expect(controller.isOpen, isTrue);

      controller.dispose();
    });
  });
}

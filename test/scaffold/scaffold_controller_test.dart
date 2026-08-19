import "package:flutter_test/flutter_test.dart";
import "package:layrz_ui/layrz_ui.dart";

void main() {
  group("LayrzScaffoldController", () {
    test("initial state is closed", () {
      final controller = LayrzScaffoldController<String>();
      expect(controller.opened, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("initial state can be opened", () {
      final controller = LayrzScaffoldController<String>(
        initialOpened: "item1",
      );
      expect(controller.opened, "item1");
      expect(controller.isOpen, isTrue);
    });

    test("open sets the item", () {
      final controller = LayrzScaffoldController<String>();
      controller.open("item1");
      expect(controller.opened, "item1");
      expect(controller.isOpen, isTrue);
    });

    test("close clears the item", () {
      final controller = LayrzScaffoldController<String>(
        initialOpened: "item1",
      );
      controller.close();
      expect(controller.opened, isNull);
      expect(controller.isOpen, isFalse);
    });

    test("open notifies listeners", () async {
      final controller = LayrzScaffoldController<String>();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.open("item1");
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("close notifies listeners", () async {
      final controller = LayrzScaffoldController<String>(
        initialOpened: "item1",
      );
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.close();
      await Future.microtask(() {});
      expect(notificationCount, greaterThan(0));
    });

    test("opening same item is a no-op", () async {
      final controller = LayrzScaffoldController<String>();
      controller.open("item1");
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.open("item1");
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("closing when already closed is a no-op", () async {
      final controller = LayrzScaffoldController<String>();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.close();
      await Future.microtask(() {});
      expect(notificationCount, 0);
    });

    test("dispose stops notifications", () async {
      final controller = LayrzScaffoldController<String>();
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      controller.dispose();
      expect(() => controller.open("item1"), throwsFlutterError);
      expect(notificationCount, 0);
    });

    test("multiple listeners receive notifications", () async {
      final controller = LayrzScaffoldController<String>();
      int count1 = 0;
      int count2 = 0;

      controller.addListener(() => count1++);
      controller.addListener(() => count2++);

      controller.open("item1");
      await Future.microtask(() {});

      expect(count1, 1);
      expect(count2, 1);
      controller.dispose();
    });

    test("listener can be removed", () async {
      final controller = LayrzScaffoldController<String>();
      int callCount = 0;
      void listener() => callCount++;

      controller.addListener(listener);
      controller.open("item1");
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.removeListener(listener);
      controller.open("item2");
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.dispose();
    });

    test("close on already-closed controller is no-op", () async {
      final controller = LayrzScaffoldController<String>();
      controller.close();
      await Future.microtask(() {});
      expect(controller.isOpen, isFalse);
      expect(controller.opened, isNull);
      controller.dispose();
    });

    test("opened property reflects current state", () async {
      final controller = LayrzScaffoldController<String>();
      expect(controller.opened, isNull);
      expect(controller.isOpen, isFalse);

      controller.open("item1");
      expect(controller.opened, equals("item1"));
      expect(controller.isOpen, isTrue);

      controller.open("item2");
      expect(controller.opened, equals("item2"));
      expect(controller.isOpen, isTrue);

      controller.dispose();
    });
  });
}

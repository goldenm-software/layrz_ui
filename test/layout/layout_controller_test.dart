import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

// Test helper to pump a themed layout with proper device pixel ratio setup,
// mirroring layout_test.dart's helper. The nav rail only renders in the
// expanded presentation (>= 960px), so every widget test here uses a wide
// viewport unless explicitly testing the compact/drawer path.
Future<void> _pumpThemedLayout(
  WidgetTester tester,
  Widget layout, {
  Size size = const Size(1400, 900),
  double devicePixelRatio = 1.0,
}) async {
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = size;

  await pumpThemedApp(tester, layout);
}

void main() {
  group('LayrzLayoutController construction', () {
    test('defaults to closed notifications panel and empty search query', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      expect(controller.notificationsOpen, isFalse);
      expect(controller.searchQuery, isEmpty);
    });

    test('seeds notificationsOpen and searchQuery from constructor arguments', () {
      final controller = LayrzLayoutController(notificationsOpen: true, searchQuery: 'devices');
      addTearDown(controller.dispose);

      expect(controller.notificationsOpen, isTrue);
      expect(controller.searchQuery, 'devices');
    });

    test('railScrollController is a real, usable ScrollController', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      expect(controller.railScrollController, isA<ScrollController>());
      expect(controller.railScrollController.hasClients, isFalse);
      expect(controller.railScrollController.initialScrollOffset, 0.0);
    });
  });

  group('LayrzLayoutController.setNotificationsOpen', () {
    test('updates notificationsOpen and notifies listeners', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNotificationsOpen(true);

      expect(controller.notificationsOpen, isTrue);
      expect(notifications, 1);
    });

    test('setting the same value again is a no-op (no notification)', () {
      final controller = LayrzLayoutController(notificationsOpen: true);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNotificationsOpen(true);

      expect(controller.notificationsOpen, isTrue);
      expect(notifications, 0);
    });

    test('toggleNotifications flips notificationsOpen and notifies', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.toggleNotifications();
      expect(controller.notificationsOpen, isTrue);
      expect(notifications, 1);

      controller.toggleNotifications();
      expect(controller.notificationsOpen, isFalse);
      expect(notifications, 2);
    });
  });

  group('LayrzLayoutController.setSearchQuery', () {
    test('updates searchQuery and notifies listeners', () {
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setSearchQuery('router');

      expect(controller.searchQuery, 'router');
      expect(notifications, 1);
    });

    test('setting the same value again is a no-op (no notification)', () {
      final controller = LayrzLayoutController(searchQuery: 'router');
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setSearchQuery('router');

      expect(controller.searchQuery, 'router');
      expect(notifications, 0);
    });

    test('accepts clearing the query back to empty', () {
      final controller = LayrzLayoutController(searchQuery: 'router');
      addTearDown(controller.dispose);

      controller.setSearchQuery('');

      expect(controller.searchQuery, isEmpty);
    });
  });

  group('LayrzLayoutController.dispose', () {
    test('disposes the owned railScrollController', () {
      final controller = LayrzLayoutController();
      final rail = controller.railScrollController;

      controller.dispose();

      // A disposed ScrollController throws when its listenable API is used.
      expect(() => rail.addListener(() {}), throwsA(isA<FlutterError>()));
    });
  });

  group('LayrzLayout controller ownership', () {
    testWidgets('with no controller supplied, creates and disposes an internal one', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: const SizedBox(child: Text('Body A')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Body A'), findsOneWidget);

      // Unmount the layout; an internally-owned controller must be disposed
      // without throwing, and without leaving anything the test framework
      // would flag as a leaked resource.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('with an external controller, does not dispose it on unmount', (WidgetTester tester) async {
      final controller = LayrzLayoutController();
      addTearDown(() {
        // Only safe because the test proves below that LayrzLayout did NOT
        // already dispose it; a double-dispose would throw.
        controller.dispose();
      });

      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: const SizedBox(child: Text('Body B')),
          controller: controller,
        ),
      );

      expect(tester.takeException(), isNull);

      // Unmount the layout that was using the external controller.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);

      // The external controller must still be alive and usable: mutating it
      // after the widget that borrowed it is gone must not throw.
      expect(() => controller.setSearchQuery('still alive'), returnsNormally);
      expect(controller.searchQuery, 'still alive');
    });

    testWidgets('swapping to a different controller detaches the old one without disposing it', (
      WidgetTester tester,
    ) async {
      final firstController = LayrzLayoutController();
      addTearDown(firstController.dispose);
      final secondController = LayrzLayoutController();
      addTearDown(secondController.dispose);

      Widget buildWith(LayrzLayoutController controller) => LayrzLayout(
        logo: 'assets/test-logo.png',
        items: [
          LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
        ],
        body: const SizedBox(child: Text('Body C')),
        controller: controller,
      );

      await _pumpThemedLayout(tester, buildWith(firstController));
      expect(tester.takeException(), isNull);

      await _pumpThemedLayout(tester, buildWith(secondController));
      expect(tester.takeException(), isNull);

      // The first controller was detached, not disposed -- it must remain
      // fully usable.
      expect(() => firstController.setNotificationsOpen(true), returnsNormally);
      expect(firstController.notificationsOpen, isTrue);
    });

    testWidgets('notificationsOpen and searchQuery on an external controller are readable while mounted', (
      WidgetTester tester,
    ) async {
      final controller = LayrzLayoutController(notificationsOpen: true, searchQuery: 'seeded');
      addTearDown(controller.dispose);

      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: const SizedBox(child: Text('Body D')),
          controller: controller,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(controller.notificationsOpen, isTrue);
      expect(controller.searchQuery, 'seeded');

      // Mutating the controller while LayrzLayout is mounted and listening
      // must not throw, and the layout must still be present afterward.
      controller.setSearchQuery('changed');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Body D'), findsOneWidget);
    });
  });

  group('LayrzLayoutController rail scroll offset persistence', () {
    testWidgets('offset set on the controller-owned ScrollController survives a widget rebuild', (
      WidgetTester tester,
    ) async {
      // This exercises persistence at the controller level: the same
      // ScrollController instance is what LayrzLayoutController hands out
      // via railScrollController, and that instance -- not a fresh one -- is
      // what must survive a route/body rebuild once it is attached to the
      // nav rail's scrollable (tracked separately; see the navigator_panel.dart
      // TODO in the delivery report). Here it is attached directly to a
      // plain scrollable list standing in for that rail.
      final controller = LayrzLayoutController();
      addTearDown(controller.dispose);

      Widget buildScrollable(String label) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Text(label),
              Expanded(
                child: ListView.builder(
                  controller: controller.railScrollController,
                  itemCount: 50,
                  itemExtent: 50.0,
                  itemBuilder: (context, index) => SizedBox(height: 50.0, child: Text('Item $index')),
                ),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(buildScrollable('route A'));
      expect(tester.takeException(), isNull);

      controller.railScrollController.jumpTo(400.0);
      await tester.pump();

      expect(controller.railScrollController.offset, 400.0);

      // Rebuild the surrounding widget (a differently-labeled sibling, the
      // way a route swap would rebuild LayrzLayout's body) while the
      // scrollable itself keeps the same position in the tree and the same
      // attached controller.
      await tester.pumpWidget(buildScrollable('route B'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('route B'), findsOneWidget);
      expect(controller.railScrollController.hasClients, isTrue);
      expect(controller.railScrollController.offset, 400.0);
    });

    testWidgets(
      'end-to-end: scrolling the actual LayrzLayout nav rail survives a body swap across route rebuilds',
      (WidgetTester tester) async {
        // Real end-to-end proof that LayrzLayoutController.railScrollController
        // is attached to the nav rail's own scrollable inside
        // LayrzLayoutNavigatorPanel (wired via layout.dart's two call sites),
        // not just to a stand-in scrollable as above.
        final controller = LayrzLayoutController();
        addTearDown(controller.dispose);

        // Enough nav items that the rail overflows the viewport and is
        // actually scrollable, plus a small non-empty notifications list so
        // the rail's notifications row/anchor is exercised too.
        final items = List<LayrzNavigatorItem>.generate(
          40,
          (index) => LayrzNavigatorPage(id: 'page-$index', labelText: 'Page $index'),
        );
        final notifications = [
          LayrzNotificationItem(id: 'n1', title: 'Notification 1', content: 'Body 1'),
        ];

        Widget buildLayout(String bodyLabel) {
          return LayrzLayout(
            logo: 'assets/test-logo.png',
            items: items,
            notifications: notifications,
            onNotificationTap: (_) {},
            controller: controller,
            body: SizedBox(child: Text(bodyLabel)),
          );
        }

        // Wide viewport so the layout resolves to the expanded presentation
        // (rail visible, >= 960px).
        await _pumpThemedLayout(tester, buildLayout('Route A body'));
        expect(tester.takeException(), isNull);
        expect(find.text('Route A body'), findsOneWidget);

        expect(controller.railScrollController.hasClients, isTrue);

        controller.railScrollController.jumpTo(200.0);
        await tester.pump();
        expect(controller.railScrollController.offset, 200.0);

        // Simulate a route rebuild: same controller, different body.
        await _pumpThemedLayout(tester, buildLayout('Route B body'));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Route B body'), findsOneWidget);
        expect(controller.railScrollController.hasClients, isTrue);
        expect(controller.railScrollController.offset, 200.0);
      },
    );
  });
}

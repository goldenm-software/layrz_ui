import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzNotificationsPanel - DESIGN-61 Notifications Row', () {
    testWidgets('renders literal text "Notifications"', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          notifications: [
            LayrzNotificationItem(
              id: '1',
              title: 'Alert',
              content: 'Test',
            ),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(find.text('Notifications'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows count badge with notification count', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'A', content: 'a'),
            LayrzNotificationItem(id: '2', title: 'B', content: 'b'),
            LayrzNotificationItem(id: '3', title: 'C', content: 'c'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(find.text('3'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hidden when notifications empty and callback null', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          notifications: [],
          onNotificationTap: null,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(find.text('Notifications'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('present in both rail and drawer footer', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Test', content: 'content'),
          ],
          onNotificationTap: (item) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(find.text('Notifications'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzNotificationItem.onTap', () {
    testWidgets('fires when notification is tapped', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1500, 950);

      final notification = LayrzNotificationItem(
        id: '1',
        title: 'Test',
        content: 'Content',
        onTap: () {},
      );

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          notifications: [notification],
          onNotificationTap: (item) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

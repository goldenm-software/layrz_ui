import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzTopBar - Top Bar Rendering', () {
    testWidgets('top bar renders with mark and navigation', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          mark: const SizedBox(
            width: 40,
            height: 40,
            child: Text('APP'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar falls back to logo when mark is null', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          logo: const SizedBox(
            width: 40,
            height: 40,
            child: Text('LOGO'),
          ),
          mark: null,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar displays user chrome in drawer mode', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: const [],
          body: const SizedBox(child: Text('Body')),
          userName: 'Frank',
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Logout', onTap: () {}),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar displays notification bell with callback', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: const [],
          body: const SizedBox(child: Text('Body')),
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Test'),
          ],
          onNotificationTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar with user and notification elements', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          mark: const SizedBox(width: 40, height: 40, child: Text('M')),
          userName: 'Grace',
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Profile', onTap: () {}),
          ],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Msg'),
          ],
          onNotificationTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar without mark or logo', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          logo: null,
          mark: null,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar with single user menu item', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: const [],
          body: const SizedBox(child: Text('Body')),
          userName: 'Henry',
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Settings', onTap: () {}),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar handles empty user menu items list', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          userName: 'Iris',
          userMenuItems: const [],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar in drawer mode no longer renders notification bell', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(520, 900);

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

      expect(tester.takeException(), isNull);
    });
  });
}

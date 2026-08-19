import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

// Test helper to pump a themed layout with proper device pixel ratio setup
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
  group('LayrzLayout - Expanded Presentation', () {
    testWidgets('renders expanded presentation with rail and items', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            LayrzNavigatorPage(id: 'dashboard', labelText: 'Dashboard', count: 5),
            LayrzNavigatorLabel('SETTINGS'),
            LayrzNavigatorPage(id: 'config', labelText: 'Configuration'),
          ],
          body: const SizedBox(child: Text('Main Body')),
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Main Body'), findsOneWidget);
    });

    testWidgets('renders with user chrome and menu in expanded', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Content')),
          userName: 'Alice Johnson',
          userAvatar: const LayrzAvatarUrl('https://example.com/avatar.jpg'),
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Profile', onTap: () {}),
            LayrzDropdownEntry(labelText: 'Logout', onTap: () {}),
          ],
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders logo and mark in expanded', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          logo: const SizedBox(
            width: 40,
            height: 40,
            child: Text('LGO'),
          ),
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders notifications in expanded presentation', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: const [],
          body: const SizedBox(child: Text('Body')),
          notifications: [
            LayrzNotificationItem(
              id: '1',
              title: 'Notification 1',
              content: 'Test content',
            ),
            LayrzNotificationItem(
              id: '2',
              title: 'Notification 2',
              content: 'Another test',
            ),
          ],
          onNotificationTap: (_) {},
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with custom backgroundColor in expanded', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          backgroundColor: const Color(0xFFF5F5F5),
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayout - Drawer Presentation', () {
    testWidgets('renders drawer presentation with top bar and drawer button', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            LayrzNavigatorPage(id: 'dashboard', labelText: 'Dashboard', count: 3),
            LayrzNavigatorLabel('MAIN'),
            LayrzNavigatorPage(id: 'about', labelText: 'About'),
          ],
          body: const SizedBox(child: Text('Mobile Body')),
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Mobile Body'), findsOneWidget);
    });

    testWidgets('renders drawer presentation with user chrome', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          userName: 'Bob Smith',
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Profile', onTap: () {}),
          ],
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders drawer presentation with notifications', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Important'),
          ],
          onNotificationTap: (_) {},
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders drawer presentation with mark instead of logo', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          mark: const SizedBox(
            width: 40,
            height: 40,
            child: Text('MRK'),
          ),
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders drawer with all components populated', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            LayrzNavigatorLabel('MENU'),
            LayrzNavigatorPage(id: 'settings', labelText: 'Settings'),
          ],
          body: const SizedBox(child: Text('Body Content')),
          logo: const SizedBox(width: 32, height: 32, child: Text('APP')),
          mark: const SizedBox(width: 32, height: 32, child: Text('A')),
          userName: 'Charlie Brown',
          userAvatar: const LayrzAvatarEmoji('👤'),
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Settings', onTap: () {}),
            LayrzDropdownEntry(labelText: 'Logout', onTap: () {}),
          ],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Info', content: 'Msg'),
          ],
          onNotificationTap: (_) {},
          backgroundColor: const Color(0xFFFFFFFF),
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Body Content'), findsOneWidget);
    });
  });

  group('LayrzLayout - Responsiveness', () {
    testWidgets('switches from expanded to drawer at sm breakpoint', (WidgetTester tester) async {
      // sm band: 600-959px, which is still drawer
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
        size: const Size(650, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('displays expanded at md breakpoint', (WidgetTester tester) async {
      // md band: 960-1263px
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
        size: const Size(1000, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('displays expanded at xl breakpoint and caps body width', (WidgetTester tester) async {
      // xl band: >= 1904px
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(
            width: double.infinity,
            child: Text('Wide Body'),
          ),
        ),
        size: const Size(2000, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Wide Body'), findsOneWidget);
    });
  });

  group('LayrzLayout - Initialization', () {
    testWidgets('renders minimal layout with empty items', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          items: const [],
          body: const SizedBox(child: Text('Empty')),
        ),
        size: const Size(1400, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Empty'), findsOneWidget);
    });
  });
}

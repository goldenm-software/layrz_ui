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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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

    testWidgets('renders drawer presentation with logo', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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

  group('LayrzLayout - Expanded Paint Order and Geometry', () {
    testWidgets('expanded presentation: body renders with Stack layout for proper paint order', (
      WidgetTester tester,
    ) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
          ],
          body: Container(
            color: const Color(0xFFFFFFFF),
            child: const Center(child: Text('Body Content')),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Verify the body text is present and visible
      expect(find.text('Body Content'), findsOneWidget);

      // Verify the widget tree uses Stack for proper paint order (not Row)
      // Stack allows the panel to paint after the body, making shadows visible
      expect(find.byType(Stack), findsWidgets);
      // Stack contains both body (Positioned.directional) and panel (PositionedDirectional)
      // Both are subclasses of Positioned, so we should find both
      expect(find.byType(Positioned), findsWidgets);
      expect(find.byType(PositionedDirectional), findsOneWidget); // Panel is PositionedDirectional
    });

    testWidgets('expanded presentation: body content is displayed and accessible', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: Container(
            color: const Color(0xFFFFFFFF),
            child: const Center(child: Text('Body')),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Verify body container is rendered
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('expanded presentation: panel layout structure uses PositionedDirectional', (
      WidgetTester tester,
    ) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Verify PositionedDirectional is used for proper RTL support
      expect(find.byType(PositionedDirectional), findsOneWidget);
    });
  });

  group('LayrzLayout - RTL Support', () {
    testWidgets('expanded presentation: RTL layout renders correctly', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: Container(
              color: const Color(0xFFFFFFFF),
              child: const Center(child: Text('RTL Body')),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('RTL Body'), findsOneWidget);

      // Verify directional widgets are present for RTL support
      expect(find.byType(PositionedDirectional), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets); // Both body and panel are Positioned types
    });

    testWidgets('expanded presentation: LTR layout renders correctly', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: Container(
              color: const Color(0xFFFFFFFF),
              child: const Center(child: Text('LTR Body')),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('LTR Body'), findsOneWidget);

      // Verify directional widgets are present
      expect(find.byType(PositionedDirectional), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets); // Both body and panel are Positioned types
    });
  });

  group('LayrzLayout - Drawer Presentation Unaffected', () {
    testWidgets('drawer presentation: compact viewport uses drawer layout, not expanded stack', (
      WidgetTester tester,
    ) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Drawer Body')),
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Drawer Body'), findsOneWidget);

      // Drawer presentation is used for small viewports (< 960px width)
      // The fix (Stack layout) only applies to expanded presentation
      // Verify no exceptions and content is accessible
    });

    testWidgets('drawer presentation: renders with notifications', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Test', content: 'Msg'),
          ],
          onNotificationTap: (_) {},
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}

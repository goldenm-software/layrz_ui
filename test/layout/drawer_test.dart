import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzDrawer - Drawer Presentation Details', () {
    testWidgets('drawer presentation renders with minimal navigation', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('drawer presentation with complex navigation hierarchy', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorLabel('PRIMARY'),
            LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            LayrzNavigatorPage(id: 'dashboard', labelText: 'Dashboard', count: 5),
            LayrzNavigatorLabel('SECONDARY'),
            LayrzNavigatorPage(id: 'reports', labelText: 'Reports', count: 2),
            LayrzNavigatorPage(id: 'analytics', labelText: 'Analytics'),
            LayrzNavigatorLabel('ACCOUNT'),
            LayrzNavigatorPage(id: 'settings', labelText: 'Settings'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with user avatar base64', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          userName: 'Elizabeth Montgomery',
          userAvatar: const LayrzAvatarBase64(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with initials avatar (no name)', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          body: const SizedBox(child: Text('Body')),
          userName: 'Margaret Ross',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with emoji avatar', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          userName: 'David',
          userAvatar: const LayrzAvatarEmoji('😀'),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with notifications disabled', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          notifications: const [],
          onNotificationTap: null,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with notification callback set', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          body: const SizedBox(child: Text('Body')),
          notifications: const [],
          onNotificationTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation at xs band boundary', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(599, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with custom background color', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          backgroundColor: const Color(0xFFEEEEEE),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer presentation with logo constrained to 80% width and 40px height', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(520, 900);

      // Valid 1x1 PNG as data URL for testing
      const String testLogoDataUrl =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

      await pumpThemedApp(
        tester,
        LayrzLayout(
          items: [],
          logo: testLogoDataUrl,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      final menuButton = find.byType(GestureDetector).first;
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify the rendered size of the drawer logo
      // The image is constrained by LayrzImage(width: 208, height: 40, fit: BoxFit.contain)
      // At drawer presentation, both top bar and drawer are visible, so we check the drawer logo
      final imageFinder = find.byType(LayrzImage);
      expect(imageFinder, findsWidgets);

      // The drawer logo should be the one with width <= 208.0 (80% of drawer width 260.0)
      // Measure the rendered sizes
      bool foundDrawerLogo = false;
      final imageCount = imageFinder.evaluate().length;
      for (int i = 0; i < imageCount; i++) {
        final size = tester.getSize(imageFinder.at(i));
        if (size.width <= 208.0 && size.height <= 40.0) {
          foundDrawerLogo = true;
          break;
        }
      }
      expect(foundDrawerLogo, true, reason: 'Drawer logo with size <= 208x40 constraint not found');

      expect(tester.takeException(), isNull);
    });

    testWidgets('drawer closes when LayrzNavigatorPage item is tapped from unfiltered list', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      bool homeTapCalled = false;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(
              id: 'home',
              labelText: 'Home',
              onTap: () => homeTapCalled = true,
            ),
            LayrzNavigatorPage(
              id: 'dashboard',
              labelText: 'Dashboard',
              onTap: () {},
            ),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Open the drawer
      final menuButton = find.byType(GestureDetector).first;
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be visible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      // Tap the Home item
      final homeItem = find.text('Home');
      await tester.tap(homeItem);
      await tester.pumpAndSettle();

      // Assert the item's onTap was called
      expect(homeTapCalled, true, reason: 'LayrzNavigatorPage.onTap was not called');

      // Assert the drawer is closed (drawer content should be gone)
      expect(find.text('Home'), findsNothing, reason: 'Drawer did not close after tapping LayrzNavigatorPage');
    });

    testWidgets('drawer stays open when LayrzNavigatorLabel is tapped', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorLabel('PRIMARY'),
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Open the drawer
      final menuButton = find.byType(GestureDetector).first;
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be visible
      expect(find.text('PRIMARY'), findsOneWidget);

      // Tap the PRIMARY label (not a page, so drawer should stay open)
      final label = find.text('PRIMARY');
      await tester.tap(label);
      await tester.pumpAndSettle();

      // Drawer should still be open
      expect(find.text('PRIMARY'), findsOneWidget, reason: 'Drawer closed when tapping LayrzNavigatorLabel');
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('drawer closes when LayrzNavigatorPage item is tapped from search-filtered list', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      bool reportsTapCalled = false;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            LayrzNavigatorPage(
              id: 'reports',
              labelText: 'Reports',
              onTap: () => reportsTapCalled = true,
            ),
            LayrzNavigatorPage(id: 'analytics', labelText: 'Analytics'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Open the drawer
      final menuButton = find.byType(GestureDetector).first;
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // All items visible
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);

      // Type in search field to filter results
      final searchField = find.byType(LayrzTextInput);
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Rep');
      await tester.pumpAndSettle();

      // Only Reports should be visible
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Analytics'), findsNothing);

      // Tap the Reports item (from filtered list)
      final reportsItem = find.text('Reports');
      await tester.tap(reportsItem);
      await tester.pumpAndSettle();

      // Assert the item's onTap was called
      expect(reportsTapCalled, true, reason: 'LayrzNavigatorPage.onTap was not called from filtered list');

      // Assert the drawer is closed
      expect(find.text('Reports'), findsNothing, reason: 'Drawer did not close after tapping LayrzNavigatorPage from filtered list');
    });

    testWidgets('avatar removed from top bar but retained in drawer', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(500, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: const SizedBox(child: Text('Body')),
          userName: 'Test User',
          userAvatar: const LayrzAvatarEmoji('👤'),
          userMenuItems: [
            LayrzDropdownEntry(labelText: 'Logout', onTap: () {}),
          ],
        ),
      );

      // In drawer presentation, top bar should NOT contain LayrzAvatar
      expect(find.byType(LayrzAvatar), findsNothing, reason: 'LayrzAvatar found in top bar (should only be in drawer)');

      // Open the drawer
      final menuButton = find.byType(GestureDetector).first;
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should contain avatar (LayrzLayoutUserChrome is private but LayrzAvatar is exported)
      expect(find.byType(LayrzAvatar), findsWidgets, reason: 'LayrzAvatar not found in drawer');
    });
  });
}

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

      // Verify the logo has the correct constraint parameters
      // The image is constrained by LayrzImage(width: 208, height: 40, fit: BoxFit.contain)
      // At drawer presentation, both top bar and drawer are visible, so we check the drawer logo
      final imageFinder = find.byType(LayrzImage);
      expect(imageFinder, findsWidgets);

      // The drawer logo should be one of the rendered LayrzImage widgets
      // Get all LayrzImage widgets and verify at least one has the drawer constraint
      bool foundDrawerLogo = false;
      for (final finder in imageFinder.evaluate()) {
        final widget = finder.widget as LayrzImage;
        if (widget.width == 208.0 && widget.height == 40.0) {
          foundDrawerLogo = true;
          break;
        }
      }
      expect(foundDrawerLogo, true, reason: 'Drawer logo with 208x40 constraint not found');

      expect(tester.takeException(), isNull);
    });
  });
}

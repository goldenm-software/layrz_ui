import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzTopBar - Top Bar Rendering', () {
    testWidgets('top bar renders with logo and navigation', (WidgetTester tester) async {
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
          logo: 'assets/test-logo.png',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('top bar renders with logo string', (WidgetTester tester) async {
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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

    testWidgets('top bar with logo', (WidgetTester tester) async {
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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
          logo: 'assets/test-logo.png',
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

    group('Logo constraint', () {
      testWidgets('top bar logo respects width and height constraints', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(500, 900);

        // Valid 1x1 PNG as data URL for testing
        const String testLogoDataUrl =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

        await pumpThemedApp(
          tester,
          LayrzLayout(
            items: const [],
            body: const SizedBox(child: Text('Body')),
            logo: testLogoDataUrl,
          ),
        );

        // Verify the logo has the correct constraint parameters
        // The image is constrained by LayrzImage(width: 200, height: 40, fit: BoxFit.contain)
        final imageFinder = find.byType(LayrzImage);
        expect(imageFinder, findsWidgets);

        final imageWidget = tester.widget<LayrzImage>(imageFinder.first);
        expect(imageWidget.width, 200.0);
        expect(imageWidget.height, 40.0);
        expect(imageWidget.fit, BoxFit.contain);

        expect(tester.takeException(), isNull);
      });
    });
  });
}

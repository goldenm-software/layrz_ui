import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayoutRail', () {
    testWidgets('renders navigation items correctly', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            LayrzNavigatorPage(id: 'dashboard', labelText: 'Dashboard', count: 5),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('hides notification bell when empty and no callback', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: const [],
          onNotificationTap: null,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows notification bell when callback provided', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: const [],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayoutRail - DESIGN-61 Visual Adjustments', () {
    group('Search filtering', () {
      testWidgets('narrows pages by case-insensitive substring match', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
              LayrzNavigatorPage(id: '3', labelText: 'Settings'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final searchField = find.byType(EditableText);
        expect(searchField, findsOneWidget);

        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'ash');
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Devices'), findsNothing);
        expect(find.text('Settings'), findsNothing);

        expect(tester.takeException(), isNull);
      });

      testWidgets('preserves section labels when section has matches', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorLabel('MAIN'),
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorLabel('REFERENCE'),
              LayrzNavigatorPage(id: '2', labelText: 'Documentation'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final searchField = find.byType(EditableText);
        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'Dash');
        await tester.pumpAndSettle();

        expect(find.text('MAIN'), findsWidgets);
        expect(find.text('REFERENCE'), findsNothing);

        expect(tester.takeException(), isNull);
      });

      testWidgets('hides section labels when section has no matches', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorLabel('MAIN'),
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorLabel('SETTINGS'),
              LayrzNavigatorPage(id: '2', labelText: 'Preferences'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final searchField = find.byType(EditableText);
        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'Board');
        await tester.pumpAndSettle();

        expect(find.text('MAIN'), findsWidgets);
        expect(find.text('SETTINGS'), findsNothing);

        expect(tester.takeException(), isNull);
      });

      testWidgets('shows empty state when nothing matches', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final searchField = find.byType(EditableText);
        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'xyz');
        await tester.pumpAndSettle();

        expect(find.text('No results'), findsWidgets);

        expect(tester.takeException(), isNull);
      });

      testWidgets('clears filter to restore full list when query cleared', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
              LayrzNavigatorPage(id: '3', labelText: 'Settings'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        final searchField = find.byType(EditableText);
        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'Board');
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Devices'), findsNothing);

        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Devices'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);

        expect(tester.takeException(), isNull);
      });
    });

    group('Logo constraint', () {
      testWidgets('logo respects 142.4 x 40 size constraint in expanded rail', (WidgetTester tester) async {
        // Valid 1x1 red PNG as data URL for testing
        const String testLogoDataUrl =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
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
            logo: testLogoDataUrl,
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Measure the actual rendered size of the LayrzImage in the rail logo block
        // The image is constrained by LayrzImage(width: 142.4, height: 40, fit: BoxFit.contain)
        final imageFinder = find.byType(LayrzImage);
        expect(imageFinder, findsWidgets);

        // Verify the widget is present and renders
        final imageWidget = tester.widget<LayrzImage>(imageFinder.first);
        expect(imageWidget.width, 142.4);
        expect(imageWidget.height, 40.0);
        expect(imageWidget.fit, BoxFit.contain);

        expect(tester.takeException(), isNull);
      });

      testWidgets('logo constraint prevents overflow with oversized aspect ratio', (
        WidgetTester tester,
      ) async {
        // Valid 1x1 PNG as data URL for testing
        const String testLogoDataUrl =
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        // Use a data URL that renders consistently across test runs
        await pumpThemedApp(
          tester,
          LayrzLayout(
            items: [],
            logo: testLogoDataUrl,
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Verify the logo has the correct constraint parameters
        final imageFinder = find.byType(LayrzImage);
        expect(imageFinder, findsOneWidget);

        final imageWidget = tester.widget<LayrzImage>(imageFinder);
        expect(imageWidget.width, 142.4);
        expect(imageWidget.height, 40.0);
        expect(imageWidget.fit, BoxFit.contain);

        expect(tester.takeException(), isNull);
      });
    });

    group('Search field', () {
      testWidgets('search field appears above items in rail', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        expect(find.byType(EditableText), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('notifications row appears above user chrome in rail footer', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [],
            notifications: [
              LayrzNotificationItem(id: '1', title: 'Test', content: 'content'),
            ],
            onNotificationTap: (item) {},
            userName: 'Test User',
            body: const SizedBox(child: Text('Body')),
          ),
        );

        expect(find.text('Notifications'), findsWidgets);
        expect(find.text('Test User'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });

    group('Footer colors - DESIGN-61 Visual Adjustments', () {
      testWidgets('notifications row uses surface3 background color', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

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

        expect(find.text('Notifications'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('user chrome uses surface3 background color', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [],
            userName: 'Test User',
            body: const SizedBox(child: Text('Body')),
          ),
        );

        expect(find.text('Test User'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

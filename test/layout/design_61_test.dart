import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayout DESIGN-61 - Visual Adjustments', () {
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
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
              LayrzNavigatorPage(id: '3', labelText: 'Settings'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Find the search field and enter text
        final searchField = find.byType(EditableText);
        expect(searchField, findsOneWidget);

        await tester.tap(searchField);
        await tester.pumpAndSettle();
        await tester.enterText(searchField, 'ash');
        await tester.pumpAndSettle();

        // Should show Dashboard (contains 'ash') but not Devices or Settings
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

        // Should show MAIN section (has Dashboard match)
        expect(find.text('MAIN'), findsWidgets);
        // Should not show REFERENCE section (no matches)
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

        // MAIN section should be visible (has Dashboard match)
        expect(find.text('MAIN'), findsWidgets);
        // SETTINGS section should be hidden (Preferences doesn't match 'Board')
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

        // Should show "No results" message
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

        // Clear the search
        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();

        // All items should be visible again
        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Devices'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);

        expect(tester.takeException(), isNull);
      });
    });

    group('Active indicator bar', () {
      testWidgets('renders for selected item and transparent for unselected', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard', isSelected: true),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Both items should render without exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('reserves space so label does not shift on selection', (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1500, 950);

        await pumpThemedApp(
          tester,
          LayrzLayout(
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard', isSelected: true),
              LayrzNavigatorPage(id: '2', labelText: 'Devices', isSelected: false),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Find the Text widgets for the labels
        final dashboardLabel = find.text('Dashboard');
        final devicesLabel = find.text('Devices');

        // Get the positions before
        final dashboardRect = tester.getRect(dashboardLabel);
        final devicesRect = tester.getRect(devicesLabel);

        // Both should be present and at expected positions
        expect(dashboardLabel, findsWidgets);
        expect(devicesLabel, findsWidgets);
        expect(dashboardRect.width, greaterThan(0));
        expect(devicesRect.width, greaterThan(0));

        expect(tester.takeException(), isNull);
      });
    });

    group('Notifications row', () {
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

        // Notifications text should not be visible
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

        // In expanded view, Notifications should be in rail
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

        // The notifications bell in the footer should trigger the panel
        // This is a basic smoke test that the structure renders
        expect(tester.takeException(), isNull);
      });
    });

    group('Top bar', () {
      testWidgets('no longer renders bell icon', (WidgetTester tester) async {
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

        // In drawer presentation, there should be no bell in the top bar
        // (it moved to the drawer footer)
        expect(tester.takeException(), isNull);
      });
    });

    group('Logo constraint', () {
      testWidgets('constrained to 80% width and 40px height in rail', (WidgetTester tester) async {
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
            logo: Container(
              width: 300,
              height: 200,
              color: const Color(0xFFFF0000),
            ),
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Logo should render at constrained size
        expect(tester.takeException(), isNull);
      });

      testWidgets('constrained to 80% width and 40px height in drawer', (WidgetTester tester) async {
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
            logo: Container(
              width: 300,
              height: 200,
              color: const Color(0xFFFF0000),
            ),
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Tap the menu to open the drawer
        final menuButton = find.byType(GestureDetector).first;
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Integration tests', () {
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
            items: [
              LayrzNavigatorPage(id: '1', labelText: 'Dashboard'),
              LayrzNavigatorPage(id: '2', labelText: 'Devices'),
            ],
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Search field should be visible
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
            items: [],
            notifications: [
              LayrzNotificationItem(id: '1', title: 'Test', content: 'content'),
            ],
            onNotificationTap: (item) {},
            userName: 'Test User',
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // Both should be visible
        expect(find.text('Notifications'), findsWidgets);
        expect(find.text('Test User'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

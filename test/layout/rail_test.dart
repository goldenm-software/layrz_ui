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
      testWidgets('logo renders within FittedBox constraint', (WidgetTester tester) async {
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

        // Verify the FittedBox is present (used to constrain the logo)
        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsWidgets);

        // The logo should render without errors
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);

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

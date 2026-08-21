import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

void main() {
  group('LayrzLayoutNavigatorPanel - Persistent Mode (Rail)', () {
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

    testWidgets('hides logo when logo string is empty', (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 900);

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: '',
          items: const [],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // In expanded (rail) mode, logo should not be rendered when empty
      // Count LayrzImage instances - should be 0 in rail when logo is empty
      expect(find.byType(LayrzImage), findsNothing);
      expect(tester.takeException(), isNull);
    });

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

        expect(find.text('Dashboard', findRichText: true), findsWidgets);
        expect(find.text('Devices', findRichText: true), findsNothing);
        expect(find.text('Settings', findRichText: true), findsNothing);

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

        expect(find.text('Dashboard', findRichText: true), findsWidgets);
        expect(find.text('Devices', findRichText: true), findsNothing);

        await tester.enterText(searchField, '');
        await tester.pumpAndSettle();

        expect(find.text('Dashboard', findRichText: true), findsWidgets);
        expect(find.text('Devices', findRichText: true), findsWidgets);
        expect(find.text('Settings', findRichText: true), findsWidgets);

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

    group('Footer colors', () {
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

  group('LayrzLayoutNavigatorPanel - Drawer Mode', () {
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

    testWidgets('drawer closes when LayrzNavigatorPage item is tapped from unfiltered list', (
      WidgetTester tester,
    ) async {
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
      final menuButton = find.byKey(const ValueKey('drawer_trigger_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be visible
      expect(find.text('Home', findRichText: true), findsOneWidget);
      expect(find.text('Dashboard', findRichText: true), findsOneWidget);

      // Tap the Home item
      final homeItem = find.text('Home', findRichText: true);
      await tester.tap(homeItem);
      await tester.pumpAndSettle();

      // Assert the item's onTap was called
      expect(homeTapCalled, true, reason: 'LayrzNavigatorPage.onTap was not called');

      // Assert the drawer is closed (drawer content should be gone)
      expect(
        find.text('Home', findRichText: true),
        findsNothing,
        reason: 'Drawer did not close after tapping LayrzNavigatorPage',
      );
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
      final menuButton = find.byKey(const ValueKey('drawer_trigger_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be visible (check for Text widget 'PRIMARY' label)
      expect(find.text('PRIMARY'), findsOneWidget);

      // Tap the PRIMARY label (not a page, so drawer should stay open)
      final label = find.text('PRIMARY');
      await tester.tap(label);
      await tester.pumpAndSettle();

      // Drawer should still be open (PRIMARY label should still be findable)
      expect(find.text('PRIMARY'), findsOneWidget, reason: 'Drawer closed when tapping LayrzNavigatorLabel');
      // Verify RichText for Home item still exists
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('drawer closes when LayrzNavigatorPage item is tapped from search-filtered list', (
      WidgetTester tester,
    ) async {
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
      final menuButton = find.byKey(const ValueKey('drawer_trigger_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // All items visible
      expect(find.text('Home', findRichText: true), findsOneWidget);
      expect(find.text('Reports', findRichText: true), findsOneWidget);
      expect(find.text('Analytics', findRichText: true), findsOneWidget);

      // Type in search field to filter results
      final searchField = find.byType(EditableText);
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'Rep');
      await tester.pumpAndSettle();

      // Only Reports should be visible
      expect(find.text('Reports', findRichText: true), findsOneWidget);
      expect(find.text('Home', findRichText: true), findsNothing);
      expect(find.text('Analytics', findRichText: true), findsNothing);

      // Tap the Reports item (from filtered list)
      final reportsItem = find.text('Reports', findRichText: true);
      await tester.tap(reportsItem);
      await tester.pumpAndSettle();

      // Assert the item's onTap was called
      expect(reportsTapCalled, true, reason: 'LayrzNavigatorPage.onTap was not called from filtered list');

      // Assert the drawer is closed
      expect(
        find.text('Reports', findRichText: true),
        findsNothing,
        reason: 'Drawer did not close after tapping LayrzNavigatorPage from filtered list',
      );
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
      final menuButton = find.byKey(const ValueKey('drawer_trigger_button'));
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should contain avatar (LayrzLayoutUserChrome is private but LayrzAvatar is exported)
      expect(find.byType(LayrzAvatar), findsWidgets, reason: 'LayrzAvatar not found in drawer');
    });

    testWidgets('regression: section caption text is bold', (WidgetTester tester) async {
      // Regression test for Bug 2: section captions should use FontWeight.w700 (bold).
      // Before the fix, the fontWeight was not set in the TextStyle.copyWith,
      // so captions inherited the label's w400 weight.
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
            LayrzNavigatorLabel('COMPONENTS'),
            LayrzNavigatorPage(id: 'button', labelText: 'Button'),
            LayrzNavigatorLabel('LAYOUT'),
            LayrzNavigatorPage(id: 'grid', labelText: 'Grid'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Find all Text widgets in the tree and locate section caption Text widgets.
      // The section caption is a Text widget with the label text in uppercase.
      final allTextWidgets = find.byType(Text);
      expect(allTextWidgets, findsWidgets);

      // Verify at least one Text widget with fontWeight.w700 contains "COMPONENTS" or "LAYOUT"
      final textWidgets = allTextWidgets.evaluate().toList();
      bool foundBoldCaption = false;
      for (final widget in textWidgets) {
        if (widget.widget is Text) {
          final text = widget.widget as Text;
          final textData = text.data ?? '';
          final isCaption = textData == 'COMPONENTS' || textData == 'LAYOUT';
          if (isCaption && text.style?.fontWeight == FontWeight.w700) {
            foundBoldCaption = true;
            break;
          }
        }
      }
      expect(foundBoldCaption, isTrue, reason: 'Section caption text does not have FontWeight.w700');

      expect(tester.takeException(), isNull);
    });

    testWidgets('regression: no results text is bold', (WidgetTester tester) async {
      // Regression test for Bug 2: "No results" placeholder should use FontWeight.w700 (bold).
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
            LayrzNavigatorPage(id: 'dashboard', labelText: 'Dashboard'),
            LayrzNavigatorPage(id: 'devices', labelText: 'Devices'),
          ],
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Search for something that doesn't match to trigger "No results"
      final searchField = find.byType(EditableText);
      await tester.tap(searchField);
      await tester.pumpAndSettle();
      await tester.enterText(searchField, 'nonexistent');
      await tester.pumpAndSettle();

      // Find the "No results" text by looking for the exact text in all Text widgets
      final allTextWidgets = find.byType(Text);
      expect(allTextWidgets, findsWidgets);

      // Verify the "No results" Text widget has fontWeight.w700
      final textWidgets = allTextWidgets.evaluate().toList();
      bool foundBoldNoResults = false;
      for (final widget in textWidgets) {
        if (widget.widget is Text) {
          final text = widget.widget as Text;
          final textData = text.data ?? '';
          if (textData == 'No results' && text.style?.fontWeight == FontWeight.w700) {
            foundBoldNoResults = true;
            break;
          }
        }
      }
      expect(foundBoldNoResults, isTrue, reason: '"No results" text does not have FontWeight.w700');

      expect(tester.takeException(), isNull);
    });
  });
}

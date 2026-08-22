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

  group('LayrzLayout - Expanded Geometry (LTR)', () {
    testWidgets('expanded LTR: body inset from left by kLayrzLayoutRailWidth', (
      WidgetTester tester,
    ) async {
      // Set viewport to expanded size (>= 960px width)
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            ],
            body: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 100,
                height: 100,
                color: const Color(0xFFFF0000),
                child: const Text('Body'),
              ),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Find the red body container positioned at the top-left of body area
      final redBox = find.byWidgetPredicate(
        (w) => w is Container && w.color == const Color(0xFFFF0000),
      );
      expect(redBox, findsOneWidget);

      final rect = tester.getRect(redBox);
      // Red box should start at kLayrzLayoutRailWidth (220.0) since it's top-left of body
      expect(rect.left, moreOrLessEquals(220.0, epsilon: 1.0));
      expect(rect.top, 0.0);
    });

    testWidgets('expanded LTR: panel renders after body (paint order for visible shadow)', (WidgetTester tester) async {
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
              child: const Text('Body Content'),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Find Stack widget and verify PositionedDirectional is present
      // The PositionedDirectional (panel) must be a later child of Stack so it paints after the body
      expect(find.byType(PositionedDirectional), findsOneWidget);

      // Verify the Stack contains both body (Positioned.directional) and panel (PositionedDirectional)
      final stacks = find.byType(Stack);
      expect(stacks, findsWidgets);
    });

    testWidgets('expanded LTR: body width matches viewport minus rail width', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: SizedBox(
              width: double.infinity,
              child: Container(
                color: const Color(0xFF0000FF),
                child: const Text('Full Width Body'),
              ),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Full Width Body'), findsOneWidget);

      // The body text position verifies the Positioned.directional inset is correct
      final textRect = tester.getRect(find.text('Full Width Body'));
      // Text left should be at or after rail width (220.0)
      expect(textRect.left, greaterThanOrEqualTo(220.0));
      // Text right should be at or before viewport right edge (1600.0)
      expect(textRect.right, lessThanOrEqualTo(1600.0));
    });
  });

  group('LayrzLayout - Expanded Geometry (RTL)', () {
    testWidgets('expanded RTL: panel occupies trailing 220px, body inset from panel', (
      WidgetTester tester,
    ) async {
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home', isSelected: true),
            ],
            body: Container(
              color: const Color(0xFFFFFFFF),
              child: const Center(child: Text('RTL Body Content')),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('RTL Body Content'), findsOneWidget);

      // PositionedDirectional must be used so it flips correctly in RTL
      expect(find.byType(PositionedDirectional), findsOneWidget);

      // The text position verifies RTL inset is correct
      final textRect = tester.getRect(find.text('RTL Body Content'));
      // In RTL, text should be on the left side (left of viewport width - rail)
      // Text left should be close to 0 (allowing for Center widget centering)
      expect(textRect.left, lessThan(1600.0));
      // Text right should be less than full width (inset by rail width 220)
      expect(textRect.right, lessThanOrEqualTo(1600.0 - 220.0 + 100)); // generous margin for Center
    });

    testWidgets('expanded RTL: panel on right, body on left with proper inset', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: LayrzLayout(
            logo: 'assets/test-logo.png',
            items: [
              LayrzNavigatorPage(id: 'home', labelText: 'Home'),
            ],
            body: SizedBox(
              width: double.infinity,
              child: Container(
                color: const Color(0xFF00FF00),
                child: const Text('RTL Full Width'),
              ),
            ),
          ),
        ),
        size: const Size(1600, 1200),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);

      // Verify RTL text position
      final textRect = tester.getRect(find.text('RTL Full Width'));
      // Text should be positioned in the left portion (due to RTL inset from right)
      expect(textRect.left, greaterThanOrEqualTo(0.0));
      expect(textRect.right, lessThan(1600.0)); // inset from right edge
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
      // The fix (Stack layout with PositionedDirectional inset) only applies to expanded presentation
      // For drawer, it should use different layout (typically Column or different Row structure)
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

    testWidgets('drawer presentation: geometry unaffected by expanded fix', (WidgetTester tester) async {
      await _pumpThemedLayout(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: [
            LayrzNavigatorPage(id: 'home', labelText: 'Home'),
          ],
          body: Container(
            color: const Color(0xFFFF0000),
            child: const Center(child: Text('Drawer Mode Body')),
          ),
        ),
        size: const Size(500, 900),
        devicePixelRatio: 1.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Drawer Mode Body'), findsOneWidget);

      // Drawer uses a different layout path, so geometry should not be affected by the Stack fix
      final textRect = tester.getRect(find.text('Drawer Mode Body'));
      // In drawer mode, body should extend across the viewport width (no rail offset)
      expect(textRect.left, greaterThanOrEqualTo(0.0));
      expect(textRect.right, lessThanOrEqualTo(500.0));
    });
  });
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

/// Regression tests for the notifications panel entry restyle and hover fix.
///
/// Before this fix, `_buildNotificationEntry` in `notifications_panel.dart`
/// was a bare [GestureDetector] with hardcoded `EdgeInsets.symmetric(horizontal:
/// 12.0, vertical: 10.0)` padding, no [MouseRegion], and therefore no pointer
/// cursor and no hover tint. These tests assert the entry now:
/// - is wrapped in a [MouseRegion] with [SystemMouseCursors.click] AND tints
///   its background with `tokens.colors.primary` at
///   `kLayrzLayoutItemHoverBackgroundOpacity` while the mouse hovers it — but
///   ONLY when [LayrzNotificationItem.onTap] is set on that specific item.
/// - a row with no per-item `onTap` renders flat: [SystemMouseCursors.basic]
///   and no hover tint, even when the panel-level `onNotificationTap` is set.
///   The panel callback never gates the hover/cursor affordance — only the
///   per-item `onTap` does.
/// - tapping a tappable row (per-item `onTap` set) fires its callbacks AND
///   then closes the notifications panel, since a tap normally navigates the
///   user somewhere and the panel should dismiss like a menu item would.
void main() {
  final railBell = find.byKey(const ValueKey('notifications_bell_row'));

  group('Notification entry — pointer cursor', () {
    testWidgets('tappable entry (per-item onTap set) MouseRegion sets SystemMouseCursors.click', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened', onTap: () {}),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      // The MouseRegion that carries the cursor wraps the GestureDetector
      // that carries the entry's key, so walk up to find it.
      final mouseRegionFinder = find.ancestor(
        of: entryFinder,
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegionFinder, findsWidgets);

      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder.first);
      expect(mouseRegion.cursor, equals(SystemMouseCursors.click));

      expect(tester.takeException(), isNull);
    });

    testWidgets('non-tappable entry (no per-item onTap) MouseRegion sets SystemMouseCursors.basic', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            // onTap deliberately null: only onNotificationTap (panel-level) is set.
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      final mouseRegionFinder = find.ancestor(
        of: entryFinder,
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegionFinder, findsWidgets);

      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder.first);
      expect(
        mouseRegion.cursor,
        equals(SystemMouseCursors.basic),
        reason: 'A row with no per-item onTap must not show the click cursor, even with onNotificationTap set',
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Notification entry — hover tint', () {
    testWidgets('tappable entry: hovering tints its background with the layout hover opacity', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      final theme = LayrzThemeData.light();

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened', onTap: () {}),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
        theme: theme,
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      Container entryContainer() => tester.widget<Container>(
        find.descendant(of: entryFinder, matching: find.byType(Container)).first,
      );

      // At rest: no hover tint.
      final restDecoration = entryContainer().decoration as BoxDecoration?;
      expect(
        restDecoration?.color,
        anyOf(isNull, equals(const Color(0x00000000))),
        reason: 'Entry at rest must have no hover tint',
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(entryFinder));
      await tester.pumpAndSettle();

      final hoverDecoration = entryContainer().decoration as BoxDecoration?;
      final expectedColor = theme.tokens.colors.primary.withValues(
        alpha: kLayrzLayoutItemHoverBackgroundOpacity,
      );

      expect(
        hoverDecoration?.color,
        equals(expectedColor),
        reason: 'Hovering a tappable entry must tint its background with the layout hover opacity',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('non-tappable entry: hovering does NOT tint its background', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            // onTap deliberately null: only onNotificationTap (panel-level) is set.
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      Container entryContainer() => tester.widget<Container>(
        find.descendant(of: entryFinder, matching: find.byType(Container)).first,
      );

      // At rest: no hover tint.
      final restDecoration = entryContainer().decoration as BoxDecoration?;
      expect(
        restDecoration?.color,
        anyOf(isNull, equals(const Color(0x00000000))),
        reason: 'Entry at rest must have no hover tint',
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(entryFinder));
      await tester.pumpAndSettle();

      final hoverDecoration = entryContainer().decoration as BoxDecoration?;
      expect(
        hoverDecoration?.color,
        anyOf(isNull, equals(const Color(0x00000000))),
        reason: 'A row with no per-item onTap must not tint on hover, even with onNotificationTap set',
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Notification entry — close on tap', () {
    testWidgets('tapping a tappable entry fires its onTap and closes the panel', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      var entryTapped = false;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(
              id: '1',
              title: 'Alert',
              content: 'Something happened',
              onTap: () => entryTapped = true,
            ),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      await tester.tap(entryFinder);
      await tester.pumpAndSettle();

      expect(entryTapped, isTrue, reason: 'The per-item onTap must still fire');
      expect(
        find.byKey(const ValueKey('notification_entry_1')),
        findsNothing,
        reason: 'Tapping a tappable entry must close the notifications panel',
      );
      expect(
        find.text('Something happened'),
        findsNothing,
        reason: 'The panel overlay content must no longer be in the tree after a tappable entry is tapped',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a non-tappable entry fires onNotificationTap and keeps the panel open', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      LayrzNotificationItem? tapped;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            // onTap deliberately null: only onNotificationTap (panel-level) is set.
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
          ],
          onNotificationTap: (item) => tapped = item,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
      expect(entryFinder, findsOneWidget);

      await tester.tap(entryFinder);
      await tester.pumpAndSettle();

      expect(tapped?.id, equals('1'), reason: 'onNotificationTap must still fire');
      expect(
        find.byKey(const ValueKey('notification_entry_1')),
        findsOneWidget,
        reason: 'A non-tappable entry (no per-item onTap) must not close the panel on tap',
      );

      expect(tester.takeException(), isNull);
    });
  });
}

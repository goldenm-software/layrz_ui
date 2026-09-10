import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

/// Regression tests for DESIGN-214: tapping the notification bell must open
/// the notifications panel.
///
/// Before this fix, the rail's notification row (in `navigator_panel.dart`)
/// was a static, non-interactive [Container] with no [GestureDetector] and no
/// [RawMenuAnchor], and the top bar (`top_bar.dart`) never rendered a bell at
/// all — so the bell was decorative in both presentations. These tests assert
/// the panel actually opens on tap, item taps fire [LayrzLayout.onNotificationTap],
/// and the panel opens even when the notification list is empty (rather than
/// remaining an inert, data-gated no-op).
void main() {
  final railBell = find.byKey(const ValueKey('notifications_bell_row'));
  final topBarBell = find.byKey(const ValueKey('notifications_bell_button'));

  group('LayrzLayout notification bell — rail presentation (wide viewport)', () {
    testWidgets('tapping the bell opens the notifications panel', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      // Panel is closed initially: entry content is not in the tree.
      expect(find.text('Something happened'), findsNothing);

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      // Panel is now open: the notification entry content is rendered.
      expect(find.text('Something happened'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the bell again closes the notifications panel', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();
      expect(find.text('Something happened'), findsOneWidget);

      await tester.tap(railBell);
      await tester.pumpAndSettle();
      expect(find.text('Something happened'), findsNothing);
    });

    testWidgets('tapping a notification entry fires onNotificationTap with that item', (tester) async {
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
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Server down'),
            LayrzNotificationItem(id: '2', title: 'Info', content: 'Backup complete'),
          ],
          onNotificationTap: (item) => tapped = item,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notification_entry_2')));
      await tester.pumpAndSettle();

      expect(tapped?.id, equals('2'));
      expect(tapped?.title, equals('Info'));
    });

    testWidgets('notification entry onTap callback fires alongside onNotificationTap', (tester) async {
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
              content: 'Server down',
              onTap: () => entryTapped = true,
            ),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notification_entry_1')));
      await tester.pumpAndSettle();

      expect(entryTapped, isTrue);
    });

    testWidgets('opens to an empty state when notifications list is empty but callback is set', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

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

      expect(find.text('No notifications'), findsNothing);

      await tester.tap(railBell);
      await tester.pumpAndSettle();

      // The bell is not a no-op when the list is empty: it still opens and
      // shows an empty-state message rather than doing nothing.
      expect(find.text('No notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayout notification bell — drawer presentation (narrow viewport)', () {
    testWidgets('tapping the top bar bell opens the notifications panel', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Drawer notification'),
          ],
          onNotificationTap: (_) {},
          body: const SizedBox(child: Text('Body')),
        ),
      );

      expect(find.text('Drawer notification'), findsNothing);
      expect(topBarBell, findsOneWidget);

      await tester.tap(topBarBell);
      await tester.pumpAndSettle();

      expect(find.text('Drawer notification'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a notification entry in the top bar panel fires onNotificationTap', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;

      LayrzNotificationItem? tapped;

      await pumpThemedApp(
        tester,
        LayrzLayout(
          logo: 'assets/test-logo.png',
          items: const [],
          notifications: [
            LayrzNotificationItem(id: '1', title: 'Alert', content: 'Drawer notification'),
          ],
          onNotificationTap: (item) => tapped = item,
          body: const SizedBox(child: Text('Body')),
        ),
      );

      await tester.tap(topBarBell);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notification_entry_1')));
      await tester.pumpAndSettle();

      expect(tapped?.id, equals('1'));
    });

    testWidgets('top bar does not render a bell when notifications empty and no callback', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;

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

      expect(topBarBell, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens to an empty state in the top bar when notifications list is empty', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;

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

      await tester.tap(topBarBell);
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LayrzLayout notification bell — accessibility', () {
    testWidgets('rail bell row is tappable and exposes semantics', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1500, 950);
      tester.view.devicePixelRatio = 1.0;

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: const [],
            notifications: [
              LayrzNotificationItem(id: '1', title: 'Alert', content: 'Test'),
            ],
            onNotificationTap: (_) {},
            body: const SizedBox(child: Text('Body')),
          ),
        );

        // The row merges its label and count badge into a single semantics
        // node ("Notifications\n1") and must expose a tap action.
        expect(
          tester.getSemantics(railBell),
          matchesSemantics(
            label: 'Notifications\n1',
            hasTapAction: true,
          ),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('drawer bell icon button exposes tappable semantics', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;

      final handle = tester.ensureSemantics();
      try {
        await pumpThemedApp(
          tester,
          LayrzLayout(
            logo: 'assets/test-logo.png',
            items: const [],
            notifications: [
              LayrzNotificationItem(id: '1', title: 'Alert', content: 'Test'),
            ],
            onNotificationTap: (_) {},
            body: const SizedBox(child: Text('Body')),
          ),
        );

        expect(topBarBell, findsOneWidget);

        // The icon button exposes a real, tappable (and focusable) semantics
        // node — not just visual pixels with no accessible action.
        expect(
          tester.getSemantics(topBarBell),
          matchesSemantics(
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );

        await tester.tap(topBarBell);
        await tester.pumpAndSettle();

        expect(find.text('Test'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });
}

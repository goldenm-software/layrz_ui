import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed_app.dart';

/// Regression tests for the notifications panel container's elevation and
/// corner clipping.
///
/// Before this fix, the panel's rounded [Container] had a hardcoded, non-token
/// shadow and no clip, so the bottom entry's divider (and hover tint) painted
/// past the panel's rounded bottom corners. The fix reuses the same
/// floating-panel elevation token [LayrzDropdownMenu] uses
/// (`tokens.shadow.elevation3`) on an outer [Container] with no clip, and adds
/// an inner [ClipRRect] (same radius) around the scrollable entry list so
/// content is clipped to the rounded corners without clipping the shadow
/// itself.
void main() {
  final railBell = find.byKey(const ValueKey('notifications_bell_row'));

  testWidgets('panel container has a non-empty boxShadow matching tokens.shadow.elevation3', (tester) async {
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
          LayrzNotificationItem(id: '1', title: 'Alert', content: 'Something happened'),
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

    // The panel's ClipRRect is identified as the one that actually wraps this
    // notification entry (the layout chrome contains an unrelated ClipRRect
    // elsewhere, e.g. the drawer scaffold, so byType alone is ambiguous).
    final clipRRectFinder = find.ancestor(
      of: entryFinder,
      matching: find.byType(ClipRRect),
    );
    expect(clipRRectFinder, findsOneWidget);

    // The panel container is the Container ancestor of that ClipRRect.
    final panelContainerFinder = find.ancestor(
      of: clipRRectFinder,
      matching: find.byType(Container),
    );
    expect(panelContainerFinder, findsWidgets);

    final panelContainer = tester.widget<Container>(panelContainerFinder.first);
    final decoration = panelContainer.decoration as BoxDecoration?;

    expect(
      decoration?.boxShadow,
      isNotNull,
      reason: 'The panel container must have a boxShadow to read as a floating overlay',
    );
    expect(
      decoration!.boxShadow,
      isNotEmpty,
      reason: 'The panel container boxShadow must not be empty',
    );
    expect(
      decoration.boxShadow,
      equals(theme.tokens.shadow.elevation3),
      reason: 'The panel must reuse the same elevation token as other floating panels (e.g. LayrzDropdownMenu)',
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('panel container clips its content to the rounded corners via an inner ClipRRect', (tester) async {
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
          LayrzNotificationItem(id: '2', title: 'Info', content: 'Second notification'),
        ],
        onNotificationTap: (_) {},
        body: const SizedBox(child: Text('Body')),
      ),
    );

    await tester.tap(railBell);
    await tester.pumpAndSettle();

    final entryFinder = find.byKey(const ValueKey('notification_entry_1'));
    expect(entryFinder, findsOneWidget);

    // The ClipRRect that actually wraps the notification entry — not the
    // shadow-carrying outer Container — is what clips the entry list (and its
    // dividers/hover tint) to the panel's rounded corners. Identified by
    // ancestry to the entry rather than byType alone, since the layout chrome
    // contains an unrelated ClipRRect elsewhere (the drawer scaffold).
    final clipRRectFinder = find.ancestor(
      of: entryFinder,
      matching: find.byType(ClipRRect),
    );
    expect(clipRRectFinder, findsOneWidget);

    final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
    expect(clipRRect.borderRadius, equals(BorderRadius.circular(8.0)));

    expect(tester.takeException(), isNull);
  });
}

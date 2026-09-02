import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// Pumps [header] with generous headroom above it instead of [pumpThemed]'s centering.
///
/// [pumpThemed] centers its child inside an [Overlay], but [LayrzCalendarHeader]'s
/// outer [Column] defaults to [MainAxisSize.max], so it fills the Overlay's full
/// (loose) height and its top row lands at the very top of the viewport with no
/// room above it — any tooltip positioned `top` would then have nowhere to go and
/// correctly flip to `bottom` per [LayrzTooltip]'s overflow-flip behaviour. Padding
/// the header away from the top edge gives the nav buttons' tooltip real room to
/// render above them, which is what these tests need to observe.
/// Pumps [header] inside a bounded, width-stretching parent matching
/// [LayrzCalendar]'s real integration contract (`LayrzCard` > `Padding` >
/// `Column(crossAxisAlignment: stretch)`), at the given [width].
///
/// [pumpThemed]'s `Center` wrapper gives its child loose, effectively
/// shrink-wrapped width — under those constraints a `Row`'s [Spacer] widens
/// to whatever its siblings leave unused, so geometry assertions built on
/// [pumpThemed] cannot tell a `Today` button pinned to the trailing edge
/// apart from one that merely sits somewhere right of the nav buttons. That
/// gap is what let the header regress to the "Today floating mid-row" bug
/// this file now guards against: the row's own render size can be the full
/// bounded width while [Spacer] still stops short of consuming all of it
/// (see the RenderFlex trap in this file's trailing-edge test). Only a
/// harness with a genuinely fixed, bounded width exercises that failure
/// mode.
Future<void> pumpHeaderAtWidth(WidgetTester tester, Widget header, double width) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpHeaderWithHeadroom(WidgetTester tester, Widget header) async {
  await tester.pumpWidget(
    Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        LayrzUiL10nDelegate(),
      ],
      child: LayrzTheme(
        data: LayrzThemeData.light(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(top: 400),
                child: header,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('LayrzCalendarHeader', () {
    testWidgets('previous and next buttons are configured with a top tooltip position', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzCalendarHeader(
          focusedDate: DateTime(2026, 8, 28),
          mode: LayrzCalendarMode.month,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onModeChanged: (_) {},
        ),
      );

      final navButtons = tester
          .widgetList<LayrzButton>(find.byType(LayrzButton))
          .where((button) => button.style == LayrzButtonStyle.textFab)
          .toList();

      expect(
        navButtons,
        hasLength(2),
        reason: 'The header should render exactly the previous and next Fab nav buttons.',
      );
      for (final button in navButtons) {
        expect(
          button.tooltipPosition,
          LayrzPreferredSide.top,
          reason:
              'The nav buttons sit directly above the mode switcher row, so their tooltip must render '
              'above the button rather than the default bottom, which would obscure the switcher.',
        );
      }
    });

    testWidgets('the previous button tooltip renders above the button, not over the mode switcher', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpHeaderWithHeadroom(
        tester,
        LayrzCalendarHeader(
          focusedDate: DateTime(2026, 8, 28),
          mode: LayrzCalendarMode.month,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onModeChanged: (_) {},
        ),
      );

      final previousButtonFinder = find.byWidgetPredicate(
        (widget) => widget is LayrzButton && widget.style == LayrzButtonStyle.textFab,
      );
      final previousButton = previousButtonFinder.first;
      final buttonRect = tester.getRect(previousButton);

      await tester.longPress(previousButton);
      await tester.pumpAndSettle();

      final tooltipRect = tester.getRect(find.text('Previous month').last);

      expect(
        tooltipRect.bottom,
        lessThanOrEqualTo(buttonRect.top),
        reason:
            'With tooltipPosition: LayrzPreferredSide.top, the tooltip must render above the button, '
            'never over the mode switcher row beneath it.',
      );
    });

    /// Regression coverage for a bug where `Today` floated mid-row instead
    /// of sitting flush against the header's trailing edge.
    ///
    /// Root cause: the period label's `Flexible` and the trailing `Spacer`
    /// were siblings in the same `Row`, both with `flex: 1`. `RenderFlex`
    /// divides its free space evenly across every flex child regardless of
    /// how much a loose-fit child actually consumes, so the label's
    /// `Flexible` was silently allotted (and stranded) half of the row's
    /// free space whenever the ellipsized text didn't need all of it —
    /// leaving `Spacer` with only the other half and `Today` short of the
    /// trailing edge by the amount the label didn't use. Fixed by making the
    /// `[back] label [next]` trio a single `Expanded` (tight-fit) group and
    /// removing `Spacer` entirely — `Expanded` forces the group to consume
    /// every pixel the row has left after `Today`'s own intrinsic width, so
    /// `Today` is flush against the trailing edge by construction rather
    /// than by how much free space happens to be left over.
    ///
    /// The prior version of this test only asserted `nextRect.right <
    /// todayRect.left`, which is satisfied by a 1px gap and did not catch
    /// this: it also ran under `pumpThemed`, whose `Center` wrapper gives
    /// the header shrink-wrapped (loose) width, so `Spacer`'s misallocated
    /// half was never visible against a row that never had real width to
    /// misallocate in the first place. This version pins the header to a
    /// bounded, stretched width via `pumpHeaderAtWidth` — matching
    /// `LayrzCalendar`'s real `Column(crossAxisAlignment: stretch)`
    /// contract — and asserts `Today`'s right edge lands within a tight
    /// tolerance of the header's own right edge, at both a wide and a
    /// compact viewport.
    for (final width in [1024.0, 380.0]) {
      testWidgets('Today sits flush against the trailing edge at width $width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpHeaderAtWidth(
          tester,
          LayrzCalendarHeader(
            focusedDate: DateTime(2026, 8, 28),
            mode: LayrzCalendarMode.month,
            onPrevious: () {},
            onNext: () {},
            onToday: () {},
            onModeChanged: (_) {},
          ),
          width,
        );

        expect(tester.takeException(), isNull, reason: 'The header must not overflow at width $width.');

        final headerRect = tester.getRect(find.byType(LayrzCalendarHeader));
        final buttons = tester.widgetList<LayrzButton>(find.byType(LayrzButton)).toList();
        final previousRect = tester.getRect(find.byWidgetPredicate((w) => w == buttons[0]));
        final nextRect = tester.getRect(find.byWidgetPredicate((w) => w == buttons[1]));
        final todayRect = tester.getRect(find.byWidgetPredicate((w) => w == buttons[2]));
        final labelRect = tester.getRect(find.text('August 2026'));

        expect(previousRect.right, lessThanOrEqualTo(labelRect.left));
        expect(labelRect.right, lessThanOrEqualTo(nextRect.left));
        expect(nextRect.right, lessThanOrEqualTo(todayRect.left));

        // The strong assertion: Today's right edge must be within a tight
        // tolerance of the header's own right edge -- not merely somewhere
        // right of [next], which a floating-mid-row Today also satisfies.
        expect(
          headerRect.right - todayRect.right,
          closeTo(0, 1.0),
          reason:
              'Today must sit flush against the header\'s trailing edge. A gap here means the nav '
              'group is stealing flex space that should belong to Today (the exact regression this '
              'test guards against), not merely that Today sits somewhere right of [next].',
        );
      });
    }
  });
}

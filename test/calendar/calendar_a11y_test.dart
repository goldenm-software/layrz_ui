import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendar Accessibility', () {
    testWidgets('a day cell with no events announces its date only', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: DateTime(2026, 8, 30),
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: const [],
            ),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
        expect(semantics.label, 'August 30');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a day cell announces today, disabled state, and event count as one merged label', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        final now = DateTime.now();

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: now,
              isToday: true,
              isOutsideMonth: false,
              isDisabled: true,
              entries: [
                LayrzCalendarEntry(title: 'A', start: now, end: now),
                LayrzCalendarEntry(title: 'B', start: now, end: now),
              ],
            ),
          ),
        );

        // A single merged Semantics node carries date, today, disabled and
        // event count together -- never a separate unlabeled child node for
        // the event chips (the inner ExcludeSemantics on the visual content
        // is what forces this merge). The date number stays merged into this
        // same node here specifically because no `onDateNumberTap` is passed
        // above -- it is inert in this test, not because the date number is
        // architecturally excluded; see calendar_day_cell_test.dart for the
        // date number's own live-semantics node when it is interactive.
        final semantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
        expect(semantics.label, contains('today'));
        expect(semantics.label, contains('disabled'));
        expect(semantics.label, contains('2 events'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a day cell with exactly one event uses the singular "event"', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        final date = DateTime(2026, 8, 15);

        await pumpThemed(
          tester,
          SizedBox(
            width: 160,
            height: 200,
            child: LayrzCalendarDayCell(
              date: date,
              isToday: false,
              isOutsideMonth: false,
              isDisabled: false,
              entries: [
                LayrzCalendarEntry(title: 'Solo event', start: date, end: date),
              ],
            ),
          ),
        );

        final semantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
        expect(semantics.label, contains('1 event'));
        expect(semantics.label, isNot(contains('1 events')));
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'a multi-day event bar announces once per day cell it crosses, via the cell label, not as its own '
      'separate node',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          // August 10-12, 2026 falls entirely within one week row under both
          // Monday-first and the default Sunday-first grid -- one continuous
          // bar, rendered once, crossing three day cells.
          await pumpThemed(
            tester,
            SizedBox(
              width: 1000,
              height: 800,
              child: LayrzCalendarMonthSurface(
                focusedDate: DateTime(2026, 8, 1),
                entries: [
                  LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
                ],
              ),
            ),
          );

          // Every day cell the bar crosses announces the event exactly once,
          // through the ordinary LayrzCalendarDayCell merged label -- the
          // bar itself is wrapped in ExcludeSemantics and contributes no
          // semantics node of its own, so the event is never announced
          // twice for a single day, nor once per day plus once for the bar.
          for (final day in [10, 11, 12]) {
            final semantics = tester.getSemantics(
              find.byWidgetPredicate((w) => w is LayrzCalendarDayCell && w.date.day == day && !w.isOutsideMonth),
            );
            expect(semantics.label, contains('1 event'), reason: 'day $day should announce exactly one event');
          }

          // A day outside the span announces no event at all.
          final unrelatedDay = tester.getSemantics(
            find.byWidgetPredicate((w) => w is LayrzCalendarDayCell && w.date.day == 13 && !w.isOutsideMonth),
          );
          expect(unrelatedDay.label, isNot(contains('event')));
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'RISK-11: a cell with an interactive overflow chip exposes both the cell label AND a live, separate '
      'semantics node for the chip -- the blanket exclusion narrows to the chrome only',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final date = DateTime(2026, 8, 28);
          final entries = List.generate(5, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: entries,
                maxVisibleSlots: 3,
                onOverflowTap: (_) {},
              ),
            ),
          );

          final cellSemantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
          // The cell-level label still summarizes the date and total count --
          // the first-read summary a screen reader hits before descending.
          expect(cellSemantics.label, contains('August 28'));
          expect(cellSemantics.label, contains('5 events'));

          // The overflow chip's own node is reachable, separate from the
          // cell's merged label, with a concrete action -- proving the
          // blanket ExcludeSemantics no longer swallows it.
          final chipSemantics = tester.getSemantics(find.text('+3'));
          expect(chipSemantics.label, contains('opens day view'));
          expect(
            chipSemantics,
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'RISK-11 extension: a cell with BOTH the date number and the overflow chip interactive exposes the cell '
      'label AND two separate live semantics nodes',
      (tester) async {
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final handle = tester.ensureSemantics();
        try {
          final date = DateTime(2026, 8, 28);
          final entries = List.generate(5, (i) => LayrzCalendarEntry(title: 'Event $i', start: date, end: date));

          await pumpThemed(
            tester,
            SizedBox(
              width: 160,
              height: 200,
              child: LayrzCalendarDayCell(
                date: date,
                isToday: false,
                isOutsideMonth: false,
                isDisabled: false,
                entries: entries,
                maxVisibleSlots: 3,
                onOverflowTap: (_) {},
                onDateNumberTap: (_) {},
              ),
            ),
          );

          final cellSemantics = tester.getSemantics(find.byType(LayrzCalendarDayCell));
          expect(cellSemantics.label, contains('August 28'));
          expect(cellSemantics.label, contains('5 events'));

          final dateNumberSemantics = tester.getSemantics(find.text('28'));
          expect(dateNumberSemantics.label, contains('opens day view'));
          expect(
            dateNumberSemantics,
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
          );

          final chipSemantics = tester.getSemantics(find.text('+3'));
          expect(chipSemantics.label, contains('opens day view'));
          expect(
            chipSemantics,
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('navigation buttons in the header are labelled and reachable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
          ),
        );

        // LayrzButton always renders its label via RichText, never a plain
        // Text -- find.widgetWithText (which only matches Text/EditableText)
        // never finds it, so every LayrzButton lookup here goes by its
        // labelText field instead.
        final previousButton = find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month');
        final nextButton = find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next month');
        final todayButton = find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today');

        expect(previousButton, findsOneWidget);
        expect(nextButton, findsOneWidget);
        expect(todayButton, findsOneWidget);

        // hasTapAction is deliberately not asserted here: LayrzButton's own
        // Semantics node (button.dart) does not forward a tap SemanticsAction
        // -- a pre-existing gap in that shipped component, outside this
        // unit's file list, reported to the lead rather than fixed here.
        expect(
          tester.getSemantics(previousButton),
          matchesSemantics(isButton: true, isEnabled: true, hasEnabledState: true),
        );
        expect(
          tester.getSemantics(nextButton),
          matchesSemantics(isButton: true, isEnabled: true, hasEnabledState: true),
        );
        expect(
          tester.getSemantics(todayButton),
          matchesSemantics(isButton: true, isEnabled: true, hasEnabledState: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('all three view-mode switcher entries announce as enabled buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
          ),
        );

        for (final label in ['View as month', 'View as week', 'View as day']) {
          final button = find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == label);
          expect(
            tester.getSemantics(button),
            matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: true),
            reason: '$label should announce as an enabled button',
          );
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the active view-mode switcher entry is visually distinguishable (filled) from the others', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.week,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      final monthButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as month'),
      );
      final weekButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as week'),
      );

      expect(weekButton.style, LayrzButtonStyle.filled);
      expect(monthButton.style, LayrzButtonStyle.outlined);

      controller.dispose();
    });
  });
}

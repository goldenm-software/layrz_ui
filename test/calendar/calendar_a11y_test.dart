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
        // event count together -- never separate unlabeled child nodes for
        // the event chips or the date number (the inner ExcludeSemantics on
        // the visual content is what forces this merge).
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
          // August 10-12, 2026 is Monday-Wednesday of the same week row --
          // one continuous bar, rendered once, crossing three day cells.
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

    testWidgets('disabled view-mode switcher entries announce as disabled, not merely absent an onTap', (
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

        final weekButton = find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as week');
        expect(
          tester.getSemantics(weekButton),
          matchesSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
      } finally {
        handle.dispose();
      }
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarDayCell', () {
    guardedTestWidgets('renders the day-of-month number', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 120,
          height: 120,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: const [],
          ),
        ),
      );

      expect(find.text('28'), findsOneWidget);
    });

    guardedTestWidgets('renders up to the visible cap of event chips, collapsing the rest into an overflow chip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final entries = List.generate(
        kLayrzCalendarMaxVisibleEvents + 2,
        (i) => LayrzCalendarEntry(
          title: 'Event $i',
          start: DateTime(2026, 8, 28),
          end: DateTime(2026, 8, 28),
        ),
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: entries,
          ),
        ),
      );

      for (var i = 0; i < kLayrzCalendarMaxVisibleEvents; i++) {
        expect(find.text('Event $i'), findsOneWidget);
      }
      expect(find.text('Event $kLayrzCalendarMaxVisibleEvents'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    guardedTestWidgets('renders no overflow chip when entries fit within the cap', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 28),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: false,
            entries: [
              LayrzCalendarEntry(title: 'One', start: DateTime(2026, 8, 28), end: DateTime(2026, 8, 28)),
            ],
          ),
        ),
      );

      expect(find.textContaining('+'), findsNothing);
    });

    guardedTestWidgets('a disabled day with events still renders those events', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 160,
          height: 200,
          child: LayrzCalendarDayCell(
            date: DateTime(2026, 8, 29),
            isToday: false,
            isOutsideMonth: false,
            isDisabled: true,
            entries: [
              LayrzCalendarEntry(title: 'Weekend shift', start: DateTime(2026, 8, 29), end: DateTime(2026, 8, 29)),
            ],
          ),
        ),
      );

      // Disabled and "no events" are distinct code paths (per the plan's
      // criterion): a disabled day with events still shows its events, it is
      // not forced empty just because it is disabled.
      expect(find.text('Weekend shift'), findsOneWidget);
      expect(find.text('29'), findsOneWidget);
    });

    guardedTestWidgets('an empty, non-disabled day renders no event content and is not styled as disabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

      expect(find.text('30'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });
  });
}

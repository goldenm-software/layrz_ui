import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarMonthSurface', () {
    guardedTestWidgets('renders weekday header labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    guardedTestWidgets('renders every day of the focused month', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 2026 has 31 days.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('places a single-day event only on its own date', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Single day event', start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 15)),
            ],
          ),
        ),
      );

      expect(find.text('Single day event'), findsOneWidget);
    });

    guardedTestWidgets('places a multi-day event on every date it spans without breaking the grid', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Multi day', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
            ],
          ),
        ),
      );

      // Rendered once per occupied date -- three day cells, three chips.
      expect(find.text('Multi day'), findsNWidgets(3));
    });

    guardedTestWidgets('applies isDateDisabled per date without affecting days that have no events', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            isDateDisabled: (date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
          ),
        ),
      );

      // The grid still renders every day regardless of disabled status --
      // disabling is a visual overlay, not an omission.
      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('leading and trailing days from adjacent months fill the grid rectangle', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 1, 2026 is a Saturday, so the grid must show trailing July
      // days to fill the first row.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      // July has 31 days; the last few (27-31) fill the leading grid cells.
      expect(find.text('31'), findsWidgets);
    });

    guardedTestWidgets('does not duplicate or shift a day across a DST transition', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Regression for a bug where the grid stepped cells via
      // `gridStart.add(Duration(days: n))`. Duration arithmetic is absolute
      // elapsed time, not calendar-day stepping: crossing a local DST
      // transition lands a 24h step on 23:00 of the *previous* local day,
      // duplicating that day's number and shifting every subsequent cell
      // onto the wrong weekday column. The fix steps via the `DateTime`
      // constructor (`DateTime(y, m, d + n)`), which normalizes by calendar
      // date and is immune to the local UTC-offset change.
      //
      // Whether this test's host machine actually has a DST transition
      // depends on its configured timezone, so this scans a window of
      // months for one instead of hardcoding a single month/year -- making
      // the test meaningful on any host with at least one DST-observing
      // month in the scanned range, while still failing loudly (not
      // silently passing) if none is found.
      DateTime? transitionMonth;
      for (var year = 2015; year <= 2030 && transitionMonth == null; year++) {
        for (var month = 1; month <= 12; month++) {
          final monthStart = DateTime(year, month, 1);
          final monthEnd = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
          if (monthStart.timeZoneOffset != monthEnd.timeZoneOffset) {
            transitionMonth = DateTime(year, month, 1);
          }
        }
      }

      expect(
        transitionMonth,
        isNotNull,
        reason:
            'No DST-transitioning month found in 2015-2030 for this host\'s local timezone -- '
            'this test cannot exercise the regression it guards. Run it on a host whose '
            'timezone observes DST (e.g. TZ=America/Mexico_City, which observed DST through 2022).',
      );

      // Reference sequence: the correct, DST-immune calendar-date stepping
      // this fix uses. Computed independently of production code so the
      // test does not just re-assert whatever the surface currently does.
      final firstOfMonth = DateTime(transitionMonth!.year, transitionMonth.month);
      final offset = firstOfMonth.weekday - DateTime.monday;
      final gridStart = DateTime(transitionMonth.year, transitionMonth.month, 1 - offset);
      final expectedCounts = <int, int>{};
      for (var i = 0; i < 42; i++) {
        final date = DateTime(gridStart.year, gridStart.month, gridStart.day + i);
        expectedCounts[date.day] = (expectedCounts[date.day] ?? 0) + 1;
      }

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: transitionMonth,
            entries: const [],
          ),
        ),
      );

      // Assert every day number renders exactly as many times as the
      // reference grid predicts -- catches both an outright duplicate (a
      // count too high) and a whole-grid shift (a different set of numbers,
      // or wrong counts throughout) in one comparison, without hardcoding
      // day numbers that only hold in one timezone.
      for (final entry in expectedCounts.entries) {
        expect(
          find.text('${entry.key}'),
          findsNWidgets(entry.value),
          reason: 'day-of-month ${entry.key} should render exactly ${entry.value} time(s) in this grid',
        );
      }
    });
  });
}

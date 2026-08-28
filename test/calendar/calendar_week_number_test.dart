import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/calendar/src/calendar_week_number.dart';

void main() {
  group('isoWeekNumberOf', () {
    test('known values from the plan are correct', () {
      expect(isoWeekNumberOf(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumberOf(DateTime(2026, 8, 28)), 35);
    });

    test('ignores the time-of-day component', () {
      final midnight = isoWeekNumberOf(DateTime(2026, 8, 28));
      final withTime = isoWeekNumberOf(DateTime(2026, 8, 28, 23, 59, 59));

      expect(withTime, midnight);
    });

    test('a late-December date can belong to week 1 of the next ISO year', () {
      // Monday, December 29, 2025 -- its Thursday (Jan 1, 2026) falls in
      // 2026, so it is ISO week 1 of 2026, not week 53 of 2025.
      expect(isoWeekNumberOf(DateTime(2025, 12, 29)), 1);
    });

    test('an early-January date can belong to week 52/53 of the previous ISO year', () {
      // Friday, January 1, 2027 -- its Thursday (Dec 30, 2026) falls in
      // 2026, so it is ISO week 53 of 2026, not week 1 of 2027.
      expect(isoWeekNumberOf(DateTime(2027, 1, 1)), 53);
      // Thursday, December 31, 2020 is the last day of ISO week 53 of 2020.
      expect(isoWeekNumberOf(DateTime(2020, 12, 31)), 53);
      // Friday, January 1, 2021 -- its Thursday (Dec 31, 2020) is still in
      // 2020, so it remains week 53 of 2020.
      expect(isoWeekNumberOf(DateTime(2021, 1, 1)), 53);
    });

    test('the week containing January 4th is always week 1', () {
      for (var year = 2020; year <= 2030; year++) {
        expect(isoWeekNumberOf(DateTime(year, 1, 4)), 1, reason: 'January 4, $year should be ISO week 1');
      }
    });

    test('week numbers ascend by one across an ordinary mid-year week boundary', () {
      // Sunday, August 23, 2026 is the last day of week 34; Monday, August
      // 24, 2026 starts week 35.
      expect(isoWeekNumberOf(DateTime(2026, 8, 23)), 34);
      expect(isoWeekNumberOf(DateTime(2026, 8, 24)), 35);
    });

    test('a full non-leap year has no duplicate or reversed week numbers across its weeks', () {
      // Walk every Monday of 2026 and assert the sequence strictly
      // increases by exactly 1 each week, with no repeats.
      var monday = DateTime(2026, 1, 5); // first Monday of 2026
      int? previous;
      for (var i = 0; i < 52; i++) {
        final week = isoWeekNumberOf(monday);
        if (previous != null) {
          expect(week, previous + 1, reason: 'week following $previous should be ${previous + 1}, got $week');
        }
        previous = week;
        monday = DateTime(monday.year, monday.month, monday.day + 7);
      }
    });

    test(
      'no duplicate week numbers occur within a single month-grid worth of rows, '
      'under both Sunday-start and Monday-start configurations, across a multi-year range',
      () {
        for (final firstDayOfWeek in [DateTime.sunday, DateTime.monday]) {
          for (var year = 2024; year <= 2027; year++) {
            for (var month = 1; month <= 12; month++) {
              final firstOfMonth = DateTime(year, month, 1);
              final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
              final gridStart = DateTime(year, month, 1 - offset);

              final seen = <int>{};
              for (var week = 0; week < 6; week++) {
                final rowFirst = DateTime(gridStart.year, gridStart.month, gridStart.day + week * 7);
                final weekNumber = isoWeekNumberOf(rowFirst);
                expect(
                  seen.add(weekNumber),
                  isTrue,
                  reason:
                      'duplicate week number $weekNumber in the $year-$month grid '
                      '(firstDayOfWeek: $firstDayOfWeek)',
                );
              }
            }
          }
        }
      },
    );

    test('never steps across a DST transition incorrectly (uses calendar-field stepping)', () {
      // A rough regression guard: computing the ISO week for dates that
      // straddle a US DST transition (2026-03-08) must not throw or produce
      // an out-of-range week number, which a `Duration`-based bug could.
      final beforeTransition = DateTime(2026, 3, 7);
      final afterTransition = DateTime(2026, 3, 9);

      final before = isoWeekNumberOf(beforeTransition);
      final after = isoWeekNumberOf(afterTransition);

      expect(before, inInclusiveRange(1, 53));
      expect(after, inInclusiveRange(1, 53));
    });
  });
}

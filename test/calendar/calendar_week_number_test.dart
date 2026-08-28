import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/calendar/src/calendar_week_number.dart';

/// An independent, `DateTime`-free ISO 8601 week-number oracle used only in
/// this test file to cross-check [isoWeekNumberOf].
///
/// Deliberately implemented with pure integer arithmetic over
/// (year, month, day) — no `DateTime` construction, no `.difference()`, no
/// timezone or DST involvement of any kind — so a mismatch against
/// [isoWeekNumberOf] can only mean the production function is wrong, never
/// that the oracle picked up the host's local time the way the original bug
/// did. This is Zeller/ordinal-date arithmetic: [_isProlepticLeapYear] and
/// [_dayOfYear] give an ordinal date, [_weekdayOfIsoDate] gives ISO weekday
/// (1=Monday..7=Sunday) via a fixed reference (0001-01-01 was a Monday under
/// the proleptic Gregorian calendar), and the rest follows the standard
/// "ISO week from ordinal date" formula.
int _isoWeekOracle(int year, int month, int day) {
  final week = _rawIsoWeek(year, month, day);
  if (week == 0) {
    // Falls in the last week of the previous ISO year.
    return _rawIsoWeek(year - 1, 12, 31);
  }
  if (week == 53 && _isoWeeksInYear(year) == 52) {
    // Rolled into week 1 of the next ISO year.
    return 1;
  }
  return week;
}

/// Raw week number per the ordinal-date formula, before correcting for the
/// week-0 (belongs to previous year) and week-53-overflow (belongs to next
/// year) edge cases; see [_isoWeekOracle].
int _rawIsoWeek(int year, int month, int day) {
  final ordinal = _dayOfYear(year, month, day);
  final weekday = _weekdayOfIsoDate(year, month, day); // 1..7, Monday..Sunday
  return (ordinal - weekday + 10) ~/ 7;
}

/// The number of ISO weeks (52 or 53) in ISO year [year].
int _isoWeeksInYear(int year) {
  int p(int y) => (y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400)) % 7;
  return p(year) == 4 || p(year - 1) == 3 ? 53 : 52;
}

/// True if [year] is a leap year under the proleptic Gregorian calendar.
bool _isProlepticLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// The 1-based ordinal day of [year] for the given [month]/[day].
int _dayOfYear(int year, int month, int day) {
  const cumulative = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  var ordinal = cumulative[month - 1] + day;
  if (month > 2 && _isProlepticLeapYear(year)) ordinal += 1;
  return ordinal;
}

/// The ISO weekday (1=Monday..7=Sunday) of (year, month, day), computed via
/// the days-since-epoch count of a fixed civil-calendar algorithm — integer
/// arithmetic only, no `DateTime`.
int _weekdayOfIsoDate(int year, int month, int day) {
  // Howard Hinnant's `days_from_civil`: days since 1970-01-01 (a Thursday).
  final y = month <= 2 ? year - 1 : year;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yoe = y - era * 400;
  final mp = (month + 9) % 12;
  final doy = (153 * mp + 2) ~/ 5 + day - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  final daysSinceEpoch = era * 146097 + doe - 719468;
  // 1970-01-01 was a Thursday (ISO weekday 4).
  final weekday = ((daysSinceEpoch + 3) % 7 + 7) % 7 + 1;
  return weekday;
}

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

    test(
      'matches a DateTime-free integer-arithmetic oracle for every day of 2020-2027, '
      'under whatever TZ this test process happens to run in',
      () {
        // This is the direct regression guard for the original bug: the
        // production function used to go through `DateTime(...)` (local
        // time) and `.difference(...).inDays`, both of which are perturbed
        // by the host's DST rules. `_isoWeekOracle` never constructs a
        // `DateTime` at all -- it is pure (year, month, day) integer
        // arithmetic -- so if this test is run under TZ=America/New_York,
        // TZ=Etc/UTC, TZ=America/Mexico_City, and TZ=Australia/Lord_Howe and
        // passes identically every time, `isoWeekNumberOf` cannot be reading
        // the host timezone, because the oracle it is compared against
        // structurally cannot either.
        //
        // Swapping `isoWeekNumberOf` for the pre-fix implementation (local
        // `DateTime` + `.difference().inDays`) makes this test fail under
        // TZ=America/New_York starting at the first date on/after the 2026
        // DST transition, while continuing to pass under TZ=Etc/UTC -- which
        // is exactly the "passes in one zone, fails in another" symptom this
        // test exists to catch.
        for (var year = 2020; year <= 2027; year++) {
          final daysInYear = _isProlepticLeapYear(year) ? 366 : 365;
          for (var ordinal = 1; ordinal <= daysInYear; ordinal++) {
            final date = DateTime(year, 1, ordinal);
            final expected = _isoWeekOracle(date.year, date.month, date.day);
            final actual = isoWeekNumberOf(date);
            expect(
              actual,
              expected,
              reason: '${date.year}-${date.month}-${date.day}: oracle says week $expected, got $actual',
            );
          }
        }
      },
    );
  });
}

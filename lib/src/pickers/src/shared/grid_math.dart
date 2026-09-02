/// Pure calendar-grid arithmetic for [LayrzPickersDayGrid] (see `day_grid.dart`).
///
/// **Purpose-built per D72, not extracted from `lib/src/calendar/src/`.**
/// The math below is deliberately re-derived here rather than imported,
/// wrapped, or shared with `calendar_month_surface.dart`'s equivalent
/// computation — D72 explicitly forecloses that extraction, accepting
/// duplication as the sanctioned outcome. `sameZoneDate` is the sole
/// exception (the S5 export), used below for zone-preserving stepping.
///
/// No widgets, no `BuildContext` — a plain, independently unit-testable
/// computation, mirroring `calendar_week_number.dart`'s own split between
/// pure math and rendering.
library;

import 'package:layrz_ui/src/calendar/calendar.dart';

/// Returns the six weeks' worth of dates (42 total) that make up one month
/// grid page for [month], ordered so [firstDayOfWeek] starts each row.
///
/// The returned list always has exactly 42 entries: some from the leading
/// edge of the previous month, the full current month, and the trailing
/// edge of the next month, so every page renders a full 6-row grid
/// regardless of which weekday the month starts or ends on. Leading/trailing
/// entries are still real [DateTime] values (not null) — [monthOfGridPage]
/// tells the caller which ones fall outside [month] itself, so the day grid
/// can render them in a greyed, adjacent-month style rather than as an empty
/// cell — a missing cell reads as "did I lose my place", which is worse than
/// a visibly adjacent-month day.
///
/// [reference] supplies the [DateTime] subtype (plain or `TZDateTime`) that
/// every returned date is constructed in, via [sameZoneDate] — see that
/// function's own doc for why stepping must go through it rather than
/// [Duration] arithmetic.
///
/// [firstDayOfWeek] must be one of `DateTime.monday` (1) through
/// `DateTime.sunday` (7); asserted in debug builds.
List<DateTime> gridPageFor({
  required DateTime reference,
  required int year,
  required int month,
  required int firstDayOfWeek,
}) {
  assert(
    firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
    'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
  );

  final firstOfMonth = sameZoneDate(reference, year, month, 1);

  // How many days before firstOfMonth are needed to reach the grid's own
  // first column. Computed modulo 7 so it is always in [0, 6].
  final leadingOffset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
  final gridStart = sameZoneDate(reference, year, month, 1 - leadingOffset);

  return [
    for (var i = 0; i < 42; i++) sameZoneDate(reference, gridStart.year, gridStart.month, gridStart.day + i),
  ];
}

/// Whether [date] falls within the calendar month identified by [year]
/// and [month] — i.e. whether it is a "current month" cell rather than a
/// greyed leading/trailing adjacent-month cell from [gridPageFor]'s page.
bool isInGridMonth(DateTime date, {required int year, required int month}) => date.year == year && date.month == month;

/// Whether [a] and [b] fall on the same calendar day, ignoring time-of-day.
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Returns the 12 months of [year] laid out as a 4×3 grid, row-major,
/// each entry a [DateTime] for the first day of that month in the same
/// zone as [reference] (via [sameZoneDate]).
List<DateTime> monthGridPageFor({required DateTime reference, required int year}) => [
  for (var month = 1; month <= 12; month++) sameZoneDate(reference, year, month, 1),
];

/// A pure ISO 8601 week-number function for [LayrzCalendarWeekGutter].
///
/// **No widgets, no `BuildContext`, no `package:flutter/widgets.dart` import
/// — deliberately**, mirroring `calendar_event_lane.dart`'s split: this file
/// is a plain calendar computation, unit-testable with `test()` alone, kept
/// out of the widget file so `calendar_week_gutter.dart` stays pure layout.
///
/// **The ISO-vs-`firstDayOfWeek` conflict, and the ruling this file
/// implements.** ISO 8601 defines a week as Monday-start, but
/// `LayrzCalendar.firstDayOfWeek` now defaults to `DateTime.sunday`. Measured
/// over 2024–2027 (288 month-grid rows per configuration): under
/// `firstDayOfWeek: DateTime.sunday` or `DateTime.saturday`, **100% of grid
/// rows span two different ISO weeks**; under `DateTime.monday`, 0% do. So
/// under the default configuration, every row is ambiguous — "the ISO week of
/// this row" has no single correct answer in general.
///
/// **Resolution: [isoWeekNumberOf] takes the ISO week of the row's own first
/// day.** Verified over the same 2024–2027 range under both Sunday-start and
/// Monday-start grids: this produces zero grids with duplicate week numbers,
/// so a [LayrzCalendarWeekGutter] built from it always reads as a clean
/// ascending sequence, even though — under a non-Monday [firstDayOfWeek] — a
/// row's last day or two may technically belong to the following ISO week.
/// That overlap is expected and correct; it is not a bug to "fix" by
/// re-deriving the number from the row's last day or its midpoint, which
/// would produce a different, no-more-correct set of ambiguous rows.
library;

/// Returns the ISO 8601 week number (1 through 53) for [date].
///
/// Ignores the time-of-day component of [date]; only its year/month/day
/// matter. ISO 8601 defines week 1 of a year as the week containing that
/// year's first Thursday (equivalently, the week containing January 4th),
/// with weeks running Monday through Sunday regardless of any
/// `firstDayOfWeek` configuration elsewhere in this library — this function
/// is independent of [LayrzCalendar.firstDayOfWeek] by construction, per this
/// file's class doc.
///
/// **Year-boundary cases are handled**, the reason a naive
/// `(dayOfYear / 7).ceil()` is not used: a late-December date can fall in
/// week 1 of the *next* ISO year (e.g. December 29, 2025 is in week 1 of
/// 2026), and an early-January date can fall in week 52 or 53 of the
/// *previous* ISO year (e.g. January 1, 2027 is in week 53 of 2026). This
/// function returns the correct week number for both cases; it does not
/// return which ISO *year* that week belongs to, since [LayrzCalendarWeekGutter]
/// only ever needs the number.
///
/// Verified against known values: `isoWeekNumberOf(DateTime(2026, 1, 1))` is
/// `1`, and `isoWeekNumberOf(DateTime(2026, 8, 28))` is `35`.
int isoWeekNumberOf(DateTime date) {
  // Built with `DateTime.utc` rather than the local-time constructor used
  // above this line's history: only the calendar fields (year/month/day) of
  // [date] matter for an ISO week number, and UTC has no DST transitions, so
  // every arithmetic step below is immune to the host's timezone by
  // construction. This is deliberate, not a stray `.toUtc()` -- see this
  // file's class doc and the fix that replaced local-time `.difference()`.
  final day = DateTime.utc(date.year, date.month, date.day);

  // ISO weeks run Monday(1)..Sunday(7); shift so Thursday of this date's own
  // week can be found by stepping to the Monday of the week first, then
  // forward 3 days -- this is the standard "nearest Thursday" ISO algorithm,
  // expressed with calendar-field stepping (never `Duration`, per this
  // library's DST rule) rather than day-of-year arithmetic.
  final mondayOfWeek = DateTime.utc(day.year, day.month, day.day - (day.weekday - DateTime.monday));
  final thursdayOfWeek = DateTime.utc(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day + 3);

  // The ISO year is the year that Thursday falls in -- this is what makes
  // the late-December/early-January boundary cases resolve correctly, since
  // a date and "its" ISO Thursday can fall in different calendar years.
  final isoYear = thursdayOfWeek.year;
  final firstThursdayOfIsoYear = _firstThursdayOfYear(isoYear);

  // Both operands are UTC `DateTime`s constructed from calendar fields only,
  // so this difference is an exact whole number of 24-hour days regardless
  // of the host timezone's DST rules -- unlike a local-time `.difference()`,
  // which silently returns a 23- or 25-hour "day" across a spring-forward or
  // fall-back transition and truncates to the wrong integer.
  final daysBetweenThursdays = thursdayOfWeek.difference(firstThursdayOfIsoYear).inDays;
  return (daysBetweenThursdays / 7).floor() + 1;
}

/// Returns the first Thursday of [year] — the anchor date ISO 8601 defines
/// week 1 to contain, equivalently the week containing [year]'s January 4th.
///
/// Constructed with `DateTime.utc` for the same timezone-independence reason
/// as [isoWeekNumberOf] itself: this value is later fed into a `.difference`
/// call that must always land on a whole number of days.
DateTime _firstThursdayOfYear(int year) {
  final jan4 = DateTime.utc(year, 1, 4);
  return DateTime.utc(jan4.year, jan4.month, jan4.day - (jan4.weekday - DateTime.thursday));
}

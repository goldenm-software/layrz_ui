/// The granularity a [LayrzCalendar] renders its grid at.
///
/// All three values render as of this pass — the month grid, plus new week
/// and day surfaces. `engineering/decisions.md`'s D11 names a fourth mode,
/// year, as part of the original four-mode scope review; it does not ship
/// here (see the class doc on `LayrzCalendar` for the correction and the
/// reasoning for shipping three of the four).
enum LayrzCalendarMode {
  /// Renders a full month grid: one row per week, one column per weekday,
  /// with leading/trailing days from the adjacent months filling the grid.
  month,

  /// Renders a single week as seven day columns sharing one hour axis and one
  /// all-day/multi-day band across the top.
  week,

  /// Renders a single day's hour-by-hour detail as one column with a fixed
  /// 00:00–23:00 axis.
  day,
}

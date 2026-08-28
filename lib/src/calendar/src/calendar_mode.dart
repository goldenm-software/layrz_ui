/// The granularity a [LayrzCalendar] renders its grid at.
///
/// All three values ship as public API from pass 1 so a caller's `switch` and
/// any [LayrzCalendarController] wiring compile against the final surface
/// area without a breaking change once week and day views land. **Only
/// [month] renders in this pass** — see the class doc on `LayrzCalendar` for
/// the exact behaviour of the other two in the meantime.
enum LayrzCalendarMode {
  /// Renders a full month grid: one row per week, one column per weekday,
  /// with leading/trailing days from the adjacent months filling the grid.
  ///
  /// The only mode implemented in this pass.
  month,

  /// Renders a single week as a row of day columns.
  ///
  /// Not implemented in this pass — selecting it throws an
  /// [UnimplementedError] rather than silently rendering an empty box.
  week,

  /// Renders a single day's detail (e.g. an hour-by-hour agenda).
  ///
  /// Not implemented in this pass — selecting it throws an
  /// [UnimplementedError] rather than silently rendering an empty box.
  day,
}

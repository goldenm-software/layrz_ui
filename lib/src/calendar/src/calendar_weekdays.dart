import 'package:layrz_ui/src/l10n/l10n.dart';

/// Returns the seven [DateTime] weekday constants (`DateTime.monday` through
/// `DateTime.sunday`), rotated so [firstDayOfWeek] is first.
///
/// This is the **single** source of weekday ordering consumed by both the
/// month grid's header labels and its grid-start math — `LayrzCalendarWeekdays`
/// exists specifically so those two call sites can never drift into two
/// independent reorderings of the same seven days (see [orderedWeekdayLabels]
/// for the label-producing sibling).
///
/// The canonical list is always built in `DateTime.monday..DateTime.sunday`
/// order first, then rotated by `(firstDayOfWeek - DateTime.monday)` — this
/// confines the `dateTimeMonday`/`dateTuesday`… l10n naming asymmetry (see
/// `LayrzUiL10nWeekdaysMixin`) to the one seven-line literal inside
/// [orderedWeekdayLabels], rather than letting it leak into every consumer of
/// this function.
///
/// [firstDayOfWeek] must be one of `DateTime.monday` (1) through
/// `DateTime.sunday` (7); asserted in debug builds.
List<int> orderedWeekdays(int firstDayOfWeek) {
  assert(
    firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
    'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
  );

  const canonical = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];
  final rotation = firstDayOfWeek - DateTime.monday;
  return [
    for (var i = 0; i < canonical.length; i++) canonical[(i + rotation) % canonical.length],
  ];
}

/// Returns the seven localized weekday display labels from [l10n], ordered to
/// start at [firstDayOfWeek], via [orderedWeekdays].
///
/// This is the label-producing sibling of [orderedWeekdays] — both the
/// weekday header row and the grid-start math must derive from these two
/// functions and never build their own independent reordering, or the header
/// labels and the grid's actual column dates can silently drift out of sync
/// (the risk this pass's column-order tests exist to guard).
List<String> orderedWeekdayLabels(LayrzUiL10n l10n, int firstDayOfWeek) {
  final byWeekday = <int, String>{
    DateTime.monday: l10n.dateTimeMonday,
    DateTime.tuesday: l10n.dateTuesday,
    DateTime.wednesday: l10n.dateWednesday,
    DateTime.thursday: l10n.dateThursday,
    DateTime.friday: l10n.dateFriday,
    DateTime.saturday: l10n.dateSaturday,
    DateTime.sunday: l10n.dateSunday,
  };
  return [for (final weekday in orderedWeekdays(firstDayOfWeek)) byWeekday[weekday]!];
}

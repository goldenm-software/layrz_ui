import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

/// Returns the seven [DateTime] weekday constants, rotated so
/// [firstDayOfWeek] is first — the pickers module's own copy of the ordering
/// rule `lib/src/calendar/src/calendar_weekdays.dart` implements, re-derived
/// per D72 rather than imported (see `grid_math.dart`'s class doc for why
/// this duplication is the sanctioned outcome).
List<int> orderedPickerWeekdays(int firstDayOfWeek) {
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
  return [for (var i = 0; i < canonical.length; i++) canonical[(i + rotation) % canonical.length]];
}

/// Returns the single-letter, localized initial for [weekday]
/// (`DateTime.monday`..`DateTime.sunday`).
String weekdayInitialFor(int weekday, LayrzUiL10n l10n) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.weekdayInitialMonday;
    case DateTime.tuesday:
      return l10n.weekdayInitialTuesday;
    case DateTime.wednesday:
      return l10n.weekdayInitialWednesday;
    case DateTime.thursday:
      return l10n.weekdayInitialThursday;
    case DateTime.friday:
      return l10n.weekdayInitialFriday;
    case DateTime.saturday:
      return l10n.weekdayInitialSaturday;
    default:
      return l10n.weekdayInitialSunday;
  }
}

/// Returns the full, localized name for [weekday], used as this header's
/// screen-reader label since the visible glyph is a single letter.
String weekdayFullNameFor(int weekday, LayrzUiL10n l10n) {
  switch (weekday) {
    case DateTime.monday:
      return l10n.dateTimeMonday;
    case DateTime.tuesday:
      return l10n.dateTuesday;
    case DateTime.wednesday:
      return l10n.dateWednesday;
    case DateTime.thursday:
      return l10n.dateThursday;
    case DateTime.friday:
      return l10n.dateFriday;
    case DateTime.saturday:
      return l10n.dateSaturday;
    default:
      return l10n.dateSunday;
  }
}

/// The compact day grid's weekday header row: seven single-letter initials
/// ("M T W T F S S" for a Monday-first week), each carrying its full weekday
/// name as a screen-reader label since the visible glyph alone is ambiguous
/// (Tuesday and Thursday both start with "T").
///
/// Purely decorative layout — this widget owns no interaction state and
/// renders no focusable elements; [LayrzPickersDayGrid] positions it above
/// the day cells and account for its height when computing row layout.
class LayrzPickersWeekdayHeader extends StatelessWidget {
  /// Which [DateTime] weekday constant (`DateTime.monday`..`DateTime.sunday`)
  /// starts the row.
  final int firstDayOfWeek;

  /// Reserved leading width matching the week-number gutter's column width,
  /// so the header's seven letters align with the day grid's seven columns
  /// beneath it. Zero when no gutter is shown.
  final double gutterWidth;

  /// Creates a new [LayrzPickersWeekdayHeader].
  const LayrzPickersWeekdayHeader({super.key, required this.firstDayOfWeek, this.gutterWidth = 0.0});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final weekdays = orderedPickerWeekdays(firstDayOfWeek);

    return Row(
      children: [
        if (gutterWidth > 0) SizedBox(width: gutterWidth),
        for (final weekday in weekdays)
          Expanded(
            child: Semantics(
              label: weekdayFullNameFor(weekday, l10n),
              child: ExcludeSemantics(
                child: Center(
                  child: Text(
                    weekdayInitialFor(weekday, l10n),
                    style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

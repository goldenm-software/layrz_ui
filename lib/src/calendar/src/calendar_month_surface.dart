import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'calendar_day_cell.dart';
import 'calendar_entry.dart';

/// The number of weekday columns a month grid always renders.
const int _kColumns = 7;

/// The layout surface for [LayrzCalendarMode.month]: a full month grid, one
/// row per week, seven columns (Monday–Sunday), with leading and trailing
/// days from the adjacent months filling out the first and last rows so the
/// grid is always a rectangle.
///
/// This is a pure layout surface in the `LayrzStepper` template sense — it
/// receives already-resolved data (the month to render, the full entry
/// list, the disabled predicate) and has no state of its own. Event overlap
/// / lane assignment for multi-day events across week rows is explicitly out
/// of scope for pass 1: a multi-day entry renders as an ordinary chip inside
/// every day cell it [LayrzCalendarEntry.occupies], one cell at a time, with
/// no visual connector spanning the row. That connector is pass 2's job.
class LayrzCalendarMonthSurface extends StatelessWidget {
  /// Creates a [LayrzCalendarMonthSurface].
  const LayrzCalendarMonthSurface({
    required this.focusedDate,
    required this.entries,
    this.isDateDisabled,
    super.key,
  });

  /// Any date within the month to render — only the year/month components
  /// are used.
  final DateTime focusedDate;

  /// The full set of events to place. Filtered per cell via
  /// [LayrzCalendarEntry.occupies].
  final List<LayrzCalendarEntry> entries;

  /// Predicate deciding whether a given date is disabled.
  ///
  /// Null means no date is disabled. See `LayrzCalendar`'s class doc for why
  /// a predicate, rather than a set or range, is this pass's primitive.
  final bool Function(DateTime date)? isDateDisabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);
    final weekdayLabels = [
      l10n.dateTimeMonday,
      l10n.dateTuesday,
      l10n.dateWednesday,
      l10n.dateThursday,
      l10n.dateFriday,
      l10n.dateSaturday,
      l10n.dateSunday,
    ];

    final today = DateTime.now();
    final gridStart = _gridStart(focusedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
                  child: Text(
                    label.substring(0, label.length.clamp(0, 3)),
                    textAlign: TextAlign.center,
                    style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spacing.sp1),
        Expanded(
          child: Column(
            children: [
              for (var week = 0; week < 6; week++)
                Expanded(
                  child: Row(
                    children: [
                      for (var day = 0; day < _kColumns; day++)
                        Expanded(
                          child: _buildCell(
                            context,
                            date: DateTime(
                              gridStart.year,
                              gridStart.month,
                              gridStart.day + week * _kColumns + day,
                            ),
                            today: today,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, {required DateTime date, required DateTime today}) {
    final isOutsideMonth = date.month != focusedDate.month;
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isDisabled = isDateDisabled?.call(date) ?? false;
    final dayEntries = entries.where((entry) => entry.occupies(date)).toList(growable: false);

    return LayrzCalendarDayCell(
      date: date,
      isToday: isToday,
      isOutsideMonth: isOutsideMonth,
      isDisabled: isDisabled,
      entries: dayEntries,
    );
  }

  /// Returns the Monday that starts the first full week rendered by the
  /// grid — always on or before the 1st of [focusedDate]'s month.
  static DateTime _gridStart(DateTime focusedDate) {
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month);
    // DateTime.weekday is 1 (Monday) through 7 (Sunday); back up to the
    // Monday on or before the 1st.
    final offset = firstOfMonth.weekday - DateTime.monday;
    // Step by calendar date (DateTime constructor field overflow), not by
    // Duration -- Duration arithmetic is absolute elapsed time and silently
    // lands on the wrong local day across a DST transition. See
    // LayrzCalendarMonthSurface.build for the same pattern and why it
    // matters.
    return DateTime(focusedDate.year, focusedDate.month, 1 - offset);
  }
}

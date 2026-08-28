import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'calendar_entry.dart';
import 'calendar_style_spec.dart';

/// The maximum number of event chips a [LayrzCalendarDayCell] paints before
/// collapsing the remainder into an overflow chip.
///
/// This is a fixed layout capacity for pass 1's month grid, not a caller
/// configuration point — a month cell is short, and an unbounded chip list
/// would push the whole week row out of alignment. Event overlap layout
/// beyond this (side-by-side widths, lane assignment) is explicitly out of
/// scope for pass 1 (see `LayrzCalendarMonthSurface`'s class doc) and lands
/// with the week/day views in pass 2.
const int kLayrzCalendarMaxVisibleEvents = 3;

/// A single day cell in a [LayrzCalendar] month grid.
///
/// Renders the day-of-month number and up to [kLayrzCalendarMaxVisibleEvents]
/// event title chips, with any remainder collapsed into a "+N more" chip.
/// **Display-only in this pass**: the cell has no `onTap` and no selection
/// affordance — see the class doc on `LayrzCalendar` for why.
///
/// **Disabled dates and "no events" are rendered by distinct code paths.**
/// [isDisabled] alone controls the disabled visual treatment (dimmed date
/// number, muted background) via [LayrzCalendarDayCellStyleSpec]; whether
/// [entries] is empty never influences that treatment. A disabled day with
/// events still renders those events at their ordinary event colors — this
/// pass does not dim event chips to match the disabled date number — and a
/// day with no events that is not disabled renders as a perfectly ordinary
/// empty cell; there is no shared "nothing to show" branch between the two
/// states.
class LayrzCalendarDayCell extends StatelessWidget {
  /// Creates a [LayrzCalendarDayCell].
  const LayrzCalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isOutsideMonth,
    required this.isDisabled,
    required this.entries,
    super.key,
  });

  /// The calendar date this cell represents.
  final DateTime date;

  /// Whether [date] is today's date.
  final bool isToday;

  /// Whether [date] falls outside the month currently in view (a leading or
  /// trailing day used to fill out the grid).
  final bool isOutsideMonth;

  /// Whether [date] is disabled per the calendar's `isDateDisabled`
  /// predicate.
  ///
  /// Purely a visual flag in this pass — a disabled date does not prevent
  /// anything, since no day is tappable yet. It exists so pass 2's
  /// interactive surface can read the same cell to decide whether a tap is
  /// honoured.
  final bool isDisabled;

  /// The events that occupy [date], already filtered and ordered by the
  /// caller (`LayrzCalendarMonthSurface`).
  final List<LayrzCalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = LayrzCalendarDayCellStyleSpec.resolve(
      tokens: tokens,
      isToday: isToday,
      isOutsideMonth: isOutsideMonth,
      isDisabled: isDisabled,
    );

    final visibleEntries = entries.take(kLayrzCalendarMaxVisibleEvents).toList();
    final overflowCount = entries.length - visibleEntries.length;

    return Semantics(
      label: _semanticsLabel(context),
      container: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: spec.backgroundColor,
            border: Border.all(color: spec.borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spacing.sp1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}',
                  style: tokens.typography.label.copyWith(
                    color: spec.dateColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                SizedBox(height: tokens.spacing.sp1),
                for (final entry in visibleEntries) _EventChip(entry: entry, fallbackColor: spec.eventColor),
                if (overflowCount > 0)
                  Text(
                    '+$overflowCount',
                    style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the one merged semantics announcement for this cell, e.g.
  /// "August 28, today, disabled, 2 events" — never separate nodes for the
  /// date number and its event chips (the outer [Semantics] plus the inner
  /// [ExcludeSemantics] on the visual content is what merges them).
  String _semanticsLabel(BuildContext context) {
    final buffer = StringBuffer(_formatDate(date));
    if (isToday) buffer.write(', today');
    if (isDisabled) buffer.write(', disabled');
    if (entries.isNotEmpty) {
      buffer.write(', ${entries.length} ${entries.length == 1 ? 'event' : 'events'}');
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}

/// A single event title chip painted inside a [LayrzCalendarDayCell].
class _EventChip extends StatelessWidget {
  const _EventChip({required this.entry, required this.fallbackColor});

  final LayrzCalendarEntry entry;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = entry.color ?? fallbackColor;

    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(tokens.radius.r1),
      ),
      child: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tokens.typography.label.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

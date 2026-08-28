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

/// The fixed height of the day-of-month number row at the top of a
/// [LayrzCalendarDayCell], not including the cell's own outer padding.
///
/// Fixed (rather than left to the date [Text]'s natural intrinsic height) so
/// `LayrzCalendarMonthSurface` can compute exactly where the first event
/// slot begins for its multi-day bar overlay, without measuring rendered
/// text metrics. See [kLayrzCalendarEventSlotHeight]'s doc for the sibling
/// constant this pairs with.
const double kLayrzCalendarDateRowHeight = 16;

/// A single day cell in a [LayrzCalendar] month grid.
///
/// Renders the day-of-month number and up to [kLayrzCalendarMaxVisibleEvents]
/// total event slots — [entries] as ordinary title chips, plus
/// [reservedMultiDaySlots] blank placeholder slots of identical height —
/// with any remainder collapsed into a "+N more" chip. **Display-only in
/// this pass**: the cell has no `onTap` and no selection affordance — see the
/// class doc on `LayrzCalendar` for why.
///
/// **Multi-day events are not drawn by this cell.** A multi-day entry is
/// rendered as a single continuous bar spanning the week row, painted by
/// `LayrzCalendarMonthSurface` in a `Stack` layer above the grid of day
/// cells — see that class's doc. This cell only reserves the vertical space
/// a bar needs via [reservedMultiDaySlots], so the surface's bar lands
/// exactly on top of a blank slot rather than overlapping a single-day chip.
/// [entries] therefore never includes a multi-day [LayrzCalendarEntry] — the
/// surface filters those out before constructing this cell.
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
    this.reservedMultiDaySlots = 0,
    this.totalEventCount,
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

  /// The single-day events that occupy [date], already filtered and ordered
  /// by the caller (`LayrzCalendarMonthSurface`).
  ///
  /// Must not contain a multi-day [LayrzCalendarEntry] (one whose
  /// [LayrzCalendarEntry.isMultiDay] is `true`) — those are rendered as
  /// continuous bars by the surface instead. See the class doc.
  final List<LayrzCalendarEntry> entries;

  /// The number of multi-day event bars the surface will paint over this
  /// cell, i.e. how many blank placeholder slots to reserve.
  ///
  /// Each reserved slot occupies the same height as one event chip and
  /// counts toward [kLayrzCalendarMaxVisibleEvents] the same way a chip
  /// does, so the "+N" overflow count and the vertical rhythm of the grid
  /// stay correct regardless of how the day's events are split between
  /// single-day chips and multi-day bars. Defaults to 0 (no multi-day event
  /// occupies this date).
  final int reservedMultiDaySlots;

  /// The total number of events occupying [date] for semantics purposes,
  /// i.e. [entries] plus every multi-day entry the surface tracks
  /// separately.
  ///
  /// Null falls back to `entries.length` (no multi-day entries occupy this
  /// date), which keeps every caller that never had a "multi-day" concept
  /// unaffected. `LayrzCalendarMonthSurface` always supplies the true total
  /// so a day cell crossed by a multi-day bar still announces the full event
  /// count in [_semanticsLabel], even though that bar's chip never actually
  /// renders inside this cell.
  final int? totalEventCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = LayrzCalendarDayCellStyleSpec.resolve(
      tokens: tokens,
      isToday: isToday,
      isOutsideMonth: isOutsideMonth,
      isDisabled: isDisabled,
    );

    final totalSlotsUsed = entries.length + reservedMultiDaySlots;
    final visibleChipCap = (kLayrzCalendarMaxVisibleEvents - reservedMultiDaySlots).clamp(0, entries.length);
    final visibleEntries = entries.take(visibleChipCap).toList();
    final overflowCount = totalSlotsUsed - (visibleEntries.length + reservedMultiDaySlots);

    return Semantics(
      label: _semanticsLabel(context),
      container: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: spec.backgroundColor,
            // Ordinary grid lines are no longer painted per cell -- they come
            // from `LayrzCalendarMonthSurface` wrapping the whole grid in a
            // divider-colored container and spacing cells apart by the
            // border width, so the container's background shows through as a
            // uniform single-width line everywhere (see that class's doc).
            // Today's ring is the one exception: it is a per-cell accent
            // highlight, not a structural grid line, so it still paints here
            // and only for `isToday`.
            border: isToday ? Border.all(color: spec.borderColor) : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spacing.sp1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: kLayrzCalendarDateRowHeight,
                  child: Text(
                    '${date.day}',
                    style: tokens.typography.label.copyWith(
                      color: spec.dateColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spacing.sp1),
                for (var i = 0; i < reservedMultiDaySlots; i++) const _ReservedEventSlot(),
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
  ///
  /// Uses [totalEventCount] (falling back to `entries.length`) so a date
  /// crossed by a multi-day bar still announces its full event count even
  /// though that event never renders as a chip inside this cell.
  String _semanticsLabel(BuildContext context) {
    final buffer = StringBuffer(_formatDate(date));
    if (isToday) buffer.write(', today');
    if (isDisabled) buffer.write(', disabled');
    final eventCount = totalEventCount ?? entries.length;
    if (eventCount > 0) {
      buffer.write(', $eventCount ${eventCount == 1 ? 'event' : 'events'}');
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

/// The fixed height of one event slot (a chip, a reserved multi-day
/// placeholder, or a bar segment painted by `LayrzCalendarMonthSurface`),
/// including its bottom margin.
///
/// `LayrzCalendarMonthSurface` reads this constant, together with
/// [kLayrzCalendarDateRowHeight], to compute the exact vertical offset of
/// each event slot for its continuous multi-day bar overlay, so a bar lands
/// on top of the blank [_ReservedEventSlot] a day cell reserves for it
/// rather than overlapping a single-day chip. The two widgets must agree on
/// slot height pixel-for-pixel, or a bar would drift from the reserved gap
/// it is meant to cover.
const double kLayrzCalendarEventSlotHeight = 20;

/// A single event title chip painted inside a [LayrzCalendarDayCell].
///
/// Renders **filled** -- a full-opacity accent background with
/// [Color.contrastColor] text -- matching `LayrzChipStyle.filled` (the
/// `filledTonal` treatment this used to mirror was removed from the design
/// system entirely; see `_MultiDayBar` in `calendar_month_surface.dart`,
/// which must render identically for the same accent color).
class _EventChip extends StatelessWidget {
  const _EventChip({required this.entry, required this.fallbackColor});

  final LayrzCalendarEntry entry;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = entry.color ?? fallbackColor;

    return SizedBox(
      height: kLayrzCalendarEventSlotHeight,
      child: Container(
        margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(tokens.radius.r1),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.typography.label.copyWith(color: color.contrastColor, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

/// A blank placeholder occupying the same height as an [_EventChip], left
/// empty so a multi-day bar painted by `LayrzCalendarMonthSurface` can be
/// positioned on top of it without overlapping a single-day chip.
///
/// Renders nothing visible of its own — the bar is painted by the surface in
/// a layer above this cell, not by this widget.
class _ReservedEventSlot extends StatelessWidget {
  const _ReservedEventSlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: kLayrzCalendarEventSlotHeight);
  }
}

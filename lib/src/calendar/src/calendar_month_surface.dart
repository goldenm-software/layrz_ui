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
/// list, the disabled predicate) and has no state of its own.
///
/// **Multi-day events render as one continuous bar per week row**, not as a
/// separate chip in every day cell they cross. Each week row is a [Stack]:
/// the ordinary [Row] of seven [LayrzCalendarDayCell]s underneath, and one
/// [Positioned] bar per multi-day [LayrzCalendarEntry] that intersects that
/// week on top, spanning from its start column to its end column (clamped to
/// the week's Monday–Sunday range). A bar that continues past a week's
/// boundary simply ends at that row and a second, independent bar segment
/// starts the following row — there is no arrow, chevron, or other
/// "continues" affordance connecting the two, a deliberate choice for this
/// pass. Single-day events are unaffected and still render as ordinary
/// per-cell chips via [LayrzCalendarDayCell.entries].
///
/// Bar vertical position and day-cell chip layout must never drift apart:
/// [LayrzCalendarDayCell.reservedMultiDaySlots] reserves one blank
/// [kLayrzCalendarEventSlotHeight]-tall slot per multi-day entry occupying a
/// given date, in the same order this surface assigns bar slot indices for
/// that week — see [_buildWeekRow] for how the two are kept in lockstep.
///
/// **Grid lines are painted by this surface, not by individual cells.** The
/// whole month grid is wrapped in a `Container` filled with
/// `tokens.colors.divider`, and every [LayrzCalendarDayCell] is inset by
/// `tokens.border.stroke1` on every side (see [_buildCell]); the container's
/// background then shows through each gap as a single, uniform grid line —
/// interior lines and the outer edge alike — rather than adjacent cells each
/// painting their own `Border.all` (which doubled the width of interior
/// lines). Each cell still paints its own opaque background so the divider
/// color only shows in the gaps, never bleeding through a cell's body. The
/// weekday header row is not part of this bordered container — it sits above
/// it, with no grid lines of its own.
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
          // Grid lines are painted by this container's own background color
          // showing through the gaps between cells, rather than each cell
          // painting its own `Border.all` -- adjacent cells used to each
          // paint a border, so interior lines were double-width while the
          // outer edge was single. Wrapping the grid in a divider-colored
          // container and insetting every cell by `tokens.border.stroke1` on
          // every side (see `_buildCell`) makes every line -- interior and
          // the outer edge alike -- exactly one `stroke1` wide, uniform by
          // construction. The weekday header row above stays outside this
          // container: it has no per-label backgrounds or grid lines of its
          // own, so it is not part of the bordered surface.
          child: Container(
            color: tokens.colors.divider,
            child: Column(
              children: [
                for (var week = 0; week < 6; week++)
                  Expanded(
                    child: _buildWeekRow(context, weekStart: gridStart, week: week, today: today),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds one week row as a [Stack]: the seven ordinary day cells
  /// underneath, plus one continuous [Positioned] bar per multi-day entry
  /// that intersects this week's Monday–Sunday range on top.
  ///
  /// Bar slot indices are assigned once here, per week, by sorting the
  /// week's intersecting multi-day entries by [LayrzCalendarEntry.start]
  /// (ties broken by title for a stable order). The same sorted list, capped
  /// the same way, is what determines
  /// [LayrzCalendarDayCell.reservedMultiDaySlots] for every date in the
  /// week -- so a bar at slot index `i` always lands on the `i`-th reserved
  /// blank slot of every cell it crosses, never on a slot reserved for a
  /// different event.
  Widget _buildWeekRow(
    BuildContext context, {
    required DateTime weekStart,
    required int week,
    required DateTime today,
  }) {
    final weekDates = [
      for (var day = 0; day < _kColumns; day++)
        DateTime(weekStart.year, weekStart.month, weekStart.day + week * _kColumns + day),
    ];
    final weekFirst = weekDates.first;
    final weekLast = weekDates.last;

    final multiDayInWeek =
        entries.where((entry) => entry.isMultiDay && weekDates.any(entry.occupies)).toList(growable: false)
          ..sort((a, b) {
            final byStart = a.start.compareTo(b.start);
            return byStart != 0 ? byStart : a.title.compareTo(b.title);
          });
    final visibleMultiDay = multiDayInWeek.take(kLayrzCalendarMaxVisibleEvents).toList(growable: false);

    return Stack(
      children: [
        Row(
          children: [
            for (final date in weekDates)
              Expanded(
                child: _buildCell(context, date: date, today: today, multiDayInWeek: visibleMultiDay),
              ),
          ],
        ),
        for (var slot = 0; slot < visibleMultiDay.length; slot++)
          _MultiDayBar(
            entry: visibleMultiDay[slot],
            slotIndex: slot,
            weekFirst: weekFirst,
            weekLast: weekLast,
            columns: _kColumns,
          ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required DateTime date,
    required DateTime today,
    required List<LayrzCalendarEntry> multiDayInWeek,
  }) {
    final tokens = context.tokens;
    final isOutsideMonth = date.month != focusedDate.month;
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isDisabled = isDateDisabled?.call(date) ?? false;

    final singleDayEntries = entries
        .where((entry) => !entry.isMultiDay && entry.occupies(date))
        .toList(growable: false);
    final multiDayOnDate = multiDayInWeek.where((entry) => entry.occupies(date)).length;
    final totalEventCount = singleDayEntries.length + entries.where((e) => e.isMultiDay && e.occupies(date)).length;

    // Insets every cell by `stroke1` on every side so the divider-colored
    // container behind this row shows through as a uniform grid line, both
    // between cells and around the grid's outer edge -- see the doc on
    // `build` for the full technique.
    return Padding(
      padding: EdgeInsets.all(tokens.border.stroke1),
      child: LayrzCalendarDayCell(
        date: date,
        isToday: isToday,
        isOutsideMonth: isOutsideMonth,
        isDisabled: isDisabled,
        entries: singleDayEntries,
        reservedMultiDaySlots: multiDayOnDate,
        totalEventCount: totalEventCount,
      ),
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

/// A single continuous bar segment for one multi-day [LayrzCalendarEntry],
/// spanning the columns it occupies within one week row.
///
/// Positioned with a [LayoutBuilder] against the week row's own width, so
/// its left edge and width are computed as exact fractions of
/// `availableWidth / columns` — the same column width every
/// [LayrzCalendarDayCell] in the underlying [Row] resolves to via its own
/// [Expanded]. Its vertical [top] offset is computed from the fixed
/// [kLayrzCalendarDateRowHeight] and [kLayrzCalendarEventSlotHeight]
/// constants (plus the cell's own outer padding) rather than measured, so it
/// lands exactly on the blank [LayrzCalendarDayCell.reservedMultiDaySlots]
/// slot reserved for it at [slotIndex] — see the class doc on
/// [LayrzCalendarMonthSurface] for why the two must stay in lockstep.
///
/// The label renders once, left-aligned within the visible span, never
/// repeated per day the bar crosses. There is no "continues" affordance at
/// either end when the bar is clipped by the week's boundary — a deliberate
/// choice for this pass (see the class doc).
///
/// Renders **filled**, identically to `_EventChip` in `calendar_day_cell.dart`
/// for the same accent color: a full-opacity background with
/// [Color.contrastColor] text, no border. A single-day event and a
/// multi-day bar of the same color must look like the same component.
class _MultiDayBar extends StatelessWidget {
  const _MultiDayBar({
    required this.entry,
    required this.slotIndex,
    required this.weekFirst,
    required this.weekLast,
    required this.columns,
  });

  /// The multi-day event this bar represents.
  final LayrzCalendarEntry entry;

  /// This bar's vertical slot within the week row's event area, shared with
  /// [LayrzCalendarDayCell.reservedMultiDaySlots] ordering.
  final int slotIndex;

  /// The first (Monday) date of the week row this bar is painted in.
  final DateTime weekFirst;

  /// The last (Sunday) date of the week row this bar is painted in.
  final DateTime weekLast;

  /// The number of day columns in the grid (always 7).
  final int columns;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = entry.color ?? tokens.colors.info.shade500;
    final contentColor = color.contrastColor;

    // Clamp the entry's actual start/end to this week's visible range --
    // an entry that starts before this week or ends after it still only
    // paints the portion this row can show; the remainder is a separate,
    // independently-clamped bar in the adjacent week row(s).
    final visibleStart = entry.start.isBefore(weekFirst)
        ? weekFirst
        : DateTime(entry.start.year, entry.start.month, entry.start.day);
    final visibleEnd = entry.end.isAfter(weekLast)
        ? weekLast
        : DateTime(entry.end.year, entry.end.month, entry.end.day);
    final startColumn = visibleStart.difference(weekFirst).inDays;
    final endColumn = visibleEnd.difference(weekFirst).inDays;

    // `tokens.border.stroke1` accounts for the outer grid-line gap
    // `LayrzCalendarMonthSurface._buildCell` now wraps every cell in (see
    // that method's doc); the rest of the offset matches
    // `LayrzCalendarDayCell`'s own internal padding and date-row layout
    // pixel-for-pixel, unaffected by the new outer inset.
    final top =
        tokens.border.stroke1 +
        tokens.spacing.sp1 +
        kLayrzCalendarDateRowHeight +
        tokens.spacing.sp1 +
        slotIndex * kLayrzCalendarEventSlotHeight;

    return Positioned(
      top: top,
      height: kLayrzCalendarEventSlotHeight,
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / columns;
          // Matches the cell's own outer grid-line inset (`stroke1`) plus
          // its internal padding (`sp1`), so the bar's edges land flush with
          // the chip padding inside the now-inset cell -- see the `top`
          // comment above for the same reasoning applied vertically.
          final cellHorizontalInset = tokens.border.stroke1 + tokens.spacing.sp1;

          return Padding(
            padding: EdgeInsets.only(
              left: startColumn * columnWidth + cellHorizontalInset,
              right: (columns - 1 - endColumn) * columnWidth + cellHorizontalInset,
            ),
            child: ExcludeSemantics(
              // Not itself a Semantics boundary -- LayrzCalendarDayCell
              // already announces this event once per date it occupies
              // via `totalEventCount`; a second, separate announcement
              // here would double up on top of that per-cell label.
              child: Container(
                margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(tokens.radius.r1),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.typography.label.copyWith(color: contentColor, fontSize: 10),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

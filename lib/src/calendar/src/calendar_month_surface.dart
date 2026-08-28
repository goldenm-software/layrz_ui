import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'calendar_day_cell.dart';
import 'calendar_entry.dart';
import 'calendar_event_lane.dart';
import 'calendar_style_spec.dart';
import 'calendar_weekdays.dart';
import 'calendar_week_gutter.dart';

/// The number of weekday columns a month grid always renders.
const int _kColumns = 7;

/// The text style the weekday header row's labels render in: full
/// `tokens.typography.title`, coloured [LayrzColorTokens.fg2] — one step
/// below the day numbers' full-strength `fg1`, since a header label is
/// secondary to the actual dates underneath it, but no longer `fg3`'s
/// washed-out grey.
///
/// **Deliberately NOT [titleWeightedBodyStyle]** — that composition is for
/// the day numbers only (Kenny: "titleStyle is too big for the days on
/// month mode, let's use the body style, but inherit the title weight and
/// features"). He named "the days" specifically; this header row has not
/// drawn the same complaint and stays at full `title`, so month view's
/// header and week view's own `title`-styled column-header date numbers
/// (`calendar_week_surface.dart`, untouched by this file) keep reading as
/// the same visual weight of heading.
TextStyle _headerTextStyle(LayrzTokens tokens) => tokens.typography.title.copyWith(color: tokens.colors.fg2);

/// Returns the rendered height of the header row's own text, measured via
/// [TextPainter] against [_headerTextStyle] rather than a hand-tuned literal.
///
/// **Why measured, not a constant.** A prior version of this file hardcoded
/// the header row's total height (`28`, then `34` after the header's
/// typography changed) and it clipped the header text in production — the
/// box was sized against padding arithmetic that double-subtracted the
/// vertical padding it was meant to reserve, and nobody could notice locally
/// because [Text] clips silently rather than throwing the debug overflow
/// banner [Column]/[Row] do. A literal has to be manually re-derived every
/// time [_headerTextStyle] changes; measuring it removes that failure mode
/// entirely. Both [build] (sizing the header row's own [SizedBox]) and
/// [LayrzCalendarWeekGutter]'s leading blank spacer read this same function,
/// so the gutter's week-number cells stay aligned with the grid's week rows
/// regardless of what the header row's typography does in the future.
///
/// The measured character is `'Sun'` — any of the seven weekday abbreviations
/// share the same [_headerTextStyle], so the letters chosen do not affect the
/// resulting height; `'Sun'` is simply always present regardless of
/// [firstDayOfWeek].
double _headerTextHeightOf(LayrzTokens tokens) {
  final painter = TextPainter(
    text: TextSpan(text: 'Sun', style: _headerTextStyle(tokens)),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.height;
}

/// The layout surface for [LayrzCalendarMode.month]: a full month grid, one
/// row per week, seven columns ordered from [firstDayOfWeek], with leading
/// and trailing days from the adjacent months filling out the first and last
/// rows so the grid is always a rectangle.
///
/// This is a pure layout surface in the `LayrzStepper` template sense — it
/// receives already-resolved data (the month to render, the full entry
/// list, the disabled predicate) and has no state of its own.
///
/// **The grid always renders 6 rows regardless of [firstDayOfWeek].** The
/// grid-start formula `(firstOfMonth.weekday - firstDayOfWeek + 7) % 7` is
/// verified equivalent to the fixed Monday-first formula when
/// `firstDayOfWeek == DateTime.monday`, and correct for all seven values —
/// the fixed 6-row × 7-column grid (42 cells) always suffices; see
/// [_gridStart].
///
/// **Multi-day events render as one continuous bar per week row**, not as a
/// separate chip in every day cell they cross. Each week row is a [Stack]:
/// the ordinary [Row] of seven [LayrzCalendarDayCell]s underneath, and one
/// [Positioned] bar per multi-day [LayrzCalendarEntry] that intersects that
/// week on top, spanning from its start column to its end column (clamped to
/// the week's configured start/end range). A bar that continues past a
/// week's boundary simply ends at that row and a second, independent bar
/// segment starts the following row — there is no arrow, chevron, or other
/// "continues" affordance connecting the two, a deliberate choice for this
/// pass. Single-day events are unaffected and still render as ordinary
/// per-cell chips via [LayrzCalendarDayCell.entries].
///
/// **Multi-day bar lane assignment is stable for the whole month**, computed
/// once via [assignLanes] (`calendar_event_lane.dart`) rather than re-derived
/// per week row — an entry keeps the same lane index across every week row it
/// spans. This can leave blank reserved lanes above real content on a sparse
/// week; that is expected and correct under per-month stability, not a bug to
/// "fix" by switching to per-week packing.
///
/// **The visible event cap is measured, not fixed.** Each week row wraps
/// itself in a single [LayoutBuilder] (not one per cell — see
/// [_buildWeekRow]'s doc for why) to compute `maxSlots =
/// (availableHeight / kLayrzCalendarEventSlotHeight).floor()`, applied to
/// both this surface's own multi-day bar cap and every
/// [LayrzCalendarDayCell]'s chip cap in that row, so the two never diverge.
///
/// Bar vertical position and day-cell chip layout must never drift apart:
/// [LayrzCalendarDayCell.reservedLaneIndices] reserves one blank
/// [kLayrzCalendarEventSlotHeight]-tall slot per lane index occupying a given
/// date, matching the lane indices this surface assigns bars — see
/// [_buildWeekRow] for how the two are kept in lockstep.
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
///
/// **The optional [LayrzCalendarWeekGutter] is composed OUTSIDE this whole
/// layout, as a leading sibling in an outer [Row] -- never inside the week
/// row's [Stack].** `_MultiDayBar`'s `columnWidth = constraints.maxWidth / 7`
/// and the day-cell [Row] are both measured against that [Stack]'s own
/// constraints; a gutter placed inside it would silently narrow `maxWidth`
/// for both, shifting and mis-sizing every multi-day bar while the
/// [Expanded] day cells kept looking correct. See [LayrzCalendarWeekGutter]'s
/// class doc for the full reasoning. The gutter reserves
/// [kLayrzCalendarWeekGutterWidth] of its own leading space plus a blank
/// spacer matching the weekday-header row's own MEASURED height (see
/// [_headerTextHeightOf]), so its week-number cells land aligned with the
/// grid's week rows rather than the header.
class LayrzCalendarMonthSurface extends StatelessWidget {
  /// Creates a [LayrzCalendarMonthSurface].
  const LayrzCalendarMonthSurface({
    required this.focusedDate,
    required this.entries,
    this.isDateDisabled,
    this.firstDayOfWeek = DateTime.sunday,
    this.onOverflowTap,
    this.dayNumberOpensDayView = true,
    this.onDateNumberTap,
    this.showWeekNumbers = true,
    this.onWeekNumberTap,
    this.onTap,
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

  /// The weekday the grid's columns and header row start from.
  ///
  /// One of `DateTime.monday` (1) through `DateTime.sunday` (7). Defaults to
  /// `DateTime.sunday`, matching [LayrzCalendar]'s default — **this changed
  /// pass 1's shipped behaviour**, which hardcoded a Monday-first grid; pass
  /// `firstDayOfWeek: DateTime.monday` to restore the previous grid.
  final int firstDayOfWeek;

  /// Called when a cell's overflow ("+N") chip is tapped, with the tapped
  /// date. Forwarded unchanged to every [LayrzCalendarDayCell] in the grid;
  /// see [LayrzCalendarDayCell.onOverflowTap].
  final void Function(DateTime date)? onOverflowTap;

  /// Whether tapping a cell's day-of-month number navigates to day view for
  /// that date. Forwarded unchanged to every [LayrzCalendarDayCell] in the
  /// grid; see [LayrzCalendarDayCell.dayNumberOpensDayView]. Defaults to
  /// `true`.
  final bool dayNumberOpensDayView;

  /// Called when a cell's day-of-month number is tapped, with the tapped
  /// date. Forwarded unchanged to every [LayrzCalendarDayCell] in the grid;
  /// see [LayrzCalendarDayCell.onDateNumberTap].
  final void Function(DateTime date)? onDateNumberTap;

  /// Whether a [LayrzCalendarWeekGutter] renders to the left of the grid,
  /// showing each week row's ISO 8601 week number.
  ///
  /// Defaults to `true`. See [LayrzCalendarWeekGutter]'s class doc for the
  /// numbering rule and why the gutter is composed outside the grid's own
  /// [Stack] rather than inside it.
  final bool showWeekNumbers;

  /// Called with a week row's first date when its [LayrzCalendarWeekGutter]
  /// number is tapped. Has no effect when [showWeekNumbers] is `false`.
  ///
  /// `LayrzCalendar` wires this to jump to that date and switch to
  /// [LayrzCalendarMode.week], mirroring [onOverflowTap]'s day-view
  /// navigation. Null renders every week number inert.
  final void Function(DateTime weekStart)? onWeekNumberTap;

  /// Called when a cell's body is tapped anywhere that is not the date
  /// number, the "+N" overflow chip, or an event chip, with that date
  /// already normalized to midnight by `LayrzCalendar`. Forwarded unchanged
  /// to every [LayrzCalendarDayCell] in the grid; see
  /// [LayrzCalendarDayCell.onTap].
  ///
  /// Tapping an event chip or multi-day bar never calls this — it fires
  /// that entry's own [LayrzCalendarEntry.onTap] instead; there is no
  /// entry-tap callback on this surface.
  final void Function(DateTime date)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = LayrzUiL10n.of(context);
    final weekdayLabels = orderedWeekdayLabels(l10n, firstDayOfWeek);

    final today = DateTime.now();
    final gridStart = _gridStart(focusedDate, firstDayOfWeek);
    final laneAssignments = assignLanes(entries: entries, monthAnchor: focusedDate);

    // Sized to the header text's own measured height plus `sp1` padding on
    // both sides -- see `_headerTextHeightOf`'s doc for why this is computed
    // rather than a hand-tuned literal (the header text clipped in
    // production against the previous hardcoded constant, whose arithmetic
    // double-subtracted the vertical padding it was meant to reserve).
    final headerTextHeight = _headerTextHeightOf(tokens);
    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerTextHeight + tokens.spacing.sp1 * 2,
          child: Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp1),
                    child: Text(
                      label.substring(0, label.length.clamp(0, 3)),
                      textAlign: TextAlign.center,
                      style: _headerTextStyle(tokens),
                    ),
                  ),
                ),
            ],
          ),
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
                    child: _buildWeekRow(
                      context,
                      weekStart: gridStart,
                      week: week,
                      today: today,
                      laneAssignments: laneAssignments,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!showWeekNumbers) return grid;

    // The gutter is composed as a leading sibling in this outer `Row`,
    // entirely outside the `grid` column above -- see the class doc's
    // "optional LayrzCalendarWeekGutter" section for why it must never sit
    // inside the week row's `Stack`. The blank spacer here matches the
    // weekday header row's own measured height (`headerTextHeight +
    // sp1 * 2`) plus the `sp1` gap before the grid body -- the same two
    // pieces `grid`'s own `Column` above stacks -- so the gutter's
    // week-number cells land aligned with the grid's week rows, not the
    // header. See `_headerTextHeightOf`'s doc for why this is measured
    // rather than a hand-tuned literal.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: headerTextHeight + tokens.spacing.sp1 * 3,
            right: tokens.spacing.sp1,
          ),
          child: LayrzCalendarWeekGutter(
            weekStarts: [
              for (var week = 0; week < 6; week++)
                DateTime(gridStart.year, gridStart.month, gridStart.day + week * _kColumns),
            ],
            onWeekTap: onWeekNumberTap,
          ),
        ),
        Expanded(child: grid),
      ],
    );
  }

  /// Builds one week row as a [Stack]: the seven ordinary day cells
  /// underneath, plus one continuous [Positioned] bar per multi-day entry
  /// that intersects this week's date range on top.
  ///
  /// **Wrapped in exactly one [LayoutBuilder] for the whole row, not one per
  /// cell.** The visible-event cap must be applied in two places — this
  /// method's own bar cap, and every [LayrzCalendarDayCell]'s chip cap — and
  /// the bars are painted in this same [Stack] before any per-cell
  /// [LayoutBuilder] could run, so a cell-level measurement would arrive too
  /// late to bound the bars: the two caps would diverge and a bar could land
  /// on a slot no cell reserved. All seven cells in a row are [Expanded]
  /// siblings of identical height, so one row-level measurement is correct
  /// for every cell in it and is available before the bar cap is computed —
  /// six [LayoutBuilder]s total for the grid, not forty-two.
  ///
  /// Bar lane indices come from [laneAssignments] (per-month stable, see the
  /// class doc), not from a per-week sort — the same lane indices this method
  /// paints bars at are what [LayrzCalendarDayCell.reservedLaneIndices]
  /// reserves for every date in the week, so a bar at lane `i` always lands
  /// on the `i`-th reserved blank slot of every cell it crosses.
  Widget _buildWeekRow(
    BuildContext context, {
    required DateTime weekStart,
    required int week,
    required DateTime today,
    required LayrzCalendarLaneAssignments laneAssignments,
  }) {
    final weekDates = [
      for (var day = 0; day < _kColumns; day++)
        DateTime(weekStart.year, weekStart.month, weekStart.day + week * _kColumns + day),
    ];
    final weekFirst = weekDates.first;
    final weekLast = weekDates.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.tokens;
        // `constraints.maxHeight` is the row's own height; a day cell's
        // usable event space is smaller than that by: the outer grid-line
        // inset `_buildCell` wraps every cell in (`stroke1` on every side,
        // so `stroke1 * 2` vertically), the cell's own internal padding
        // (`sp1` on every side, `sp1 * 2` vertically), the fixed date-number
        // row, and the `sp1` gap between the date row and the event slots.
        final availableHeight =
            constraints.maxHeight -
            (tokens.border.stroke1 * 2) -
            (tokens.spacing.sp1 * 2) -
            kLayrzCalendarDateRowHeight -
            tokens.spacing.sp1;
        final maxSlots = (availableHeight / kLayrzCalendarEventSlotHeight).floor().clamp(0, 1 << 30);

        // Every lane index touched on any day of this week, in ascending
        // order -- this is the row's own bar cap, capacity-limited the same
        // way each cell's chip cap is, so the surface and the cells never
        // disagree about how many multi-day bars this row can show.
        final laneIndicesThisWeek = <int>{};
        for (final date in weekDates) {
          laneIndicesThisWeek.addAll(laneAssignments.occupiedLanesOn(date));
        }
        final sortedLanes = laneIndicesThisWeek.toList()..sort();
        final visibleLanes = sortedLanes.take(maxSlots).toSet();

        return Stack(
          children: [
            Row(
              children: [
                for (final date in weekDates)
                  Expanded(
                    child: _buildCell(
                      context,
                      date: date,
                      today: today,
                      laneAssignments: laneAssignments,
                      visibleLanes: visibleLanes,
                      maxSlots: maxSlots,
                    ),
                  ),
              ],
            ),
            for (final lane in visibleLanes)
              if (laneAssignments.entryAt(date: weekFirst, lane: lane) != null ||
                  weekDates.any((d) => laneAssignments.entryAt(date: d, lane: lane) != null))
                ..._barsForLane(
                  lane: lane,
                  weekDates: weekDates,
                  weekFirst: weekFirst,
                  weekLast: weekLast,
                  laneAssignments: laneAssignments,
                ),
          ],
        );
      },
    );
  }

  /// Returns one [_MultiDayBar] per distinct entry occupying [lane] within
  /// [weekDates] — ordinarily exactly one, since per-month lane stability
  /// means a single entry owns a lane for as long as it appears in a given
  /// week, but this guards against two different entries ever sharing a lane
  /// within the same week (which [assignLanes] never produces, but this
  /// method does not assume it).
  List<Widget> _barsForLane({
    required int lane,
    required List<DateTime> weekDates,
    required DateTime weekFirst,
    required DateTime weekLast,
    required LayrzCalendarLaneAssignments laneAssignments,
  }) {
    final seen = <LayrzCalendarEntry>{};
    final bars = <Widget>[];
    for (final date in weekDates) {
      final entry = laneAssignments.entryAt(date: date, lane: lane);
      if (entry == null || !seen.add(entry)) continue;
      bars.add(
        _MultiDayBar(
          entry: entry,
          slotIndex: lane,
          weekFirst: weekFirst,
          weekLast: weekLast,
          columns: _kColumns,
        ),
      );
    }
    return bars;
  }

  Widget _buildCell(
    BuildContext context, {
    required DateTime date,
    required DateTime today,
    required LayrzCalendarLaneAssignments laneAssignments,
    required Set<int> visibleLanes,
    required int maxSlots,
  }) {
    final tokens = context.tokens;
    final isOutsideMonth = date.month != focusedDate.month;
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final isDisabled = isDateDisabled?.call(date) ?? false;

    final singleDayEntries = entries
        .where((entry) => !entry.isMultiDay && entry.occupies(date))
        .toList(growable: false);
    final reservedLaneIndices = laneAssignments.occupiedLanesOn(date).intersection(visibleLanes);
    final totalMultiDayOnDate = entries.where((e) => e.isMultiDay && e.occupies(date)).length;
    final totalEventCount = singleDayEntries.length + totalMultiDayOnDate;

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
        reservedLaneIndices: reservedLaneIndices,
        totalEventCount: totalEventCount,
        maxVisibleSlots: maxSlots,
        onOverflowTap: onOverflowTap,
        dayNumberOpensDayView: dayNumberOpensDayView,
        onDateNumberTap: onDateNumberTap,
        onTap: onTap,
      ),
    );
  }

  /// Returns the first day of the configured week ([firstDayOfWeek]) that
  /// starts the first full week rendered by the grid — always on or before
  /// the 1st of [focusedDate]'s month.
  ///
  /// Generalizes pass 1's Monday-only formula
  /// (`firstOfMonth.weekday - DateTime.monday`) to
  /// `(firstOfMonth.weekday - firstDayOfWeek + 7) % 7`, verified equivalent
  /// to the original at `firstDayOfWeek == DateTime.monday` and correct for
  /// all seven values — the fixed 6-row grid (42 cells) still suffices for
  /// every month under every first-day choice.
  static DateTime _gridStart(DateTime focusedDate, int firstDayOfWeek) {
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month);
    final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
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
/// lands exactly on the blank [LayrzCalendarDayCell.reservedLaneIndices]
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
///
/// **[LayrzCalendarEntry.isPreview] ghosts this bar** identically to
/// `_EventChip`'s own preview treatment — reduced-opacity fill, an outline
/// substituted for the solid background, the entry's own color kept — with
/// no geometry change (decision D15): a preview bar occupies exactly the
/// span and lane it would occupy once committed.
///
/// **Interactive when [LayrzCalendarEntry.onTap] is non-null**: hover and
/// pointer cursor, varying only colour per D15. Consumed above
/// [LayrzCalendarDayCell]'s own cell-body detector, so a tap on this bar
/// never also fires the covered cells' `onTap`.
class _MultiDayBar extends StatefulWidget {
  const _MultiDayBar({
    required this.entry,
    required this.slotIndex,
    required this.weekFirst,
    required this.weekLast,
    required this.columns,
  });

  /// The multi-day event this bar represents. Its own
  /// [LayrzCalendarEntry.onTap] drives this bar's interactivity — there is
  /// no separate callback parameter here.
  final LayrzCalendarEntry entry;

  /// This bar's vertical slot within the week row's event area, shared with
  /// [LayrzCalendarDayCell.reservedLaneIndices] ordering.
  final int slotIndex;

  /// The first date of the week row this bar is painted in, per the
  /// configured [LayrzCalendarMonthSurface.firstDayOfWeek].
  final DateTime weekFirst;

  /// The last date of the week row this bar is painted in, per the
  /// configured [LayrzCalendarMonthSurface.firstDayOfWeek].
  final DateTime weekLast;

  /// The number of day columns in the grid (always 7).
  final int columns;

  @override
  State<_MultiDayBar> createState() => _MultiDayBarState();
}

class _MultiDayBarState extends State<_MultiDayBar> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entry = widget.entry;
    final weekFirst = widget.weekFirst;
    final weekLast = widget.weekLast;
    final columns = widget.columns;
    final slotIndex = widget.slotIndex;
    final isInteractive = entry.onTap != null;
    final color = entry.color ?? tokens.colors.info.shade500;
    final contentColor = entry.isPreview ? color : color.contrastColor;

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

          final bar = Container(
            margin: EdgeInsets.only(bottom: tokens.spacing.sp1 / 2),
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
            decoration: entry.isPreview
                ? BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: isInteractive && _isHovered ? 0.9 : 0.6)),
                    borderRadius: BorderRadius.circular(tokens.radius.r1),
                  )
                : BoxDecoration(
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
          );

          // Not itself a Semantics boundary when non-interactive --
          // LayrzCalendarDayCell already announces this event once per date
          // it occupies via `totalEventCount`; a second, separate
          // announcement here would double up on top of that per-cell
          // label. When interactive, a dedicated node is needed so the
          // entry's own `onTap` is reachable as a semantics action too.
          final content = isInteractive
              ? Semantics(
                  button: true,
                  enabled: true,
                  label: entry.title,
                  onTap: entry.onTap,
                  child: ExcludeSemantics(child: bar),
                )
              : ExcludeSemantics(child: bar);

          final tappableBar = !isInteractive
              ? content
              : MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _setHovered(true),
                  onExit: (_) => _setHovered(false),
                  child: GestureDetector(onTap: entry.onTap, child: content),
                );

          return Padding(
            padding: EdgeInsets.only(
              left: startColumn * columnWidth + cellHorizontalInset,
              right: (columns - 1 - endColumn) * columnWidth + cellHorizontalInset,
            ),
            child: tappableBar,
          );
        },
      ),
    );
  }
}

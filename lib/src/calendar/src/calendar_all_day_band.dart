import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'calendar_day_surface.dart' show kLayrzCalendarHourAxisWidth;
import 'calendar_entry.dart';
import 'calendar_event_lane.dart';

/// The shared all-day/multi-day band rendered across the top of
/// [LayrzCalendarWeekSurface] (spanning all seven columns) and
/// [LayrzCalendarDaySurface] (spanning its single column).
///
/// **Renders one continuous bar per multi-day entry, never one chip per
/// occupied column.** A multi-day entry spanning three of [columnDates]
/// paints as a single [Positioned] bar three columns wide, matching how
/// `_MultiDayBar` collapses a multi-day event in
/// `LayrzCalendarMonthSurface` — a bar that reads as one continuous shape in
/// month view and as N repeated titles here would make the same event look
/// like several to anyone switching between the two modes. Lane indices are
/// computed once via [assignBandLanes] and shared between the bar's vertical
/// slot and this band's own row height, the same lockstep
/// [LayrzCalendarMonthSurface] keeps between its bars and
/// [LayrzCalendarDayCell.reservedLaneIndices].
///
/// **Scoped to [columnDates]' own range, not the month.** This is the
/// correct narrower application of [calendar_event_lane.dart]'s greedy
/// interval-coloring algorithm, not a reversal of that module's per-month
/// stability ruling: per-month stability exists so one entry's lane does not
/// jump between week *rows within a single month view*, a concern that does
/// not arise here because only one week (or one day) is ever visible in this
/// band at once. [assignLanes] itself stays month-anchored and untouched;
/// [assignBandLanes] is a sibling pure function for this band's narrower
/// range.
class AllDayBand extends StatelessWidget {
  /// Creates an [AllDayBand].
  const AllDayBand({required this.columnDates, required this.entries, super.key});

  /// The dates each column of the band corresponds to, left to right.
  ///
  /// Exactly one date for [LayrzCalendarDaySurface]'s single column, or seven
  /// consecutive dates for [LayrzCalendarWeekSurface]'s week.
  final List<DateTime> columnDates;

  /// The full multi-day entry list to place within [columnDates]' range.
  ///
  /// Entries that do not intersect [columnDates] are ignored; an entry that
  /// starts before or ends after the visible range still renders, clamped to
  /// the portion of it that falls within [columnDates]. Each bar's own
  /// [LayrzCalendarEntry.onTap] drives its interactivity — there is no
  /// separate entry-tap callback on this widget.
  final List<LayrzCalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final rangeStart = columnDates.first;
    final rangeEnd = columnDates.last;
    final laneAssignments = assignBandLanes(entries: entries, rangeStart: rangeStart, rangeEnd: rangeEnd);
    final laneCount = laneAssignments.laneCount;
    final columns = columnDates.length;

    return SizedBox(
      height: laneCount * kLayrzCalendarAllDayRowHeight,
      child: Stack(
        children: [
          Row(
            children: [
              SizedBox(width: columns > 1 ? kLayrzCalendarHourAxisWidth : 0),
              for (var i = 0; i < columns; i++) const Expanded(child: SizedBox.shrink()),
            ],
          ),
          for (final assignment in laneAssignments.assignments)
            _AllDayBar(
              entry: assignment.entry,
              lane: assignment.lane,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              columns: columns,
              hasHourAxis: columns > 1,
            ),
        ],
      ),
    );
  }
}

/// One continuous bar segment for one multi-day [LayrzCalendarEntry] within
/// [AllDayBand], spanning the columns it occupies within [rangeStart]..
/// [rangeEnd].
///
/// Mirrors `_MultiDayBar` in `calendar_month_surface.dart`: a single label,
/// never repeated per column crossed, clamped at either end when the entry
/// starts before [rangeStart] or ends after [rangeEnd].
///
/// **[LayrzCalendarEntry.isPreview] ghosts this bar** the same way
/// `_MultiDayBar`'s preview treatment does: reduced-opacity fill, an outline
/// substituted for the solid background, the entry's own color kept, no
/// geometry change. **Interactive when [LayrzCalendarEntry.onTap] is
/// non-null**: hover and pointer cursor, colour-only per D15.
class _AllDayBar extends StatefulWidget {
  const _AllDayBar({
    required this.entry,
    required this.lane,
    required this.rangeStart,
    required this.rangeEnd,
    required this.columns,
    required this.hasHourAxis,
  });

  /// The multi-day event this bar represents. Its own
  /// [LayrzCalendarEntry.onTap] drives this bar's interactivity — there is
  /// no separate callback parameter here.
  final LayrzCalendarEntry entry;

  /// This bar's vertical lane within the band, shared with every other bar
  /// occupying the same date range.
  final int lane;

  /// The first date of [AllDayBand.columnDates].
  final DateTime rangeStart;

  /// The last date of [AllDayBand.columnDates].
  final DateTime rangeEnd;

  /// The number of day columns the band renders.
  final int columns;

  /// Whether the band reserves a leading [kLayrzCalendarHourAxisWidth]
  /// column for the shared hour axis, as [LayrzCalendarWeekSurface] does.
  /// False for [LayrzCalendarDaySurface]'s single-column band, which has no
  /// axis to the left of it.
  final bool hasHourAxis;

  @override
  State<_AllDayBar> createState() => _AllDayBarState();
}

class _AllDayBarState extends State<_AllDayBar> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entry = widget.entry;
    final rangeStart = widget.rangeStart;
    final rangeEnd = widget.rangeEnd;
    final columns = widget.columns;
    final isInteractive = entry.onTap != null;
    final color = entry.color ?? tokens.colors.info.shade500;
    final contentColor = entry.isPreview ? color : color.contrastColor;

    final visibleStart = entry.start.isBefore(rangeStart)
        ? rangeStart
        : DateTime(entry.start.year, entry.start.month, entry.start.day);
    final visibleEnd = entry.end.isAfter(rangeEnd)
        ? rangeEnd
        : DateTime(entry.end.year, entry.end.month, entry.end.day);
    final startColumn = visibleStart.difference(rangeStart).inDays;
    final endColumn = visibleEnd.difference(rangeStart).inDays;

    return Positioned(
      top: widget.lane * kLayrzCalendarAllDayRowHeight,
      height: kLayrzCalendarAllDayRowHeight - tokens.spacing.sp1 / 2,
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final axisWidth = widget.hasHourAxis ? kLayrzCalendarHourAxisWidth : 0.0;
          final columnWidth = (constraints.maxWidth - axisWidth) / columns;

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
            child: SelectionContainer.disabled(
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tokens.typography.label.copyWith(color: contentColor, fontSize: 10),
              ),
            ),
          );

          final content = isInteractive
              ? Semantics(
                  button: true,
                  enabled: true,
                  label: entry.title,
                  onTap: entry.onTap,
                  child: ExcludeSemantics(child: bar),
                )
              : bar;

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
              left: axisWidth + startColumn * columnWidth + tokens.spacing.sp1 / 2,
              right: (columns - 1 - endColumn) * columnWidth + tokens.spacing.sp1 / 2,
            ),
            child: tappableBar,
          );
        },
      ),
    );
  }
}

/// The fixed height of one row within [AllDayBand], including its bottom
/// margin.
const double kLayrzCalendarAllDayRowHeight = 22;

/// Packs [entries] into stable lane indices for the date range
/// [rangeStart]..[rangeEnd] inclusive, so overlapping multi-day bars within
/// [AllDayBand] never collide.
///
/// **Sibling to [assignLanes], not a replacement for it.** [assignLanes]
/// stays month-anchored for [LayrzCalendarMonthSurface], per that module's
/// per-month lane stability ruling. This function applies the same
/// greedy-interval-coloring algorithm to an arbitrary range instead, which is
/// the correct scope for a band that only ever shows one week (or one day) at
/// a time — there is no "jumps between rows within one view" concern to
/// guard against here, because only one row is ever visible.
///
/// [entries] may contain single-day entries; they are ignored, matching
/// [assignLanes]. Only entries intersecting [rangeStart]..[rangeEnd] are
/// packed; an entry that starts before the range and/or ends after it is
/// still packed and still keeps one lane for its entire visible span within
/// the range.
///
/// **Algorithm and determinism**: identical in shape to [assignLanes] --
/// entries sorted by [LayrzCalendarEntry.start] ascending, ties broken by
/// [LayrzCalendarEntry.title], each assigned the lowest-numbered lane not
/// already occupied by a previously-assigned overlapping entry. Deterministic
/// for a fixed [entries] list and range.
LayrzCalendarLaneAssignments assignBandLanes({
  required List<LayrzCalendarEntry> entries,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

  final candidates =
      entries
          .where((entry) {
            if (!entry.isMultiDay) return false;
            final entryStart = DateTime(entry.start.year, entry.start.month, entry.start.day);
            final entryEnd = DateTime(entry.end.year, entry.end.month, entry.end.day);
            return !entryEnd.isBefore(start) && !entryStart.isAfter(end);
          })
          .toList(growable: false)
        ..sort((a, b) {
          final byStart = a.start.compareTo(b.start);
          return byStart != 0 ? byStart : a.title.compareTo(b.title);
        });

  final assignments = <LayrzCalendarLaneAssignment>[];
  // Per-lane list of the [start, end] date ranges already assigned to it, so
  // a new entry can be tested for overlap against every lane in O(lanes so
  // far) without re-deriving ranges from `assignments` each time -- mirrors
  // [assignLanes]'s own bookkeeping.
  final laneRanges = <int, List<(DateTime start, DateTime end)>>{};

  for (final entry in candidates) {
    final entryStart = DateTime(entry.start.year, entry.start.month, entry.start.day);
    final entryEnd = DateTime(entry.end.year, entry.end.month, entry.end.day);

    var lane = 0;
    while (true) {
      final ranges = laneRanges[lane];
      final overlaps = ranges != null && ranges.any((r) => !entryStart.isAfter(r.$2) && !entryEnd.isBefore(r.$1));
      if (!overlaps) break;
      lane++;
    }

    assignments.add(LayrzCalendarLaneAssignment(entry: entry, lane: lane));
    (laneRanges[lane] ??= []).add((entryStart, entryEnd));
  }

  return LayrzCalendarLaneAssignments(assignments);
}

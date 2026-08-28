/// Pure lane-assignment functions for multi-day [LayrzCalendarEntry] bars.
///
/// **No widgets, no `BuildContext`, no `package:flutter/widgets.dart` import
/// — deliberately.** This file is consumed by `LayrzCalendarMonthSurface`
/// (and, per-day, by the week view's all-day band) purely for the lane
/// *index* each multi-day entry should render on; every pixel decision stays
/// in the widget layer. Keeping this pure is what makes lane packing
/// unit-testable with plain `test()` and keeps the already-367-line month
/// surface file from growing past the one-concern split threshold.
///
/// **The ruling this module implements is per-MONTH lane stability, not
/// per-week.** An entry keeps exactly one lane index across every week row it
/// spans, computed once from its own start/end dates intersected with the
/// visible month — never re-derived per week row, and never dependent on
/// where the configured first day of the week falls. A bar that jumped lanes
/// between week rows would make one continuous event read as two different
/// events, which is a correctness defect, not a density tradeoff.
///
/// **Accepted cost, by design: sparse weeks can show blank reserved lanes
/// above real content.** For example an entry sitting in lane 2 while lanes 0
/// and 1 are empty on a given day, because those lower lanes are reserved for
/// other entries that occupy that day in a different week of the same month.
/// This is expected and correct under per-month stability — do not "fix" it
/// by switching to per-week packing, which would silently reverse the
/// decision this module exists to implement.
library;

import 'package:flutter/foundation.dart' show immutable;

import 'calendar_entry.dart';

/// The lane assignment produced for one multi-day [LayrzCalendarEntry] by
/// [assignLanes].
///
/// Carries the entry back alongside its lane index so a caller iterating
/// [LayrzCalendarLaneAssignments.assignments] does not need a separate lookup
/// to recover which entry a lane index belongs to.
@immutable
class LayrzCalendarLaneAssignment {
  /// Creates a [LayrzCalendarLaneAssignment].
  const LayrzCalendarLaneAssignment({required this.entry, required this.lane});

  /// The multi-day entry this assignment describes.
  final LayrzCalendarEntry entry;

  /// The zero-based lane index [entry] occupies for the whole month, stable
  /// across every week row it spans.
  final int lane;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LayrzCalendarLaneAssignment && entry == other.entry && lane == other.lane;

  @override
  int get hashCode => Object.hash(entry, lane);

  @override
  String toString() => 'LayrzCalendarLaneAssignment(entry: ${entry.title}, lane: $lane)';
}

/// The result of packing a month's multi-day [LayrzCalendarEntry] list into
/// lanes via [assignLanes].
///
/// This is the richer shape `LayrzCalendarDayCell.reservedMultiDaySlots`
/// needs: real lane packing produces sparse per-day occupancy (lane 2
/// occupied while lanes 0 and 1 are free on that day), which a bare `int`
/// count cannot represent. [occupiedLanesOn] answers "which lane indices are
/// reserved on this date" so a day cell can render the right number of blank
/// reserved slots *and* leave the right gaps between real chips, rather than
/// stacking every reservation at the top of the cell.
class LayrzCalendarLaneAssignments {
  /// Creates a [LayrzCalendarLaneAssignments] from an already-computed
  /// [assignments] list.
  ///
  /// Prefer [assignLanes] to construct this from raw entries; this
  /// constructor exists for tests and for callers that already hold a
  /// assignment list (e.g. after filtering).
  LayrzCalendarLaneAssignments(this.assignments);

  /// Every multi-day entry that was packed, paired with its assigned lane.
  ///
  /// Order matches the order lanes were assigned in (ascending start date,
  /// then title), not lane index — use [occupiedLanesOn] or [laneCount] for
  /// index-oriented queries.
  final List<LayrzCalendarLaneAssignment> assignments;

  /// The number of lanes in use across the whole packed set, i.e. one more
  /// than the highest lane index assigned.
  ///
  /// Zero when [assignments] is empty. This is the value a caller needs to
  /// know how much vertical space the multi-day band could occupy in the
  /// worst case across the month — the per-day reservation is almost always
  /// smaller, via [occupiedLanesOn].
  int get laneCount {
    if (assignments.isEmpty) return 0;
    return assignments.map((a) => a.lane).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// The set of lane indices reserved on [date] by any entry in
  /// [assignments] that occupies it.
  ///
  /// Sparse by construction: a date can reserve `{2}` while `{0, 1}` are free
  /// that day, because lanes 0 and 1 belong to entries that occupy the date
  /// only in a different week of the same month. A caller computing how many
  /// blank slots to reserve above real content on a given day should use
  /// `occupiedLanesOn(date).length` (the count) together with the actual
  /// indices when it needs to leave the right gaps, not assume the occupied
  /// lanes are always `0..count-1`.
  Set<int> occupiedLanesOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return {
      for (final assignment in assignments)
        if (assignment.entry.occupies(day)) assignment.lane,
    };
  }

  /// The entry occupying [lane] on [date], or null if that lane is free that
  /// day.
  ///
  /// Convenience built on [occupiedLanesOn]'s underlying data for a caller
  /// that already knows which lane it is painting and wants the entry for
  /// it, e.g. to look up its color and title.
  LayrzCalendarEntry? entryAt({required DateTime date, required int lane}) {
    final day = DateTime(date.year, date.month, date.day);
    for (final assignment in assignments) {
      if (assignment.lane == lane && assignment.entry.occupies(day)) {
        return assignment.entry;
      }
    }
    return null;
  }
}

/// Packs [entries] into stable lane indices for the month containing
/// [monthAnchor], so overlapping multi-day bars never collide and a
/// continuous event never changes lane between week rows.
///
/// [entries] may contain single-day entries; they are ignored (a single-day
/// entry is never rendered as a bar and never consumes a lane) — callers do
/// not need to pre-filter. Only [LayrzCalendarEntry.isMultiDay] entries that
/// intersect the calendar month [monthAnchor] falls in (year/month
/// components only; day is ignored) are packed. An entry that starts before
/// the month and/or ends after it is still packed and still keeps one lane
/// for its entire visible span within the month — the month boundary clamps
/// which *days* the entry occupies for the purposes of [occupiedLanesOn], not
/// how many entries compete for lanes.
///
/// **Algorithm — greedy interval-graph coloring, in deterministic order:**
/// entries are sorted by [LayrzCalendarEntry.start] ascending, ties broken by
/// [LayrzCalendarEntry.title] (matching the tie-break the naive pass-1 sort
/// used, so there is one ordering convention in the codebase, not two). Each
/// entry in that order is assigned the lowest-numbered lane not already
/// occupied by a previously-assigned entry whose date range overlaps it. This
/// is a standard minimal-coloring greedy for interval graphs processed in
/// start order, so the result uses the fewest lanes possible for the given
/// input and never assigns the same lane to two overlapping entries.
///
/// **Determinism**: for a fixed [entries] list and [monthAnchor], the result
/// is always identical — no dependency on map/set iteration order, wall-clock
/// time, or the configured first day of the week.
LayrzCalendarLaneAssignments assignLanes({
  required List<LayrzCalendarEntry> entries,
  required DateTime monthAnchor,
}) {
  final monthStart = DateTime(monthAnchor.year, monthAnchor.month);
  final monthEnd = DateTime(monthAnchor.year, monthAnchor.month + 1, 0);

  final candidates =
      entries
          .where((entry) {
            if (!entry.isMultiDay) return false;
            final start = DateTime(entry.start.year, entry.start.month, entry.start.day);
            final end = DateTime(entry.end.year, entry.end.month, entry.end.day);
            return !end.isBefore(monthStart) && !start.isAfter(monthEnd);
          })
          .toList(growable: false)
        ..sort((a, b) {
          final byStart = a.start.compareTo(b.start);
          return byStart != 0 ? byStart : a.title.compareTo(b.title);
        });

  final assignments = <LayrzCalendarLaneAssignment>[];
  // Per-lane list of the [start, end] date ranges already assigned to it, so
  // a new entry can be tested for overlap against every lane in O(lanes so
  // far) without re-deriving ranges from `assignments` each time.
  final laneRanges = <int, List<(DateTime start, DateTime end)>>{};

  for (final entry in candidates) {
    final start = DateTime(entry.start.year, entry.start.month, entry.start.day);
    final end = DateTime(entry.end.year, entry.end.month, entry.end.day);

    var lane = 0;
    while (true) {
      final ranges = laneRanges[lane];
      final overlaps = ranges != null && ranges.any((r) => !start.isAfter(r.$2) && !end.isBefore(r.$1));
      if (!overlaps) break;
      lane++;
    }

    assignments.add(LayrzCalendarLaneAssignment(entry: entry, lane: lane));
    (laneRanges[lane] ??= []).add((start, end));
  }

  return LayrzCalendarLaneAssignments(assignments);
}

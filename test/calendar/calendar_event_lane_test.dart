import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/calendar/src/calendar_entry.dart';
import 'package:layrz_ui/src/calendar/src/calendar_event_lane.dart';

void main() {
  group('assignLanes', () {
    test('a single multi-day entry is assigned lane 0', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 12),
      );

      final result = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(result.assignments, hasLength(1));
      expect(result.assignments.single.lane, 0);
      expect(result.laneCount, 1);
    });

    test('single-day entries are ignored and consume no lane', () {
      final singleDay = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 10, 9),
        end: DateTime(2026, 8, 10, 9, 30),
      );
      final multiDay = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 12),
      );

      final result = assignLanes(entries: [singleDay, multiDay], monthAnchor: DateTime(2026, 8, 1));

      expect(result.assignments, hasLength(1));
      expect(result.assignments.single.entry, multiDay);
    });

    test('overlapping multi-day entries never share a lane', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 5), end: DateTime(2026, 8, 8));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 7), end: DateTime(2026, 8, 10));
      final c = LayrzCalendarEntry(title: 'C', start: DateTime(2026, 8, 6), end: DateTime(2026, 8, 9));

      final result = assignLanes(entries: [a, b, c], monthAnchor: DateTime(2026, 8, 1));

      final lanes = {for (final assignment in result.assignments) assignment.entry: assignment.lane};
      // a, b and c pairwise overlap (a-b, a-c, b-c all share at least one
      // date), so all three must land on distinct lanes -- a 3-clique in the
      // interval overlap graph needs exactly 3 colors.
      expect(lanes.values.toSet(), hasLength(3));
    });

    test('non-overlapping entries reuse the same lane, minimizing lane count', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 4), end: DateTime(2026, 8, 6));
      final c = LayrzCalendarEntry(title: 'C', start: DateTime(2026, 8, 7), end: DateTime(2026, 8, 9));

      final result = assignLanes(entries: [a, b, c], monthAnchor: DateTime(2026, 8, 1));

      expect(result.laneCount, 1, reason: 'no two of these entries overlap, so one lane suffices for all three');
    });

    test('an entry spanning three weeks keeps the same lane index throughout', () {
      // Aug 2026: 1st is a Saturday, so a Mon-Aug-3 to Mon-Aug-17 span
      // crosses three week rows under any first-day-of-week convention.
      final longEntry = LayrzCalendarEntry(
        title: 'Long project',
        start: DateTime(2026, 8, 3),
        end: DateTime(2026, 8, 17),
      );
      // A short entry overlapping only the middle week forces `longEntry`
      // off lane 0 if (and only if) lanes were being re-derived per week --
      // per-month stability means `longEntry` keeps whichever lane it was
      // first assigned for its *entire* span, regardless of this collision.
      final middleWeekEntry = LayrzCalendarEntry(
        title: 'Mid-week clash',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 11),
      );

      final result = assignLanes(entries: [longEntry, middleWeekEntry], monthAnchor: DateTime(2026, 8, 1));

      final longLane = result.assignments.firstWhere((a) => a.entry == longEntry).lane;
      for (var day = 3; day <= 17; day++) {
        final date = DateTime(2026, 8, day);
        expect(
          result.occupiedLanesOn(date).contains(longLane),
          isTrue,
          reason: '$date should still show longEntry on lane $longLane',
        );
      }
    });

    test('nested events (one fully contains another) never share a lane', () {
      final outer = LayrzCalendarEntry(title: 'Outer', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 20));
      final inner = LayrzCalendarEntry(title: 'Inner', start: DateTime(2026, 8, 5), end: DateTime(2026, 8, 10));

      final result = assignLanes(entries: [outer, inner], monthAnchor: DateTime(2026, 8, 1));

      final outerLane = result.assignments.firstWhere((a) => a.entry == outer).lane;
      final innerLane = result.assignments.firstWhere((a) => a.entry == inner).lane;
      expect(outerLane, isNot(innerLane));
    });

    test('events sharing a start date do not collide', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 4), end: DateTime(2026, 8, 6));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 4), end: DateTime(2026, 8, 9));

      final result = assignLanes(entries: [a, b], monthAnchor: DateTime(2026, 8, 1));

      final laneA = result.assignments.firstWhere((a) => a.entry.title == 'A').lane;
      final laneB = result.assignments.firstWhere((a) => a.entry.title == 'B').lane;
      expect(laneA, isNot(laneB));
    });

    test('events sharing an end date do not collide', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 2), end: DateTime(2026, 8, 9));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 7), end: DateTime(2026, 8, 9));

      final result = assignLanes(entries: [a, b], monthAnchor: DateTime(2026, 8, 1));

      final laneA = result.assignments.firstWhere((a) => a.entry.title == 'A').lane;
      final laneB = result.assignments.firstWhere((a) => a.entry.title == 'B').lane;
      expect(laneA, isNot(laneB));
    });

    test('an entry ending exactly where another begins does not collide (touching, not overlapping)', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 5));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 5), end: DateTime(2026, 8, 8));

      final result = assignLanes(entries: [a, b], monthAnchor: DateTime(2026, 8, 1));

      // The two entries both occupy Aug 5 (inclusive-range semantics per
      // LayrzCalendarEntry.occupies), so they DO overlap on that date and
      // must not share a lane -- this pins down the inclusive boundary
      // behavior explicitly rather than leaving it implicit.
      final laneA = result.assignments.firstWhere((a) => a.entry.title == 'A').lane;
      final laneB = result.assignments.firstWhere((a) => a.entry.title == 'B').lane;
      expect(laneA, isNot(laneB));
    });

    test('an entry spanning a month boundary is packed for the month it is queried against', () {
      final entry = LayrzCalendarEntry(
        title: 'Spans boundary',
        start: DateTime(2026, 7, 28),
        end: DateTime(2026, 8, 3),
      );

      final julyResult = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 7, 1));
      final augustResult = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(julyResult.assignments, hasLength(1));
      expect(augustResult.assignments, hasLength(1));
      expect(julyResult.occupiedLanesOn(DateTime(2026, 7, 30)), isNotEmpty);
      expect(augustResult.occupiedLanesOn(DateTime(2026, 8, 1)), isNotEmpty);
    });

    test('an entry entirely outside the queried month is excluded', () {
      final entry = LayrzCalendarEntry(
        title: 'September only',
        start: DateTime(2026, 9, 5),
        end: DateTime(2026, 9, 7),
      );

      final result = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(result.assignments, isEmpty);
    });

    test('assignment is deterministic for equal inputs regardless of input order', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 5));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 3), end: DateTime(2026, 8, 8));

      final forward = assignLanes(entries: [a, b], monthAnchor: DateTime(2026, 8, 1));
      final backward = assignLanes(entries: [b, a], monthAnchor: DateTime(2026, 8, 1));

      final forwardLanes = {for (final x in forward.assignments) x.entry: x.lane};
      final backwardLanes = {for (final x in backward.assignments) x.entry: x.lane};
      expect(forwardLanes, backwardLanes);
    });

    test('ties on the same start date break by title, matching the pass-1 sort convention', () {
      final z = LayrzCalendarEntry(title: 'Zebra', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 5));
      final a = LayrzCalendarEntry(title: 'Apple', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 5));

      final result = assignLanes(entries: [z, a], monthAnchor: DateTime(2026, 8, 1));

      // Both start the same day and overlap fully, so they must land on
      // different lanes; "Apple" sorts before "Zebra" and is processed
      // first, so it claims lane 0.
      final appleLane = result.assignments.firstWhere((x) => x.entry.title == 'Apple').lane;
      final zebraLane = result.assignments.firstWhere((x) => x.entry.title == 'Zebra').lane;
      expect(appleLane, 0);
      expect(zebraLane, 1);
    });

    test('an empty entry list produces no assignments and zero lane count', () {
      final result = assignLanes(entries: const [], monthAnchor: DateTime(2026, 8, 1));

      expect(result.assignments, isEmpty);
      expect(result.laneCount, 0);
    });

    test(
      'does not duplicate or shift lane assignment across a DST transition month',
      () {
        // Mirrors the rigor of the DST regression test in
        // calendar_month_surface_test.dart: scans a window of years for a
        // real DST-observing month on this host rather than hardcoding one,
        // so the test is meaningful wherever it runs and fails loudly (not
        // silently) if no such month exists in range.
        DateTime? transitionMonth;
        for (var year = 2015; year <= 2030 && transitionMonth == null; year++) {
          for (var month = 1; month <= 12; month++) {
            final monthStart = DateTime(year, month, 1);
            final monthEnd = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
            if (monthStart.timeZoneOffset != monthEnd.timeZoneOffset) {
              transitionMonth = DateTime(year, month, 1);
            }
          }
        }

        expect(
          transitionMonth,
          isNotNull,
          reason:
              'No DST-transitioning month found in 2015-2030 for this host\'s local timezone -- '
              'this test cannot exercise the regression it guards. Run it on a host whose '
              'timezone observes DST (e.g. TZ=America/Mexico_City, which observed DST through 2022).',
        );

        final year = transitionMonth!.year;
        final month = transitionMonth.month;
        // An entry spanning the entire transition month plus a few days on
        // either side, so its occupied-day set must include every day of the
        // month with no gap and no duplicate -- exactly what a
        // `Duration(days: n)`-stepped implementation would get wrong across
        // the transition (landing on 23:00 of the previous local day,
        // producing a duplicate date and a missing one).
        final spanStart = DateTime(year, month, 1);
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final spanEnd = DateTime(year, month, daysInMonth);
        final entry = LayrzCalendarEntry(title: 'Spans the transition', start: spanStart, end: spanEnd);

        final result = assignLanes(entries: [entry], monthAnchor: DateTime(year, month, 1));

        expect(result.assignments, hasLength(1));
        final lane = result.assignments.single.lane;
        for (var day = 1; day <= daysInMonth; day++) {
          final date = DateTime(year, month, day);
          expect(
            result.occupiedLanesOn(date),
            {lane},
            reason: 'day $day of the DST-transition month should occupy exactly lane $lane, once',
          );
        }
      },
    );

    test('a dense set of entries under a non-default (Monday) week start month still packs without collision', () {
      // Per the plan's liliana test-construction requirement: a synthetic
      // dense case is the one most likely to go unwritten, and lane packing
      // is explicitly independent of the configured first day of the week --
      // this test proves that independence by using a month/entry set with
      // no reference to any week-start convention at all.
      final entries = [
        LayrzCalendarEntry(title: 'A', start: DateTime(2026, 3, 2), end: DateTime(2026, 3, 6)),
        LayrzCalendarEntry(title: 'B', start: DateTime(2026, 3, 3), end: DateTime(2026, 3, 9)),
        LayrzCalendarEntry(title: 'C', start: DateTime(2026, 3, 4), end: DateTime(2026, 3, 8)),
        LayrzCalendarEntry(title: 'D', start: DateTime(2026, 3, 5), end: DateTime(2026, 3, 12)),
        LayrzCalendarEntry(title: 'E', start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 15)),
      ];

      final result = assignLanes(entries: entries, monthAnchor: DateTime(2026, 3, 1));

      expect(result.assignments, hasLength(5));
      // For every day in range, no lane is claimed by two different entries.
      for (var day = 2; day <= 15; day++) {
        final date = DateTime(2026, 3, day);
        final entriesToday = entries.where((e) => e.occupies(date));
        final lanesToday = [
          for (final e in entriesToday) result.assignments.firstWhere((a) => a.entry == e).lane,
        ];
        expect(lanesToday.toSet(), hasLength(lanesToday.length), reason: '$date has a lane collision');
      }
    });
  });

  group('LayrzCalendarLaneAssignment', () {
    test('two assignments with equal entry and lane are equal and share a hashCode', () {
      final entry = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final first = LayrzCalendarLaneAssignment(entry: entry, lane: 1);
      final second = LayrzCalendarLaneAssignment(entry: entry, lane: 1);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('assignments differing by lane are not equal', () {
      final entry = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final first = LayrzCalendarLaneAssignment(entry: entry, lane: 0);
      final second = LayrzCalendarLaneAssignment(entry: entry, lane: 1);

      expect(first, isNot(second));
    });

    test('assignments differing by entry are not equal', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final first = LayrzCalendarLaneAssignment(entry: a, lane: 0);
      final second = LayrzCalendarLaneAssignment(entry: b, lane: 0);

      expect(first, isNot(second));
    });

    test('toString includes the entry title and lane index', () {
      final entry = LayrzCalendarEntry(title: 'Conference', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final assignment = LayrzCalendarLaneAssignment(entry: entry, lane: 2);

      expect(assignment.toString(), contains('Conference'));
      expect(assignment.toString(), contains('2'));
    });
  });

  group('LayrzCalendarLaneAssignments', () {
    test('occupiedLanesOn is empty for a date no entry occupies', () {
      final entry = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final result = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(result.occupiedLanesOn(DateTime(2026, 8, 20)), isEmpty);
    });

    test('occupiedLanesOn ignores the time-of-day component of the queried date', () {
      final entry = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final result = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(result.occupiedLanesOn(DateTime(2026, 8, 2, 23, 59)), {0});
    });

    test('entryAt returns the entry occupying a lane on a date, or null when free', () {
      final entry = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 3));
      final result = assignLanes(entries: [entry], monthAnchor: DateTime(2026, 8, 1));

      expect(result.entryAt(date: DateTime(2026, 8, 2), lane: 0), entry);
      expect(result.entryAt(date: DateTime(2026, 8, 2), lane: 1), isNull);
      expect(result.entryAt(date: DateTime(2026, 8, 10), lane: 0), isNull);
    });

    test('sparse occupancy: a later-assigned entry can occupy a higher lane while lower lanes are free that day', () {
      // Two non-overlapping entries in different parts of the month, plus
      // one that overlaps only the second -- forcing the third entry onto
      // lane 1 while lane 0 is free on the days the third entry actually
      // occupies. This is the "blank reserved lanes above real content"
      // shape that per-month stability deliberately produces and that a
      // bare int count could never express.
      final first = LayrzCalendarEntry(title: 'First', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 5));
      final second = LayrzCalendarEntry(title: 'Second', start: DateTime(2026, 8, 20), end: DateTime(2026, 8, 25));
      final overlapsSecond = LayrzCalendarEntry(
        title: 'Overlaps second',
        start: DateTime(2026, 8, 22),
        end: DateTime(2026, 8, 26),
      );

      final result = assignLanes(entries: [first, second, overlapsSecond], monthAnchor: DateTime(2026, 8, 1));

      final firstLane = result.assignments.firstWhere((a) => a.entry == first).lane;
      final secondLane = result.assignments.firstWhere((a) => a.entry == second).lane;
      final overlapsSecondLane = result.assignments.firstWhere((a) => a.entry == overlapsSecond).lane;

      expect(firstLane, 0, reason: 'no earlier entry to collide with');
      expect(secondLane, 0, reason: '"Second" does not overlap "First", so it reuses lane 0');
      expect(overlapsSecondLane, isNot(secondLane));
      // On Aug 24 (occupied by both "second" and "overlapsSecond"), lane 0
      // is occupied by "second" -- there is no separate free gap here, this
      // just pins the sparse-occupancy query shape used elsewhere in the
      // suite: querying a day only "overlapsSecond" occupies (e.g. Aug 26)
      // shows its lane occupied while lane 0 is free that day.
      expect(result.occupiedLanesOn(DateTime(2026, 8, 26)), {overlapsSecondLane});
      expect(result.occupiedLanesOn(DateTime(2026, 8, 26)).contains(0), isFalse);
    });

    test('laneCount reflects the highest lane index plus one', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 10));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 2), end: DateTime(2026, 8, 10));
      final c = LayrzCalendarEntry(title: 'C', start: DateTime(2026, 8, 3), end: DateTime(2026, 8, 10));

      final result = assignLanes(entries: [a, b, c], monthAnchor: DateTime(2026, 8, 1));

      expect(result.laneCount, 3);
    });
  });
}

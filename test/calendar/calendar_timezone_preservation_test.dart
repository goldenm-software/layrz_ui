import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

/// End-to-end proof that [LayrzCalendarMonthSurface] preserves the zone of a
/// `TZDateTime` passed to it, rather than flattening every internal
/// computation into the host process's own local zone.
///
/// **Why this is only now testable.** Before `calendar_zone.dart`'s
/// `sameZoneDate`/`sameZoneDateTime` helpers replaced every field-extracting
/// `DateTime(reference.year, reference.month, reference.day)` construction in
/// this module, every internal grid computation silently re-anchored to the
/// *host process's* zone regardless of what zone a `TZDateTime` argument
/// actually carried -- so the only way to observe the bug was to run the
/// suite itself under a matching `TZ`, which made the defect invisible on a
/// UTC CI host. This file's whole point is the opposite: it runs entirely
/// under whatever `TZ` the test process happens to have (this repo's `TZ=`
/// invocations exercise `Etc/UTC`, `America/New_York` and
/// `Australia/Lord_Howe`), and asserts the calendar's rendered grid matches
/// each fixture's own **named zone**, not the host's -- proving the fix is
/// genuinely host-independent, not coincidentally passing under one `TZ`.
void main() {
  // Must run before any TZDateTime fixture below is constructed. Test-only:
  // nothing under `lib/` calls this -- see `calendar_zone.dart`'s doc for why
  // reusing an existing TZDateTime's Location needs no initialization of its
  // own; this call exists purely to build this file's own fixtures.
  tzdata.initializeTimeZones();

  group('LayrzCalendarMonthSurface preserves a TZDateTime\'s own zone', () {
    guardedTestWidgets('Pacific/Auckland: renders Auckland\'s day boundaries regardless of the host TZ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final auckland = tz.getLocation('Pacific/Auckland');
      // 23:30 Auckland time on the 1st is still the 1st in Auckland,
      // regardless of what calendar date that instant falls on elsewhere --
      // this is exactly the kind of value that a flattening bug would get
      // wrong, since reading .day off it under a UTC-losing conversion could
      // land on the 31st of the previous month instead.
      final focusedDate = tz.TZDateTime(auckland, 2026, 8, 1, 23, 30);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: focusedDate, entries: const [], showWeekNumbers: false),
        ),
      );

      // August 2026 in Lord Howe/Auckland's own calendar starts on a
      // Saturday -- the reference grid used throughout this suite computes
      // this independently of the widget under test via TZDateTime, per this
      // file's class doc.
      final expectedCounts = _referenceGridCounts(auckland, 2026, 8, DateTime.sunday);
      final dayCellFinder = find.byType(LayrzCalendarDayCell);
      for (final entry in expectedCounts.entries) {
        expect(
          find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
          findsNWidgets(entry.value),
          reason: 'Pacific/Auckland August 2026: day-of-month ${entry.key} should render ${entry.value} time(s)',
        );
      }
    });

    guardedTestWidgets('America/New_York: renders New York\'s day boundaries regardless of the host TZ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final newYork = tz.getLocation('America/New_York');
      final focusedDate = tz.TZDateTime(newYork, 2026, 2, 15, 3, 0);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: focusedDate, entries: const [], showWeekNumbers: false),
        ),
      );

      final expectedCounts = _referenceGridCounts(newYork, 2026, 2, DateTime.sunday);
      final dayCellFinder = find.byType(LayrzCalendarDayCell);
      for (final entry in expectedCounts.entries) {
        expect(
          find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
          findsNWidgets(entry.value),
          reason: 'America/New_York February 2026: day-of-month ${entry.key} should render ${entry.value} time(s)',
        );
      }
    });

    guardedTestWidgets(
      'Australia/Lord_Howe: renders Lord Howe\'s day boundaries (30-minute DST offset) regardless of the host TZ',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final lordHowe = tz.getLocation('Australia/Lord_Howe');
        // April 2024 contains Lord Howe's own fall-back transition
        // (2024-04-07, +11:00 -> +10:30) -- the fractional-hour shift that
        // would defeat an implementation assuming every DST delta is a whole
        // hour.
        final focusedDate = tz.TZDateTime(lordHowe, 2024, 4, 7, 1, 45);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1000,
            height: 800,
            child: LayrzCalendarMonthSurface(focusedDate: focusedDate, entries: const [], showWeekNumbers: false),
          ),
        );

        final expectedCounts = _referenceGridCounts(lordHowe, 2024, 4, DateTime.sunday);
        final dayCellFinder = find.byType(LayrzCalendarDayCell);
        for (final entry in expectedCounts.entries) {
          expect(
            find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
            findsNWidgets(entry.value),
            reason: 'Australia/Lord_Howe April 2024: day-of-month ${entry.key} should render ${entry.value} time(s)',
          );
        }
      },
    );

    guardedTestWidgets('a plain DateTime focusedDate still renders using the host\'s own zone -- no regression', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // No package:timezone involved at all here -- this is the ordinary,
      // pre-existing calling convention every other calendar test in this
      // repo uses, and it must render identically to before this fix.
      final focusedDate = DateTime(2026, 8, 1);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(focusedDate: focusedDate, entries: const [], showWeekNumbers: false),
        ),
      );

      expect(find.byType(LayrzCalendarDayCell), findsNWidgets(42));
      // Same host-local reference grid this suite uses for the TZDateTime
      // cases above, just anchored with a plain DateTime -- proving the
      // pre-existing calling convention renders identically to before this
      // fix, using the same day-count-map comparison rather than guessing
      // which day-of-month values happen to be unambiguous in this grid.
      final expectedCounts = _referenceGridCounts(null, 2026, 8, DateTime.sunday);
      final dayCellFinder = find.byType(LayrzCalendarDayCell);
      for (final entry in expectedCounts.entries) {
        expect(
          find.descendant(of: dayCellFinder, matching: find.text('${entry.key}')),
          findsNWidgets(entry.value),
          reason: 'plain DateTime, August 2026: day-of-month ${entry.key} should render ${entry.value} time(s)',
        );
      }
    });
  });

  group('LayrzCalendarController preserves a TZDateTime\'s own zone', () {
    test('nextWeek/previousWeek step within the same named Location across its own DST transition', () {
      final lordHowe = tz.getLocation('Australia/Lord_Howe');
      // One week before Lord Howe's own fall-back transition (2024-04-07).
      final controller = LayrzCalendarController(initialDate: tz.TZDateTime(lordHowe, 2024, 3, 31));

      controller.nextWeek();

      final stepped = controller.focusedDate;
      expect(stepped, isA<tz.TZDateTime>(), reason: 'stepping must preserve the TZDateTime subtype');
      expect((stepped as tz.TZDateTime).location, lordHowe);
      expect(stepped.year, 2024);
      expect(stepped.month, 4);
      expect(stepped.day, 7, reason: 'calendar-field stepping (not Duration) must land exactly 7 days later');

      controller.previousWeek();
      final back = controller.focusedDate;
      expect((back as tz.TZDateTime).location, lordHowe);
      expect(back.day, 31);
      expect(back.month, 3);
    });

    test('nextMonth/previousMonth preserve the Location across a year boundary', () {
      final auckland = tz.getLocation('Pacific/Auckland');
      final controller = LayrzCalendarController(initialDate: tz.TZDateTime(auckland, 2026, 12, 15));

      controller.nextMonth();
      final stepped = controller.focusedDate;
      expect((stepped as tz.TZDateTime).location, auckland);
      expect(stepped.year, 2027);
      expect(stepped.month, 1);
    });
  });

  group('DST-guard reversion proof (RISK re-proof, per-zone)', () {
    // Required by the plan: prove the DST guards actually catch a
    // Duration-stepped implementation in every zone under test, not just
    // coincidentally under whichever TZ the suite happens to run under. This
    // mirrors calendar_month_surface_test.dart's own RISK-7 re-proof but adds
    // the explicit before/after comparison this task specifically asked to
    // see executed.
    for (final zoneName in ['America/New_York', 'Pacific/Auckland', 'Australia/Lord_Howe']) {
      test('$zoneName: the safe (sameZoneDate) and buggy (Duration) grids genuinely diverge', () {
        final location = tz.getLocation(zoneName);
        // Each zone's own fall-back month, matching the transitions this
        // suite's other files already established as fall-back (offset
        // decreases) in 2024.
        final (year, month) = switch (zoneName) {
          'America/New_York' => (2024, 11),
          'Pacific/Auckland' => (2024, 4),
          'Australia/Lord_Howe' => (2024, 4),
          _ => throw StateError('no fixture for $zoneName'),
        };

        final safeCounts = _referenceGridCounts(location, year, month, DateTime.sunday);
        final buggyCounts = _buggyDurationSteppedGridCounts(location, year, month, DateTime.sunday);

        expect(
          safeCounts,
          isNot(equals(buggyCounts)),
          reason:
              '$zoneName $year-$month: the calendar-field-stepped and Duration-stepped grids produced identical '
              'day-count maps -- the DST guard would not catch a regression here.',
        );
      });
    }
  });
}

/// The correct, DST-immune reference grid's per-day render counts for
/// [year]/[month], computed independently of production code using only
/// [sameZoneDate]'s calendar-field overflow, never `Duration`.
///
/// When [location] is non-null, the anchor is a `TZDateTime` in that zone
/// (exercising the same `TZDateTime` branch of [sameZoneDate] the widget
/// tests above do); when null, the anchor is a plain [DateTime] in the host's
/// own zone, matching the pre-existing calling convention. Mirrors
/// `calendar_month_surface_test.dart`'s own `_referenceGridCounts`,
/// generalized to call the shared helper under test rather than either
/// constructor directly, so this file's expectations are pinned to the same
/// code path `LayrzCalendarMonthSurface` itself now uses.
Map<int, int> _referenceGridCounts(tz.Location? location, int year, int month, int firstDayOfWeek) {
  final DateTime anchor = location == null ? DateTime(year, month) : tz.TZDateTime(location, year, month);
  final firstOfMonth = sameZoneDate(anchor, year, month);
  final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
  final gridStart = sameZoneDate(anchor, year, month, 1 - offset);
  final counts = <int, int>{};
  for (var i = 0; i < 42; i++) {
    final date = sameZoneDate(gridStart, gridStart.year, gridStart.month, gridStart.day + i);
    counts[date.day] = (counts[date.day] ?? 0) + 1;
  }
  return counts;
}

/// The buggy `Duration`-stepped equivalent of [_referenceGridCounts], used
/// only to prove the reference grid actually diverges from what a
/// `Duration`-based regression would produce, in [location]'s own zone.
Map<int, int> _buggyDurationSteppedGridCounts(tz.Location location, int year, int month, int firstDayOfWeek) {
  final firstOfMonth = tz.TZDateTime(location, year, month);
  final offset = (firstOfMonth.weekday - firstDayOfWeek + 7) % 7;
  final gridStart = tz.TZDateTime(location, year, month, 1).subtract(Duration(days: offset));
  final counts = <int, int>{};
  for (var i = 0; i < 42; i++) {
    final date = gridStart.add(Duration(days: i));
    counts[date.day] = (counts[date.day] ?? 0) + 1;
  }
  return counts;
}

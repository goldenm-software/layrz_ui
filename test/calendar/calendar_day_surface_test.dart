import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarDaySurface', () {
    guardedTestWidgets('renders a fixed 24-row hour axis in h24 format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    guardedTestWidgets('renders a fixed 24-row hour axis in amPm format', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
            timeFormat: LayrzTimeFormat.amPm,
          ),
        ),
      );

      expect(find.text('12 AM'), findsOneWidget);
      expect(find.text('12 PM'), findsOneWidget);
      expect(find.text('11 PM'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
    });

    guardedTestWidgets('each hour label sits at the vertical midpoint of its own hour row', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      // The axis's own top edge is row 0's top -- row N's boundaries are
      // computed from it rather than from any assumed global origin, since
      // pumpThemed centers its child inside the test surface.
      final axisTop = tester.getTopLeft(find.byType(HourAxis)).dy;

      const hourLabels = {0: '00:00', 1: '01:00', 12: '12:00', 23: '23:00'};
      for (final entry in hourLabels.entries) {
        final rowTop = axisTop + entry.key * kLayrzCalendarHourRowHeight;
        final rowMidpoint = rowTop + kLayrzCalendarHourRowHeight / 2;

        final labelCenter = tester.getCenter(find.text(entry.value)).dy;

        expect(labelCenter, closeTo(rowMidpoint, 1.0), reason: 'hour ${entry.key} label not centered in its row');
      }
    });

    guardedTestWidgets('centering the hour label leaves row geometry -- and grid alignment -- unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final date = DateTime(2026, 8, 28);
      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: date,
            entries: [
              // A 09:00-10:00 event whose top must land exactly on the 09:00
              // gridline -- if centering the label had shifted row geometry
              // (rather than only the text within the row), this would drift.
              LayrzCalendarEntry(
                title: 'Standup',
                start: DateTime(2026, 8, 28, 9),
                end: DateTime(2026, 8, 28, 10),
              ),
            ],
          ),
        ),
      );

      final axisTop = tester.getTopLeft(find.byType(HourAxis)).dy;
      final expectedNineAmTop = axisTop + 9 * kLayrzCalendarHourRowHeight;

      final eventPositioned = tester.widget<Positioned>(
        find.ancestor(of: find.text('Standup'), matching: find.byType(Positioned)).first,
      );
      final gridTop = tester.getTopLeft(find.byType(HourGridColumn)).dy;

      expect(gridTop, closeTo(axisTop, 0.5), reason: 'axis and timed grid must stay top-aligned with each other');
      expect(
        gridTop + eventPositioned.top!,
        closeTo(expectedNineAmTop, 0.5),
        reason: 'event block top must still land on the 09:00 row boundary, not move with the label',
      );

      // The overall axis height (24 fixed rows) must be untouched.
      final axisHeight = tester.getSize(find.byType(HourAxis)).height;
      expect(axisHeight, closeTo(kLayrzCalendarHourRowHeight * 24, 0.5));
    });

    guardedTestWidgets('the hour grid content ends short of the scroll view edge, reserving room for the scrollbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      final scrollViewRight = tester.getTopRight(find.byType(SingleChildScrollView)).dx;
      final contentRight = tester.getTopRight(find.byType(HourGridColumn)).dx;

      // The grid content (day column) must end kLayrzCalendarHourGridEndPadding
      // short of the scroll view's own right edge -- that gap is exactly where
      // the globally-installed LayrzScrollbar paints its thumb, so it never
      // overlaps an event block reaching the rightmost column.
      expect(scrollViewRight - contentRight, closeTo(kLayrzCalendarHourGridEndPadding, 0.5));
    });

    guardedTestWidgets('renders a timed single-day event on the hour grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final date = DateTime(2026, 8, 28);
      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: date,
            entries: [
              LayrzCalendarEntry(
                title: 'Standup',
                start: DateTime(2026, 8, 28, 9),
                end: DateTime(2026, 8, 28, 9, 30),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Standup'), findsOneWidget);
    });

    guardedTestWidgets('renders the all-day band for a multi-day entry occupying the focused date', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 27), end: DateTime(2026, 8, 29)),
            ],
          ),
        ),
      );

      // Day view's band has a single column -- one shared AllDayBand, one
      // bar, exactly the same collapsed-bar widget week view uses, just with
      // one column instead of seven.
      expect(find.byType(AllDayBand), findsOneWidget);
      expect(find.text('Offsite'), findsOneWidget);
    });

    guardedTestWidgets('a very short timed event still renders at the minimum block height', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              // 5-minute event -- far shorter than kLayrzCalendarMinEventBlockHeight
              // would allow if height were computed purely from duration.
              LayrzCalendarEntry(
                title: 'Quick sync',
                start: DateTime(2026, 8, 28, 9),
                end: DateTime(2026, 8, 28, 9, 5),
              ),
            ],
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.ancestor(of: find.text('Quick sync'), matching: find.byType(Positioned)).first,
      );
      expect(positioned.height, kLayrzCalendarMinEventBlockHeight);
    });

    guardedTestWidgets('does not step across a DST transition day incorrectly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Regression guard mirroring the month surface's: the day surface must
      // never assume a transition day has exactly 24 elapsed hours, but its
      // hour-of-day AXIS is always the ordinary fixed 24 rows regardless.
      // Renders without throwing and shows all 24 axis rows on a
      // DST-transition day itself.
      DateTime? transitionMonth;
      for (var year = 2015; year <= 2030 && transitionMonth == null; year++) {
        for (var month = 1; month <= 12; month++) {
          final start = DateTime(year, month, 1);
          final end = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
          if (end.timeZoneOffset < start.timeZoneOffset) transitionMonth = DateTime(year, month, 1);
        }
      }
      expect(transitionMonth, isNotNull);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: transitionMonth!,
            entries: const [],
          ),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
    });

    guardedTestWidgets('two overlapping timed events split the column width evenly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(
                title: 'Design System',
                start: DateTime(2026, 8, 28, 11),
                end: DateTime(2026, 8, 28, 12),
              ),
              LayrzCalendarEntry(
                title: 'Ocupado',
                start: DateTime(2026, 8, 28, 11, 45),
                end: DateTime(2026, 8, 28, 13, 15),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Design System'), findsOneWidget);
      expect(find.text('Ocupado'), findsOneWidget);
    });

    guardedTestWidgets(
      'the later-starting overlapping event is demoted -- lighter fill -- while the earlier one keeps its solid fill',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const accent = Color(0xFF2196F3);

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 900,
            child: LayrzCalendarDaySurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: [
                LayrzCalendarEntry(
                  title: 'Earlier',
                  start: DateTime(2026, 8, 28, 11),
                  end: DateTime(2026, 8, 28, 12),
                  color: accent,
                ),
                LayrzCalendarEntry(
                  title: 'Later',
                  start: DateTime(2026, 8, 28, 11, 45),
                  end: DateTime(2026, 8, 28, 13, 15),
                  color: accent,
                ),
              ],
            ),
          ),
        );

        // "Later" draws on top and stays solid; "Earlier" is covered and
        // demoted to a light-fill/outlined treatment.
        final earlierContainer = tester.widget<Container>(
          find.ancestor(of: find.text('Earlier'), matching: find.byType(Container)).first,
        );
        final laterContainer = tester.widget<Container>(
          find.ancestor(of: find.text('Later'), matching: find.byType(Container)).first,
        );

        final earlierDecoration = earlierContainer.decoration as BoxDecoration;
        final laterDecoration = laterContainer.decoration as BoxDecoration;

        expect(laterDecoration.color, accent);
        expect(laterDecoration.border, isNull);
        expect(earlierDecoration.color, isNot(accent));
        expect(earlierDecoration.border, isNotNull);
      },
    );

    guardedTestWidgets('an unoverlapped event keeps its ordinary solid chip style', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const accent = Color(0xFF4CAF50);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(
                title: 'Solo',
                start: DateTime(2026, 8, 28, 9),
                end: DateTime(2026, 8, 28, 10),
                color: accent,
              ),
            ],
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Solo'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, accent);
      expect(decoration.border, isNull);
    });
  });

  group('LayrzCalendarDaySurface onTap / LayrzCalendarEntry.onTap', () {
    guardedTestWidgets(
      'with the surface\'s onTap null and no entry carrying its own onTap, the hour grid is exactly as '
      'display-only as before -- no MouseRegion',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 900,
            child: LayrzCalendarDaySurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: [
                LayrzCalendarEntry(title: 'Solo', start: DateTime(2026, 8, 28, 9), end: DateTime(2026, 8, 28, 10)),
              ],
            ),
          ),
        );

        expect(find.byType(MouseRegion), findsNothing);
      },
    );

    guardedTestWidgets('a click cursor appears on the hour grid only when onTap is set', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
            onTap: (_) {},
          ),
        ),
      );

      final mouseRegions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
      expect(mouseRegions, isNotEmpty);
      expect(mouseRegions.every((m) => m.cursor == SystemMouseCursors.click), isTrue);
    });

    guardedTestWidgets('tapping the top of the 09:00 row (no offset) returns 09:00:00', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
            onTap: (d) => tapped = d,
          ),
        ),
      );

      // The 09:00 row's top-left in the grid column -- one row height per
      // hour, kLayrzCalendarHourRowHeight = 48.
      final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn));
      await tester.tapAt(gridTopLeft + const Offset(10, 9 * kLayrzCalendarHourRowHeight + 1));
      await tester.pump();

      expect(tapped, DateTime(2026, 8, 28, 9, 0));
    });

    guardedTestWidgets(
      'tapping 20px into the 09:00 row (past the 15-min boundary at 12px) snaps down to 09:15, not up to 09:30',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 900,
            child: LayrzCalendarDaySurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: const [],
              onTap: (d) => tapped = d,
            ),
          ),
        );

        final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn));
        await tester.tapAt(gridTopLeft + const Offset(10, 9 * kLayrzCalendarHourRowHeight + 20));
        await tester.pump();

        expect(tapped, DateTime(2026, 8, 28, 9, 15));
      },
    );

    guardedTestWidgets(
      'tapping exactly at the 45-minute boundary (36px into the row) returns 09:45, seconds and ms always zero',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 900,
            child: LayrzCalendarDaySurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: const [],
              onTap: (d) => tapped = d,
            ),
          ),
        );

        final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn));
        await tester.tapAt(gridTopLeft + const Offset(10, 9 * kLayrzCalendarHourRowHeight + 36));
        await tester.pump();

        expect(tapped, DateTime(2026, 8, 28, 9, 45));
        expect(tapped!.second, 0);
        expect(tapped!.millisecond, 0);
      },
    );

    guardedTestWidgets(
      'tapping just below the 45-minute boundary (47px into the row, just short of the next hour) still returns '
      '09:45, never rolling over to 10:00',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;

        await pumpThemed(
          tester,
          SizedBox(
            width: 600,
            height: 900,
            child: LayrzCalendarDaySurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: const [],
              onTap: (d) => tapped = d,
            ),
          ),
        );

        final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn));
        await tester.tapAt(gridTopLeft + const Offset(10, 9 * kLayrzCalendarHourRowHeight + 47));
        await tester.pump();

        expect(tapped, DateTime(2026, 8, 28, 9, 45));
      },
    );

    guardedTestWidgets('tapping a timed event block fires that entry\'s own onTap, not the surface\'s onTap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tappedDate;
      var entryTapped = false;
      final entry = LayrzCalendarEntry(
        title: 'Solo',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        onTap: () => entryTapped = true,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [entry],
            onTap: (d) => tappedDate = d,
          ),
        ),
      );

      await tester.tap(find.text('Solo'));
      await tester.pump();

      expect(entryTapped, isTrue);
      expect(tappedDate, isNull);
    });

    guardedTestWidgets('a preview timed block that is also covered gets both ghosting and covered demotion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const accent = Color(0xFF4CAF50);

      await pumpThemed(
        tester,
        SizedBox(
          width: 600,
          height: 900,
          child: LayrzCalendarDaySurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              // 'Preview' starts first, so the later-starting 'Cover' draws
              // on top and covers it -- 'Preview' is both isPreview and
              // isCovered.
              LayrzCalendarEntry(
                title: 'Preview',
                start: DateTime(2026, 8, 28, 9),
                end: DateTime(2026, 8, 28, 11),
                color: accent,
                isPreview: true,
              ),
              LayrzCalendarEntry(
                title: 'Cover',
                start: DateTime(2026, 8, 28, 9, 30),
                end: DateTime(2026, 8, 28, 10, 30),
                color: accent,
              ),
            ],
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('Preview'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;

      // Ghosted (border present, translucent fill) AND demoted-by-coverage
      // (fill alpha lower than an uncovered preview's 0.12) -- the two
      // treatments compose rather than one replacing the other.
      expect(decoration.border, isNotNull);
      expect(decoration.color!.a, lessThan(0.12));
    });
  });

  group('assignOverlapColumns', () {
    test('returns an empty list for no entries', () {
      expect(assignOverlapColumns(const []), isEmpty);
    });

    test('a single entry gets columnCount 1 and is never covered', () {
      final entry = LayrzCalendarEntry(
        title: 'Solo',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final result = assignOverlapColumns([entry]);
      expect(result, hasLength(1));
      expect(result.first.columnCount, 1);
      expect(result.first.isCovered, isFalse);
    });

    test('two non-overlapping entries each get columnCount 1', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 28, 9), end: DateTime(2026, 8, 28, 10));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 28, 11), end: DateTime(2026, 8, 28, 12));
      final result = assignOverlapColumns([a, b]);
      expect(result.every((p) => p.columnCount == 1), isTrue);
      expect(result.every((p) => !p.isCovered), isTrue);
    });

    test('two overlapping entries split into 2 columns, the later starter is not covered', () {
      final earlier = LayrzCalendarEntry(
        title: 'Earlier',
        start: DateTime(2026, 8, 28, 11),
        end: DateTime(2026, 8, 28, 12),
      );
      final later = LayrzCalendarEntry(
        title: 'Later',
        start: DateTime(2026, 8, 28, 11, 45),
        end: DateTime(2026, 8, 28, 13, 15),
      );
      final result = assignOverlapColumns([earlier, later]);
      expect(result.every((p) => p.columnCount == 2), isTrue);

      final earlierPlacement = result.firstWhere((p) => p.entry.title == 'Earlier');
      final laterPlacement = result.firstWhere((p) => p.entry.title == 'Later');
      expect(earlierPlacement.isCovered, isTrue);
      expect(laterPlacement.isCovered, isFalse);
    });

    test('order is deterministic: later-starting events appear later in the list (paint on top)', () {
      final a = LayrzCalendarEntry(title: 'A', start: DateTime(2026, 8, 28, 9), end: DateTime(2026, 8, 28, 10));
      final b = LayrzCalendarEntry(title: 'B', start: DateTime(2026, 8, 28, 9, 30), end: DateTime(2026, 8, 28, 11));
      final result = assignOverlapColumns([b, a]); // reversed input order
      expect(result.map((p) => p.entry.title).toList(), ['A', 'B']);
    });
  });
}

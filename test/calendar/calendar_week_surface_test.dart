import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarWeekSurface', () {
    guardedTestWidgets('renders one shared hour axis, not one per column', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      // Exactly one "00:00" label anywhere in the tree -- if the axis were
      // repeated per column, this would find seven.
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
    });

    guardedTestWidgets('default firstDayOfWeek (Sunday) renders columns Sun..Sat in order', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 28 2026 is a Friday; the Sunday-first week containing it runs
      // Aug 23 (Sun) through Aug 29 (Sat).
      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      final headerRow = tester.widget<Row>(find.byType(Row).first);
      final columnTexts = headerRow.children
          .whereType<Expanded>()
          .map((e) => (((e.child as Padding).child) as Column).children.cast<Text>().map((t) => t.data).toList())
          .toList();

      final dayNames = columnTexts.map((column) => column[0]).toList();
      final dayNumbers = columnTexts.map((column) => column[1]).toList();

      expect(dayNames, ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
      expect(dayNumbers, ['23', '24', '25', '26', '27', '28', '29']);
    });

    guardedTestWidgets('firstDayOfWeek: DateTime.monday renders columns Mon..Sun in order', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Monday-first week containing Aug 28 2026 (Friday) runs Aug 24 (Mon)
      // through Aug 30 (Sun).
      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
            firstDayOfWeek: DateTime.monday,
          ),
        ),
      );

      final headerRow = tester.widget<Row>(find.byType(Row).first);
      final columnTexts = headerRow.children
          .whereType<Expanded>()
          .map((e) => (((e.child as Padding).child) as Column).children.cast<Text>().map((t) => t.data).toList())
          .toList();

      final dayNames = columnTexts.map((column) => column[0]).toList();
      final dayNumbers = columnTexts.map((column) => column[1]).toList();

      expect(dayNames, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
      expect(dayNumbers, ['24', '25', '26', '27', '28', '29', '30']);
    });

    guardedTestWidgets(
      'the column header date number uses the title style, not the muted label style',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final theme = LayrzThemeData.light();

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            height: 900,
            child: LayrzCalendarWeekSurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: const [],
            ),
          ),
          theme: theme,
        );

        final headerRow = tester.widget<Row>(find.byType(Row).first);
        final firstColumn = headerRow.children.whereType<Expanded>().first.child as Padding;
        final texts = (firstColumn.child as Column).children.cast<Text>();

        final dayNameStyle = texts[0].style;
        final dayNumberStyle = texts[1].style;

        expect(dayNumberStyle, theme.tokens.typography.title);
        expect(dayNameStyle, theme.tokens.typography.label.copyWith(color: theme.tokens.colors.fg3));
        expect(dayNumberStyle, isNot(dayNameStyle));
      },
    );

    guardedTestWidgets('a multi-day entry in the week band renders as ONE continuous bar, not one per column', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Sunday-first week containing Aug 28 2026 runs Aug 23 (Sun) through
      // Aug 29 (Sat); "Offsite" spans Aug 24-26, columns 1-3 (zero-based).
      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 24), end: DateTime(2026, 8, 26)),
            ],
          ),
        ),
      );

      // Exactly one shared band, and the title renders exactly once -- a
      // 3-day span must read as one continuous shape, matching how
      // LayrzCalendarMonthSurface collapses the same entry into a single
      // bar per week row, not three repeated titles.
      expect(find.byType(AllDayBand), findsOneWidget);
      expect(find.text('Offsite'), findsOneWidget);

      // Geometry: the single bar spans columns 1-3 of 7, so it must start
      // roughly 1/7 of the way into the band's width (past the hour axis)
      // and be roughly 3/7 of the band's usable width wide -- not a single
      // day-column's width, which would indicate three separate uncollapsed
      // segments coincidentally rendering the same text once each.
      final bandBox = tester.getRect(find.byType(AllDayBand));
      final barBox = tester.getRect(
        find.ancestor(of: find.text('Offsite'), matching: find.byType(Container)).first,
      );
      final usableWidth = bandBox.width - kLayrzCalendarHourAxisWidth;
      final columnWidth = usableWidth / 7;

      expect(barBox.left, closeTo(bandBox.left + kLayrzCalendarHourAxisWidth + 1 * columnWidth, 8));
      expect(barBox.width, closeTo(3 * columnWidth, 8));
    });

    guardedTestWidgets('a multi-day entry clipped by the week edges still renders as one bar', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Sunday-first week containing Aug 28 2026 runs Aug 23-29. An entry
      // starting before the week and ending after it must still render as a
      // single bar spanning the full band width, clamped to the visible
      // range -- not one segment per day, and not an exception.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(title: 'Long Trip', start: DateTime(2026, 8, 20), end: DateTime(2026, 9, 3)),
            ],
          ),
        ),
      );

      expect(find.byType(AllDayBand), findsOneWidget);
      expect(find.text('Long Trip'), findsOneWidget);

      final bandBox = tester.getRect(find.byType(AllDayBand));
      final barBox = tester.getRect(
        find.ancestor(of: find.text('Long Trip'), matching: find.byType(Container)).first,
      );
      final usableWidth = bandBox.width - kLayrzCalendarHourAxisWidth;

      // Clamped to the full visible week -- spans (almost) the entire
      // usable width, since neither endpoint falls inside this week.
      expect(barBox.width, closeTo(usableWidth, 8));
    });

    guardedTestWidgets('two non-overlapping multi-day entries each render as their own single bar', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 24), end: DateTime(2026, 8, 25)),
              LayrzCalendarEntry(title: 'Conference', start: DateTime(2026, 8, 27), end: DateTime(2026, 8, 28)),
            ],
          ),
        ),
      );

      expect(find.text('Offsite'), findsOneWidget);
      expect(find.text('Conference'), findsOneWidget);
    });

    guardedTestWidgets('does not render an all-day band when no all-day entries occupy the week', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      expect(find.byType(AllDayBand), findsNothing);
    });

    guardedTestWidgets('the hour grid content ends short of the scroll view edge, reserving room for the scrollbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
          ),
        ),
      );

      final scrollViewRight = tester.getTopRight(find.byType(SingleChildScrollView)).dx;
      // The seven HourGridColumns render left to right in weekDates order, so
      // the last match is the rightmost (Saturday, under the default
      // Sunday-first week) -- the column whose right edge would collide with
      // the scrollbar if no inset were reserved.
      final rightmostColumnRight = tester.getTopRight(find.byType(HourGridColumn).at(6)).dx;

      // Same guarantee as the day surface: the rightmost day column ends
      // kLayrzCalendarHourGridEndPadding short of the scroll view's own right
      // edge, so the globally-installed LayrzScrollbar thumb never paints
      // over an event block reaching the last (rightmost) column.
      expect(scrollViewRight - rightmostColumnRight, closeTo(kLayrzCalendarHourGridEndPadding, 0.5));
    });

    guardedTestWidgets('renders a timed event in its own day column', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: [
              LayrzCalendarEntry(
                title: 'Standup',
                start: DateTime(2026, 8, 25, 9),
                end: DateTime(2026, 8, 25, 9, 30),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Standup'), findsOneWidget);
    });

    guardedTestWidgets('renders hour-axis labels in amPm format when configured', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1400,
          height: 900,
          child: LayrzCalendarWeekSurface(
            focusedDate: DateTime(2026, 8, 28),
            entries: const [],
            timeFormat: LayrzTimeFormat.amPm,
          ),
        ),
      );

      expect(find.text('12 AM'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);
    });

    guardedTestWidgets(
      'a dense week under a non-default (Monday) week start renders without overflowing',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            height: 900,
            child: LayrzCalendarWeekSurface(
              focusedDate: DateTime(2026, 8, 28),
              firstDayOfWeek: DateTime.monday,
              entries: [
                for (var i = 0; i < 5; i++)
                  LayrzCalendarEntry(
                    title: 'Overlap $i',
                    start: DateTime(2026, 8, 26, 9),
                    end: DateTime(2026, 8, 26, 10),
                  ),
              ],
            ),
          ),
        );

        // guardedTestWidgets asserts no RenderFlex overflow occurred; the
        // events all render since a wide viewport gives plenty of column
        // width to split five ways.
        for (var i = 0; i < 5; i++) {
          expect(find.text('Overlap $i'), findsOneWidget);
        }
      },
    );

    group('onTap / LayrzCalendarEntry.onTap', () {
      guardedTestWidgets(
        'with the surface\'s onTap null and no entry carrying its own onTap, every day column is exactly as '
        'display-only as before -- no MouseRegion',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1400,
              height: 900,
              child: LayrzCalendarWeekSurface(
                focusedDate: DateTime(2026, 8, 28),
                entries: [
                  LayrzCalendarEntry(
                    title: 'Standup',
                    start: DateTime(2026, 8, 25, 9),
                    end: DateTime(2026, 8, 25, 9, 30),
                  ),
                ],
              ),
            ),
          );

          expect(find.byType(MouseRegion), findsNothing);
        },
      );

      guardedTestWidgets('tapping empty hour-grid space in a day column fires onTap with that column\'s date', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            height: 900,
            child: LayrzCalendarWeekSurface(
              focusedDate: DateTime(2026, 8, 28),
              firstDayOfWeek: DateTime.monday,
              entries: const [],
              onTap: (d) => tapped = d,
            ),
          ),
        );

        // The first (Monday) day column of the week containing Aug 28 2026
        // (a Friday) is Aug 24. Tap near the top of its grid.
        final gridFinder = find.byType(HourGridColumn).first;
        final gridTopLeft = tester.getTopLeft(gridFinder);
        await tester.tapAt(gridTopLeft + const Offset(5, 5));
        await tester.pump();

        expect(tapped?.year, 2026);
        expect(tapped?.month, 8);
        expect(tapped?.day, 24);
        expect(tapped?.hour, 0);
        expect(tapped?.second, 0);
      });

      guardedTestWidgets('tapping a timed block fires that entry\'s own onTap only, never the surface\'s onTap', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tappedDate;
        var entryTapped = false;
        final entry = LayrzCalendarEntry(
          title: 'Standup',
          start: DateTime(2026, 8, 25, 9),
          end: DateTime(2026, 8, 25, 9, 30),
          onTap: () => entryTapped = true,
        );

        await pumpThemed(
          tester,
          SizedBox(
            width: 1400,
            height: 900,
            child: LayrzCalendarWeekSurface(
              focusedDate: DateTime(2026, 8, 28),
              entries: [entry],
              onTap: (d) => tappedDate = d,
            ),
          ),
        );

        await tester.tap(find.text('Standup'));
        await tester.pump();

        expect(entryTapped, isTrue);
        expect(tappedDate, isNull);
      });

      guardedTestWidgets(
        'tapping an all-day band bar fires that entry\'s own onTap only, never the surface\'s onTap',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          DateTime? tappedDate;
          var entryTapped = false;
          final entry = LayrzCalendarEntry(
            title: 'Offsite',
            start: DateTime(2026, 8, 24),
            end: DateTime(2026, 8, 26),
            onTap: () => entryTapped = true,
          );

          await pumpThemed(
            tester,
            SizedBox(
              width: 1400,
              height: 900,
              child: LayrzCalendarWeekSurface(
                focusedDate: DateTime(2026, 8, 28),
                firstDayOfWeek: DateTime.monday,
                entries: [entry],
                onTap: (d) => tappedDate = d,
              ),
            ),
          );

          await tester.tap(find.text('Offsite'));
          await tester.pump();

          expect(entryTapped, isTrue);
          expect(tappedDate, isNull);
        },
      );
    });
  });
}

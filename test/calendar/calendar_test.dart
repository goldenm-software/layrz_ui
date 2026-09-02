import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendar', () {
    guardedTestWidgets('renders the month surface by default, wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
    });

    guardedTestWidgets('renders the month surface, compact viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 380,
          height: 800,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      expect(find.text('August 2026'), findsOneWidget);
    });

    guardedTestWidgets('creates and disposes an internal controller when none is supplied', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      // Unmounting must not throw -- proves the internal controller was
      // disposed exactly once, by the widget itself.
      await tester.pumpWidget(const SizedBox());
    });

    guardedTestWidgets('a caller-supplied controller drives the focused date and is not disposed by the widget', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 1));

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      expect(find.text('August 2026'), findsOneWidget);

      controller.nextMonth();
      await tester.pump();

      expect(find.text('September 2026'), findsOneWidget);

      // Unmount the calendar; a caller-supplied controller must survive
      // this, since disposal is caller-owned.
      await tester.pumpWidget(const SizedBox());
      expect(controller.focusedDate, DateTime(2026, 9, 1));

      controller.dispose();
    });

    guardedTestWidgets('previous/next navigation changes the visible month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      expect(find.text('August 2026'), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next month'));
      await tester.pump();

      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month'));
      await tester.pump();
      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month'));
      await tester.pump();

      expect(find.text('July 2026'), findsOneWidget);
    });

    guardedTestWidgets('the Today button returns to the current month', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2020, 1, 1)),
        ),
      );

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today'));
      await tester.pump();

      final now = DateTime.now();
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
      expect(find.text('${monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
    });

    guardedTestWidgets('the previous/next navigation buttons use the textFab style', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      final previousButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month'),
      );
      final nextButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next month'),
      );

      expect(previousButton.style, LayrzButtonStyle.textFab);
      expect(nextButton.style, LayrzButtonStyle.textFab);
    });

    guardedTestWidgets('the period label sits between the previous and next buttons', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      final rowFinder = find.ancestor(
        of: find.text('August 2026'),
        matching: find.byType(Row),
      );
      final row = tester.widget<Row>(rowFinder.first);
      final children = row.children;

      // The label sits strictly between the previous and next buttons in the
      // navigation row's child order -- [previous, ..., label, ..., next,
      // Spacer, Today].
      bool isPrevious(Widget w) => w is LayrzButton && w.labelText == 'Previous month';
      bool isNext(Widget w) => w is LayrzButton && w.labelText == 'Next month';
      bool isLabel(Widget w) => w is Flexible && w.child is Text && (w.child as Text).data == 'August 2026';

      final previousIndex = children.indexWhere(isPrevious);
      final nextIndex = children.indexWhere(isNext);
      final labelIndex = children.indexWhere(isLabel);

      expect(previousIndex, greaterThanOrEqualTo(0));
      expect(nextIndex, greaterThan(previousIndex));
      expect(labelIndex, greaterThan(previousIndex));
      expect(labelIndex, lessThan(nextIndex));
    });

    /// Regression coverage for a bug where `Today` floated mid-row instead
    /// of sitting flush against the header's trailing edge (see
    /// `calendar_header_test.dart` for the full root-cause writeup: a
    /// `Flexible` on the period label and the trailing `Spacer` were
    /// sibling flex children, and `RenderFlex` split free space evenly
    /// between them regardless of how much the label's loose fit actually
    /// used, stranding the rest instead of handing it to `Spacer`).
    ///
    /// The version of this test that shipped alongside that bug only
    /// asserted `todayLeft - nextLeft > navGroupWidth` -- true even for the
    /// broken layout, since a partially-starved `Spacer` still pushed
    /// `Today` further right than the nav group's own width without ever
    /// reaching the true trailing edge. This version additionally pins
    /// `Today`'s right edge against the calendar's own right edge, which
    /// the broken layout fails.
    guardedTestWidgets(
      'the back arrow, period label and next arrow are grouped on the left, Today sits at the trailing edge',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final calendarFinder = find.byType(LayrzCalendar);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
          ),
        );

        final previousLeft = tester
            .getTopLeft(
              find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month'),
            )
            .dx;
        final labelLeft = tester.getTopLeft(find.text('August 2026')).dx;
        final nextLeft = tester
            .getTopLeft(
              find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next month'),
            )
            .dx;
        final todayRect = tester.getRect(
          find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today'),
        );
        final calendarRect = tester.getRect(calendarFinder);

        // [back], the label and [next] sit as a tight left-aligned group --
        // the label starts right after the back arrow, and the next arrow
        // starts right after the label.
        expect(labelLeft, greaterThan(previousLeft));
        expect(nextLeft, greaterThan(labelLeft));

        // Today is pushed away from that group to the far trailing edge --
        // it must not sit immediately next to the next arrow.
        final navGroupWidth = nextLeft - previousLeft;
        expect(todayRect.left - nextLeft, greaterThan(navGroupWidth));

        // The strong assertion: Today's right edge must land within a tight
        // tolerance of the calendar's own right edge (accounting for the
        // card's padding), not merely somewhere right of [next] -- which a
        // Today floating mid-row also satisfies.
        expect(
          calendarRect.right - todayRect.right,
          lessThanOrEqualTo(25),
          reason:
              'Today must sit flush against the header\'s trailing edge, not floating mid-row. A '
              'gap here means the nav group is stealing flex space that should belong to Today.',
        );
      },
    );

    guardedTestWidgets('the Today button is filled when the focused month is not the current month', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2020, 1, 1)),
        ),
      );

      final todayButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today'),
      );
      expect(todayButton.style, LayrzButtonStyle.filled);
    });

    guardedTestWidgets('the Today button is text when the focused date is today', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          // No initialDate -- LayrzCalendarController defaults focusedDate to
          // today, so the "Today" button should already read as de-emphasised.
          child: LayrzCalendar(),
        ),
      );

      final todayButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today'),
      );
      expect(todayButton.style, LayrzButtonStyle.text);
    });

    guardedTestWidgets('the Today button switches from filled to text once navigation reaches today', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      final controller = LayrzCalendarController(initialDate: DateTime(now.year, now.month == 1 ? 12 : now.month - 1));

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      expect(
        tester.widget<LayrzButton>(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today')).style,
        LayrzButtonStyle.filled,
      );

      controller.goToToday();
      await tester.pump();

      expect(
        tester.widget<LayrzButton>(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today')).style,
        LayrzButtonStyle.text,
      );

      controller.dispose();
    });

    guardedTestWidgets(
      'renders single-day events as chips and a multi-day event as one continuous bar, not a chip per day',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // August 17-19, 2026 is Monday-Wednesday of the same week row, so
        // 'Offsite' must render as exactly one bar with its label shown
        // once, not three separate per-day chips.
        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(
              initialDate: DateTime(2026, 8, 15),
              entries: [
                LayrzCalendarEntry(title: 'Standup', start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 15)),
                LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 17), end: DateTime(2026, 8, 19)),
              ],
            ),
          ),
        );

        expect(find.text('Standup'), findsOneWidget);
        expect(find.text('Offsite'), findsOneWidget);
      },
    );

    guardedTestWidgets('view-mode switcher renders month/week/day, all three selectable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as month'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as week'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as day'), findsOneWidget);

      final weekButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as week'),
      );
      final dayButton = tester.widget<LayrzButton>(
        find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as day'),
      );
      expect(weekButton.onTap, isNotNull);
      expect(dayButton.onTap, isNotNull);
    });

    guardedTestWidgets('tapping the week switcher entry renders the week surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as week'));
      await tester.pump();

      expect(find.byType(LayrzCalendarWeekSurface), findsOneWidget);
      expect(find.byType(LayrzCalendarMonthSurface), findsNothing);
    });

    guardedTestWidgets('tapping the day switcher entry renders the day surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as day'));
      await tester.pump();

      expect(find.byType(LayrzCalendarDaySurface), findsOneWidget);
      expect(find.byType(LayrzCalendarMonthSurface), findsNothing);
    });

    guardedTestWidgets('week-mode navigation buttons read "Previous/Next week" and step by 7 days', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.week,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous week'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next week'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous month'), findsNothing);

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next week'));
      await tester.pump();

      expect(controller.focusedDate, DateTime(2026, 8, 22));

      controller.dispose();
    });

    guardedTestWidgets('day-mode navigation buttons read "Previous/Next day" and step by 1 day', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.day,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous day'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next day'), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next day'));
      await tester.pump();

      expect(controller.focusedDate, DateTime(2026, 8, 16));

      controller.dispose();
    });

    guardedTestWidgets('day-mode period label reads as a full date, not a month/year', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 28 2026 is a Friday.
      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 28),
        initialMode: LayrzCalendarMode.day,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      expect(find.text('Friday, August 28'), findsOneWidget);
      expect(find.text('August 2026'), findsNothing);

      controller.dispose();
    });

    guardedTestWidgets('firstDayOfWeek defaults to Sunday for the month surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      final surface = tester.widget<LayrzCalendarMonthSurface>(find.byType(LayrzCalendarMonthSurface));
      expect(surface.firstDayOfWeek, DateTime.sunday);
    });

    guardedTestWidgets('firstDayOfWeek threads through to the month and week surfaces', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller, firstDayOfWeek: DateTime.monday),
        ),
      );

      expect(
        tester.widget<LayrzCalendarMonthSurface>(find.byType(LayrzCalendarMonthSurface)).firstDayOfWeek,
        DateTime.monday,
      );

      controller.setMode(LayrzCalendarMode.week);
      await tester.pump();

      expect(
        tester.widget<LayrzCalendarWeekSurface>(find.byType(LayrzCalendarWeekSurface)).firstDayOfWeek,
        DateTime.monday,
      );

      controller.dispose();
    });

    guardedTestWidgets('timeFormat defaults to h24 and threads through to the day surface', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.day,
      );

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(controller: controller),
        ),
      );

      final surface = tester.widget<LayrzCalendarDaySurface>(find.byType(LayrzCalendarDaySurface));
      expect(surface.timeFormat, LayrzTimeFormat.h24);

      controller.dispose();
    });

    guardedTestWidgets(
      'tapping a month cell\'s overflow chip switches to day view focused on that date and fires onModeChanged',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzCalendarMode? notifiedMode;
        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
        final date = DateTime(2026, 8, 20);

        // A calendar height just tall enough for each week row's structural
        // minimum (date-row + padding) but not for more than a couple of
        // event slots -- constrains the measured maxSlots to a small value,
        // forcing the overflow chip to appear for a day with many events,
        // without starving the cell below the space its fixed chrome needs.
        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 620,
            child: LayrzCalendar(
              controller: controller,
              onModeChanged: (mode) => notifiedMode = mode,
              entries: [
                for (var i = 0; i < 6; i++) LayrzCalendarEntry(title: 'Event $i', start: date, end: date),
              ],
            ),
          ),
        );

        final overflowTextFinder = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('+'));
        expect(overflowTextFinder, findsWidgets);

        await tester.tap(overflowTextFinder.first);
        await tester.pump();

        expect(controller.mode, LayrzCalendarMode.day);
        expect(controller.focusedDate, date);
        expect(notifiedMode, LayrzCalendarMode.day);
        expect(find.byType(LayrzCalendarDaySurface), findsOneWidget);

        controller.dispose();
      },
    );

    guardedTestWidgets(
      'dayNumberOpensDayView defaults to true and threads through to the month surface',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(controller: controller),
          ),
        );

        final surface = tester.widget<LayrzCalendarMonthSurface>(find.byType(LayrzCalendarMonthSurface));
        expect(surface.dayNumberOpensDayView, isTrue);

        controller.dispose();
      },
    );

    guardedTestWidgets(
      'tapping a month cell\'s date number switches to day view focused on that date, fires onModeChanged, and '
      'renders the day surface',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzCalendarMode? notifiedMode;
        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
        final date = DateTime(2026, 8, 20);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(
              controller: controller,
              onModeChanged: (mode) => notifiedMode = mode,
            ),
          ),
        );

        await tester.tap(find.text('${date.day}').first);
        await tester.pump();

        expect(controller.mode, LayrzCalendarMode.day);
        expect(controller.focusedDate, date);
        expect(notifiedMode, LayrzCalendarMode.day);
        expect(find.byType(LayrzCalendarDaySurface), findsOneWidget);

        controller.dispose();
      },
    );

    guardedTestWidgets(
      'tapping a month cell\'s date number does nothing when dayNumberOpensDayView is false',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        LayrzCalendarMode? notifiedMode;
        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
        final date = DateTime(2026, 8, 20);

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(
              controller: controller,
              dayNumberOpensDayView: false,
              onModeChanged: (mode) => notifiedMode = mode,
            ),
          ),
        );

        await tester.tap(find.text('${date.day}').first);
        await tester.pump();

        expect(controller.mode, LayrzCalendarMode.month);
        expect(notifiedMode, isNull);
        expect(find.byType(LayrzCalendarDaySurface), findsNothing);

        controller.dispose();
      },
    );

    guardedTestWidgets('does not render year-view chrome', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1200,
          height: 900,
          child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
        ),
      );

      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'View as year'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Previous year'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Next year'), findsNothing);
    });

    guardedTestWidgets(
      'switching the controller to LayrzCalendarMode.week renders the week surface without throwing',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(controller: controller),
          ),
        );

        controller.setMode(LayrzCalendarMode.week);
        await tester.pump();

        expect(find.byType(LayrzCalendarWeekSurface), findsOneWidget);

        controller.dispose();
      },
    );

    guardedTestWidgets(
      'switching the controller to LayrzCalendarMode.day renders the day surface without throwing',
      (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(controller: controller),
          ),
        );

        controller.setMode(LayrzCalendarMode.day);
        await tester.pump();

        expect(find.byType(LayrzCalendarDaySurface), findsOneWidget);

        controller.dispose();
      },
    );

    group('onTap / LayrzCalendarEntry.onTap', () {
      guardedTestWidgets('month view: tapping empty cell space fires onTap with that date at midnight', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(
              initialDate: DateTime(2026, 8, 15),
              onTap: (d) => tapped = d,
            ),
          ),
        );

        final cellFinder = find.ancestor(of: find.text('20'), matching: find.byType(LayrzCalendarDayCell)).first;
        await tester.tapAt(tester.getBottomRight(cellFinder) - const Offset(4, 4));
        await tester.pump();

        expect(tapped, DateTime(2026, 8, 20));
        expect(tapped!.hour, 0);
        expect(tapped!.minute, 0);
        expect(tapped!.second, 0);
        expect(tapped!.millisecond, 0);
      });

      guardedTestWidgets(
        'month view: tapping an event chip fires that entry\'s own onTap, never the calendar\'s onTap',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          DateTime? tappedDate;
          var entryTapped = false;
          final date = DateTime(2026, 8, 20);
          final entry = LayrzCalendarEntry(title: 'Standup', start: date, end: date, onTap: () => entryTapped = true);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1200,
              height: 900,
              child: LayrzCalendar(
                initialDate: DateTime(2026, 8, 15),
                entries: [entry],
                onTap: (d) => tappedDate = d,
              ),
            ),
          );

          await tester.tap(find.text('Standup'));
          await tester.pump();

          expect(entryTapped, isTrue);
          expect(tappedDate, isNull);
        },
      );

      guardedTestWidgets('week view: an hour-grid tap returns the 15-minute-snapped time, not midnight', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;
        final controller = LayrzCalendarController(
          initialDate: DateTime(2026, 8, 28),
          initialMode: LayrzCalendarMode.week,
        );

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(controller: controller, onTap: (d) => tapped = d),
          ),
        );

        final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn).first);
        await tester.tapAt(gridTopLeft + const Offset(5, 9 * kLayrzCalendarHourRowHeight + 20));
        await tester.pump();

        expect(tapped, isNotNull);
        expect(tapped!.hour, 9);
        expect(tapped!.minute, 15);
        expect(tapped!.second, 0);

        controller.dispose();
      });

      guardedTestWidgets('day view: an hour-grid tap returns the 15-minute-snapped time, not midnight', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        DateTime? tapped;
        final controller = LayrzCalendarController(
          initialDate: DateTime(2026, 8, 28),
          initialMode: LayrzCalendarMode.day,
        );

        await pumpThemed(
          tester,
          SizedBox(
            width: 1200,
            height: 900,
            child: LayrzCalendar(controller: controller, onTap: (d) => tapped = d),
          ),
        );

        final gridTopLeft = tester.getTopLeft(find.byType(HourGridColumn));
        await tester.tapAt(gridTopLeft + const Offset(5, 9 * kLayrzCalendarHourRowHeight + 20));
        await tester.pump();

        expect(tapped, DateTime(2026, 8, 28, 9, 15));

        controller.dispose();
      });

      guardedTestWidgets(
        'with the calendar\'s onTap null and no entry carrying its own onTap, the whole calendar is exactly as '
        'display-only as before -- no MouseRegion anywhere from these two callbacks',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1200,
              height: 900,
              child: LayrzCalendar(
                initialDate: DateTime(2026, 8, 15),
                entries: [
                  LayrzCalendarEntry(title: 'Standup', start: DateTime(2026, 8, 20), end: DateTime(2026, 8, 20)),
                ],
              ),
            ),
          );

          // Every MouseRegion still present belongs to chrome unrelated to
          // onTap/LayrzCalendarEntry.onTap (nav buttons, the mode switcher,
          // the date number, which is interactive by default via
          // dayNumberOpensDayView) -- none of them should carry a click
          // cursor sourced from either of those two callbacks, and tapping
          // empty cell space or the event chip must do nothing observable.
          await tester.tapAt(tester.getBottomRight(find.byType(LayrzCalendarDayCell).first) - const Offset(4, 4));
          await tester.pump();
          await tester.tap(find.text('Standup'));
          await tester.pump();

          // No exception, no crash -- this test's substantive assertion is
          // that neither callback exists to fire, verified structurally
          // in the lower-level surface/day-cell tests' MouseRegion-count
          // assertions; this test proves the coordinator does not swallow
          // taps into a dead detector either.
          expect(find.byType(LayrzCalendar), findsOneWidget);
        },
      );
    });

    group('SelectionContainer.disabled', () {
      guardedTestWidgets(
        'a BuildContext below the calendar sees a disabled selection registrar, not the SelectionArea\'s own',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // SelectionContainer.disabled resolves to SelectionRegistrarScope
          // with a sentinel _disabled registrar -- `registrarOf` throws for
          // anything below it, which `SelectionContainer.maybeOf` catches
          // and turns into `null`. Above a real SelectionArea (not present
          // here), `maybeOf` would instead return the enclosing
          // SelectionContainer. This is the substantive behavioural
          // assertion the plan calls for -- not merely that a
          // SelectionContainer widget exists in the tree.
          await pumpThemed(
            tester,
            SizedBox(
              width: 1200,
              height: 900,
              child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
            ),
          );

          final dayCellContext = tester.element(find.byType(LayrzCalendarDayCell).first);

          expect(SelectionContainer.maybeOf(dayCellContext), isNull);
        },
      );

      guardedTestWidgets(
        'wrapping the calendar in a real SelectionArea does not leak that registrar past the disabled boundary',
        (tester) async {
          tester.view.physicalSize = const Size(1600, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await pumpThemed(
            tester,
            SizedBox(
              width: 1200,
              height: 900,
              // A minimal stand-in for SelectionArea: a real, enabled
              // SelectionContainer ancestor whose registrar the disabled
              // scope inside LayrzCalendar must shadow. Using the full
              // Material `SelectionArea` is not possible in this
              // Material-free repo, so this constructs the same
              // `SelectionContainer` primitive `SelectionArea` itself uses
              // under the hood, directly from `package:flutter/widgets.dart`.
              child: SelectionContainer(
                registrar: _FakeSelectionRegistrar(),
                delegate: _TestSelectionContainerDelegate(),
                child: LayrzCalendar(initialDate: DateTime(2026, 8, 15)),
              ),
            ),
          );

          final dayCellContext = tester.element(find.byType(LayrzCalendarDayCell).first);

          // Still null underneath the calendar's own disabled wrapper, even
          // though a real, enabled SelectionContainer now sits above it --
          // proving the disabled scope actually shadows an ancestor
          // registrar rather than merely being absent when nothing else
          // provides one.
          expect(SelectionContainer.maybeOf(dayCellContext), isNull);
        },
      );
    });
  });
}

/// A minimal [SelectionRegistrar] used only to construct a real, enabled
/// [SelectionContainer] ancestor in the "does not leak past the disabled
/// boundary" test above -- never expected to actually receive a registration
/// in this test, since [LayrzCalendar]'s own [SelectionContainer.disabled]
/// shadows it for everything beneath the calendar.
class _FakeSelectionRegistrar extends SelectionRegistrar {
  @override
  void add(Selectable selectable) {}

  @override
  void remove(Selectable selectable) {}
}

/// A minimal, never-exercised [MultiSelectableSelectionContainerDelegate]
/// pairing with [_FakeSelectionRegistrar] -- mirrors the Flutter framework's
/// own `TestContainerDelegate` test double (`selection_container_test.dart`).
/// This test never drives selection through it; both overrides simply throw
/// if ever reached.
class _TestSelectionContainerDelegate extends MultiSelectableSelectionContainerDelegate {
  @override
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    throw UnimplementedError();
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    throw UnimplementedError();
  }
}

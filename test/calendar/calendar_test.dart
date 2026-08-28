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

    guardedTestWidgets('the previous/next navigation buttons use the outlinedTonalFab style', (tester) async {
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

      expect(previousButton.style, LayrzButtonStyle.outlinedTonalFab);
      expect(nextButton.style, LayrzButtonStyle.outlinedTonalFab);
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
      // ..., Today].
      bool isPrevious(Widget w) => w is LayrzButton && w.labelText == 'Previous month';
      bool isNext(Widget w) => w is LayrzButton && w.labelText == 'Next month';
      bool isLabel(Widget w) => w is Expanded && w.child is Text && (w.child as Text).data == 'August 2026';

      final previousIndex = children.indexWhere(isPrevious);
      final nextIndex = children.indexWhere(isNext);
      final labelIndex = children.indexWhere(isLabel);

      expect(previousIndex, greaterThanOrEqualTo(0));
      expect(nextIndex, greaterThan(previousIndex));
      expect(labelIndex, greaterThan(previousIndex));
      expect(labelIndex, lessThan(nextIndex));
    });

    guardedTestWidgets('the Today button is elevated when the focused month is not the current month', (
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
      expect(todayButton.style, LayrzButtonStyle.elevated);
    });

    guardedTestWidgets('the Today button is outlinedTonal when the focused date is today', (tester) async {
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
      expect(todayButton.style, LayrzButtonStyle.outlinedTonal);
    });

    guardedTestWidgets('the Today button switches from elevated to outlinedTonal once navigation reaches today', (
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
        LayrzButtonStyle.elevated,
      );

      controller.goToToday();
      await tester.pump();

      expect(
        tester.widget<LayrzButton>(find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == 'Today')).style,
        LayrzButtonStyle.outlinedTonal,
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

    guardedTestWidgets('view-mode switcher renders month/week/day and week/day are disabled', (tester) async {
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
      expect(weekButton.onTap, isNull);
      expect(dayButton.onTap, isNull);
    });

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
      'throws UnimplementedError when the controller is switched to a mode this pass does not render',
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

        expect(tester.takeException(), isA<UnimplementedError>());

        controller.dispose();
      },
    );

    guardedTestWidgets(
      'throws UnimplementedError for LayrzCalendarMode.day too, not only week',
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

        expect(tester.takeException(), isA<UnimplementedError>());

        controller.dispose();
      },
    );
  });
}

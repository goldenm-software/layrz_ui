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

    guardedTestWidgets('renders single-day and multi-day events without breaking the grid', (tester) async {
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
              LayrzCalendarEntry(title: 'Standup', start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 15)),
              LayrzCalendarEntry(title: 'Offsite', start: DateTime(2026, 8, 17), end: DateTime(2026, 8, 19)),
            ],
          ),
        ),
      );

      expect(find.text('Standup'), findsOneWidget);
      expect(find.text('Offsite'), findsNWidgets(3));
    });

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

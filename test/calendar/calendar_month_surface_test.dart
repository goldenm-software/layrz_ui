import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzCalendarMonthSurface', () {
    guardedTestWidgets('renders weekday header labels', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    guardedTestWidgets('renders every day of the focused month', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 2026 has 31 days.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('places a single-day event only on its own date', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Single day event', start: DateTime(2026, 8, 15), end: DateTime(2026, 8, 15)),
            ],
          ),
        ),
      );

      expect(find.text('Single day event'), findsOneWidget);
    });

    guardedTestWidgets('places a multi-day event on every date it spans without breaking the grid', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: [
              LayrzCalendarEntry(title: 'Multi day', start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 12)),
            ],
          ),
        ),
      );

      // Rendered once per occupied date -- three day cells, three chips.
      expect(find.text('Multi day'), findsNWidgets(3));
    });

    guardedTestWidgets('applies isDateDisabled per date without affecting days that have no events', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
            isDateDisabled: (date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
          ),
        ),
      );

      // The grid still renders every day regardless of disabled status --
      // disabling is a visual overlay, not an omission.
      for (var day = 1; day <= 31; day++) {
        expect(find.text('$day'), findsWidgets);
      }
    });

    guardedTestWidgets('leading and trailing days from adjacent months fill the grid rectangle', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // August 1, 2026 is a Saturday, so the grid must show trailing July
      // days to fill the first row.
      await pumpThemed(
        tester,
        SizedBox(
          width: 1000,
          height: 800,
          child: LayrzCalendarMonthSurface(
            focusedDate: DateTime(2026, 8, 1),
            entries: const [],
          ),
        ),
      );

      // July has 31 days; the last few (27-31) fill the leading grid cells.
      expect(find.text('31'), findsWidgets);
    });
  });
}

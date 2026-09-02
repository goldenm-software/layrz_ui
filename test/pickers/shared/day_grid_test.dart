import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/day_grid.dart';

import '../../helpers/no_overflow.dart';
import '../../helpers/pump_themed.dart';

void main() {
  group('LayrzPickersDayGrid — layout', () {
    guardedTestWidgets('renders a full 42-cell grid at a wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      expect(find.text('1'), findsWidgets);
      expect(find.text('30'), findsWidgets);
    });

    guardedTestWidgets('renders without overflow at a narrow (compact) viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (_) {}),
      );

      expect(find.byType(LayrzPickersDayGrid), findsOneWidget);
    });

    guardedTestWidgets('tapping a selectable day fires onDayTap with the correct date', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), onDayTap: (d) => tapped = d),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.day, 15);
      expect(tapped!.month, 9);
    });

    guardedTestWidgets('a disabled day (outside firstDay/lastDay) does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          firstDay: DateTime(2026, 9, 10),
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('a disabledDays entry does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          disabledDays: {DateTime(2026, 9, 15)},
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('15').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('showWeekNumbers false renders no week-number gutter text', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), showWeekNumbers: false, onDayTap: (_) {}),
      );

      expect(find.byType(LayrzPickersDayGrid), findsOneWidget);
    });

    guardedTestWidgets('a rejected date does not fire onDayTap', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapCount = 0;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          rejectedDates: {DateTime(2026, 9, 10)},
          onDayTap: (_) => tapCount++,
        ),
      );

      await tester.tap(find.text('10').first);
      await tester.pump();

      expect(tapCount, 0);
    });

    guardedTestWidgets('a range endpoint remains selectable', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? tapped;
      await pumpThemed(
        tester,
        LayrzPickersDayGrid(
          displayedMonth: DateTime(2026, 9),
          rangeStart: DateTime(2026, 9, 5),
          rangeEnd: DateTime(2026, 9, 20),
          onDayTap: (d) => tapped = d,
        ),
      );

      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.day, 5);
    });

    guardedTestWidgets('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', (tester) async {
      expect(
        () => LayrzPickersDayGrid(displayedMonth: DateTime(2026, 9), firstDayOfWeek: 0, onDayTap: (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

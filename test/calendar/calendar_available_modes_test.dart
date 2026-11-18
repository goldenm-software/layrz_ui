import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void _wideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder _button(String label) => find.byWidgetPredicate((w) => w is LayrzButton && w.labelText == label);

Finder _weekNumber(String number) =>
    find.descendant(of: find.byType(LayrzCalendarWeekGutter), matching: find.text(number));

Finder get _overflowChip => find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('+'));

Future<void> _pumpCalendar(WidgetTester tester, LayrzCalendar calendar, {double height = 900}) {
  return pumpThemed(tester, SizedBox(width: 1200, height: height, child: calendar));
}

List<LayrzCalendarEntry> _crowdedDay(DateTime date) => [
  for (var i = 0; i < 6; i++) LayrzCalendarEntry(title: 'Event $i', start: date, end: date),
];

void main() {
  group('LayrzCalendar availableModes', () {
    guardedTestWidgets('defaults to all three modes, all shown in the switcher', (tester) async {
      _wideViewport(tester);
      await _pumpCalendar(tester, LayrzCalendar(initialDate: DateTime(2026, 8, 15)));

      final calendar = tester.widget<LayrzCalendar>(find.byType(LayrzCalendar));
      expect(calendar.availableModes, {LayrzCalendarMode.month, LayrzCalendarMode.week, LayrzCalendarMode.day});
      expect(_button('View as month'), findsOneWidget);
      expect(_button('View as week'), findsOneWidget);
      expect(_button('View as day'), findsOneWidget);
    });

    guardedTestWidgets('{month} hides the switcher and keeps navigation', (tester) async {
      _wideViewport(tester);
      await _pumpCalendar(
        tester,
        LayrzCalendar(initialDate: DateTime(2026, 8, 15), availableModes: const {LayrzCalendarMode.month}),
      );

      expect(_button('View as month'), findsNothing);
      expect(_button('View as week'), findsNothing);
      expect(_button('View as day'), findsNothing);
      expect(_button('Next month'), findsOneWidget);
      expect(_button('Today'), findsOneWidget);
    });

    guardedTestWidgets('{month, week} shows month and week but no day button', (tester) async {
      _wideViewport(tester);
      await _pumpCalendar(
        tester,
        LayrzCalendar(
          initialDate: DateTime(2026, 8, 15),
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.week},
        ),
      );

      expect(_button('View as month'), findsOneWidget);
      expect(_button('View as week'), findsOneWidget);
      expect(_button('View as day'), findsNothing);
    });

    guardedTestWidgets('day number does not open day view when day is unavailable', (tester) async {
      _wideViewport(tester);
      LayrzCalendarMode? notified;
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.week},
          onModeChanged: (mode) => notified = mode,
        ),
      );

      final surface = tester.widget<LayrzCalendarMonthSurface>(find.byType(LayrzCalendarMonthSurface));
      expect(surface.dayNumberOpensDayView, isFalse);

      await tester.tap(find.text('20').first);
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.month);
      expect(notified, isNull);
      expect(find.byType(LayrzCalendarDaySurface), findsNothing);
    });

    guardedTestWidgets('day number still opens day view when day is available', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.day},
        ),
      );

      await tester.tap(find.text('20').first);
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.day);
      expect(controller.focusedDate, DateTime(2026, 8, 20));
    });

    guardedTestWidgets('the +N chip still renders but does not navigate when day is unavailable', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month},
          entries: _crowdedDay(DateTime(2026, 8, 20)),
        ),
        height: 620,
      );

      final surface = tester.widget<LayrzCalendarMonthSurface>(find.byType(LayrzCalendarMonthSurface));
      expect(surface.onOverflowTap, isNull);
      expect(_overflowChip, findsWidgets);

      await tester.tap(_overflowChip.first);
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.month);
      expect(find.byType(LayrzCalendarDaySurface), findsNothing);
    });

    guardedTestWidgets('the +N chip navigates to day view when day is available', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.day},
          entries: _crowdedDay(DateTime(2026, 8, 20)),
        ),
        height: 620,
      );

      await tester.tap(_overflowChip.first);
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.day);
    });

    guardedTestWidgets('week numbers still render but do not navigate when week is unavailable', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.day},
        ),
      );

      final gutter = tester.widget<LayrzCalendarWeekGutter>(find.byType(LayrzCalendarWeekGutter));
      expect(gutter.onWeekTap, isNull);
      expect(_weekNumber('33'), findsOneWidget);

      await tester.tap(_weekNumber('33'));
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.month);
      expect(find.byType(LayrzCalendarWeekSurface), findsNothing);
    });

    guardedTestWidgets('week numbers navigate to week view when week is available', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.week},
        ),
      );

      await tester.tap(_weekNumber('33'));
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.week);
      expect(controller.focusedDate, DateTime(2026, 8, 16));
    });

    guardedTestWidgets('initialMode outside availableModes falls back to the first available mode', (tester) async {
      _wideViewport(tester);
      await _pumpCalendar(
        tester,
        LayrzCalendar(
          initialDate: DateTime(2026, 8, 15),
          initialMode: LayrzCalendarMode.day,
          availableModes: const {LayrzCalendarMode.week, LayrzCalendarMode.month},
        ),
      );

      expect(find.byType(LayrzCalendarMonthSurface), findsOneWidget);
      expect(find.byType(LayrzCalendarDaySurface), findsNothing);
    });

    guardedTestWidgets('an external controller on an unavailable mode is corrected on init', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.day,
      );
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(controller: controller, availableModes: const {LayrzCalendarMode.week}),
      );

      expect(controller.mode, LayrzCalendarMode.week);
      expect(find.byType(LayrzCalendarWeekSurface), findsOneWidget);
    });

    guardedTestWidgets('external setMode to an unavailable mode reverts to an available one', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 15));
      addTearDown(controller.dispose);

      await _pumpCalendar(
        tester,
        LayrzCalendar(
          controller: controller,
          availableModes: const {LayrzCalendarMode.month, LayrzCalendarMode.week},
        ),
      );

      controller.setMode(LayrzCalendarMode.day);
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.month);
      expect(find.byType(LayrzCalendarMonthSurface), findsOneWidget);
      expect(find.byType(LayrzCalendarDaySurface), findsNothing);
    });

    guardedTestWidgets('narrowing availableModes on rebuild moves off a now-unavailable mode', (tester) async {
      _wideViewport(tester);
      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 8, 15),
        initialMode: LayrzCalendarMode.week,
      );
      addTearDown(controller.dispose);
      late StateSetter setModes;
      var modes = const {LayrzCalendarMode.month, LayrzCalendarMode.week, LayrzCalendarMode.day};

      await pumpThemed(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setModes = setState;
            return SizedBox(
              width: 1200,
              height: 900,
              child: LayrzCalendar(controller: controller, availableModes: modes),
            );
          },
        ),
      );
      expect(find.byType(LayrzCalendarWeekSurface), findsOneWidget);

      setModes(() => modes = const {LayrzCalendarMode.month});
      await tester.pump();

      expect(controller.mode, LayrzCalendarMode.month);
      expect(find.byType(LayrzCalendarMonthSurface), findsOneWidget);
      expect(_button('View as week'), findsNothing);
    });

    guardedTestWidgets('an empty availableModes set asserts', (tester) async {
      _wideViewport(tester);
      await _pumpCalendar(tester, LayrzCalendar(initialDate: DateTime(2026, 8, 15), availableModes: const {}));

      expect(tester.takeException(), isAssertionError);
    });
  });
}

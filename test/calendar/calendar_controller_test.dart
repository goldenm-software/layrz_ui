import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzCalendarController', () {
    test('defaults focusedDate to today (normalized to midnight)', () {
      final controller = LayrzCalendarController();
      final today = DateTime.now();

      expect(controller.focusedDate.year, today.year);
      expect(controller.focusedDate.month, today.month);
      expect(controller.focusedDate.day, today.day);
      expect(controller.focusedDate.hour, 0);
      expect(controller.focusedDate.minute, 0);

      controller.dispose();
    });

    test('defaults mode to LayrzCalendarMode.month', () {
      final controller = LayrzCalendarController();

      expect(controller.mode, LayrzCalendarMode.month);

      controller.dispose();
    });

    test('honours initialDate and initialMode', () {
      final controller = LayrzCalendarController(
        initialDate: DateTime(2026, 3, 15),
        initialMode: LayrzCalendarMode.week,
      );

      expect(controller.focusedDate, DateTime(2026, 3, 15));
      expect(controller.mode, LayrzCalendarMode.week);

      controller.dispose();
    });

    test('nextMonth advances to the first day of the following month and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.nextMonth();

      expect(controller.focusedDate, DateTime(2026, 9, 1));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('nextMonth rolls over the year boundary', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 12, 10));

      controller.nextMonth();

      expect(controller.focusedDate, DateTime(2027, 1, 1));

      controller.dispose();
    });

    test('previousMonth moves back one month and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.previousMonth();

      expect(controller.focusedDate, DateTime(2026, 7, 1));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('previousMonth rolls back across the year boundary', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 1, 10));

      controller.previousMonth();

      expect(controller.focusedDate, DateTime(2025, 12, 1));

      controller.dispose();
    });

    test('goToToday sets focusedDate to today at midnight and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2020, 1, 1));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.goToToday();

      final today = DateTime.now();
      expect(controller.focusedDate.year, today.year);
      expect(controller.focusedDate.month, today.month);
      expect(controller.focusedDate.day, today.day);
      expect(notified, isTrue);

      controller.dispose();
    });

    test('goToDate normalizes to midnight and notifies', () {
      final controller = LayrzCalendarController();
      var notified = false;
      controller.addListener(() => notified = true);

      controller.goToDate(DateTime(2026, 5, 4, 17, 30));

      expect(controller.focusedDate, DateTime(2026, 5, 4));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('setMode updates mode and notifies when the mode actually changes', () {
      final controller = LayrzCalendarController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setMode(LayrzCalendarMode.day);

      expect(controller.mode, LayrzCalendarMode.day);
      expect(notifyCount, 1);

      controller.dispose();
    });

    test('setMode is a no-op and does not notify when the mode is unchanged', () {
      final controller = LayrzCalendarController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setMode(LayrzCalendarMode.month);

      expect(notifyCount, 0);

      controller.dispose();
    });

    test('nextWeek advances focusedDate by exactly 7 calendar days and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.nextWeek();

      expect(controller.focusedDate, DateTime(2026, 9, 4));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('previousWeek moves focusedDate back by exactly 7 calendar days and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.previousWeek();

      expect(controller.focusedDate, DateTime(2026, 8, 21));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('nextDay advances focusedDate by exactly 1 calendar day and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.nextDay();

      expect(controller.focusedDate, DateTime(2026, 8, 29));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('previousDay moves focusedDate back by exactly 1 calendar day and notifies', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 28));
      var notified = false;
      controller.addListener(() => notified = true);

      controller.previousDay();

      expect(controller.focusedDate, DateTime(2026, 8, 27));
      expect(notified, isTrue);

      controller.dispose();
    });

    test('nextWeek rolls over a month boundary via calendar-date stepping, not Duration', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 8, 29));

      controller.nextWeek();

      // August has 31 days: Aug 29 + 7 = Sept 5, via DateTime field overflow
      // normalization -- never `add(Duration(days: 7))`.
      expect(controller.focusedDate, DateTime(2026, 9, 5));

      controller.dispose();
    });

    test('nextDay rolls over a year boundary via calendar-date stepping, not Duration', () {
      final controller = LayrzCalendarController(initialDate: DateTime(2026, 12, 31));

      controller.nextDay();

      expect(controller.focusedDate, DateTime(2027, 1, 1));

      controller.dispose();
    });
  });
}

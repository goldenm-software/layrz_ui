import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/pickers/src/shared/grid_math.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  group('gridPageFor', () {
    test('always returns exactly 42 dates', () {
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.length, 42);
    });

    test('the first row starts on firstDayOfWeek (Monday)', () {
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.first.weekday, DateTime.monday);
    });

    test('the first row starts on firstDayOfWeek (Sunday)', () {
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.sunday);
      expect(page.first.weekday, DateTime.sunday);
    });

    test('a month starting exactly on firstDayOfWeek has no leading adjacent days', () {
      // September 2025 starts on a Monday.
      final page = gridPageFor(reference: DateTime(2025, 9), year: 2025, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.first, DateTime(2025, 9, 1));
    });

    test('includes leading days from the previous month when the month does not start on firstDayOfWeek', () {
      // September 2026 starts on a Tuesday.
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.first, DateTime(2026, 8, 31));
    });

    test('includes trailing days from the next month to fill 42 cells', () {
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.last.isAfter(DateTime(2026, 9, 30)), isTrue);
    });

    test('dates are in strictly ascending calendar-day order', () {
      final page = gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      for (var i = 1; i < page.length; i++) {
        expect(page[i].isAfter(page[i - 1]), isTrue);
      }
    });

    test('handles a leap-year February correctly', () {
      final page = gridPageFor(reference: DateTime(2028, 2), year: 2028, month: 2, firstDayOfWeek: DateTime.monday);
      expect(page.any((d) => d.year == 2028 && d.month == 2 && d.day == 29), isTrue);
    });

    test('preserves TZDateTime zone via the reference parameter', () {
      tz_data.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      final reference = tz.TZDateTime(location, 2026, 9);
      final page = gridPageFor(reference: reference, year: 2026, month: 9, firstDayOfWeek: DateTime.monday);
      expect(page.every((d) => d is tz.TZDateTime), isTrue);
      expect((page.first as tz.TZDateTime).location, location);
    });

    test('asserts firstDayOfWeek is within DateTime.monday..DateTime.sunday', () {
      expect(
        () => gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => gridPageFor(reference: DateTime(2026, 9), year: 2026, month: 9, firstDayOfWeek: 8),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('isInGridMonth', () {
    test('is true for a date within the given month', () {
      expect(isInGridMonth(DateTime(2026, 9, 15), year: 2026, month: 9), isTrue);
    });

    test('is false for a leading adjacent-month date', () {
      expect(isInGridMonth(DateTime(2026, 8, 31), year: 2026, month: 9), isFalse);
    });

    test('is false for a trailing adjacent-month date', () {
      expect(isInGridMonth(DateTime(2026, 10, 1), year: 2026, month: 9), isFalse);
    });
  });

  group('isSameDay', () {
    test('is true for two DateTimes on the same calendar day with different times', () {
      expect(isSameDay(DateTime(2026, 9, 15, 8), DateTime(2026, 9, 15, 22)), isTrue);
    });

    test('is false for different calendar days', () {
      expect(isSameDay(DateTime(2026, 9, 15), DateTime(2026, 9, 16)), isFalse);
    });
  });

  group('monthGridPageFor', () {
    test('returns exactly 12 months, January through December', () {
      final page = monthGridPageFor(reference: DateTime(2026), year: 2026);
      expect(page.length, 12);
      expect(page.first.month, 1);
      expect(page.last.month, 12);
    });

    test('every entry falls in the requested year', () {
      final page = monthGridPageFor(reference: DateTime(2026), year: 2026);
      expect(page.every((d) => d.year == 2026), isTrue);
    });

    test('preserves TZDateTime zone via the reference parameter', () {
      tz_data.initializeTimeZones();
      final location = tz.getLocation('Europe/Madrid');
      final reference = tz.TZDateTime(location, 2026);
      final page = monthGridPageFor(reference: reference, year: 2026);
      expect(page.every((d) => d is tz.TZDateTime), isTrue);
    });
  });
}

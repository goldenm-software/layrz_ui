import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('orderedWeekdays', () {
    test('defaults the canonical Monday-first list when firstDayOfWeek is Monday', () {
      expect(orderedWeekdays(DateTime.monday), [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ]);
    });

    test('rotates to Sunday-first when firstDayOfWeek is Sunday', () {
      expect(orderedWeekdays(DateTime.sunday), [
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      ]);
    });

    test('rotates to Saturday-first when firstDayOfWeek is Saturday', () {
      expect(orderedWeekdays(DateTime.saturday), [
        DateTime.saturday,
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ]);
    });

    test('every one of the seven DateTime weekday constants produces a valid full-week rotation', () {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        final result = orderedWeekdays(day);
        expect(result.length, 7);
        expect(result.toSet(), {1, 2, 3, 4, 5, 6, 7});
        expect(result.first, day);
      }
    });

    test('asserts firstDayOfWeek is within 1-7', () {
      expect(() => orderedWeekdays(0), throwsA(isA<AssertionError>()));
      expect(() => orderedWeekdays(8), throwsA(isA<AssertionError>()));
    });
  });

  group('orderedWeekdayLabels', () {
    const l10n = LayrzUiL10nDefault();

    test('returns labels in Sunday-first order for the default first day', () {
      expect(orderedWeekdayLabels(l10n, DateTime.sunday), [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ]);
    });

    test('returns labels in Monday-first order', () {
      expect(orderedWeekdayLabels(l10n, DateTime.monday), [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ]);
    });

    test('label order always matches orderedWeekdays -- one shared source, never two', () {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        final weekdayInts = orderedWeekdays(day);
        final labels = orderedWeekdayLabels(l10n, day);
        const byWeekday = {
          DateTime.monday: 'Monday',
          DateTime.tuesday: 'Tuesday',
          DateTime.wednesday: 'Wednesday',
          DateTime.thursday: 'Thursday',
          DateTime.friday: 'Friday',
          DateTime.saturday: 'Saturday',
          DateTime.sunday: 'Sunday',
        };
        expect(labels, [for (final w in weekdayInts) byWeekday[w]]);
      }
    });
  });
}

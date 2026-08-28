import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzCalendarEntry', () {
    test('isMultiDay is false for an entry within a single calendar date', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 23, 59),
      );

      expect(entry.isMultiDay, isFalse);
    });

    test('isMultiDay is true when end falls on a later calendar date than start', () {
      final entry = LayrzCalendarEntry(
        title: 'Overnight shift',
        start: DateTime(2026, 8, 28, 23),
        end: DateTime(2026, 8, 29, 1),
      );

      expect(entry.isMultiDay, isTrue);
    });

    test('isMultiDay is true for an entry spanning several days', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.isMultiDay, isTrue);
    });

    test('occupies is true for every date in an inclusive multi-day range', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.occupies(DateTime(2026, 8, 28)), isTrue);
      expect(entry.occupies(DateTime(2026, 8, 29)), isTrue);
      expect(entry.occupies(DateTime(2026, 8, 30)), isTrue);
    });

    test('occupies is false for a date outside the range', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.occupies(DateTime(2026, 8, 27)), isFalse);
      expect(entry.occupies(DateTime(2026, 8, 31)), isFalse);
    });

    test('occupies ignores the time-of-day component of the queried date', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      expect(entry.occupies(DateTime(2026, 8, 28, 23, 59)), isTrue);
    });

    test('copyWith replaces only the given fields', () {
      const color = Color(0xFF00FF00);
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      final copy = entry.copyWith(title: 'Renamed', color: color);

      expect(copy.title, 'Renamed');
      expect(copy.color, color);
      expect(copy.start, entry.start);
      expect(copy.end, entry.end);
    });

    test('copyWith with no arguments returns an equal entry', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      expect(entry.copyWith(), entry);
    });

    test('equality and hashCode are value-based', () {
      final a = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final b = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final c = a.copyWith(title: 'Different');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('color defaults to null', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 28),
      );

      expect(entry.color, isNull);
    });
  });
}

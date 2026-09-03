import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  group('LayrzDateRange', () {
    test('fromUnordered normalizes a reversed pair', () {
      final a = DateTime(2026, 9, 20);
      final b = DateTime(2026, 9, 10);
      final range = LayrzDateRange.fromUnordered(a, b);
      expect(range.start, b);
      expect(range.end, a);
    });

    test('fromUnordered keeps an already-ordered pair unchanged', () {
      final a = DateTime(2026, 9, 10);
      final b = DateTime(2026, 9, 20);
      final range = LayrzDateRange.fromUnordered(a, b);
      expect(range.start, a);
      expect(range.end, b);
    });

    test('lengthInDays is inclusive of both endpoints', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      expect(range.lengthInDays, 5);
    });

    test('lengthInDays is 1 for a single-day range', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 10));
      expect(range.lengthInDays, 1);
    });

    test('contains is true for dates within the inclusive bounds', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      expect(range.contains(DateTime(2026, 9, 10)), isTrue);
      expect(range.contains(DateTime(2026, 9, 12)), isTrue);
      expect(range.contains(DateTime(2026, 9, 14)), isTrue);
    });

    test('contains is false for dates outside the bounds', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      expect(range.contains(DateTime(2026, 9, 9)), isFalse);
      expect(range.contains(DateTime(2026, 9, 15)), isFalse);
    });

    test('contains ignores time-of-day', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      expect(range.contains(DateTime(2026, 9, 10, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 9, 14, 0, 1)), isTrue);
    });

    test('copyWith replaces only given fields', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      final copy = range.copyWith(end: DateTime(2026, 9, 20));
      expect(copy.start, DateTime(2026, 9, 10));
      expect(copy.end, DateTime(2026, 9, 20));
    });

    test('equality and hashCode are value-based', () {
      final a = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      final b = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      final c = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 15));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes start and end', () {
      final range = LayrzDateRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 14));
      expect(range.toString(), contains('2026-09-10'));
      expect(range.toString(), contains('2026-09-14'));
    });

    test('leap-year span computes the correct length', () {
      // 2028 is a leap year -- Feb has 29 days.
      final range = LayrzDateRange(start: DateTime(2028, 2, 1), end: DateTime(2028, 2, 29));
      expect(range.lengthInDays, 29);
    });

    test('month-boundary span computes the correct length', () {
      final range = LayrzDateRange(start: DateTime(2026, 1, 30), end: DateTime(2026, 2, 2));
      expect(range.lengthInDays, 4);
    });

    test('preserves TZDateTime endpoints', () {
      tz_data.initializeTimeZones();
      final location = tz.getLocation('America/New_York');
      final start = tz.TZDateTime(location, 2026, 9, 10);
      final end = tz.TZDateTime(location, 2026, 9, 14);
      final range = LayrzDateRange(start: start, end: end);
      expect(range.start, isA<tz.TZDateTime>());
      expect((range.start as tz.TZDateTime).location, location);
    });
  });
}

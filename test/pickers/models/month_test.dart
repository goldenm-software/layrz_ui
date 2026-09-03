import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzMonth', () {
    test('fromDateTime discards day/time/timezone', () {
      final month = LayrzMonth.fromDateTime(DateTime(2026, 9, 14, 13, 30));
      expect(month.year, 2026);
      expect(month.month, 9);
    });

    test('toDateTime returns the first day of the month at midnight', () {
      const month = LayrzMonth(year: 2026, month: 9);
      final dt = month.toDateTime();
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 1);
      expect(dt.hour, 0);
    });

    test('copyWith replaces only given fields', () {
      const month = LayrzMonth(year: 2026, month: 9);
      final copy = month.copyWith(month: 3);
      expect(copy.year, 2026);
      expect(copy.month, 3);
    });

    test('next rolls over December to January of the next year', () {
      const december = LayrzMonth(year: 2026, month: 12);
      expect(december.next, const LayrzMonth(year: 2027, month: 1));
    });

    test('next steps forward within the same year', () {
      const month = LayrzMonth(year: 2026, month: 5);
      expect(month.next, const LayrzMonth(year: 2026, month: 6));
    });

    test('previous rolls back January to December of the prior year', () {
      const january = LayrzMonth(year: 2026, month: 1);
      expect(january.previous, const LayrzMonth(year: 2025, month: 12));
    });

    test('previous steps back within the same year', () {
      const month = LayrzMonth(year: 2026, month: 5);
      expect(month.previous, const LayrzMonth(year: 2026, month: 4));
    });

    test('compareTo orders by year first, then month', () {
      const earlier = LayrzMonth(year: 2025, month: 12);
      const later = LayrzMonth(year: 2026, month: 1);
      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
      expect(earlier.compareTo(earlier), 0);
    });

    test('comparison operators are consistent with compareTo', () {
      const a = LayrzMonth(year: 2026, month: 1);
      const b = LayrzMonth(year: 2026, month: 2);
      expect(a < b, isTrue);
      expect(a <= b, isTrue);
      expect(a <= a, isTrue);
      expect(b > a, isTrue);
      expect(b >= a, isTrue);
      expect(a >= a, isTrue);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzMonth(year: 2026, month: 9);
      const b = LayrzMonth(year: 2026, month: 9);
      const c = LayrzMonth(year: 2026, month: 10);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('month bounds are asserted', () {
      expect(() => LayrzMonth(year: 2026, month: 0), throwsA(isA<AssertionError>()));
      expect(() => LayrzMonth(year: 2026, month: 13), throwsA(isA<AssertionError>()));
    });

    test('toString includes year and month', () {
      const month = LayrzMonth(year: 2026, month: 9);
      expect(month.toString(), contains('2026'));
      expect(month.toString(), contains('9'));
    });

    test('sorting a list of LayrzMonth orders chronologically', () {
      final months = [
        const LayrzMonth(year: 2026, month: 3),
        const LayrzMonth(year: 2025, month: 12),
        const LayrzMonth(year: 2026, month: 1),
      ]..sort();
      expect(months, [
        const LayrzMonth(year: 2025, month: 12),
        const LayrzMonth(year: 2026, month: 1),
        const LayrzMonth(year: 2026, month: 3),
      ]);
    });
  });
}

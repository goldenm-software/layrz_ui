import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzMonthRange', () {
    test('fromUnordered normalizes a reversed pair', () {
      const a = LayrzMonth(year: 2026, month: 9);
      const b = LayrzMonth(year: 2026, month: 3);
      final range = LayrzMonthRange.fromUnordered(a, b);
      expect(range.start, b);
      expect(range.end, a);
    });

    test('fromUnordered keeps an already-ordered pair unchanged', () {
      const a = LayrzMonth(year: 2026, month: 3);
      const b = LayrzMonth(year: 2026, month: 9);
      final range = LayrzMonthRange.fromUnordered(a, b);
      expect(range.start, a);
      expect(range.end, b);
    });

    test('lengthInMonths is inclusive of both endpoints', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      expect(range.lengthInMonths, 4);
    });

    test('lengthInMonths is 1 for a single-month range', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 3));
      expect(range.lengthInMonths, 1);
    });

    test('lengthInMonths spans a year boundary correctly', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2025, month: 11), end: LayrzMonth(year: 2026, month: 2));
      expect(range.lengthInMonths, 4);
    });

    test('contains is true for months within the inclusive bounds', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      expect(range.contains(const LayrzMonth(year: 2026, month: 3)), isTrue);
      expect(range.contains(const LayrzMonth(year: 2026, month: 4)), isTrue);
      expect(range.contains(const LayrzMonth(year: 2026, month: 6)), isTrue);
    });

    test('contains is false for months outside the bounds', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      expect(range.contains(const LayrzMonth(year: 2026, month: 2)), isFalse);
      expect(range.contains(const LayrzMonth(year: 2026, month: 7)), isFalse);
    });

    test('toList returns every month in the range, in order', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 11), end: LayrzMonth(year: 2027, month: 2));
      expect(range.toList(), [
        const LayrzMonth(year: 2026, month: 11),
        const LayrzMonth(year: 2026, month: 12),
        const LayrzMonth(year: 2027, month: 1),
        const LayrzMonth(year: 2027, month: 2),
      ]);
    });

    test('toList for a single-month range returns exactly one entry', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 6), end: LayrzMonth(year: 2026, month: 6));
      expect(range.toList(), [const LayrzMonth(year: 2026, month: 6)]);
    });

    test('copyWith replaces only given fields', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      final copy = range.copyWith(end: const LayrzMonth(year: 2026, month: 9));
      expect(copy.start, const LayrzMonth(year: 2026, month: 3));
      expect(copy.end, const LayrzMonth(year: 2026, month: 9));
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      const b = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      const c = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 7));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString includes start and end', () {
      const range = LayrzMonthRange(start: LayrzMonth(year: 2026, month: 3), end: LayrzMonth(year: 2026, month: 6));
      expect(range.toString(), contains('LayrzMonth(year: 2026, month: 3)'));
      expect(range.toString(), contains('LayrzMonth(year: 2026, month: 6)'));
    });
  });
}

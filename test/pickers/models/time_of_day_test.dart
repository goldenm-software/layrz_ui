import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTimeOfDay', () {
    test('fromDateTime discards date and timezone', () {
      final time = LayrzTimeOfDay.fromDateTime(DateTime(2026, 9, 14, 13, 30, 45));
      expect(time.hour, 13);
      expect(time.minute, 30);
      expect(time.second, 45);
    });

    test('second defaults to zero', () {
      const time = LayrzTimeOfDay(hour: 9, minute: 30);
      expect(time.second, 0);
    });

    test('hour12 maps midnight and noon to 12', () {
      expect(const LayrzTimeOfDay(hour: 0, minute: 0).hour12, 12);
      expect(const LayrzTimeOfDay(hour: 12, minute: 0).hour12, 12);
    });

    test('hour12 maps other hours correctly', () {
      expect(const LayrzTimeOfDay(hour: 1, minute: 0).hour12, 1);
      expect(const LayrzTimeOfDay(hour: 13, minute: 0).hour12, 1);
      expect(const LayrzTimeOfDay(hour: 23, minute: 0).hour12, 11);
    });

    test('isPm is true for hour >= 12', () {
      expect(const LayrzTimeOfDay(hour: 11, minute: 59).isPm, isFalse);
      expect(const LayrzTimeOfDay(hour: 12, minute: 0).isPm, isTrue);
      expect(const LayrzTimeOfDay(hour: 23, minute: 59).isPm, isTrue);
    });

    test('copyWith replaces only given fields', () {
      const time = LayrzTimeOfDay(hour: 9, minute: 30, second: 15);
      final copy = time.copyWith(minute: 45);
      expect(copy.hour, 9);
      expect(copy.minute, 45);
      expect(copy.second, 15);
    });

    test('compareTo orders by hour, then minute, then second', () {
      const earlier = LayrzTimeOfDay(hour: 9, minute: 0, second: 0);
      const later = LayrzTimeOfDay(hour: 9, minute: 0, second: 1);
      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
      expect(earlier.compareTo(earlier), 0);
    });

    test('comparison operators are consistent with compareTo', () {
      const a = LayrzTimeOfDay(hour: 9, minute: 0);
      const b = LayrzTimeOfDay(hour: 17, minute: 0);
      expect(a < b, isTrue);
      expect(a <= b, isTrue);
      expect(b > a, isTrue);
      expect(b >= a, isTrue);
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzTimeOfDay(hour: 9, minute: 30, second: 15);
      const b = LayrzTimeOfDay(hour: 9, minute: 30, second: 15);
      const c = LayrzTimeOfDay(hour: 9, minute: 30, second: 16);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('no interval snapping — any minute/second value is representable', () {
      const time = LayrzTimeOfDay(hour: 9, minute: 37, second: 53);
      expect(time.minute, 37);
      expect(time.second, 53);
    });

    test('bounds are asserted', () {
      expect(() => LayrzTimeOfDay(hour: -1, minute: 0), throwsA(isA<AssertionError>()));
      expect(() => LayrzTimeOfDay(hour: 24, minute: 0), throwsA(isA<AssertionError>()));
      expect(() => LayrzTimeOfDay(hour: 0, minute: -1), throwsA(isA<AssertionError>()));
      expect(() => LayrzTimeOfDay(hour: 0, minute: 60), throwsA(isA<AssertionError>()));
      expect(() => LayrzTimeOfDay(hour: 0, minute: 0, second: -1), throwsA(isA<AssertionError>()));
      expect(() => LayrzTimeOfDay(hour: 0, minute: 0, second: 60), throwsA(isA<AssertionError>()));
    });

    test('toString includes hour, minute, and second', () {
      const time = LayrzTimeOfDay(hour: 9, minute: 30, second: 15);
      expect(time.toString(), contains('9'));
      expect(time.toString(), contains('30'));
      expect(time.toString(), contains('15'));
    });
  });
}

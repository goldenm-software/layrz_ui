import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzConnectionTimes.defaults', () {
    test('matches the documented 15-minute online / 60-minute idle thresholds', () {
      const times = LayrzConnectionTimes.defaults();
      expect(times.online, const Duration(minutes: 15));
      expect(times.idle, const Duration(minutes: 60));
    });
  });

  group('LayrzConnectionTimes.copyWith', () {
    test('replaces only the given fields', () {
      const original = LayrzConnectionTimes.defaults();
      final copy = original.copyWith(online: const Duration(minutes: 5));

      expect(copy.online, const Duration(minutes: 5));
      expect(copy.idle, original.idle);
    });

    test('with no arguments returns an equal value', () {
      const original = LayrzConnectionTimes.defaults();
      expect(original.copyWith(), original);
    });
  });

  group('LayrzConnectionTimes equality', () {
    test('two instances with the same fields are equal and share a hashCode', () {
      const a = LayrzConnectionTimes(online: Duration(minutes: 5), idle: Duration(minutes: 20));
      const b = LayrzConnectionTimes(online: Duration(minutes: 5), idle: Duration(minutes: 20));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('instances with different fields are not equal', () {
      const a = LayrzConnectionTimes(online: Duration(minutes: 5), idle: Duration(minutes: 20));
      const b = LayrzConnectionTimes(online: Duration(minutes: 6), idle: Duration(minutes: 20));

      expect(a == b, isFalse);
    });
  });

  test('toString reports both thresholds', () {
    const times = LayrzConnectionTimes(online: Duration(minutes: 5), idle: Duration(minutes: 20));
    expect(times.toString(), contains('5:00'));
    expect(times.toString(), contains('20:00'));
  });
}

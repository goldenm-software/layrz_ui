import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzConnectionTimes.defaults', () {
    test('matches the documented 15-minute online / 60-minute idle / 30-day offline thresholds', () {
      const times = LayrzConnectionTimes.defaults();
      expect(times.online, const Duration(minutes: 15));
      expect(times.idle, const Duration(minutes: 60));
      expect(times.offline, const Duration(days: 30));
    });
  });

  group('LayrzConnectionTimes.copyWith', () {
    test('replaces only the given fields', () {
      const original = LayrzConnectionTimes.defaults();
      final copy = original.copyWith(online: const Duration(minutes: 5));

      expect(copy.online, const Duration(minutes: 5));
      expect(copy.idle, original.idle);
      expect(copy.offline, original.offline);
    });

    test('replaces the offline field independently of online/idle', () {
      const original = LayrzConnectionTimes.defaults();
      final copy = original.copyWith(offline: const Duration(days: 2));

      expect(copy.offline, const Duration(days: 2));
      expect(copy.online, original.online);
      expect(copy.idle, original.idle);
    });

    test('with no arguments returns an equal value', () {
      const original = LayrzConnectionTimes.defaults();
      expect(original.copyWith(), original);
    });
  });

  group('LayrzConnectionTimes equality', () {
    test('two instances with the same fields are equal and share a hashCode', () {
      const a = LayrzConnectionTimes(
        online: Duration(minutes: 5),
        idle: Duration(minutes: 20),
        offline: Duration(days: 30),
      );
      const b = LayrzConnectionTimes(
        online: Duration(minutes: 5),
        idle: Duration(minutes: 20),
        offline: Duration(days: 30),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('instances with different online/idle fields are not equal', () {
      const a = LayrzConnectionTimes(
        online: Duration(minutes: 5),
        idle: Duration(minutes: 20),
        offline: Duration(days: 30),
      );
      const b = LayrzConnectionTimes(
        online: Duration(minutes: 6),
        idle: Duration(minutes: 20),
        offline: Duration(days: 30),
      );

      expect(a == b, isFalse);
    });

    test('instances differing only in offline are not equal', () {
      const a = LayrzConnectionTimes(
        online: Duration(minutes: 5),
        idle: Duration(minutes: 20),
        offline: Duration(days: 30),
      );
      const b = LayrzConnectionTimes(
        online: Duration(minutes: 5),
        idle: Duration(minutes: 20),
        offline: Duration(days: 2),
      );

      expect(a == b, isFalse);
    });
  });

  test('toString reports all three thresholds', () {
    const offline = Duration(days: 30);
    const times = LayrzConnectionTimes(
      online: Duration(minutes: 5),
      idle: Duration(minutes: 20),
      offline: offline,
    );
    expect(times.toString(), contains('5:00'));
    expect(times.toString(), contains('20:00'));
    // Duration.toString() reports days as total hours (30 days == 720
    // hours), not a literal "30" -- assert against the real formatting
    // rather than a substring that happens not to appear in it.
    expect(times.toString(), contains(offline.toString()));
  });
}

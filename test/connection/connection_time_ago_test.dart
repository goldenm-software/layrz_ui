import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  const l10n = LayrzUiL10nDefault();

  group('humanizeLayrzConnectionTimeAgo', () {
    test('under a minute renders "just now"', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(seconds: 30), l10n), 'just now');
    });

    test('a singular minute uses the singular unit', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(minutes: 1), l10n), '1 minute ago');
    });

    test('plural minutes use the plural unit', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(minutes: 5), l10n), '5 minutes ago');
    });

    test('at least an hour reports hours, not minutes', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(hours: 2), l10n), '2 hours ago');
    });

    test('a singular hour uses the singular unit', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(hours: 1), l10n), '1 hour ago');
    });

    test('at least a day reports days, not hours', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(days: 3), l10n), '3 days ago');
    });

    test('a singular day uses the singular unit', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(days: 1), l10n), '1 day ago');
    });

    test('a negative (future) duration is treated as its absolute value', () {
      expect(humanizeLayrzConnectionTimeAgo(const Duration(minutes: -5), l10n), '5 minutes ago');
    });
  });
}

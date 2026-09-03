import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// A minimal, distinctly-worded [LayrzUiL10n] subclass used to prove that
/// name-producing directives (`%B`/`%b`/`%A`/`%a`/`%p`) read through l10n
/// rather than a hardcoded English string.
class _TestL10n extends LayrzUiL10n {
  const _TestL10n();

  @override
  String get monthSeptember => 'TEST_SEPTEMBER';

  @override
  String get monthAbbreviatedSeptember => 'TEST_SEP';

  @override
  String get dateWednesday => 'TEST_WEDNESDAY';

  @override
  String get weekdayAbbreviatedWednesday => 'TEST_WED';

  @override
  String get timeMeridiemAm => 'TEST_AM';

  @override
  String get timeMeridiemPm => 'TEST_PM';
}

void main() {
  const l10n = LayrzUiL10nDefault();
  // 2026-09-16 is a Wednesday, day-of-year 259.
  final reference = DateTime(2026, 9, 16, 14, 5, 9);

  group('formatStrftime — every supported directive', () {
    test('%Y renders the 4-digit year', () {
      expect(formatStrftime(reference, '%Y', l10n), '2026');
    });

    test('%y renders the zero-padded 2-digit year', () {
      expect(formatStrftime(DateTime(2005, 1, 1), '%y', l10n), '05');
    });

    test('%m renders the zero-padded month', () {
      expect(formatStrftime(reference, '%m', l10n), '09');
    });

    test('%d renders the zero-padded day', () {
      expect(formatStrftime(DateTime(2026, 9, 5), '%d', l10n), '05');
    });

    test('%H renders the zero-padded 24-hour hour', () {
      expect(formatStrftime(reference, '%H', l10n), '14');
      expect(formatStrftime(DateTime(2026, 1, 1, 0), '%H', l10n), '00');
    });

    test('%I renders the zero-padded 12-hour hour', () {
      expect(formatStrftime(reference, '%I', l10n), '02');
      expect(formatStrftime(DateTime(2026, 1, 1, 0), '%I', l10n), '12');
      expect(formatStrftime(DateTime(2026, 1, 1, 12), '%I', l10n), '12');
    });

    test('%M renders the zero-padded minute', () {
      expect(formatStrftime(reference, '%M', l10n), '05');
    });

    test('%S renders the zero-padded second', () {
      expect(formatStrftime(reference, '%S', l10n), '09');
    });

    test('%B renders the full month name', () {
      expect(formatStrftime(reference, '%B', l10n), 'September');
    });

    test('%b renders the abbreviated month name', () {
      expect(formatStrftime(reference, '%b', l10n), 'Sep');
    });

    test('%A renders the full weekday name', () {
      expect(formatStrftime(reference, '%A', l10n), 'Wednesday');
    });

    test('%a renders the abbreviated weekday name', () {
      expect(formatStrftime(reference, '%a', l10n), 'Wed');
    });

    test('%p renders the meridiem marker', () {
      expect(formatStrftime(DateTime(2026, 1, 1, 9), '%p', l10n), 'AM');
      expect(formatStrftime(DateTime(2026, 1, 1, 21), '%p', l10n), 'PM');
    });

    test('%j renders the zero-padded day of year', () {
      expect(formatStrftime(reference, '%j', l10n), '259');
      expect(formatStrftime(DateTime(2026, 1, 1), '%j', l10n), '001');
    });

    test('%% renders a literal percent', () {
      expect(formatStrftime(reference, '%%', l10n), '%');
    });
  });

  group('formatStrftime — composition', () {
    test('a full old-layrz_theme-style pattern renders correctly', () {
      expect(formatStrftime(reference, '%Y-%m-%d', l10n), '2026-09-16');
    });

    test('a pattern mixing literals and directives renders correctly', () {
      expect(formatStrftime(reference, '%A, %B %d %Y at %H:%M', l10n), 'Wednesday, September 16 2026 at 14:05');
    });

    test('a pattern with a literal percent followed by a directive renders both', () {
      expect(formatStrftime(reference, '100%% done on %Y', l10n), '100% done on 2026');
    });
  });

  group('formatStrftime — l10n sourcing', () {
    test('%B reads through LayrzUiL10n, not a hardcoded English string', () {
      expect(formatStrftime(reference, '%B', const _TestL10n()), 'TEST_SEPTEMBER');
    });

    test('%b reads through LayrzUiL10n', () {
      expect(formatStrftime(reference, '%b', const _TestL10n()), 'TEST_SEP');
    });

    test('%A reads through LayrzUiL10n', () {
      expect(formatStrftime(reference, '%A', const _TestL10n()), 'TEST_WEDNESDAY');
    });

    test('%a reads through LayrzUiL10n', () {
      expect(formatStrftime(reference, '%a', const _TestL10n()), 'TEST_WED');
    });

    test('%p reads through LayrzUiL10n', () {
      expect(formatStrftime(DateTime(2026, 1, 1, 9), '%p', const _TestL10n()), 'TEST_AM');
      expect(formatStrftime(DateTime(2026, 1, 1, 21), '%p', const _TestL10n()), 'TEST_PM');
    });
  });
}

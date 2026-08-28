import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzTimeFormat', () {
    test('has exactly two values in the specified order: amPm, h24', () {
      expect(LayrzTimeFormat.values, [LayrzTimeFormat.amPm, LayrzTimeFormat.h24]);
    });
  });

  group('formatHourLabel', () {
    const l10n = LayrzUiL10nDefault();

    test('h24 formats midnight as 00:00', () {
      expect(formatHourLabel(0, LayrzTimeFormat.h24, l10n), '00:00');
    });

    test('h24 formats noon as 12:00', () {
      expect(formatHourLabel(12, LayrzTimeFormat.h24, l10n), '12:00');
    });

    test('h24 formats an evening hour with zero-padding', () {
      expect(formatHourLabel(8, LayrzTimeFormat.h24, l10n), '08:00');
      expect(formatHourLabel(23, LayrzTimeFormat.h24, l10n), '23:00');
    });

    test('amPm formats midnight as 12 AM', () {
      expect(formatHourLabel(0, LayrzTimeFormat.amPm, l10n), '12 AM');
    });

    test('amPm formats noon as 12 PM', () {
      expect(formatHourLabel(12, LayrzTimeFormat.amPm, l10n), '12 PM');
    });

    test('amPm formats a morning hour', () {
      expect(formatHourLabel(8, LayrzTimeFormat.amPm, l10n), '8 AM');
    });

    test('amPm formats an afternoon hour', () {
      expect(formatHourLabel(14, LayrzTimeFormat.amPm, l10n), '2 PM');
    });

    test('amPm formats the last hour of the day', () {
      expect(formatHourLabel(23, LayrzTimeFormat.amPm, l10n), '11 PM');
    });

    test('amPm uses the localized meridiem markers, not string literals', () {
      // A stub l10n with translated markers proves the function reads
      // through the l10n object rather than a hardcoded 'AM'/'PM'.
      const stub = _StubL10n();
      expect(formatHourLabel(0, LayrzTimeFormat.amPm, stub), '12 MADRUGADA');
      expect(formatHourLabel(13, LayrzTimeFormat.amPm, stub), '1 TARDE');
    });

    test('asserts hour is within 0-23', () {
      expect(() => formatHourLabel(-1, LayrzTimeFormat.h24, l10n), throwsA(isA<AssertionError>()));
      expect(() => formatHourLabel(24, LayrzTimeFormat.h24, l10n), throwsA(isA<AssertionError>()));
    });
  });

  group('kLayrzCalendarWidestHourLabels', () {
    test('includes both the widest h24 and widest amPm labels', () {
      expect(kLayrzCalendarWidestHourLabels, contains('08:00'));
      expect(kLayrzCalendarWidestHourLabels, contains('12 AM'));
      expect(kLayrzCalendarWidestHourLabels, contains('12 PM'));
    });
  });
}

class _StubL10n extends LayrzUiL10nDefault {
  const _StubL10n();

  @override
  String get timeMeridiemAm => 'MADRUGADA';

  @override
  String get timeMeridiemPm => 'TARDE';
}

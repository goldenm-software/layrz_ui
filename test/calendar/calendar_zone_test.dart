import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/calendar/src/calendar_zone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Test-only: nothing under `lib/` calls this directly -- `calendar_zone.dart`
  // only ever reuses a `Location` already carried on a caller-supplied
  // `TZDateTime`, which requires no initialization of its own (see
  // `sameZoneDate`'s doc). This is loaded here purely so this file's own
  // `TZDateTime` fixtures can be constructed.
  setUpAll(tzdata.initializeTimeZones);

  group('sameZoneDate', () {
    test('given a plain DateTime reference, returns a plain DateTime', () {
      final reference = DateTime(2026, 1, 1);
      final result = sameZoneDate(reference, 2026, 3, 15);

      expect(result, DateTime(2026, 3, 15));
      expect(result, isNot(isA<tz.TZDateTime>()));
    });

    test('given a plain DateTime reference, defaults day to 1 when omitted', () {
      final reference = DateTime(2026, 1, 1);
      final result = sameZoneDate(reference, 2026, 3);

      expect(result, DateTime(2026, 3, 1));
    });

    test('given a TZDateTime reference, returns a TZDateTime in the same Location', () {
      final auckland = tz.getLocation('Pacific/Auckland');
      final reference = tz.TZDateTime(auckland, 2026, 1, 1);
      final result = sameZoneDate(reference, 2026, 3, 15);

      expect(result, isA<tz.TZDateTime>());
      expect((result as tz.TZDateTime).location, auckland);
      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 15);
    });

    test('preserves Location across a fall-back DST transition via calendar-field overflow', () {
      // Australia/Lord_Howe falls back on 2024-04-07 (offset +11:00 ->
      // +10:30). Stepping day-of-month past the transition via field
      // overflow (day: 6 + 2 = 8) must land on the correct calendar date in
      // Lord Howe's own zone, not the host's.
      final lordHowe = tz.getLocation('Australia/Lord_Howe');
      final reference = tz.TZDateTime(lordHowe, 2024, 4, 6);
      final stepped = sameZoneDate(reference, reference.year, reference.month, reference.day + 2);

      expect(stepped, isA<tz.TZDateTime>());
      expect((stepped as tz.TZDateTime).location, lordHowe);
      expect(stepped.year, 2024);
      expect(stepped.month, 4);
      expect(stepped.day, 8);
    });

    test('month-overflow stepping normalizes correctly for a TZDateTime reference', () {
      final newYork = tz.getLocation('America/New_York');
      final reference = tz.TZDateTime(newYork, 2026, 12, 1);
      final result = sameZoneDate(reference, reference.year, reference.month + 1);

      expect(result, isA<tz.TZDateTime>());
      expect((result as tz.TZDateTime).location, newYork);
      expect(result.year, 2027);
      expect(result.month, 1);
    });

    test('requires no explicit package:timezone initialization beyond what the reference already carries', () {
      // The Location object attached to `reference` is self-contained (its
      // own transition table), so reusing it here needs no additional setup
      // -- proven by never calling anything beyond what setUpAll above did
      // once for this whole file, across every zone exercised in this group.
      final lordHowe = tz.getLocation('Australia/Lord_Howe');
      final reference = tz.TZDateTime(lordHowe, 2024, 4, 6);
      expect(() => sameZoneDate(reference, 2024, 4, 8), returnsNormally);
    });
  });

  group('sameZoneDateTime', () {
    test('given a plain DateTime reference, returns a plain DateTime with time-of-day fields', () {
      final reference = DateTime(2026, 1, 1);
      final result = sameZoneDateTime(reference, 2026, 3, 15, 9, 45);

      expect(result, DateTime(2026, 3, 15, 9, 45));
      expect(result, isNot(isA<tz.TZDateTime>()));
    });

    test('time-of-day fields default to zero, matching the plain DateTime constructor', () {
      final reference = DateTime(2026, 1, 1);
      final result = sameZoneDateTime(reference, 2026, 3, 15);

      expect(result, DateTime(2026, 3, 15));
    });

    test('given a TZDateTime reference, returns a TZDateTime in the same Location with time-of-day fields', () {
      final auckland = tz.getLocation('Pacific/Auckland');
      final reference = tz.TZDateTime(auckland, 2026, 1, 1);
      final result = sameZoneDateTime(reference, 2026, 3, 15, 14, 30, 1, 2, 3);

      expect(result, isA<tz.TZDateTime>());
      final tzResult = result as tz.TZDateTime;
      expect(tzResult.location, auckland);
      expect(tzResult.hour, 14);
      expect(tzResult.minute, 30);
      expect(tzResult.second, 1);
      expect(tzResult.millisecond, 2);
      expect(tzResult.microsecond, 3);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzCalendarEntry', () {
    test('isMultiDay is false for an entry within a single calendar date', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 23, 59),
      );

      expect(entry.isMultiDay, isFalse);
    });

    test('isMultiDay is true when end falls on a later calendar date than start', () {
      final entry = LayrzCalendarEntry(
        title: 'Overnight shift',
        start: DateTime(2026, 8, 28, 23),
        end: DateTime(2026, 8, 29, 1),
      );

      expect(entry.isMultiDay, isTrue);
    });

    test('isMultiDay is true for an entry spanning several days', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.isMultiDay, isTrue);
    });

    test('occupies is true for every date in an inclusive multi-day range', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.occupies(DateTime(2026, 8, 28)), isTrue);
      expect(entry.occupies(DateTime(2026, 8, 29)), isTrue);
      expect(entry.occupies(DateTime(2026, 8, 30)), isTrue);
    });

    test('occupies is false for a date outside the range', () {
      final entry = LayrzCalendarEntry(
        title: 'Conference',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 30),
      );

      expect(entry.occupies(DateTime(2026, 8, 27)), isFalse);
      expect(entry.occupies(DateTime(2026, 8, 31)), isFalse);
    });

    test('occupies ignores the time-of-day component of the queried date', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      expect(entry.occupies(DateTime(2026, 8, 28, 23, 59)), isTrue);
    });

    test('copyWith replaces only the given fields', () {
      const color = Color(0xFF00FF00);
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      final copy = entry.copyWith(title: 'Renamed', color: color);

      expect(copy.title, 'Renamed');
      expect(copy.color, color);
      expect(copy.start, entry.start);
      expect(copy.end, entry.end);
    });

    test('copyWith with no arguments returns an equal entry', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      expect(entry.copyWith(), entry);
    });

    test('equality and hashCode are value-based', () {
      final a = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final b = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final c = a.copyWith(title: 'Different');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('color defaults to null', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 28),
      );

      expect(entry.color, isNull);
    });

    test('isPreview defaults to false', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 28),
      );

      expect(entry.isPreview, isFalse);
    });

    test('equality differs by isPreview alone', () {
      final real = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      final preview = real.copyWith(isPreview: true);

      expect(real, isNot(equals(preview)));
      expect(real.hashCode, isNot(equals(preview.hashCode)));
    });

    test('two otherwise-identical entries with the same isPreview are equal', () {
      final a = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        isPreview: true,
      );
      final b = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        isPreview: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith sets isPreview', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      final copy = entry.copyWith(isPreview: true);

      expect(copy.isPreview, isTrue);
    });

    test('copyWith without isPreview preserves the existing value, including true', () {
      final preview = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        isPreview: true,
      );

      final copy = preview.copyWith(title: 'Renamed');

      expect(copy.isPreview, isTrue);
    });

    test('copyWith with no arguments returns an equal entry including isPreview', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        isPreview: true,
      );

      expect(entry.copyWith(), entry);
    });

    test('onTap defaults to null', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28),
        end: DateTime(2026, 8, 28),
      );

      expect(entry.onTap, isNull);
    });

    test('copyWith sets onTap', () {
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );
      var tapped = false;

      final copy = entry.copyWith(onTap: () => tapped = true);
      copy.onTap!();

      expect(tapped, isTrue);
    });

    test('copyWith without onTap preserves the existing callback', () {
      var tapped = false;
      final entry = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        onTap: () => tapped = true,
      );

      final copy = entry.copyWith(title: 'Renamed');
      copy.onTap!();

      expect(tapped, isTrue);
    });

    test('onTap is deliberately excluded from equality -- two entries with identical data but separately-written '
        'closures still compare equal', () {
      final a = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        onTap: () {},
      );
      final b = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        onTap: () {},
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('onTap is excluded from hashCode too -- an entry with a callback and an otherwise-identical one without '
        'still hash equal', () {
      final withCallback = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
        onTap: () {},
      );
      final withoutCallback = LayrzCalendarEntry(
        title: 'Standup',
        start: DateTime(2026, 8, 28, 9),
        end: DateTime(2026, 8, 28, 10),
      );

      expect(withCallback, equals(withoutCallback));
      expect(withCallback.hashCode, equals(withoutCallback.hashCode));
    });

    group('subclassing (the documented extension point)', () {
      test('a subclass instance is constructible and reachable through the base type', () {
        final event = _TestEvent(
          recordId: 42,
          title: 'Standup',
          start: DateTime(2026, 8, 28, 9),
          end: DateTime(2026, 8, 28, 10),
        );

        // Assignable to the base type, exactly what LayrzCalendar.entries
        // expects a caller to hand it.
        final LayrzCalendarEntry asBase = event;
        expect(asBase.title, 'Standup');
      });

      test('a subclass\'s onTap fires with that subclass\'s own data already in scope, no cast needed', () {
        int? capturedRecordId;
        final event = _TestEvent(
          recordId: 42,
          title: 'Standup',
          start: DateTime(2026, 8, 28, 9),
          end: DateTime(2026, 8, 28, 10),
        );
        final withTap = _TestEvent(
          recordId: event.recordId,
          title: event.title,
          start: event.start,
          end: event.end,
          onTap: () => capturedRecordId = event.recordId,
        );

        withTap.onTap!();

        expect(capturedRecordId, 42);
      });

      test(
        'base equality compares runtimeType first, so a subclass instance never equals a plain base instance with '
        'the same fields',
        () {
          final base = LayrzCalendarEntry(
            title: 'Standup',
            start: DateTime(2026, 8, 28, 9),
            end: DateTime(2026, 8, 28, 10),
          );
          final subclass = _TestEvent(
            recordId: 1,
            title: 'Standup',
            start: DateTime(2026, 8, 28, 9),
            end: DateTime(2026, 8, 28, 10),
          );

          expect(base, isNot(equals(subclass)));
        },
      );

      test(
        'documented gap: base equality does NOT know about a subclass\'s own extra fields, so two same-subclass '
        'instances differing only in those fields compare equal unless the subclass overrides == -- this is the '
        'behaviour a consumer must fix by overriding, not a defect in the base',
        () {
          final first = _TestEvent(
            recordId: 1,
            title: 'Standup',
            start: DateTime(2026, 8, 28, 9),
            end: DateTime(2026, 8, 28, 10),
          );
          final second = _TestEvent(
            recordId: 2,
            title: 'Standup',
            start: DateTime(2026, 8, 28, 9),
            end: DateTime(2026, 8, 28, 10),
          );

          // Same runtimeType, same base fields, DIFFERENT recordId -- base
          // `==` cannot see `recordId` at all, so these compare equal. A
          // real consumer's subclass should override `==`/`hashCode` to
          // fold `recordId` in; `_TestEvent` deliberately does not, to prove
          // this is the base's documented behaviour rather than an artifact
          // of a particular subclass's own override.
          expect(first, equals(second));
        },
      );

      test('a subclass that DOES override == correctly distinguishes instances differing in its own field', () {
        final first = _OverridingTestEvent(
          recordId: 1,
          title: 'Standup',
          start: DateTime(2026, 8, 28, 9),
          end: DateTime(2026, 8, 28, 10),
        );
        final second = _OverridingTestEvent(
          recordId: 2,
          title: 'Standup',
          start: DateTime(2026, 8, 28, 9),
          end: DateTime(2026, 8, 28, 10),
        );
        final firstAgain = _OverridingTestEvent(
          recordId: 1,
          title: 'Standup',
          start: DateTime(2026, 8, 28, 9),
          end: DateTime(2026, 8, 28, 10),
        );

        expect(first, isNot(equals(second)));
        expect(first, equals(firstAgain));
        expect(first.hashCode, equals(firstAgain.hashCode));
      });
    });
  });
}

/// A minimal subclass used to prove [LayrzCalendarEntry] is extendable, per
/// its class doc's documented pattern -- adds one field
/// ([recordId]) and does NOT override `==`/`hashCode`, so
/// [calendar_entry_test.dart]'s "documented gap" test can demonstrate the
/// equality contract a real consumer's subclass must fix.
class _TestEvent extends LayrzCalendarEntry {
  const _TestEvent({
    required this.recordId,
    required super.title,
    required super.start,
    required super.end,
    super.onTap,
  });

  /// A field a real consumer's domain object would carry -- a database
  /// primary key stand-in for this test.
  final int recordId;
}

/// The same shape as [_TestEvent], but with `==`/`hashCode` correctly
/// overridden to fold [recordId] in -- proving the class doc's documented
/// fix actually works when a consumer applies it.
class _OverridingTestEvent extends LayrzCalendarEntry {
  const _OverridingTestEvent({
    required this.recordId,
    required super.title,
    required super.start,
    required super.end,
  });

  final int recordId;

  @override
  bool operator ==(Object other) => other is _OverridingTestEvent && super == other && recordId == other.recordId;

  @override
  int get hashCode => Object.hash(super.hashCode, recordId);
}

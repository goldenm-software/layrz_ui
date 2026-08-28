import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzCalendarDayCellStyleSpec', () {
    final tokens = LayrzTokens.light();

    test('resolve tints the background and border for today', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: true,
        isOutsideMonth: false,
        isDisabled: false,
      );

      expect(spec.borderColor, tokens.colors.primary.shade500);
      expect(spec.dateColor, tokens.colors.fg1);
    });

    test('resolve uses fg1 for an ordinary in-month day', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: false,
        isDisabled: false,
      );

      expect(spec.dateColor, tokens.colors.fg1);
      expect(spec.borderColor, tokens.colors.divider);
      expect(spec.backgroundColor, tokens.colors.sf1);
    });

    test('resolve dims the date color for a day outside the focused month', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: true,
        isDisabled: false,
      );

      expect(spec.dateColor, tokens.colors.fg3);
    });

    test('resolve mutes the date color for a disabled day, taking precedence over outside-month', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: true,
        isDisabled: true,
      );

      // isDisabled must win over isOutsideMonth -- the two are independent
      // inputs, and disabled has its own distinct color rather than falling
      // back to the outside-month treatment.
      expect(spec.dateColor, tokens.colors.fg4);
    });

    test('resolve always sets eventColor to the info swatch', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: false,
        isDisabled: false,
      );

      expect(spec.eventColor, tokens.colors.info.shade500);
    });

    test('copyWith replaces only the given fields', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: false,
        isDisabled: false,
      );

      const replacement = Color(0xFF123456);
      final copy = spec.copyWith(dateColor: replacement);

      expect(copy.dateColor, replacement);
      expect(copy.backgroundColor, spec.backgroundColor);
      expect(copy.borderColor, spec.borderColor);
      expect(copy.eventColor, spec.eventColor);
    });

    test('copyWith with no arguments returns an equal spec', () {
      final spec = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: false,
        isDisabled: false,
      );

      expect(spec.copyWith(), spec);
    });

    test('equality and hashCode are value-based', () {
      final a = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: true,
        isOutsideMonth: false,
        isDisabled: false,
      );
      final b = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: true,
        isOutsideMonth: false,
        isDisabled: false,
      );
      final c = LayrzCalendarDayCellStyleSpec.resolve(
        tokens: tokens,
        isToday: false,
        isOutsideMonth: false,
        isDisabled: false,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}

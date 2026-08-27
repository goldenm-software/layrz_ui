import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  final tokens = LayrzTokens.light();

  group('LayrzSliderColors', () {
    test('two instances with identical fields are equal and share a hashCode', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('instances differing only in trackColor are not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFFFFFFFF),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      expect(a == b, isFalse);
    });

    test('instances differing only in activeTrackColor are not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFFFFFFFF),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      expect(a == b, isFalse);
    });

    test('instances differing only in thumbColor are not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFFFFFFFF),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      expect(a == b, isFalse);
    });

    test('instances differing only in thumbBorderColor are not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFFFFFFFF),
        thumbElevation: 1,
      );
      expect(a == b, isFalse);
    });

    test('instances differing only in thumbElevation are not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      const b = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 2,
      );
      expect(a == b, isFalse);
    });

    test('identical() short-circuit returns true for the same instance', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      expect(a == a, isTrue);
    });

    test('comparing against a different runtime type is not equal', () {
      const a = LayrzSliderColors(
        trackColor: Color(0xFF000000),
        activeTrackColor: Color(0xFF111111),
        thumbColor: Color(0xFF222222),
        thumbBorderColor: Color(0xFF333333),
        thumbElevation: 1,
      );
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a LayrzSliderColors', isFalse);
    });
  });

  group('resolveLayrzSliderColors precedence', () {
    test('disabled takes precedence over every other state', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.hovered, WidgetState.pressed, WidgetState.focused},
        isDisabled: true,
        hasErrors: true,
        isDragging: true,
        isFocusVisible: true,
      );
      expect(colors.activeTrackColor, tokens.colors.fg4);
      expect(colors.thumbColor, tokens.colors.fg4);
    });

    test('a disabled thumb is flush with no elevation', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.hovered, WidgetState.pressed, WidgetState.focused},
        isDisabled: true,
        hasErrors: true,
        isDragging: true,
        isFocusVisible: true,
      );
      expect(colors.thumbElevation, 0);
    });

    test('error takes precedence over interaction states when not disabled', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.hovered, WidgetState.pressed, WidgetState.focused},
        isDisabled: false,
        hasErrors: true,
        isDragging: true,
        isFocusVisible: true,
      );
      expect(colors.activeTrackColor, tokens.colors.danger);
      expect(colors.thumbColor, tokens.colors.danger);
    });

    test('an error thumb rests at the base elevation, same as default', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: const {},
        isDisabled: false,
        hasErrors: true,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.thumbElevation, 1);
    });

    test('pressed state takes precedence over hover/focus when enabled and error-free', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.pressed, WidgetState.hovered, WidgetState.focused},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: true,
      );
      expect(colors.activeTrackColor, tokens.colors.primary.shade600);
      expect(colors.thumbColor, tokens.colors.primary.shade600);
    });

    test('a pressed thumb lifts to a higher elevation than resting', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.pressed},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.thumbElevation, 2);
    });

    test('an active drag is treated the same as pressed even without WidgetState.pressed', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: const {},
        isDisabled: false,
        hasErrors: false,
        isDragging: true,
        isFocusVisible: false,
      );
      expect(colors.activeTrackColor, tokens.colors.primary.shade600);
      expect(colors.thumbElevation, 2);
    });

    test('hover state colours the track/thumb primary with a neutral border', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.hovered},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.activeTrackColor, tokens.colors.primary);
      expect(colors.thumbBorderColor, tokens.colors.sf1);
    });

    test('a hovered thumb lifts to a higher elevation than resting', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: {WidgetState.hovered},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.thumbElevation, 2);
    });

    test('keyboard focus-visible shows a primary-shade700 border, distinct from hover', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: const {},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: true,
      );
      expect(colors.activeTrackColor, tokens.colors.primary);
      expect(colors.thumbBorderColor, tokens.colors.primary.shade700);
    });

    test('default (no state) resolves to the base primary palette', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: const {},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.trackColor, tokens.colors.sf3);
      expect(colors.activeTrackColor, tokens.colors.primary);
      expect(colors.thumbColor, tokens.colors.primary);
      expect(colors.thumbBorderColor, tokens.colors.sf1);
    });

    test('default (no state) rests at the base elevation', () {
      final colors = resolveLayrzSliderColors(
        tokens: tokens,
        states: const {},
        isDisabled: false,
        hasErrors: false,
        isDragging: false,
        isFocusVisible: false,
      );
      expect(colors.thumbElevation, 1);
    });
  });
}

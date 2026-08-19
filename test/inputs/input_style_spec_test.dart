import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/input_style_spec.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

void main() {
  group('LayrzInputStyleSpec', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    test('copyWith returns new instance with updated fields', () {
      final original = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );

      final updated = original.copyWith(
        backgroundColor: tokens.colors.surface,
        isDashed: true,
      );

      expect(updated.backgroundColor, tokens.colors.surface);
      expect(updated.isDashed, true);
      expect(updated.borderColor, original.borderColor);
      expect(updated.borderWidth, original.borderWidth);
      expect(updated.textColor, original.textColor);
    });

    test('equality works correctly', () {
      final spec1 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );

      final spec2 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );

      expect(spec1, spec2);
      expect(spec1.hashCode, spec2.hashCode);
    });

    test('inequality works correctly', () {
      final spec1 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );

      final spec2 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.surface,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
        isDashed: false,
      );

      expect(spec1, isNot(spec2));
    });

    test('resolve: default state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.surface2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.borderWidth, tokens.border.base);
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.isDashed, false);
    });

    test('resolve: hovered state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.hovered},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.surface3);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.isDashed, false);
    });

    test('resolve: focused state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.focused},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.surface2);
      expect(spec.borderColor, tokens.colors.primary);
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.isDashed, false);
    });

    test('resolve: pressed state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.pressed},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.surface3);
      expect(spec.isDashed, false);
    });

    test('resolve: error state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.backgroundColor, tokens.colors.danger.shade50);
      expect(spec.borderColor, tokens.colors.danger);
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.isDashed, false);
    });

    test('resolve: disabled state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.disabled},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.surface2);
      expect(spec.borderColor, tokens.colors.divider);
      expect(spec.textColor, tokens.colors.fg4);
      expect(spec.isDashed, true);
    });

    test('resolve: read-only state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: false,
        readOnly: true,
      );

      expect(spec.backgroundColor, tokens.colors.surface2);
      expect(spec.borderColor, tokens.colors.divider);
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.isDashed, false);
    });

    test('resolve: precedence - disabled > readOnly', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.disabled},
        tokens: tokens,
        hasErrors: false,
        readOnly: true,
      );

      expect(spec.isDashed, true);
      expect(spec.textColor, tokens.colors.fg4);
    });

    test('resolve: precedence - readOnly > error', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
        readOnly: true,
      );

      expect(spec.backgroundColor, tokens.colors.surface2);
      expect(spec.isDashed, false);
    });

    test('resolve: precedence - error > pressed', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.pressed},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.backgroundColor, tokens.colors.danger.shade50);
      expect(spec.borderColor, tokens.colors.danger);
    });

    test('resolve: border width is always the same', () {
      final states = [
        <WidgetState>{},
        {WidgetState.hovered},
        {WidgetState.focused},
        {WidgetState.pressed},
        {WidgetState.disabled},
      ];

      final specs = states
          .map(
            (s) => LayrzInputStyleSpec.resolve(
              states: s,
              tokens: tokens,
              hasErrors: false,
            ),
          )
          .toList();

      final firstWidth = specs.first.borderWidth;
      for (final spec in specs) {
        expect(spec.borderWidth, firstWidth);
      }
    });
  });
}

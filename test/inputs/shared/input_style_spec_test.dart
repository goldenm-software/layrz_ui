import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_style_spec.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

void main() {
  group('LayrzInputStyleSpec', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light();
    });

    test('copyWith returns new instance with updated fields', () {
      final original = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );

      final updated = original.copyWith(
        backgroundColor: tokens.colors.sf2,
      );

      expect(updated.backgroundColor, tokens.colors.sf2);
      expect(updated.borderColor, original.borderColor);
      expect(updated.borderWidth, original.borderWidth);
      expect(updated.textColor, original.textColor);
    });

    test('equality works correctly', () {
      final spec1 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );

      final spec2 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );

      expect(spec1, spec2);
      expect(spec1.hashCode, spec2.hashCode);
    });

    test('inequality works correctly', () {
      final spec1 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );

      final spec2 = LayrzInputStyleSpec(
        backgroundColor: tokens.colors.sf3,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.base,
        textColor: tokens.colors.fg1,
      );

      expect(spec1, isNot(spec2));
    });

    test('resolve: default state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.borderWidth, tokens.border.base);
      expect(spec.textColor, tokens.colors.fg1);
    });

    test('resolve: hovered state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.hovered},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.sf3);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg1);
    });

    test('resolve: focused state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.focused},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, tokens.colors.primary);
      expect(spec.textColor, tokens.colors.primary);
    });

    test('resolve: pressed state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.pressed},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.sf3);
    });

    test('resolve: error state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.backgroundColor, tokens.colors.danger.shade50);
      expect(spec.borderColor, tokens.colors.danger);
      // Text color must match the border's danger color (DESIGN-106 follow-up):
      // the error state previously left text at plain fg1, which read as a
      // regular field with only a colored border/background, and, since the
      // chrome derives affix icon color from the same textColor, also left
      // the suffix icons uncolored in the reported screenshot.
      expect(spec.textColor, tokens.colors.danger);
    });

    test('resolve: disabled state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.disabled},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg4);
    });

    test('resolve: read-only state', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: false,
        readOnly: true,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg1);
    });

    test('resolve: precedence - disabled > readOnly', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.disabled},
        tokens: tokens,
        hasErrors: false,
        readOnly: true,
      );

      expect(spec.textColor, tokens.colors.fg4);
    });

    test('resolve: precedence - disabled > error (disabled wins, stays fg4, not danger)', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.disabled},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg4);
      expect(spec.textColor, isNot(tokens.colors.danger));
    });

    test('resolve: precedence - readOnly > error', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
        readOnly: true,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
    });

    test('resolve: precedence - readOnly > error (readOnly wins, stays fg1, not danger)', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
        readOnly: true,
      );

      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.textColor, isNot(tokens.colors.danger));
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

    test('resolve: precedence - error > pressed (text also follows danger, not fg1)', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.pressed},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.textColor, tokens.colors.danger);
    });

    test('resolve: focused state - text and border both use primary', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {WidgetState.focused},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.borderColor, tokens.colors.primary);
      expect(spec.textColor, tokens.colors.primary);
      expect(spec.textColor, spec.borderColor);
    });

    test('resolve: error state - text and border both use danger', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: true,
      );

      expect(spec.borderColor, tokens.colors.danger);
      expect(spec.textColor, tokens.colors.danger);
      expect(spec.textColor, spec.borderColor);
    });

    test('resolve: default state - plain fg1, distinct from danger and primary', () {
      final spec = LayrzInputStyleSpec.resolve(
        states: {},
        tokens: tokens,
        hasErrors: false,
      );

      expect(spec.textColor, tokens.colors.fg1);
      expect(spec.textColor, isNot(tokens.colors.danger));
      expect(spec.textColor, isNot(tokens.colors.primary));
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

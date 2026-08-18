import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/menus/src/dropdown_entry_style_spec.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzDropdownEntryStyleSpec', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzThemeData.light(fontHandler: const FakeFontHandler()).tokens;
    });

    testWidgets('resolve returns correct colors for default state', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.backgroundColor, const Color(0x00000000));
      expect(spec.labelColor, tokens.colors.fg1);
      expect(spec.iconColor, tokens.colors.fg1);
    });

    testWidgets('resolve returns correct colors for hovered state', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.hovered},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.backgroundColor, isNotNull);
      expect(spec.labelColor, tokens.colors.fg1);
      expect(spec.iconColor, tokens.colors.fg1);
    });

    testWidgets('resolve returns correct colors for pressed state', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.pressed},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.backgroundColor, tokens.colors.primary.shade100);
      expect(spec.labelColor, tokens.colors.primary.shade700);
      expect(spec.iconColor, tokens.colors.primary.shade700);
    });

    testWidgets('resolve returns correct colors for disabled state', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: false,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.backgroundColor, const Color(0x00000000));
      expect(spec.labelColor, tokens.colors.fg3);
      expect(spec.iconColor, tokens.colors.fg3);
    });

    testWidgets('resolve respects disabled precedence over pressed', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: false,
        states: {WidgetState.pressed},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.labelColor, tokens.colors.fg3);
    });

    testWidgets('resolve respects pressed precedence over hovered', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.pressed, WidgetState.hovered},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec.labelColor, tokens.colors.primary.shade700);
    });

    testWidgets('copyWith creates a new instance with replaced fields', (tester) async {
      final original = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      const newColor = Color(0xFFFF0000);
      final copy = original.copyWith(
        backgroundColor: newColor,
      );

      expect(copy.backgroundColor, newColor);
      expect(copy.labelColor, original.labelColor);
      expect(copy.iconColor, original.iconColor);
    });

    testWidgets('equality works correctly', (tester) async {
      final spec1 = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      final spec2 = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec1, spec2);
    });

    testWidgets('hashCode is consistent with equality', (tester) async {
      final spec1 = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      final spec2 = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: const {},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(spec1.hashCode, spec2.hashCode);
    });

    testWidgets('uses custom color when provided', (tester) async {
      final spec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.pressed},
        tokens: tokens,
        accent: tokens.colors.danger,
      );

      expect(spec.backgroundColor, tokens.colors.danger.shade100);
      expect(spec.labelColor, tokens.colors.danger.shade700);
    });

    testWidgets('focused state is treated same as hovered', (tester) async {
      final hoveredSpec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.hovered},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      final focusedSpec = LayrzDropdownEntryStyleSpec.resolve(
        enabled: true,
        states: {WidgetState.focused},
        tokens: tokens,
        accent: tokens.colors.primary,
      );

      expect(hoveredSpec.backgroundColor, focusedSpec.backgroundColor);
      expect(hoveredSpec.labelColor, focusedSpec.labelColor);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzAccordionStyleSpec', () {
    final tokens = LayrzTokens.light();

    test('default state resolves to sf1 background and fg1 content', () {
      final spec = LayrzAccordionStyleSpec.resolve(states: const {}, tokens: tokens);

      expect(spec.headerBackgroundColor, equals(tokens.colors.sf1));
      expect(spec.headerContentColor, equals(tokens.colors.fg1));
      expect(spec.borderColor, equals(tokens.colors.divider));
      expect(spec.borderWidth, equals(tokens.border.base));
    });

    test('hovered state lifts background to sf2', () {
      final spec = LayrzAccordionStyleSpec.resolve(
        states: {WidgetState.hovered},
        tokens: tokens,
      );

      expect(spec.headerBackgroundColor, equals(tokens.colors.sf2));
      expect(spec.headerContentColor, equals(tokens.colors.fg1));
    });

    test('focused state resolves identically to hovered state', () {
      final hovered = LayrzAccordionStyleSpec.resolve(states: {WidgetState.hovered}, tokens: tokens);
      final focused = LayrzAccordionStyleSpec.resolve(states: {WidgetState.focused}, tokens: tokens);

      expect(focused, equals(hovered));
    });

    test('pressed state deepens background to sf3', () {
      final spec = LayrzAccordionStyleSpec.resolve(
        states: {WidgetState.pressed},
        tokens: tokens,
      );

      expect(spec.headerBackgroundColor, equals(tokens.colors.sf3));
    });

    test('pressed takes precedence over hovered', () {
      final spec = LayrzAccordionStyleSpec.resolve(
        states: {WidgetState.hovered, WidgetState.pressed},
        tokens: tokens,
      );

      expect(spec.headerBackgroundColor, equals(tokens.colors.sf3));
    });

    test('disabled state fades content and border to fg3, regardless of other states', () {
      final spec = LayrzAccordionStyleSpec.resolve(
        states: {WidgetState.disabled, WidgetState.hovered, WidgetState.pressed},
        tokens: tokens,
      );

      expect(spec.headerBackgroundColor, equals(tokens.colors.sf1));
      expect(spec.headerContentColor, equals(tokens.colors.fg3));
      expect(spec.borderColor, equals(tokens.colors.fg3));
    });

    test('disabled takes precedence over every other state', () {
      final disabledOnly = LayrzAccordionStyleSpec.resolve(states: {WidgetState.disabled}, tokens: tokens);
      final disabledWithOthers = LayrzAccordionStyleSpec.resolve(
        states: {WidgetState.disabled, WidgetState.focused, WidgetState.pressed},
        tokens: tokens,
      );

      expect(disabledWithOthers, equals(disabledOnly));
    });

    test('border width is identical across every state (D15: no geometry change)', () {
      final states = [
        const <WidgetState>{},
        {WidgetState.hovered},
        {WidgetState.focused},
        {WidgetState.pressed},
        {WidgetState.disabled},
      ];

      final widths = states.map((s) => LayrzAccordionStyleSpec.resolve(states: s, tokens: tokens).borderWidth);

      expect(widths.toSet(), hasLength(1));
    });

    test('copyWith replaces only the given fields', () {
      const spec = LayrzAccordionStyleSpec(
        headerBackgroundColor: Color(0xFF000000),
        headerContentColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderWidth: 1.0,
      );

      final copy = spec.copyWith(headerBackgroundColor: const Color(0xFFFFFFFF));

      expect(copy.headerBackgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(copy.headerContentColor, equals(spec.headerContentColor));
      expect(copy.borderColor, equals(spec.borderColor));
      expect(copy.borderWidth, equals(spec.borderWidth));
    });

    test('equality and hashCode are value-based', () {
      const a = LayrzAccordionStyleSpec(
        headerBackgroundColor: Color(0xFF000000),
        headerContentColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderWidth: 1.0,
      );
      const b = LayrzAccordionStyleSpec(
        headerBackgroundColor: Color(0xFF000000),
        headerContentColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderWidth: 1.0,
      );
      const c = LayrzAccordionStyleSpec(
        headerBackgroundColor: Color(0xFFFFFFFF),
        headerContentColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderWidth: 1.0,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}

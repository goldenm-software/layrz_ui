import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  final tokens = LayrzTokens.light();

  group('LayrzFileInputStyleSpec.resolve', () {
    test('disabled takes precedence over every other state', () {
      final spec = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.populated,
        tokens: tokens,
        hasErrors: true,
        disabled: true,
      );
      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, const Color(0x00000000));
      expect(spec.contentColor, tokens.colors.fg4);
    });

    test('error takes precedence over dragging/hover/populated', () {
      final spec = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.dragging,
        tokens: tokens,
        hasErrors: true,
      );
      expect(spec.backgroundColor, tokens.colors.danger.shade50);
      expect(spec.borderColor, tokens.colors.danger);
      expect(spec.contentColor, tokens.colors.danger);
    });

    test('dragging state uses primary color with a thicker border than other states', () {
      final dragging = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.dragging,
        tokens: tokens,
        hasErrors: false,
      );
      final hover = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.hover,
        tokens: tokens,
        hasErrors: false,
      );
      expect(dragging.borderColor, tokens.colors.primary);
      expect(dragging.contentColor, tokens.colors.primary);
      expect(dragging.borderWidth, greaterThan(hover.borderWidth));
    });

    test('hover state uses primary border with base border width', () {
      final spec = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.hover,
        tokens: tokens,
        hasErrors: false,
      );
      expect(spec.backgroundColor, tokens.colors.sf3);
      expect(spec.borderColor, tokens.colors.primary);
      expect(spec.borderWidth, tokens.border.stroke2);
    });

    test('populated state uses divider border and fg1 content', () {
      final spec = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.populated,
        tokens: tokens,
        hasErrors: false,
      );
      expect(spec.backgroundColor, tokens.colors.sf1);
      expect(spec.borderColor, tokens.colors.divider);
      expect(spec.contentColor, tokens.colors.fg1);
    });

    test('empty state uses divider border and fg3 content', () {
      final spec = LayrzFileInputStyleSpec.resolve(
        state: LayrzFileInputState.empty,
        tokens: tokens,
        hasErrors: false,
      );
      expect(spec.backgroundColor, tokens.colors.sf2);
      expect(spec.borderColor, tokens.colors.divider);
      expect(spec.contentColor, tokens.colors.fg3);
    });

    test('all four non-error, non-disabled states are visually distinct', () {
      final specs = {
        for (final state in LayrzFileInputState.values)
          state: LayrzFileInputStyleSpec.resolve(state: state, tokens: tokens, hasErrors: false),
      };

      final asSet = specs.values.toSet();
      expect(asSet.length, specs.length, reason: 'each of the four states must resolve to a distinct spec');
    });
  });

  group('LayrzFileInputStyleSpec value semantics', () {
    test('copyWith replaces only the given fields', () {
      const spec = LayrzFileInputStyleSpec(
        backgroundColor: Color(0xFF000000),
        borderColor: Color(0xFF111111),
        borderWidth: 1.0,
        contentColor: Color(0xFF222222),
      );
      final copy = spec.copyWith(borderWidth: 2.0);
      expect(copy.backgroundColor, spec.backgroundColor);
      expect(copy.borderColor, spec.borderColor);
      expect(copy.borderWidth, 2.0);
      expect(copy.contentColor, spec.contentColor);
    });

    test('equal specs with identical fields compare equal and share hashCode', () {
      const a = LayrzFileInputStyleSpec(
        backgroundColor: Color(0xFF000000),
        borderColor: Color(0xFF111111),
        borderWidth: 1.0,
        contentColor: Color(0xFF222222),
      );
      const b = LayrzFileInputStyleSpec(
        backgroundColor: Color(0xFF000000),
        borderColor: Color(0xFF111111),
        borderWidth: 1.0,
        contentColor: Color(0xFF222222),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}

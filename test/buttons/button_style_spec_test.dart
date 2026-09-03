import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzButtonStyleSpec', () {
    late LayrzTokens tokens;
    late Color primaryColor;

    setUp(() {
      tokens = LayrzTokens.light();
      primaryColor = tokens.colors.primary;
    });

    group('resolve() - Base state (default, no interactions)', () {
      test('filled: solid background, contrastColor content, no border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(primaryColor));
        expect(spec.contentColor, equals(primaryColor.contrastColor));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.shadows, isEmpty);
      });

      test('outlined: transparent background, accent content, accent border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.contentColor, equals(primaryColor));
        expect(spec.borderColor, equals(primaryColor));
        expect(spec.shadows, isEmpty);
      });

      test('text: transparent background, accent content, no border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.contentColor, equals(primaryColor));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.shadows, isEmpty);
      });
    });

    group('resolve() - Fab variants match non-Fab base specs', () {
      test('filledFab matches filled in default state', () {
        final filledSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final filledFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(filledFabSpec.backgroundColor, equals(filledSpec.backgroundColor));
        expect(filledFabSpec.contentColor, equals(filledSpec.contentColor));
        expect(filledFabSpec.borderColor, equals(filledSpec.borderColor));
        expect(filledFabSpec.shadows, equals(filledSpec.shadows));
      });

      test('outlinedFab matches outlined in default state', () {
        final outlinedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final outlinedFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(outlinedFabSpec.backgroundColor, equals(outlinedSpec.backgroundColor));
        expect(outlinedFabSpec.contentColor, equals(outlinedSpec.contentColor));
        expect(outlinedFabSpec.borderColor, equals(outlinedSpec.borderColor));
        expect(outlinedFabSpec.shadows, equals(outlinedSpec.shadows));
      });

      test('textFab matches text in default state', () {
        final textSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final textFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(textFabSpec.backgroundColor, equals(textSpec.backgroundColor));
        expect(textFabSpec.contentColor, equals(textSpec.contentColor));
        expect(textFabSpec.borderColor, equals(textSpec.borderColor));
        expect(textFabSpec.shadows, equals(textSpec.shadows));
      });
    });

    group('resolve() - Disabled state', () {
      test('disabled state content color is fg3', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.contentColor, equals(tokens.colors.fg3));
      });

      test('disabled state border color is fg3', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.borderColor, equals(tokens.colors.fg3));
      });

      test('disabled state removes shadows', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.shadows, isEmpty);
      });

      test('disabled state beats pressed state', () {
        final disabledSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.disabled, WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(disabledSpec.contentColor, equals(tokens.colors.fg3));
        expect(pressedSpec.contentColor, isNot(equals(tokens.colors.fg3)));
      });

      test('disabled state beats hovered state', () {
        final disabledSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.disabled, WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(disabledSpec.contentColor, equals(tokens.colors.fg3));
        expect(hoveredSpec.contentColor, isNot(equals(tokens.colors.fg3)));
      });

      test('text disabled state has fully transparent background (base was already transparent)', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.borderColor, equals(const Color(0x00000000)));
      });
    });

    group('resolve() - Pressed state', () {
      test('filled has no shadow, default or pressed', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(baseSpec.shadows, isEmpty);
        expect(pressedSpec.shadows, isEmpty);
      });

      test('pressed state changes background color', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(pressedSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('outlined is not inert on press: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(pressedSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('outlinedFab is not inert on press: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(pressedSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('text is not inert on press: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(pressedSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });
    });

    group('resolve() - Hovered state', () {
      test('hovered state changes background color', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(hoveredSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('hovered state has no shadow on filled', () {
        final filledSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(filledSpec.shadows, isEmpty);
      });

      test('outlined is not inert on hover: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(hoveredSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('outlinedFab is not inert on hover: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(hoveredSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });

      test('text is not inert on hover: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(hoveredSpec.backgroundColor, isNot(equals(baseSpec.backgroundColor)));
      });
    });

    group('D15 Regression: geometry stability across states', () {
      test('borderWidth is identical across all states for all styles', () {
        for (final style in LayrzButtonStyle.values) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          final disabledSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.disabled},
            tokens: tokens,
            accent: primaryColor,
          );

          expect(
            hoveredSpec.borderWidth,
            equals(defaultSpec.borderWidth),
            reason: '$style borderWidth should not change on hover',
          );
          expect(
            pressedSpec.borderWidth,
            equals(defaultSpec.borderWidth),
            reason: '$style borderWidth should not change on press',
          );
          expect(
            disabledSpec.borderWidth,
            equals(defaultSpec.borderWidth),
            reason: '$style borderWidth should not change when disabled',
          );
        }
      });
    });

    group('copyWith()', () {
      test('returns a new instance with replaced fields', () {
        final original = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        final updated = original.copyWith(
          backgroundColor: const Color(0xFF222222),
        );

        expect(updated.backgroundColor, equals(const Color(0xFF222222)));
        expect(updated.borderColor, equals(original.borderColor));
        expect(updated.borderWidth, equals(original.borderWidth));
        expect(updated.contentColor, equals(original.contentColor));
        expect(updated.shadows, equals(original.shadows));
      });

      test('all fields can be updated independently', () {
        final original = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        final updated = original.copyWith(
          backgroundColor: const Color(0xFF333333),
          borderColor: const Color(0xFF444444),
          borderWidth: 3.0,
          contentColor: const Color(0xFF555555),
          shadows: [
            const BoxShadow(
              color: Color(0xFF666666),
              blurRadius: 4.0,
            ),
          ],
        );

        expect(updated.backgroundColor, equals(const Color(0xFF333333)));
        expect(updated.borderColor, equals(const Color(0xFF444444)));
        expect(updated.borderWidth, equals(3.0));
        expect(updated.contentColor, equals(const Color(0xFF555555)));
        expect(updated.shadows, isNotEmpty);
      });
    });

    group('equality (== and hashCode)', () {
      test('two specs with identical fields are equal', () {
        final spec1 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        final spec2 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        expect(spec1, equals(spec2));
      });

      test('specs with different backgroundColor are not equal', () {
        final spec1 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        final spec2 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF222222),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        expect(spec1, isNot(equals(spec2)));
      });

      test('equal specs have equal hashCodes', () {
        final spec1 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        final spec2 = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        expect(spec1.hashCode, equals(spec2.hashCode));
      });

      test('identical instances are equal', () {
        final spec = LayrzButtonStyleSpec(
          backgroundColor: const Color(0xFF000000),
          borderColor: const Color(0xFF111111),
          borderWidth: 2.0,
          contentColor: const Color(0xFFFFFFFF),
          shadows: const [],
        );

        expect(spec, equals(spec));
      });
    });

    group('resolve() - Custom accent color', () {
      test('uses provided accent color instead of primary', () {
        const customAccent = Color(0xFFABCDEF);

        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: customAccent,
        );

        expect(spec.backgroundColor, equals(customAccent));
      });

      test('custom accent color applies to all styles', () {
        const customAccent = Color(0xFFABCDEF);

        for (final style in LayrzButtonStyle.values) {
          final spec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: customAccent,
          );

          // For filled, background should be the accent.
          // For text, content should be the accent (background stays transparent).
          // For outlined, border should be accent.
          if (style == LayrzButtonStyle.filled || style == LayrzButtonStyle.filledFab) {
            expect(spec.backgroundColor, equals(customAccent));
          } else if (style == LayrzButtonStyle.text || style == LayrzButtonStyle.textFab) {
            expect(spec.contentColor, equals(customAccent));
            expect(spec.backgroundColor, equals(const Color(0x00000000)));
          } else if (style == LayrzButtonStyle.outlined || style == LayrzButtonStyle.outlinedFab) {
            expect(spec.borderColor, equals(customAccent));
          }
        }
      });
    });

    group('Four-state interaction model', () {
      test('focus state resolves to same spec as hovered state for all styles', () {
        for (final style in LayrzButtonStyle.values) {
          final focusedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.focused},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          expect(
            focusedSpec.backgroundColor,
            equals(hoveredSpec.backgroundColor),
            reason: '$style focused should match hovered background',
          );
          expect(
            focusedSpec.borderColor,
            equals(hoveredSpec.borderColor),
            reason: '$style focused should match hovered border',
          );
          expect(
            focusedSpec.contentColor,
            equals(hoveredSpec.contentColor),
            reason: '$style focused should match hovered content',
          );
          expect(
            focusedSpec.shadows,
            equals(hoveredSpec.shadows),
            reason: '$style focused should match hovered shadows',
          );
        }
      });

      test('all 6 styles respond to hover state', () {
        for (final style in LayrzButtonStyle.values) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          // Hovered should differ from default for all styles.
          // Either background, content, or shadow must change.
          final backgroundColorChanged = hoveredSpec.backgroundColor != defaultSpec.backgroundColor;
          final borderColorChanged = hoveredSpec.borderColor != defaultSpec.borderColor;
          final contentColorChanged = hoveredSpec.contentColor != defaultSpec.contentColor;
          final shadowsChanged = hoveredSpec.shadows != defaultSpec.shadows;

          expect(
            backgroundColorChanged || borderColorChanged || contentColorChanged || shadowsChanged,
            isTrue,
            reason: '$style must not be inert on hover',
          );
        }
      });

      test('all 6 styles respond to pressed state', () {
        for (final style in LayrzButtonStyle.values) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: primaryColor,
          );

          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          // Pressed should differ from default for all styles.
          final backgroundColorChanged = pressedSpec.backgroundColor != defaultSpec.backgroundColor;
          final borderColorChanged = pressedSpec.borderColor != defaultSpec.borderColor;
          final contentColorChanged = pressedSpec.contentColor != defaultSpec.contentColor;
          final shadowsChanged = pressedSpec.shadows != defaultSpec.shadows;

          expect(
            backgroundColorChanged || borderColorChanged || contentColorChanged || shadowsChanged,
            isTrue,
            reason: '$style must not be inert on press',
          );
        }
      });

      test('pressed state differs from hovered state for all styles', () {
        for (final style in LayrzButtonStyle.values) {
          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          // Pressed and hovered should be visually distinct.
          final backgroundColorChanged = pressedSpec.backgroundColor != hoveredSpec.backgroundColor;
          final borderColorChanged = pressedSpec.borderColor != hoveredSpec.borderColor;
          final contentColorChanged = pressedSpec.contentColor != hoveredSpec.contentColor;
          final shadowsChanged = pressedSpec.shadows != hoveredSpec.shadows;

          expect(
            backgroundColorChanged || borderColorChanged || contentColorChanged || shadowsChanged,
            isTrue,
            reason: '$style pressed must differ visually from hovered',
          );
        }
      });

      test('state precedence: disabled beats pressed', () {
        for (final style in LayrzButtonStyle.values) {
          final disabledPressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.disabled, WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          final disabledSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.disabled},
            tokens: tokens,
            accent: primaryColor,
          );

          expect(
            disabledPressedSpec.contentColor,
            equals(disabledSpec.contentColor),
            reason: '$style disabled + pressed should render as disabled',
          );
        }
      });

      test('state precedence: disabled beats hovered', () {
        for (final style in LayrzButtonStyle.values) {
          final disabledHoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.disabled, WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          final disabledSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.disabled},
            tokens: tokens,
            accent: primaryColor,
          );

          expect(
            disabledHoveredSpec.contentColor,
            equals(disabledSpec.contentColor),
            reason: '$style disabled + hovered should render as disabled',
          );
        }
      });

      test('state precedence: pressed beats hovered', () {
        for (final style in LayrzButtonStyle.values) {
          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          // Pressed should not equal hovered (covered by earlier test,
          // but included here for clarity of precedence intent).
          expect(
            pressedSpec.backgroundColor != hoveredSpec.backgroundColor ||
                pressedSpec.borderColor != hoveredSpec.borderColor ||
                pressedSpec.contentColor != hoveredSpec.contentColor ||
                pressedSpec.shadows != hoveredSpec.shadows,
            isTrue,
            reason: '$style pressed should have higher visual weight than hovered',
          );
        }
      });
    });

    group('Outlined pair border invariant', () {
      test('outlined: border color identical across default/hover/pressed', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.borderColor, equals(hoveredSpec.borderColor));
        expect(defaultSpec.borderColor, equals(pressedSpec.borderColor));
        expect(defaultSpec.borderColor.a, greaterThan(0.0)); // Border must be visible
      });

      test('outlinedFab: border color identical across default/hover/pressed', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.borderColor, equals(hoveredSpec.borderColor));
        expect(defaultSpec.borderColor, equals(pressedSpec.borderColor));
        expect(defaultSpec.borderColor.a, greaterThan(0.0)); // Border must be visible
      });
    });

    group('Text style borderless invariant', () {
      test('text: border color stays fully transparent across default/hover/pressed', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.borderColor, equals(const Color(0x00000000)));
        expect(hoveredSpec.borderColor, equals(const Color(0x00000000)));
        expect(pressedSpec.borderColor, equals(const Color(0x00000000)));
      });

      test('textFab: border color stays fully transparent across default/hover/pressed', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.borderColor, equals(const Color(0x00000000)));
        expect(hoveredSpec.borderColor, equals(const Color(0x00000000)));
        expect(pressedSpec.borderColor, equals(const Color(0x00000000)));
      });
    });

    group('Filled shadow behavior', () {
      test('filled: no shadow by default, hovered, or pressed — hover/press distinction is colour-only', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.shadows, isEmpty, reason: 'filled default should have no shadow');
        expect(hoveredSpec.shadows, isEmpty, reason: 'filled hovered should have no shadow');
        expect(pressedSpec.shadows, isEmpty, reason: 'filled pressed should have no shadow');

        // Filled has no shadow to distinguish states, so the background colour
        // itself must carry the hover/pressed distinction (per D15: colour may
        // vary even though geometry and shadow do not).
        expect(
          hoveredSpec.backgroundColor,
          isNot(equals(defaultSpec.backgroundColor)),
          reason: 'filled hovered background must differ from default without a shadow to rely on',
        );
        expect(
          pressedSpec.backgroundColor,
          isNot(equals(hoveredSpec.backgroundColor)),
          reason: 'filled pressed background must differ from hovered without a shadow to rely on',
        );
      });

      test('filledFab: no shadow by default, hovered, or pressed', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(defaultSpec.shadows, isEmpty, reason: 'filledFab default should have no shadow');
        expect(hoveredSpec.shadows, isEmpty, reason: 'filledFab hovered should have no shadow');
        expect(pressedSpec.shadows, isEmpty, reason: 'filledFab pressed should have no shadow');
      });
    });

    group('Shadowless invariant (no style paints a shadow, in any state)', () {
      test('outlined, outlinedFab have no shadow in any state', () {
        final borderlessStyles = [
          LayrzButtonStyle.outlined,
          LayrzButtonStyle.outlinedFab,
        ];

        for (final style in borderlessStyles) {
          for (final state in {
            const <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.focused},
            {WidgetState.pressed},
          }) {
            final spec = LayrzButtonStyleSpec.resolve(
              style: style,
              states: state,
              tokens: tokens,
              accent: primaryColor,
            );

            expect(spec.shadows, isEmpty, reason: '$style should have no shadow in state $state');
          }
        }
      });

      test('text, textFab have no shadow in any state', () {
        final shadowlessStyles = [
          LayrzButtonStyle.text,
          LayrzButtonStyle.textFab,
        ];

        for (final style in shadowlessStyles) {
          for (final state in {
            const <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.focused},
            {WidgetState.pressed},
          }) {
            final spec = LayrzButtonStyleSpec.resolve(
              style: style,
              states: state,
              tokens: tokens,
              accent: primaryColor,
            );

            expect(spec.shadows, isEmpty, reason: '$style should have no shadow in state $state');
          }
        }
      });

      test('filled, filledFab have no shadow in any state (regression guard: elevation must not return)', () {
        final flatStyles = [
          LayrzButtonStyle.filled,
          LayrzButtonStyle.filledFab,
        ];

        for (final style in flatStyles) {
          for (final state in {
            const <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.focused},
            {WidgetState.pressed},
            {WidgetState.disabled},
          }) {
            final spec = LayrzButtonStyleSpec.resolve(
              style: style,
              states: state,
              tokens: tokens,
              accent: primaryColor,
            );

            expect(spec.shadows, isEmpty, reason: '$style should have no shadow in state $state');
          }
        }
      });
    });

    group('Fill ladder rung verification', () {
      test('outlined/outlinedFab hovered reaches opacity 0.20', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor.a, closeTo(0.20, 0.001));
      });

      test('outlinedFab hovered reaches opacity 0.20', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor.a, closeTo(0.20, 0.001));
      });

      test('outlined pressed reaches solid (α = 1.0)', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor.a, equals(1.0));
      });

      test('outlined pressed content color switches to contrast', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlined,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.contentColor, equals(primaryColor.contrastColor));
      });

      test('text hovered reaches opacity 0.20 (kLayrzButtonTextHoveredOpacity)', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor.a, closeTo(kLayrzButtonTextHoveredOpacity, 0.001));
      });

      test('text pressed reaches opacity 0.35 (kLayrzButtonTextPressedOpacity), never solid', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor.a, closeTo(kLayrzButtonTextPressedOpacity, 0.001));
        expect(spec.backgroundColor.a, lessThan(1.0));
      });

      test('text pressed content color stays accent (never switches to contrast)', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.contentColor, equals(primaryColor));
      });

      test('textFab hovered/pressed match text opacities', () {
        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );
        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.textFab,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(hoveredSpec.backgroundColor.a, closeTo(kLayrzButtonTextHoveredOpacity, 0.001));
        expect(pressedSpec.backgroundColor.a, closeTo(kLayrzButtonTextPressedOpacity, 0.001));
      });

      test('filled hovered uses lerp factor 0.18', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        final expectedColor = Color.lerp(defaultSpec.backgroundColor, defaultSpec.contentColor, 0.18)!;
        expect(hoveredSpec.backgroundColor.toARGB32(), equals(expectedColor.toARGB32()));
      });

      test('filled pressed uses lerp factor 0.34', () {
        final defaultSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filled,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        final expectedColor = Color.lerp(defaultSpec.backgroundColor, defaultSpec.contentColor, 0.34)!;
        expect(pressedSpec.backgroundColor.toARGB32(), equals(expectedColor.toARGB32()));
      });

      test('hovered background opacity is always significantly different from default for outlined styles', () {
        for (final style in [LayrzButtonStyle.outlined, LayrzButtonStyle.outlinedFab]) {
          final defaultSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {},
            tokens: tokens,
            accent: primaryColor,
          );

          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          // These go from 0 to 0.20
          expect(
            hoveredSpec.backgroundColor.a - defaultSpec.backgroundColor.a,
            greaterThanOrEqualTo(0.15),
            reason: '$style hovered opacity should be significantly greater than default',
          );
        }
      });

      test('pressed background opacity is always strictly greater than hovered for outlined/text styles', () {
        for (final style in [
          LayrzButtonStyle.outlined,
          LayrzButtonStyle.outlinedFab,
          LayrzButtonStyle.text,
          LayrzButtonStyle.textFab,
        ]) {
          final hoveredSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.hovered},
            tokens: tokens,
            accent: primaryColor,
          );

          final pressedSpec = LayrzButtonStyleSpec.resolve(
            style: style,
            states: {WidgetState.pressed},
            tokens: tokens,
            accent: primaryColor,
          );

          expect(
            pressedSpec.backgroundColor.a,
            greaterThan(hoveredSpec.backgroundColor.a),
            reason: '$style pressed opacity should exceed hovered',
          );
        }
      });
    });

    group('Bordered styles have accent borders in all states', () {
      test('outlined, outlinedFab have accent border in all states', () {
        for (final style in [LayrzButtonStyle.outlined, LayrzButtonStyle.outlinedFab]) {
          for (final state in {
            const <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.focused},
            {WidgetState.pressed},
          }) {
            final spec = LayrzButtonStyleSpec.resolve(
              style: style,
              states: state,
              tokens: tokens,
              accent: primaryColor,
            );

            expect(spec.borderColor.a, greaterThan(0.0), reason: '$style should have accent border in state $state');
          }
        }
      });
    });

    group('Text style has no border in any state', () {
      test('text, textFab have fully transparent border in all states', () {
        for (final style in [LayrzButtonStyle.text, LayrzButtonStyle.textFab]) {
          for (final state in {
            const <WidgetState>{},
            {WidgetState.hovered},
            {WidgetState.focused},
            {WidgetState.pressed},
          }) {
            final spec = LayrzButtonStyleSpec.resolve(
              style: style,
              states: state,
              tokens: tokens,
              accent: primaryColor,
            );

            expect(spec.borderColor.a, equals(0.0), reason: '$style should have no border in state $state');
          }
        }
      });
    });
  });
}

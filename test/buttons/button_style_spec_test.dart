import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/buttons/buttons.dart';
import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/extensions/extensions.dart';
import 'package:layrz_ui/tokens/tokens.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzButtonStyleSpec', () {
    late LayrzTokens tokens;
    late Color primaryColor;

    setUp(() {
      tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
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

      test('elevated: solid background, contrastColor content, no border, has shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevated,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(primaryColor));
        expect(spec.contentColor, equals(primaryColor.contrastColor));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.shadows, isNotEmpty);
        expect(spec.shadows.length, greaterThan(0));
      });

      test('filledTonal: tonal background, accent content, no border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledTonal,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(primaryColor.withOpacityValue(tokens.colors.tonalOpacity)));
        expect(spec.contentColor, equals(primaryColor));
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

      test('outlinedTonal: subtle tonal background, accent content, accent border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedTonal,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.backgroundColor, equals(primaryColor.withOpacityValue(kLayrzButtonOutlinedTonalOpacity)));
        expect(spec.contentColor, equals(primaryColor));
        expect(spec.borderColor, equals(primaryColor));
        expect(spec.shadows, isEmpty);
      });

      test('text: transparent background, accent content, transparent border, no shadow', () {
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

      test('fab: transparent background, accent content, transparent border, no shadow', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
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

      test('elevatedFab matches elevated in default state', () {
        final elevatedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevated,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final elevatedFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevatedFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(elevatedFabSpec.backgroundColor, equals(elevatedSpec.backgroundColor));
        expect(elevatedFabSpec.contentColor, equals(elevatedSpec.contentColor));
        expect(elevatedFabSpec.borderColor, equals(elevatedSpec.borderColor));
        expect(elevatedFabSpec.shadows, equals(elevatedSpec.shadows));
      });

      test('filledTonalFab matches filledTonal in default state', () {
        final filledTonalSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledTonal,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final filledTonalFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.filledTonalFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(filledTonalFabSpec.backgroundColor, equals(filledTonalSpec.backgroundColor));
        expect(filledTonalFabSpec.contentColor, equals(filledTonalSpec.contentColor));
        expect(filledTonalFabSpec.borderColor, equals(filledTonalSpec.borderColor));
        expect(filledTonalFabSpec.shadows, equals(filledTonalSpec.shadows));
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

      test('outlinedTonalFab matches outlinedTonal in default state', () {
        final outlinedTonalSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedTonal,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final outlinedTonalFabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.outlinedTonalFab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(outlinedTonalFabSpec.backgroundColor, equals(outlinedTonalSpec.backgroundColor));
        expect(outlinedTonalFabSpec.contentColor, equals(outlinedTonalSpec.contentColor));
        expect(outlinedTonalFabSpec.borderColor, equals(outlinedTonalSpec.borderColor));
        expect(outlinedTonalFabSpec.shadows, equals(outlinedTonalSpec.shadows));
      });

      test('fab matches text in default state', () {
        final textSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final fabSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(fabSpec.backgroundColor, equals(textSpec.backgroundColor));
        expect(fabSpec.contentColor, equals(textSpec.contentColor));
        expect(fabSpec.borderColor, equals(textSpec.borderColor));
        expect(fabSpec.shadows, equals(textSpec.shadows));
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
          style: LayrzButtonStyle.elevated,
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

      test('disabled text: transparent border, fg3 content', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.text,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.borderColor.a, equals(0.0));
        expect(spec.contentColor, equals(tokens.colors.fg3));
      });

      test('disabled fab: transparent border, fg3 content', () {
        final spec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
          states: {WidgetState.disabled},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(spec.borderColor.a, equals(0.0));
        expect(spec.contentColor, equals(tokens.colors.fg3));
      });
    });

    group('resolve() - Pressed state', () {
      test('elevated loses shadow when pressed', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevated,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevated,
          states: {WidgetState.pressed},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(baseSpec.shadows, isNotEmpty);
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

      test('fab is not inert on press: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final pressedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
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

      test('hovered state preserves shadows on elevated', () {
        final elevatedSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.elevated,
          states: {WidgetState.hovered},
          tokens: tokens,
          accent: primaryColor,
        );

        expect(elevatedSpec.shadows, isNotEmpty);
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

      test('fab is not inert on hover: background changes', () {
        final baseSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
          states: {},
          tokens: tokens,
          accent: primaryColor,
        );

        final hoveredSpec = LayrzButtonStyleSpec.resolve(
          style: LayrzButtonStyle.fab,
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

          // For filled/elevated, background should be the accent.
          // For tonal variants, background should be tonal version of accent.
          // For outlined, border should be accent.
          if (style == LayrzButtonStyle.filled || style == LayrzButtonStyle.filledFab) {
            expect(spec.backgroundColor, equals(customAccent));
          } else if (style == LayrzButtonStyle.elevated || style == LayrzButtonStyle.elevatedFab) {
            expect(spec.backgroundColor, equals(customAccent));
          } else if (style == LayrzButtonStyle.filledTonal || style == LayrzButtonStyle.filledTonalFab) {
            expect(
              spec.backgroundColor,
              equals(customAccent.withOpacityValue(tokens.colors.tonalOpacity)),
            );
          } else if (style == LayrzButtonStyle.outlined || style == LayrzButtonStyle.outlinedFab) {
            expect(spec.borderColor, equals(customAccent));
          } else if (style == LayrzButtonStyle.outlinedTonal || style == LayrzButtonStyle.outlinedTonalFab) {
            expect(spec.borderColor, equals(customAccent));
          }
        }
      });
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/alerts.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';

import '../helpers/fake_font_handler.dart';

void main() {
  group('LayrzAlertStyleSpec', () {
    late LayrzTokens tokens;

    setUp(() {
      tokens = LayrzTokens.light(fontHandler: const FakeFontHandler());
    });

    group('resolve() - layrz style', () {
      test('layrz inert: surface background, solid accent border, tonal left panel, accent icon', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);
        expect(spec.backgroundColor, equals(tokens.colors.surface));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.leftPanelColor, equals(tonal));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(tokens.colors.fg1));
        expect(spec.bodyColor, equals(tokens.colors.fg2));
      });

      test('layrz interactive: background is opaque', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        expect(spec.backgroundColor.isOpaque, isTrue);
      });

      test('layrz interactive: left panel is opaque flattened tonal (shadow prevention)', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);
        final expectedFlattenedPanel = tonal.flattenOn(tokens.colors.surface);
        expect(spec.leftPanelColor, equals(expectedFlattenedPanel));
        expect(spec.leftPanelColor.isOpaque, isTrue);
      });

      test('layrz inert: left panel is translucent tonal (unchanged)', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);
        expect(spec.leftPanelColor, equals(tonal));
        expect(spec.leftPanelColor.isOpaque, isFalse);
      });

      test('layrz: tonal left panel, accent border across severities', () {
        final severities = [
          (name: 'info', color: tokens.colors.info.shade500),
          (name: 'success', color: tokens.colors.success.shade500),
          (name: 'warning', color: tokens.colors.warning.shade500),
          (name: 'danger', color: tokens.colors.danger.shade500),
          (name: 'contextual', color: tokens.colors.contextual.shade500),
        ];

        for (final severity in severities) {
          final spec = LayrzAlertStyleSpec.resolve(
            style: LayrzAlertStyle.layrz,
            accent: severity.color,
            tokens: tokens,
            isInteractive: false,
          );

          final expectedTonal = severity.color.withOpacityValue(tokens.colors.tonalOpacity);
          expect(
            spec.leftPanelColor,
            equals(expectedTonal),
            reason: 'layrz ${severity.name} should have tonal left panel',
          );
          expect(
            spec.borderColor,
            equals(severity.color),
            reason: 'layrz ${severity.name} should have solid accent border',
          );
          expect(
            spec.iconColor,
            equals(severity.color),
            reason: 'layrz ${severity.name} should have accent icon',
          );
        }
      });
    });

    group('resolve() - filledTonal style', () {
      test('filledTonal inert: tonal background, transparent border, transparent icon chip, accent text', () {
        final accent = tokens.colors.success.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledTonal,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.backgroundColor, equals(accent.withOpacityValue(tokens.colors.tonalOpacity)));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.borderWidth, equals(0.0));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.leftPanelColor, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(accent));
        expect(spec.bodyColor, equals(accent));
      });

      test('filledTonal interactive: background is opaque composite of tonal on surface', () {
        final accent = tokens.colors.success.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledTonal,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);
        final expectedColor = Color.alphaBlend(tonal, tokens.colors.surface);
        expect(spec.backgroundColor, equals(expectedColor));
        expect(spec.backgroundColor.isOpaque, isTrue);
      });
    });

    group('resolve() - filled style', () {
      test('filled inert: accent background, accent border, transparent icon chip, contrast text', () {
        final accent = tokens.colors.danger.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.backgroundColor, equals(accent));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.leftPanelColor, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent.contrastColor));
        expect(spec.titleColor, equals(accent.contrastColor));
        expect(spec.bodyColor, equals(accent.contrastColor));
      });

      test('filled interactive: background is opaque', () {
        final accent = tokens.colors.danger.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        expect(spec.backgroundColor.isOpaque, isTrue);
      });
    });

    group('resolve() - outlined style', () {
      test('outlined inert: transparent background, accent border, transparent icon chip, accent text', () {
        final accent = tokens.colors.warning.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.leftPanelColor, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(accent));
        expect(spec.bodyColor, equals(accent));
      });

      test('outlined interactive: background equals surface token', () {
        final accent = tokens.colors.warning.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        expect(spec.backgroundColor, equals(tokens.colors.surface));
        expect(spec.backgroundColor.isOpaque, isTrue);
      });
    });

    group('resolve() - filledIcon style', () {
      test('filledIcon inert: surface background, accent border, solid accent left panel, contrast icon', () {
        final accent = tokens.colors.contextual.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledIcon,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.backgroundColor, equals(tokens.colors.surface));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.leftPanelColor, equals(accent));
        expect(spec.iconColor, equals(accent.contrastColor));
        expect(spec.titleColor, equals(tokens.colors.fg1));
        expect(spec.bodyColor, equals(tokens.colors.fg2));
      });

      test('filledIcon interactive: border is accent with base width', () {
        final accent = tokens.colors.contextual.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledIcon,
          accent: accent,
          tokens: tokens,
          isInteractive: true,
        );

        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.backgroundColor.isOpaque, isTrue);
      });

      test('filledIcon border and left panel track accent colour across severity types', () {
        final severities = [
          (name: 'info', color: tokens.colors.info.shade500),
          (name: 'success', color: tokens.colors.success.shade500),
          (name: 'warning', color: tokens.colors.warning.shade500),
          (name: 'danger', color: tokens.colors.danger.shade500),
          (name: 'contextual', color: tokens.colors.contextual.shade500),
        ];

        for (final severity in severities) {
          final spec = LayrzAlertStyleSpec.resolve(
            style: LayrzAlertStyle.filledIcon,
            accent: severity.color,
            tokens: tokens,
            isInteractive: false,
          );

          expect(
            spec.borderColor,
            equals(severity.color),
            reason: 'filledIcon ${severity.name} should have accent border',
          );
          expect(
            spec.leftPanelColor,
            equals(severity.color),
            reason: 'filledIcon ${severity.name} should have solid accent left panel',
          );
          expect(
            spec.iconColor,
            equals(severity.color.contrastColor),
            reason: 'filledIcon ${severity.name} should have contrast icon',
          );
        }
      });
    });

    group('copyWith', () {
      test('copyWith replaces only specified fields', () {
        final original = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
        );

        final newBgColor = const Color(0xFFFF0000);
        final modified = original.copyWith(backgroundColor: newBgColor);

        expect(modified.backgroundColor, equals(newBgColor));
        expect(modified.borderColor, equals(original.borderColor));
        expect(modified.titleColor, equals(original.titleColor));
      });
    });

    group('equality', () {
      test('two specs with identical fields are equal', () {
        final spec1 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec1, equals(spec2));
      });

      test('two specs with different fields are not equal', () {
        final spec1 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec1, isNot(equals(spec2)));
      });
    });

    group('hashCode', () {
      test('equal specs have identical hash codes', () {
        final spec1 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: tokens.colors.success.shade500,
          tokens: tokens,
          isInteractive: false,
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: tokens.colors.success.shade500,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec1.hashCode, equals(spec2.hashCode));
      });
    });

    group('interactive alerts invariant — all fill colours must be opaque', () {
      test('every interactive style has opaque fill colours to prevent shadow bleed', () {
        final accent = tokens.colors.primary.shade500;
        final styles = LayrzAlertStyle.values;
        const transparent = Color(0x00000000);

        for (final style in styles) {
          final spec = LayrzAlertStyleSpec.resolve(
            style: style,
            accent: accent,
            tokens: tokens,
            isInteractive: true,
          );

          // All fill colours (any colour that paints a surface area) must be opaque
          // when interactive to prevent shadows from bleeding through.
          // Exclude transparent/empty fills and non-fill colours (borders, text, icons).

          // Background is always a fill
          expect(
            spec.backgroundColor.isOpaque,
            isTrue,
            reason: 'Style $style should have opaque background when interactive',
          );

          // Left panel is a fill for split-panel styles
          if (spec.leftPanelColor != transparent) {
            expect(
              spec.leftPanelColor.isOpaque,
              isTrue,
              reason: 'Style $style should have opaque left panel when interactive',
            );
          }

          // Icon chip background is a fill for single-panel styles
          if (spec.iconChipBackground != transparent) {
            expect(
              spec.iconChipBackground.isOpaque,
              isTrue,
              reason: 'Style $style should have opaque icon chip when interactive',
            );
          }
        }
      });
    });

    group('border assertion — other styles unchanged', () {
      test('layrz style: solid accent border with base width', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
      });

      test('filledTonal style: transparent border with zero width', () {
        final accent = tokens.colors.success.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledTonal,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.borderWidth, equals(0.0));
      });

      test('filled style: accent border with base width', () {
        final accent = tokens.colors.danger.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
      });

      test('outlined style: accent border with base width', () {
        final accent = tokens.colors.warning.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: accent,
          tokens: tokens,
          isInteractive: false,
        );

        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
      });
    });
  });
}

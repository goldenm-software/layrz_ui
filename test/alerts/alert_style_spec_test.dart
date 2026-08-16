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
      test('layrz: surface background, tonal border, tonal icon chip, accent icon, fg1 title, fg2 body', () {
        final accent = tokens.colors.info.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(tokens.colors.surface));
        expect(spec.borderColor, equals(accent.withOpacityValue(tokens.colors.tonalOpacity)));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.iconChipBackground, equals(accent.withOpacityValue(tokens.colors.tonalOpacity)));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(tokens.colors.fg1));
        expect(spec.bodyColor, equals(tokens.colors.fg2));
      });
    });

    group('resolve() - filledTonal style', () {
      test('filledTonal: tonal background, transparent border, transparent icon chip, accent text', () {
        final accent = tokens.colors.success.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledTonal,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(accent.withOpacityValue(tokens.colors.tonalOpacity)));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.borderWidth, equals(0.0));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(accent));
        expect(spec.bodyColor, equals(accent));
      });
    });

    group('resolve() - filled style', () {
      test('filled: accent background, accent border, transparent icon chip, contrast text', () {
        final accent = tokens.colors.danger.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(accent));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent.contrastColor));
        expect(spec.titleColor, equals(accent.contrastColor));
        expect(spec.bodyColor, equals(accent.contrastColor));
      });
    });

    group('resolve() - outlined style', () {
      test('outlined: transparent background, accent border, transparent icon chip, accent text', () {
        final accent = tokens.colors.warning.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(const Color(0x00000000)));
        expect(spec.borderColor, equals(accent));
        expect(spec.borderWidth, equals(tokens.border.base));
        expect(spec.iconChipBackground, equals(const Color(0x00000000)));
        expect(spec.iconColor, equals(accent));
        expect(spec.titleColor, equals(accent));
        expect(spec.bodyColor, equals(accent));
      });
    });

    group('resolve() - filledIcon style', () {
      test('filledIcon: surface background, accent left panel, transparent border, contrast icon', () {
        final accent = tokens.colors.contextual.shade500;
        final spec = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filledIcon,
          accent: accent,
          tokens: tokens,
        );

        expect(spec.backgroundColor, equals(tokens.colors.surface));
        expect(spec.borderColor, equals(const Color(0x00000000)));
        expect(spec.borderWidth, equals(0.0));
        expect(spec.iconChipBackground, equals(accent));
        expect(spec.iconColor, equals(accent.contrastColor));
        expect(spec.titleColor, equals(tokens.colors.fg1));
        expect(spec.bodyColor, equals(tokens.colors.fg2));
      });
    });

    group('copyWith', () {
      test('copyWith replaces only specified fields', () {
        final original = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
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
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
        );

        expect(spec1, equals(spec2));
      });

      test('two specs with different fields are not equal', () {
        final spec1 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.layrz,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.filled,
          accent: tokens.colors.primary.shade500,
          tokens: tokens,
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
        );
        final spec2 = LayrzAlertStyleSpec.resolve(
          style: LayrzAlertStyle.outlined,
          accent: tokens.colors.success.shade500,
          tokens: tokens,
        );

        expect(spec1.hashCode, equals(spec2.hashCode));
      });
    });
  });
}

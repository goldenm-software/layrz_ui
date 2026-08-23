import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzColorExtensions', () {
    group('toHex / hex', () {
      test('returns 6-digit uppercase hex without alpha', () {
        const color = Color(0xFF001E60);
        expect(color.toHex(), equals('#001E60'));
        expect(color.hex, equals('#001E60'));
      });

      test('handles semi-transparent colors by ignoring alpha', () {
        const color = Color(0x80001E60); // 50% transparent
        expect(color.toHex(), equals('#001E60'));
      });

      test('returns uppercase hex', () {
        const color = Color(0xFFaabbcc);
        expect(color.toHex(), equals('#AABBCC'));
      });

      test('pads single-digit hex values with leading zero', () {
        const color = Color(0xFF000102);
        expect(color.toHex(), equals('#000102'));
      });
    });

    group('toHexWithAlpha / hexWithAlpha', () {
      test('returns 8-digit uppercase hex with alpha first', () {
        const color = Color(0xFF001E60);
        expect(color.toHexWithAlpha(), equals('#FF001E60'));
        expect(color.hexWithAlpha, equals('#FF001E60'));
      });

      test('includes alpha channel correctly', () {
        const color = Color(0x80001E60); // 50% transparent
        expect(color.toHexWithAlpha(), equals('#80001E60'));
      });

      test('handles fully transparent colors', () {
        const color = Color(0x00001E60);
        expect(color.toHexWithAlpha(), equals('#00001E60'));
      });
    });

    group('toInt', () {
      test('encodes color as 32-bit ARGB integer', () {
        const color = Color(0xFF001E60);
        expect(color.toInt(), equals(0xFF001E60));
      });

      test('includes alpha channel in encoding', () {
        const color = Color(0x80001E60);
        expect(color.toInt(), equals(0x80001E60));
      });

      test('encodes white as expected', () {
        const color = Color(0xFFFFFFFF);
        expect(color.toInt(), equals(0xFFFFFFFF));
      });

      test('encodes black as expected', () {
        const color = Color(0xFF000000);
        expect(color.toInt(), equals(0xFF000000));
      });
    });

    group('LayrzColorExtensions.fromHex (static)', () {
      test('parses 6-digit hex with leading hash', () {
        final color = LayrzColorExtensions.fromHex('#001E60');
        expect((color.r * 255.0).round(), equals(0));
        expect((color.g * 255.0).round(), equals(30));
        expect((color.b * 255.0).round(), equals(96));
        expect((color.a * 255).round(), equals(255)); // fully opaque
      });

      test('parses 6-digit hex without leading hash', () {
        final color = LayrzColorExtensions.fromHex('001E60');
        expect((color.r * 255.0).round(), equals(0));
        expect((color.g * 255.0).round(), equals(30));
        expect((color.b * 255.0).round(), equals(96));
        expect((color.a * 255).round(), equals(255)); // fully opaque
      });

      test('parses lowercase hex correctly', () {
        final color = LayrzColorExtensions.fromHex('#aabbcc');
        expect((color.r * 255.0).round(), equals(170));
        expect((color.g * 255.0).round(), equals(187));
        expect((color.b * 255.0).round(), equals(204));
      });

      test('round-trip fromHex(c.toHex()) equals original opaque color', () {
        const original = Color(0xFF001E60);
        final roundTrip = LayrzColorExtensions.fromHex(original.toHex());
        expect(roundTrip, equals(original));
      });

      test('round-trip with kPrimaryColor', () {
        final roundTrip = LayrzColorExtensions.fromHex(kPrimaryColor.toHex());
        expect(roundTrip, equals(kPrimaryColor));
      });
    });

    group('LayrzColorExtensions.fromHexWithAlpha (static)', () {
      test('parses 8-digit hex with leading hash', () {
        final color = LayrzColorExtensions.fromHexWithAlpha('#FF001E60');
        expect((color.a * 255).round(), equals(255)); // alpha from first pair
        expect((color.r * 255.0).round(), equals(0));
        expect((color.g * 255.0).round(), equals(30));
        expect((color.b * 255.0).round(), equals(96));
      });

      test('parses 8-digit hex without leading hash', () {
        final color = LayrzColorExtensions.fromHexWithAlpha('FF001E60');
        expect((color.a * 255).round(), equals(255));
        expect((color.r * 255.0).round(), equals(0));
        expect((color.g * 255.0).round(), equals(30));
        expect((color.b * 255.0).round(), equals(96));
      });

      test('parses alpha from first pair (swap detection)', () {
        // This test detects if alpha and red are swapped.
        // Alpha is 80 (hex), Red is 00, so if they're swapped, red becomes
        // 128.
        final color = LayrzColorExtensions.fromHexWithAlpha('#80001E60');
        expect((color.a * 255).round(), equals(128)); // 0x80 = 128
        expect((color.r * 255.0).round(), equals(0)); // NOT 128, would be if swapped
        expect((color.g * 255.0).round(), equals(30));
        expect((color.b * 255.0).round(), equals(96));
      });

      test('parses semi-transparent color correctly', () {
        final color = LayrzColorExtensions.fromHexWithAlpha('#80AABBCC');
        expect((color.a * 255).round(), equals(128));
        expect((color.r * 255.0).round(), equals(170));
        expect((color.g * 255.0).round(), equals(187));
        expect((color.b * 255.0).round(), equals(204));
      });

      test('round-trip fromHexWithAlpha(c.toHexWithAlpha()) equals original', () {
        const original = Color(0x80001E60);
        final roundTrip = LayrzColorExtensions.fromHexWithAlpha(original.toHexWithAlpha());
        expect(roundTrip, equals(original));
      });
    });

    group('LayrzColorExtensions.fromJson (static)', () {
      test('delegates to fromHex for same hex input', () {
        const testHex = '#001E60';
        final fromHex = LayrzColorExtensions.fromHex(testHex);
        final fromJson = LayrzColorExtensions.fromJson(testHex);
        expect(fromJson, equals(fromHex));
      });

      test('parses hex correctly when called via fromJson', () {
        final color = LayrzColorExtensions.fromJson('#AABBCC');
        expect((color.r * 255.0).round(), equals(170));
        expect((color.g * 255.0).round(), equals(187));
        expect((color.b * 255.0).round(), equals(204));
      });

      test('round-trip fromJson(c.toJson()) equals original', () {
        const original = Color(0xFF001E60);
        final roundTrip = LayrzColorExtensions.fromJson(original.toJson());
        expect(roundTrip, equals(original));
      });
    });

    group('contrastColor', () {
      test('returns black for white', () {
        const white = Color(0xFFFFFFFF);
        expect(white.contrastColor, equals(const Color(0xFF000000)));
      });

      test('returns white for black', () {
        const black = Color(0xFF000000);
        expect(black.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns white for primary brand color (#001E60)', () {
        const primary = Color(0xFF001E60);
        expect(primary.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns black for light background color (#FCFCFC)', () {
        const lightBg = Color(0xFFFCFCFC);
        expect(lightBg.contrastColor, equals(const Color(0xFF000000)));
      });

      test('returns white for Material green 500 (#4CAF50)', () {
        const green = Color(0xFF4CAF50);
        expect(green.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns white for Material red 500 (#F44336)', () {
        const red = Color(0xFFF44336);
        expect(red.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns white for Material blue 500 (#2196F3)', () {
        const blue = Color(0xFF2196F3);
        expect(blue.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns black for Material orange 500 (#FF9800)', () {
        const orange = Color(0xFFFF9800);
        expect(orange.contrastColor, equals(const Color(0xFF000000)));
      });

      test('returns black for Material grey 500 (#9E9E9E)', () {
        const grey = Color(0xFF9E9E9E);
        expect(grey.contrastColor, equals(const Color(0xFF000000)));
      });
    });

    group('opposite', () {
      test('opposite and contrastColor return identical values for white', () {
        const white = Color(0xFFFFFFFF);
        expect(white.opposite, equals(white.contrastColor));
      });

      test('opposite and contrastColor return identical values for black', () {
        const black = Color(0xFF000000);
        expect(black.opposite, equals(black.contrastColor));
      });

      test('opposite and contrastColor return identical values for grey', () {
        const grey = Color(0xFF808080);
        expect(grey.opposite, equals(grey.contrastColor));
      });

      test('opposite and contrastColor return identical values for primary color', () {
        const primary = Color(0xFF001E60);
        expect(primary.opposite, equals(primary.contrastColor));
      });

      test('opposite and contrastColor return identical values for light background', () {
        const lightBg = Color(0xFFFCFCFC);
        expect(lightBg.opposite, equals(lightBg.contrastColor));
      });

      test('opposite and contrastColor return identical values for green 500', () {
        const green = Color(0xFF4CAF50);
        expect(green.opposite, equals(green.contrastColor));
      });

      test('opposite and contrastColor return identical values for red 500', () {
        const red = Color(0xFFF44336);
        expect(red.opposite, equals(red.contrastColor));
      });

      test('opposite and contrastColor return identical values for blue 500', () {
        const blue = Color(0xFF2196F3);
        expect(blue.opposite, equals(blue.contrastColor));
      });
    });

    group('withOpacityValue', () {
      test('sets opacity to specified value', () {
        const color = Color(0xFF001E60);
        final withOpacity = color.withOpacityValue(0.5);
        expect((withOpacity.a * 255.0).round(), closeTo(127.5, 1)); // ~50% opacity
      });

      test('can set opacity to 1.0 (fully opaque)', () {
        const color = Color(0x80001E60);
        final opaque = color.withOpacityValue(1.0);
        expect((opaque.a * 255.0).round(), equals(255));
      });

      test('can set opacity to 0.0 (fully transparent)', () {
        const color = Color(0xFF001E60);
        final transparent = color.withOpacityValue(0.0);
        expect((transparent.a * 255.0).round(), equals(0));
      });

      test('preserves color channels when changing opacity', () {
        const color = Color(0xFF001E60);
        final withOpacity = color.withOpacityValue(0.25);
        expect(withOpacity.r, equals(color.r));
        expect(withOpacity.g, equals(color.g));
        expect(withOpacity.b, equals(color.b));
      });
    });

    group('toJson', () {
      test('toJson is alias for toHex', () {
        const color = Color(0xFF001E60);
        expect(color.toJson(), equals(color.toHex()));
      });
    });

    group('flattenOn', () {
      test('fully transparent colour flattened onto background returns background', () {
        const transparent = Color(0x00FF0000); // 0% alpha
        const background = Color(0xFF001E60);
        final result = transparent.flattenOn(background);
        expect(result, equals(background));
      });

      test('fully opaque colour flattened onto anything returns itself unchanged', () {
        const opaque = Color(0xFF001E60);
        const background = Color(0xFFFFFFFF);
        final result = opaque.flattenOn(background);
        expect(result, equals(opaque));
      });

      test('50% black flattened onto white returns expected blended grey', () {
        const halfBlack = Color(0x80000000);
        const white = Color(0xFFFFFFFF);
        final result = halfBlack.flattenOn(white);

        // 50% alpha blend of black onto white produces 50% grey
        // Formula: result = foreground + background * (1 - alpha)
        // = 0 + 255 * (1 - 0.5) = 127.5
        expect((result.r * 255.0).round(), closeTo(127, 1));
        expect((result.g * 255.0).round(), closeTo(127, 1));
        expect((result.b * 255.0).round(), closeTo(127, 1));
        expect((result.a * 255).round(), equals(255)); // always opaque
      });

      test('result is always opaque regardless of input alpha', () {
        const translucent = Color(0x40FF5733); // ~25% opacity
        const background = Color(0xFF001E60);
        final result = translucent.flattenOn(background);
        expect((result.a * 255).round(), equals(255));
      });

      test('alert real case: tonal at 20% flattened onto surface', () {
        // Simulate the alert case: accent at tonalOpacity onto tokens.colors.sf2
        final tokens = LayrzTokens.light();
        final accent = tokens.colors.info.shade500;
        final tonal = accent.withOpacityValue(tokens.colors.tonalOpacity);

        // Both methods should produce the same result
        final viaFlattenOn = tonal.flattenOn(tokens.colors.sf2);
        final viaAlphaBlend = Color.alphaBlend(tonal, tokens.colors.sf2);

        expect(viaFlattenOn, equals(viaAlphaBlend));
      });
    });

    group('isOpaque', () {
      test('fully opaque colour returns true', () {
        const opaque = Color(0xFF001E60);
        expect(opaque.isOpaque, isTrue);
      });

      test('fully transparent colour returns false', () {
        const transparent = Color(0x00001E60);
        expect(transparent.isOpaque, isFalse);
      });

      test('partial alpha returns false', () {
        const partial = Color(0x80001E60);
        expect(partial.isOpaque, isFalse);
      });

      test('result of flattenOn is always opaque', () {
        const translucent = Color(0x40FF5733);
        const background = Color(0xFF001E60);
        final flattened = translucent.flattenOn(background);
        expect(flattened.isOpaque, isTrue);
      });

      test('white is opaque', () {
        const white = Color(0xFFFFFFFF);
        expect(white.isOpaque, isTrue);
      });

      test('black is opaque', () {
        const black = Color(0xFF000000);
        expect(black.isOpaque, isTrue);
      });
    });
  });
}

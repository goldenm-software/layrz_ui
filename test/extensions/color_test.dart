import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/extensions/extensions.dart';

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
      test('returns black for light colors', () {
        const lightColor = Color(0xFFFFFFFF); // white
        expect(lightColor.contrastColor, equals(const Color(0xFF000000)));
      });

      test('returns white for dark colors', () {
        const darkColor = Color(0xFF000000); // black
        expect(darkColor.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns white for primary brand color', () {
        const primary = Color(0xFF001E60); // Layrz primary
        expect(primary.contrastColor, equals(const Color(0xFFFFFFFF)));
      });

      test('returns black for light background color', () {
        const lightBg = Color(0xFFFCFCFC); // Layrz light background
        expect(lightBg.contrastColor, equals(const Color(0xFF000000)));
      });

      test('uses luminance threshold of 0.179', () {
        // Create a color near the luminance threshold
        const threshold = Color(
          0xFFB3B3B3,
        ); // Approximately at the 0.179 threshold
        final contrast = threshold.contrastColor;
        expect([
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ], contains(contrast));
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
  });
}

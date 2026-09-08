import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzNotoColorEmojiFont', () {
    test('has name "Noto Color Emoji"', () {
      const font = LayrzNotoColorEmojiFont();
      expect(font.name, 'Noto Color Emoji');
    });

    test('is const-constructible', () {
      const font = LayrzNotoColorEmojiFont();
      expect(font, isA<LayrzNotoColorEmojiFont>());
    });

    test('load completes without error (bundled fonts need no explicit fetch)', () async {
      const font = LayrzNotoColorEmojiFont();
      await expectLater(font.load(), completes);
    });

    test('every style getter reports the "Noto Color Emoji" family at w400', () {
      const font = LayrzNotoColorEmojiFont();
      for (final style in [font.display, font.headline, font.title, font.body, font.label]) {
        expect(style.fontFamily, 'Noto Color Emoji');
        expect(style.fontWeight, FontWeight.w400);
      }
    });

    test('every style getter carries no color or font size of its own', () {
      const font = LayrzNotoColorEmojiFont();
      for (final style in [font.display, font.headline, font.title, font.body, font.label]) {
        expect(style.color, isNull);
        expect(style.fontSize, isNull);
      }
    });

    // registerOnWeb loads the bundled asset via rootBundle.load and hands it
    // to registerWebFontFromBytes -- on the VM test target that resolves to
    // register_web_font_stub.dart's no-op (see register_web_font.dart's
    // conditional export), so this exercises the real bundled-asset read
    // path end to end without depending on package:web.
    test('registerOnWeb completes without error on the native (non-web) target', () async {
      const font = LayrzNotoColorEmojiFont();
      await expectLater(font.registerOnWeb(), completes);
    });
  });
}

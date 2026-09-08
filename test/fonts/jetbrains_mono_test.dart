import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzJetBrainsMonoFont', () {
    test('has name "JetBrains Mono"', () {
      const font = LayrzJetBrainsMonoFont();
      expect(font.name, 'JetBrains Mono');
    });

    test('is const-constructible', () {
      const font = LayrzJetBrainsMonoFont();
      expect(font, isA<LayrzJetBrainsMonoFont>());
    });

    test('load completes without error (bundled fonts need no explicit fetch)', () async {
      const font = LayrzJetBrainsMonoFont();
      await expectLater(font.load(), completes);
    });

    test('every style getter reports the "JetBrains Mono" family', () {
      const font = LayrzJetBrainsMonoFont();
      for (final style in [font.display, font.headline, font.title, font.body, font.label]) {
        expect(style.fontFamily, 'JetBrains Mono');
      }
    });

    // The bundled asset is a single variable font spanning the `wght` axis,
    // so weight is expressed via fontVariations rather than fontWeight (see
    // this class's own doc) -- fontWeight itself must stay unset.
    test('weight is expressed via fontVariations, never fontWeight', () {
      const font = LayrzJetBrainsMonoFont();
      for (final style in [font.display, font.headline, font.title, font.body, font.label]) {
        expect(style.fontWeight, isNull);
        expect(style.fontVariations, isNotNull);
        expect(style.fontVariations, hasLength(1));
        expect(style.fontVariations!.single.axis, 'wght');
      }
    });

    test('display and headline/title carry heavier weights than body/label', () {
      const font = LayrzJetBrainsMonoFont();
      expect(font.display.fontVariations!.single.value, 700);
      expect(font.headline.fontVariations!.single.value, 600);
      expect(font.title.fontVariations!.single.value, 600);
      expect(font.body.fontVariations!.single.value, 400);
      expect(font.label.fontVariations!.single.value, 400);
    });

    test('every style getter carries no color or font size of its own', () {
      const font = LayrzJetBrainsMonoFont();
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
      const font = LayrzJetBrainsMonoFont();
      await expectLater(font.registerOnWeb(), completes);
    });
  });
}

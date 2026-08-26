import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzFont abstract', () {
    test('abstract class defines name field and style getters', () {
      // Use LayrzRobotoFont as a concrete implementation
      const font = LayrzRobotoFont();
      expect(font.name, 'Roboto');
      expect(font.display, isA<TextStyle>());
      expect(font.headline, isA<TextStyle>());
      expect(font.title, isA<TextStyle>());
      expect(font.body, isA<TextStyle>());
      expect(font.label, isA<TextStyle>());
    });
  });

  group('LayrzRobotoFont', () {
    test('has name Roboto', () {
      const font = LayrzRobotoFont();
      expect(font.name, 'Roboto');
    });

    test('display returns w700 weight', () {
      const font = LayrzRobotoFont();
      expect(font.display.fontFamily, 'Roboto');
      expect(font.display.fontWeight, FontWeight.w700);
    });

    test('headline returns w600 weight', () {
      const font = LayrzRobotoFont();
      expect(font.headline.fontFamily, 'Roboto');
      expect(font.headline.fontWeight, FontWeight.w600);
    });

    test('title returns w600 weight', () {
      const font = LayrzRobotoFont();
      expect(font.title.fontFamily, 'Roboto');
      expect(font.title.fontWeight, FontWeight.w600);
    });

    test('body returns w400 weight', () {
      const font = LayrzRobotoFont();
      expect(font.body.fontFamily, 'Roboto');
      expect(font.body.fontWeight, FontWeight.w400);
    });

    test('label returns w400 weight', () {
      const font = LayrzRobotoFont();
      expect(font.label.fontFamily, 'Roboto');
      expect(font.label.fontWeight, FontWeight.w400);
    });

    test('is const-constructible', () {
      const font = LayrzRobotoFont();
      expect(font, isA<LayrzRobotoFont>());
    });

    test('all styles have no color or font size set', () {
      const font = LayrzRobotoFont();
      expect(font.display.color, isNull);
      expect(font.display.fontSize, isNull);
      expect(font.headline.color, isNull);
      expect(font.headline.fontSize, isNull);
      expect(font.title.color, isNull);
      expect(font.title.fontSize, isNull);
      expect(font.body.color, isNull);
      expect(font.body.fontSize, isNull);
      expect(font.label.color, isNull);
      expect(font.label.fontSize, isNull);
    });

    test('LayrzRobotoFont.load throws UnsupportedError', () async {
      const font = LayrzRobotoFont();
      await expectLater(font.load(), throwsUnsupportedError);
    });
  });
}

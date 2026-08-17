import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzFontSource', () {
    test('has three values: google, local, uri', () {
      expect(LayrzFontSource.values.length, 3);
      expect(LayrzFontSource.values, contains(LayrzFontSource.google));
      expect(LayrzFontSource.values, contains(LayrzFontSource.local));
      expect(LayrzFontSource.values, contains(LayrzFontSource.uri));
    });
  });

  group('LayrzFont', () {
    test('creates a local font', () {
      const font = LayrzFont(source: LayrzFontSource.local, name: 'Roboto');
      expect(font.source, LayrzFontSource.local);
      expect(font.name, 'Roboto');
      expect(font.uri, isNull);
    });

    test('creates a google font', () {
      const font = LayrzFont(source: LayrzFontSource.google, name: 'Open Sans');
      expect(font.source, LayrzFontSource.google);
      expect(font.name, 'Open Sans');
      expect(font.uri, isNull);
    });

    test('creates a uri font', () {
      const font = LayrzFont(
        source: LayrzFontSource.uri,
        name: 'CustomFont',
        uri: 'https://example.com/font.ttf',
      );
      expect(font.source, LayrzFontSource.uri);
      expect(font.name, 'CustomFont');
      expect(font.uri, 'https://example.com/font.ttf');
    });

    test('asserts that uri is non-null when source is uri', () {
      expect(
        () => LayrzFont(source: LayrzFontSource.uri, name: 'BadFont', uri: null),
        throwsAssertionError,
      );
    });

    test('allows null uri for non-uri sources', () {
      const localFont = LayrzFont(
        source: LayrzFontSource.local,
        name: 'Local',
        uri: null,
      );
      expect(localFont.uri, isNull);

      const googleFont = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Google',
        uri: null,
      );
      expect(googleFont.uri, isNull);
    });

    test('copyWith updates source', () {
      const original = LayrzFont(source: LayrzFontSource.local, name: 'Roboto');
      final updated = original.copyWith(source: LayrzFontSource.google);
      expect(updated.source, LayrzFontSource.google);
      expect(updated.name, 'Roboto');
      expect(updated.uri, isNull);
    });

    test('copyWith updates name', () {
      const original = LayrzFont(source: LayrzFontSource.local, name: 'Roboto');
      final updated = original.copyWith(name: 'Ubuntu');
      expect(updated.source, LayrzFontSource.local);
      expect(updated.name, 'Ubuntu');
      expect(updated.uri, isNull);
    });

    test('copyWith updates uri', () {
      const original = LayrzFont(
        source: LayrzFontSource.uri,
        name: 'Custom',
        uri: 'https://example.com/font.ttf',
      );
      final updated = original.copyWith(uri: 'https://new.com/font.ttf');
      expect(updated.source, LayrzFontSource.uri);
      expect(updated.name, 'Custom');
      expect(updated.uri, 'https://new.com/font.ttf');
    });

    test('copyWith preserves fields not specified', () {
      const original = LayrzFont(
        source: LayrzFontSource.uri,
        name: 'Custom',
        uri: 'https://example.com/font.ttf',
      );
      final updated = original.copyWith(name: 'NewName');
      expect(updated.source, LayrzFontSource.uri);
      expect(updated.name, 'NewName');
      expect(updated.uri, 'https://example.com/font.ttf');
    });

    test('equality works for identical fonts', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      const font2 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      expect(font1, font2);
    });

    test('equality works for different fonts', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      const font2 = LayrzFont(source: LayrzFontSource.local, name: 'Open Sans');
      expect(font1, isNot(font2));
    });

    test('equality distinguishes by name', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      const font2 = LayrzFont(source: LayrzFontSource.google, name: 'Roboto');
      expect(font1, isNot(font2));
    });

    test('equality distinguishes by uri', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.uri,
        name: 'Custom',
        uri: 'https://example.com/font1.ttf',
      );
      const font2 = LayrzFont(
        source: LayrzFontSource.uri,
        name: 'Custom',
        uri: 'https://example.com/font2.ttf',
      );
      expect(font1, isNot(font2));
    });

    test('hashCode is equal for equal fonts', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      const font2 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      expect(font1.hashCode, font2.hashCode);
    });

    test('hashCode is different for different fonts', () {
      const font1 = LayrzFont(
        source: LayrzFontSource.google,
        name: 'Open Sans',
      );
      const font2 = LayrzFont(source: LayrzFontSource.local, name: 'Open Sans');
      expect(font1.hashCode, isNot(font2.hashCode));
    });

    test('toString returns a descriptive string', () {
      const font = LayrzFont(source: LayrzFontSource.google, name: 'Open Sans');
      final stringRepresentation = font.toString();
      expect(stringRepresentation, contains('LayrzFont'));
      expect(stringRepresentation, contains('google'));
      expect(stringRepresentation, contains('Open Sans'));
    });
  });

  group('Font constants', () {
    test('kLayrzFont is Open Sans with google source', () {
      expect(kLayrzFont.source, LayrzFontSource.google);
      expect(kLayrzFont.name, 'Open Sans');
      expect(kLayrzFont.uri, isNull);
    });

    test('kLayrzFontFallbacks is [Ubuntu, Roboto]', () {
      expect(kLayrzFontFallbacks, ['Ubuntu', 'Roboto']);
      expect(kLayrzFontFallbacks.length, 2);
    });
  });
}

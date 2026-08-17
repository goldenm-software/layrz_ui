import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LayrzGoogleFontsHandler', () {
    const handler = LayrzGoogleFontsHandler();

    group('fallbacks', () {
      test('returns kLayrzFontFallbacks', () {
        expect(handler.fallbacks, kLayrzFontFallbacks);
        expect(handler.fallbacks, ['Ubuntu', 'Roboto']);
      });
    });

    group('resolveFamily', () {
      test('returns name verbatim for local fonts', () {
        const font = LayrzFont(
          source: LayrzFontSource.local,
          name: 'MyLocalFont',
        );
        expect(handler.resolveFamily(font), 'MyLocalFont');
      });

      test('returns name verbatim for uri fonts', () {
        const font = LayrzFont(
          source: LayrzFontSource.uri,
          name: 'MyCustomFont',
          uri: 'https://example.com/font.ttf',
        );
        expect(handler.resolveFamily(font), 'MyCustomFont');
      });

      test('returns a valid font family for a known google font', () {
        // Open Sans is a real Google Font
        const font = LayrzFont(
          source: LayrzFontSource.google,
          name: 'Open Sans',
        );
        final resolved = handler.resolveFamily(font);
        expect(resolved, isNotEmpty);
        // Open Sans should resolve to itself via GoogleFonts.getFont
        expect(resolved, isA<String>());
      });

      test('falls back gracefully for unknown google fonts', () {
        // Use a font name that is unlikely to exist in Google Fonts
        const font = LayrzFont(
          source: LayrzFontSource.google,
          name: 'ThisFontDoesNotExistOnGoogleFonts12345',
        );
        final resolved = handler.resolveFamily(font);
        // Should fall back to Ubuntu
        expect(resolved, isNotEmpty);
        expect(resolved, isA<String>());
      });
    });

    group('resolveFamilyForWeight', () {
      test('returns name verbatim for local fonts regardless of weight', () {
        const font = LayrzFont(
          source: LayrzFontSource.local,
          name: 'MyLocalFont',
        );
        expect(handler.resolveFamilyForWeight(font, FontWeight.w300), 'MyLocalFont');
        expect(handler.resolveFamilyForWeight(font, FontWeight.w700), 'MyLocalFont');
      });

      test('returns name verbatim for uri fonts regardless of weight', () {
        const font = LayrzFont(
          source: LayrzFontSource.uri,
          name: 'MyCustomFont',
          uri: 'https://example.com/font.ttf',
        );
        expect(handler.resolveFamilyForWeight(font, FontWeight.w300), 'MyCustomFont');
        expect(handler.resolveFamilyForWeight(font, FontWeight.w700), 'MyCustomFont');
      });

      test('returns different families for different weights for google fonts', () {
        // Open Sans is a real Google Font with multiple weight variants
        const font = LayrzFont(
          source: LayrzFontSource.google,
          name: 'Open Sans',
        );
        final w300 = handler.resolveFamilyForWeight(font, FontWeight.w300);
        final w400 = handler.resolveFamilyForWeight(font, FontWeight.w400);
        final w600 = handler.resolveFamilyForWeight(font, FontWeight.w600);
        final w700 = handler.resolveFamilyForWeight(font, FontWeight.w700);
        final w800 = handler.resolveFamilyForWeight(font, FontWeight.w800);

        // All families should be non-empty strings
        expect(w300, isNotEmpty);
        expect(w400, isNotEmpty);
        expect(w600, isNotEmpty);
        expect(w700, isNotEmpty);
        expect(w800, isNotEmpty);

        // At least some weights should return different families for a multi-weight font
        // (This may not always be true if the variant mapping is limited, but for
        // Open Sans we expect differences.)
        final families = <String>{w300, w400, w600, w700, w800};
        expect(
          families.length,
          greaterThan(1),
          reason: 'Open Sans should have different families for different weights',
        );
      });

      test('falls back gracefully for unknown google fonts with weight', () {
        const font = LayrzFont(
          source: LayrzFontSource.google,
          name: 'ThisFontDoesNotExistOnGoogleFonts12345',
        );
        final resolved = handler.resolveFamilyForWeight(font, FontWeight.w700);
        expect(resolved, isNotEmpty);
        expect(resolved, isA<String>());
      });
    });

    group('preload', () {
      test('completes immediately for local fonts', () async {
        const font = LayrzFont(
          source: LayrzFontSource.local,
          name: 'LocalFont',
        );
        // Should complete without error or delay
        await expectLater(handler.preload(font), completes);
      });

      test(
        'throws StateError when preloading uri font without fetcher',
        () async {
          const font = LayrzFont(
            source: LayrzFontSource.uri,
            name: 'CustomFont',
            uri: 'https://example.com/font.ttf',
          );
          expect(
            () => handler.preload(font),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains('LayrzGoogleFontsHandler.preload'),
                  contains('CustomFont'),
                  contains('fetcher'),
                ),
              ),
            ),
          );
        },
      );

      test(
        'calls fetcher exactly once when preloading uri font with fetcher',
        () async {
          const font = LayrzFont(
            source: LayrzFontSource.uri,
            name: 'CustomFont',
            uri: 'https://example.com/font.ttf',
          );

          var fetcherCallCount = 0;
          String? fetchedUri;

          Future<ByteData> stubFetcher(String uri) async {
            fetcherCallCount++;
            fetchedUri = uri;
            // Return a minimal ByteData. FontLoader.load() will likely fail with invalid bytes,
            // but that is expected and acceptable for this test.
            return ByteData(4);
          }

          final handlerWithFetcher = LayrzGoogleFontsHandler(
            fetcher: stubFetcher,
          );

          // Preload may fail when loading invalid font bytes, but the fetcher should be called.
          try {
            await handlerWithFetcher.preload(font);
          } catch (_) {
            // Ignore any load failures from invalid bytes
          }

          expect(fetcherCallCount, 1);
          expect(fetchedUri, 'https://example.com/font.ttf');
        },
      );
    });
  });
}

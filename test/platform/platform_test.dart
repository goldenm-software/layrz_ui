import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzPlatform', () {
    test('current returns a non-null LayrzPlatform value', () {
      final platform = LayrzPlatform.current;
      expect(platform, isNotNull);
      expect(platform, isA<LayrzPlatform>());
    });

    test('all enum values have a toString()', () {
      const values = [
        LayrzPlatform.web,
        LayrzPlatform.android,
        LayrzPlatform.iOS,
        LayrzPlatform.macOS,
        LayrzPlatform.windows,
        LayrzPlatform.linux,
        LayrzPlatform.fuchsia,
        LayrzPlatform.webWasm,
        LayrzPlatform.unknown,
      ];

      for (final platform in values) {
        expect(platform.toString(), isNotEmpty);
        expect(platform.toString(), isA<String>());
      }
    });

    test('toString returns human-readable names', () {
      expect(LayrzPlatform.web.toString(), equals('Web (CanvasKit)'));
      expect(LayrzPlatform.webWasm.toString(), equals('Web (WASM)'));
      expect(LayrzPlatform.android.toString(), equals('Google Android'));
      expect(LayrzPlatform.iOS.toString(), equals('Apple iOS'));
      expect(LayrzPlatform.macOS.toString(), equals('Apple macOS'));
      expect(LayrzPlatform.windows.toString(), equals('Microsoft Windows'));
      expect(LayrzPlatform.linux.toString(), equals('GNU/Linux'));
      expect(LayrzPlatform.fuchsia.toString(), equals('Google Fuchsia'));
      expect(LayrzPlatform.unknown.toString(), equals('Unknown'));
    });

    group('Static predicates', () {
      test('isMobile is true for Android and iOS only', () {
        if (LayrzPlatform.isMobile) {
          final current = LayrzPlatform.current;
          expect([LayrzPlatform.android, LayrzPlatform.iOS], contains(current));
        }
      });

      test('isDesktop is true for macOS, Windows, and Linux only', () {
        if (LayrzPlatform.isDesktop) {
          final current = LayrzPlatform.current;
          expect([
            LayrzPlatform.macOS,
            LayrzPlatform.windows,
            LayrzPlatform.linux,
          ], contains(current));
        }
      });

      test('isMobile and isDesktop are mutually exclusive', () {
        // isMobile should not be true when isDesktop is true
        if (LayrzPlatform.isDesktop) {
          expect(LayrzPlatform.isMobile, isFalse);
        }
        // isMobile should not be false when isDesktop is false
        if (LayrzPlatform.isMobile) {
          expect(LayrzPlatform.isDesktop, isFalse);
        }
      });

      test('exactly one platform predicate is true at a time', () {
        final predicates = [
          ('isWeb', LayrzPlatform.isWeb),
          ('isAndroid', LayrzPlatform.isAndroid),
          ('isIOS', LayrzPlatform.isIOS),
          ('isMacOS', LayrzPlatform.isMacOS),
          ('isWindows', LayrzPlatform.isWindows),
          ('isLinux', LayrzPlatform.isLinux),
          ('isFuchsia', LayrzPlatform.isFuchsia),
          ('isWebWasm', LayrzPlatform.isWebWasm),
        ];

        int trueCount = 0;
        for (final (_, value) in predicates) {
          if (value) trueCount++;
        }

        expect(
          trueCount,
          equals(1),
          reason: 'Exactly one platform predicate should be true; found $trueCount',
        );
      });

      test('all predicates align with current platform', () {
        final current = LayrzPlatform.current;

        switch (current) {
          case LayrzPlatform.web:
            expect(LayrzPlatform.isWeb, isTrue);
          case LayrzPlatform.android:
            expect(LayrzPlatform.isAndroid, isTrue);
          case LayrzPlatform.iOS:
            expect(LayrzPlatform.isIOS, isTrue);
          case LayrzPlatform.macOS:
            expect(LayrzPlatform.isMacOS, isTrue);
          case LayrzPlatform.windows:
            expect(LayrzPlatform.isWindows, isTrue);
          case LayrzPlatform.linux:
            expect(LayrzPlatform.isLinux, isTrue);
          case LayrzPlatform.fuchsia:
            expect(LayrzPlatform.isFuchsia, isTrue);
          case LayrzPlatform.webWasm:
            expect(LayrzPlatform.isWebWasm, isTrue);
          case LayrzPlatform.unknown:
            fail('Current platform should not be unknown');
        }
      });
    });

    group('Composite predicates', () {
      test('isMobile includes Android and iOS', () {
        final current = LayrzPlatform.current;
        final shouldBeMobile = current == LayrzPlatform.android || current == LayrzPlatform.iOS;
        expect(LayrzPlatform.isMobile, equals(shouldBeMobile));
      });

      test('isDesktop includes macOS, Windows, and Linux', () {
        final current = LayrzPlatform.current;
        final shouldBeDesktop =
            current == LayrzPlatform.macOS || current == LayrzPlatform.windows || current == LayrzPlatform.linux;
        expect(LayrzPlatform.isDesktop, equals(shouldBeDesktop));
      });

      test('isMobile and isDesktop cannot both be true', () {
        expect(LayrzPlatform.isMobile && LayrzPlatform.isDesktop, isFalse);
      });
    });
  });
}

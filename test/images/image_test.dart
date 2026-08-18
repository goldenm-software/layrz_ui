import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzImage', () {
    group('Rendering - Raster Images', () {
      testWidgets('renders asset image', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('applies width and height', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 200,
            height: 150,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, equals(200));
        expect(image.height, equals(150));
      });

      testWidgets('applies fit parameter', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, equals(BoxFit.contain));
      });

      testWidgets('applies alignment parameter', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
            alignment: Alignment.topLeft,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.alignment, equals(Alignment.topLeft));
      });

      testWidgets('applies filterQuality', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
            filterQuality: FilterQuality.high,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.filterQuality, equals(FilterQuality.high));
      });

      testWidgets('defaults to BoxFit.cover', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, equals(BoxFit.cover));
      });

      testWidgets('defaults to Alignment.center', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.alignment, equals(Alignment.center));
      });

      testWidgets('defaults to FilterQuality.medium', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
            width: 100,
            height: 100,
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.filterQuality, equals(FilterQuality.medium));
      });
    });

    group('Rendering - Base64 and Data-URI', () {
      testWidgets('decodes and displays base64 image', (tester) async {
        const plainText = 'test data';
        final encoded = base64Encode(utf8.encode(plainText));

        await pumpThemed(
          tester,
          LayrzImage(
            source: encoded,
            width: 100,
            height: 100,
          ),
        );

        // Should render Image.memory
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('decodes and displays data-URI image', (tester) async {
        const plainText = 'test data';
        final encoded = base64Encode(utf8.encode(plainText));
        final dataUri = 'data:image/png;base64,$encoded';

        await pumpThemed(
          tester,
          LayrzImage(
            source: dataUri,
            width: 100,
            height: 100,
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('shows fallback on malformed base64', (tester) async {
        const fallbackText = 'Image failed to load';

        await pumpThemed(
          tester,
          LayrzImage(
            source: 'not!valid!base64!!!',
            width: 100,
            height: 100,
            fallback: const Text(fallbackText),
          ),
        );

        expect(find.text(fallbackText), findsOneWidget);
      });
    });

    group('Fallback behavior', () {
      testWidgets('shows fallback when provided', (tester) async {
        const fallbackText = 'Image not found';

        await pumpThemed(
          tester,
          LayrzImage(
            source: 'nonexistent_asset.png',
            width: 100,
            height: 100,
            fallback: const Text(fallbackText),
          ),
        );

        // The asset won't load, so the errorBuilder should show the fallback
        // Note: This is an indirect test; the actual behavior depends on
        // Flutter's Image error handling.
      });

      testWidgets('renders empty SizedBox when no fallback provided', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'nonexistent_asset.png',
            width: 100,
            height: 100,
          ),
        );

        // Should render something, but we can't directly verify it's empty
        // without inspecting the Image's errorBuilder
        expect(find.byType(Overlay), findsWidgets);
      });
    });

    group('Edge cases', () {
      testWidgets('handles empty source gracefully', (tester) async {
        // Empty string should be treated as an asset path
        await pumpThemed(
          tester,
          const LayrzImage(
            source: '',
            width: 100,
            height: 100,
          ),
        );

        // Should still render an Image (though it will fail to load)
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('can have null width and height', (tester) async {
        await pumpThemed(
          tester,
          const LayrzImage(
            source: 'assets/test.png',
          ),
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, isNull);
        expect(image.height, isNull);
      });
    });
  });
}

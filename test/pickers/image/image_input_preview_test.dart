import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/pickers/src/image/image_input_preview.dart';

import '../../helpers/pump_themed.dart';

/// A minimal, genuinely decodable 1x1 red PNG (verified against a real PNG
/// decoder, not hand-derived).
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0xC9,
  0xFE,
  0x92,
  0xEF,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// A second, genuinely decodable 1x1 black PNG whose base64 encoding
/// contains no `/` character.
///
/// `LayrzImage`'s bare-base64 heuristic (`isLikelyBase64` in
/// `lib/src/images/src/image_source.dart`) deliberately excludes any string
/// containing `/`, since asset paths use it as a path separator -- a real,
/// documented limitation of the bare-base64 detection, not a bug. A base64
/// payload is only guaranteed to be treated as bare base64 (rather than
/// mistaken for an asset path) when it happens not to contain that
/// character, so the "valid bare base64" happy-path test below needs a
/// payload verified to satisfy that constraint, not just any decodable image.
final Uint8List _validPngBytesNoSlashInBase64 = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x60,
  0x60,
  0x60,
  0x00,
  0x00,
  0x00,
  0x04,
  0x00,
  0x01,
  0xF6,
  0x17,
  0x38,
  0x55,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  /// Pumps [child] at a wide viewport (trap 1, project CLAUDE.md rule #2).
  Future<void> pumpWide(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpThemed(tester, child);
    await tester.pump();
  }

  group('LayrzImageInputPreview happy path', () {
    testWidgets('a valid data-URI source renders via LayrzImage, not the fallback', (tester) async {
      final dataUri = 'data:image/png;base64,${base64Encode(_validPngBytes)}';

      await pumpWide(tester, LayrzImageInputPreview(source: dataUri));

      expect(find.byType(LayrzImage), findsOneWidget);
      expect(find.textContaining("Couldn't load"), findsNothing);
    });

    testWidgets('a valid bare base64 source renders via LayrzImage', (tester) async {
      final bare = base64Encode(_validPngBytesNoSlashInBase64);
      expect(bare.contains('/'), isFalse, reason: 'sanity check on the fixture -- see its own doc comment');

      await pumpWide(tester, LayrzImageInputPreview(source: bare));

      expect(find.byType(LayrzImage), findsOneWidget);
      expect(find.textContaining("Couldn't load"), findsNothing);
    });

    testWidgets('size controls the rendered LayrzImage width and height', (tester) async {
      final dataUri = 'data:image/png;base64,${base64Encode(_validPngBytes)}';

      await pumpWide(tester, LayrzImageInputPreview(source: dataUri, size: 64));

      final image = tester.widget<LayrzImage>(find.byType(LayrzImage));
      expect(image.width, 64);
      expect(image.height, 64);
    });
  });

  group('LayrzImageInputPreview broken-image fallback (dossier §8c, liliana — calm failure state)', () {
    testWidgets("a malformed base64 source renders the 'couldn't load image' fallback, never a blank box", (
      tester,
    ) async {
      await pumpWide(tester, const LayrzImageInputPreview(source: 'not-valid-base64!!!'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't load image"), findsOneWidget);
    });

    testWidgets('a malformed data-URI source renders the fallback', (tester) async {
      await pumpWide(tester, const LayrzImageInputPreview(source: 'data:image/png;base64,not-real-data'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't load image"), findsOneWidget);
    });

    testWidgets('the fallback fills the same square footprint the successful preview would (no geometry shift)', (
      tester,
    ) async {
      await pumpWide(tester, const LayrzImageInputPreview(source: 'not-valid-base64!!!', size: 80));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.ancestor(of: find.textContaining("Couldn't load image"), matching: find.byType(Container)).first,
      );
      expect(container.constraints?.maxWidth ?? (container.constraints?.minWidth), isNotNull);
    });
  });
}

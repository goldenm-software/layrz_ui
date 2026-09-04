import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

/// A minimal valid 1x1 transparent PNG, used so [LayrzImage.source] decodes
/// successfully in tests rather than falling back.
final Uint8List _tinyPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

void main() {
  group('LayrzFileInputPreview', () {
    testWidgets('renders an image thumbnail for image files', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final result = LayrzFileInputResult(name: 'photo.png', mimeType: 'image/png', bytes: _tinyPngBytes);

      await pumpThemed(tester, LayrzFileInputPreview(result: result));
      await tester.pump();

      expect(find.byType(LayrzImage), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders a name+icon chip for non-image files', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final result = LayrzFileInputResult(
        name: 'report.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await pumpThemed(tester, LayrzFileInputPreview(result: result));
      await tester.pump();

      expect(find.byType(LayrzImage), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('honors the size parameter for the chip', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final result = LayrzFileInputResult(
        name: 'report.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await pumpThemed(tester, LayrzFileInputPreview(result: result, size: 96));
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 96);
      expect(container.constraints?.maxHeight, 96);
    });
  });
}

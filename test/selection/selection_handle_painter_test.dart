import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSelectionHandlePainter', () {
    test('creates with color', () {
      final painter = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
      );
      expect(painter.color, const Color(0xFF0000FF));
    });

    test('shouldRepaint returns true when color changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
      );
      final painter2 = LayrzSelectionHandlePainter(
        color: const Color(0xFFFF0000),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when color stays the same', () {
      final painter1 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
      );
      final painter2 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
      );
      expect(painter1.shouldRepaint(painter2), false);
    });

    test('paint creates a teardrop path (circle with square corner)', () {
      // The teardrop is drawn as a circle with a square corner cut out.
      // We verify this by checking that paint() completes without error.
      final painter = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
      );
      const size = Size(22.0, 22.0);

      // Create a mock canvas to verify paint is called
      final recordingCanvas = ui.PictureRecorder();
      final canvas = Canvas(recordingCanvas);

      // This should not throw
      expect(
        () => painter.paint(canvas, size),
        returnsNormally,
      );

      // Close the recording
      recordingCanvas.endRecording();
    });
  });
}

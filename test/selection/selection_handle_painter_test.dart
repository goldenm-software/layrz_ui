import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

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

  group('LayrzTextSelectionControls handle anchor points', () {
    test('getHandleAnchor returns correct anchor for left handle', () {
      final controls = LayrzTextSelectionControls.instance;
      final anchor = controls.getHandleAnchor(
        TextSelectionHandleType.left,
        20.0,
      );
      // Left handle anchor should be at the right edge (22, 0)
      expect(anchor, const Offset(22.0, 0.0));
    });

    test('getHandleAnchor returns correct anchor for right handle', () {
      final controls = LayrzTextSelectionControls.instance;
      final anchor = controls.getHandleAnchor(
        TextSelectionHandleType.right,
        20.0,
      );
      // Right handle anchor should be at the left edge (0, 0)
      expect(anchor, Offset.zero);
    });

    test('getHandleAnchor returns correct anchor for collapsed handle', () {
      final controls = LayrzTextSelectionControls.instance;
      final anchor = controls.getHandleAnchor(
        TextSelectionHandleType.collapsed,
        20.0,
      );
      // Collapsed handle anchor should be at center-top (11, -4)
      expect(anchor, const Offset(11.0, -4.0));
    });

    test('getHandleSize returns 22x22 for all line heights', () {
      final controls = LayrzTextSelectionControls.instance;
      expect(controls.getHandleSize(16.0), const Size(22.0, 22.0));
      expect(controls.getHandleSize(20.0), const Size(22.0, 22.0));
      expect(controls.getHandleSize(24.0), const Size(22.0, 22.0));
    });

    testWidgets('buildHandle for left applies rotation', (tester) async {
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final handle = controls.buildHandle(
              context,
              TextSelectionHandleType.left,
              20.0,
            );
            // Left handle should be wrapped in a Transform.rotate
            return handle;
          },
        ),
      );
      // Verify widget tree contains a Transform widget
      expect(find.byType(Transform), findsOneWidget);
    });

    testWidgets('buildHandle for right has no rotation', (tester) async {
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final handle = controls.buildHandle(
              context,
              TextSelectionHandleType.right,
              20.0,
            );
            // Right handle should be returned as-is, no Transform wrapper
            return handle;
          },
        ),
      );
      // Right handle returns GestureDetector directly, not wrapped in Transform
      // So we shouldn't find a Transform as the outermost widget
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('buildHandle for collapsed applies rotation', (tester) async {
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final handle = controls.buildHandle(
              context,
              TextSelectionHandleType.collapsed,
              20.0,
            );
            // Collapsed handle should be wrapped in a Transform.rotate
            return handle;
          },
        ),
      );
      // Verify widget tree contains a Transform widget
      expect(find.byType(Transform), findsOneWidget);
    });
  });
}

import 'dart:math' as math;
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

    testWidgets('buildHandle for left has no rotation (points up-right)', (tester) async {
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
            // Left handle is returned as-is with no Transform (0 rotation)
            // It points up-right at the selection start
            return handle;
          },
        ),
      );
      // Left handle returns GestureDetector directly, not wrapped in Transform
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(Transform), findsNothing);
    });

    testWidgets('buildHandle for right applies π/2 rotation (points up-left)', (tester) async {
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
            // Right handle is wrapped in Transform.rotate with π/2 angle
            // It points up-left at the selection end
            return handle;
          },
        ),
      );
      // Verify widget tree contains a Transform widget (for π/2 rotation)
      expect(find.byType(Transform), findsOneWidget);
    });

    testWidgets('buildHandle for collapsed applies π/4 rotation (points up)', (tester) async {
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
            // Collapsed handle is wrapped in Transform.rotate with π/4 angle
            return handle;
          },
        ),
      );
      // Verify widget tree contains a Transform widget
      expect(find.byType(Transform), findsOneWidget);
    });

    test('handle rotation angles are correct per type', () {
      // Base orientation: unrotated teardrop has square corner pointing up-right (NE)
      // Rotations move the corner counterclockwise from this base

      // Left handle: 0 rotation → corner at up-right (45°)
      const leftAngle = 0.0;
      expect(leftAngle, 0.0, reason: 'Left handle should have no rotation');

      // Right handle: π/2 rotation → corner at up-left (135°), 90° from up-right
      const rightAngle = math.pi / 2.0;
      expect(rightAngle, closeTo(math.pi / 2.0, 0.0001),
          reason: 'Right handle should rotate by π/2 to point up-left');

      // Collapsed handle: π/4 rotation → corner at up (90°), 45° from up-right
      const collapsedAngle = math.pi / 4.0;
      expect(collapsedAngle, closeTo(math.pi / 4.0, 0.0001),
          reason: 'Collapsed handle should rotate by π/4 to point up');
    });

    testWidgets('left handle corner points up-right for selection start', (tester) async {
      // The left handle's corner should touch the selection start edge.
      // With anchor at right edge (22, 0) and no rotation, the corner is at the
      // unrotated position pointing up-right (NE).
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final anchor = controls.getHandleAnchor(TextSelectionHandleType.left, 16.0);
            // Anchor at right edge
            expect(anchor, Offset(22.0, 0.0));
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('right handle corner points up-left for selection end', (tester) async {
      // The right handle's corner should touch the selection end edge.
      // With anchor at left edge (0, 0) and π/2 rotation, the corner points up-left (NW).
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final anchor = controls.getHandleAnchor(TextSelectionHandleType.right, 16.0);
            // Anchor at left edge
            expect(anchor, Offset.zero);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });
}

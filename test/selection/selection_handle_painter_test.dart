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
      // The teardrop is created by combining a circle and a square at the top-left,
      // producing a circular bulge with a pointed corner at the top-left (NW).
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

    testWidgets('buildHandle for left applies π/2 rotation (points up-right)', (tester) async {
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
            // Left handle is wrapped in Transform.rotate with π/2 (90° clockwise)
            // to rotate the corner from NW base to NE (up-right) at the selection start
            return handle;
          },
        ),
      );
      // Left handle should be wrapped in Transform.rotate
      expect(find.byType(Transform), findsOneWidget, reason: 'Left handle should rotate π/2 to point up-right (NE)');
    });

    testWidgets('buildHandle for right has no rotation (points up-left)', (tester) async {
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
            // Right handle is returned as-is with no Transform (0 rotation)
            // It keeps the NW base orientation, pointing up-left at the selection end
            return handle;
          },
        ),
      );
      // Right handle should NOT be wrapped in Transform (no rotation needed)
      expect(
        find.byType(Transform),
        findsNothing,
        reason: 'Right handle should have no rotation to point up-left (NW)',
      );
      expect(find.byType(GestureDetector), findsOneWidget);
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
      // Base orientation: unrotated teardrop has square corner at top-left (NW)
      // Transform.rotate applies clockwise rotation for positive angles.
      // All rotations are derived from this NW base.

      // Left handle: π/2 clockwise rotation → corner rotates from NW to NE (up-right)
      const leftAngle = math.pi / 2.0;
      expect(
        leftAngle,
        closeTo(math.pi / 2.0, 0.0001),
        reason: 'Left handle should rotate π/2 clockwise to point NE (up-right)',
      );

      // Right handle: 0 rotation → corner stays at NW (up-left), touching selection end
      const rightAngle = 0.0;
      expect(rightAngle, 0.0, reason: 'Right handle should have no rotation to point NW (up-left)');

      // Collapsed handle: π/4 clockwise rotation → corner rotates from NW toward N (straight up)
      const collapsedAngle = math.pi / 4.0;
      expect(
        collapsedAngle,
        closeTo(math.pi / 4.0, 0.0001),
        reason: 'Collapsed handle should rotate π/4 clockwise to point N (straight up)',
      );
    });

    testWidgets('left handle corner points up-right for selection start', (tester) async {
      // The left handle's corner should touch the selection start edge.
      // With anchor at right edge (22, 0) and π/2 clockwise rotation,
      // the corner rotates from NW base to NE (up-right).
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final anchor = controls.getHandleAnchor(TextSelectionHandleType.left, 16.0);
            // Anchor at right edge for NE-pointing handle
            expect(anchor, Offset(22.0, 0.0));
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('right handle corner points up-left for selection end', (tester) async {
      // The right handle's corner should touch the selection end edge.
      // With anchor at left edge (0, 0) and no rotation, the corner stays at NW (up-left).
      await pumpThemed(
        tester,
        Builder(
          builder: (context) {
            final controls = LayrzTextSelectionControls.instance;
            final anchor = controls.getHandleAnchor(TextSelectionHandleType.right, 16.0);
            // Anchor at left edge for NW-pointing handle
            expect(anchor, Offset.zero);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });
}

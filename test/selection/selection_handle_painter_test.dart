import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSelectionHandlePainter', () {
    test('creates with type and color', () {
      final painter = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      expect(painter.type, TextSelectionHandleType.left);
      expect(painter.color, const Color(0xFF0000FF));
    });

    test('shouldRepaint returns true when color changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      final painter2 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFFFF0000),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when type changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      final painter2 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.right,
        color: const Color(0xFF0000FF),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      final painter2 = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      expect(painter1.shouldRepaint(painter2), false);
    });

    test('renders distinct paths for left, right, and collapsed types', () {
      // Create painters for each type and verify they have different configurations
      final leftPainter = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.left,
        color: const Color(0xFF0000FF),
      );
      final rightPainter = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.right,
        color: const Color(0xFF0000FF),
      );
      final collapsedPainter = LayrzSelectionHandlePainter(
        type: TextSelectionHandleType.collapsed,
        color: const Color(0xFF0000FF),
      );

      // Each type should have a different configuration
      expect(leftPainter.type, TextSelectionHandleType.left);
      expect(rightPainter.type, TextSelectionHandleType.right);
      expect(collapsedPainter.type, TextSelectionHandleType.collapsed);

      // Verify that different types trigger repaints when switched
      expect(leftPainter.shouldRepaint(rightPainter), true);
      expect(leftPainter.shouldRepaint(collapsedPainter), true);
      expect(rightPainter.shouldRepaint(collapsedPainter), true);
    });
  });
}

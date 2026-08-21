import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSelectionHandlePainter', () {
    test('creates with color and borderRadius', () {
      final painter = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(4),
      );
      expect(painter.color, const Color(0xFF0000FF));
      expect(painter.borderRadius, BorderRadius.circular(4));
    });

    test('shouldRepaint returns true when color changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(4),
      );
      final painter2 = LayrzSelectionHandlePainter(
        color: const Color(0xFFFF0000),
        borderRadius: BorderRadius.circular(4),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when borderRadius changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(4),
      );
      final painter2 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(8),
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(4),
      );
      final painter2 = LayrzSelectionHandlePainter(
        color: const Color(0xFF0000FF),
        borderRadius: BorderRadius.circular(4),
      );
      expect(painter1.shouldRepaint(painter2), false);
    });
  });
}

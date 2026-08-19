import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/inputs/src/dashed_border_painter.dart';

void main() {
  group('DashedBorderPainter', () {
    test('creates with correct properties', () {
      final painter = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        borderRadius: BorderRadius.circular(8),
      );

      expect(painter.color, const Color(0xFF000000));
      expect(painter.strokeWidth, 2.0);
      expect(painter.dashLength, 4.0);
      expect(painter.gapLength, 4.0);
    });

    test('custom dash and gap lengths', () {
      final painter = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(10),
        dashLength: 6.0,
        gapLength: 3.0,
      );

      expect(painter.dashLength, 6.0);
      expect(painter.gapLength, 3.0);
    });

    test('shouldRepaint returns true when color changes', () {
      final painter1 = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(8),
      );

      final painter2 = DashedBorderPainter(
        color: const Color(0xFFFFFFFF),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(8),
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when strokeWidth changes', () {
      final painter1 = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(8),
      );

      final painter2 = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
        borderRadius: BorderRadius.circular(8),
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when properties same', () {
      final painter1 = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(8),
      );

      final painter2 = DashedBorderPainter(
        color: const Color(0xFF000000),
        strokeWidth: 1.5,
        borderRadius: BorderRadius.circular(8),
      );

      expect(painter1.shouldRepaint(painter2), false);
    });
  });
}

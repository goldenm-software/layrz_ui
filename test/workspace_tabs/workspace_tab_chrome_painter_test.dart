import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzWorkspaceTabChromePainter — shouldRepaint', () {
    test('returns false when every field is identical', () {
      const a = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        shoulderRadius: 4.0,
      );
      const b = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        shoulderRadius: 4.0,
      );

      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when fillColor differs', () {
      const a = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0);
      const b = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFF000000), topRadius: 8.0);

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when topRadius differs', () {
      const a = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0);
      const b = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 4.0);

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when shoulderRadius differs', () {
      const a = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0, shoulderRadius: 0.0);
      const b = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0, shoulderRadius: 4.0);

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when borderColor differs', () {
      const a = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0);
      const b = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        borderColor: Color(0xFF000000),
      );

      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when borderWidth differs', () {
      const a = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        borderColor: Color(0xFF000000),
        borderWidth: 1.0,
      );
      const b = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        borderColor: Color(0xFF000000),
        borderWidth: 2.0,
      );

      expect(a.shouldRepaint(b), isTrue);
    });
  });

  group('LayrzWorkspaceTabChromePainter — paint', () {
    test('paints without throwing at a typical tab size, with and without a border', () {
      const withoutBorder = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        shoulderRadius: 0.0,
      );
      const withBorder = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 8.0,
        shoulderRadius: 4.0,
        borderColor: Color(0xFF000000),
        borderWidth: 2.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(160.0, 40.0);

      expect(() => withoutBorder.paint(canvas, size), returnsNormally);
      expect(() => withBorder.paint(canvas, size), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('handles a radius larger than the available size without throwing', () {
      const painter = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: 999.0,
        shoulderRadius: 999.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, const Size(20.0, 10.0)), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('handles a zero-size canvas without throwing', () {
      const painter = LayrzWorkspaceTabChromePainter(fillColor: Color(0xFFFFFFFF), topRadius: 8.0);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, Size.zero), returnsNormally);

      recorder.endRecording().dispose();
    });

    test('the closed shape contains its own interior and excludes points outside the shoulder flare', () {
      const width = 160.0;
      const height = 40.0;
      const topRadius = 8.0;
      const shoulderRadius = 6.0;
      const painter = LayrzWorkspaceTabChromePainter(
        fillColor: Color(0xFFFFFFFF),
        topRadius: topRadius,
        shoulderRadius: shoulderRadius,
      );

      final path = buildWorkspaceTabBumpPath(
        width: width,
        height: height,
        topRadius: topRadius,
        shoulderRadius: shoulderRadius,
      )..close();

      // The painter's own paint() builds this same closed path internally;
      // reconstructing it here via the shared, exported
      // `buildWorkspaceTabBumpPath` function (rather than reaching into a
      // private field) is exactly how `LayrzWorkspaceTabChromePainter`
      // itself builds its shape, so this asserts the real, public contract.
      expect(path.contains(const Offset(width / 2, height / 2)), isTrue, reason: 'tab interior');
      expect(path.contains(const Offset(-shoulderRadius - 1, height - 1)), isFalse, reason: 'left shoulder cutout');
      expect(
        path.contains(const Offset(width + shoulderRadius + 1, height - 1)),
        isFalse,
        reason: 'right shoulder cutout',
      );

      // painter.paint() must not throw building the equivalent shape.
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(width, height)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}

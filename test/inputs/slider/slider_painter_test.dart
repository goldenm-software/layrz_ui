import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayrzSliderPainter', () {
    const baseColors = (
      trackColor: Color(0xFFE0E0E0),
      activeTrackColor: Color(0xFF3366FF),
      thumbColor: Color(0xFF3366FF),
      thumbBorderColor: Color(0xFFFFFFFF),
    );

    LayrzSliderPainter buildPainter({double fraction = 0.5}) {
      return LayrzSliderPainter(
        fraction: fraction,
        trackThickness: 4.0,
        thumbRadius: 8.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
      );
    }

    test('creates with the given geometry and colours', () {
      final painter = buildPainter(fraction: 0.25);
      expect(painter.fraction, 0.25);
      expect(painter.trackThickness, 4.0);
      expect(painter.thumbRadius, 8.0);
      expect(painter.thumbBorderWidth, 2.0);
      expect(painter.trackColor, baseColors.trackColor);
      expect(painter.activeTrackColor, baseColors.activeTrackColor);
      expect(painter.thumbColor, baseColors.thumbColor);
      expect(painter.thumbBorderColor, baseColors.thumbBorderColor);
    });

    test('paint completes without error at fraction 0.0 (thumb at start)', () {
      final painter = buildPainter(fraction: 0.0);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(200, 20)), returnsNormally);
      recorder.endRecording();
    });

    test('paint completes without error at fraction 1.0 (thumb at end)', () {
      final painter = buildPainter(fraction: 1.0);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(200, 20)), returnsNormally);
      recorder.endRecording();
    });

    test('paint completes without error at fraction 0.5 (thumb centered)', () {
      final painter = buildPainter(fraction: 0.5);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(200, 20)), returnsNormally);
      recorder.endRecording();
    });

    test('paint completes without error when thumbBorderWidth is zero', () {
      final painter = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbRadius: 8.0,
        thumbBorderWidth: 0.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(200, 20)), returnsNormally);
      recorder.endRecording();
    });

    test('paint completes without error on a degenerate zero-width size', () {
      final painter = buildPainter(fraction: 0.5);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      recorder.endRecording();
    });

    test('shouldRepaint returns true when fraction changes', () {
      final a = buildPainter(fraction: 0.2);
      final b = buildPainter(fraction: 0.8);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when trackColor changes', () {
      final a = buildPainter();
      final b = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbRadius: 8.0,
        thumbBorderWidth: 2.0,
        trackColor: const Color(0xFF000000),
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when thumbRadius changes', () {
      final a = buildPainter();
      final b = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbRadius: 10.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final a = buildPainter();
      final b = buildPainter();
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}

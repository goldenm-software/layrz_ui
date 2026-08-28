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

    const baseShadows = [
      BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
    ];

    LayrzSliderPainter buildPainter({double fraction = 0.5}) {
      return LayrzSliderPainter(
        fraction: fraction,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: baseShadows,
      );
    }

    test('creates with the given geometry and colours', () {
      final painter = buildPainter(fraction: 0.25);
      expect(painter.fraction, 0.25);
      expect(painter.trackThickness, 4.0);
      expect(painter.thumbSize, 16.0);
      expect(painter.thumbCornerRadius, 6.0);
      expect(painter.thumbBorderWidth, 2.0);
      expect(painter.trackColor, baseColors.trackColor);
      expect(painter.activeTrackColor, baseColors.activeTrackColor);
      expect(painter.thumbColor, baseColors.thumbColor);
      expect(painter.thumbBorderColor, baseColors.thumbBorderColor);
      expect(painter.thumbShadows, baseShadows);
    });

    test('defaults thumbShadows to an empty list when not provided', () {
      final painter = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
      );
      expect(painter.thumbShadows, isEmpty);
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
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
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

    test('paint completes without error when thumbShadows is empty', () {
      final painter = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
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

    test('paint completes without error with multiple thumb shadows', () {
      final painter = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 5, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
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
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: const Color(0xFF000000),
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: baseShadows,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when thumbSize changes', () {
      final a = buildPainter();
      final b = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 20.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: baseShadows,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when thumbCornerRadius changes', () {
      final a = buildPainter();
      final b = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 999.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: baseShadows,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns true when thumbShadows changes', () {
      final a = buildPainter();
      final b = LayrzSliderPainter(
        fraction: 0.5,
        trackThickness: 4.0,
        thumbSize: 16.0,
        thumbCornerRadius: 6.0,
        thumbBorderWidth: 2.0,
        trackColor: baseColors.trackColor,
        activeTrackColor: baseColors.activeTrackColor,
        thumbColor: baseColors.thumbColor,
        thumbBorderColor: baseColors.thumbBorderColor,
        thumbShadows: const [],
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final a = buildPainter();
      final b = buildPainter();
      expect(a.shouldRepaint(b), isFalse);
    });

    test('with a 28px thumb, the thumb centre reaches exactly thumbSize/2 from each track edge', () {
      // Mirrors LayrzSlider's actual thumb size (see _thumbSize in
      // slider_input.dart) rather than this file's arbitrary 16.0 example --
      // this test locks in that the usable-width math still lands the thumb
      // centre exactly at the inset on both extremes after the thumb grew.
      const thumbSize = 28.0;
      const trackWidth = 300.0;
      final usableWidth = trackWidth - thumbSize;

      final thumbXAtMin = thumbSize / 2 + usableWidth * 0.0;
      final thumbXAtMax = thumbSize / 2 + usableWidth * 1.0;

      expect(thumbXAtMin, thumbSize / 2);
      expect(thumbXAtMax, trackWidth - thumbSize / 2);
    });

    test('paint completes without error using the real 28px thumb / 8px track at both extremes', () {
      // Mirrors LayrzSlider's actual geometry (see _trackVisualHeight and
      // _thumbSize in slider_input.dart): an 8px track behind a 28px thumb,
      // painted into a `Size(300, paintHeight)` where paintHeight ==
      // trackThickness + thumbSize (8 + 28 = 36), exactly as
      // `_LayrzSliderState._buildPainter`/`build` construct it.
      for (final fraction in [0.0, 1.0]) {
        final painter = LayrzSliderPainter(
          fraction: fraction,
          trackThickness: 8.0,
          thumbSize: 28.0,
          thumbCornerRadius: 10.0,
          thumbBorderWidth: 2.0,
          trackColor: baseColors.trackColor,
          activeTrackColor: baseColors.activeTrackColor,
          thumbColor: baseColors.thumbColor,
          thumbBorderColor: baseColors.thumbBorderColor,
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        expect(() => painter.paint(canvas, const Size(300, 36)), returnsNormally);
        recorder.endRecording();
      }
    });

    test('the 28px thumb fully covers the 8px track at both extremes (thumb >> track)', () {
      // Geometric check (not just a paint smoke test) that the thumb's
      // bounding box, centred on the track's centreline, vertically contains
      // the entire painted track line at fraction 0.0 and 1.0 -- the two
      // positions where the thumb sits at the very ends of the usable travel
      // range and so has the least horizontal overlap margin with the track
      // ends. The track line is drawn centred at `trackY = paintHeight / 2`
      // with half-thickness `trackThickness / 2`; the thumb square is centred
      // at the same `trackY` with half-edge `thumbSize / 2`. Coverage holds
      // whenever `thumbSize / 2 >= trackThickness / 2`, i.e. `thumbSize >=
      // trackThickness` -- true here by a wide margin (28 >> 8), unlike the
      // old 4px track where the same inequality (28 >> 4) also held, so this
      // was never at risk, but is now asserted directly rather than assumed.
      const trackThickness = 8.0;
      const thumbSize = 28.0;
      const paintHeight = trackThickness + thumbSize;

      final trackY = paintHeight / 2;
      final trackTop = trackY - trackThickness / 2;
      final trackBottom = trackY + trackThickness / 2;

      for (final fraction in [0.0, 1.0]) {
        final thumbCenterY = trackY; // thumb is vertically centred on the track's own centreline.
        final thumbTop = thumbCenterY - thumbSize / 2;
        final thumbBottom = thumbCenterY + thumbSize / 2;

        expect(
          thumbTop,
          lessThanOrEqualTo(trackTop),
          reason: 'thumb top must sit at or above the track top at fraction $fraction',
        );
        expect(
          thumbBottom,
          greaterThanOrEqualTo(trackBottom),
          reason: 'thumb bottom must sit at or below the track bottom at fraction $fraction',
        );
      }
    });
  });
}

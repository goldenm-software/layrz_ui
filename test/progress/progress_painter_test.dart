import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/progress/progress.dart';

// Most tests below assert only that painting does not throw and that
// shouldRepaint reacts to shape-specific fields, matching the
// "renders without throwing" convention already used for the linear-mode
// tests in this file. A few tests need to distinguish an actual `drawCircle`
// call from a full-turn `drawArc` call (see the DESIGN-88 ring-seam fix) —
// those use flutter_test's `paints` matcher, which inspects the recorded
// canvas calls directly instead of just checking that a Picture came out.

void main() {
  group('LayrzProgressPainter', () {
    const trackColor = Color(0xFFEEEEEE);
    const indicatorColor = Color(0xFF112233);

    test('shouldRepaint returns true when determinateValue changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.2,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when sweepPosition changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.1,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.4,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when sweepWidthFraction changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.1,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.1,
        sweepWidthFraction: 0.5,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when trackColor changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: Color(0xFF000000),
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when indicatorColor changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: Color(0xFFFFFFFF),
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when borderRadius changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 8.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isFalse);
    });

    test('paint fills a full bar at determinateValue 1.0 without throwing', () {
      const painter = LayrzProgressPainter(
        determinateValue: 1.0,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 8));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('paint draws nothing extra for determinateValue 0.0 without throwing', () {
      const painter = LayrzProgressPainter(
        determinateValue: 0.0,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 8));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('paint draws an indeterminate sweep at the oscillation midpoint without throwing', () {
      const painter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.5,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(200, 8));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('paint draws an indeterminate sweep at each end of the oscillation without throwing', () {
      const startPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const endPainter = LayrzProgressPainter(
        determinateValue: null,
        sweepPosition: 1.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      startPainter.paint(canvas, const Size(200, 8));
      endPainter.paint(canvas, const Size(200, 8));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('shouldRepaint returns true when shape changes', () {
      const oldPainter = LayrzProgressPainter(
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('shouldRepaint returns true when strokeWidth changes', () {
      const oldPainter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );
      const newPainter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 6.0,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('circular paint draws a full ring at determinateValue 1.0 without throwing', () {
      const painter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 1.0,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(50, 50));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('circular track is painted as a closed circle, not a full-turn arc', () {
      // Regression test for the "2000's game" render artifact: a 360-degree
      // drawArc retains a start/end point even at a full sweep, and a round
      // stroke cap there produces an overlapping lump where the ring
      // "closes". drawCircle has no endpoints, so it is the only shape that
      // closes cleanly. Asserting `circle(...)` here fails if the track ever
      // regresses back to a full-turn `arc(...)`.
      const painter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, const Size(50, 50)),
        paints
          ..circle(x: 25, y: 25, radius: 23, color: trackColor, style: PaintingStyle.stroke, strokeWidth: 4.0)
          ..arc(color: indicatorColor, style: PaintingStyle.stroke, strokeWidth: 4.0, strokeCap: StrokeCap.round),
      );
    });

    test('circular indicator arc keeps a round stroke cap', () {
      // Unlike the track, the indicator is a genuine partial arc with real
      // visible ends, so StrokeCap.round is correct and must not be removed —
      // it is what gives the ring its modern rounded tips.
      const painter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.25,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      expect(
        (Canvas canvas) => painter.paint(canvas, const Size(50, 50)),
        paints..arc(
          rect: const Rect.fromLTRB(2, 2, 48, 48),
          startAngle: -math.pi / 2,
          sweepAngle: math.pi / 2,
          strokeCap: StrokeCap.round,
        ),
      );
    });

    test('circular paint draws nothing extra for determinateValue 0.0 without throwing', () {
      const painter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.0,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(50, 50));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('circular paint draws a rotating indeterminate arc without throwing', () {
      const midPainter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: null,
        sweepPosition: 0.5,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );
      const wrapPainter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: null,
        sweepPosition: 0.95,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      midPainter.paint(canvas, const Size(50, 50));
      wrapPainter.paint(canvas, const Size(50, 50));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('circular paint handles a non-square size by using the smaller dimension', () {
      const painter = LayrzProgressPainter(
        shape: LayrzProgressFormat.circular,
        determinateValue: 0.5,
        sweepPosition: 0.0,
        sweepWidthFraction: 0.3,
        trackColor: trackColor,
        indicatorColor: indicatorColor,
        borderRadius: 4.0,
        strokeWidth: 4.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(80, 50));
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });
  });
}

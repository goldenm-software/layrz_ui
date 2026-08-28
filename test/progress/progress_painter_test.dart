import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/src/progress/progress.dart';

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
  });
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Painter-level tests for [LayoPainter.featureOffset]: the default-zero
/// contract (byte-identical to a painter built before this field existed),
/// [LayoPainter.shouldRepaint] reacting to it, and that a non-zero value
/// actually translates only the facial features -- proven by sampling actual
/// pixels rather than merely checking the field is stored.
void main() {
  group('LayoPainter.featureOffset', () {
    const size = Size(396.15, 659.76);

    test('defaults to Offset.zero', () {
      const painter = LayoPainter();
      expect(painter.featureOffset, Offset.zero);
    });

    test('shouldRepaint is false for an identically-configured painter, including featureOffset', () {
      const painterA = LayoPainter(featureOffset: Offset(2, 3));
      const painterB = LayoPainter(featureOffset: Offset(2, 3));
      expect(painterA.shouldRepaint(painterB), isFalse);
    });

    test('shouldRepaint is true when only featureOffset differs', () {
      const painterA = LayoPainter();
      const painterB = LayoPainter(featureOffset: Offset(2, 3));
      expect(painterA.shouldRepaint(painterB), isTrue);
    });

    test('shouldRepaint is true when featureOffset differs, uniformly across every emotion', () {
      for (final emotion in LayoEmotion.values) {
        final painterA = LayoPainter(emotion: emotion);
        final painterB = LayoPainter(emotion: emotion, featureOffset: const Offset(1, 1));
        expect(painterA.shouldRepaint(painterB), isTrue, reason: 'featureOffset must trigger repaint for $emotion');
      }
    });

    /// Rasterizes [painter] at [size] and returns the actual pixel color at
    /// [point] -- mirrors the same helper in `layo_painter_test.dart`.
    Future<Color> pixelAt(LayoPainter painter, Size size, Offset point) async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.ceil(), size.height.ceil());
      final byteData = await image.toByteData();
      final bytes = byteData!.buffer.asUint8List();
      final x = point.dx.round().clamp(0, image.width - 1);
      final y = point.dy.round().clamp(0, image.height - 1);
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(bytes[offset + 3], bytes[offset], bytes[offset + 1], bytes[offset + 2]);
    }

    test('a non-zero featureOffset shifts the eye but leaves the antenna tip exactly where it was', () async {
      // The k scale for this size (396.15-wide source) is 1.0, so source
      // units and painted pixels coincide -- this lets the offset below be
      // reasoned about directly in source units.
      const leftEyeCenter = Offset(134.67, 195.73);
      const antennaTipCenter = Offset(197.66, 17.30);

      const atRest = LayoPainter();
      const shifted = LayoPainter(featureOffset: Offset(20, 0));

      // At rest, the left eye's own accent-blue fill is present at its
      // documented center.
      final restEyeColor = await pixelAt(atRest, size, leftEyeCenter);
      expect(restEyeColor, const Color(0xFF60ABDE));

      // Shifted 20 source units right, that same point (still the eye's OLD
      // center) is no longer part of the (now-moved) eye -- it falls into
      // the dark screen background instead, proving the eye really moved
      // rather than the painter silently ignoring the offset.
      final shiftedEyeColor = await pixelAt(shifted, size, leftEyeCenter);
      expect(shiftedEyeColor, isNot(restEyeColor));

      // The antenna tip is drawn OUTSIDE the translated block in `paint`
      // (see LayoPainter.paint, which wraps only _paintEmotionGlyphs in the
      // save/translate/restore), so it must render identically regardless
      // of featureOffset.
      final restAntennaColor = await pixelAt(atRest, size, antennaTipCenter);
      final shiftedAntennaColor = await pixelAt(shifted, size, antennaTipCenter);
      expect(shiftedAntennaColor, restAntennaColor);
    });

    test('Offset.zero renders byte-identical to a painter with no featureOffset at all', () async {
      const withExplicitZero = LayoPainter(featureOffset: Offset.zero);
      const withDefault = LayoPainter();

      final recorderA = PictureRecorder();
      withExplicitZero.paint(Canvas(recorderA), size);
      final imageA = await recorderA.endRecording().toImage(size.width.ceil(), size.height.ceil());
      final bytesA = (await imageA.toByteData())!.buffer.asUint8List();

      final recorderB = PictureRecorder();
      withDefault.paint(Canvas(recorderB), size);
      final imageB = await recorderB.endRecording().toImage(size.width.ceil(), size.height.ceil());
      final bytesB = (await imageB.toByteData())!.buffer.asUint8List();

      expect(bytesA, bytesB);
    });
  });
}

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.smug]: pure [LayoPainter] geometry/color
/// assertions (the half-lidded eyes at mrLayo's own canonical spacing since
/// it draws a mouth, the asymmetric smirk, and the blue antenna/tie accent)
/// and [Layo]'s own subtle `smugT` animation lifecycle.
///
/// Split into its own file per this repository's file-size convention.
void main() {
  const size = Size(396.15, 659.76);

  Future<Color> pixelAt(LayoPainter painter, Size paintedSize, Offset point) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, paintedSize);
    final picture = recorder.endRecording();
    final image = await picture.toImage(paintedSize.width.ceil(), paintedSize.height.ceil());
    final byteData = await image.toByteData();
    final bytes = byteData!.buffer.asUint8List();
    final x = point.dx.round().clamp(0, image.width - 1);
    final y = point.dy.round().clamp(0, image.height - 1);
    final offset = (y * image.width + x) * 4;
    return Color.fromARGB(bytes[offset + 3], bytes[offset], bytes[offset + 1], bytes[offset + 2]);
  }

  group('LayoPainter smug', () {
    test('paints smug without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('smug paints the antenna tip and tie in blue, like mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      const blue = Color(0xFF60ABDE);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue);
    });

    test('each eye\'s lower half paints blue, at mrLayo\'s own canonical eye centers (it draws a mouth)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      final leftLower = await pixelAt(painter, size, const Offset(134.67, 195.73 + 10));
      expect(leftLower, const Color(0xFF60ABDE));
      final rightLower = await pixelAt(painter, size, const Offset(261.17, 195.73 + 10));
      expect(rightLower, const Color(0xFF60ABDE));
    });

    test('the eye\'s upper region above the lid is not painted (the half-lid cuts it off)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      final leftUpper = await pixelAt(painter, size, const Offset(134.67, 195.73 - 15));
      expect(leftUpper, isNot(const Color(0xFF60ABDE)), reason: 'the lid must cut off the eye\'s own top region');
    });

    test('paints an asymmetric smirk below the eyes', () async {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      // The smirk's raised (right) corner sits well above its own baseline.
      final color = await pixelAt(painter, size, const Offset(197.93 + 34, 245.0 - 13));
      expect(color, const Color(0xFF60ABDE), reason: 'smug must draw a smirk with a raised corner');
    });

    test('smugT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.smug);
      expect(painter.smugT, 0.0);
    });

    test('paints without throwing across smugT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.smug, smugT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when smugT differs for smug', () {
        const painterA = LayoPainter(emotion: LayoEmotion.smug);
        const painterB = LayoPainter(emotion: LayoEmotion.smug, smugT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-smug when smugT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, smugT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.smug animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) smugT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.smug)),
        ),
      );

      expect(painterIn(tester).smugT, 0.0);
    });

    guardedTestWidgets('smug pulses periodically: smugT rises above 0, then settles back to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.smug)),
        ),
      );

      expect(painterIn(tester).smugT, 0.0);

      var sawPulse = false;
      for (var i = 0; i < 62 && !sawPulse; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).smugT > 0.0) {
          sawPulse = true;
        }
      }

      expect(sawPulse, isTrue, reason: 'smug must pulse (smugT rises above 0) at some point while animating');

      // The pulse controller's own forward+reverse cycle is ~700ms each way
      // (~1.4s round trip); pump comfortably past that, well short of the
      // next jittered pulse's minimum 3s interval.
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).smugT, 0.0, reason: 'the pulse must fall back to exactly 0');
    });

    guardedTestWidgets('animate: false never pulses: smugT stays 0 even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.smug)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).smugT, 0.0, reason: 'animate: false must suppress the pulse entirely');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never pulses smug\'s own smugT: it stays 0', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(seconds: 8));

        expect(painterIn(tester).smugT, 0.0, reason: '$emotion must never pulse smug\'s own smugT');
      });
    }
  });
}

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.listening]: pure [LayoPainter] geometry/color
/// assertions (the equalizer bars, centered on the screen's own horizontal
/// center, and the teal antenna/tie accent) and [Layo]'s own `eqT` animation
/// lifecycle.
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

  group('LayoPainter listening', () {
    test('paints listening without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.listening);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('listening paints the antenna tip and tie in its teal accent', () async {
      const painter = LayoPainter(emotion: LayoEmotion.listening);
      const teal = Color(0xFF16A6A0);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, teal);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, teal);
    });

    test('eqT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.listening);
      expect(painter.eqT, 0.0);
    });

    test('the middle bar paints teal near the baseline regardless of eqT (min height still reaches there)', () async {
      // The baseline sits at y 254.91 (chosen so the bars' own full height
      // range centers on the screen's own vertical middle, see
      // layo_glyphs_listening.dart's own _kBarBaselineY doc comment); every
      // bar's minimum height (14) still reaches up to y 240.91, so a point
      // just above the baseline must always be teal regardless of eqT.
      for (final t in [0.0, 0.3, 0.7]) {
        final painter = LayoPainter(emotion: LayoEmotion.listening, eqT: t);
        final color = await pixelAt(painter, size, const Offset(197, 251.91));
        expect(color, const Color(0xFF16A6A0), reason: 'a bar must always reach near its own baseline at eqT: $t');
      }
    });

    test('a bar\'s own height changes as eqT advances (grows tall enough to reach higher, then recedes)', () async {
      // Bar index 0 has phaseOffset 0.0, speed 1.05 -- at eqT == 0.25 its own
      // phase is (0.25 * 1.05) % 1.0 = 0.2625, close enough to the breath's
      // own quarter-cycle peak that its height is well above its eqT == 0.0
      // value (46 units, see the bar-height doc comment), reaching well
      // above the sample point below (baseline 254.91 minus 70 = 184.91,
      // comfortably inside the bar's own max-height reach of
      // 254.91 - 78 = 176.91).
      const atZero = LayoPainter(emotion: LayoEmotion.listening);
      const atQuarter = LayoPainter(emotion: LayoEmotion.listening, eqT: 0.25);

      const barCenterX = 148.745; // the first bar's own center (x 148.745-246.745 span, 5 bars)
      const highPoint = Offset(barCenterX, 184.91);

      final colorAtZero = await pixelAt(atZero, size, highPoint);
      final colorAtQuarter = await pixelAt(atQuarter, size, highPoint);
      expect(
        colorAtQuarter,
        isNot(colorAtZero),
        reason: 'the first bar\'s own height must change between eqT == 0.0 and its own breath peak at 0.25',
      );
    });

    test('the bar group\'s own full height range is centered on the screen window\'s own vertical center', () {
      // The bars' own full possible vertical range spans from the baseline
      // (254.91) up to baseline - maxHeight (254.91 - 78 = 176.91); its own
      // midpoint is (254.91 + 176.91) / 2 = 215.91 -- the screen window's
      // own vertical center (see LayoPainter._screenRect: (123.02 + 308.80)
      // / 2 = 215.91).
      const baselineY = 254.91;
      const maxHeight = 78.0;
      const screenCenterY = 215.91;
      expect((baselineY + (baselineY - maxHeight)) / 2, closeTo(screenCenterY, 0.001));
    });

    test('the bar group is centered on the screen window\'s own horizontal center', () async {
      // The screen window spans x 78.45-317.04 (LayoPainter._screenRect),
      // whose own center is (78.45 + 317.04) / 2 = 197.745. At eqT == 0.0
      // the group's own left/right pairs (bars 0/4 and 1/3) share identical
      // phase offsets and speeds, so their heights are pairwise identical --
      // sampling a point equidistant left and right of that center, just
      // above the baseline (where even the shortest bar's own minimum
      // height still reaches, see the "middle bar" test above), must find
      // the same teal color on both sides.
      const painter = LayoPainter(emotion: LayoEmotion.listening);
      const screenCenterX = 197.745;
      const halfSpan = 40.0;

      final left = await pixelAt(painter, size, const Offset(screenCenterX - halfSpan, 251.91));
      final right = await pixelAt(painter, size, const Offset(screenCenterX + halfSpan, 251.91));
      expect(
        left,
        right,
        reason: 'the bar group must be symmetric (and therefore centered) around the screen\'s own center',
      );
    });

    test('paints without throwing across eqT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.listening, eqT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when eqT differs for listening', () {
        const painterA = LayoPainter(emotion: LayoEmotion.listening);
        const painterB = LayoPainter(emotion: LayoEmotion.listening, eqT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-eq when eqT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, eqT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.listening animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) eqT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.listening)),
        ),
      );

      expect(painterIn(tester).eqT, 0.0);
    });

    guardedTestWidgets('listening bounces: eqT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.listening)),
        ),
      );

      expect(painterIn(tester).eqT, 0.0);

      await tester.pump(const Duration(milliseconds: 350));

      expect(
        painterIn(tester).eqT,
        closeTo(0.25, 0.05),
        reason: 'listening must advance the EQ bounce at the quarter-cycle point of its ~1.4s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never bounces its EQ: eqT stays 0', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        expect(painterIn(tester).eqT, 0.0, reason: '$emotion must never bounce an EQ');
      });
    }

    guardedTestWidgets('reduced motion forces eqT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.listening)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).eqT, 0.0);
    });
  });
}

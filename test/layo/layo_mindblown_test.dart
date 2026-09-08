import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.mindBlown]: pure [LayoPainter] geometry/color
/// assertions (the spiral eyes at mrLayo's own canonical spacing since it
/// draws a mouth, the open "O" mouth, and the magenta antenna/tie accent) and
/// [Layo]'s own `spinT`/`popT` animation lifecycle.
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

  group('LayoPainter mindBlown', () {
    test('paints mindBlown without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('mindBlown paints the antenna tip and tie in its magenta accent', () async {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      const magenta = Color(0xFFD500F9);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, magenta);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, magenta);
    });

    test('does not paint the mrLayo circular eyes (its eyes are spirals)', () {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('a spiral eye paints magenta at mrLayo\'s own canonical eye center (it draws a mouth)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      // The spiral's own path starts at radius 0 (its exact center), so
      // sampling that center point is guaranteed to land on the stroke
      // regardless of the spiral's pitch elsewhere.
      final color = await pixelAt(painter, size, const Offset(134.67, 195.73));
      expect(color, const Color(0xFFD500F9));
    });

    test('paints an open "O" mouth below the eyes', () async {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      final color = await pixelAt(painter, size, const Offset(197.93 - 17, 245.0));
      expect(color, const Color(0xFFD500F9), reason: 'mindBlown must draw an open "O" mouth');
    });

    test('spinT and popT both default to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.mindBlown);
      expect(painter.spinT, 0.0);
      expect(painter.popT, 0.0);
    });

    test('the pop burst shakes/scales the whole glyph group: a sample changes at the pop peak', () async {
      const atRest = LayoPainter(emotion: LayoEmotion.mindBlown);
      const atPopPeak = LayoPainter(emotion: LayoEmotion.mindBlown, popT: 0.5);

      final restColor = await pixelAt(atRest, size, const Offset(134.67 + 16, 195.73));
      final popColor = await pixelAt(atPopPeak, size, const Offset(134.67 + 16, 195.73));
      expect(
        popColor,
        isNot(restColor),
        reason: 'the pop burst must scale/shake the whole glyph group, changing what paints at a fixed sample point',
      );
    });

    test('paints without throwing across spinT and popT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.mindBlown, spinT: t, popT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when spinT differs for mindBlown', () {
        const painterA = LayoPainter(emotion: LayoEmotion.mindBlown);
        const painterB = LayoPainter(emotion: LayoEmotion.mindBlown, spinT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when popT differs for mindBlown', () {
        const painterA = LayoPainter(emotion: LayoEmotion.mindBlown);
        const painterB = LayoPainter(emotion: LayoEmotion.mindBlown, popT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-mindBlown when spinT/popT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, spinT: 0.5, popT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.mindBlown animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) spinT and popT are both 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.mindBlown)),
        ),
      );

      expect(painterIn(tester).spinT, 0.0);
      expect(painterIn(tester).popT, 0.0);
    });

    guardedTestWidgets('mindBlown spins the spirals: spinT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.mindBlown)),
        ),
      );

      expect(painterIn(tester).spinT, 0.0);

      await tester.pump(const Duration(milliseconds: 500));

      expect(
        painterIn(tester).spinT,
        closeTo(0.25, 0.05),
        reason: 'mindBlown must spin the spirals at the quarter-cycle point of its ~2s loop',
      );
    });

    guardedTestWidgets('mindBlown pops periodically: popT rises above 0, then settles back to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.mindBlown)),
        ),
      );

      expect(painterIn(tester).popT, 0.0);

      var sawPop = false;
      for (var i = 0; i < 62 && !sawPop; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).popT > 0.0) {
          sawPop = true;
        }
      }

      expect(sawPop, isTrue, reason: 'mindBlown must pop (popT rises above 0) at some point while animating');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never spins or pops: both stay 0 while animating', (tester) async {
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

        expect(painterIn(tester).spinT, 0.0, reason: '$emotion must never spin');
        expect(painterIn(tester).popT, 0.0, reason: '$emotion must never pop');
      });
    }

    guardedTestWidgets('reduced motion forces both spinT and popT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.mindBlown)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).spinT, 0.0);
      expect(painterIn(tester).popT, 0.0);
    });
  });
}

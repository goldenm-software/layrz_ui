import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layo/src/glyphs/layo_glyphs_money.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.money]: pure [LayoPainter] geometry/color
/// assertions (the `$` eyes, the antenna/tie accent, and the bill-rain
/// background layer) plus [Layo]'s own animation lifecycle for `moneyT` and
/// `billRainT`.
///
/// Split into its own file (rather than appended to the already oversized
/// `layo_painter_test.dart`/`layo_emotion_widget_test.dart`) per this
/// repository's file-size convention -- mirroring how
/// `layo_comandante_wink_test.dart` was split out for
/// [LayoEmotion.comandante].
void main() {
  const size = Size(396.15, 659.76);

  /// Rasterizes [painter] at [size] and returns the actual pixel color at
  /// [point] -- see `layo_painter_test.dart`'s own `pixelAt` for why this is
  /// more robust here than the `paints` matcher's strictly sequential
  /// predicates.
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

  group('LayoPainter money', () {
    test('paints money without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.money);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('money paints the antenna tip and tie in its green accent', () async {
      const painter = LayoPainter(emotion: LayoEmotion.money);
      const green = Color(0xFF2E7D32);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, green, reason: 'money\'s antenna tip must be its exact green accent');

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, green, reason: 'money\'s tie must follow its own green accent, like every other tie-wearing emotion');
    });

    test('at moneyT == 0.0 each "\$" eye paints a stroked path in the green accent', () {
      // paintMoneyEyes is exercised directly (rather than fishing its own
      // drawPath calls out of the full painter's draw sequence, where the
      // bill rain's own drawRRect/drawLine/drawArc calls precede it) --
      // simpler and immune to `paints`' strictly-sequential call-order
      // matching picking up the wrong call, exactly like
      // `layo_painter_test.dart`'s own `paintMrLayoMouth` unit test.
      expect(
        (Canvas canvas) => paintMoneyEyes(
          canvas,
          1.0,
          accentColor: const Color(0xFF2E7D32),
          moneyT: 0.0,
          paintSmoothed: (canvas, color, k, shapeOnto) => shapeOnto(Paint()..color = color),
        ),
        paints..path(color: const Color(0xFF2E7D32)),
      );
    });

    test('paints without throwing across moneyT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.money, moneyT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('bill-rain background layer', () {
      test('billRainT defaults to 0.0', () {
        const painter = LayoPainter(emotion: LayoEmotion.money);
        expect(painter.billRainT, 0.0);
      });

      test('paints a green bill rectangle behind the body at billRainT == 0.0', () async {
        // The first bill seed sits at xFraction 0.08, phaseOffset 0.0, so at
        // billRainT == 0.0 it starts just above the top edge and has not yet
        // entered the frame -- sample a bill seed whose own phase offset
        // guarantees it is already on-screen at t == 0 instead.
        const painter = LayoPainter(emotion: LayoEmotion.money);
        // seed index 6: xFraction 0.02, phaseOffset 0.55, speed 1.20 -> at
        // t=0, phase = 0.55, comfortably inside the frame's vertical travel.
        final x = 0.02 * size.width;
        final travel = size.height + 12 * 2;
        final y = -12 + 0.55 * travel;
        final color = await pixelAt(painter, size, Offset(x, y));
        expect(color.a, greaterThan(0), reason: 'a bill must be painted at its own phase-0 position');
      });

      test('bill positions move as billRainT advances', () async {
        const atStart = LayoPainter(emotion: LayoEmotion.money);
        const advanced = LayoPainter(emotion: LayoEmotion.money, billRainT: 0.5);

        // Sample the same seed's phase-0 position; once billRainT advances,
        // that exact point should no longer necessarily hold the same bill,
        // so at least one of a spread of sample points must differ.
        final travel = size.height + 12 * 2;
        final x = 0.02 * size.width;
        final y = -12 + 0.55 * travel;

        final colorAtStart = await pixelAt(atStart, size, Offset(x, y));
        final colorAdvanced = await pixelAt(advanced, size, Offset(x, y));
        expect(
          colorAdvanced,
          isNot(colorAtStart),
          reason: 'advancing billRainT must move the bill rain, changing what paints at a fixed sample point',
        );
      });

      test('the bill rain paints strictly before the body (behind the whole figure)', () async {
        // The bill rain is the very first thing `paint` draws; sampling a
        // point squarely inside the mascot's own opaque inner body panel
        // must show that panel's own color, not a bill, proving the body is
        // painted on top of (not occluded by) the rain.
        const painter = LayoPainter(emotion: LayoEmotion.money);
        const bodyInnerColor = Color(0xFFD4D2D3);
        final color = await pixelAt(painter, size, const Offset(197, 600));
        expect(
          color,
          bodyInnerColor,
          reason: 'the body must occlude the bill rain wherever the two overlap',
        );
      });

      test('no other emotion ever paints a bill-rain background layer', () async {
        for (final emotion in LayoEmotion.values.where((e) => e != LayoEmotion.money)) {
          final painter = LayoPainter(emotion: emotion);
          // A point well outside the body/head silhouette but inside the
          // painted box -- only money's rain could plausibly paint there.
          final color = await pixelAt(painter, size, const Offset(10, 10));
          expect(color.a, 0, reason: '$emotion must not paint anything at the very top-left corner');
        }
      });

      test('paints without throwing across billRainT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.money, billRainT: t);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });
    });

    group('shouldRepaint', () {
      test('is true when moneyT differs for money', () {
        const painterA = LayoPainter(emotion: LayoEmotion.money);
        const painterB = LayoPainter(emotion: LayoEmotion.money, moneyT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when billRainT differs for money', () {
        const painterA = LayoPainter(emotion: LayoEmotion.money);
        const painterB = LayoPainter(emotion: LayoEmotion.money, billRainT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-money when moneyT/billRainT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, moneyT: 0.5, billRainT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.money animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) moneyT and billRainT are both 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.money)),
        ),
      );

      expect(painterIn(tester).moneyT, 0.0);
      expect(painterIn(tester).billRainT, 0.0);
    });

    guardedTestWidgets('money shimmers: moneyT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.money)),
        ),
      );

      expect(painterIn(tester).moneyT, 0.0);

      await tester.pump(const Duration(milliseconds: 400));

      expect(
        painterIn(tester).moneyT,
        closeTo(0.25, 0.05),
        reason: 'money must play the shimmer at the quarter-cycle point of its ~1.6s loop',
      );
    });

    guardedTestWidgets('money\'s bill rain loops: billRainT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.money)),
        ),
      );

      expect(painterIn(tester).billRainT, 0.0);

      await tester.pump(const Duration(milliseconds: 1500));

      expect(
        painterIn(tester).billRainT,
        closeTo(0.25, 0.05),
        reason: 'the bill rain must advance at the quarter-cycle point of its ~6s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea, LayoEmotion.comandante]) {
      guardedTestWidgets('$emotion never shimmers or rains bills: both stay 0 while animating', (tester) async {
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

        expect(painterIn(tester).moneyT, 0.0, reason: '$emotion must never shimmer');
        expect(painterIn(tester).billRainT, 0.0, reason: '$emotion must never rain bills');
      });
    }

    guardedTestWidgets('reduced motion forces both moneyT and billRainT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.money)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).moneyT, 0.0);
      expect(painterIn(tester).billRainT, 0.0);
    });
  });
}

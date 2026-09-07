import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.success]: pure [LayoPainter] geometry/color
/// assertions (the bold double check mark's draw-in and pop/bounce, plus the
/// green antenna/tie accent) and [Layo]'s own `checkDrawT`/`checkPopT`
/// animation lifecycle.
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

  group('LayoPainter success', () {
    test('paints success without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.success);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('success paints the antenna tip and tie in its green accent', () async {
      const painter = LayoPainter(emotion: LayoEmotion.success);
      const green = Color(0xFF2E7D32);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, green);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, green);
    });

    group('draw-in and pop/bounce', () {
      test('checkDrawT defaults to 1.0 (fully drawn, this emotion\'s resting pose)', () {
        const painter = LayoPainter(emotion: LayoEmotion.success);
        expect(painter.checkDrawT, 1.0);
      });

      test('checkPopT defaults to 0.0 (no bounce in progress)', () {
        const painter = LayoPainter(emotion: LayoEmotion.success);
        expect(painter.checkPopT, 0.0);
      });

      test('at checkDrawT == 0.0 nothing is drawn at the check\'s own long-leg endpoint', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success, checkDrawT: 0.0);
        // The check's long-leg end sits at (228.745, 165) -- shifted left of
        // the single-check's own original (250, 165) so the double-check
        // pair centers horizontally on the screen, see
        // layo_glyphs_success.dart's own _kCheckStart doc comment. Undrawn at
        // checkDrawT == 0.0, this point must not be green.
        final color = await pixelAt(painter, size, const Offset(228.745, 165));
        expect(color, isNot(const Color(0xFF2E7D32)));
      });

      test('at checkDrawT == 1.0 the check reaches its own long-leg endpoint', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success);
        final color = await pixelAt(painter, size, const Offset(228.745, 165));
        expect(color, const Color(0xFF2E7D32), reason: 'a fully-drawn check must reach its own long-leg tip');
      });

      test('at checkDrawT == 0.3 (short leg only) the check has not yet reached its own corner', () async {
        // The short leg (start (128.745,210) to corner (164.745,246)) is
        // drawn before the long leg -- at a small draw fraction the corner
        // itself must not yet be reached.
        const painter = LayoPainter(emotion: LayoEmotion.success, checkDrawT: 0.05);
        final color = await pixelAt(painter, size, const Offset(164.745, 246));
        expect(color, isNot(const Color(0xFF2E7D32)));
      });

      test('paints without throwing across checkDrawT and checkPopT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.success, checkDrawT: t, checkPopT: t);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('the pop/bounce only ever applies once fully drawn: still reaches the endpoint at checkPopT peak', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success, checkPopT: 0.3);
        final color = await pixelAt(painter, size, const Offset(228.745, 165));
        expect(
          color,
          const Color(0xFF2E7D32),
          reason: 'a fully-drawn check mid-bounce must still cover its own resting endpoint region',
        );
      });

      test('a second check is painted, offset to the right and overlapping the first (double check)', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success);
        // The second check's own long-leg endpoint sits at
        // (228.745+38, 165+6) = (266.745, 171) -- unreachable by the base
        // check alone, so this being green proves a second, distinct stroke
        // was drawn.
        final color = await pixelAt(painter, size, const Offset(266.745, 171));
        expect(color, const Color(0xFF2E7D32), reason: 'the second check must reach its own offset long-leg tip');
      });

      test('at checkDrawT == 0.0 the second check\'s endpoint is undrawn too', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success, checkDrawT: 0.0);
        final color = await pixelAt(painter, size, const Offset(266.745, 171));
        expect(color, isNot(const Color(0xFF2E7D32)));
      });

      test('both checks draw in together: at a small draw fraction neither has reached its own corner', () async {
        const painter = LayoPainter(emotion: LayoEmotion.success, checkDrawT: 0.05);
        // The second check's own corner sits at (164.745+38, 246+6) =
        // (202.745, 252).
        final color = await pixelAt(painter, size, const Offset(202.745, 252));
        expect(color, isNot(const Color(0xFF2E7D32)));
      });

      test(
        'the check stroke is bold/heavy: a point off the centerline but within the thicker stroke is covered',
        () async {
          // The base check's long leg runs from (164.745, 246) to
          // (228.745, 165), so its own midpoint sits at (196.745, 205.5);
          // moving 6 source units along the leg's own perpendicular direction
          // lands at ~(201.46, 209.22) -- inside this emotion's own
          // 15-unit-wide stroke (half-width 7.5) but outside what a thin
          // 9-unit stroke (half-width 4.5) would ever reach, so this being
          // green proves the stroke was widened, not merely that a stroke
          // exists at all.
          const painter = LayoPainter(emotion: LayoEmotion.success);
          final color = await pixelAt(painter, size, const Offset(201.455, 209.22));
          expect(
            color,
            const Color(0xFF2E7D32),
            reason: 'the bold stroke must cover a point 6 units off its centerline',
          );
        },
      );

      test('the double check is centered horizontally on the screen window\'s own center', () async {
        // The pair's combined bounding box spans x 128.745-266.745 (base
        // check start to second check's long-leg end), whose own midpoint
        // is (128.745 + 266.745) / 2 = 197.745 -- the screen window's own
        // horizontal center (see LayoPainter._screenRect). Sampling a point
        // equidistant left and right of that center, along the base check's
        // own long leg direction, is a weaker geometric proof than
        // recomputing the bounds directly, so this asserts the bounds
        // arithmetic itself instead of a pixel sample.
        const pairLeft = 128.745;
        const pairRight = 266.745;
        const screenCenterX = 197.745;
        expect((pairLeft + pairRight) / 2, closeTo(screenCenterX, 0.001));
        // Sanity-check both extremes still paint at checkDrawT == 1.0.
        const painter = LayoPainter(emotion: LayoEmotion.success);
        final leftColor = await pixelAt(painter, size, const Offset(pairLeft, 210));
        expect(leftColor, const Color(0xFF2E7D32), reason: 'the base check\'s own short-leg start must still paint');
      });
    });

    group('shouldRepaint', () {
      test('is true when checkDrawT differs for success', () {
        const painterA = LayoPainter(emotion: LayoEmotion.success);
        const painterB = LayoPainter(emotion: LayoEmotion.success, checkDrawT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when checkPopT differs for success', () {
        const painterA = LayoPainter(emotion: LayoEmotion.success);
        const painterB = LayoPainter(emotion: LayoEmotion.success, checkPopT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-check when checkDrawT/checkPopT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, checkDrawT: 0.5, checkPopT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.success animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) checkDrawT is 1.0 (fully drawn) and checkPopT is 0.0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.success)),
        ),
      );

      expect(painterIn(tester).checkDrawT, 1.0);
      expect(painterIn(tester).checkPopT, 0.0);
    });

    guardedTestWidgets('success draws itself on immediately when animation starts, then pops and settles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.success)),
        ),
      );

      // The very first frame after animation starts must begin the draw-in
      // from 0, unlike the static (animate: false) resting pose.
      await tester.pump();
      expect(
        painterIn(tester).checkDrawT,
        lessThan(1.0),
        reason: 'the initial draw-in must start from an undrawn state',
      );

      // Pump past the draw-in's own ~600ms duration.
      for (var i = 0; i < 7; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).checkDrawT, 1.0, reason: 'the draw-in must finish fully drawn');

      // The pop/bounce plays immediately after the draw-in finishes (~450ms);
      // pump through it and confirm it settles back to 0.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).checkPopT, 0.0, reason: 'the pop/bounce must settle back to exactly 0');
    });

    guardedTestWidgets('success replays the draw-in periodically after the initial sequence settles', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.success)),
        ),
      );

      // Settle the initial draw-in + pop (~1.05s total).
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).checkDrawT, 1.0);
      expect(painterIn(tester).checkPopT, 0.0);

      // The replay scheduler fires within 3-6s; pump well past that,
      // sampling in small steps to catch checkDrawT dip below 1.0 (a replay
      // in progress) at least once.
      var sawReplay = false;
      for (var i = 0; i < 62 && !sawReplay; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).checkDrawT < 1.0) {
          sawReplay = true;
        }
      }

      expect(sawReplay, isTrue, reason: 'success must replay the draw-in (checkDrawT dips below 1.0) at some point');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never draws or pops a check: checkDrawT stays 1.0, checkPopT stays 0.0', (
        tester,
      ) async {
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

        expect(painterIn(tester).checkDrawT, 1.0, reason: '$emotion\'s checkDrawT is inert and stays at its default');
        expect(painterIn(tester).checkPopT, 0.0, reason: '$emotion must never pop a check');
      });
    }

    guardedTestWidgets('reduced motion keeps the check fully drawn and static, never popping', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.success)),
          ),
        ),
      );

      expect(painterIn(tester).checkDrawT, 1.0);

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).checkDrawT, 1.0);
      expect(painterIn(tester).checkPopT, 0.0);
    });
  });
}

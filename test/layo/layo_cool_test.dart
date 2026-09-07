import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.cool]: pure [LayoPainter] geometry/color
/// assertions (the sunglasses **overlay** hiding the eyes, the blue
/// antenna/tie accent, and the underlying mouth) and [Layo]'s own subtle
/// `gleamT` animation lifecycle.
///
/// Split into its own file per this repository's file-size convention,
/// mirroring how `layo_comandante_wink_test.dart` was split out for
/// [LayoEmotion.comandante]'s own overlay emotion.
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

  group('LayoPainter cool', () {
    test('paints cool without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('cool paints the antenna tip and tie in blue, like mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      const blue = Color(0xFF60ABDE);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue);
    });

    test('does not paint the mrLayo circular eyes -- the sunglasses hide them', () {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('the sunglasses lenses paint blue over both eye positions', () async {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      const blue = Color(0xFF60ABDE);

      final leftLens = await pixelAt(painter, size, const Offset(197.66 - 63, 195.73));
      expect(leftLens, blue);

      final rightLens = await pixelAt(painter, size, const Offset(197.66 + 63, 195.73));
      expect(rightLens, blue);
    });

    test('the bridge connects both lenses', () async {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      const blue = Color(0xFF60ABDE);
      final bridge = await pixelAt(painter, size, const Offset(197.66, 195.73));
      expect(bridge, blue);
    });

    test('the lens is wider than mrLayo\'s own eye radius, proving it is a sunglasses lens not just an eye', () async {
      // The lens spans a full 32-unit half-width; sampling well past
      // mrLayo's own 15.57 eye radius (but still inside the lens) proves
      // this is the wider sunglasses shape, not merely a same-colored eye.
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      const blue = Color(0xFF60ABDE);
      final color = await pixelAt(painter, size, const Offset(197.66 - 63 - 25, 195.73));
      expect(color, blue, reason: 'the lens must extend well past a plain eye\'s own radius');
    });

    test('paints a mouth underneath the sunglasses (mrLayo\'s own smile)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      final color = await pixelAt(painter, size, const Offset(197.93, 245));
      expect(color, const Color(0xFF60ABDE), reason: 'cool must draw mrLayo\'s own smile underneath the glasses');
    });

    test(
      'no other emotion (except comandante, mrLayo, wink, smug) paints this far into the lens\' own width',
      () async {
        // comandante's own beret overlay legitimately spans this same
        // top-of-head region, and mrLayo/wink/smug share the same blue eye
        // color at a nearby position -- all four are excluded here. Every
        // other emotion must show its own face at the lens' own far edge,
        // never this shared blue.
        const blue = Color(0xFF60ABDE);
        const excluded = {
          LayoEmotion.cool,
          LayoEmotion.comandante,
          LayoEmotion.mrLayo,
          LayoEmotion.wink,
          LayoEmotion.smug,
        };
        for (final emotion in LayoEmotion.values.where((e) => !excluded.contains(e))) {
          final painter = LayoPainter(emotion: emotion);
          final color = await pixelAt(painter, size, const Offset(197.66 - 63 - 25, 195.73));
          expect(color, isNot(blue), reason: '$emotion must not paint a sunglasses lens this wide');
        }
      },
    );

    test('gleamT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.cool);
      expect(painter.gleamT, 0.0);
    });

    test('paints without throwing across gleamT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.cool, gleamT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when gleamT differs for cool', () {
        const painterA = LayoPainter(emotion: LayoEmotion.cool);
        const painterB = LayoPainter(emotion: LayoEmotion.cool, gleamT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-cool when gleamT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, gleamT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.cool animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) gleamT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.cool)),
        ),
      );

      expect(painterIn(tester).gleamT, 0.0);
    });

    guardedTestWidgets('cool gleams periodically: gleamT rises above 0, then settles back to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.cool)),
        ),
      );

      expect(painterIn(tester).gleamT, 0.0);

      var sawGleam = false;
      for (var i = 0; i < 62 && !sawGleam; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).gleamT > 0.0) {
          sawGleam = true;
        }
      }

      expect(sawGleam, isTrue, reason: 'cool must gleam (gleamT rises above 0) at some point while animating');

      // The gleam controller's own forward+reverse cycle is ~900ms each way
      // (~1.8s round trip); pump comfortably past that, well short of the
      // next jittered gleam's minimum 3s interval.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).gleamT, 0.0, reason: 'the gleam must fall back to exactly 0');
    });

    guardedTestWidgets('animate: false never gleams: gleamT stays 0 even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.cool)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).gleamT, 0.0, reason: 'animate: false must suppress the gleam entirely');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never gleams cool\'s own gleamT: it stays 0', (tester) async {
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

        expect(painterIn(tester).gleamT, 0.0, reason: '$emotion must never gleam cool\'s own gleamT');
      });
    }
  });
}

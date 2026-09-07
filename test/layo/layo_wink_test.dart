import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.wink]: pure [LayoPainter] geometry/color
/// assertions (mrLayo's own canonical eye spacing and smile, the blue
/// antenna/tie accent, and `wearWinkT`'s effect on the right eye alone) and
/// [Layo]'s own wear-wink animation lifecycle.
///
/// Split into its own file per this repository's file-size convention,
/// mirroring how `layo_comandante_wink_test.dart` was split out for
/// [LayoEmotion.comandante].
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

  group('LayoPainter wink', () {
    test('paints wink without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.wink);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('wink paints the antenna tip and tie in blue, like mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.wink);
      const blue = Color(0xFF60ABDE);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue);
    });

    test('both eyes paint blue circles at rest (wearWinkT: 0.0), at mrLayo\'s own canonical spacing', () async {
      const painter = LayoPainter(emotion: LayoEmotion.wink);
      const blue = Color(0xFF60ABDE);

      final left = await pixelAt(painter, size, const Offset(134.67, 195.73));
      expect(left, blue);

      final right = await pixelAt(painter, size, const Offset(261.17, 195.73));
      expect(right, blue);
    });

    test('wink paints a mouth (mrLayo\'s own smile), unlike the mouthless emotions', () async {
      const painter = LayoPainter(emotion: LayoEmotion.wink);
      final color = await pixelAt(painter, size, const Offset(197.93, 245));
      expect(color, const Color(0xFF60ABDE), reason: 'wink must draw mrLayo\'s own smile');
    });

    test('wearWinkT squashes the right eye alone; the left eye stays the full open circle', () async {
      const painter = LayoPainter(emotion: LayoEmotion.wink, wearWinkT: 1.0);
      // At full wink (wearWinkT: 1.0) the right eye is squashed to a thin
      // ellipse -- its own vertical extremes should no longer paint blue.
      final rightEyeTop = await pixelAt(painter, size, const Offset(261.17, 195.73 - 14));
      expect(rightEyeTop, isNot(const Color(0xFF60ABDE)), reason: 'a fully winked right eye must not paint this tall');

      final leftEyeTop = await pixelAt(painter, size, const Offset(134.67, 195.73 - 14));
      expect(
        leftEyeTop,
        const Color(0xFF60ABDE),
        reason: 'the left eye must stay the full open circle at every wearWinkT',
      );
    });

    test('wearWinkT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.wink);
      expect(painter.wearWinkT, 0.0);
    });

    test('paints without throwing across wearWinkT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.wink, wearWinkT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when wearWinkT differs for wink', () {
        const painterA = LayoPainter(emotion: LayoEmotion.wink);
        const painterB = LayoPainter(emotion: LayoEmotion.wink, wearWinkT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.comandante, LayoEmotion.love]) {
        test('is false-for-wink when wearWinkT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, wearWinkT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.wink animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) wearWinkT is 0.0 -- both eyes open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.wink)),
        ),
      );

      expect(painterIn(tester).wearWinkT, 0.0);
    });

    guardedTestWidgets('wink winks periodically: wearWinkT rises above 0, then settles back to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.wink)),
        ),
      );

      expect(painterIn(tester).wearWinkT, 0.0);

      var sawWink = false;
      for (var i = 0; i < 62 && !sawWink; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).wearWinkT > 0.0) {
          sawWink = true;
        }
      }

      expect(sawWink, isTrue, reason: 'wink must wink (wearWinkT rises above 0) at some point while animating');

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).wearWinkT, 0.0, reason: 'the wink must fall back to exactly 0 (both eyes open again)');
    });

    guardedTestWidgets('animate: false never winks: wearWinkT stays 0 even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.wink)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).wearWinkT, 0.0, reason: 'animate: false must suppress the wink entirely');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.comandante, LayoEmotion.love]) {
      guardedTestWidgets('$emotion never plays LayoEmotion.wink\'s own wearWinkT: it stays 0', (tester) async {
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

        expect(painterIn(tester).wearWinkT, 0.0, reason: '$emotion must never play LayoEmotion.wink\'s own wearWinkT');
      });
    }
  });
}

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.excited]: pure [LayoPainter] geometry/color
/// assertions (the star eyes alone -- no mouth, pulled closer together than
/// mrLayo's own eye spacing -- and the yellow antenna/tie accent) and
/// [Layo]'s own `sparkleT`/`excitedBounceT` animation lifecycle.
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

  group('LayoPainter excited', () {
    test('paints excited without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('excited paints the antenna tip and tie in its yellow accent, matching idea', () async {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      const yellow = Color(0xFFF5CC24);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, yellow);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, yellow);
    });

    test('does not paint the mrLayo circular eyes (its eyes are stars)', () {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('a star point paints yellow at rest (sparkleT: 0.0, bounceT: 0.0)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      // The left star's own top point, straight up from its center (now at
      // x 147.66, pulled closer to the screen's own center than mrLayo's
      // own eye spacing since this emotion draws no mouth).
      final color = await pixelAt(painter, size, const Offset(147.66, 195.73 - 10));
      expect(color, const Color(0xFFF5CC24));
    });

    test('sparkleT and excitedBounceT both default to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      expect(painter.sparkleT, 0.0);
      expect(painter.excitedBounceT, 0.0);
    });

    test('does not paint any mouth at all', () async {
      const painter = LayoPainter(emotion: LayoEmotion.excited);
      // The old smile spanned roughly x 150-245 at y 235-268; sampling its
      // own midpoint must find no glyph color there now that this emotion
      // draws no mouth.
      final color = await pixelAt(painter, size, const Offset(197.5, 251));
      expect(color, isNot(const Color(0xFFF5CC24)), reason: 'excited must draw no mouth of any kind');
    });

    test('the bounce lifts the whole glyph group: a rest-position sample changes at the bounce peak', () async {
      const atRest = LayoPainter(emotion: LayoEmotion.excited);
      const atBouncePeak = LayoPainter(emotion: LayoEmotion.excited, excitedBounceT: 0.5);

      final restColor = await pixelAt(atRest, size, const Offset(147.66, 195.73 - 18));
      final bounceColor = await pixelAt(atBouncePeak, size, const Offset(147.66, 195.73 - 18));
      expect(
        bounceColor,
        isNot(restColor),
        reason: 'the bounce must lift the whole glyph group, changing what paints at a fixed sample point',
      );
    });

    test('paints without throwing across sparkleT and excitedBounceT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.excited, sparkleT: t, excitedBounceT: t);
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when sparkleT differs for excited', () {
        const painterA = LayoPainter(emotion: LayoEmotion.excited);
        const painterB = LayoPainter(emotion: LayoEmotion.excited, sparkleT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when excitedBounceT differs for excited', () {
        const painterA = LayoPainter(emotion: LayoEmotion.excited);
        const painterB = LayoPainter(emotion: LayoEmotion.excited, excitedBounceT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-excited when sparkleT/excitedBounceT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, sparkleT: 0.5, excitedBounceT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.excited animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) sparkleT and excitedBounceT are both 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.excited)),
        ),
      );

      expect(painterIn(tester).sparkleT, 0.0);
      expect(painterIn(tester).excitedBounceT, 0.0);
    });

    guardedTestWidgets('excited twinkles: sparkleT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.excited)),
        ),
      );

      expect(painterIn(tester).sparkleT, 0.0);

      await tester.pump(const Duration(milliseconds: 375));

      expect(
        painterIn(tester).sparkleT,
        closeTo(0.25, 0.05),
        reason: 'excited must play the twinkle at the quarter-cycle point of its ~1.5s loop',
      );
    });

    guardedTestWidgets('excited bounces: excitedBounceT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.excited)),
        ),
      );

      expect(painterIn(tester).excitedBounceT, 0.0);

      await tester.pump(const Duration(milliseconds: 375));

      expect(
        painterIn(tester).excitedBounceT,
        closeTo(0.25, 0.05),
        reason: 'excited must play the bounce in sync with the twinkle, at the same quarter-cycle point',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never twinkles or bounces: both stay 0 while animating', (tester) async {
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

        expect(painterIn(tester).sparkleT, 0.0, reason: '$emotion must never twinkle');
        expect(painterIn(tester).excitedBounceT, 0.0, reason: '$emotion must never bounce excitedly');
      });
    }

    guardedTestWidgets('reduced motion forces both sparkleT and excitedBounceT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.excited)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).sparkleT, 0.0);
      expect(painterIn(tester).excitedBounceT, 0.0);
    });
  });
}

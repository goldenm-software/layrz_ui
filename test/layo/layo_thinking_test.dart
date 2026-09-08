import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.thinking]: pure [LayoPainter] geometry/color
/// assertions (the white thought-bubble cloud and its connector circles,
/// decoupled from the blue antenna/tie accent) and [Layo]'s own `thoughtT`
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

  group('LayoPainter thinking', () {
    test('paints thinking without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.thinking);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('thinking paints the antenna tip and tie in blue, matching mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.thinking);
      const blue = Color(0xFF60ABDE);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue);
    });

    test('the cloud paints white at its own center, regardless of thoughtT', () async {
      for (final t in [0.0, 0.5, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.thinking, thoughtT: t);
        final color = await pixelAt(painter, size, const Offset(198, 182));
        expect(
          color,
          const Color(0xFFFFFFFF),
          reason: 'the cloud itself must be static (and white) regardless of thoughtT: $t',
        );
      }
    });

    test('the cloud is white while the antenna tip and tie stay blue (decoupled colors)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.thinking);
      const blue = Color(0xFF60ABDE);
      const white = Color(0xFFFFFFFF);

      final cloud = await pixelAt(painter, size, const Offset(198, 182));
      expect(cloud, white, reason: 'the cloud must be white, decoupled from the tie/dot accent');

      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue, reason: 'the antenna tip must stay blue even though the cloud is white');

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue, reason: 'the tie must stay blue even though the cloud is white');
    });

    test('thoughtT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.thinking);
      expect(painter.thoughtT, 0.0);
    });

    test('paints without throwing across thoughtT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.thinking, thoughtT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when thoughtT differs for thinking', () {
        const painterA = LayoPainter(emotion: LayoEmotion.thinking);
        const painterB = LayoPainter(emotion: LayoEmotion.thinking, thoughtT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-thought when thoughtT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, thoughtT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.thinking animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) thoughtT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.thinking)),
        ),
      );

      expect(painterIn(tester).thoughtT, 0.0);
    });

    guardedTestWidgets('thinking\'s connectors sequence: thoughtT moves away from 0 while animating', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.thinking)),
        ),
      );

      expect(painterIn(tester).thoughtT, 0.0);

      await tester.pump(const Duration(milliseconds: 550));

      expect(
        painterIn(tester).thoughtT,
        closeTo(0.25, 0.05),
        reason: 'thinking must advance the connector sequence at the quarter-cycle point of its ~2.2s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never advances the connector sequence: thoughtT stays 0', (tester) async {
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

        expect(painterIn(tester).thoughtT, 0.0, reason: '$emotion must never advance the thought-connector sequence');
      });
    }

    guardedTestWidgets('reduced motion forces thoughtT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.thinking)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).thoughtT, 0.0);
    });
  });
}

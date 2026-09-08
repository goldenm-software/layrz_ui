import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.working]: pure [LayoPainter] geometry/color
/// assertions (the two gears alone -- no mouth -- and the amber antenna/tie
/// accent) and [Layo]'s own `gearT` animation lifecycle.
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

  group('LayoPainter working', () {
    test('paints working without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('working paints the antenna tip and tie in its amber accent, distinct from alert\'s orange', () async {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      const amber = Color(0xFFB8860B);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, amber);
      expect(tip, isNot(const Color(0xFFFF9800)), reason: 'working\'s amber must differ from alert\'s own orange');

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, amber);
    });

    test('does not paint the mrLayo circular eyes (its glyphs are gears)', () {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('the larger gear paints amber at rest (gearT: 0.0)', () async {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      // Sampling the larger gear's exact resting center would hit its own
      // punched-out bore hole (radius 11), so this samples 20 units above
      // that center instead -- inside the gear's solid tooth-root/tooth-tip
      // ring (inner radius 26, outer radius 34) and clear of any tooth gap.
      final color = await pixelAt(painter, size, const Offset(174.245, 224.275 - 20));
      expect(color, const Color(0xFFB8860B));
    });

    test('gearT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      expect(painter.gearT, 0.0);
    });

    test('does not paint any mouth at all', () async {
      const painter = LayoPainter(emotion: LayoEmotion.working);
      final color = await pixelAt(painter, size, const Offset(197.5, 251));
      expect(color, isNot(const Color(0xFFB8860B)), reason: 'working must draw no mouth of any kind');
    });

    test('paints without throwing across gearT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.working, gearT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when gearT differs for working', () {
        const painterA = LayoPainter(emotion: LayoEmotion.working);
        const painterB = LayoPainter(emotion: LayoEmotion.working, gearT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-working when gearT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, gearT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.working animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) gearT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.working)),
        ),
      );

      expect(painterIn(tester).gearT, 0.0);
    });

    guardedTestWidgets('working rotates the gears: gearT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.working)),
        ),
      );

      expect(painterIn(tester).gearT, 0.0);

      await tester.pump(const Duration(milliseconds: 750));

      expect(
        painterIn(tester).gearT,
        closeTo(0.25, 0.05),
        reason: 'working must rotate the gears at the quarter-cycle point of its ~3s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never rotates gears: gearT stays 0 while animating', (tester) async {
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

        expect(painterIn(tester).gearT, 0.0, reason: '$emotion must never rotate gears');
      });
    }

    guardedTestWidgets('reduced motion forces gearT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.working)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).gearT, 0.0);
    });
  });
}

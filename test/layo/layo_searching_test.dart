import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.searching]: pure [LayoPainter] geometry/color
/// assertions (the magnifier glyph alone -- no mouth, centered in the
/// screen -- and the blue antenna/tie accent, matching mrLayo) and [Layo]'s
/// own `scanT` animation lifecycle.
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

  group('LayoPainter searching', () {
    test('paints searching without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('searching paints the antenna tip and tie in blue, matching mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      const blue = Color(0xFF60ABDE);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, blue);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, blue);
    });

    test('does not paint the mrLayo circular eyes (its glyph is a magnifier)', () {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('the lens ring paints blue at rest (scanT: 0.0), the whole group centered on the screen', () async {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      // At rest the whole glyph group (lens plus handle) is centered on the
      // screen's own true center; the lens ring's own center sits up and
      // left of that to balance the handle's extra reach down-right --
      // sample its own left edge.
      final color = await pixelAt(painter, size, const Offset(156.70, 208.87));
      expect(color, const Color(0xFF60ABDE));
    });

    test('scanT defaults to 0.0', () {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      expect(painter.scanT, 0.0);
    });

    test('does not paint any mouth at all', () async {
      const painter = LayoPainter(emotion: LayoEmotion.searching);
      final color = await pixelAt(painter, size, const Offset(197.5, 251));
      expect(color, isNot(const Color(0xFF60ABDE)), reason: 'searching must draw no mouth of any kind');
    });

    test('the scan moves the whole glyph group: a rest-position sample changes at the scan peak', () async {
      const atRest = LayoPainter(emotion: LayoEmotion.searching);
      const atScanPeak = LayoPainter(emotion: LayoEmotion.searching, scanT: 0.25);

      final restColor = await pixelAt(atRest, size, const Offset(156.70, 208.87));
      final scanColor = await pixelAt(atScanPeak, size, const Offset(156.70, 208.87));
      expect(
        scanColor,
        isNot(restColor),
        reason: 'the scan must move the whole glyph group, changing what paints at a fixed sample point',
      );
    });

    test('paints without throwing across scanT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.searching, scanT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('shouldRepaint', () {
      test('is true when scanT differs for searching', () {
        const painterA = LayoPainter(emotion: LayoEmotion.searching);
        const painterB = LayoPainter(emotion: LayoEmotion.searching, scanT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-searching when scanT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, scanT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.searching animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) scanT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.searching)),
        ),
      );

      expect(painterIn(tester).scanT, 0.0);
    });

    guardedTestWidgets('searching scans: scanT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.searching)),
        ),
      );

      expect(painterIn(tester).scanT, 0.0);

      await tester.pump(const Duration(milliseconds: 650));

      expect(
        painterIn(tester).scanT,
        closeTo(0.25, 0.05),
        reason: 'searching must play the scan at the quarter-cycle point of its ~2.6s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never scans: scanT stays 0 while animating', (tester) async {
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

        expect(painterIn(tester).scanT, 0.0, reason: '$emotion must never scan');
      });
    }

    guardedTestWidgets('reduced motion forces scanT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.searching)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).scanT, 0.0);
    });
  });
}

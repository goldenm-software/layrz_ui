import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.sad]: pure [LayoPainter] geometry/color assertions
/// (the open eyes -- pulled closer together than mrLayo's own eye spacing
/// since this emotion draws no mouth to anchor the wider gap -- the grey
/// antenna/tie accent, and the tear drip) and [Layo]'s own `tearT` animation
/// lifecycle (including its shorter-than-usual drip interval).
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

  group('LayoPainter sad', () {
    test('paints sad without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.sad);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('sad paints the antenna tip and tie in glyphColor (grey), not accentColor', () async {
      const painter = LayoPainter(emotion: LayoEmotion.sad);
      const grey = Color(0xFF848484);
      final tip = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tip, grey);

      final tie = await pixelAt(painter, size, const Offset(197, 355));
      expect(tie, grey);
    });

    test('paints two open eyes, pulled closer together than mrLayo\'s own eye spacing', () async {
      const painter = LayoPainter(emotion: LayoEmotion.sad);
      const grey = Color(0xFF848484);

      // Sampling each eye's own center must land inside the filled circle.
      // sad's own eyes sit at x 147.66/247.66 -- 50 units off the screen's
      // own center (197.66), noticeably closer together than mrLayo's x
      // 134.67/261.17 (~63 units off-center), since this emotion draws no
      // mouth to visually anchor the wider gap.
      final left = await pixelAt(painter, size, const Offset(147.66, 195.73));
      expect(left, grey, reason: 'the left eye must be a plain open (filled) circle');

      final right = await pixelAt(painter, size, const Offset(247.66, 195.73));
      expect(right, grey, reason: 'the right eye must be a plain open (filled) circle');

      // A point well clear of both eyes' own 15.57 radius reach (right of
      // the left eye's own rightmost edge at 147.66 + 15.57 = 163.23, left
      // of the right eye's own leftmost edge at 247.66 - 15.57 = 232.09)
      // must be background, proving the eyes read as a distinct pair rather
      // than one merged/overlapping shape.
      final betweenEyes = await pixelAt(painter, size, const Offset(197.66, 195.73));
      expect(betweenEyes, isNot(grey), reason: 'the gap between sad\'s two eyes must not be filled');
    });

    test('does not paint any mouth at all', () async {
      const painter = LayoPainter(emotion: LayoEmotion.sad);
      // The old frown spanned roughly x 165-230 at y 250-262; sampling its
      // own midpoint must find no glyph color there now that this emotion
      // draws no mouth.
      final color = await pixelAt(painter, size, const Offset(197.5, 256));
      expect(color, isNot(const Color(0xFF848484)), reason: 'sad must draw no mouth of any kind');
    });

    group('tear drip', () {
      test('tearT defaults to 0.0 (no tear visible)', () {
        const painter = LayoPainter(emotion: LayoEmotion.sad);
        expect(painter.tearT, 0.0);
      });

      test('at tearT == 0.0 no tear shape is painted at all', () async {
        const painter = LayoPainter(emotion: LayoEmotion.sad);
        // A vertical strip beneath the left eye (now at x 147.66, whose own
        // circle bottom edge sits at 195.73 + 15.57 = 211.3) where the tear
        // would fall, starting well clear of the eye itself.
        for (final y in [220.0, 240.0, 260.0, 280.0]) {
          final color = await pixelAt(painter, size, Offset(147.66, y));
          expect(color, isNot(const Color(0xFF848484)), reason: 'no tear should paint at y=$y when tearT is 0');
        }
      });

      test('mid-drip (tearT: 0.5) the tear is visible at its own interpolated position', () async {
        const painter = LayoPainter(emotion: LayoEmotion.sad, tearT: 0.5);
        // startY ~ 195.73 + 15.57 + 2 = 213.30, endY ~ 283.30; at t=0.5 the
        // tear center sits at ~248.30, directly below the left eye's own
        // x 147.66.
        final color = await pixelAt(painter, size, const Offset(147.66, 248.30));
        expect(color, const Color(0xFF848484), reason: 'the tear must be visible at its own mid-drip position');
      });

      test('paints without throwing across tearT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.sad, tearT: t);
          // Genuine no-throw contract: this sweep exists to catch a crash from
          // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
          // animation parameter's range -- specific values are covered by pixel-level
          // assertions elsewhere in this file.
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('a negative tearT paints no tear (defensive: below the documented 0..1 domain)', () async {
        const painter = LayoPainter(emotion: LayoEmotion.sad, tearT: -0.5);
        final color = await pixelAt(painter, size, const Offset(147.66, 248.30));
        expect(color, isNot(const Color(0xFF848484)));
      });
    });

    group('shouldRepaint', () {
      test('is true when tearT differs for sad', () {
        const painterA = LayoPainter(emotion: LayoEmotion.sad);
        const painterB = LayoPainter(emotion: LayoEmotion.sad, tearT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-tear when tearT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, tearT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.sad animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) tearT is 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.sad)),
        ),
      );

      expect(painterIn(tester).tearT, 0.0);
    });

    guardedTestWidgets('sad drips periodically: tearT rises above 0, then falls back to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.sad)),
        ),
      );

      expect(painterIn(tester).tearT, 0.0);

      var sawTear = false;
      var sawReset = false;
      for (var i = 0; i < 62 && !sawReset; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final value = painterIn(tester).tearT;
        if (value > 0.0) {
          sawTear = true;
        } else if (sawTear && value == 0.0) {
          // The drip that was in progress has now completed and reset --
          // stop pumping immediately so a further pump cannot cross into
          // the next jittered drip's own minimum 1.5s interval (timed from
          // this reset moment, see Layo._scheduleNextTear) before the
          // assertion below samples it.
          sawReset = true;
        }
      }

      expect(sawTear, isTrue, reason: 'sad must drip a tear (tearT rises above 0) at some point');
      expect(sawReset, isTrue, reason: 'the tear must settle back to exactly 0 once the drip in progress completes');
      expect(painterIn(tester).tearT, 0.0, reason: 'the tear must settle back to exactly 0 between drips');
    });

    guardedTestWidgets('sad drips more frequently than the other jittered one-shot emotions', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.sad)),
        ),
      );

      // The tear interval is jittered 1.5-2.5s (vs. every other one-shot
      // scheduler's 3-6s, see Layo._scheduleNextTear) -- pumping 3s must be
      // long enough to have started (and very likely finished) the very
      // first drip, unlike a 3-6s scheduler which could still be at 0 this
      // early.
      var sawTear = false;
      for (var i = 0; i < 30 && !sawTear; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).tearT > 0.0) {
          sawTear = true;
        }
      }

      expect(sawTear, isTrue, reason: 'sad\'s first drip must fire well within 3s given its shorter 1.5-2.5s interval');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never drips a tear: tearT stays 0, even after time passes', (tester) async {
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

        expect(painterIn(tester).tearT, 0.0, reason: '$emotion must never drip a tear');
      });
    }

    guardedTestWidgets('reduced motion forces tearT to stay 0, even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.sad)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).tearT, 0.0);
    });

    guardedTestWidgets('animate: false never drips, even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.sad)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).tearT, 0.0);
    });
  });
}

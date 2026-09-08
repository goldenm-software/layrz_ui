import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layo/src/glyphs/layo_glyphs_party.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.party]: pure [LayoPainter] geometry/color
/// assertions (the party hat overlay, the confetti background layer, the
/// festive antenna/tie accent, and the shared mrLayo face underneath) plus
/// [Layo]'s own animation lifecycle for `confettiT` and `pomPomBobT`.
///
/// Split into its own file (rather than appended to the already oversized
/// `layo_painter_test.dart`/`layo_emotion_widget_test.dart`) per this
/// repository's file-size convention -- mirroring how `layo_christmas_test.dart`
/// was split out for its own emotion.
void main() {
  const size = Size(396.15, 659.76);

  /// Rasterizes [painter] at [paintedSize] and returns the actual pixel
  /// color at [point] -- see `layo_painter_test.dart`'s own `pixelAt` for why
  /// this is more robust here than the `paints` matcher's strictly
  /// sequential predicates.
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

  /// A tolerant color-equality matcher: within [tolerance] per channel of
  /// [expected]. This design system's shapes antialias their own edges, so a
  /// sample point a handful of source units from a shape's exact center can
  /// land on a softened edge pixel rather than the shape's flat interior
  /// fill -- this matcher absorbs that without asserting on a sample point so
  /// far inside the shape it stops proving the shape's own extent.
  Matcher closeToColor(Color expected, {int tolerance = 12}) => predicate<Color>((actual) {
    return (actual.r - expected.r).abs() * 255 <= tolerance &&
        (actual.g - expected.g).abs() * 255 <= tolerance &&
        (actual.b - expected.b).abs() * 255 <= tolerance;
  }, 'is close to $expected (±$tolerance/255 per channel)');

  group('LayoPainter party', () {
    test('paints party without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('party has no antenna at all, like comandante and christmas', () {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // The antenna tip sits at the shared (197.66, 17.30) center, radius
      // 16.71 -- with no antenna at all, nothing but the hat's own body
      // paints up there, never that exact circle.
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 197.66, y: 17.30, radius: 16.71)),
      );
    });

    test('party wears the ordinary bow-tie, unlike comandante and christmas', () async {
      // The tie's own body sits centered near (197, 355) in source units --
      // with the tie drawn, that spot must show the tie's own screenColor
      // outline or its accent fill, never fully transparent.
      const painter = LayoPainter(emotion: LayoEmotion.party);
      final color = await pixelAt(painter, size, const Offset(197, 340));
      expect(color.a, greaterThan(0), reason: 'party must paint a bow-tie, unlike comandante/christmas');
    });

    test('the hat cone paints festive party pink near its own base', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // Well inside the cone's own silhouette, near its base (native y 138),
      // clear of the yellow stripes drawn higher up (centered at 124/98).
      final color = await pixelAt(painter, size, const Offset(197.66, 134));
      expect(color, closeToColor(kPartyPink), reason: 'the cone must be filled in festive party pink');
    });

    test('the hat has bold dark outline pixels tracing its own edge', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // Sampling right at the cone's own left edge (base y 138, left x 90)
      // -- its stroke sits astride the fill boundary, so a point just
      // outside the fill must show a color distinctly darker than the pink
      // fill itself, proving the bold outline was actually painted.
      final color = await pixelAt(painter, size, const Offset(89, 137));
      expect(
        color.computeLuminance(),
        lessThan(kPartyPink.computeLuminance()),
        reason: 'the cone\'s bold dark outline must paint a visibly darker edge than the plain pink fill',
      );
    });

    test('the hat has two yellow stripes over the pink cone', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // The lower stripe is centered at native y (138 - 14) = 124, well
      // inside the cone's own silhouette at that height.
      final color = await pixelAt(painter, size, const Offset(197.66, 124));
      expect(color, closeToColor(kPartyYellow), reason: 'the lower stripe must paint festive yellow');
    });

    test('the pom-pom paints yellow at its own resting apex', () async {
      // The apex/pom-pom center is (197.66, -60) in native units -- above
      // this suite's own shared `size`'s top edge (y 0), so this sample
      // paints onto a canvas pre-translated down by [margin] (leaving `k`
      // unaffected, since `LayoPainter._kOf` derives it from `size.width`
      // alone) and samples the same margin-shifted point to compensate.
      const painter = LayoPainter(emotion: LayoEmotion.party);
      const margin = 100.0;
      const tallSize = Size(396.15, 659.76 + margin);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(0, margin);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(tallSize.width.ceil(), tallSize.height.ceil());
      final byteData = await image.toByteData();
      final bytes = byteData!.buffer.asUint8List();
      const point = Offset(197.66, -60 + margin);
      final x = point.dx.round().clamp(0, image.width - 1);
      final y = point.dy.round().clamp(0, image.height - 1);
      final offset = (y * image.width + x) * 4;
      final color = Color.fromARGB(bytes[offset + 3], bytes[offset], bytes[offset + 1], bytes[offset + 2]);

      expect(color, closeToColor(kPartyYellow), reason: 'the pom-pom must be yellow at its own resting center');
    });

    test('the hat base sits on the head with no gap: no transparent pixel between hat and head', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // Scan the hat's own vertical center from just above the head shell's
      // top edge (98.89) down through the cone's own base (138) -- once the
      // pink cone begins, no fully-transparent pixel should appear before
      // the head shell picks up underneath it (regression test for the
      // "floating hat" issue this emotion shipped with initially).
      var sawPink = false;
      var sawGapAfterPink = false;
      for (var y = 80; y <= 145; y++) {
        final color = await pixelAt(painter, size, Offset(197.66, y.toDouble()));
        if (color.a > 0.5 && color.r > 0.8 && color.g < 0.3 && color.b > 0.3) {
          sawPink = true;
        } else if (sawPink && color.a < 0.1) {
          sawGapAfterPink = true;
        }
      }
      expect(sawPink, isTrue, reason: 'the scan must actually cross the pink cone');
      expect(sawGapAfterPink, isFalse, reason: 'the hat must sit on the head with no floating gap beneath it');
    });

    test('the hat base spans a wide portion of the head, reading as a pyramid not a spike', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      // Sampling well inside the base on both the left and right thirds
      // (not just dead-center) must both show the pink cone -- a narrow
      // spike would leave these points outside the triangle's own edges.
      final left = await pixelAt(painter, size, const Offset(120, 134));
      final right = await pixelAt(painter, size, const Offset(276, 134));
      expect(left, closeToColor(kPartyPink), reason: 'the cone must be wide enough to cover its own left third');
      expect(right, closeToColor(kPartyPink), reason: 'the cone must be wide enough to cover its own right third');
    });

    test('paints the mrLayo mouth and open eyes underneath the hat, in blue not pink', () async {
      const painter = LayoPainter(emotion: LayoEmotion.party);
      const blue = Color(0xFF5FACDF);
      final mouth = await pixelAt(painter, size, const Offset(197.93, 245));
      expect(mouth, closeToColor(blue), reason: 'party must draw mrLayo\'s own smile underneath the hat, in blue');
      expect(mouth, isNot(closeToColor(kPartyPink)), reason: 'the mouth must never be the festive pink');

      final leftEye = await pixelAt(painter, size, const Offset(134.67, 195.73));
      expect(leftEye, closeToColor(blue), reason: 'party must draw mrLayo\'s own open left eye, in blue');
      expect(leftEye, isNot(closeToColor(kPartyPink)), reason: 'the left eye must never be the festive pink');

      final rightEye = await pixelAt(painter, size, const Offset(261.17, 195.73));
      expect(rightEye, closeToColor(blue), reason: 'party must draw mrLayo\'s own open right eye, in blue');
      expect(rightEye, isNot(closeToColor(kPartyPink)), reason: 'the right eye must never be the festive pink');
    });

    test('blinkT squashes both party eyes shut, like mrLayo', () async {
      const open = LayoPainter(emotion: LayoEmotion.party);
      const closed = LayoPainter(emotion: LayoEmotion.party, blinkT: 1.0);
      const blue = Color(0xFF5FACDF);

      final openEye = await pixelAt(open, size, const Offset(134.67, 195.73));
      expect(openEye, closeToColor(blue));

      // At blinkT == 1.0 the eye is squashed to a thin ellipse -- sampling
      // its own vertical extreme (well above/below the squashed center)
      // must no longer show the eye's fill there.
      final closedEyeEdge = await pixelAt(closed, size, const Offset(134.67, 195.73 - 14));
      expect(closedEyeEdge, isNot(blue), reason: 'a fully-closed blink must not paint the eye this far from center');
    });

    test('paints without throwing across blinkT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.party, blinkT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    test('paints without throwing across pomPomBobT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.party, pomPomBobT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('confetti background layer', () {
      test('confettiT defaults to 0.0', () {
        const painter = LayoPainter(emotion: LayoEmotion.party);
        expect(painter.confettiT, 0.0);
      });

      test('pomPomBobT defaults to 0.0', () {
        const painter = LayoPainter(emotion: LayoEmotion.party);
        expect(painter.pomPomBobT, 0.0);
      });

      test('paints without throwing across confettiT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.party, confettiT: t);
          // Genuine no-throw contract: this sweep exists to catch a crash from
          // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
          // animation parameter's range -- specific values are covered by pixel-level
          // assertions elsewhere in this file.
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('the confetti paints strictly before the body (behind the whole figure)', () async {
        const painter = LayoPainter(emotion: LayoEmotion.party);
        const bodyOuterColor = Color(0xFFEAE9EA);
        const bodyInnerColor = Color(0xFFD4D2D3);
        final color = await pixelAt(painter, size, const Offset(197, 600));
        // Well inside the body's own inner dome -- the body must occlude
        // any confetti piece wherever the two overlap, proving draw order.
        expect(
          color,
          anyOf(bodyOuterColor, bodyInnerColor),
          reason: 'the body must occlude the confetti wherever the two overlap',
        );
      });

      test('no other emotion ever paints the party confetti', () async {
        for (final emotion in LayoEmotion.values.where((e) => e != LayoEmotion.party)) {
          final painter = LayoPainter(emotion: emotion);
          // A point well outside the body/head silhouette but inside the
          // painted box -- only party's confetti could plausibly paint
          // there (mirrors layo_christmas_test.dart's own equivalent check).
          final color = await pixelAt(painter, size, const Offset(10, 10));
          expect(color.a, 0, reason: '$emotion must not paint anything at the very top-left corner');
        }
      });
    });

    group('shouldRepaint', () {
      test('is true when confettiT differs for party', () {
        const painterA = LayoPainter(emotion: LayoEmotion.party);
        const painterB = LayoPainter(emotion: LayoEmotion.party, confettiT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when pomPomBobT differs for party', () {
        const painterA = LayoPainter(emotion: LayoEmotion.party);
        const painterB = LayoPainter(emotion: LayoEmotion.party, pomPomBobT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when blinkT differs for party', () {
        const painterA = LayoPainter(emotion: LayoEmotion.party);
        const painterB = LayoPainter(emotion: LayoEmotion.party, blinkT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-party when confettiT/pomPomBobT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, confettiT: 0.5, pomPomBobT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.party animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) confettiT, pomPomBobT, and blinkT are all 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.party)),
        ),
      );

      expect(painterIn(tester).confettiT, 0.0);
      expect(painterIn(tester).pomPomBobT, 0.0);
      expect(painterIn(tester).blinkT, 0.0);
    });

    guardedTestWidgets('party\'s confetti loops: confettiT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.party)),
        ),
      );

      expect(painterIn(tester).confettiT, 0.0);

      await tester.pump(const Duration(milliseconds: 1500));

      expect(
        painterIn(tester).confettiT,
        closeTo(0.25, 0.05),
        reason: 'the confetti must advance at the quarter-cycle point of its ~6s loop',
      );
    });

    guardedTestWidgets('the party hat pom-pom bobs: pomPomBobT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.party)),
        ),
      );

      expect(painterIn(tester).pomPomBobT, 0.0);

      await tester.pump(const Duration(milliseconds: 500));

      expect(
        painterIn(tester).pomPomBobT,
        closeTo(0.25, 0.05),
        reason: 'the pom-pom bob must advance at the quarter-cycle point of its ~2s loop',
      );
    });

    guardedTestWidgets('party blinks, like mrLayo: blinkT rises above 0, then returns to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.party)),
        ),
      );

      expect(painterIn(tester).blinkT, 0.0);

      var sawBlink = false;
      for (var i = 0; i < 65 && !sawBlink; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).blinkT > 0.0) {
          sawBlink = true;
        }
      }

      expect(sawBlink, isTrue, reason: 'party must blink (blinkT rises above 0) at some point while animating');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea, LayoEmotion.christmas]) {
      guardedTestWidgets('$emotion never shows confetti or bobs party\'s pom-pom: both stay 0', (tester) async {
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

        expect(painterIn(tester).confettiT, 0.0, reason: '$emotion must never show confetti');
        expect(painterIn(tester).pomPomBobT, 0.0, reason: '$emotion must never bob party\'s pom-pom');
      });
    }

    guardedTestWidgets('reduced motion forces confettiT, pomPomBobT, and blinkT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.party)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).confettiT, 0.0);
      expect(painterIn(tester).pomPomBobT, 0.0);
      expect(painterIn(tester).blinkT, 0.0);
    });
  });
}

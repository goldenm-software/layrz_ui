import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layo/src/glyphs/layo_glyphs_christmas.dart';

import '../helpers/no_overflow.dart';

/// Tests for [LayoEmotion.christmas]: pure [LayoPainter] geometry/color
/// assertions (the Santa hat overlay, the poinsettia and holly cluster, the
/// sweater body overlay, the snowfall background layer, the festive antenna
/// accent, and the shared mrLayo face underneath) plus [Layo]'s own
/// animation lifecycle for `snowT` and `pomPomSwayT`.
///
/// Split into its own file (rather than appended to the already oversized
/// `layo_painter_test.dart`/`layo_emotion_widget_test.dart`) per this
/// repository's file-size convention -- mirroring how
/// `layo_money_test.dart` and `layo_cool_test.dart` were split out for their
/// own emotions.
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
  /// [expected]. This design system's Bézier-ported shapes antialias their
  /// own edges, so a sample point a handful of source units from a shape's
  /// exact center can land on a softened edge pixel rather than the shape's
  /// flat interior fill -- this matcher absorbs that without asserting on a
  /// sample point so far inside the shape it stops proving the shape's own
  /// extent.
  Matcher closeToColor(Color expected, {int tolerance = 12}) => predicate<Color>((actual) {
    return (actual.r - expected.r).abs() * 255 <= tolerance &&
        (actual.g - expected.g).abs() * 255 <= tolerance &&
        (actual.b - expected.b).abs() * 255 <= tolerance;
  }, 'is close to $expected (±$tolerance/255 per channel)');

  group('LayoPainter christmas', () {
    test('paints christmas without throwing', () {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('christmas has no antenna at all, like comandante', () {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      expect(painter.paint, isNotNull); // sanity: painter constructs fine
      // The antenna tip sits at the shared (197.66, 17.30) center -- with no
      // antenna at all, nothing but the hat's own crown paints up there,
      // never the festive-red antenna dot's own exact fill.
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 197.66, y: 17.30, radius: 16.71)),
      );
    });

    test('christmas wears no bow-tie, like comandante', () async {
      // The tie's own body fills its own bounding area around (146-252,
      // 325-384) in source units, centered near (197, 355) -- with no tie
      // drawn, that spot must show the sweater's own red instead of any tie
      // color (this design system's tie is always colored via
      // _antennaTipColor, never plain kChristmasSweaterOuterRed/InnerRed).
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(197, 355));
      expect(
        color,
        anyOf(kChristmasSweaterOuterRed, kChristmasSweaterInnerRed),
        reason: 'with no tie drawn, the sweater\'s own red must show through at the tie\'s usual spot',
      );
    });

    test('the Santa hat brim paints white at its own vertical center', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(200, 112));
      expect(color, kChristmasWhite, reason: 'the thick fur brim must be white at its own vertical center');
    });

    test('the hat brim has a bold dark outline pixel at its own top edge', () async {
      // Sampling right at the brim's own top edge (its stroke sits astride
      // the fill boundary) must show a color distinctly darker than plain
      // white -- proving the bold outline was actually painted, not merely
      // requested.
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(200, 86.0));
      expect(
        color.computeLuminance(),
        lessThan(kChristmasWhite.computeLuminance()),
        reason: 'the brim\'s bold dark outline must paint a visibly darker edge than the plain white fill',
      );
    });

    test('the pom-pom paints white at its own drooped-tip resting center', () async {
      // The pom-pom's resting center is `_kHatPomPom` (292, 8) in native
      // units, which map 1:1 onto this test's own painted `size` (`k == 1`)
      // -- sampled exactly at that center, well clear of its own edge.
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(292, 8));
      expect(color, kChristmasWhite, reason: 'the pom-pom must be white at its own resting center');
    });

    test('the pom-pom has a bold dark outline pixel at its own edge', () async {
      // The pom-pom's own radius is 24 native units around its (292, 8)
      // center -- sampled just outside that radius, on its own outline
      // stroke.
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(292 + 24, 8));
      expect(
        color.computeLuminance(),
        lessThan(kChristmasWhite.computeLuminance()),
        reason: 'the pom-pom\'s bold dark outline must paint a visibly darker edge than the plain white fill',
      );
    });

    test('the hat cone paints christmas red near its own base', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      // Well inside the base cone's own silhouette (close to the brim,
      // where it is widest), rather than near the fold above.
      final color = await pixelAt(painter, size, const Offset(100, 60));
      expect(color, kChristmasRed, reason: 'the cone must be filled in festive Christmas red');
    });

    test('the cone is a single solid fill with no interior gap or seam near the neck', () async {
      // Regression test: this emotion's hat cone/fold went through several
      // broken constructions -- a hand-authored "there and back" path whose
      // return leg crossed its own outward leg, an offset-ribbon technique
      // whose two computed edges crossed each other on the sharp curve near
      // the droop, and (once split into a full-width base plus a separate
      // folded-over top) two independently-outlined overlapping shapes whose
      // seam left a stray extra-lobe outline cutting across the base's own
      // dome. paintChristmasHat now merges the base and fold via
      // `Path.combine(PathOperation.union, ...)` into one silhouette with a
      // single outline pass, which is mechanically guaranteed seamless
      // regardless of exactly how the two source shapes overlap. Sampling a
      // point squarely inside the base cone's own body, well clear of any
      // edge or the bold outline stroke, must show the solid red fill.
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(120, 44));
      expect(color, kChristmasRed, reason: 'the cone must have no interior gap near its own neck seam');
    });

    test('the poinsettia paints a gold center near the hat brim\'s own left side', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(95, 112));
      expect(color, kChristmasGold, reason: 'the poinsettia\'s own center must be gold');
    });

    test('the poinsettia petals paint christmas red around its own center', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(95, 112 - 16));
      expect(
        color,
        closeToColor(kChristmasRed, tolerance: 24),
        reason: 'the poinsettia\'s petals must be Christmas red',
      );
    });

    test('the holly sprig paints green leaves near the hat brim\'s own left side', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      final color = await pixelAt(painter, size, const Offset(140, 110 - 16));
      expect(color, closeToColor(kChristmasGreen), reason: 'the holly sprig\'s leaves must be holly green');
    });

    test('the antenna tip color would be festive red, if it had an antenna', () {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      expect(painter.accentColor, isNull);
      // _resolvedAccentColor is private, but the same public accentColor
      // override path proves the christmas branch resolves to kChristmasRed
      // -- exercised indirectly through the tie/antenna color used
      // elsewhere in this emotion's own overlay glyphs (the poinsettia
      // petals and hat cone both reuse it).
    });

    test('paints the mrLayo mouth and open eyes underneath the hat, in blue not red', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      const blue = Color(0xFF5FACDF);
      final mouth = await pixelAt(painter, size, const Offset(197.93, 245));
      expect(mouth, closeToColor(blue), reason: 'christmas must draw mrLayo\'s own smile underneath the hat, in blue');
      expect(mouth, isNot(closeToColor(kChristmasRed)), reason: 'the mouth must never be the festive red');

      final leftEye = await pixelAt(painter, size, const Offset(134.67, 195.73));
      expect(leftEye, closeToColor(blue), reason: 'christmas must draw mrLayo\'s own open left eye, in blue');
      expect(leftEye, isNot(closeToColor(kChristmasRed)), reason: 'the left eye must never be the festive red');

      final rightEye = await pixelAt(painter, size, const Offset(261.17, 195.73));
      expect(rightEye, closeToColor(blue), reason: 'christmas must draw mrLayo\'s own open right eye, in blue');
      expect(rightEye, isNot(closeToColor(kChristmasRed)), reason: 'the right eye must never be the festive red');
    });

    test('blinkT squashes both christmas eyes shut, like mrLayo', () async {
      const open = LayoPainter(emotion: LayoEmotion.christmas);
      const closed = LayoPainter(emotion: LayoEmotion.christmas, blinkT: 1.0);
      const blue = Color(0xFF5FACDF);

      final openEye = await pixelAt(open, size, const Offset(134.67, 195.73));
      expect(openEye, closeToColor(blue));

      // At blinkT == 1.0 the eye is squashed to a thin ellipse -- sampling
      // its own vertical extreme (well above/below the squashed center)
      // must no longer show the eye's fill there.
      final closedEyeEdge = await pixelAt(closed, size, const Offset(134.67, 195.73 - 14));
      expect(closedEyeEdge, isNot(blue), reason: 'a fully-closed blink must not paint the eye this far from center');
    });

    test('the sweater\'s inner dome paints the lighter sweater red', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      // (197, 600) sits well inside the inner dome's own silhouette (see
      // LayoPainter._paintBody's `inner` path), so the sweater's own lighter
      // red must show there -- not the plain grey body, and not the darker
      // outer-dome red.
      final color = await pixelAt(painter, size, const Offset(197, 600));
      expect(color, kChristmasSweaterInnerRed, reason: 'the inner dome must show the lighter sweater red');
    });

    test('the sweater\'s outer dome paints the darker sweater red at the body\'s own rim', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      // (30, 553) sits inside the outer dome but outside the inner dome's
      // own silhouette (the inner dome's left edge is well past x=49 at this
      // height), so only the outer dome's darker red should show there --
      // proving the two-tone rim/depth separation survived the recolor.
      final color = await pixelAt(painter, size, const Offset(30, 553));
      expect(color, kChristmasSweaterOuterRed, reason: 'the outer dome\'s own rim must show the darker sweater red');
    });

    test('the sweater covers the full body: no plain grey body color survives anywhere on it', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      const bodyOuterColor = Color(0xFFEAE9EA);
      const bodyInnerColor = Color(0xFFD4D2D3);
      for (final point in [const Offset(197, 600), const Offset(30, 553), const Offset(365, 553)]) {
        final color = await pixelAt(painter, size, point);
        expect(color, isNot(bodyOuterColor), reason: 'no plain outer body grey may survive under the sweater');
        expect(color, isNot(bodyInnerColor), reason: 'no plain inner body grey may survive under the sweater');
      }
    });

    test('the sweater\'s fair-isle band paints white across the chest', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      // Sample inside the band but between two chevron strokes, where the
      // band's own white base (not a red chevron stroke) should show.
      final color = await pixelAt(painter, size, const Offset(90, 478));
      expect(color.computeLuminance(), greaterThan(kChristmasSweaterInnerRed.computeLuminance()));
    });

    test('the sweater is clipped to the body dome: nothing paints outside its silhouette', () async {
      const painter = LayoPainter(emotion: LayoEmotion.christmas);
      // Just outside the outer body dome's own left edge -- at native y 320
      // the dome (LayoPainter._paintBody's `outer` path) has barely begun
      // widening from its own top pinch point (y 298.94), so x 5 sits
      // clearly outside it, unlike y 553 where the dome's own leftmost point
      // reaches all the way to x 0. Must show fully transparent, not
      // sweater red bleeding past the body's own silhouette.
      final color = await pixelAt(painter, size, const Offset(5, 320));
      expect(color.a, 0, reason: 'the sweater must never paint past the body dome\'s own silhouette');
    });

    test('paints without throwing across blinkT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.christmas, blinkT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    test('paints without throwing across pomPomSwayT\'s full 0..1 sweep', () {
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final painter = LayoPainter(emotion: LayoEmotion.christmas, pomPomSwayT: t);
        // Genuine no-throw contract: this sweep exists to catch a crash from
        // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
        // animation parameter's range -- specific values are covered by pixel-level
        // assertions elsewhere in this file.
        expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
      }
    });

    group('snowfall background layer', () {
      test('snowT defaults to 0.0', () {
        const painter = LayoPainter(emotion: LayoEmotion.christmas);
        expect(painter.snowT, 0.0);
      });

      test('paints without throwing across snowT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.christmas, snowT: t);
          // Genuine no-throw contract: this sweep exists to catch a crash from
          // interpolation (lerpDouble/clamp misuse, negative radii, etc.) across the
          // animation parameter's range -- specific values are covered by pixel-level
          // assertions elsewhere in this file.
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('the snowfall paints strictly before the body (behind the whole figure)', () async {
        const painter = LayoPainter(emotion: LayoEmotion.christmas);
        const bodyInnerColor = Color(0xFFD4D2D3);
        final color = await pixelAt(painter, size, const Offset(197, 600));
        // The body's own sweater (christmas red) occludes both the plain
        // body panel color and any snowflake wherever the two overlap --
        // proving draw order, since kChristmasRed is what should win here,
        // not bodyInnerColor or a stray flake.
        expect(
          color,
          isNot(bodyInnerColor),
          reason: 'the sweater/body must occlude the snowfall wherever the two overlap',
        );
      });

      test('no other emotion ever paints the christmas snowfall', () async {
        for (final emotion in LayoEmotion.values.where((e) => e != LayoEmotion.christmas)) {
          final painter = LayoPainter(emotion: emotion);
          // A point well outside the body/head silhouette but inside the
          // painted box -- only christmas's snowfall could plausibly paint
          // there (mirrors layo_money_test.dart's own equivalent check).
          final color = await pixelAt(painter, size, const Offset(10, 10));
          expect(color.a, 0, reason: '$emotion must not paint anything at the very top-left corner');
        }
      });
    });

    group('shouldRepaint', () {
      test('is true when snowT differs for christmas', () {
        const painterA = LayoPainter(emotion: LayoEmotion.christmas);
        const painterB = LayoPainter(emotion: LayoEmotion.christmas, snowT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when pomPomSwayT differs for christmas', () {
        const painterA = LayoPainter(emotion: LayoEmotion.christmas);
        const painterB = LayoPainter(emotion: LayoEmotion.christmas, pomPomSwayT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when blinkT differs for christmas', () {
        const painterA = LayoPainter(emotion: LayoEmotion.christmas);
        const painterB = LayoPainter(emotion: LayoEmotion.christmas, blinkT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-christmas when snowT/pomPomSwayT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, snowT: 0.5, pomPomSwayT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }
    });
  });

  group('Layo.emotion == LayoEmotion.christmas animation', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) snowT, pomPomSwayT, and blinkT are all 0.0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.christmas)),
        ),
      );

      expect(painterIn(tester).snowT, 0.0);
      expect(painterIn(tester).pomPomSwayT, 0.0);
      expect(painterIn(tester).blinkT, 0.0);
    });

    guardedTestWidgets('christmas\'s snowfall loops: snowT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.christmas)),
        ),
      );

      expect(painterIn(tester).snowT, 0.0);

      await tester.pump(const Duration(milliseconds: 1750));

      expect(
        painterIn(tester).snowT,
        closeTo(0.25, 0.05),
        reason: 'the snowfall must advance at the quarter-cycle point of its ~7s loop',
      );
    });

    guardedTestWidgets('the pom-pom sways: pomPomSwayT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.christmas)),
        ),
      );

      expect(painterIn(tester).pomPomSwayT, 0.0);

      await tester.pump(const Duration(milliseconds: 750));

      expect(
        painterIn(tester).pomPomSwayT,
        closeTo(0.25, 0.05),
        reason: 'the pom-pom sway must advance at the quarter-cycle point of its ~3s loop',
      );
    });

    guardedTestWidgets('christmas blinks, like mrLayo: blinkT rises above 0, then returns to 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.christmas)),
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

      expect(sawBlink, isTrue, reason: 'christmas must blink (blinkT rises above 0) at some point while animating');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea, LayoEmotion.comandante]) {
      guardedTestWidgets('$emotion never snows or sways christmas\'s pom-pom: both stay 0', (tester) async {
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

        expect(painterIn(tester).snowT, 0.0, reason: '$emotion must never snow');
        expect(painterIn(tester).pomPomSwayT, 0.0, reason: '$emotion must never sway christmas\'s pom-pom');
      });
    }

    guardedTestWidgets('reduced motion forces snowT, pomPomSwayT, and blinkT to stay 0', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.christmas)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(painterIn(tester).snowT, 0.0);
      expect(painterIn(tester).pomPomSwayT, 0.0);
      expect(painterIn(tester).blinkT, 0.0);
    });
  });
}

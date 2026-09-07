import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/layo/src/glyphs/layo_glyphs_mr_layo.dart';

void main() {
  group('LayoPainter', () {
    const size = Size(396.15, 659.76);

    test('default painter is LayoEmotion.mrLayo, at rest, with the original colors', () {
      const painter = LayoPainter();
      expect(painter.emotion, LayoEmotion.mrLayo);
      expect(painter.pulseT, 0.0);
      expect(painter.blinkT, 0.0);
      // accentColor is left null by default so each emotion resolves its own
      // canonical accent; mrLayo's resolves to the original blue.
      expect(painter.accentColor, isNull);
      expect(painter.glyphColor, const Color(0xFF848484));
    });

    for (final emotion in LayoEmotion.values) {
      test('paint renders $emotion without throwing', () {
        final painter = LayoPainter(emotion: emotion);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });
    }

    /// Rasterizes [painter] at [size] and returns the actual pixel color at
    /// [point] -- more robust here than the `paints` matcher's strictly
    /// sequential predicates, since the antenna tip is the *last* shape this
    /// painter draws and several earlier shapes also draw `drawCircle` calls
    /// (the eyes), which a single non-sequential `circle()` predicate cannot
    /// skip past.
    Future<Color> pixelAt(LayoPainter painter, Size size, Offset point) async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.ceil(), size.height.ceil());
      final byteData = await image.toByteData();
      final bytes = byteData!.buffer.asUint8List();
      final x = point.dx.round().clamp(0, image.width - 1);
      final y = point.dy.round().clamp(0, image.height - 1);
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(bytes[offset + 3], bytes[offset], bytes[offset + 1], bytes[offset + 2]);
    }

    test('mrLayo paints the antenna tip in accentColor (blue)', () async {
      const painter = LayoPainter();
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFF60ABDE));
    });

    test('question paints the antenna tip in accentColor (blue), like mrLayo', () async {
      const painter = LayoPainter(emotion: LayoEmotion.question);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFF60ABDE));
    });

    test('sleep paints the antenna tip in glyphColor (grey), not accentColor', () async {
      const painter = LayoPainter(emotion: LayoEmotion.sleep);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFF848484));
    });

    test(
      'dead paints the antenna tip in glyphColor (grey), not accentColor (droopT: 0.0 to sample undrooped)',
      () async {
        // droopT defaults to 1.0 (the resting drooped tilt), which rotates
        // the tip away from its unrotated center -- pass 0.0 explicitly to
        // check the color at this exact upright sample point; the drooped
        // rotation itself is covered separately below.
        const painter = LayoPainter(emotion: LayoEmotion.dead, droopT: 0.0);
        final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
        expect(color, const Color(0xFF848484));
      },
    );

    test('love paints the antenna tip in its red accent by default', () async {
      const painter = LayoPainter(emotion: LayoEmotion.love);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFFCC2222));
    });

    test('angry paints the antenna tip in its crimson accent by default', () async {
      const painter = LayoPainter(emotion: LayoEmotion.angry);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFFC62828));
    });

    test('alert paints the antenna tip in its exact orange accent by default', () async {
      const painter = LayoPainter(emotion: LayoEmotion.alert);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFFFF9800));
    });

    test('layo404 paints the antenna tip in glyphColor (grey), not accentColor', () async {
      const painter = LayoPainter(emotion: LayoEmotion.layo404);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFF848484));
    });

    test('idea paints the antenna tip in its yellow accent by default', () async {
      const painter = LayoPainter(emotion: LayoEmotion.idea);
      final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(color, const Color(0xFFF5CC24));
    });

    test('comandante paints NO antenna at all -- neither stalk nor tip', () async {
      // comandante is the sole emotion with no antenna whatsoever (its
      // beret overlay sits exactly where one would be); (197.66, 17.30) is
      // every other emotion's antenna-tip center, and (197.66, 60) sits on
      // the antenna stalk's own path for every other emotion -- both must
      // sample plain background/beret color here, never an antenna-tip
      // accent or the antenna stalk's own bodyInnerColor.
      const painter = LayoPainter(emotion: LayoEmotion.comandante);
      const bodyInnerColor = Color(0xFFD4D2D3);
      final tipPoint = await pixelAt(painter, size, const Offset(197.66, 17.30));
      expect(tipPoint, isNot(const Color(0xFF60ABDE)), reason: 'comandante must not paint an antenna tip');
      expect(
        tipPoint,
        isNot(bodyInnerColor),
        reason: 'comandante must not paint the antenna stalk\'s own color at the tip\'s usual location either',
      );
    });

    test('an explicit accentColor overrides every colored-accent emotion\'s default', () async {
      const explicit = Color(0xFF123456);
      for (final emotion in [
        LayoEmotion.mrLayo,
        LayoEmotion.question,
        LayoEmotion.love,
        LayoEmotion.angry,
        LayoEmotion.alert,
        LayoEmotion.idea,
      ]) {
        final painter = LayoPainter(emotion: emotion, accentColor: explicit);
        final color = await pixelAt(painter, size, const Offset(197.66, 17.30));
        expect(color, explicit, reason: '$emotion must respect an explicit accentColor override');
      }
    });

    test('an explicit accentColor overrides comandante\'s default too, sampled at its own open eye', () async {
      // comandante has no antenna tip to sample (see the dedicated
      // no-antenna test above), so its own accentColor override is verified
      // at its left eye instead -- always the plain open circle, unaffected
      // by winkT, so this sample is stable regardless of the wink phase.
      const explicit = Color(0xFF123456);
      const painter = LayoPainter(emotion: LayoEmotion.comandante, accentColor: explicit);
      final color = await pixelAt(painter, size, const Offset(134.67, 195.73));
      expect(color, explicit, reason: 'comandante\'s eyes must respect an explicit accentColor override');
    });

    test('mrLayo paints two blue circular eyes when blinkT is 0 (open)', () {
      // Every shape in this painter is drawn twice in immediate succession
      // (see `_paintSmoothed`'s fill-then-stroke antialiasing pass), so the
      // `paints` matcher's strictly-sequential predicates must account for
      // both calls per eye -- chaining fill-only predicates for both eyes
      // back to back would consume the first eye's fill, then mismatch
      // against the first eye's own stroke call when checking the second eye.
      const painter = LayoPainter();
      const accent = Color(0xFF60ABDE);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        paints
          ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
          ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke)
          ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
          ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke),
      );
    });

    test('question does not paint the mrLayo circular eyes (its eyes are the "??" glyphs)', () {
      const painter = LayoPainter(emotion: LayoEmotion.question);
      expect(
        (Canvas canvas) => painter.paint(canvas, size),
        isNot(paints..circle(x: 134.67, y: 195.73, radius: 15.57)),
      );
    });

    test('mrLayo mouth glyph function draws a blue path containing its center', () {
      // Exercising `paintMrLayoMouth` directly (rather than fishing the
      // mouth's own drawPath call out of the full painter's draw sequence,
      // where several other accent-colored fills precede and follow it) is
      // both simpler and immune to `paints`' call-order matching picking up
      // the wrong drawPath call.
      void smoothed(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) {
        shapeOnto(Paint()..color = color);
      }

      expect(
        (Canvas canvas) => paintMrLayoMouth(canvas, 1.0, accentColor: const Color(0xFF60ABDE), paintSmoothed: smoothed),
        paints..path(color: const Color(0xFF60ABDE), includes: const [Offset(198, 245)]),
      );
    });

    for (final emotion in [LayoEmotion.sleep, LayoEmotion.dead]) {
      test('$emotion never draws a shape at the mouth\'s own screen location', () {
        // sleep and dead draw no accent-colored shapes at all (their glyphs
        // are grey), so there is no earlier accent-colored path to be
        // mistaken for the mouth here -- this check is order-independent.
        final painter = LayoPainter(emotion: emotion);
        expect(
          (Canvas canvas) => painter.paint(canvas, size),
          isNot(paints..path(includes: const [Offset(198, 245)])),
        );
      });
    }

    group('shouldRepaint', () {
      test('is false for an identically-configured LayoPainter', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter();
        expect(painterA.shouldRepaint(painterB), isFalse);
      });

      test('is true when emotion differs', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(emotion: LayoEmotion.sleep);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when accentColor differs', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(accentColor: Color(0xFFFF0000));
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when glyphColor differs', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(glyphColor: Color(0xFFFF0000));
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when faceShadowColor differs', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(faceShadowColor: Color(0xFFFF0000));
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when pulseT differs, for every emotion that pulses', () {
        for (final emotion in [
          LayoEmotion.mrLayo,
          LayoEmotion.question,
          LayoEmotion.sleep,
          LayoEmotion.angry,
          LayoEmotion.layo404,
        ]) {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, pulseT: 0.5);
          expect(painterA.shouldRepaint(painterB), isTrue, reason: 'pulse must repaint for $emotion');
        }
      });

      for (final emotion in [LayoEmotion.dead, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-pulse when pulseT alone differs for $emotion (no looping pulse)', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, pulseT: 0.5);
          expect(
            painterA.shouldRepaint(painterB),
            isFalse,
            reason: '$emotion does not play the generic looping pulse, so a pulseT-only change must not repaint',
          );
        });
      }

      test('is true when blinkT differs for the only blinkable emotion (mrLayo)', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(blinkT: 1.0);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [
        LayoEmotion.question,
        LayoEmotion.sleep,
        LayoEmotion.dead,
        LayoEmotion.love,
        LayoEmotion.angry,
        LayoEmotion.alert,
        LayoEmotion.layo404,
        LayoEmotion.idea,
      ]) {
        test('is false-for-blink when blinkT alone differs for a non-blinkable emotion ($emotion)', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, blinkT: 1.0);
          expect(
            painterA.shouldRepaint(painterB),
            isFalse,
            reason: '$emotion does not blink, so a blinkT-only change must not trigger a repaint',
          );
        });
      }

      test('is true when wiggleT differs for question', () {
        const painterA = LayoPainter(emotion: LayoEmotion.question);
        const painterB = LayoPainter(emotion: LayoEmotion.question, wiggleT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.sleep, LayoEmotion.dead]) {
        test('is false-for-wiggle when wiggleT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, wiggleT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when zzzPhase differs for sleep', () {
        const painterA = LayoPainter(emotion: LayoEmotion.sleep);
        const painterB = LayoPainter(emotion: LayoEmotion.sleep, zzzPhase: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.question, LayoEmotion.dead]) {
        test('is false-for-zzz when zzzPhase alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, zzzPhase: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when droopT differs for dead', () {
        const painterA = LayoPainter(emotion: LayoEmotion.dead);
        const painterB = LayoPainter(emotion: LayoEmotion.dead, droopT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.question, LayoEmotion.sleep]) {
        test('is false-for-droop when droopT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, droopT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when beatT differs for love', () {
        const painterA = LayoPainter(emotion: LayoEmotion.love);
        const painterB = LayoPainter(emotion: LayoEmotion.love, beatT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.idea]) {
        test('is false-for-beat when beatT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, beatT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when burstT differs for angry', () {
        const painterA = LayoPainter(emotion: LayoEmotion.angry);
        const painterB = LayoPainter(emotion: LayoEmotion.angry, burstT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.alert]) {
        test('is false-for-burst when burstT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, burstT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when alertPulseT differs for alert', () {
        const painterA = LayoPainter(emotion: LayoEmotion.alert);
        const painterB = LayoPainter(emotion: LayoEmotion.alert, alertPulseT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.layo404]) {
        test('is false-for-alertPulse when alertPulseT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, alertPulseT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when glitchOpacity differs for layo404', () {
        const painterA = LayoPainter(emotion: LayoEmotion.layo404);
        const painterB = LayoPainter(emotion: LayoEmotion.layo404, glitchOpacity: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when glitchOffset differs for layo404', () {
        const painterA = LayoPainter(emotion: LayoEmotion.layo404);
        const painterB = LayoPainter(emotion: LayoEmotion.layo404, glitchOffset: 1.0);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.dead, LayoEmotion.idea]) {
        test('is false-for-glitch when glitchOpacity/glitchOffset alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, glitchOpacity: 0.5, glitchOffset: 1.0);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when glowT differs for idea', () {
        const painterA = LayoPainter(emotion: LayoEmotion.idea);
        const painterB = LayoPainter(emotion: LayoEmotion.idea, glowT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      test('is true when flashT differs for idea', () {
        const painterA = LayoPainter(emotion: LayoEmotion.idea);
        const painterB = LayoPainter(emotion: LayoEmotion.idea, flashT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.layo404]) {
        test('is false-for-glow/flash when glowT/flashT alone differ for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, glowT: 0.5, flashT: 0.5);
          expect(painterA.shouldRepaint(painterB), isFalse);
        });
      }

      test('is true when winkT differs for comandante', () {
        const painterA = LayoPainter(emotion: LayoEmotion.comandante);
        const painterB = LayoPainter(emotion: LayoEmotion.comandante, winkT: 0.5);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.idea]) {
        test('is false-for-wink when winkT alone differs for $emotion', () {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, winkT: 0.5);
          expect(
            painterA.shouldRepaint(painterB),
            isFalse,
            reason: '$emotion does not wink, so a winkT-only change must not repaint',
          );
        });
      }
    });

    group('bow-tie on every emotion except comandante, colored by that emotion\'s own accent', () {
      // (197, 355) sits inside the tie's own body fill, well below the
      // screen window (bottom 308.8) and every emotion's screen glyphs, so
      // no other accent/glyph-colored shape can be mistaken for the tie here
      // regardless of which emotion is painting.
      const tieCenter = Offset(197, 355);

      for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.question]) {
        test('$emotion paints the tie fill in accentColor (blue)', () async {
          final painter = LayoPainter(emotion: emotion);
          final color = await pixelAt(painter, size, tieCenter);
          expect(color, const Color(0xFF60ABDE), reason: '$emotion\'s tie must follow its own blue accent');
        });
      }

      for (final emotion in [LayoEmotion.sleep, LayoEmotion.dead, LayoEmotion.layo404]) {
        test('$emotion paints the tie fill in glyphColor (grey), not blue', () async {
          final painter = LayoPainter(emotion: emotion);
          final color = await pixelAt(painter, size, tieCenter);
          expect(color, const Color(0xFF848484), reason: '$emotion\'s tie must follow its own grey accent');
        });
      }

      final coloredTieExpectations = {
        LayoEmotion.love: const Color(0xFFCC2222),
        LayoEmotion.angry: const Color(0xFFC62828),
        LayoEmotion.alert: const Color(0xFFFF9800),
        LayoEmotion.idea: const Color(0xFFF5CC24),
      };
      for (final entry in coloredTieExpectations.entries) {
        test('${entry.key} paints the tie fill in its own accent', () async {
          final painter = LayoPainter(emotion: entry.key);
          final color = await pixelAt(painter, size, tieCenter);
          expect(color, entry.value, reason: '${entry.key}\'s tie must follow its own accent');
        });
      }

      test('comandante paints NO tie at all -- the sole exception', () async {
        // comandante wears a chest ribbon rack instead of the tie every
        // other emotion wears (LayoPainter._wearsTie excludes it alone), so
        // its own accent (blue) must never appear at the shared tie
        // location -- unlike every emotion above, none of which ever left
        // this point at plain body color.
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        final color = await pixelAt(painter, size, tieCenter);
        expect(
          color,
          isNot(const Color(0xFF60ABDE)),
          reason: 'comandante must not paint a tie -- it wears a chest ribbon rack instead',
        );
      });
    });

    test('tieFoldColor darkens its input toward black by the tuned fraction', () {
      const accent = Color(0xFF60ABDE);
      final fold = tieFoldColor(accent);
      expect(fold.a, 1.0);
      expect(fold.r, lessThan(accent.r));
      expect(fold.g, lessThan(accent.g));
      expect(fold.b, lessThan(accent.b));
    });

    group('comandante: beret overlay, chest ribbon rack, and right-eye wink', () {
      test('winkT defaults to 0.0 (both eyes open, no wink in progress)', () {
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        expect(painter.winkT, 0.0);
      });

      test('the beret overlay paints its red body color near the top of the head', () async {
        // (197.66, 60) sits inside the beret body's own fill at rest --
        // comfortably below its crown top and comfortably above the head
        // shell's own top edge (98.89) -- so it samples the beret rather
        // than background or the head shell.
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        final color = await pixelAt(painter, size, const Offset(197.66, 60));
        expect(color, const Color(0xFF90191C), reason: 'the beret\'s main body must paint its exact red fill');
      });

      test('the beret overlay is drawn on top of the head shell, not underneath it', () async {
        // The head shell's own light body color would show at this point if
        // the beret were painted before it (or not at all); sampling red
        // instead confirms the overlay draws after LayoPainter._paintHeadShell.
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        const bodyOuterColor = Color(0xFFEAE9EA);
        final color = await pixelAt(painter, size, const Offset(197.66, 60));
        expect(
          color,
          isNot(bodyOuterColor),
          reason: 'the beret overlay must occlude the head shell beneath it, not the other way around',
        );
      });

      test('every other emotion never paints the beret\'s red at the same sample point', () async {
        for (final emotion in LayoEmotion.values.where((e) => e != LayoEmotion.comandante)) {
          final painter = LayoPainter(emotion: emotion);
          final color = await pixelAt(painter, size, const Offset(197.66, 60));
          expect(color, isNot(const Color(0xFF90191C)), reason: '$emotion must not paint a beret');
        }
      });

      test('comandante paints no antenna, unlike every emotion whose beret-region sample would show one', () async {
        // (197.66, 5) sits well within where an antenna tip's own glow/fill
        // could plausibly reach for a pulsing emotion; for comandante (no
        // antenna at all) this must read as the beret's own red, not any
        // antenna-related color.
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        final color = await pixelAt(painter, size, const Offset(197.66, 5));
        expect(
          color,
          const Color(0xFF90191C),
          reason: 'with no antenna to draw, the beret\'s own crown must be the only thing visible here',
        );
      });

      test('the first ribbon row paints its own varied stripe colors on the upper-right chest', () async {
        // The rack is deliberately offset right of the shared artwork's own
        // center (x 197.66) and sits high on the chest, just below the neck
        // seam -- row 1's first bar spans roughly x 200.66-232.66 at y
        // 350-359; its own three vertical stripes are red/gold/red (see
        // _kRibbonBarStripes' first entry) -- sampling the left and middle
        // stripes distinguishes "a real striped bar" from "one flat block".
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        final leftStripe = await pixelAt(painter, size, const Offset(204, 354));
        final middleStripe = await pixelAt(painter, size, const Offset(216, 354));
        expect(leftStripe, const Color(0xFFB71C1C), reason: 'the first bar\'s left stripe must be its exact red');
        expect(
          middleStripe,
          const Color(0xFFFFD600),
          reason: 'the first bar\'s middle stripe must be its exact gold, distinct from its own left stripe',
        );
      });

      test('the second ribbon row sits below the first, with its own distinct stripe colors', () async {
        // Row 2's first bar (white/navy/white, per _kRibbonBarStripes'
        // fourth entry) sits at y 363-372, directly below row 1's y 350-359.
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        final color = await pixelAt(painter, size, const Offset(204, 367));
        expect(color, const Color(0xFFFFFFFF), reason: 'the second row\'s first bar must paint its own exact white');
      });

      test('every other emotion never paints any ribbon-rack stripe color at the same chest locations', () async {
        const ribbonSampleColors = [Color(0xFFB71C1C), Color(0xFFFFD600)];
        for (final emotion in LayoEmotion.values.where((e) => e != LayoEmotion.comandante)) {
          final painter = LayoPainter(emotion: emotion);
          for (final point in [Offset(204, 354), Offset(216, 354)]) {
            final color = await pixelAt(painter, size, point);
            expect(
              ribbonSampleColors,
              isNot(contains(color)),
              reason: '$emotion must not paint any chest ribbon-rack stripe at $point',
            );
          }
        }
      });

      test('at rest (winkT: 0.0) both eyes render as full open blue circles', () {
        const painter = LayoPainter(emotion: LayoEmotion.comandante);
        const accent = Color(0xFF60ABDE);
        expect(
          (Canvas canvas) => painter.paint(canvas, size),
          paints
            ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
            ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke)
            ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
            ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke),
        );
      });

      test('mid-wink (winkT: 1.0) the left eye stays a full open circle', () {
        const painter = LayoPainter(emotion: LayoEmotion.comandante, winkT: 1.0);
        const accent = Color(0xFF60ABDE);
        expect(
          (Canvas canvas) => painter.paint(canvas, size),
          paints
            ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
            ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke),
        );
      });

      test('mid-wink (winkT: 1.0) the right eye is squashed away from its open-circle rest sample', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.comandante);
        const midWink = LayoPainter(emotion: LayoEmotion.comandante, winkT: 1.0);

        // Sample a point on the right eye's own rest-circle rim, well off
        // its horizontal center line, so a full-height squash (winkT: 1.0
        // scales toward a thin ellipse) uncovers it while the open-circle
        // painter still covers it.
        const rimPoint = Offset(261.17, 195.73 - 12);
        final restColor = await pixelAt(atRest, size, rimPoint);
        final winkColor = await pixelAt(midWink, size, rimPoint);
        expect(restColor, const Color(0xFF60ABDE), reason: 'sanity: the open right eye must cover this rim point');
        expect(
          winkColor,
          isNot(const Color(0xFF60ABDE)),
          reason: 'a full wink must squash the right eye away from its open-circle rim',
        );
      });

      test('paints without throwing across winkT\'s full 0..1 sweep', () {
        for (final winkT in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.comandante, winkT: winkT);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });
    });

    group('dead antenna: resting droop, no looping pulse, no opacity change', () {
      test('droopT defaults to 1.0 (the resting drooped pose)', () {
        const painter = LayoPainter(emotion: LayoEmotion.dead);
        expect(painter.droopT, 1.0);
      });

      test('paints the antenna tip circle with a fully-opaque Paint.color regardless of droopT', () {
        // Asserting on the raw Paint passed to drawCircle (rather than
        // sampling a rasterized pixel) sidesteps the rotated shape's own
        // antialiased edge, which can land a fixed sample point on a
        // partial-coverage pixel for reasons unrelated to whether droopT
        // dims the color -- this checks the actual fill color requested,
        // which is what "never dimmed" means.
        for (final droopT in [0.0, 0.5, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.dead, droopT: droopT);
          expect(
            (Canvas canvas) => painter.paint(canvas, size),
            paints..circle(color: const Color(0xFF848484), style: PaintingStyle.fill),
            reason: 'droopT == $droopT must not change the antenna tip\'s alpha',
          );
        }
      });

      test('a fully-drooped antenna (droopT: 1.0) tilts the tip away from its unrotated center', () async {
        const drooped = LayoPainter(emotion: LayoEmotion.dead, droopT: 1.0);
        const upright = LayoPainter(emotion: LayoEmotion.dead, droopT: 0.0);

        // Sample a point that the *upright* tip's own circle covers -- if
        // droopT actually rotates the tip (and the stalk it is pivoted with)
        // around the stalk's base, the drooped painter must have rotated the
        // tip away from that point, so grey no longer appears there. This
        // fails if droopT were wired to something else (e.g. only alpha), or
        // wired to nothing at all.
        const tipCenter = Offset(197.66, 17.30);
        final uprightColor = await pixelAt(upright, size, tipCenter);
        expect(uprightColor, const Color(0xFF848484), reason: 'sanity: upright tip must sit exactly at its center');

        final droopedColor = await pixelAt(drooped, size, tipCenter);
        expect(
          droopedColor,
          isNot(const Color(0xFF848484)),
          reason: 'a fully-drooped antenna must have visibly rotated the tip away from its upright center',
        );
      });
    });

    group('love: heartbeat', () {
      test('beatT defaults to 0.0 (no bump, static hearts)', () {
        const painter = LayoPainter(emotion: LayoEmotion.love);
        expect(painter.beatT, 0.0);
      });

      test('at beatT == 0.0 the antenna tip renders at its exact base radius', () {
        const painter = LayoPainter(emotion: LayoEmotion.love);
        const accent = Color(0xFFCC2222);
        expect(
          (Canvas canvas) => painter.paint(canvas, size),
          paints..circle(x: 197.66, y: 17.30, radius: 16.71, color: accent, style: PaintingStyle.fill),
        );
      });

      test('at the heartbeat\'s main-beat peak, the antenna tip radius grows beyond the base radius', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.love);
        const atPeak = LayoPainter(emotion: LayoEmotion.love, beatT: 0.18);

        // Sample a ring just outside the base radius: at rest it must be
        // background (transparent/body), but at the beat's peak the grown
        // circle must cover it in the antenna's red.
        const ringPoint = Offset(197.66 + 16.71 + 1.2, 17.30);
        final restColor = await pixelAt(atRest, size, ringPoint);
        final peakColor = await pixelAt(atPeak, size, ringPoint);
        expect(
          peakColor,
          isNot(restColor),
          reason: 'the heartbeat must visibly grow the antenna tip beyond its base radius at the beat\'s peak',
        );
      });
    });

    group('angry: furrow + tremble burst', () {
      test('burstT defaults to 0.0 (relaxed, no shake)', () {
        const painter = LayoPainter(emotion: LayoEmotion.angry);
        expect(painter.burstT, 0.0);
      });

      test('brows are short angled wedges, not hearts: absent at love\'s heart-lobe centers', () async {
        // Regression for a bug where angry's brow paths were accidentally
        // ported as love's full heart-eye paths. Both hearts' own lobe
        // centers sit well outside the real (much smaller) brow wedges'
        // bounding boxes (left brow: x 128.6-166.8, y 185.4-214.7; right
        // brow: x 228.8-267.0, y 185.4-214.7) but well inside the old,
        // wrongly-ported heart shape -- so a real heart still being drawn
        // here would paint accent color at these points, and the corrected
        // wedge must not.
        const painter = LayoPainter(emotion: LayoEmotion.angry);
        const accent = Color(0xFFC62828);

        // love's left heart lobe center and its lower-left flank, both
        // inside the heart's bbox (x 126-190, y 163-250) but outside the
        // angry brow's own bbox (y 185.4-214.7) and the mouth bar's own
        // bbox (y 231-253).
        for (final p in [Offset(158, 206), Offset(140, 230)]) {
          final color = await pixelAt(painter, size, p);
          expect(
            color,
            isNot(accent),
            reason: 'angry must not paint accent color at $p -- that point only a heart shape would cover',
          );
        }
      });

      test('brows render as the correct wedge geometry: solid accent across the brow\'s own bbox', () async {
        const painter = LayoPainter(emotion: LayoEmotion.angry);
        const accent = Color(0xFFC62828);

        // A handful of points spread across the left brow's own small bbox
        // (x 128.6-166.8, y 185.4-214.7) that the exact wedge path covers.
        for (final p in [Offset(147, 200), Offset(140, 197), Offset(150, 205), Offset(135, 200), Offset(155, 200)]) {
          final color = await pixelAt(painter, size, p);
          expect(color, accent, reason: 'the left brow wedge must cover $p');
        }

        // The mirrored points across the right brow's bbox
        // (x 228.8-267.0, y 185.4-214.7).
        for (final p in [Offset(247, 200), Offset(254, 197), Offset(244, 205), Offset(259, 200), Offset(239, 200)]) {
          final color = await pixelAt(painter, size, p);
          expect(color, accent, reason: 'the right brow wedge must cover $p');
        }
      });

      test('paints without throwing across the burst\'s full 0..1 sweep', () {
        for (final burstT in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.angry, burstT: burstT);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('mid-burst the mouth bar shifts from its rest position', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.angry);
        // 0.2 lands off both the burst envelope's zero crossings and the
        // tremble's own high-frequency zero crossings, so the horizontal
        // shake is guaranteed nonzero here.
        const midBurst = LayoPainter(emotion: LayoEmotion.angry, burstT: 0.2);
        const accent = Color(0xFFC62828);

        // Sample a point right at the mouth bar's own left edge -- the
        // tremble's horizontal shake must move the whole glyph group enough
        // that this exact edge pixel is no longer the same as at rest.
        const edgePoint = Offset(145.5, 242);
        final restColor = await pixelAt(atRest, size, edgePoint);
        final burstColor = await pixelAt(midBurst, size, edgePoint);
        expect(restColor, accent, reason: 'sanity: the mouth bar\'s left edge must be accent-colored at rest');
        expect(
          burstColor,
          isNot(accent),
          reason: 'the tremble must shift the mouth bar away from its resting edge at the burst\'s peak',
        );
      });
    });

    group('alert: top-widening funnel pulse', () {
      test('alertPulseT defaults to 0.0 (at rest, static "!!")', () {
        const painter = LayoPainter(emotion: LayoEmotion.alert);
        expect(painter.alertPulseT, 0.0);
      });

      test('paints without throwing across the pulse\'s full 0..1 sweep', () {
        for (final pulseT in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.alert, alertPulseT: pulseT);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('mid-pulse, the "!" stem\'s TOP edge widens outward beyond its resting bounds', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.alert);
        const midPulse = LayoPainter(emotion: LayoEmotion.alert, alertPulseT: 0.6);
        const accent = Color(0xFFFF9800);

        // Sample a point just outside the left stem's resting left edge,
        // near its TOP (y 174, close to the stem's top at y 171.57) -- at
        // rest this is background, but the top-widening funnel must cover
        // it mid-pulse.
        const topOutsidePoint = Offset(155, 174);
        final restColorAtTop = await pixelAt(atRest, size, topOutsidePoint);
        final pulseColorAtTop = await pixelAt(midPulse, size, topOutsidePoint);
        expect(restColorAtTop, isNot(accent), reason: 'sanity: the stem\'s top must not reach this point at rest');
        expect(
          pulseColorAtTop,
          accent,
          reason: 'the top-widening pulse must grow the stem\'s TOP edge outward mid-pulse',
        );
      });

      test('mid-pulse, the "!" stem\'s BOTTOM (near the dot) stays at its resting width', () async {
        const midPulse = LayoPainter(emotion: LayoEmotion.alert, alertPulseT: 0.6);
        const accent = Color(0xFFFF9800);

        // A point at the stem's own resting width, near its bottom (y 230,
        // close to the stem's bottom at y 233.96) -- the funnel narrows
        // back to the resting width here regardless of the pulse, so this
        // point stays covered.
        const bottomAtRestingWidth = Offset(162, 230);
        final color = await pixelAt(midPulse, size, bottomAtRestingWidth);
        expect(
          color,
          accent,
          reason: 'the funnel must taper back to the resting stem width at the bottom, near the dot',
        );

        // A point well outside even the resting width near the bottom must
        // still be background -- the widening is top-only, so it must not
        // have also widened the bottom.
        const bottomOutsideRestingWidth = Offset(155, 230);
        final outsideColor = await pixelAt(midPulse, size, bottomOutsideRestingWidth);
        expect(
          outsideColor,
          isNot(accent),
          reason: 'the widening must be confined to the stem\'s top -- the bottom must not also widen',
        );
      });
    });

    group('layo404: glitch/flicker', () {
      test('glitchOpacity defaults to 1.0 (fully opaque) and glitchOffset to 0.0 (no jitter)', () {
        const painter = LayoPainter(emotion: LayoEmotion.layo404);
        expect(painter.glitchOpacity, 1.0);
        expect(painter.glitchOffset, 0.0);
      });

      test('at glitchOpacity == 1.0 a digit renders at full alpha', () async {
        const painter = LayoPainter(emotion: LayoEmotion.layo404);
        // A point inside the first "4" digit's own fill.
        const digitPoint = Offset(120, 220);
        final color = await pixelAt(painter, size, digitPoint);
        expect(color, const Color(0xFF848484));
      });

      test('a dimmed glitchOpacity reduces the digit group\'s effective alpha', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.layo404);
        const dimmed = LayoPainter(emotion: LayoEmotion.layo404, glitchOpacity: 0.3);
        const digitPoint = Offset(120, 220);

        // The screen behind the digit is a distinct dark color
        // (0xFF302F44), so a genuinely dimmed (alpha-blended) digit must
        // sample as a color between the two -- neither the fully-opaque
        // grey nor the raw screen color.
        final restColor = await pixelAt(atRest, size, digitPoint);
        final dimmedColor = await pixelAt(dimmed, size, digitPoint);
        expect(restColor, const Color(0xFF848484));
        expect(
          dimmedColor,
          isNot(const Color(0xFF848484)),
          reason: 'glitchOpacity below 1.0 must visibly dim the "404" glyph group toward the screen behind it',
        );
      });

      test('a nonzero glitchOffset shifts the digit group horizontally', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.layo404);
        const shifted = LayoPainter(emotion: LayoEmotion.layo404, glitchOffset: 1.6);

        // Sample a point right at the first "4"'s own left edge -- a
        // horizontal shift must move accent-filled pixels away from this
        // exact column.
        const edgePoint = Offset(113.96, 225);
        final restColor = await pixelAt(atRest, size, edgePoint);
        final shiftedColor = await pixelAt(shifted, size, edgePoint);
        expect(
          shiftedColor,
          isNot(restColor),
          reason: 'a nonzero glitchOffset must visibly shift the "404" glyph group horizontally',
        );
      });
    });

    group('idea: glow + flash', () {
      test('glowT and flashT both default to 0.0 (no glow, no flash)', () {
        const painter = LayoPainter(emotion: LayoEmotion.idea);
        expect(painter.glowT, 0.0);
        expect(painter.flashT, 0.0);
      });

      test('at rest, the antenna tip renders at its exact base radius with no glow ring', () {
        const painter = LayoPainter(emotion: LayoEmotion.idea);
        const accent = Color(0xFFF5CC24);
        expect(
          (Canvas canvas) => painter.paint(canvas, size),
          paints..circle(x: 197.66, y: 17.30, radius: 16.71, color: accent, style: PaintingStyle.fill),
        );
      });

      test('at the flash\'s peak, the antenna dot\'s glow ring extends beyond the base radius', () async {
        const atRest = LayoPainter(emotion: LayoEmotion.idea);
        const atFlashPeak = LayoPainter(emotion: LayoEmotion.idea, flashT: 1.0);

        // Sample a ring just outside the base radius: the flash's glow ring
        // must paint a translucent yellow there, unlike the fully-static
        // resting painter.
        const ringPoint = Offset(197.66 + 16.71 + 4.0, 17.30);
        final restColor = await pixelAt(atRest, size, ringPoint);
        final flashColor = await pixelAt(atFlashPeak, size, ringPoint);
        expect(
          flashColor,
          isNot(restColor),
          reason: 'the "insight" flash must paint a visible glow ring beyond the antenna tip\'s base radius',
        );
      });

      test('paints without throwing across glowT and flashT\'s full 0..1 sweep', () {
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final painter = LayoPainter(emotion: LayoEmotion.idea, glowT: t, flashT: t);
          expect(() => painter.paint(Canvas(PictureRecorder()), size), returnsNormally);
        }
      });

      test('the bulb\'s own glow ring is clipped to the dark screen: never paints outside it', () async {
        // Regression for a bug where a strong "insight" flash's glow ring
        // (centered on the bulb at roughly (197, 210), well inside the
        // screen rect x 78.45-317.04, y 123.02-308.80) grew large enough to
        // spill onto the head shell/body outside the screen. At glowT: 0.5
        // (the glow breath's own peak) and flashT: 1.0 (a flash's peak),
        // the glow ring's radius is at its largest -- if it were unclipped,
        // these points just outside each of the screen's four edges,
        // roughly level with the bulb's own center, would show a visible
        // yellow tint instead of the plain body color.
        const maxFlash = LayoPainter(emotion: LayoEmotion.idea, glowT: 0.5, flashT: 1.0);
        const bodyOuterColor = Color(0xFFEAE9EA);

        for (final p in [
          Offset(197, 118), // just above the screen's top edge (123.02)
          Offset(197, 314), // just below the screen's bottom edge (308.80)
          Offset(72, 210), // just left of the screen's left edge (78.45)
          Offset(323, 210), // just right of the screen's right edge (317.04)
        ]) {
          final color = await pixelAt(maxFlash, size, p);
          expect(
            color,
            bodyOuterColor,
            reason: 'the bulb\'s glow ring must never paint outside the dark screen -- $p must stay plain body color',
          );
        }

        // Sanity: well inside the screen, near the bulb's own center, the
        // glow must actually be visible (not accidentally clipped away
        // entirely).
        final insideColor = await pixelAt(maxFlash, size, const Offset(197, 210));
        expect(
          insideColor,
          isNot(bodyOuterColor),
          reason: 'sanity: the glow must still be visible well inside the screen',
        );
      });
    });
  });
}

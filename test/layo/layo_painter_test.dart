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
      expect(painter.accentColor, const Color(0xFF60ABDE));
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

      test('is true when pulseT differs, for every emotion that pulses (all but dead)', () {
        for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.question, LayoEmotion.sleep]) {
          final painterA = LayoPainter(emotion: emotion);
          final painterB = LayoPainter(emotion: emotion, pulseT: 0.5);
          expect(painterA.shouldRepaint(painterB), isTrue, reason: 'pulse must repaint for $emotion');
        }
      });

      test('is false-for-pulse when pulseT alone differs for dead (no looping pulse)', () {
        const painterA = LayoPainter(emotion: LayoEmotion.dead);
        const painterB = LayoPainter(emotion: LayoEmotion.dead, pulseT: 0.5);
        expect(
          painterA.shouldRepaint(painterB),
          isFalse,
          reason: 'dead does not play the looping pulse, so a pulseT-only change must not trigger a repaint',
        );
      });

      test('is true when blinkT differs for the only blinkable emotion (mrLayo)', () {
        const painterA = LayoPainter();
        const painterB = LayoPainter(blinkT: 1.0);
        expect(painterA.shouldRepaint(painterB), isTrue);
      });

      for (final emotion in [LayoEmotion.question, LayoEmotion.sleep, LayoEmotion.dead]) {
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
    });

    group('bow-tie on every emotion, colored by that emotion\'s own accent', () {
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

      for (final emotion in [LayoEmotion.sleep, LayoEmotion.dead]) {
        test('$emotion paints the tie fill in glyphColor (grey), not blue', () async {
          final painter = LayoPainter(emotion: emotion);
          final color = await pixelAt(painter, size, tieCenter);
          expect(color, const Color(0xFF848484), reason: '$emotion\'s tie must follow its own grey accent');
        });
      }
    });

    test('tieFoldColor darkens its input toward black by the tuned fraction', () {
      const accent = Color(0xFF60ABDE);
      final fold = tieFoldColor(accent);
      expect(fold.a, 1.0);
      expect(fold.r, lessThan(accent.r));
      expect(fold.g, lessThan(accent.g));
      expect(fold.b, lessThan(accent.b));
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
  });
}

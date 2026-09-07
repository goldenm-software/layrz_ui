import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Widget-level [Layo.emotion] tests: default value, per-emotion wiring
/// through to [LayoPainter], the mrLayo unchanged-regression check, and
/// emotion-gated blink/pulse animation behavior.
///
/// [Layo]'s core size/animation contract (independent of [Layo.emotion]) is
/// covered in `layo_test.dart`; pure [LayoPainter] tests (shouldRepaint,
/// per-emotion antenna color, per-emotion glyph presence) live in
/// `layo_painter_test.dart`.
void main() {
  group('Layo.emotion', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('defaults to LayoEmotion.mrLayo when omitted', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false)),
        ),
      );

      expect(painterIn(tester).emotion, LayoEmotion.mrLayo);
    });

    for (final emotion in LayoEmotion.values) {
      guardedTestWidgets('emotion: $emotion is wired straight through to LayoPainter.emotion', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, animate: false, emotion: emotion)),
          ),
        );

        expect(painterIn(tester).emotion, emotion);
      });

      guardedTestWidgets('emotion: $emotion renders without error at a bounded width', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 150, emotion: emotion)),
          ),
        );

        expect(find.byType(Layo), findsOneWidget);
      });
    }

    guardedTestWidgets('mrLayo (the regression case) still paints the tie, blue eyes, and mouth unchanged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 396.15, animate: false)),
        ),
      );

      final painter = painterIn(tester);
      expect(painter.emotion, LayoEmotion.mrLayo);

      // The tie and mouth path presence is verified precisely (in isolation,
      // via the glyph functions themselves) in `layo_painter_test.dart` --
      // `paints`' path(includes:) matches strictly the *next* drawPath call
      // in sequence, and the tie's own two drawPath calls (outline, fill)
      // precede the mouth's here, so chaining multiple path() predicates
      // against the full painter's draw sequence does not reliably reach
      // the mouth's own call.
      //
      // Every shape in this painter is drawn twice in immediate succession
      // (see `_paintSmoothed`'s fill-then-stroke antialiasing pass), so each
      // eye needs a fill predicate immediately followed by its own stroke
      // predicate -- chaining fill-only predicates for both eyes back to
      // back would consume the first eye's fill, then mismatch against the
      // first eye's own stroke call when checking the second eye.
      const accent = Color(0xFF60ABDE);
      expect(
        (Canvas canvas) => painter.paint(canvas, const Size(396.15, 659.76)),
        paints
          // Both circular blue eyes, open (blinkT == 0 since animate: false).
          ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
          ..circle(x: 134.67, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke)
          ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.fill)
          ..circle(x: 261.17, y: 195.73, radius: 15.57, color: accent, style: PaintingStyle.stroke)
          // The antenna tip in accent blue, not grey.
          ..circle(x: 197.66, y: 17.30, color: accent),
      );
    });

    guardedTestWidgets('mrLayo is blinkable: blinkT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120)),
        ),
      );

      expect(painterIn(tester).blinkT, 0.0);

      // The blink scheduler fires within 3-6s of animation starting;
      // pump well past the longest possible interval plus the blink's
      // own ~140ms close/reopen duration, then sample mid-blink by
      // pumping in small steps so we can catch blinkT above 0 at least
      // once during the run.
      var sawNonZeroBlink = false;
      for (var i = 0; i < 62 && !sawNonZeroBlink; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).blinkT > 0.0) {
          sawNonZeroBlink = true;
        }
      }

      expect(sawNonZeroBlink, isTrue, reason: 'mrLayo must blink at some point while animating');
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
      LayoEmotion.comandante,
    ]) {
      guardedTestWidgets('$emotion is not blinkable: blinkT stays 0 for the whole animation window', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        expect(painterIn(tester).blinkT, 0.0);

        // Pump well past the longest possible blink-scheduling interval
        // (6s) — a blinkable emotion would show blinkT > 0 somewhere in
        // this window; a non-blinkable one must not, ever.
        for (var i = 0; i < 62; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            painterIn(tester).blinkT,
            0.0,
            reason: '$emotion must never blink, even while animating',
          );
        }
      });
    }

    guardedTestWidgets('question wiggles: wiggleT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.question)),
        ),
      );

      expect(painterIn(tester).wiggleT, 0.0);

      await tester.pump(const Duration(milliseconds: 900));

      expect(
        painterIn(tester).wiggleT,
        closeTo(0.5, 0.05),
        reason: 'question must play the "?" wiggle at the quarter-cycle-equivalent point of its ~1.8s loop',
      );
    });

    for (final emotion in [
      LayoEmotion.mrLayo,
      LayoEmotion.sleep,
      LayoEmotion.dead,
      LayoEmotion.love,
      LayoEmotion.angry,
      LayoEmotion.alert,
      LayoEmotion.layo404,
      LayoEmotion.idea,
      LayoEmotion.comandante,
    ]) {
      guardedTestWidgets('$emotion never wiggles: wiggleT stays 0 while animating', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(milliseconds: 900));

        expect(painterIn(tester).wiggleT, 0.0, reason: '$emotion must never wiggle');
      });
    }

    guardedTestWidgets('sleep fades the zzz: zzzPhase moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.sleep)),
        ),
      );

      expect(painterIn(tester).zzzPhase, 0.0);

      await tester.pump(const Duration(milliseconds: 1400));

      expect(
        painterIn(tester).zzzPhase,
        closeTo(0.5, 0.05),
        reason: 'sleep must play the zzz fade at the half-cycle point of its ~2.8s loop',
      );
    });

    for (final emotion in [
      LayoEmotion.mrLayo,
      LayoEmotion.question,
      LayoEmotion.dead,
      LayoEmotion.love,
      LayoEmotion.angry,
      LayoEmotion.alert,
      LayoEmotion.layo404,
      LayoEmotion.idea,
      LayoEmotion.comandante,
    ]) {
      guardedTestWidgets('$emotion never fades a zzz: zzzPhase stays 0 while animating', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(milliseconds: 1400));

        expect(painterIn(tester).zzzPhase, 0.0, reason: '$emotion has no zzz to fade');
      });
    }

    for (final emotion in [
      LayoEmotion.mrLayo,
      LayoEmotion.question,
      LayoEmotion.sleep,
      LayoEmotion.angry,
      LayoEmotion.layo404,
    ]) {
      guardedTestWidgets('$emotion still pulses the antenna while animating', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        expect(painterIn(tester).pulseT, 0.0);

        await tester.pump(const Duration(milliseconds: 500));

        expect(
          painterIn(tester).pulseT,
          closeTo(0.25, 0.05),
          reason: '$emotion must play the antenna pulse identically to every other pulsing emotion',
        );
      });
    }

    guardedTestWidgets('dead never plays the looping pulse: pulseT stays 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.dead)),
        ),
      );

      await tester.pump(const Duration(seconds: 3));

      expect(
        painterIn(tester).pulseT,
        0.0,
        reason:
            'dead must never play the looping antenna pulse — a dead robot should not look like it is '
            'still sending a signal; it rests drooped and twitches instead',
      );
    });

    for (final emotion in [LayoEmotion.love, LayoEmotion.idea, LayoEmotion.comandante]) {
      guardedTestWidgets('$emotion never plays the generic looping pulse: pulseT stays 0 while animating', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(seconds: 3));

        expect(
          painterIn(tester).pulseT,
          0.0,
          reason:
              '$emotion must never play the generic looping pulse -- either it drives its own antenna dot '
              'animation instead (love, idea), or it has no antenna at all to pulse (comandante)',
        );
      });
    }

    guardedTestWidgets('dead rests fully drooped (droopT: 1.0) immediately, with no twitch in progress', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.dead)),
        ),
      );

      expect(
        painterIn(tester).droopT,
        1.0,
        reason: 'the resting droop is not an animation to reach — it is where a dead antenna sits from the start',
      );
    });

    guardedTestWidgets('dead twitches periodically: droopT briefly rises above rest, then falls back to 1.0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.dead)),
        ),
      );

      expect(painterIn(tester).droopT, 1.0);

      // The twitch scheduler fires within 3-6s of animation starting, like
      // the blink; pump well past the longest possible interval plus the
      // twitch's own short rise+fall duration, sampling in small steps so we
      // can catch droopT below 1.0 (mid-twitch) at least once during the
      // run, then confirm it settles back to exactly 1.0 afterward.
      var sawTwitch = false;
      for (var i = 0; i < 62 && !sawTwitch; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).droopT < 1.0) {
          sawTwitch = true;
        }
      }

      expect(sawTwitch, isTrue, reason: 'dead must twitch (droopT dips below the resting 1.0) at some point');

      // Pump in the same small steps used above, just past this twitch's own
      // short rise+fall duration (~520ms), so it settles back to rest --
      // deliberately not long enough for the *next* jittered twitch (minimum
      // 3s later) to start, so this only observes the twitch just caught
      // above settling, not a subsequent one. A single large-duration pump
      // does not work here: each `await` inside `_playTwitch` needs its own
      // frame to resolve, so the controller's forward-then-reverse chain
      // only completes across multiple smaller pumps, matching how a real
      // app (which renders every frame) would actually observe it.
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).droopT, 1.0, reason: 'the twitch must fall back to exactly the resting droop');
    });

    for (final emotion in [
      LayoEmotion.mrLayo,
      LayoEmotion.question,
      LayoEmotion.sleep,
      LayoEmotion.love,
      LayoEmotion.angry,
      LayoEmotion.alert,
      LayoEmotion.layo404,
      LayoEmotion.idea,
      LayoEmotion.comandante,
    ]) {
      guardedTestWidgets('$emotion never droops or twitches: droopT stays at 1.0 (ignored by its painter)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        // droopT stays at its resting 1.0 for every emotion (no twitch ever
        // moves it away from rest unless dead) -- $emotion's own painter
        // simply never reads this field, so the value itself is inert.
        expect(painterIn(tester).droopT, 1.0);

        await tester.pump(const Duration(seconds: 8));

        expect(painterIn(tester).droopT, 1.0, reason: '$emotion must never twitch');
      });
    }

    guardedTestWidgets('dead with animate: false rests drooped with no twitch, even after time passes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.dead)),
        ),
      );

      expect(painterIn(tester).droopT, 1.0);

      await tester.pump(const Duration(seconds: 8));

      expect(
        painterIn(tester).droopT,
        1.0,
        reason: 'animate: false must show the static resting droop and never twitch',
      );
    });

    guardedTestWidgets('dead under reduced motion rests drooped with no twitch, even after time passes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: Layo(width: 120, emotion: LayoEmotion.dead)),
          ),
        ),
      );

      expect(painterIn(tester).droopT, 1.0);

      await tester.pump(const Duration(seconds: 8));

      expect(
        painterIn(tester).droopT,
        1.0,
        reason: 'reduced motion must show the static resting droop and never twitch',
      );
    });

    guardedTestWidgets('love beats: beatT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.love)),
        ),
      );

      expect(painterIn(tester).beatT, 0.0);

      var sawNonZeroBeat = false;
      for (var i = 0; i < 15 && !sawNonZeroBeat; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).beatT > 0.0) {
          sawNonZeroBeat = true;
        }
      }

      expect(sawNonZeroBeat, isTrue, reason: 'love must play the heartbeat at some point while animating');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never beats: beatT stays 0 while animating', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(milliseconds: 1500));

        expect(painterIn(tester).beatT, 0.0, reason: '$emotion must never beat');
      });
    }

    guardedTestWidgets('angry bursts periodically: burstT briefly rises above 0, then falls back to 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.angry)),
        ),
      );

      expect(painterIn(tester).burstT, 0.0);

      var sawBurst = false;
      for (var i = 0; i < 62 && !sawBurst; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).burstT > 0.0) {
          sawBurst = true;
        }
      }

      expect(sawBurst, isTrue, reason: 'angry must burst (burstT rises above 0) at some point');

      // The burst controller's own forward+reverse cycle is ~550ms each way
      // (~1.1s round trip); pump comfortably past that, well short of the
      // next jittered burst's minimum 3s interval.
      for (var i = 0; i < 13; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).burstT, 0.0, reason: 'the burst must fall back to exactly 0 (relaxed)');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.alert]) {
      guardedTestWidgets('$emotion never bursts: burstT stays 0, even after time passes', (tester) async {
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

        expect(painterIn(tester).burstT, 0.0, reason: '$emotion must never burst');
      });
    }

    guardedTestWidgets('alert pulses: alertPulseT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.alert)),
        ),
      );

      expect(painterIn(tester).alertPulseT, 0.0);

      await tester.pump(const Duration(milliseconds: 450));

      expect(
        painterIn(tester).alertPulseT,
        closeTo(0.5, 0.05),
        reason: 'alert must play the squash-stretch pulse at the half-cycle point of its ~900ms loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.angry, LayoEmotion.layo404]) {
      guardedTestWidgets('$emotion never plays the alert pulse: alertPulseT stays 0 while animating', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(milliseconds: 1500));

        expect(painterIn(tester).alertPulseT, 0.0, reason: '$emotion must never play the alert pulse');
      });
    }

    guardedTestWidgets('layo404 glitches periodically: glitchOpacity dips below 1.0, then settles back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.layo404)),
        ),
      );

      expect(painterIn(tester).glitchOpacity, 1.0);

      var sawGlitch = false;
      for (var i = 0; i < 62 && !sawGlitch; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).glitchOpacity < 1.0) {
          sawGlitch = true;
        }
      }

      expect(sawGlitch, isTrue, reason: 'layo404 must glitch (glitchOpacity dips below 1.0) at some point');

      // The glitch controller's own forward+reverse cycle is ~320ms each way
      // (~640ms round trip); pump comfortably past that, well short of the
      // next jittered glitch's minimum 3s interval.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        painterIn(tester).glitchOpacity,
        1.0,
        reason: 'the glitch must settle back to exactly 1.0 (fully opaque) between bursts',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.dead, LayoEmotion.idea]) {
      guardedTestWidgets('$emotion never glitches: glitchOpacity stays 1.0, even after time passes', (
        tester,
      ) async {
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

        expect(painterIn(tester).glitchOpacity, 1.0, reason: '$emotion must never glitch');
      });
    }

    guardedTestWidgets('idea glows continuously: glowT moves away from 0 while animating', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.idea)),
        ),
      );

      expect(painterIn(tester).glowT, 0.0);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(
        painterIn(tester).glowT,
        closeTo(0.5, 0.05),
        reason: 'idea must play the glow breath at the half-cycle point of its ~2.4s loop',
      );
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.layo404]) {
      guardedTestWidgets('$emotion never glows: glowT stays 0 while animating', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Layo(width: 120, emotion: emotion)),
          ),
        );

        await tester.pump(const Duration(milliseconds: 1500));

        expect(painterIn(tester).glowT, 0.0, reason: '$emotion must never glow');
      });
    }

    guardedTestWidgets('idea flashes periodically: flashT briefly rises above 0, then falls back to 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.idea)),
        ),
      );

      expect(painterIn(tester).flashT, 0.0);

      var sawFlash = false;
      for (var i = 0; i < 62 && !sawFlash; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).flashT > 0.0) {
          sawFlash = true;
        }
      }

      expect(sawFlash, isTrue, reason: 'idea must flash (flashT rises above 0) at some point');

      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).flashT, 0.0, reason: 'the flash must fall back to exactly 0');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.layo404]) {
      guardedTestWidgets('$emotion never flashes: flashT stays 0, even after time passes', (tester) async {
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

        expect(painterIn(tester).flashT, 0.0, reason: '$emotion must never flash');
      });
    }
  });
}

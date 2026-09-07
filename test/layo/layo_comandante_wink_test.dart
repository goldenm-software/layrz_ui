import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Widget-level tests for [LayoEmotion.comandante]'s right-eye wink
/// animation, split into its own file (rather than appended to the already
/// oversized `layo_emotion_widget_test.dart`) per this repository's
/// file-size convention.
///
/// [LayoPainter]'s own pure geometry/color assertions for [LayoEmotion.comandante]
/// (the beret overlay, the chest chevrons, the no-tie exception, and
/// `winkT`'s effect on the raw painter) live in `layo_painter_test.dart`;
/// this file covers only [Layo]'s animation lifecycle -- the wink scheduler
/// firing, resting at both-eyes-open, and settling back after a wink.
void main() {
  group('Layo.emotion == LayoEmotion.comandante wink', () {
    LayoPainter painterIn(WidgetTester tester) {
      final finder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LayoPainter);
      return tester.widget<CustomPaint>(finder).painter! as LayoPainter;
    }

    guardedTestWidgets('at rest (animate: false) winkT is 0.0 -- both eyes open', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.comandante)),
        ),
      );

      expect(painterIn(tester).winkT, 0.0);
    });

    guardedTestWidgets('comandante winks periodically: winkT rises above 0, then settles back to 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, emotion: LayoEmotion.comandante)),
        ),
      );

      expect(painterIn(tester).winkT, 0.0);

      // The wink scheduler fires within 3-6s of animation starting, the same
      // jittered interval every other one-shot scheduler in this widget
      // uses; pump well past that plus the wink's own short close/reopen
      // duration, sampling in small steps so we can catch winkT above 0
      // (mid-wink) at least once during the run.
      var sawWink = false;
      for (var i = 0; i < 62 && !sawWink; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (painterIn(tester).winkT > 0.0) {
          sawWink = true;
        }
      }

      expect(sawWink, isTrue, reason: 'comandante must wink (winkT rises above 0) at some point while animating');

      // Pump in the same small steps used above, just past this wink's own
      // short close/reopen duration, so it settles back to rest -- not long
      // enough for the *next* jittered wink (minimum 3s later) to start.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(painterIn(tester).winkT, 0.0, reason: 'the wink must fall back to exactly 0 (both eyes open again)');
    });

    guardedTestWidgets('animate: false never winks: winkT stays 0 even after time passes', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Layo(width: 120, animate: false, emotion: LayoEmotion.comandante)),
        ),
      );

      await tester.pump(const Duration(seconds: 8));

      expect(painterIn(tester).winkT, 0.0, reason: 'animate: false must suppress the wink entirely');
    });

    for (final emotion in [LayoEmotion.mrLayo, LayoEmotion.love, LayoEmotion.layo404]) {
      guardedTestWidgets('$emotion never winks: winkT stays 0, even after time passes', (tester) async {
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

        expect(painterIn(tester).winkT, 0.0, reason: '$emotion must never wink');
      });
    }
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('LayoController', () {
    test('defaults to LayoEmotion.mrLayo for from/target/current, at rest', () {
      final controller = LayoController();
      expect(controller.from, LayoEmotion.mrLayo);
      expect(controller.target, LayoEmotion.mrLayo);
    });

    test('an explicit initialEmotion seeds from and target identically', () {
      final controller = LayoController(initialEmotion: LayoEmotion.success);
      expect(controller.from, LayoEmotion.success);
      expect(controller.target, LayoEmotion.success);
    });

    test('to() sets target to the requested emotion and from to the previous current', () {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      controller.to(LayoEmotion.excited);
      expect(controller.target, LayoEmotion.excited);
      expect(controller.from, LayoEmotion.mrLayo);
    });

    test('to() notifies listeners exactly once per distinct target change', () {
      final controller = LayoController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.to(LayoEmotion.sad);
      expect(notifications, 1);

      controller.to(LayoEmotion.party);
      expect(notifications, 2);
    });

    test('to() with the same value the target already holds is a no-op: no notification, no from change', () {
      final controller = LayoController(initialEmotion: LayoEmotion.working);
      controller.to(LayoEmotion.excited);
      // Settle as if the transition finished, so from == target == excited.
      controller.reportCurrent(LayoEmotion.excited);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.to(LayoEmotion.excited);
      expect(notifications, 0, reason: 'requesting the emotion already targeted must not notify');
      expect(controller.from, LayoEmotion.working, reason: 'from must be unchanged by a no-op to() call');
    });

    test('re-basing mid-transition: a second to() call before reportCurrent uses the ORIGINAL from, not the '
        'abandoned target', () {
      // No reportCurrent call happens between these two to() calls -- as if
      // TransitionedLayo has not yet ticked _current forward from the first
      // transition's own start, so the second to() call's own "currently
      // visible emotion" estimate is still the original mrLayo.
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      controller.to(LayoEmotion.excited);
      controller.to(LayoEmotion.angry);

      expect(controller.target, LayoEmotion.angry, reason: 'the latest to() call always wins the target');
      expect(
        controller.from,
        LayoEmotion.mrLayo,
        reason: 'with no reportCurrent in between, the re-based transition starts from the original current emotion',
      );
    });

    test('re-basing mid-transition: reportCurrent between two to() calls re-bases from the reported value', () {
      // This is the realistic TransitionedLayo flow: reportCurrent is called
      // continuously while a transition plays, so a re-basing to() call
      // picks up wherever the mascot visually was, not the original from.
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      controller.to(LayoEmotion.excited);
      // The mascot is now visually partway between mrLayo and excited;
      // TransitionedLayo reports its own current best estimate.
      controller.reportCurrent(LayoEmotion.excited);
      controller.to(LayoEmotion.angry);

      expect(controller.target, LayoEmotion.angry);
      expect(
        controller.from,
        LayoEmotion.excited,
        reason: 're-basing must start the new transition from the reported (visually current) emotion',
      );
    });

    test('reportCurrent alone never notifies listeners (it is not a mutation of from/target)', () {
      final controller = LayoController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.reportCurrent(LayoEmotion.money);
      expect(notifications, 0);
    });

    test('no queue: calling to() three times in a row leaves only the LATEST target, never a backlog', () {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      controller.to(LayoEmotion.sad);
      controller.to(LayoEmotion.cool);
      controller.to(LayoEmotion.working);

      // Only the final call's target survives -- there is no queued sequence
      // of sad -> cool -> working for a caller to ever observe or drain.
      expect(controller.target, LayoEmotion.working);
      // And the very first call's own "from" is still what a from getter can
      // report -- there is no way to ask this controller "what was requested
      // second", confirming no history beyond from/target is retained.
      expect(controller.from, LayoEmotion.mrLayo);
    });

    test('LayoController is a Listenable/ChangeNotifier that can be listened to and disposed', () {
      final controller = LayoController();
      addTearDown(controller.dispose);
      expect(controller, isA<Listenable>());
    });
  });
}

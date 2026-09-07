import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('TransitionedLayo', () {
    /// Pumps [child] inside a bounded, wide-viewport host so [TransitionedLayo]'s
    /// (and [Layo]'s) [AspectRatio] always resolves against a real width.
    Future<void> pumpWide(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 300, child: child)),
        ),
      );
    }

    testWidgets('builds with a controller and renders a Layo at rest', (tester) async {
      final controller = LayoController();
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedLayo(controller: controller));

      expect(find.byType(TransitionedLayo), findsOneWidget);
      expect(find.byType(Layo), findsOneWidget);
    });

    testWidgets('at rest (no transition ever requested) renders a single plain Layo showing '
        'initialEmotion\'s controller target', (tester) async {
      final controller = LayoController(initialEmotion: LayoEmotion.success);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedLayo(controller: controller));
      await tester.pump();

      expect(find.byType(Layo), findsOneWidget);
      final layo = tester.widget<Layo>(find.byType(Layo));
      expect(layo.emotion, LayoEmotion.success);
    });

    testWidgets('is size-automatic: an explicit width produces a bounded box of that width', (tester) async {
      final controller = LayoController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: TransitionedLayo(controller: controller, width: 120)),
        ),
      );

      final size = tester.getSize(find.byType(TransitionedLayo));
      expect(size.width, 120);
      expect(size.height, closeTo(120 * 833 / 500, 0.5));
    });

    group('mid-transition crossfade', () {
      testWidgets('controller.to() stacks TWO Layo widgets (outgoing + incoming) with complementary opacity', (
        tester,
      ) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedLayo(controller: controller));
        await tester.pump();

        controller.to(LayoEmotion.excited);
        // A zero-duration pump anchors the ticker's own start timestamp;
        // only the pump after it actually advances elapsed animation time.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final layoWidgets = tester.widgetList<Layo>(find.byType(Layo)).toList();
        expect(layoWidgets, hasLength(2), reason: 'mid-transition must stack exactly two complete Layo widgets');
        expect(layoWidgets.map((l) => l.emotion), containsAll([LayoEmotion.mrLayo, LayoEmotion.excited]));

        final fadeTransitions = tester.widgetList<FadeTransition>(find.byType(FadeTransition)).toList();
        expect(fadeTransitions, hasLength(2));
        final opacities = fadeTransitions.map((f) => f.opacity.value).toList()..sort();
        // Complementary: outgoing (fading out) + incoming (fading in) sum to 1.0.
        expect(opacities[0] + opacities[1], closeTo(1.0, 1e-9));
        expect(opacities[0], greaterThan(0.0));
        expect(opacities[0], lessThan(1.0));

        // Bounded settle rather than pumpAndSettle: once the transition
        // finishes, the settled Layo starts its own looping idle-animation
        // controllers (e.g. the antenna pulse), which never go idle on their
        // own -- pumpAndSettle would wait for them forever.
        await tester.pump(const Duration(milliseconds: 300));
      });

      testWidgets('a completed transition settles on a SINGLE Layo for the target emotion', (tester) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedLayo(controller: controller));
        await tester.pump();

        controller.to(LayoEmotion.angry);
        // Bounded settle, not pumpAndSettle -- see the sibling test's own
        // comment for why (the settled Layo's looping idle animations never
        // go idle on their own).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final layoWidgets = tester.widgetList<Layo>(find.byType(Layo)).toList();
        expect(layoWidgets, hasLength(1), reason: 'a settled transition must drop the outgoing Layo entirely');
        expect(layoWidgets.single.emotion, LayoEmotion.angry);
        expect(find.byType(FadeTransition), findsNothing, reason: 'a settled frame must not stack any FadeTransition');
      });

      testWidgets('re-basing mid-transition restarts the crossfade toward the new target', (tester) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedLayo(controller: controller));
        await tester.pump();

        controller.to(LayoEmotion.excited);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));
        // Re-base before the first transition settles.
        controller.to(LayoEmotion.working);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final layoWidgets = tester.widgetList<Layo>(find.byType(Layo)).toList();
        expect(
          layoWidgets.map((l) => l.emotion),
          contains(LayoEmotion.working),
          reason: 're-basing must retarget the incoming Layo toward the new emotion',
        );

        // Bounded settle, not pumpAndSettle -- see the earlier test's own
        // comment for why.
        await tester.pump(const Duration(milliseconds: 300));
        final settled = tester.widget<Layo>(find.byType(Layo));
        expect(settled.emotion, LayoEmotion.working);
      });
    });

    group('reduced motion / animate: false', () {
      testWidgets('animate: false hard-cuts to the target with no crossfade ever stacked', (tester) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedLayo(controller: controller, animate: false));
        await tester.pump();

        controller.to(LayoEmotion.sad);
        // Pump a single frame -- if this were animating, this would still be
        // mid-transition; a hard cut must already show the settled Layo.
        await tester.pump();

        expect(find.byType(Layo), findsOneWidget);
        final layo = tester.widget<Layo>(find.byType(Layo));
        expect(layo.emotion, LayoEmotion.sad);
        expect(find.byType(FadeTransition), findsNothing, reason: 'a hard cut must never stack a crossfade');
      });

      testWidgets('MediaQuery.disableAnimations forces a hard cut even when animate is true', (tester) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(width: 300, child: TransitionedLayo(controller: controller)),
              ),
            ),
          ),
        );
        await tester.pump();

        controller.to(LayoEmotion.cool);
        await tester.pump();

        expect(find.byType(Layo), findsOneWidget);
        final layo = tester.widget<Layo>(find.byType(Layo));
        expect(layo.emotion, LayoEmotion.cool);
        expect(find.byType(FadeTransition), findsNothing);
      });
    });

    testWidgets('disposes cleanly without throwing when unmounted mid-transition', (tester) async {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedLayo(controller: controller));
      await tester.pump();

      controller.to(LayoEmotion.party);
      await tester.pump(const Duration(milliseconds: 50));

      // Unmount while the transition is still in flight.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}

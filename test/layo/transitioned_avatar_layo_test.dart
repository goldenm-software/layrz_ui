import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Widget-level tests for [TransitionedAvatarLayo]: the composition of
/// [AvatarLayo]'s frame (clip/crop/ring geometry, reused via
/// [AvatarLayo.buildFrame]) around a crossfading [TransitionedLayo], PLUS the
/// avatar's own background/ring [Color.lerp] driven by
/// [LayoController.from]/[LayoController.target] alongside that crossfade.
void main() {
  group('TransitionedAvatarLayo', () {
    /// Pumps [child] inside a bounded, wide-viewport host so the widget's
    /// [AspectRatio] always resolves against a real width.
    Future<void> pumpWide(WidgetTester tester, Widget child, {double width = 200}) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      );
    }

    /// Finds the [Container] that fills the clipped portrait area -- the
    /// direct ancestor [Container] of the [Stack] positioning the inner
    /// mascot -- so its resolved `color` (the lerped/settled background) can
    /// be asserted directly. Mirrors `avatar_layo_test.dart`'s own
    /// `fillContainer` helper.
    Container fillContainer(WidgetTester tester) => tester.widget<Container>(
      find.ancestor(of: find.byType(Stack), matching: find.byType(Container)).first,
    );

    /// Finds the outermost [Container] -- the one painting the ring via its
    /// own [BoxDecoration.color] -- so that resolved (lerped/settled) ring
    /// color can be asserted directly. Mirrors `avatar_layo_test.dart`'s own
    /// `ringContainer` helper.
    Container ringContainer(WidgetTester tester) => tester.widget<Container>(find.byType(Container).first);

    /// Returns the currently-painted fill and ring colors as a pair, reading
    /// straight off the actually-rendered widget tree rather than
    /// recomputing them independently -- so a test asserting "mid-transition
    /// is neither endpoint" is checking real paint output.
    (Color, Color) currentColors(WidgetTester tester) {
      final bg = fillContainer(tester).color!;
      final ring = (ringContainer(tester).decoration! as BoxDecoration).color!;
      return (bg, ring);
    }

    guardedTestWidgets('builds for LayoAvatarShape.circle and settles on the target emotion\'s colors', (
      tester,
    ) async {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
      await tester.pump();

      expect(find.byType(TransitionedAvatarLayo), findsOneWidget);
      final (bg, ring) = currentColors(tester);
      expect(bg, avatarBackgroundFor(LayoEmotion.mrLayo));
      expect(ring, avatarRingFor(LayoEmotion.mrLayo));
    });

    guardedTestWidgets('builds for LayoAvatarShape.roundedBox and settles on the target emotion\'s colors', (
      tester,
    ) async {
      final controller = LayoController(initialEmotion: LayoEmotion.excited);
      addTearDown(controller.dispose);

      await pumpWide(
        tester,
        TransitionedAvatarLayo(controller: controller, shape: LayoAvatarShape.roundedBox),
      );
      await tester.pump();

      expect(find.byType(TransitionedAvatarLayo), findsOneWidget);
      final (bg, ring) = currentColors(tester);
      expect(bg, avatarBackgroundFor(LayoEmotion.excited));
      expect(ring, avatarRingFor(LayoEmotion.excited));

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      final radius = (clip.borderRadius as BorderRadius).topLeft.x;
      final outerContainer = tester.widget<Container>(find.byType(Container).first);
      final side = outerContainer.constraints!.maxWidth;
      expect(radius, lessThan(side / 2), reason: 'roundedBox must use a smaller radius than a circle would');
    });

    guardedTestWidgets('reuses the AvatarLayo frame (ClipRRect + ring Container), no duplicated crop math', (
      tester,
    ) async {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
      await tester.pump();

      // The same structural signature AvatarLayo itself produces: a
      // Clip.hardEdge Stack (the oversized-mascot crop) inside a ClipRRect
      // (the shape clip), inside a ring-painting outer Container.
      expect(find.byType(ClipRRect), findsOneWidget);
      final stack = tester.widget<Stack>(find.byType(Stack).first);
      expect(stack.clipBehavior, Clip.hardEdge);

      // And the mascot content is a TransitionedLayo, not a bare Layo --
      // proving this composes TransitionedLayo's crossfade rather than
      // reimplementing it.
      expect(find.byType(TransitionedLayo), findsOneWidget);
    });

    guardedTestWidgets('is square: renders an AspectRatio of 1.0 with no explicit width', (tester) async {
      final controller = LayoController();
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedAvatarLayo(controller: controller, animate: false), width: 220);

      final aspectRatioFinder = find.byWidgetPredicate((w) => w is AspectRatio && w.aspectRatio == 1.0);
      expect(aspectRatioFinder, findsOneWidget);

      final renderedSize = tester.getSize(find.byType(TransitionedAvatarLayo));
      expect(renderedSize.width, closeTo(220, 0.01));
      expect(renderedSize.height, closeTo(220, 0.01));
    });

    guardedTestWidgets('with an explicit width sizes to width x width, no AspectRatio', (tester) async {
      final controller = LayoController();
      addTearDown(controller.dispose);

      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: TransitionedAvatarLayo(controller: controller, width: 160, animate: false)),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is AspectRatio && w.aspectRatio == 1.0),
        findsNothing,
      );

      final renderedSize = tester.getSize(find.byType(TransitionedAvatarLayo));
      expect(renderedSize.width, closeTo(160, 0.01));
      expect(renderedSize.height, closeTo(160, 0.01));
    });

    group('background/ring lerp during a transition', () {
      guardedTestWidgets('mid-transition, the background is strictly between the two emotions\' backgrounds', (
        tester,
      ) async {
        final controller = LayoController(initialEmotion: LayoEmotion.love);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
        await tester.pump();

        final fromBg = avatarBackgroundFor(LayoEmotion.love);
        final targetBg = avatarBackgroundFor(LayoEmotion.success);
        expect(fromBg, isNot(equals(targetBg)), reason: 'sanity: the two emotions must have distinct backgrounds');

        controller.to(LayoEmotion.success);
        // A zero-duration pump anchors the ticker's own start timestamp;
        // only the pump after it actually advances elapsed animation time.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 140));

        final (midBg, midRing) = currentColors(tester);
        expect(midBg, isNot(equals(fromBg)), reason: 'mid-transition must not equal the FROM background');
        expect(midBg, isNot(equals(targetBg)), reason: 'mid-transition must not equal the TARGET background');

        final fromRing = avatarRingFor(LayoEmotion.love);
        final targetRing = avatarRingFor(LayoEmotion.success);
        expect(midRing, isNot(equals(fromRing)));
        expect(midRing, isNot(equals(targetRing)));

        // Bounded settle rather than pumpAndSettle -- once the transition
        // finishes, idle-animation controllers loop forever.
        await tester.pump(const Duration(milliseconds: 300));
      });

      guardedTestWidgets('settles on the target emotion\'s background and ring once the transition completes', (
        tester,
      ) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
        await tester.pump();

        controller.to(LayoEmotion.angry);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final (bg, ring) = currentColors(tester);
        expect(bg, avatarBackgroundFor(LayoEmotion.angry));
        expect(ring, avatarRingFor(LayoEmotion.angry));
      });

      guardedTestWidgets('re-basing mid-transition redirects the lerp toward the new target', (tester) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
        await tester.pump();

        controller.to(LayoEmotion.excited);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));
        // Re-base before the first transition settles.
        controller.to(LayoEmotion.working);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final (bg, ring) = currentColors(tester);
        expect(bg, avatarBackgroundFor(LayoEmotion.working));
        expect(ring, avatarRingFor(LayoEmotion.working));
      });
    });

    group('reduced motion / animate: false', () {
      guardedTestWidgets('animate: false hard-cuts the background and ring with no intermediate frame', (
        tester,
      ) async {
        final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
        addTearDown(controller.dispose);

        await pumpWide(tester, TransitionedAvatarLayo(controller: controller, animate: false));
        await tester.pump();

        controller.to(LayoEmotion.sad);
        // Pump a single frame -- if this were animating, this would still be
        // mid-transition; a hard cut must already show the settled colors.
        await tester.pump();

        final (bg, ring) = currentColors(tester);
        expect(bg, avatarBackgroundFor(LayoEmotion.sad));
        expect(ring, avatarRingFor(LayoEmotion.sad));
        expect(find.byType(FadeTransition), findsNothing, reason: 'a hard cut must never stack a crossfade');
      });

      guardedTestWidgets('MediaQuery.disableAnimations forces a hard cut even when animate is true', (
        tester,
      ) async {
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
                child: SizedBox(width: 200, child: TransitionedAvatarLayo(controller: controller)),
              ),
            ),
          ),
        );
        await tester.pump();

        controller.to(LayoEmotion.cool);
        await tester.pump();

        final (bg, ring) = currentColors(tester);
        expect(bg, avatarBackgroundFor(LayoEmotion.cool));
        expect(ring, avatarRingFor(LayoEmotion.cool));
        expect(find.byType(FadeTransition), findsNothing);
      });
    });

    guardedTestWidgets('controller.to() drives both the face crossfade and the color lerp from one call', (
      tester,
    ) async {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
      await tester.pump();

      controller.to(LayoEmotion.money);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Face: TransitionedLayo stacks two Layo widgets mid-crossfade.
      final layoWidgets = tester.widgetList<Layo>(find.byType(Layo)).toList();
      expect(layoWidgets, hasLength(2), reason: 'mid-transition must still crossfade the face via TransitionedLayo');

      // Color: the frame's own background must have moved off the FROM value.
      final (bg, _) = currentColors(tester);
      expect(bg, isNot(equals(avatarBackgroundFor(LayoEmotion.mrLayo))));

      await tester.pump(const Duration(milliseconds: 300));
    });

    guardedTestWidgets('disposes cleanly without throwing when unmounted mid-transition', (tester) async {
      final controller = LayoController(initialEmotion: LayoEmotion.mrLayo);
      addTearDown(controller.dispose);

      await pumpWide(tester, TransitionedAvatarLayo(controller: controller));
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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';

/// Widget-level tests for [AvatarLayo]: default shape, the fixed
/// per-[LayoEmotion] background color resolution (the background can no
/// longer be set from outside — there is no `backgroundColor` parameter),
/// the fixed per-[LayoEmotion] ring color resolution (always a darkened
/// shade of that same emotion's own background, never a fixed cross-emotion
/// tone), the fixed 1:1 sizing contract (explicit [AvatarLayo.width] and the
/// parent-filling default), pass-through of [AvatarLayo.emotion] and
/// [AvatarLayo.animate] to the inner [Layo], and the head-and-shoulders crop
/// composition (a [Positioned] [Layo] rendered larger than the frame inside
/// a hard-edge-clipped [Stack], cropped by a surrounding [ClipRRect]).
void main() {
  group('AvatarLayo', () {
    /// Finds the inner [Layo] widget instance so its resolved properties can
    /// be asserted directly, rather than only checking it exists.
    Layo innerLayo(WidgetTester tester) => tester.widget<Layo>(find.byType(Layo));

    /// Finds the [Container] that fills the clipped portrait area (the
    /// direct ancestor [Container] of the [Stack] positioning the inner
    /// [Layo]), so its resolved `color` — the per-emotion fixed background —
    /// can be asserted directly.
    Container fillContainer(WidgetTester tester) => tester.widget<Container>(
      find.ancestor(of: find.byType(Stack), matching: find.byType(Container)).first,
    );

    /// Finds the outermost [Container] -- the one painting the fixed ring
    /// via its own [BoxDecoration.color] -- so that resolved ring color can
    /// be asserted directly.
    Container ringContainer(WidgetTester tester) => tester.widget<Container>(find.byType(Container).first);

    /// The exact darken formula [AvatarLayo] itself uses to derive a ring
    /// color from a background color, duplicated here (rather than reused
    /// from the library) so the test independently proves the two colors
    /// have the expected relationship instead of trivially matching by
    /// construction.
    Color darkenedRingFor(Color background) => Color.lerp(background, const Color(0xFF000000), 0.35)!;

    /// Pumps a bare [AvatarLayo] with the given [emotion] inside a fixed-size
    /// box, at a wide desktop viewport.
    Future<void> pumpAvatar(WidgetTester tester, {required LayoEmotion emotion}) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(width: 200, height: 200, child: AvatarLayo(emotion: emotion, animate: false)),
          ),
        ),
      );
    }

    guardedTestWidgets('defaults to LayoAvatarShape.circle and LayoEmotion.mrLayo', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 200, height: 200, child: AvatarLayo())),
        ),
      );

      final avatar = tester.widget<AvatarLayo>(find.byType(AvatarLayo));
      expect(avatar.shape, LayoAvatarShape.circle);
      expect(avatar.emotion, LayoEmotion.mrLayo);
    });

    guardedTestWidgets('resolves the blue background for LayoEmotion.mrLayo', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.mrLayo);
      expect(fillContainer(tester).color, const Color.fromARGB(255, 27, 52, 108));
    });

    guardedTestWidgets('resolves the orange background for LayoEmotion.alert', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.alert);
      expect(fillContainer(tester).color, const Color(0xFFF57C00));
    });

    guardedTestWidgets('resolves the yellow background for LayoEmotion.excited and LayoEmotion.idea', (
      tester,
    ) async {
      await pumpAvatar(tester, emotion: LayoEmotion.excited);
      expect(fillContainer(tester).color, const Color(0xFFF5B800));

      await pumpAvatar(tester, emotion: LayoEmotion.idea);
      expect(fillContainer(tester).color, const Color(0xFFF5B800));
    });

    guardedTestWidgets('resolves the grey background for the sleep/dead/sad/layo404 group', (tester) async {
      for (final emotion in [LayoEmotion.sleep, LayoEmotion.dead, LayoEmotion.sad, LayoEmotion.layo404]) {
        await pumpAvatar(tester, emotion: emotion);
        expect(fillContainer(tester).color, const Color(0xFF8A8A8A), reason: 'for $emotion');
      }
    });

    guardedTestWidgets('resolves the purple background for LayoEmotion.mindBlown', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.mindBlown);
      expect(fillContainer(tester).color, const Color(0xFF7B1FA2));
    });

    guardedTestWidgets('resolves the green background for LayoEmotion.christmas', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.christmas);
      expect(fillContainer(tester).color, const Color(0xFF1B7A3D));
    });

    guardedTestWidgets('resolves the green background for LayoEmotion.money and LayoEmotion.success', (
      tester,
    ) async {
      await pumpAvatar(tester, emotion: LayoEmotion.money);
      expect(fillContainer(tester).color, const Color(0xFF1B7A3D));

      await pumpAvatar(tester, emotion: LayoEmotion.success);
      expect(fillContainer(tester).color, const Color(0xFF1B7A3D));
    });

    guardedTestWidgets('resolves the deep dark red background for LayoEmotion.love', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.love);
      expect(fillContainer(tester).color, const Color(0xFF7A1620));
    });

    guardedTestWidgets('resolves the deep dark red background for LayoEmotion.comandante and LayoEmotion.angry', (
      tester,
    ) async {
      await pumpAvatar(tester, emotion: LayoEmotion.comandante);
      expect(fillContainer(tester).color, const Color(0xFF7A1620));

      await pumpAvatar(tester, emotion: LayoEmotion.angry);
      expect(fillContainer(tester).color, const Color(0xFF7A1620));
    });

    guardedTestWidgets('resolves the brown background for LayoEmotion.working', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.working);
      expect(fillContainer(tester).color, const Color(0xFF6B4423));
    });

    guardedTestWidgets('resolves the party pink background for LayoEmotion.party', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.party);
      expect(fillContainer(tester).color, const Color(0xFFD81B8C));
    });

    guardedTestWidgets(
      'resolves the blue background for the searching/thinking/wink/smug/cool/question group',
      (
        tester,
      ) async {
        for (final emotion in [
          LayoEmotion.question,
          LayoEmotion.searching,
          LayoEmotion.thinking,
          LayoEmotion.wink,
          LayoEmotion.smug,
          LayoEmotion.cool,
        ]) {
          await pumpAvatar(tester, emotion: emotion);
          expect(fillContainer(tester).color, const Color.fromARGB(255, 27, 52, 108), reason: 'for $emotion');
        }
      },
    );

    guardedTestWidgets('resolves the teal background for LayoEmotion.listening', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.listening);
      expect(fillContainer(tester).color, const Color(0xFF0E7C77));
    });

    guardedTestWidgets('rings LayoEmotion.mrLayo with a darker shade of its own blue background', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.mrLayo);
      final bg = fillContainer(tester).color!;
      final ring = (ringContainer(tester).decoration! as BoxDecoration).color!;
      expect(ring, darkenedRingFor(bg));
      // Sanity: the ring is strictly darker than the background it derives
      // from, not merely a different color -- proves "darkened", not just
      // "distinct".
      expect(ring.computeLuminance(), lessThan(bg.computeLuminance()));
    });

    guardedTestWidgets('rings every emotion with a darker shade of that same emotion\'s own background', (
      tester,
    ) async {
      for (final emotion in LayoEmotion.values) {
        await pumpAvatar(tester, emotion: emotion);
        final bg = fillContainer(tester).color!;
        final ring = (ringContainer(tester).decoration! as BoxDecoration).color!;
        expect(ring, darkenedRingFor(bg), reason: 'for $emotion');
        expect(ring.computeLuminance(), lessThan(bg.computeLuminance()), reason: 'for $emotion');
      }
    });

    guardedTestWidgets('rings do not share one fixed cross-emotion color -- orange and blue differ', (tester) async {
      await pumpAvatar(tester, emotion: LayoEmotion.mrLayo);
      final blueRing = (ringContainer(tester).decoration! as BoxDecoration).color;

      await pumpAvatar(tester, emotion: LayoEmotion.alert);
      final orangeRing = (ringContainer(tester).decoration! as BoxDecoration).color;

      expect(orangeRing, isNot(equals(blueRing)));
    });

    for (final shape in LayoAvatarShape.values) {
      guardedTestWidgets('builds for LayoAvatarShape.${shape.name} and applies a ClipRRect', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(width: 180, height: 180, child: AvatarLayo(shape: shape)),
            ),
          ),
        );

        expect(find.byType(AvatarLayo), findsOneWidget);
        expect(find.byType(ClipRRect), findsOneWidget);

        final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
        final radius = (clip.borderRadius as BorderRadius).topLeft.x;
        expect(radius, greaterThan(0));

        if (shape == LayoAvatarShape.circle) {
          // A circle clip on a square box uses exactly half the (inner,
          // border-inset) side as its radius. The border-inset comes from
          // the outer Container's own padding (a per-emotion ring fill
          // clipped to the same radius, inset by that padding), not from a
          // BoxBorder.
          final outerContainer = tester.widget<Container>(find.byType(Container).first);
          final side = outerContainer.constraints!.maxWidth;
          final borderWidth = (outerContainer.padding! as EdgeInsets).top;
          final innerSide = side - borderWidth * 2;
          expect(radius, closeTo(innerSide / 2, 0.5));
        } else {
          final outerContainer = tester.widget<Container>(find.byType(Container).first);
          final side = outerContainer.constraints!.maxWidth;
          expect(radius, lessThan(side / 2));
        }
      });
    }

    guardedTestWidgets('passes emotion and animate through to the inner Layo', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: AvatarLayo(emotion: LayoEmotion.excited, animate: false),
            ),
          ),
        ),
      );

      final layo = innerLayo(tester);
      expect(layo.emotion, LayoEmotion.excited);
      expect(layo.animate, isFalse);
    });

    guardedTestWidgets('defaults emotion to LayoEmotion.mrLayo and animate to true on the inner Layo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox(width: 180, height: 180, child: AvatarLayo())),
        ),
      );

      final layo = innerLayo(tester);
      expect(layo.emotion, LayoEmotion.mrLayo);
      expect(layo.animate, isTrue);
    });

    guardedTestWidgets('is square: renders an AspectRatio of 1.0 with no explicit width', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(width: 220, child: AvatarLayo(animate: false)),
          ),
        ),
      );

      // AvatarLayo builds directly to its own 1:1 AspectRatio, with the
      // inner Layo's own separate (500:833) AspectRatio nested further
      // below it -- so two AspectRatio widgets exist in this tree, and only
      // the outer (aspectRatio == 1.0) one is AvatarLayo's own.
      final aspectRatioFinder = find.byWidgetPredicate((w) => w is AspectRatio && w.aspectRatio == 1.0);
      expect(aspectRatioFinder, findsOneWidget);

      final renderedSize = tester.getSize(find.byType(AvatarLayo));
      expect(renderedSize.width, closeTo(220, 0.01));
      expect(renderedSize.height, closeTo(220, 0.01));
    });

    guardedTestWidgets('with an explicit width sizes to width x width, no AspectRatio', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: AvatarLayo(width: 160, animate: false)),
        ),
      );

      // No 1:1 AspectRatio is built when an explicit width is given -- the
      // inner Layo still has its own separate (500:833) AspectRatio further
      // down, which is not what this assertion covers.
      expect(
        find.byWidgetPredicate((w) => w is AspectRatio && w.aspectRatio == 1.0),
        findsNothing,
      );

      final renderedSize = tester.getSize(find.byType(AvatarLayo));
      expect(renderedSize.width, closeTo(160, 0.01));
      expect(renderedSize.height, closeTo(160, 0.01));
    });

    guardedTestWidgets('crops the inner Layo via an oversized, top-offset Positioned inside a clipped Stack', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const side = 200.0;
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: AvatarLayo(width: side, animate: false)),
        ),
      );

      // The inner Layo is rendered strictly smaller than the avatar frame's
      // own side (70% of the border-inset content side), not equal to it --
      // the "zoom" half of the head-and-shoulders crop comes from cropping
      // its bottom via the ClipRRect below, not from oversizing it here.
      final layo = innerLayo(tester);
      expect(layo.width, lessThan(side));
      expect(layo.width, greaterThan(0));

      // It sits inside a Positioned with a nonzero top offset (pushing the
      // head down slightly from the very top edge) inside a Stack clipped
      // with Clip.hardEdge, so the body running off the bottom edge of the
      // Stack's own bounds is cropped away instead of overflowing visibly.
      final positioned = tester.widget<Positioned>(
        find.ancestor(of: find.byType(Layo), matching: find.byType(Positioned)).first,
      );
      expect(positioned.top, greaterThan(0));
      expect(positioned.width, layo.width);

      final stack = tester.widget<Stack>(
        find.ancestor(of: find.byType(Layo), matching: find.byType(Stack)).first,
      );
      expect(stack.clipBehavior, Clip.hardEdge);

      // The rendered AvatarLayo box itself stays exactly side x side --
      // proving the crop happens within the frame rather than inflating the
      // avatar's own footprint.
      final renderedSize = tester.getSize(find.byType(AvatarLayo));
      expect(renderedSize.width, closeTo(side, 0.01));
      expect(renderedSize.height, closeTo(side, 0.01));
    });
  });
}

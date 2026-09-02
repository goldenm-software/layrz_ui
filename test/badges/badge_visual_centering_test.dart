import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';
import 'helpers/real_font.dart';

void main() {
  group('LayrzBadgeVisual count centering (DESIGN-167 follow-up)', () {
    // Regression suite for the "the # must be centered" defect.
    //
    // IMPORTANT — why this suite measures glyph INK bounds, not the `Text`
    // widget's layout-box rect (`tester.getRect(find.text(...))`):
    //
    // An earlier version of this suite asserted centering by comparing the
    // badge's `Container` rect against the `Text` widget's own rect. That
    // assertion passed even against the pre-fix code (verified directly:
    // checked out the commit before the `Center`/`textAlign` fix and re-ran
    // the old assertions unchanged -- still green), despite the maintainer
    // seeing the count visibly left-of-center on a real device after that
    // fix shipped. The reason: `RenderParagraph.performLayout` does `size =
    // constraints.constrain(textSize)` -- exactly like every other box in
    // this widget's constraint chain, its own layout box gets widened up to
    // the ambient `minWidth` floor whenever the text is narrower than that
    // floor (true for every single/double-digit count at this diameter).
    // That widened box is what `tester.getRect(find.text(...))` reports, and
    // its center trivially coincides with the container's center because
    // both derive from the same symmetric padding/minWidth math -- REGARDLESS
    // of whether `TextAlign.start` (the old default) or `TextAlign.center`
    // painted the glyphs inside that box. The old assertion was therefore
    // checking a geometric tautology, not the visible ink -- it could not
    // have failed even with the bug present, which is exactly what re-running
    // it against the pre-fix code confirmed.
    //
    // A second, independent problem made this invisible in CI specifically:
    // Flutter's default widget-test fallback font renders every glyph as a
    // uniform box that exactly fills its own advance width, with no side
    // bearing -- so even a "tight" ink-bounds query
    // (`RenderParagraph.getBoxesForSelection` with `BoxWidthStyle.tight`)
    // returns the same box as the untight layout query under that font. The
    // asymmetry this suite exists to catch is a property of a REAL font's
    // glyph metrics, and is structurally unobservable under the fallback
    // font no matter what is measured. This suite loads the real
    // Roboto-Regular.ttf (see `helpers/real_font.dart`) specifically so the
    // ink-bounds assertions below are capable of failing.
    //
    // Measured directly against the pre-fix code with the real font loaded:
    // a single digit's ink center sat 3.0lp left of the badge's true center
    // (far above the horizontal tolerance used below) -- while the
    // *layout-box* measurement the old suite used read exactly 0.0lp every
    // time. Against the current (post-fix) code, the same horizontal
    // ink-bounds measurement reads 0.0lp for every count form, including the
    // 99+ overflow form.
    //
    // Vertically, the current code carries a small, real, FONT-INTRINSIC
    // bias that is not a layout defect: Roboto's digit glyphs (and,
    // separately, its `+` glyph) do not sit exactly centered within their own
    // line-box ascent/descent, even when that line box itself is perfectly
    // centered in the badge. Measured directly: -0.6lp uniformly across
    // every count form (3, 5, 42, 99, 99+) at fontSize 12 -- sub-pixel at any
    // real device pixel ratio, and NOT something this widget's layout can
    // correct, since it is a property of the glyphs themselves, not of the
    // constraint chain. Two compensation attempts were tried and rejected:
    // `StrutStyle(forceStrutHeight: true)` and
    // `TextHeightBehavior(applyHeightToFirstAscent/LastDescent: false)` each
    // shifted the bias to a DIFFERENT, larger value per content string (up to
    // 1.1lp) instead of removing it, because digits and `+` have different
    // vertical ink centers relative to each other -- there is no single
    // strut/height adjustment that centers both simultaneously. The
    // horizontal tolerance below stays tight (this is where the real,
    // measured 3.0lp defect lived); the vertical tolerance is set to admit
    // the known-harmless ~0.6lp font-intrinsic bias while still catching a
    // genuine multi-pixel regression.
    const horizontalTolerance = 0.5;
    const verticalTolerance = 0.75;

    /// Pumps a [LayrzBadgeVisual] displaying [count] and returns the badge's
    /// painted `Container` rect alongside the real, ink-tight bounding rect
    /// of its digit glyphs (in the same global coordinate space), after
    /// registering a real Roboto font so glyph metrics are representative of
    /// a production render rather than the test-font fallback.
    Future<(Rect box, Rect ink)> pumpAndMeasureInk(WidgetTester tester, int count) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await loadRealRobotoFont(tester);
      await pumpThemed(tester, LayrzBadgeVisual(count: count));

      final boxRect = tester.getRect(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );

      final text = LayrzBadgeVisual.formatCount(count);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
      final tightBoxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
        boxHeightStyle: ui.BoxHeightStyle.tight,
        boxWidthStyle: ui.BoxWidthStyle.tight,
      );

      double minLeft = double.infinity, minTop = double.infinity;
      double maxRight = -double.infinity, maxBottom = -double.infinity;
      for (final b in tightBoxes) {
        minLeft = minLeft < b.left ? minLeft : b.left;
        minTop = minTop < b.top ? minTop : b.top;
        maxRight = maxRight > b.right ? maxRight : b.right;
        maxBottom = maxBottom > b.bottom ? maxBottom : b.bottom;
      }
      final topLeftGlobal = paragraph.localToGlobal(Offset(minLeft, minTop));
      final bottomRightGlobal = paragraph.localToGlobal(Offset(maxRight, maxBottom));
      final inkRect = Rect.fromPoints(topLeftGlobal, bottomRightGlobal);

      return (boxRect, inkRect);
    }

    guardedTestWidgets('a 1-digit count (3) has its glyph ink centered both horizontally and vertically', (
      tester,
    ) async {
      final (box, ink) = await pumpAndMeasureInk(tester, 3);

      expect((ink.center.dx - box.center.dx).abs(), lessThan(horizontalTolerance));
      expect((ink.center.dy - box.center.dy).abs(), lessThan(verticalTolerance));
    });

    guardedTestWidgets('a single-digit count (5) has its glyph ink centered both horizontally and vertically', (
      tester,
    ) async {
      final (box, ink) = await pumpAndMeasureInk(tester, 5);

      expect((ink.center.dx - box.center.dx).abs(), lessThan(horizontalTolerance));
      expect((ink.center.dy - box.center.dy).abs(), lessThan(verticalTolerance));
    });

    guardedTestWidgets('a 2-digit count (42) has its glyph ink centered both horizontally and vertically', (
      tester,
    ) async {
      final (box, ink) = await pumpAndMeasureInk(tester, 42);

      expect((ink.center.dx - box.center.dx).abs(), lessThan(horizontalTolerance));
      expect((ink.center.dy - box.center.dy).abs(), lessThan(verticalTolerance));
    });

    guardedTestWidgets('the 99+ overflow form has its glyph ink centered both horizontally and vertically', (
      tester,
    ) async {
      final (box, ink) = await pumpAndMeasureInk(tester, 250);

      expect((ink.center.dx - box.center.dx).abs(), lessThan(horizontalTolerance));
      expect((ink.center.dy - box.center.dy).abs(), lessThan(verticalTolerance));
    });

    guardedTestWidgets('the boundary value 99 has its glyph ink centered both horizontally and vertically', (
      tester,
    ) async {
      final (box, ink) = await pumpAndMeasureInk(tester, 99);

      expect((ink.center.dx - box.center.dx).abs(), lessThan(horizontalTolerance));
      expect((ink.center.dy - box.center.dy).abs(), lessThan(verticalTolerance));
    });

    guardedTestWidgets(
      'regression guard: the Text content is explicitly center-aligned '
      '(without this, the ink-bounds assertions above would fail)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(tester, const LayrzBadgeVisual(count: 3));

        final textWidget = tester.widget<Text>(find.text('3'));
        expect(textWidget.textAlign, equals(TextAlign.center));
      },
    );
  });

  group('LayrzBadgeVisual icon and dot centering', () {
    guardedTestWidgets('an icon glyph is centered both horizontally and vertically', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzBadgeVisual(icon: MdiIcons.bell));

      final boxRect = tester.getRect(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );
      final iconRect = tester.getRect(find.byType(Icon));

      expect((iconRect.center.dx - boxRect.center.dx).abs(), lessThan(0.5));
      expect((iconRect.center.dy - boxRect.center.dy).abs(), lessThan(0.5));
    });

    guardedTestWidgets('a bare presence dot renders as a perfect circle (equal width and height)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzBadgeVisual());

      final boxRect = tester.getRect(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );

      expect(boxRect.width, equals(boxRect.height));
    });

    guardedTestWidgets(
      'a bare presence dot is smaller than a count/icon badge (DESIGN-172)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const dotKey = Key('dot-under-test');
        const countKey = Key('count-under-test');

        await pumpThemed(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LayrzBadgeVisual(key: dotKey),
              const LayrzBadgeVisual(count: 5, key: countKey),
            ],
          ),
        );

        final dotSize = tester.getSize(find.byKey(dotKey));
        final countSize = tester.getSize(find.byKey(countKey));

        // The dot must be strictly smaller in both axes than a count badge --
        // not merely narrower (a count badge is already only as tall as
        // `diameter`, so height is the axis this guards most directly), and
        // it must still be a circle (equal width/height) at its own size.
        expect(dotSize.width, lessThan(countSize.width));
        expect(dotSize.height, lessThan(countSize.height));
        expect(dotSize.width, equals(dotSize.height));

        // Derived from the spacing token scale (`tokens.spacing.sp2`), not a
        // magic number -- see the `diameter` computation in
        // `lib/src/badges/src/badge_visual.dart`.
        final tokens = LayrzTheme.of(tester.element(find.byKey(dotKey))).tokens;
        expect(dotSize.width, equals(tokens.spacing.sp2));
        expect(countSize.width, equals(tokens.spacing.sp4));
      },
    );

    guardedTestWidgets('a bare presence dot does not balloon when overlaid on a large child', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Regression test for a defect found alongside the centering fix:
      // `Container.build` special-cases a literal `null` child together with
      // non-tight constraints (this badge's `minWidth`/`minHeight`-only
      // constraints qualify) by substituting a widget that fills whatever
      // bounded space it is handed -- so a bare dot rendered with `child:
      // null` ballooned to the decorated child's own size under
      // `LayrzBadge`'s `Positioned.fill` -> `Align` -> `FractionalTranslation`
      // overlay, exactly like the count/icon forms did before the
      // `alignment:`-avoidance fix. `LayrzBadgeVisual` passes a zero-size
      // `SizedBox.shrink()` instead of `null` specifically to keep `Container`
      // off that special-cased path.
      await pumpThemed(
        tester,
        LayrzBadge(label: 'Online status', child: const SizedBox(width: 200, height: 200)),
      );

      final dotSize = tester.getSize(find.byType(LayrzBadgeVisual));

      expect(dotSize.width, lessThan(100));
      expect(dotSize.height, lessThan(100));
      expect(dotSize.width, equals(dotSize.height));
    });

    guardedTestWidgets('a bare presence dot does not balloon standalone in an unbounded-height Row', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Same defect as above, exercised via the standalone/inline usage this
      // widget documents as its reason for existing (a badge sitting inline
      // next to a label, e.g. `LayrzLayoutRailItem`'s shape) rather than via
      // the `LayrzBadge` overlay.
      await pumpThemed(
        tester,
        SizedBox(
          height: 400,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [LayrzBadgeVisual()],
          ),
        ),
      );

      final dotSize = tester.getSize(find.byType(LayrzBadgeVisual));

      expect(dotSize.height, lessThan(100));
      expect(dotSize.width, equals(dotSize.height));
    });

    guardedTestWidgets(
      'a bare presence dot overlaid on an avatar still positions at the corner, not lost under the edge',
      (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // DESIGN-172: shrinking the dot must not regress its overlay
        // position -- it should still read as attached to the avatar's
        // corner rather than disappearing under the child's edge or drifting
        // away from it. `FractionalTranslation`'s translation is scaled to
        // the badge's OWN size, so a smaller dot self-adjusts proportionally
        // and this assertion holds regardless of the exact diameter chosen.
        const avatarKey = Key('avatar-under-test');

        await pumpThemed(
          tester,
          LayrzBadge(
            label: 'Online status',
            alignment: LayrzBadgeAlignment.bottomRight,
            child: const SizedBox(key: avatarKey, width: 40, height: 40),
          ),
        );

        final avatarRect = tester.getRect(find.byKey(avatarKey));
        final dotRect = tester.getRect(find.byType(LayrzBadgeVisual));

        // The dot's center must sit at (or very near) the avatar's
        // bottom-right corner -- not deep inside the avatar (which would
        // read as floating in the middle of it) and not so far outside that
        // it looks detached.
        const positionTolerance = 6.0;
        expect((dotRect.center.dx - avatarRect.right).abs(), lessThan(positionTolerance));
        expect((dotRect.center.dy - avatarRect.bottom).abs(), lessThan(positionTolerance));
      },
    );
  });

  group('LayrzBadgeVisual overlay sizing regression', () {
    guardedTestWidgets('does not expand to a large decorated child\'s size when overlaid', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const bareKey = Key('bare-visual-for-centering');

      await pumpThemed(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LayrzBadgeVisual(count: 42, key: bareKey),
            LayrzBadge(
              label: 'Notifications',
              count: 42,
              child: const SizedBox(width: 300, height: 300),
            ),
          ],
        ),
      );

      final bareSize = tester.getSize(find.byKey(bareKey));
      final overlaySize = tester.getSize(
        find.descendant(of: find.byType(LayrzBadge), matching: find.byType(LayrzBadgeVisual)),
      );

      expect(overlaySize, equals(bareSize));
      // Guards the centering fix specifically: the `Center` added inside the
      // badge's own `Padding` must stay shrink-wrapped (via widthFactor/
      // heightFactor) rather than filling the ambient bounded-but-loose
      // constraints the overlay hands it -- a factor-less `Center` here
      // would reproduce the exact ballooning `Container.alignment` caused.
      expect(overlaySize.width, lessThan(100));
      expect(overlaySize.height, lessThan(100));
    });
  });
}

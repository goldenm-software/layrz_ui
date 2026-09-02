import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/no_overflow.dart';
import '../helpers/pump_themed.dart';

void main() {
  group('LayrzBadgeVisual count centering (DESIGN-167 follow-up)', () {
    // Regression suite for the "the # must be centered" defect: symmetric
    // padding alone only centers content when the padded content happens to
    // measure exactly `diameter` -- otherwise `ConstrainedBox`'s minWidth/
    // minHeight slack was dumped entirely on the right/bottom by
    // `RenderPadding`, biasing every count form up-and-left of true center
    // (and single digits additionally left-of-center, since only they fall
    // short of `diameter` horizontally too). Each case below computes the
    // rendered `Text`'s rect and the badge's own painted box rect and asserts
    // their centers coincide, rather than trusting a bare "renders" check.

    /// Returns the badge's painted `Container` rect and the digit `Text`'s
    /// rect for a [LayrzBadgeVisual] displaying [count], after pumping it
    /// into a themed tree at a fixed, explicit viewport.
    Future<(Rect box, Rect text)> pumpAndMeasure(WidgetTester tester, int count) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, LayrzBadgeVisual(count: count));

      final boxRect = tester.getRect(
        find.descendant(of: find.byType(LayrzBadgeVisual), matching: find.byType(Container)).first,
      );
      final textRect = tester.getRect(find.text(LayrzBadgeVisual.formatCount(count)));
      return (boxRect, textRect);
    }

    /// Sub-pixel tolerance for center-coincidence assertions. Layout in this
    /// widget is exact arithmetic on the values under test (no rounding from
    /// device pixel snapping is expected at devicePixelRatio 1.0), so this is
    /// deliberately tight -- it exists only to absorb floating-point noise,
    /// not to paper over a real offset.
    const tolerance = 0.5;

    guardedTestWidgets('a 1-digit count (3) is centered both horizontally and vertically', (tester) async {
      final (box, text) = await pumpAndMeasure(tester, 3);

      expect((text.center.dx - box.center.dx).abs(), lessThan(tolerance));
      expect((text.center.dy - box.center.dy).abs(), lessThan(tolerance));
    });

    guardedTestWidgets('a single-digit count (5) is centered both horizontally and vertically', (tester) async {
      final (box, text) = await pumpAndMeasure(tester, 5);

      expect((text.center.dx - box.center.dx).abs(), lessThan(tolerance));
      expect((text.center.dy - box.center.dy).abs(), lessThan(tolerance));
    });

    guardedTestWidgets('a 2-digit count (42) is centered both horizontally and vertically', (tester) async {
      final (box, text) = await pumpAndMeasure(tester, 42);

      expect((text.center.dx - box.center.dx).abs(), lessThan(tolerance));
      expect((text.center.dy - box.center.dy).abs(), lessThan(tolerance));
    });

    guardedTestWidgets('the 99+ overflow form is centered both horizontally and vertically', (tester) async {
      final (box, text) = await pumpAndMeasure(tester, 250);

      expect((text.center.dx - box.center.dx).abs(), lessThan(tolerance));
      expect((text.center.dy - box.center.dy).abs(), lessThan(tolerance));
    });

    guardedTestWidgets('the boundary value 99 is centered both horizontally and vertically', (tester) async {
      final (box, text) = await pumpAndMeasure(tester, 99);

      expect((text.center.dx - box.center.dx).abs(), lessThan(tolerance));
      expect((text.center.dy - box.center.dy).abs(), lessThan(tolerance));
    });
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

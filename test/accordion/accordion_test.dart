import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';
import '../helpers/pump_themed_app.dart';

/// A marker widget used as the accordion body so tests can assert its
/// presence/absence in the tree without depending on incidental descendants
/// (like [Text]) that other parts of the header also render.
class _BodyMarker extends StatelessWidget {
  const _BodyMarker();

  @override
  Widget build(BuildContext context) => const Text('body-marker-content');
}

/// Pumps [LayrzAccordion] at both a wide (1600x1200) and a narrow (400x800)
/// viewport, running [verify] against each. The accordion's layout does not
/// branch on `context.isCompact`, but both directions are exercised anyway to
/// guard against a future regression that makes it start doing so silently.
Future<void> _pumpAtBothViewports(
  WidgetTester tester,
  Widget Function() build,
  Future<void> Function() verify,
) async {
  for (final size in [const Size(1600, 1200), const Size(400, 800)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpThemed(tester, build());
    await verify();
  }
}

void main() {
  group('LayrzAccordion', () {
    testWidgets('renders title and leading icon in the header', (tester) async {
      await _pumpAtBothViewports(
        tester,
        () => LayrzAccordion(
          titleText: 'Section title',
          leadingIcon: MdiIcons.folderOutline,
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
        () async {
          expect(find.text('Section title'), findsOneWidget);
          expect(find.byIcon(MdiIcons.folderOutline), findsOneWidget);
        },
      );
    });

    testWidgets('omits leading icon space when leadingIcon is null', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'No icon',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      // Only the trailing chevron icon should be present -- no leading icon.
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('collapsed body is genuinely absent from the tree', (tester) async {
      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Collapsible',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('expanded body is present in the tree', (tester) async {
      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Expanded',
          expanded: true,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsOneWidget);
    });

    testWidgets('body is removed again after collapsing from expanded', (tester) async {
      bool expanded = true;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzAccordion(
            titleText: 'Toggle me',
            expanded: expanded,
            onExpansionChanged: (value) => setState(() => expanded = value),
            body: const _BodyMarker(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(_BodyMarker), findsOneWidget);

      await tester.tap(find.text('Toggle me'));
      await tester.pumpAndSettle();

      expect(expanded, isFalse);
      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('tapping anywhere on the header toggles -- not only the chevron', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Whole header target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      // Tap directly on the title text, nowhere near the chevron.
      await tester.tap(find.text('Whole header target'));
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('tapping the chevron also toggles', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Chevron target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.byIcon(MdiIcons.chevronDown));
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('is a fully controlled component -- expanded does not change without a rebuild', (tester) async {
      int callCount = 0;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Controlled',
          expanded: false,
          onExpansionChanged: (_) => callCount++,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.text('Controlled'));
      await tester.pumpAndSettle();

      // The callback fired, but since the test never fed the new value back in,
      // the widget's own `expanded` prop is still false -- so the body stays absent.
      expect(callCount, equals(1));
      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('disabled (onExpansionChanged null) does not toggle on tap', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Disabled',
          expanded: false,
          body: const _BodyMarker(),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('toggles when Enter is pressed while focused', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Keyboard target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('toggles when Space is pressed while focused', (tester) async {
      bool? lastValue;

      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Space target',
          expanded: false,
          onExpansionChanged: (value) => lastValue = value,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('does not respond to keyboard activation when disabled', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Disabled keyboard',
          expanded: false,
          body: const _BodyMarker(),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsNothing);
    });

    testWidgets('reacts to an externally-driven expanded flip', (tester) async {
      final expandedNotifier = ValueNotifier<bool>(false);
      addTearDown(expandedNotifier.dispose);

      await pumpThemedApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: expandedNotifier,
          builder: (context, expanded, _) => LayrzAccordion(
            titleText: 'External control',
            expanded: expanded,
            onExpansionChanged: (value) => expandedNotifier.value = value,
            body: const _BodyMarker(),
          ),
        ),
      );

      expect(find.byType(_BodyMarker), findsNothing);

      // Flip programmatically, as if driven by state outside the accordion --
      // not via a tap on the header itself.
      expandedNotifier.value = true;
      await tester.pumpAndSettle();

      expect(find.byType(_BodyMarker), findsOneWidget);
    });

    testWidgets('header background color does not change size across hover/press (D15)', (tester) async {
      await pumpThemedApp(
        tester,
        LayrzAccordion(
          titleText: 'Geometry check',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      final beforeSize = tester.getSize(find.byType(LayrzAccordion));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterSize = tester.getSize(find.byType(LayrzAccordion));

      expect(beforeSize, equals(afterSize));
    });

    testWidgets('expanded body surface shares the header background color -- no seam', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Continuous surface',
          expanded: true,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      final headerContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final headerColor = (headerContainer.decoration as BoxDecoration).color;

      final bodyDecoratedBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(_BodyMarker), matching: find.byType(DecoratedBox)).first,
      );
      final bodyColor = (bodyDecoratedBox.decoration as BoxDecoration).color;

      expect(bodyColor, equals(headerColor));
    });

    /// Locates the border-carrying [DecoratedBox] built by `_buildPanelShell`
    /// -- the shell that owns the border and corner radius enclosing both the
    /// header and the body.
    ///
    /// `_buildPanelShell` no longer wraps this box in a [ClipRRect] (removed
    /// to fix a left/right edge seam where the clip's antialiasing fought the
    /// border's own antialiased stroke -- see that method's doc comment), so
    /// this is now found by its own decoration: it is the [DecoratedBox] in
    /// [LayrzAccordion]'s subtree whose [BoxDecoration.border] is non-null,
    /// distinguishing it from the outer, shadow-only box [shadowDecoratedBox]
    /// locates and from any [DecoratedBox] the header or body paint
    /// internally (none of which set a border).
    DecoratedBox outerShellDecoratedBox(WidgetTester tester) {
      return tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).border != null,
        ),
      );
    }

    /// Locates the shadow-carrying [DecoratedBox] built by `_buildPanelShell`
    /// -- the outer node that wraps the border/[Column] stack and carries
    /// only [BoxDecoration.boxShadow] and the shared, animated border radius,
    /// with no border of its own.
    ///
    /// Matched by the presence of a non-null [BoxDecoration.boxShadow] key
    /// rather than merely the absence of a border: while expanded, the
    /// body's own background [DecoratedBox] (see `_buildBodyReveal`) also
    /// sets a border-less [BoxDecoration.borderRadius] for its rounded bottom
    /// corners, so "no border" alone would match two boxes once the body is
    /// present. Only `_buildPanelShell`'s outer box ever sets [boxShadow], so
    /// keying on that (even an empty, faded-to-nothing list still satisfies
    /// "not null") stays unambiguous in every expansion state.
    DecoratedBox shadowDecoratedBox(WidgetTester tester) {
      return tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).boxShadow != null,
        ),
      );
    }

    BorderRadius outerShellBorderRadius(WidgetTester tester) {
      return (outerShellDecoratedBox(tester).decoration as BoxDecoration).borderRadius! as BorderRadius;
    }

    Border outerShellBorder(WidgetTester tester) {
      return (outerShellDecoratedBox(tester).decoration as BoxDecoration).border! as Border;
    }

    /// Returns the [boxShadow] list painted by the outer, shadow-carrying
    /// [DecoratedBox], or an empty list if none is set.
    List<BoxShadow> shellShadow(WidgetTester tester) {
      return (shadowDecoratedBox(tester).decoration as BoxDecoration).boxShadow ?? const [];
    }

    testWidgets(
      'the outer shell corner radius stays uniform across the entire reveal, never interpolating',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        bool expanded = false;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => LayrzAccordion(
              titleText: 'Timeline check',
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              body: const _BodyMarker(),
            ),
          ),
        );

        // Fully collapsed: all four corners are rounded, matching a
        // standalone header with no body attached.
        expect(outerShellBorderRadius(tester).bottomLeft, equals(const Radius.circular(10.0)));
        expect(outerShellBorderRadius(tester).topLeft, equals(const Radius.circular(10.0)));

        await tester.tap(find.text('Timeline check'));
        await tester.pump();

        // Pump to roughly the midpoint of the 200ms dTransition reveal. The
        // corner radius must not move at all during the reveal -- only the
        // shadow and the internal divider are still keyed to this timeline.
        await tester.pump(const Duration(milliseconds: 100));

        final midRadius = outerShellBorderRadius(tester);
        expect(
          midRadius.bottomLeft,
          equals(const Radius.circular(10.0)),
          reason: 'corner radius must stay constant mid-reveal, not interpolate toward square',
        );
        expect(midRadius.topLeft, equals(const Radius.circular(10.0)));

        await tester.pumpAndSettle();

        // Fully expanded and settled: still uniformly rounded on all four
        // corners -- expansion never squares off the bottom.
        final expandedRadius = outerShellBorderRadius(tester);
        expect(expandedRadius.topLeft, equals(const Radius.circular(10.0)));
        expect(expandedRadius.topRight, equals(const Radius.circular(10.0)));
        expect(expandedRadius.bottomLeft, equals(const Radius.circular(10.0)));
        expect(expandedRadius.bottomRight, equals(const Radius.circular(10.0)));
      },
    );

    testWidgets(
      'at full expansion, a single continuous (now fully transparent) border shape encloses header and body',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpThemed(
          tester,
          LayrzAccordion(
            titleText: 'Continuous border',
            expanded: true,
            onExpansionChanged: (_) {},
            body: const _BodyMarker(),
          ),
        );
        await tester.pumpAndSettle();

        // Exactly one DecoratedBox draws the panel's outer border -- there is
        // no second, independently-clipped border around the header alone
        // (the defect this fix removes) and none around the body alone.
        final border = outerShellBorder(tester);

        // All four sides still share one continuous color and width -- a
        // single Border.all, not four independently-resolved sides that
        // could drift -- even though that shared color is now fully faded.
        expect(border.top.color, equals(border.bottom.color));
        expect(border.left.color, equals(border.right.color));
        expect(border.top.width, equals(border.bottom.width));
        expect(border.left.width, equals(border.right.width));

        // Border and shadow are mutually exclusive at full expansion: the
        // border has faded to fully transparent (alpha ~0) so the shadow
        // alone defines the panel's edge, per the "border on closed, shadow
        // on opened" design. Width stays the constant token width -- only
        // the color's alpha animates, never geometry.
        expect(border.top.color.a, closeTo(0.0, 0.001));
        expect(border.top.width, equals(LayrzTokens.light().border.base));

        // The body is present beneath this same shell, proving the border
        // shape encloses header and body together rather than only the
        // header.
        expect(find.byType(_BodyMarker), findsOneWidget);

        // Bottom corners stay rounded, equal to the top corners, even while
        // expanded -- the panel always reads as one consistently rounded
        // card, never squaring off at the bottom once open.
        expect(outerShellBorderRadius(tester).bottomLeft, equals(const Radius.circular(10.0)));
        expect(outerShellBorderRadius(tester).bottomRight, equals(const Radius.circular(10.0)));
        expect(outerShellBorderRadius(tester).topLeft, equals(const Radius.circular(10.0)));
        expect(outerShellBorderRadius(tester).topRight, equals(const Radius.circular(10.0)));
      },
    );

    testWidgets('at full expansion, the panel is elevated with a full-strength drop shadow', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Elevated when expanded',
          expanded: true,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      final tokens = LayrzTokens.light();
      final expectedShadow = tokens.shadow.elevation2;
      final shadow = shellShadow(tester);

      expect(shadow, isNotEmpty, reason: 'a fully expanded panel must carry a visible drop shadow');
      expect(shadow.length, equals(expectedShadow.length));
      for (var i = 0; i < shadow.length; i++) {
        // Full elevation -- the shadow's alpha should be at (or effectively
        // at) the resolved elevation2 token's own alpha, not faded.
        expect(shadow[i].color.a, closeTo(expectedShadow[i].color.a, 0.01));
        expect(shadow[i].blurRadius, equals(expectedShadow[i].blurRadius));
        expect(shadow[i].offset, equals(expectedShadow[i].offset));
      }

      // Border and shadow are mutually exclusive: at full expansion the
      // border has faded fully out (alpha ~0), since the shadow alone now
      // defines the panel's edge -- it has not been "replaced" by removing
      // the BorderSide, only faded to transparent while its width and shape
      // stay in place.
      final border = outerShellBorder(tester);
      expect(border.top.color.a, closeTo(0.0, 0.001));
    });

    testWidgets('when collapsed, the panel is flat -- no visible drop shadow', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Flat when collapsed',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );
      await tester.pumpAndSettle();

      final shadow = shellShadow(tester);

      // Either no shadows at all, or every shadow faded to (near) zero alpha.
      final allInvisible = shadow.every((s) => s.color.a < 0.001);
      expect(allInvisible, isTrue, reason: 'a collapsed panel must read as flat -- no visible shadow');

      // The border must be at full alpha while collapsed -- this was already
      // true before elevation was added, and must remain so: collapsed reads
      // as a bordered, flat card with no shadow to help delineate it.
      final border = outerShellBorder(tester);
      final tokens = LayrzTokens.light();
      expect(border.bottom.color.a, closeTo(tokens.colors.fg3.a, 0.001));
    });

    testWidgets(
      'the shadow fades in and the border fades out continuously with expansion progress, as an inverse cross-fade',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        bool expanded = false;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => LayrzAccordion(
              titleText: 'Shadow timeline check',
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              body: const _BodyMarker(),
            ),
          ),
        );

        final tokens = LayrzTokens.light();
        final fullShadowAlpha = tokens.shadow.elevation2.first.color.a;
        final fullBorderAlpha = tokens.colors.fg3.a;

        // Collapsed: no visible shadow, full-alpha border.
        expect(shellShadow(tester).every((s) => s.color.a < 0.001), isTrue);
        expect(outerShellBorder(tester).top.color.a, closeTo(fullBorderAlpha, 0.001));

        await tester.tap(find.text('Shadow timeline check'));
        await tester.pump();
        // Roughly the midpoint of the 200ms dTransition reveal.
        await tester.pump(const Duration(milliseconds: 100));

        final midShadow = shellShadow(tester);
        final midBorderAlpha = outerShellBorder(tester).top.color.a;

        expect(midShadow, isNotEmpty);
        // Mid-flight the shadow must be partially faded in -- neither fully
        // absent (0) nor already at full strength -- proving it interpolates
        // in lockstep with the same reveal animation rather than blinking in
        // once the body finishes revealing.
        expect(
          midShadow.first.color.a,
          allOf(greaterThan(0.0), lessThan(fullShadowAlpha)),
          reason: 'shadow alpha must be interpolating mid-reveal, not stuck at either end',
        );

        // The border must be the exact inverse: also partially faded, never
        // fully opaque nor fully transparent mid-flight -- a clean cross-fade
        // against the shadow rather than a border that lingers at full
        // strength while the shadow comes in on top of it.
        expect(
          midBorderAlpha,
          allOf(greaterThan(0.0), lessThan(fullBorderAlpha)),
          reason: 'border alpha must be interpolating (fading out) mid-reveal, not stuck at either end',
        );

        // The two fractions must sum to ~1: exactly what "fades in" and
        // "fades out" mean for the same underlying progress value.
        final shadowFraction = midShadow.first.color.a / fullShadowAlpha;
        final borderFraction = midBorderAlpha / fullBorderAlpha;
        expect(
          shadowFraction + borderFraction,
          closeTo(1.0, 0.02),
          reason: 'border and shadow must be an inverse cross-fade of the same progress value',
        );

        await tester.pumpAndSettle();
        expect(shellShadow(tester).first.color.a, closeTo(fullShadowAlpha, 0.01));
        expect(outerShellBorder(tester).top.color.a, closeTo(0.0, 0.001));
      },
    );

    testWidgets('when collapsed, the outer shell is fully rounded like a standalone header', (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(
        tester,
        LayrzAccordion(
          titleText: 'Collapsed shell',
          expanded: false,
          onExpansionChanged: (_) {},
          body: const _BodyMarker(),
        ),
      );

      final radius = outerShellBorderRadius(tester);
      expect(radius.topLeft, equals(const Radius.circular(10.0)));
      expect(radius.topRight, equals(const Radius.circular(10.0)));
      expect(radius.bottomLeft, equals(const Radius.circular(10.0)));
      expect(radius.bottomRight, equals(const Radius.circular(10.0)));

      final border = outerShellBorder(tester);
      expect(border.bottom, isNot(equals(BorderSide.none)));
    });

    testWidgets('the body reveal animates smoothly -- mid-flight height is strictly between 0 and full', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool expanded = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzAccordion(
            titleText: 'Reveal timeline check',
            expanded: expanded,
            onExpansionChanged: (value) => setState(() => expanded = value),
            body: const SizedBox(height: 200, child: _BodyMarker()),
          ),
        ),
      );

      await tester.tap(find.text('Reveal timeline check'));
      await tester.pump();
      // Roughly the midpoint of the 200ms dTransition reveal.
      await tester.pump(const Duration(milliseconds: 100));

      // The body's own intrinsic size stays 200 throughout -- it is the
      // enclosing ClipRect (sized by Align's heightFactor) that shrinks to
      // the currently-revealed height, so that ancestor is what must be
      // measured to observe the reveal in flight.
      final clipRectFinder = find.ancestor(of: find.byType(_BodyMarker), matching: find.byType(ClipRect));
      final midHeight = tester.getSize(clipRectFinder.first).height;
      expect(
        midHeight,
        allOf(greaterThan(0.0), lessThan(200.0)),
        reason: 'mid-reveal the body must be partially clipped, not fully collapsed or fully open',
      );

      await tester.pumpAndSettle();

      final finalHeight = tester.getSize(clipRectFinder.first).height;
      expect(finalHeight, closeTo(200.0, 0.5));
    });

    /// Returns the [BorderRadius] painted by the header's own fill
    /// [BoxDecoration], as built by `_buildHeader`.
    ///
    /// This is the header's *own* rounded corners -- distinct from
    /// [outerShellBorderRadius]'s box, which is the outer bordered/shadowed
    /// shell built by `_buildPanelShell`. DESIGN-92: the header fill used to
    /// have no [BorderRadius] of its own at all (a plain rectangular
    /// [AnimatedContainer.color] fill), so its square corners bled past the
    /// outer shell's rounded stroke -- visible as a background-colored
    /// corner artifact wherever the fill reached the panel's own edge. The
    /// top corners are rounded in every state; the bottom corners are
    /// rounded only while collapsed (where the header is the whole panel)
    /// and interpolate down to square as the panel expands (where the body
    /// sits flush below, and the header/body seam must stay a plain
    /// hairline). This helper locates the header's own decoration to assert
    /// that regression stays fixed in both directions.
    BorderRadius headerFillBorderRadius(WidgetTester tester) {
      final headerContainer = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      return (headerContainer.decoration as BoxDecoration).borderRadius! as BorderRadius;
    }

    testWidgets(
      'DESIGN-92: header fill top corners are always rounded; bottom corners rounded only while collapsed',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        bool expanded = false;

        await pumpThemedApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => LayrzAccordion(
              titleText: 'Corner artifact check',
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              body: const _BodyMarker(),
            ),
          ),
        );

        // Collapsed: the header fill's top corners must already match the
        // outer shell's rounded radius -- not square -- or a sliver of the
        // fill color would peek out past the border's rounded stroke.
        final collapsedShellRadius = outerShellBorderRadius(tester);
        final collapsedHeaderRadius = headerFillBorderRadius(tester);
        expect(collapsedHeaderRadius.topLeft, equals(collapsedShellRadius.topLeft));
        expect(collapsedHeaderRadius.topRight, equals(collapsedShellRadius.topRight));
        // Collapsed, the header IS the whole panel -- its bottom corners
        // are the panel's own bottom corners, and must match the shell
        // radius too, or the same corner-bleed defect the top corners had
        // shows up at the bottom of a closed panel instead.
        expect(collapsedHeaderRadius.bottomLeft, equals(collapsedShellRadius.bottomLeft));
        expect(collapsedHeaderRadius.bottomRight, equals(collapsedShellRadius.bottomRight));
        // The radius itself must never be zero (i.e. this is genuinely
        // rounded, not a coincidental match against an also-square value).
        expect(collapsedHeaderRadius.topLeft, isNot(equals(Radius.zero)));
        expect(collapsedHeaderRadius.bottomLeft, isNot(equals(Radius.zero)));

        await tester.tap(find.text('Corner artifact check'));
        await tester.pump();
        // Roughly the midpoint of the 200ms dTransition reveal.
        await tester.pump(const Duration(milliseconds: 100));

        // Mid-reveal: the bottom radius must be strictly between the full
        // collapsed radius and zero -- proving it interpolates smoothly
        // with progress rather than snapping abruptly at either end. The
        // top radius, meanwhile, must not move at all.
        final midHeaderRadius = headerFillBorderRadius(tester);
        expect(midHeaderRadius.topLeft, equals(collapsedShellRadius.topLeft));
        expect(midHeaderRadius.topRight, equals(collapsedShellRadius.topRight));
        expect(
          midHeaderRadius.bottomLeft.x,
          allOf(greaterThan(0.0), lessThan(collapsedShellRadius.bottomLeft.x)),
          reason: 'bottom radius must be interpolating mid-reveal, not stuck at either end',
        );

        await tester.pumpAndSettle();

        // Expanded and settled: the header fill's top corners must still
        // match the shell radius. At full expansion the outer border has
        // faded to fully transparent (see the cross-fade tests above), so
        // the header fill's own top corners are the only thing defining the
        // panel's top edge -- they must read as rounded, never square.
        final expandedShellRadius = outerShellBorderRadius(tester);
        final expandedHeaderRadius = headerFillBorderRadius(tester);
        expect(expandedHeaderRadius.topLeft, equals(expandedShellRadius.topLeft));
        expect(expandedHeaderRadius.topRight, equals(expandedShellRadius.topRight));
        // But the bottom corners must now be square: the body sits flush
        // beneath the header, and the header/body seam must stay a plain
        // hairline, not a rounded notch.
        expect(expandedHeaderRadius.bottomLeft, equals(Radius.zero));
        expect(expandedHeaderRadius.bottomRight, equals(Radius.zero));
      },
    );

    testWidgets('rotates the chevron between collapsed and expanded', (tester) async {
      bool expanded = false;

      await pumpThemedApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => LayrzAccordion(
            titleText: 'Rotation check',
            expanded: expanded,
            onExpansionChanged: (value) => setState(() => expanded = value),
            body: const _BodyMarker(),
          ),
        ),
      );

      final collapsedRotation = tester.widget<RotationTransition>(find.byType(RotationTransition));
      expect(collapsedRotation.turns.value, equals(0.0));

      await tester.tap(find.text('Rotation check'));
      await tester.pumpAndSettle();

      final expandedRotation = tester.widget<RotationTransition>(find.byType(RotationTransition));
      expect(expandedRotation.turns.value, equals(0.5));
    });
  });
}

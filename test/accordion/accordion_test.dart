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
    /// header and the body. It sits directly inside the outermost
    /// [ClipRRect] under [LayrzAccordion], one level above every other
    /// [DecoratedBox] the header/body themselves might paint.
    ///
    /// This is the *inner* of the two [DecoratedBox]es `_buildPanelShell`
    /// builds -- the one still inside the [ClipRRect]. The border was left
    /// here (rather than hoisted to the outer, shadow-carrying box) when the
    /// DESIGN-92 follow-up added elevation, so this helper's search --
    /// descendant of the first [ClipRRect] -- still finds it unchanged.
    DecoratedBox outerShellDecoratedBox(WidgetTester tester) {
      return tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(ClipRRect).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
    }

    /// Locates the shadow-carrying [DecoratedBox] built by `_buildPanelShell`
    /// -- the outer node that wraps the panel's [ClipRRect] and carries only
    /// [BoxDecoration.boxShadow] and the shared, animated border radius. It is
    /// the ancestor of, not a descendant inside, the outermost [ClipRRect] --
    /// unlike [outerShellDecoratedBox] above -- since a shadow painted inside
    /// the clip would be clipped away and never render (see
    /// `_buildPanelShell`'s doc comment).
    DecoratedBox shadowDecoratedBox(WidgetTester tester) {
      return tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byType(ClipRRect).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
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

    testWidgets('at full expansion, a single continuous border encloses header and body', (tester) async {
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

      expect(border.top, isNot(equals(BorderSide.none)), reason: 'top side must be present');
      expect(border.left, isNot(equals(BorderSide.none)), reason: 'left side must be present');
      expect(border.right, isNot(equals(BorderSide.none)), reason: 'right side must be present');
      expect(border.bottom, isNot(equals(BorderSide.none)), reason: 'bottom side must be present');

      // All four sides share one continuous color and width -- a single
      // Border.all, not four independently-resolved sides that could drift.
      expect(border.top.color, equals(border.bottom.color));
      expect(border.left.color, equals(border.right.color));
      expect(border.top.width, equals(border.bottom.width));
      expect(border.left.width, equals(border.right.width));

      // The body is present beneath this same shell, proving the border
      // encloses header and body together rather than only the header.
      expect(find.byType(_BodyMarker), findsOneWidget);

      // Bottom corners stay rounded, equal to the top corners, even while
      // expanded -- the panel always reads as one consistently rounded
      // card, never squaring off at the bottom once open.
      expect(outerShellBorderRadius(tester).bottomLeft, equals(const Radius.circular(10.0)));
      expect(outerShellBorderRadius(tester).bottomRight, equals(const Radius.circular(10.0)));
      expect(outerShellBorderRadius(tester).topLeft, equals(const Radius.circular(10.0)));
      expect(outerShellBorderRadius(tester).topRight, equals(const Radius.circular(10.0)));
    });

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

      // The border painted on the inner shell must still be visible under
      // the shadow -- elevation must not have replaced or hidden it.
      final border = outerShellBorder(tester);
      expect(border.top, isNot(equals(BorderSide.none)));
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

      // The border must still be present while collapsed -- this was already
      // true before elevation was added, and must remain so.
      final border = outerShellBorder(tester);
      expect(border.bottom, isNot(equals(BorderSide.none)));
    });

    testWidgets('the shadow fades in continuously with expansion progress, not a second timeline', (tester) async {
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

      // Collapsed: no visible shadow.
      expect(shellShadow(tester).every((s) => s.color.a < 0.001), isTrue);

      await tester.tap(find.text('Shadow timeline check'));
      await tester.pump();
      // Roughly the midpoint of the 200ms dTransition reveal.
      await tester.pump(const Duration(milliseconds: 100));

      final midShadow = shellShadow(tester);
      final tokens = LayrzTokens.light();
      final fullAlpha = tokens.shadow.elevation2.first.color.a;

      expect(midShadow, isNotEmpty);
      // Mid-flight the shadow must be partially faded in -- neither fully
      // absent (0) nor already at full strength -- proving it interpolates
      // in lockstep with the same reveal animation rather than blinking in
      // once the body finishes revealing.
      expect(
        midShadow.first.color.a,
        allOf(greaterThan(0.0), lessThan(fullAlpha)),
        reason: 'shadow alpha must be interpolating mid-reveal, not stuck at either end',
      );

      await tester.pumpAndSettle();
      expect(shellShadow(tester).first.color.a, closeTo(fullAlpha, 0.01));
    });

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

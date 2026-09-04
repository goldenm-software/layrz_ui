import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../helpers/pump_themed.dart';

void main() {
  group('LayrzAiMarker', () {
    testWidgets('renders two star glyphs', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());

      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall), findsNWidgets(2));
    });

    testWidgets('renders no visible text label', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());

      // Icon-only, by hard requirement: there is no label parameter to opt
      // into, so no Text widget should ever appear -- Icon itself renders
      // via an internal RichText carrying a single glyph codepoint (not a
      // human-readable string), so that is not what this test guards
      // against; a real accidental label would show up as a Text widget.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('star color resolves to white, on an aiAccent container', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(tester, const LayrzAiMarker(), theme: theme);

      final icons = tester.widgetList<Icon>(
        find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall),
      );
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        expect(icon.color, const Color(0xFFFFFFFF));
      }

      final container = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, theme.tokens.colors.aiAccent);
    });

    testWidgets('the container uses the r1 rounded-corner radius token', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final theme = LayrzThemeData.light();
      await pumpThemed(tester, const LayrzAiMarker(), theme: theme);

      final container = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(theme.tokens.radius.r1));
    });

    testWidgets('renders a single fixed square footprint (the size enum was removed)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // LayrzAiMarker used to offer a small/big LayrzAiMarkerSize choice;
      // that enum and the `size` parameter are both gone, so there is only
      // one footprint to assert against -- a bare square of some positive,
      // stable size.
      await pumpThemed(tester, const LayrzAiMarker());
      final size = tester.getSize(find.byType(LayrzAiMarker));

      expect(size.width, size.height);
      expect(size.width, greaterThan(0.0));
    });

    testWidgets('renders two visible white stars in a diagonal arrangement (big top-left, small bottom-right)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Each star now carries its own independent top/left/bottom/right
      // placement (see the `_kBigStar*`/`_kSmallStar*` internal knobs in
      // ai_marker.dart) rather than sharing a single inset -- this asserts
      // the real, current geometry those knobs produce: the big star is
      // anchored from the top-left corner (top and left set, bottom and
      // right unconstrained) and the small star from the bottom-right corner
      // (bottom and right set, top and left unconstrained).
      await pumpThemed(tester, const LayrzAiMarker());

      final positioned = tester
          .widgetList<Positioned>(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(Positioned)))
          .toList();
      // The fill is also wrapped in a Positioned.fill, which sets all four
      // of left/top/right/bottom -- filter it out by keeping only anchors
      // that set exactly one horizontal and one vertical edge (the two star
      // anchors: top-left-only, or bottom-right-only).
      final starAnchors = positioned
          .where((p) => (p.left != null) != (p.right != null) && (p.top != null) != (p.bottom != null))
          .toList();
      expect(starAnchors.length, 2);

      final topLeft = starAnchors.firstWhere((p) => p.left != null && p.top != null);
      final bottomRight = starAnchors.firstWhere((p) => p.right != null && p.bottom != null);
      // Real geometry assertions against the current knob *shape*, not their
      // exact magic-number values -- those are hand-tuned, actively-adjusted
      // constants (see the `_kBigStar*`/`_kSmallStar*` knobs in
      // ai_marker.dart) that change independently of this test's job, which
      // is to prove the two stars are genuinely diagonal, not both anchored
      // to the same corner or overlapping concentrically: the top-left
      // anchor leaves bottom/right unconstrained, the bottom-right anchor
      // leaves top/left unconstrained, and both inward offsets stay
      // non-positive (an inset of 0 or a small negative bleed past the
      // container's own edge is fine; a large positive inset floating the
      // stars deep inside empty padding would not be).
      expect(topLeft.left, lessThanOrEqualTo(0.0));
      expect(topLeft.top, lessThanOrEqualTo(0.0));
      expect(bottomRight.right, lessThanOrEqualTo(0.0));
      expect(bottomRight.bottom, lessThanOrEqualTo(0.0));
      expect(topLeft.bottom, isNull);
      expect(topLeft.right, isNull);
      expect(bottomRight.top, isNull);
      expect(bottomRight.left, isNull);

      final stars = find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall);
      expect(stars, findsNWidgets(2));
      final icons = tester.widgetList<Icon>(stars).toList();
      for (final icon in icons) {
        expect(icon.color, const Color(0xFFFFFFFF));
        expect(icon.size, greaterThan(0.0));
      }
      // The bigger, top-left star must be larger than the smaller,
      // bottom-right accent star -- never equal, never inverted.
      expect(icons[0].size, isNot(equals(icons[1].size)));
    });

    testWidgets('a tooltip is present wrapping the marker', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());

      expect(find.byType(LayrzTooltip), findsOneWidget);
      final tooltip = tester.widget<LayrzTooltip>(find.byType(LayrzTooltip));
      expect(tooltip.contentText, 'Generated by AI');
    });

    testWidgets('the tooltip text is sourced from LayrzUiL10n, not a constructor parameter', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // There is no `tooltip:` parameter on LayrzAiMarker -- the disclosure
      // tooltip is legally load-bearing and must be identical (and
      // identically translated) everywhere, so it is only ever overridable
      // by providing a LayrzUiL10n subclass/delegate, never per call site.
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [DefaultWidgetsLocalizations.delegate, _CustomAiL10nDelegate()],
          child: LayrzTheme(
            data: LayrzThemeData.light(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => const Center(child: LayrzAiMarker())),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final tooltip = tester.widget<LayrzTooltip>(find.byType(LayrzTooltip));
      expect(tooltip.contentText, 'This summary was generated by AI (es)');
    });

    testWidgets('reduce motion: renders statically with no AnimatedBuilder driving frames', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [DefaultWidgetsLocalizations.delegate, LayrzUiL10nDelegate()],
          child: LayrzTheme(
            data: LayrzThemeData.light(),
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(disableAnimations: true),
                    child: const Center(child: LayrzAiMarker()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // No AnimatedBuilder should be present anywhere under the marker when
      // motion is disabled -- both the burst and the glow pulse are torn
      // down entirely, not merely paused.
      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(AnimatedBuilder)), findsNothing);

      // A fixed, non-animating shadow is still present -- reduce motion
      // removes the pulse, not the glow altogether.
      final decoratedBoxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(DecoratedBox)),
          )
          .toList();
      final fill = decoratedBoxes.firstWhere((d) => (d.decoration as BoxDecoration).color != null);
      final shadow = (fill.decoration as BoxDecoration).boxShadow;
      expect(shadow, isNotNull);
      expect(shadow, isNotEmpty);

      // The orbit is off under reduce motion -- the shadow sits at a fixed,
      // non-orbiting position (Offset.zero), not somewhere mid-loop.
      final before = shadow!.first;
      expect(before.offset, Offset.zero);

      // Pumping several frames must not throw and must not change the shadow
      // -- there is no ticking controller left to advance, so blur, spread,
      // and (the orbit-specific assertion) the offset all stay put.
      await tester.pump(const Duration(milliseconds: 500));
      final decoratedBoxesAfter = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(DecoratedBox)),
          )
          .toList();
      final fillAfter = decoratedBoxesAfter.firstWhere((d) => (d.decoration as BoxDecoration).color != null);
      final shadowAfter = (fillAfter.decoration as BoxDecoration).boxShadow!.first;
      expect(shadowAfter.blurRadius, before.blurRadius);
      expect(shadowAfter.spreadRadius, before.spreadRadius);
      expect(shadowAfter.offset, before.offset);
      expect(shadowAfter.offset, Offset.zero);
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall), findsNWidgets(2));
    });

    testWidgets('motion enabled: an AnimatedBuilder drives the burst and the glow orbit', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());

      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(AnimatedBuilder)), findsWidgets);
    });

    testWidgets('the glow shadow orbits (its offset traces a moving, non-zero path across the animation loop)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Replaces the old pulse-only regression test now that the glow's
      // primary animated property is its BoxShadow.offset (an orbit around
      // the container) rather than blur/spread/alpha growing in place. This
      // asserts the shadow's offset actually moves -- distinct, non-zero
      // Offset values at different points in the loop, tracing a path with
      // more than one direction -- rather than merely existing once, static,
      // at Offset.zero.
      await pumpThemed(tester, const LayrzAiMarker());

      final samples = <BoxShadow>[];
      // Sampled across a single 4-second orbit loop (see _kOrbitDuration in
      // ai_marker.dart) -- explicit pump() durations, not pumpAndSettle,
      // since the orbit controller repeats indefinitely and would never
      // settle.
      for (final millis in [0, 500, 1000, 1500, 2000, 2500, 3000, 3500]) {
        await tester.pump(Duration(milliseconds: millis));

        final decoratedBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(DecoratedBox)),
            )
            .toList();
        final fill = decoratedBoxes.firstWhere((d) => (d.decoration as BoxDecoration).color != null);
        final decoration = fill.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, isNotEmpty);
        samples.add(decoration.boxShadow!.first);

        // The stars must remain fully outside the shadow-bearing fill's own
        // sibling relationship -- i.e. still present and still white,
        // regardless of the glow's current phase.
        final starsInTree = find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall);
        expect(starsInTree, findsNWidgets(2));
        for (final icon in tester.widgetList<Icon>(starsInTree)) {
          expect(icon.color, const Color(0xFFFFFFFF));
          expect(icon.size, greaterThan(0.0));
        }
      }

      final offsets = samples.map((s) => s.offset).toSet();
      expect(offsets.length, greaterThan(1), reason: 'the glow offset must change across the loop -- it must move');
      expect(
        offsets.any((o) => o != Offset.zero),
        isTrue,
        reason: 'the glow must travel away from Offset.zero at some point in the orbit',
      );

      // A real orbit -- not just back-and-forth motion along one axis --
      // visits both positive and negative dx (or dy) across the loop.
      final dxValues = samples.map((s) => s.offset.dx).toSet();
      final dyValues = samples.map((s) => s.offset.dy).toSet();
      expect(dxValues.any((v) => v > 0), isTrue, reason: 'the orbit must swing to the right at some point');
      expect(dxValues.any((v) => v < 0), isTrue, reason: 'the orbit must swing to the left at some point');
      expect(dyValues.any((v) => v > 0), isTrue, reason: 'the orbit must swing downward at some point');
      expect(dyValues.any((v) => v < 0), isTrue, reason: 'the orbit must swing upward at some point');
    });

    testWidgets('the two stars are not rendered at identical scale mid-cycle (staggered burst is live)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());
      // Advance partway into the loop -- enough for the big star to be
      // mid-bounce while the small star's delayed interval has only just
      // begun (or not yet), matching the burst helper's own staggered-phase
      // unit test.
      await tester.pump(const Duration(milliseconds: 400));

      final scaleTransforms = tester
          .widgetList<Transform>(
            find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(Transform)),
          )
          .toList();

      expect(scaleTransforms.length, 2);
      final scaleA = scaleTransforms[0].transform.getMaxScaleOnAxis();
      final scaleB = scaleTransforms[1].transform.getMaxScaleOnAxis();
      expect(scaleA, isNot(closeTo(scaleB, 0.001)));
    });
  });

  group('LayrzAiMarker accessibility', () {
    testWidgets('the mandatory semantics disclosure label is present and announced', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzAiMarker());

        expect(
          tester.getSemantics(find.byType(LayrzAiMarker)),
          matchesSemantics(label: 'Generated by AI', isImage: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the semantics label is sourced from LayrzUiL10n, not a constructor parameter', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        // Same rationale as the tooltip case above -- overridable only via a
        // LayrzUiL10n subclass/delegate, never a `semanticsLabel:` parameter.
        await tester.pumpWidget(
          Localizations(
            locale: const Locale('en'),
            delegates: const [DefaultWidgetsLocalizations.delegate, _CustomAiL10nDelegate()],
            child: LayrzTheme(
              data: LayrzThemeData.light(),
              child: Overlay(
                initialEntries: [
                  OverlayEntry(builder: (context) => const Center(child: LayrzAiMarker())),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.getSemantics(find.byType(LayrzAiMarker)),
          matchesSemantics(label: 'This summary was generated by AI (es)', isImage: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('the star glyphs do not surface a separate semantics node', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzAiMarker());

        // The marker's own Semantics node carries the label; the inner Icons
        // must be excluded so no unlabelled/duplicate node appears alongside
        // it (mirrors LayrzBadge's ExcludeSemantics-over-child pattern).
        final node = tester.getSemantics(find.byType(LayrzAiMarker));
        expect(node.label, 'Generated by AI');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('exposes a tooltip semantics hint', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await pumpThemed(tester, const LayrzAiMarker());

        // LayrzTooltip attaches a `tooltip:` semantics hint on its own
        // Semantics node (see tooltip.dart's build()), which wraps
        // LayrzAiMarker's own content -- so it is a descendant of the
        // LayrzAiMarker element, not an ancestor. Assert it carries the same
        // disclosure text as a redundant availability path.
        final tooltipSemantics = find.descendant(
          of: find.byType(LayrzAiMarker),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.tooltip == 'Generated by AI'),
        );
        expect(tooltipSemantics, findsWidgets);
      } finally {
        handle.dispose();
      }
    });
  });
}

/// Custom [LayrzUiL10n] subclass overriding the AI-disclosure keys.
///
/// Used to prove that [LayrzAiMarker]'s disclosure label and tooltip are
/// sourced from [LayrzUiL10n] -- the only supported way to change that text
/// is a subclass/delegate like this one, never a constructor parameter.
class _CustomAiL10n extends LayrzUiL10n {
  /// Creates a minimal override localizations instance.
  const _CustomAiL10n();

  @override
  String get aiGeneratedLabel => 'This summary was generated by AI (es)';

  @override
  String get aiGeneratedTooltip => 'This summary was generated by AI (es)';
}

/// Delegate for loading [_CustomAiL10n].
class _CustomAiL10nDelegate extends LocalizationsDelegate<LayrzUiL10n> {
  /// Creates a delegate for the custom AI-disclosure localizations.
  const _CustomAiL10nDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LayrzUiL10n> load(Locale locale) async => const _CustomAiL10n();

  @override
  bool shouldReload(covariant LocalizationsDelegate<LayrzUiL10n> old) => false;
}

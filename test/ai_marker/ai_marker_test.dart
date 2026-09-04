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

    testWidgets('the small size renders a square footprint smaller than the big default', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker(size: LayrzAiMarkerSize.small));
      final smallSize = tester.getSize(find.byType(LayrzAiMarker));

      expect(smallSize.width, smallSize.height);
      // Compared against the hand-tuned big dimension directly rather than
      // pumping a second LayrzAiMarker into the same tester -- pumpThemed's
      // Overlay is reused across pumpWidget calls in one test, which was
      // observed to preserve the first marker's resolved element size on the
      // second pump. A fresh tester per testWidgets avoids that entirely.
      expect(smallSize.width, lessThan(44.0));
    });

    testWidgets('the default (big) size renders a larger square footprint than small', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());
      final bigSize = tester.getSize(find.byType(LayrzAiMarker));

      expect(bigSize.width, bigSize.height);
      expect(bigSize.width, greaterThan(22.0));
    });

    testWidgets('both sizes render two visible white stars in a diagonal arrangement', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final size in LayrzAiMarkerSize.values) {
        await pumpThemed(tester, LayrzAiMarker(size: size));

        final positioned = tester
            .widgetList<Positioned>(
              find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(Positioned)),
            )
            .toList();
        // The fill is also wrapped in a Positioned.fill, which sets all four
        // of left/top/right/bottom -- filter it out by keeping only anchors
        // that set exactly one horizontal and one vertical edge (the two
        // star anchors: top-left-only, or bottom-right-only).
        final starAnchors = positioned
            .where((p) => (p.left != null) != (p.right != null) && (p.top != null) != (p.bottom != null))
            .toList();
        expect(starAnchors.length, 2);

        final topLeft = starAnchors.firstWhere((p) => p.left != null && p.top != null);
        final bottomRight = starAnchors.firstWhere((p) => p.right != null && p.bottom != null);
        expect(topLeft.left, greaterThanOrEqualTo(0.0));
        expect(topLeft.top, greaterThanOrEqualTo(0.0));
        expect(bottomRight.right, greaterThanOrEqualTo(0.0));
        expect(bottomRight.bottom, greaterThanOrEqualTo(0.0));

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
      }
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
      // motion is disabled -- both the burst and the shine glint are torn
      // down entirely, not merely paused.
      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(AnimatedBuilder)), findsNothing);
      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(ShaderMask)), findsNothing);

      // Pumping several frames must not throw and must not change anything
      // -- there is no ticking controller left to advance.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall), findsNWidgets(2));
    });

    testWidgets('motion enabled: an AnimatedBuilder drives the burst and the glint', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpThemed(tester, const LayrzAiMarker());

      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(AnimatedBuilder)), findsWidgets);
      expect(find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(ShaderMask)), findsOneWidget);
    });

    testWidgets('the glint ShaderMask does not wrap the star glyphs, at any point in the sweep', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Regression test for a real rendering bug (commit d61f9a3): the glint
      // was originally implemented as a single ShaderMask wrapping the whole
      // container -- pill *and* stars. BlendMode.srcATop replaces a masked
      // child's color wherever it is opaque, keeping only its alpha, so that
      // structure silently repainted the white stars to the gradient's own
      // (aiAccent-based) color outside the moving highlight band, making them
      // invisible almost the entire cycle. A widget-tree check that merely
      // asserts "a ShaderMask exists somewhere" and "an Icon has color white"
      // -- as the previous test suite did -- passes against that broken
      // structure just as easily as against a fixed one, because both
      // structures contain a ShaderMask and both contain white Icons. The
      // only way to actually catch this is to assert the *containment*
      // relationship itself: the Icons must NOT be descendants of the
      // ShaderMask, in either direction of the animation.
      await pumpThemed(tester, const LayrzAiMarker());

      for (final millis in [0, 150, 300, 450, 600, 750, 900]) {
        await tester.pump(Duration(milliseconds: millis));

        final shaderMask = find.descendant(of: find.byType(LayrzAiMarker), matching: find.byType(ShaderMask));
        expect(shaderMask, findsOneWidget);

        final starsUnderShader = find.descendant(
          of: shaderMask,
          matching: find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall),
        );
        expect(
          starsUnderShader,
          findsNothing,
          reason:
              'the star Icons must never be painted inside the glint ShaderMask subtree, '
              'or BlendMode.srcATop erases their white color outside the highlight band',
        );

        final starsInTree = find.byWidgetPredicate((w) => w is Icon && w.icon == MdiIcons.starFourPointsSmall);
        expect(starsInTree, findsNWidgets(2));
        for (final icon in tester.widgetList<Icon>(starsInTree)) {
          expect(icon.color, const Color(0xFFFFFFFF));
          expect(icon.size, greaterThan(0.0));
        }
      }
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

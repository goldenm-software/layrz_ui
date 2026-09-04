import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/skeleton/src/shimmer_painter.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'ai_marker_burst.dart';
import 'ai_marker_position.dart';
import 'ai_marker_size.dart';
import 'ai_marker_wrapper.dart';

/// An icon-only marker disclosing that nearby content was generated or
/// assisted by AI.
///
/// [LayrzAiMarker] renders two overlapping `MdiIcons.starFourPointsSmall`
/// glyphs — a bigger sparkle inset toward the top-left, a smaller accent
/// sparkle inset toward the bottom-right, the conventional diagonal
/// "AI sparkle" motif — in white, on top of a fully-rounded container filled
/// with `tokens.colors.aiAccent`. The orange-on-orange contrast of an earlier
/// revision (bare orange stars directly on the page background) was too weak
/// against light surfaces; painting the accent as a solid pill behind white
/// glyphs keeps the marker legible everywhere it's dropped (Kenny,
/// 2026-09-04). It is deliberately **icon-only**: there is no visible text
/// label parameter, and none should be added. Disclosure is carried instead
/// by two mandatory, always-present mechanisms, both sourced from
/// [LayrzUiL10n] and **not** configurable by the caller:
///
/// 1. A [Semantics] label (`LayrzUiL10n.aiGeneratedLabel`) announced to
///    screen readers.
/// 2. A [LayrzTooltip] (`LayrzUiL10n.aiGeneratedTooltip`) wrapping the
///    marker.
///
/// **Disclosure text is not a per-caller override.** This is Kenny's
/// explicit, final decision (DESIGN-69, relayed 2026-09-04): the AI-
/// disclosure label and tooltip are legally load-bearing and must read
/// identically, and be translated identically, everywhere [LayrzAiMarker] is
/// used. A `semanticsLabel`/`tooltip` constructor parameter would let two
/// call sites disclose the same fact in two different strings, or let one
/// silently drift out of translation — so there is no such parameter; both
/// strings always come from `LayrzUiL10n.of(context)`. Localize by providing
/// a [LayrzUiL10n] subclass (see the `l10n` module), never by passing text
/// here.
///
/// **Known, accepted trade-off, on record:** a sighted user who never
/// triggers a screen reader and never hovers/long-presses the tooltip sees
/// only a bare sparkle with no visible text — for that user the disclosure is
/// not visible in the moment. This is an owned decision, not an oversight; do
/// not "fix" it by adding a `label:` parameter.
///
/// **Animation is compound, not a single effect:**
/// - **Geometry** — the two star glyphs play a staggered, continuous, gentle
///   sparkle-burst: each pops in with a scale bounce, the small star's pop
///   phase-offset behind the big star's (see [LayrzAiMarkerBurst]), settling
///   between repeats. This must read as an AI *twinkle*, never as a spinning
///   loading indicator — there is no rotation anywhere in this widget.
/// - **Shine** — a moving-gradient glint sweeps across the background pill
///   only via [LayrzShimmerGradient] (`lib/src/skeleton/src/shimmer_painter.dart`),
///   the same internal helper `LayrzSkeleton` uses for its shimmer. Sharing
///   one implementation avoids two divergent "moving highlight" effects in
///   the library.
///
///   **The glint's [ShaderMask] wraps only the [DecoratedBox] fill, never the
///   star glyphs.** `BlendMode.srcATop` keeps the masked child's *alpha* but
///   replaces its *color* with the shader's color at every opaque pixel — so
///   an earlier revision that wrapped the whole container (pill *and* stars)
///   in one `ShaderMask` silently repainted the white stars to the gradient's
///   `aiAccent` color everywhere outside the moving highlight band, making
///   them functionally invisible except for an instant as the band crossed
///   them (Kenny, live showroom screenshot, 2026-09-04). The stars are now
///   painted as a sibling on top of the shaded fill, entirely outside the
///   `ShaderMask` subtree, so the glint can only ever affect the pill's own
///   color and can never touch the glyphs.
///
/// **Reduce motion:** when `MediaQuery.disableAnimationsOf(context)` is true,
/// both the burst and the glint are switched off entirely and the stars
/// render in their settled, static resting pose — non-negotiable, since a
/// perpetual twinkle is a vestibular trigger for users who have asked for
/// reduced motion.
///
/// For overlaying this marker on the corner of another widget (a chat bubble,
/// a card) without affecting that widget's layout, see [LayrzAiMarker.wrap]
/// (`ai_marker_wrapper.dart`).
@immutable
class LayrzAiMarker extends StatefulWidget {
  /// Creates a standalone, icon-only AI-disclosure marker.
  const LayrzAiMarker({super.key, this.size = LayrzAiMarkerSize.big});

  /// Overlays a [LayrzAiMarker] on a corner of [child] without affecting
  /// [child]'s layout footprint.
  ///
  /// A thin delegation to [LayrzAiMarkerWrapper] — kept as a static method,
  /// rather than a factory constructor, because [LayrzAiMarker] is a
  /// [StatefulWidget] and a factory constructor cannot return an instance of
  /// a different [Widget] subtype. This is the call-site form referenced
  /// throughout this file's docs; [LayrzAiMarkerWrapper] itself remains the
  /// underlying implementation and stays independently constructible.
  ///
  /// There is no `semanticsLabel`/`tooltip` parameter here either, for the
  /// same reason [LayrzAiMarker] has none — see the class doc.
  static Widget wrap({
    Key? key,
    required Widget child,
    LayrzAiMarkerPosition position = LayrzAiMarkerPosition.topRight,
    LayrzAiMarkerSize size = LayrzAiMarkerSize.big,
    bool isVisible = true,
  }) {
    return LayrzAiMarkerWrapper(key: key, position: position, size: size, isVisible: isVisible, child: child);
  }

  /// The hand-tuned footprint the marker renders at.
  ///
  /// Each [LayrzAiMarkerSize] value maps to its own container dimension and
  /// star sizes via [_LayrzAiMarkerState._dimensionsFor] — not a shared
  /// scale factor — so the small variant's accent star stays legible instead
  /// of shrinking into a blur. Defaults to [LayrzAiMarkerSize.big].
  final LayrzAiMarkerSize size;

  @override
  State<LayrzAiMarker> createState() => _LayrzAiMarkerState();
}

/// Hand-tuned geometry for one [LayrzAiMarkerSize] value.
///
/// Bundled as one immutable value so [_LayrzAiMarkerState._dimensionsFor]
/// returns container, star, and inset sizing together — the three numbers
/// are tuned as a set per size and must never be mixed across sizes.
@immutable
class _LayrzAiMarkerDimensions {
  /// The side length, in logical pixels, of the square marker container.
  final double container;

  /// The side length, in logical pixels, of the bigger, top-left-anchored
  /// star glyph.
  final double bigStar;

  /// The side length, in logical pixels, of the smaller, bottom-right-anchored
  /// accent star glyph.
  final double smallStar;

  /// The inward inset, in logical pixels, applied to both stars from their
  /// respective anchor corner — kept minimal so the stars occupy most of the
  /// container rather than floating in unused padding.
  final double inset;

  /// Creates a bundle of hand-tuned dimensions for one marker size.
  const _LayrzAiMarkerDimensions({
    required this.container,
    required this.bigStar,
    required this.smallStar,
    required this.inset,
  });
}

class _LayrzAiMarkerState extends State<LayrzAiMarker> with SingleTickerProviderStateMixin {
  static const LayrzAiMarkerBurst _burst = LayrzAiMarkerBurst();

  /// Drives both the staggered burst and the shine glint from one ticker —
  /// the two effects are visually independent but share a single continuous
  /// cycle so they loop in the same cadence rather than drifting apart.
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  /// Starts or tears down [_controller] to match the current reduce-motion
  /// setting.
  ///
  /// Mirrors `LayrzProgressBar._startSweep`/`_stopSweep`
  /// (`lib/src/progress/src/progress_bar.dart`): the controller is created
  /// lazily and only while motion is enabled, so no ticker keeps running once
  /// reduce-motion switches on.
  void _syncAnimation() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller != null) return;
    final tokens = context.tokens;
    _controller = AnimationController(vsync: this, duration: tokens.motion.dIndeterminate * 2)..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Resolves the hand-tuned dimension bundle for the given [size].
  ///
  /// These numbers are tuned as a set, not derived from one another: the
  /// small variant does not scale the big variant down, because a naive
  /// linear scale made the small accent star shrink into near-invisibility.
  /// Padding is kept minimal in both so the stars occupy most of the
  /// container rather than floating in unused space.
  static _LayrzAiMarkerDimensions _dimensionsFor(LayrzAiMarkerSize size) {
    switch (size) {
      case LayrzAiMarkerSize.small:
        return const _LayrzAiMarkerDimensions(container: 22.0, bigStar: 15.0, smallStar: 9.5, inset: 1.5);
      case LayrzAiMarkerSize.big:
        return const _LayrzAiMarkerDimensions(container: 44.0, bigStar: 29.0, smallStar: 18.0, inset: 3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = _controller;
    final dimensions = _dimensionsFor(widget.size);

    final Widget stars = controller == null
        ? _StarPair(
            dimensions: dimensions,
            color: const Color(0xFFFFFFFF),
            big: kLayrzAiMarkerSettledFrame,
            small: kLayrzAiMarkerSettledFrame,
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return _StarPair(
                dimensions: dimensions,
                color: const Color(0xFFFFFFFF),
                big: _burst.bigStarAt(controller.value),
                small: _burst.smallStarAt(controller.value),
              );
            },
          );

    // The glint only ever wraps this bare, content-free fill -- never the
    // stars -- because BlendMode.srcATop replaces a masked child's *color*
    // wherever it is opaque, keeping only its alpha. Masking the stars along
    // with the pill would recolor them to the gradient's own color, erasing
    // them outside the moving highlight band (see the class doc).
    final Widget fill = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colors.aiAccent,
        borderRadius: BorderRadius.circular(tokens.radius.r1),
      ),
    );

    final Widget shinedFill = controller == null
        ? fill
        : AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LayrzShimmerGradient.forAnimationValue(
                  value: controller.value,
                  baseColor: tokens.colors.aiAccent,
                  highlightColor: const Color(0xFFFFFFFF),
                  shaderRect: rect,
                  bandWidth: 0.5,
                ).createShader(),
                child: child,
              );
            },
            child: fill,
          );

    // The stars are painted as a sibling stacked on top of the (possibly
    // shaded) fill, entirely outside the ShaderMask subtree, so they are
    // always rendered at their own true color regardless of where the glint
    // band currently sits.
    final Widget container = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: shinedFill),
        stars,
      ],
    );

    final l10n = context.l10n;

    return LayrzTooltip(
      contentText: l10n.aiGeneratedTooltip,
      child: Semantics(
        label: l10n.aiGeneratedLabel,
        image: true,
        child: ExcludeSemantics(
          child: SizedBox(width: dimensions.container, height: dimensions.container, child: container),
        ),
      ),
    );
  }
}

/// The bare pair of diagonally-arranged star glyphs, positioned and scaled
/// per the current [LayrzAiMarkerBurstFrame] of each.
///
/// Split out from [_LayrzAiMarkerState.build] purely for readability — it
/// carries no state and no animation of its own, only geometry for a given
/// [dimensions] bundle and pair of frames. The bigger star is inset from the
/// top-left corner of the container and the smaller accent star from the
/// bottom-right, filling the container diagonally rather than overlapping
/// concentrically — the classic AI-sparkle motif Kenny asked for
/// (2026-09-04): a prominent sparkle anchored up-left with a smaller accent
/// sparkle trailing down-right.
class _StarPair extends StatelessWidget {
  const _StarPair({required this.dimensions, required this.color, required this.big, required this.small});

  /// The hand-tuned container, star, and inset sizes for the marker's
  /// current [LayrzAiMarkerSize].
  final _LayrzAiMarkerDimensions dimensions;

  /// The fill color applied to both star glyphs.
  final Color color;

  /// The current burst frame (scale/opacity) for the top-left star.
  final LayrzAiMarkerBurstFrame big;

  /// The current burst frame (scale/opacity) for the bottom-right star.
  final LayrzAiMarkerBurstFrame small;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dimensions.container,
      height: dimensions.container,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: dimensions.inset,
            top: dimensions.inset,
            child: Opacity(
              opacity: big.opacity,
              child: Transform.scale(
                scale: big.scale,
                child: Icon(MdiIcons.starFourPointsSmall, size: dimensions.bigStar, color: color),
              ),
            ),
          ),
          Positioned(
            right: dimensions.inset,
            bottom: dimensions.inset,
            child: Opacity(
              opacity: small.opacity,
              child: Transform.scale(
                scale: small.scale,
                child: Icon(MdiIcons.starFourPointsSmall, size: dimensions.smallStar, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

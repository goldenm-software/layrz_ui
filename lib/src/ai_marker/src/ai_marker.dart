import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
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
/// - **Glow** — a soft [BoxShadow] in `tokens.colors.aiAccent` pulses on the
///   container, growing its blur/spread and fading its opacity out, then back
///   in, on a continuous loop (see [_glowFor]). This replaced an earlier
///   moving-gradient glint swept across the pill via [ShaderMask] +
///   `LayrzShimmerGradient` (the same helper `LayrzSkeleton` still uses for
///   its own shimmer); the glint read as a highlight crossing a static
///   surface, whereas the pulsing shadow reads as the marker itself
///   "breathing" — a better match for a living, AI-generated disclosure
///   (Kenny, 2026-09-04).
///
///   **Both the burst and the glow are driven by the same
///   [AnimationController]**, so the star pop and the shadow's breathing
///   cycle stay in the same cadence rather than drifting apart over repeats.
///   The shadow is painted on the container's own [BoxDecoration] — sibling
///   to, not wrapping, the star glyphs — so it can never affect their color,
///   and the containing [Stack] uses `clipBehavior: Clip.none` so the glow is
///   never clipped away at the container's own bounds.
///
/// **Reduce motion:** when `MediaQuery.disableAnimationsOf(context)` is true,
/// both the burst and the glow pulse are switched off entirely: the stars
/// render in their settled, static resting pose and the container keeps a
/// fixed, non-animating shadow — non-negotiable, since a perpetual twinkle
/// and a pulsing glow are both vestibular triggers for users who have asked
/// for reduced motion.
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

  /// Drives both the staggered burst and the pulsing glow shadow from one
  /// ticker — the two effects are visually independent but share a single
  /// continuous cycle so they loop in the same cadence rather than drifting
  /// apart.
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
        return const _LayrzAiMarkerDimensions(container: 25.0, bigStar: 18.0, smallStar: 16.0, inset: -2);
      case LayrzAiMarkerSize.big:
        return const _LayrzAiMarkerDimensions(container: 35.0, bigStar: 29.0, smallStar: 23.0, inset: -2);
    }
  }

  /// The blur radius, in logical pixels, the glow shadow settles at when the
  /// pulse is at its calmest point in the cycle.
  static const double _glowMinBlur = 2.0;

  /// The blur radius, in logical pixels, the glow shadow reaches at the peak
  /// of the pulse.
  static const double _glowMaxBlur = 8.0;

  /// The spread radius, in logical pixels, the glow shadow settles at when
  /// the pulse is at its calmest point in the cycle.
  static const double _glowMinSpread = 0.0;

  /// The spread radius, in logical pixels, the glow shadow reaches at the
  /// peak of the pulse.
  static const double _glowMaxSpread = 2.0;

  /// The shadow's alpha at the calmest point in the cycle.
  static const double _glowMinAlpha = 0.15;

  /// The shadow's alpha at the peak of the pulse.
  static const double _glowMaxAlpha = 0.55;

  /// Computes the "breathing" glow's [BoxShadow] at driving animation [value]
  /// in `[0.0, 1.0]`.
  ///
  /// Shares the same `[0.0, 1.0]` controller value that drives
  /// [LayrzAiMarkerBurst], so the shadow's breathing cycle and the star burst
  /// stay in lockstep. A full sine wave (rather than [_controller]'s own
  /// repeat boundary) is used so the glow grows out and fades back smoothly
  /// across the loop seam, instead of snapping at `value == 0.0`/`1.0`.
  static BoxShadow _glowFor(Color aiAccent, double value) {
    // 0.5 + 0.5*sin(...) maps into [0.0, 1.0] and starts (at value == 0) at
    // the same point it ends, so consecutive repeats of the controller never
    // produce a visible jump in the shadow.
    final phase = 0.5 + 0.5 * math.sin(2 * math.pi * value - math.pi / 2);
    final eased = Curves.easeInOut.transform(phase);
    return BoxShadow(
      color: aiAccent.withValues(alpha: _glowMinAlpha + (_glowMaxAlpha - _glowMinAlpha) * eased),
      blurRadius: _glowMinBlur + (_glowMaxBlur - _glowMinBlur) * eased,
      spreadRadius: _glowMinSpread + (_glowMaxSpread - _glowMinSpread) * eased,
    );
  }

  /// The fixed, non-animating glow rendered under reduce motion — a subtle
  /// resting shadow rather than no shadow at all, so the marker still reads
  /// as elevated when the pulse is switched off.
  static BoxShadow _settledGlow(Color aiAccent) {
    return BoxShadow(
      color: aiAccent.withValues(alpha: _glowMinAlpha),
      blurRadius: _glowMinBlur,
      spreadRadius: _glowMinSpread,
    );
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

    // The pulsing glow is painted as this DecoratedBox's own BoxShadow --
    // never a wrapper around the stars -- so it can only ever affect the
    // pill's own painted extent, exactly like the fill color it replaces.
    final Widget glowingFill = controller == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colors.aiAccent,
              borderRadius: BorderRadius.circular(tokens.radius.r1),
              boxShadow: [_settledGlow(tokens.colors.aiAccent)],
            ),
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.colors.aiAccent,
                  borderRadius: BorderRadius.circular(tokens.radius.r1),
                  boxShadow: [_glowFor(tokens.colors.aiAccent, controller.value)],
                ),
              );
            },
          );

    // The stars are painted as a sibling stacked on top of the fill, so they
    // are always rendered at their own true color regardless of the glow's
    // current phase. `clipBehavior: Clip.none` keeps the pulsing shadow from
    // being clipped away at the Stack's own bounds -- a shadow clipped to the
    // container's own rect would never be visible around it.
    final Widget container = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: glowingFill),
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

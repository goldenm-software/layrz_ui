import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/skeleton/src/shimmer_painter.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'ai_marker_burst.dart';
import 'ai_marker_position.dart';
import 'ai_marker_wrapper.dart';

/// An icon-only marker disclosing that nearby content was generated or
/// assisted by AI.
///
/// [LayrzAiMarker] renders two overlapping `MdiIcons.starFourPointsSmall`
/// glyphs — a larger sparkle behind a smaller one in front, the conventional
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
  const LayrzAiMarker({super.key, this.size = 24.0});

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
    double size = 24.0,
    bool isVisible = true,
  }) {
    return LayrzAiMarkerWrapper(key: key, position: position, size: size, isVisible: isVisible, child: child);
  }

  /// The overall footprint of the marker, in logical pixels.
  ///
  /// This is the diameter of the rounded `tokens.colors.aiAccent` container;
  /// the star pair is rendered inside it, inset on every side so the glyphs
  /// don't touch the container's edge. Defaults to `24.0`, matching the
  /// design system's common inline-icon size.
  final double size;

  @override
  State<LayrzAiMarker> createState() => _LayrzAiMarkerState();
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = _controller;

    // The stars sit inside the accent pill with breathing room on every
    // side rather than touching its edge -- inset by 18% of the marker's
    // own size on each side (64% of size left for the pair), which at the
    // default 24.0 size leaves a comfortable ~4.3px margin.
    final innerSize = widget.size * 0.64;

    final Widget stars = controller == null
        ? _StarPair(
            size: innerSize,
            color: const Color(0xFFFFFFFF),
            big: kLayrzAiMarkerSettledFrame,
            small: kLayrzAiMarkerSettledFrame,
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return _StarPair(
                size: innerSize,
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
        borderRadius: BorderRadius.circular(tokens.radius.full),
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
          child: SizedBox(width: widget.size, height: widget.size, child: container),
        ),
      ),
    );
  }
}

/// The bare pair of overlapping star glyphs, positioned and scaled per the
/// current [LayrzAiMarkerBurstFrame] of each.
///
/// Split out from [_LayrzAiMarkerState.build] purely for readability — it
/// carries no state and no animation of its own, only geometry for a given
/// pair of frames.
class _StarPair extends StatelessWidget {
  const _StarPair({required this.size, required this.color, required this.big, required this.small});

  final double size;
  final Color color;
  final LayrzAiMarkerBurstFrame big;
  final LayrzAiMarkerBurstFrame small;

  @override
  Widget build(BuildContext context) {
    // The smaller, front-facing star is offset toward the bottom-right of
    // the larger back star and scaled down from it -- the reference motif is
    // two sparkles of different sizes overlapping, not concentric.
    final smallSize = size * 0.55;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: big.opacity,
              child: Transform.scale(
                scale: big.scale,
                child: Icon(MdiIcons.starFourPointsSmall, size: size, color: color),
              ),
            ),
          ),
          Positioned(
            right: -smallSize * 0.15,
            bottom: -smallSize * 0.15,
            child: Opacity(
              opacity: small.opacity,
              child: Transform.scale(
                scale: small.scale,
                child: Icon(MdiIcons.starFourPointsSmall, size: smallSize, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
/// "AI sparkle" motif — tinted with `tokens.colors.aiAccent`. It is
/// deliberately **icon-only**: there is no visible text label parameter, and
/// none should be added. Disclosure is carried instead by two mandatory,
/// always-present mechanisms, both sourced from [LayrzUiL10n] and **not**
/// configurable by the caller:
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
/// - **Shine** — a moving-gradient glint sweeps across the glyphs via
///   [LayrzShimmerGradient] (`lib/src/skeleton/src/shimmer_painter.dart`),
///   the same internal helper `LayrzSkeleton` uses for its shimmer. Sharing
///   one implementation avoids two divergent "moving highlight" effects in
///   the library.
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
  /// The larger (back) star occupies the full [size]; the smaller (front)
  /// star is scaled down from it. Defaults to `24.0`, matching the design
  /// system's common inline-icon size.
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

    final Widget stars = controller == null
        ? _StarPair(
            size: widget.size,
            color: tokens.colors.aiAccent,
            big: kLayrzAiMarkerSettledFrame,
            small: kLayrzAiMarkerSettledFrame,
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return _StarPair(
                size: widget.size,
                color: tokens.colors.aiAccent,
                big: _burst.bigStarAt(controller.value),
                small: _burst.smallStarAt(controller.value),
              );
            },
          );

    final Widget shined = controller == null
        ? stars
        : AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LayrzShimmerGradient.forAnimationValue(
                  value: controller.value,
                  baseColor: tokens.colors.aiAccent,
                  highlightColor: tokens.colors.sf1,
                  shaderRect: rect,
                  bandWidth: 0.5,
                ).createShader(),
                child: child,
              );
            },
            child: stars,
          );

    final l10n = context.l10n;

    return LayrzTooltip(
      contentText: l10n.aiGeneratedTooltip,
      child: Semantics(
        label: l10n.aiGeneratedLabel,
        image: true,
        child: ExcludeSemantics(
          child: SizedBox(width: widget.size, height: widget.size, child: shined),
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

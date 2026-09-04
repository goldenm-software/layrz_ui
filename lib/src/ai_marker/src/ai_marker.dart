import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'ai_marker_burst.dart';
import 'ai_marker_position.dart';
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
///   in, on a continuous loop (see [_LayrzAiMarkerState._glowFor]). This
///   replaced an earlier moving-gradient glint swept across the pill via
///   [ShaderMask] + `LayrzShimmerGradient` (the same helper `LayrzSkeleton`
///   still uses for its own shimmer); the glint read as a highlight crossing
///   a static surface, whereas the pulsing shadow reads as the marker itself
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
/// **Single fixed footprint.** [LayrzAiMarker] used to offer a
/// `LayrzAiMarkerSize` (`small`/`big`) choice; that enum is gone and there is
/// no `size` parameter of any kind. The container renders at one hand-tuned
/// size ([_kContainerSize]) everywhere. Each star's own placement (top, left,
/// bottom, right) is still hand-tunable, but only as internal constants — see
/// the `_kBigStar*`/`_kSmallStar*` knobs at the top of
/// [_LayrzAiMarkerState] — never as a constructor parameter.
///
/// For overlaying this marker on the corner of another widget (a chat bubble,
/// a card) without affecting that widget's layout, see [LayrzAiMarker.wrap]
/// (`ai_marker_wrapper.dart`).
@immutable
class LayrzAiMarker extends StatefulWidget {
  /// Creates a standalone, icon-only AI-disclosure marker.
  const LayrzAiMarker({super.key});

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
    bool isVisible = true,
  }) {
    return LayrzAiMarkerWrapper(key: key, position: position, isVisible: isVisible, child: child);
  }

  @override
  State<LayrzAiMarker> createState() => _LayrzAiMarkerState();
}

class _LayrzAiMarkerState extends State<LayrzAiMarker> with SingleTickerProviderStateMixin {
  static const LayrzAiMarkerBurst _burst = LayrzAiMarkerBurst();

  /// The side length, in logical pixels, of the square marker container.
  ///
  /// [LayrzAiMarker] used to offer a `small`/`big` size enum; that choice is
  /// gone and this is now the only footprint the marker ever renders at.
  /// Carried over from the former "big" variant's hand-tuned dimension.
  static const double _kContainerSize = 30.0;

  /// **Tuning knob, not a public parameter.** The big star's inward offset,
  /// in logical pixels, from the container's top edge. `null` leaves that
  /// edge unconstrained (standard [Positioned] semantics) — set it to move
  /// the star vertically; leave `null` to let [_kBigStarBottom] (if set)
  /// govern instead.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const double? _kBigStarTop = -8.5;

  /// **Tuning knob, not a public parameter.** The big star's inward offset,
  /// in logical pixels, from the container's left edge. See [_kBigStarTop].
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const double? _kBigStarLeft = -8.5;

  /// **Tuning knob, not a public parameter.** The big star's offset from the
  /// container's bottom edge. `null` by default — the big star is anchored
  /// from the top-left, per [_kBigStarTop]/[_kBigStarLeft]. See
  /// [_kBigStarTop].
  static const double? _kBigStarBottom = null;

  /// **Tuning knob, not a public parameter.** The big star's offset from the
  /// container's right edge. `null` by default — see [_kBigStarBottom].
  static const double? _kBigStarRight = null;

  /// **Tuning knob, not a public parameter.** The side length, in logical
  /// pixels, of the bigger, top-left-anchored star glyph.
  static const double _kBigStarSize = 40.0;

  /// **Tuning knob, not a public parameter.** The small star's offset from
  /// the container's top edge. `null` by default — the small star is
  /// anchored from the bottom-right, per [_kSmallStarBottom]/
  /// [_kSmallStarRight]. See [_kBigStarTop] for the general shape of these
  /// per-star slots.
  static const double? _kSmallStarTop = null;

  /// **Tuning knob, not a public parameter.** The small star's offset from
  /// the container's left edge. `null` by default — see [_kSmallStarTop].
  static const double? _kSmallStarLeft = null;

  /// **Tuning knob, not a public parameter.** The small star's inward offset,
  /// in logical pixels, from the container's bottom edge.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const double? _kSmallStarBottom = -3.5;

  /// **Tuning knob, not a public parameter.** The small star's inward offset,
  /// in logical pixels, from the container's right edge.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const double? _kSmallStarRight = -3.5;

  /// **Tuning knob, not a public parameter.** The side length, in logical
  /// pixels, of the smaller, bottom-right-anchored accent star glyph.
  static const double _kSmallStarSize = 26.0;

  /// The big star's resolved placement, built from the [_kBigStarTop] /
  /// [_kBigStarLeft] / [_kBigStarBottom] / [_kBigStarRight] /
  /// [_kBigStarSize] knobs above.
  ///
  /// **This is the one place to look to move the big star.** Edit the four
  /// `_kBigStar*` edge constants above — any of top/left/bottom/right,
  /// independently, `null` for "unconstrained" — and this slot picks them up
  /// automatically; nothing else in the widget needs to change.
  static const _LayrzAiMarkerStarSlot _bigStarSlot = _LayrzAiMarkerStarSlot(
    top: _kBigStarTop,
    left: _kBigStarLeft,
    bottom: _kBigStarBottom,
    right: _kBigStarRight,
    size: _kBigStarSize,
  );

  /// The small star's resolved placement, built from the [_kSmallStarTop] /
  /// [_kSmallStarLeft] / [_kSmallStarBottom] / [_kSmallStarRight] /
  /// [_kSmallStarSize] knobs above.
  ///
  /// **This is the one place to look to move the small star** — same shape
  /// as [_bigStarSlot], see that field's doc.
  static const _LayrzAiMarkerStarSlot _smallStarSlot = _LayrzAiMarkerStarSlot(
    top: _kSmallStarTop,
    left: _kSmallStarLeft,
    bottom: _kSmallStarBottom,
    right: _kSmallStarRight,
    size: _kSmallStarSize,
  );

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

    final Widget stars = controller == null
        ? const _StarPair(
            bigSlot: _bigStarSlot,
            smallSlot: _smallStarSlot,
            color: Color(0xFFFFFFFF),
            big: kLayrzAiMarkerSettledFrame,
            small: kLayrzAiMarkerSettledFrame,
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return _StarPair(
                bigSlot: _bigStarSlot,
                smallSlot: _smallStarSlot,
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
        Positioned.fill(child: stars),
      ],
    );

    final l10n = context.l10n;

    return LayrzTooltip(
      contentText: l10n.aiGeneratedTooltip,
      child: Semantics(
        label: l10n.aiGeneratedLabel,
        image: true,
        child: ExcludeSemantics(
          child: SizedBox(width: _kContainerSize, height: _kContainerSize, child: container),
        ),
      ),
    );
  }
}

/// One star glyph's hand-tuned placement within the marker container,
/// expressed as standard [Positioned] edge offsets.
///
/// **This is the internal tuning knob for moving a star.** Each of [top],
/// [left], [bottom], [right] can be set or left `null` independently, with
/// the same "unconstrained edge" semantics [Positioned] itself uses — so a
/// star can be anchored from any corner, or even stretched between two
/// opposite edges, by editing the `_kBigStar*`/`_kSmallStar*` constants in
/// [_LayrzAiMarkerState] that build these slots. There is no constructor
/// parameter on [LayrzAiMarker] for this — it is deliberately not public API,
/// only an easy-to-find internal constant for Kenny (or a future maintainer)
/// to hand-tune.
@immutable
class _LayrzAiMarkerStarSlot {
  /// The star's offset from the container's top edge, in logical pixels.
  /// `null` leaves this edge unconstrained.
  final double? top;

  /// The star's offset from the container's left edge, in logical pixels.
  /// `null` leaves this edge unconstrained.
  final double? left;

  /// The star's offset from the container's bottom edge, in logical pixels.
  /// `null` leaves this edge unconstrained.
  final double? bottom;

  /// The star's offset from the container's right edge, in logical pixels.
  /// `null` leaves this edge unconstrained.
  final double? right;

  /// The side length, in logical pixels, of this star's glyph.
  final double size;

  /// Creates a star placement slot from up to four independent edge offsets
  /// plus the glyph's own size.
  const _LayrzAiMarkerStarSlot({this.top, this.left, this.bottom, this.right, required this.size});
}

/// The bare pair of diagonally-arranged star glyphs, positioned and scaled
/// per the current [LayrzAiMarkerBurstFrame] of each.
///
/// Split out from [_LayrzAiMarkerState.build] purely for readability — it
/// carries no state and no animation of its own, only geometry for the given
/// [bigSlot]/[smallSlot] placements and pair of burst frames. Each star's
/// [_LayrzAiMarkerStarSlot] independently supplies its own top/left/bottom/
/// right offsets to the [Positioned] that anchors it, so the two stars need
/// not share a single inset the way earlier revisions did.
class _StarPair extends StatelessWidget {
  const _StarPair({
    required this.bigSlot,
    required this.smallSlot,
    required this.color,
    required this.big,
    required this.small,
  });

  /// The bigger, top-left-anchored star's placement and size.
  final _LayrzAiMarkerStarSlot bigSlot;

  /// The smaller, bottom-right-anchored accent star's placement and size.
  final _LayrzAiMarkerStarSlot smallSlot;

  /// The fill color applied to both star glyphs.
  final Color color;

  /// The current burst frame (scale/opacity) for the big star.
  final LayrzAiMarkerBurstFrame big;

  /// The current burst frame (scale/opacity) for the small star.
  final LayrzAiMarkerBurstFrame small;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: bigSlot.top,
          left: bigSlot.left,
          bottom: bigSlot.bottom,
          right: bigSlot.right,
          child: Opacity(
            opacity: big.opacity,
            child: Transform.scale(
              scale: big.scale,
              child: Icon(MdiIcons.starFourPointsSmall, size: bigSlot.size, color: color),
            ),
          ),
        ),
        Positioned(
          top: smallSlot.top,
          left: smallSlot.left,
          bottom: smallSlot.bottom,
          right: smallSlot.right,
          child: Opacity(
            opacity: small.opacity,
            child: Transform.scale(
              scale: small.scale,
              child: Icon(MdiIcons.starFourPointsSmall, size: smallSlot.size, color: color),
            ),
          ),
        ),
      ],
    );
  }
}

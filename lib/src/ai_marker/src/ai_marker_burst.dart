import 'package:flutter/widgets.dart';

/// The resolved scale and opacity for one of [LayrzAiMarkerBurst]'s two star
/// glyphs at a given point in the burst cycle.
///
/// Bundled as one immutable value (rather than returning scale and opacity
/// separately) so [LayrzAiMarkerBurst.bigStarAt]/[LayrzAiMarkerBurst.smallStarAt]
/// have a single return type and a caller cannot accidentally pair the big
/// star's scale with the small star's opacity.
@immutable
class LayrzAiMarkerBurstFrame {
  /// The glyph's scale factor at this point in the cycle, in `[0.0, 1.0]`
  /// baseline-relative terms where `1.0` is the glyph's resting (settled)
  /// scale. Values briefly exceed `1.0` during the bounce overshoot.
  final double scale;

  /// The glyph's opacity at this point in the cycle, in `[0.0, 1.0]`.
  final double opacity;

  /// Creates a burst frame with the given [scale] and [opacity].
  const LayrzAiMarkerBurstFrame({required this.scale, required this.opacity});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAiMarkerBurstFrame && runtimeType == other.runtimeType && scale == other.scale;

  @override
  int get hashCode => Object.hash(scale, opacity);
}

/// The resting, fully-settled frame every star returns to between bursts and
/// renders permanently under reduce-motion.
const LayrzAiMarkerBurstFrame kLayrzAiMarkerSettledFrame = LayrzAiMarkerBurstFrame(scale: 1.0, opacity: 1.0);

/// **Internal, non-public API.** Not exported from `ai_marker.dart` or the
/// root barrel — `lib/src/ai_marker/src/ai_marker.dart` is this helper's only
/// consumer.
///
/// Computes the staggered scale-bounce + opacity transform for
/// [LayrzAiMarker]'s two overlapping sparkle glyphs from a single driving
/// `Animation<double>` in `[0.0, 1.0]`.
///
/// This is deliberately a pure computation over an animation value — not a
/// [CustomPainter] or a widget — mirroring `LayrzShimmerGradient`'s shape
/// (`lib/src/skeleton/src/shimmer_painter.dart`): it stays trivially testable
/// (assert the frame at a given value) without pumping a widget tree, and the
/// widget layer (`ai_marker.dart`) owns the `AnimationController` and repeat
/// loop.
///
/// **Read target:** the two stars pop in with a bounce and settle — a
/// twinkle, not a spin. There is no rotation anywhere in this helper; a
/// reader reaching for `Transform.rotate` here would produce the loading-
/// spinner read this component must avoid.
///
/// **Stagger:** the small star's [Interval] starts [smallStarDelay] later
/// than the big star's, so the two glyphs are never in identical phase — the
/// small star visibly "pops in after" the big one on every cycle, which is
/// what makes the pair read as a burst rather than two synchronized dots.
@immutable
class LayrzAiMarkerBurst {
  /// Fraction of the cycle, in `(0.0, 1.0)`, that the small star's burst
  /// interval is delayed behind the big star's.
  ///
  /// Defaults to `0.18` — enough to be visibly sequential (not simultaneous)
  /// without leaving the small star idle for a large share of the loop.
  final double smallStarDelay;

  /// Fraction of the cycle, in `(0.0, 1.0]`, that a single star's pop-and-
  /// settle bounce occupies before it holds at the settled frame for the
  /// remainder of the cycle.
  ///
  /// Defaults to `0.55` — the burst plays out over roughly half the loop,
  /// leaving a calm hold before the next repeat, which is what keeps the
  /// continuous loop reading as "gentle" rather than frantic.
  final double burstFraction;

  /// Creates a [LayrzAiMarkerBurst] with the given stagger parameters.
  const LayrzAiMarkerBurst({this.smallStarDelay = 0.18, this.burstFraction = 0.55});

  /// The [Curve] driving the big star's pop-and-settle bounce, occupying the
  /// first [burstFraction] of the cycle and holding at the settled value for
  /// the remainder.
  Curve get _bigStarCurve => Interval(0.0, burstFraction, curve: Curves.elasticOut);

  /// The [Curve] driving the small star's pop-and-settle bounce, starting
  /// [smallStarDelay] into the cycle so it visibly follows the big star.
  Curve get _smallStarCurve =>
      Interval(smallStarDelay, (smallStarDelay + burstFraction).clamp(0.0, 1.0), curve: Curves.elasticOut);

  /// Resolves a raw `[0.0, 1.0]` curve output into a [LayrzAiMarkerBurstFrame].
  ///
  /// [Curves.elasticOut] overshoots past `1.0` mid-bounce by design (the
  /// "pop"); this maps that overshoot into a scale that peaks around `1.15`
  /// and settles at `1.0`, with opacity fading in over the same span so the
  /// glyph doesn't appear at full scale before it's visible.
  LayrzAiMarkerBurstFrame _frameFor(double curved) {
    final scale = 0.6 + curved * 0.4;
    final opacity = curved.clamp(0.0, 1.0);
    return LayrzAiMarkerBurstFrame(scale: scale, opacity: opacity);
  }

  /// The big star's frame at driving animation [value] in `[0.0, 1.0]`.
  LayrzAiMarkerBurstFrame bigStarAt(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return _frameFor(_bigStarCurve.transform(clamped));
  }

  /// The small star's frame at driving animation [value] in `[0.0, 1.0]`,
  /// phase-offset from [bigStarAt] by [smallStarDelay].
  ///
  /// Before its delayed interval starts, the small star holds at scale `0.0`
  /// (invisible) rather than the settled frame — it has not "popped in" yet,
  /// so showing it at rest would read as if it were always there.
  LayrzAiMarkerBurstFrame smallStarAt(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped < smallStarDelay) {
      return const LayrzAiMarkerBurstFrame(scale: 0.0, opacity: 0.0);
    }
    return _frameFor(_smallStarCurve.transform(clamped));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAiMarkerBurst &&
          runtimeType == other.runtimeType &&
          smallStarDelay == other.smallStarDelay &&
          burstFraction == other.burstFraction;

  @override
  int get hashCode => Object.hash(smallStarDelay, burstFraction);
}

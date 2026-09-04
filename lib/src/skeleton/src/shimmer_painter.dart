import 'package:flutter/widgets.dart';

/// Builds the moving-gradient `Shader` behind the design system's shimmer
/// and glint effects.
///
/// **Internal, non-public API.** This file is not exported from any barrel
/// (neither `lib/src/skeleton/skeleton.dart` nor the root `lib/layrz_ui.dart`).
/// It exists purely to give two unrelated public widgets — `LayrzSkeleton`
/// (and its primitives, `lib/src/skeleton/src/skeleton_box.dart` and
/// siblings) and `LayrzAiMarker` (`lib/src/ai_marker/src/ai_marker.dart`,
/// imported cross-module via `package:layrz_ui/src/skeleton/src/shimmer_painter.dart`)
/// — one shared implementation of the identical "moving highlight sweeps
/// across a shape" mechanic, rather than two divergent copies. Skeleton uses
/// it as a loading shimmer; AiMarker reuses it as an animated glint sweep
/// over its icon. Consumers wrap their content in a `ShaderMask` using
/// [gradient] and [shaderRect] (via `ShaderMask.shaderCallback`), the first
/// use of `ShaderMask` in this codebase.
///
/// [LayrzShimmerGradient] is a pure, immutable value describing the gradient
/// and its bounds; it is not itself a [CustomPainter] or a widget — that
/// keeps it trivially testable (gradient stops, colors, and shader rect at a
/// given animation value) without needing a widget pump. Callers typically
/// build one per frame from an `Animation<double>` in `[0.0, 1.0]` via
/// [LayrzShimmerGradient.forAnimationValue] and feed it to `ShaderMask`.
@immutable
class LayrzShimmerGradient {
  /// The base color of the sweep — the color shown outside the moving
  /// highlight band.
  final Color baseColor;

  /// The highlight color — the brighter (or, for a glint, more saturated)
  /// color at the center of the moving band.
  final Color highlightColor;

  /// The current sweep position, in `[0.0, 1.0]`, where `0.0` places the
  /// highlight band just before the start of [shaderRect] and `1.0` places
  /// it just past the end — i.e. the band travels the full bounds plus its
  /// own width, so it fully enters and fully exits on each cycle rather than
  /// snapping partway through.
  final double position;

  /// The width of the highlight band, as a fraction of [shaderRect]'s width,
  /// in `(0.0, 1.0]`.
  final double bandWidth;

  /// The bounds the gradient is stretched across, in the local coordinate
  /// space `ShaderMask.shaderCallback` receives.
  final Rect shaderRect;

  /// Creates a new [LayrzShimmerGradient].
  const LayrzShimmerGradient({
    required this.baseColor,
    required this.highlightColor,
    required this.position,
    required this.shaderRect,
    this.bandWidth = 0.3,
  });

  /// Builds a [LayrzShimmerGradient] for the given animation [value].
  ///
  /// This is the primary construction path for consumers driving the sweep
  /// from an `AnimationController`. [value] is clamped to `[0.0, 1.0]`
  /// defensively — an out-of-range value (e.g. from a curved animation that
  /// overshoots) would otherwise produce a [LinearGradient] with out-of-order
  /// stops, which throws.
  factory LayrzShimmerGradient.forAnimationValue({
    required double value,
    required Color baseColor,
    required Color highlightColor,
    required Rect shaderRect,
    double bandWidth = 0.3,
  }) {
    return LayrzShimmerGradient(
      baseColor: baseColor,
      highlightColor: highlightColor,
      position: value.clamp(0.0, 1.0),
      shaderRect: shaderRect,
      bandWidth: bandWidth,
    );
  }

  /// The unclamped band extent, `[center - half, center + half]`, before
  /// clamping to the `[0.0, 1.0]` range gradient stops require.
  ///
  /// Used by [gradient] to detect when the band has fully entered or fully
  /// exited the visible range -- see the class-level note on why that case
  /// needs its own path.
  (double start, double end) get _unclampedBand {
    final half = bandWidth / 2;
    // position travels across [-bandWidth, 1.0 + bandWidth] conceptually so
    // the band fully enters and exits.
    final center = position * (1.0 + bandWidth) - bandWidth / 2;
    return (center - half, center + half);
  }

  /// Builds the [LinearGradient] for this sweep state, left-to-right across
  /// [shaderRect].
  ///
  /// Near the very start and end of a sweep cycle, the highlight band's
  /// center sits outside `[0.0, 1.0]` while its near edge has already (or
  /// still) clamps into range. Naively clamping `bandStart`/`bandCenter`
  /// onto the same boundary value (`0.0` or `1.0`) while [colors] still
  /// places [highlightColor] at that collapsed stop makes [LinearGradient]
  /// interpolate a hard, near-zero-width jump into and back out of
  /// [highlightColor] right at the shape's edge -- painting a thin bright
  /// line pinned to it every cycle, exactly the stray "border" this shimmer
  /// must never show. The fix: only ever include the [highlightColor] stop
  /// when the band's true, unclamped center itself lies within
  /// `[0.0, 1.0]`. Whenever the center has not yet entered (or has already
  /// left) that range, this returns a flat two-stop [baseColor] gradient --
  /// the visible portion of the band at that point in the cycle is far
  /// enough from its peak that a flat base fill is indistinguishable from
  /// the true (barely-brightened) ramp, and never introduces a coincident
  /// highlight-at-the-edge stop.
  LinearGradient get gradient {
    final (bandStartRaw, bandEndRaw) = _unclampedBand;
    final centerRaw = (bandStartRaw + bandEndRaw) / 2;

    if (centerRaw <= 0.0 || centerRaw >= 1.0) {
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [baseColor, baseColor],
      );
    }

    final bandStart = bandStartRaw.clamp(0.0, 1.0);
    final bandEnd = bandEndRaw.clamp(0.0, 1.0);

    final stops = <double>[0.0, bandStart, centerRaw, bandEnd, 1.0];
    for (var i = 1; i < stops.length; i++) {
      if (stops[i] < stops[i - 1]) stops[i] = stops[i - 1];
    }

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [baseColor, baseColor, highlightColor, baseColor, baseColor],
      stops: stops,
    );
  }

  /// Creates the [Shader] for this sweep state, ready to return from a
  /// `ShaderMask.shaderCallback`.
  Shader createShader() => gradient.createShader(shaderRect);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzShimmerGradient &&
          runtimeType == other.runtimeType &&
          baseColor == other.baseColor &&
          highlightColor == other.highlightColor &&
          position == other.position &&
          bandWidth == other.bandWidth &&
          shaderRect == other.shaderRect;

  @override
  int get hashCode => Object.hash(baseColor, highlightColor, position, bandWidth, shaderRect);
}

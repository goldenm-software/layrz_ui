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

  /// The gradient stops for the moving band, in the fixed order
  /// `[start, bandStart, bandCenter, bandEnd, end]`, monotonically
  /// non-decreasing and clamped to `[0.0, 1.0]` as required by [LinearGradient].
  List<double> get _stops {
    final half = bandWidth / 2;
    // position travels across [-bandWidth, 1.0 + bandWidth] conceptually so
    // the band fully enters and exits; remapped here into stops clamped to
    // the valid [0.0, 1.0] range gradient stops require.
    final center = position * (1.0 + bandWidth) - bandWidth / 2;
    final bandStart = (center - half).clamp(0.0, 1.0);
    final bandEnd = (center + half).clamp(0.0, 1.0);
    final clampedCenter = center.clamp(0.0, 1.0);

    final stops = <double>[0.0, bandStart, clampedCenter, bandEnd, 1.0];
    for (var i = 1; i < stops.length; i++) {
      if (stops[i] < stops[i - 1]) stops[i] = stops[i - 1];
    }
    return stops;
  }

  /// Builds the [LinearGradient] for this sweep state, left-to-right across
  /// [shaderRect].
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [baseColor, baseColor, highlightColor, baseColor, baseColor],
    stops: _stops,
  );

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

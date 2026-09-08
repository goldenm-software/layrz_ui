import 'package:flutter/widgets.dart';

/// Paints an opaque black fill shape for a skeleton shape primitive
/// (`LayrzSkeletonBox`, `LayrzSkeletonCircle`, `LayrzSkeletonLine`), either a
/// rounded rectangle or a circle depending on which constructor is used.
///
/// **Internal, non-public API.** Not exported from any barrel. Replaces the
/// `DecoratedBox`/`BoxDecoration` fill every skeleton primitive previously
/// used, which is not usable here because `BoxDecoration` exposes no control
/// over its fill's antialiasing.
///
/// **Why this exists**: [LayrzSkeletonShimmerBox] composites this shape's
/// filled area through a `ShaderMask` (`BlendMode.srcIn`). The engine's
/// `ShaderMaskLayer::Paint` applies that mask by drawing a plain,
/// non-antialiased `DrawRect` exactly the size of the shape's `SizedBox`
/// (see `shader_mask_layer.cc`, `saveLayer(paint_bounds())` followed by a
/// `canvas->DrawRect(shader_rect, dl_paint)` with no antialiasing flag set).
/// `DecoratedBox`'s fill, by contrast, is painted via `Canvas.drawRRect`
/// with Skia's default `Paint(isAntiAlias: true)` — so the shape's own edge
/// blends its fill color to transparent over roughly one device pixel,
/// while the mask that gates visibility through `ShaderMask` has a hard,
/// unblended edge at that exact same logical boundary. The two edges never
/// agree on how much of that boundary pixel is "inside", leaving a
/// partial-alpha ring at top and bottom — the hairline seam.
///
/// Nudging the shape's height (as a previous fix attempted, moving
/// `kLayrzSkeletonInputHeight` from `43.0` to `43.5`) cannot fix this: whichever
/// edge lands on a fractional device pixel still carries Skia's antialiasing,
/// so the mismatch just relocates to a different edge. The only
/// edge-independent fix is to remove the mismatch itself, by making the
/// shape's own fill non-antialiased so its edge is exactly as hard as the
/// mask's — this widget does that by painting with `Paint()..isAntiAlias =
/// false`.
class LayrzSkeletonFill extends StatelessWidget {
  /// The corner radius applied to a rounded-rectangle fill, in logical
  /// pixels. Null when this fill paints a circle instead (see
  /// [LayrzSkeletonFill.circle]).
  final double? borderRadius;

  /// Whether this fill paints a circle (using the painted area's shortest
  /// side as the diameter) rather than a rounded rectangle.
  final bool isCircle;

  /// Creates a rounded-rectangle [LayrzSkeletonFill] with the given
  /// [borderRadius], in logical pixels. Pass `0.0` for sharp corners.
  const LayrzSkeletonFill({super.key, required double this.borderRadius}) : isCircle = false;

  /// Creates a circular [LayrzSkeletonFill], sized to the shortest side of
  /// the area it is painted into.
  const LayrzSkeletonFill.circle({super.key}) : borderRadius = null, isCircle = true;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LayrzSkeletonFillPainter(borderRadius: borderRadius, isCircle: isCircle),
    );
  }
}

/// The [CustomPainter] backing [LayrzSkeletonFill].
///
/// Paints with `isAntiAlias: false` — see the class-level doc on
/// [LayrzSkeletonFill] for why that is the fix and not an oversight.
class _LayrzSkeletonFillPainter extends CustomPainter {
  /// The corner radius to paint with, in logical pixels; null for a circle.
  final double? borderRadius;

  /// Whether to paint a circle instead of a rounded rectangle.
  final bool isCircle;

  /// Creates a new [_LayrzSkeletonFillPainter].
  const _LayrzSkeletonFillPainter({required this.borderRadius, required this.isCircle});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;

    if (isCircle) {
      canvas.drawOval(rect, paint);
      return;
    }

    final radius = borderRadius ?? 0.0;
    if (radius <= 0.0) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LayrzSkeletonFillPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.isCircle != isCircle;
}

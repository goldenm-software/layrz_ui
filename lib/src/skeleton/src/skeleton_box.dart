import 'package:flutter/widgets.dart';

import 'skeleton_fill.dart';
import 'skeleton_shimmer_box.dart';

/// The standard height of a `LayrzInput` chrome, in logical pixels, used as
/// the preset for [LayrzSkeletonBox.input].
///
/// Derived from the non-dense, regular (viewport ≥ 960px) input chrome:
/// `contentHeight` (20) + two vertical paddings of `tokens.spacing.pd2` (10
/// each, 20 total) + two borders of `tokens.border.base` (1.5 each, 3 total)
/// = 43.0.
///
/// This is the honest geometric value with no fractional-pixel adjustment.
/// An earlier fix attempted to close a hairline seam by bumping this to
/// `43.5` (a "half-pixel snap"), reasoning that a whole-number height was
/// landing the box's edge on a fractional device-pixel boundary. That did
/// not work — it only relocated the seam to the opposite edge, proving the
/// seam was never about which physical pixel the edge fell on. The actual
/// cause and fix live in [LayrzSkeletonFill]'s class-level doc: the seam is
/// an antialiasing mismatch between the shape's own fill edge and the
/// engine's `ShaderMask` mask edge, fixed by painting the fill without
/// antialiasing so both edges agree exactly. With that fixed at the source,
/// this constant carries no fractional-pixel hack.
///
/// This constant does **not** cover the dense variant (~35lp) or the
/// compact-viewport variant (~51lp) of `LayrzInput` — matching those exactly
/// is a known limitation of [LayrzSkeletonBox.input].
const double kLayrzSkeletonInputHeight = 43.0;

/// The standard corner radius of a `LayrzInput` chrome, in logical pixels,
/// used as the preset for [LayrzSkeletonBox.input].
///
/// Mirrors `tokens.radius.br2`, the `BorderRadius.circular(10)` applied to
/// the input container.
const double kLayrzSkeletonInputRadius = 10.0;

/// A rectangular skeleton shape primitive — the loading placeholder for a
/// block of content with an explicit, known size, such as an image, a card,
/// or a button.
///
/// [LayrzSkeletonBox] is used as a child of `LayrzSkeleton`'s `child` tree,
/// alongside other primitives (`LayrzSkeletonCircle`, `LayrzSkeletonLine`),
/// composed by the caller into the shape of the real widget being loaded:
///
/// ```dart
/// LayrzSkeleton(
///   child: LayrzSkeletonBox(width: 200, height: 120, borderRadius: 12),
/// )
/// ```
///
/// **No-reflow**: [width] and [height] are honored exactly — this primitive
/// never imposes a minimum size or clamps its dimensions — so giving it the
/// same size as the real content it stands in for guarantees the page does
/// not jump when the real content replaces it.
///
/// Used standalone (outside any `LayrzSkeleton` ancestor), it still shimmers
/// via a self-owned fallback ticker, so it renders sensibly in isolation
/// (e.g. a widget catalog page or a unit test) — see
/// `LayrzSkeletonShimmerBox` for that fallback mechanism.
class LayrzSkeletonBox extends StatelessWidget {
  /// The width of the box, in logical pixels.
  final double width;

  /// The height of the box, in logical pixels.
  final double height;

  /// The corner radius applied to the box, in logical pixels.
  ///
  /// Defaults to `0.0` (sharp corners). Set this to match the border radius
  /// of the real content this primitive stands in for.
  final double borderRadius;

  /// Creates a new [LayrzSkeletonBox].
  const LayrzSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 0.0,
  });

  /// Creates a [LayrzSkeletonBox] preset to simulate a standard `LayrzInput`.
  ///
  /// Presets [height] to [kLayrzSkeletonInputHeight] and [borderRadius] to
  /// [kLayrzSkeletonInputRadius], matching the non-dense, regular
  /// (viewport ≥ 960px) input chrome. Only [width] is required from the
  /// caller — skeletons have no way to know the width of the real content
  /// they stand in for.
  ///
  /// This preset does **not** account for the dense (~35lp) or
  /// compact-viewport (~51lp) `LayrzInput` variants; use the default
  /// constructor with an explicit [height] to match those instead.
  const LayrzSkeletonBox.input({
    super.key,
    required this.width,
    double? borderRadius,
  }) : height = kLayrzSkeletonInputHeight,
       borderRadius = borderRadius ?? kLayrzSkeletonInputRadius;

  @override
  Widget build(BuildContext context) {
    return LayrzSkeletonShimmerBox(
      shape: SizedBox(
        width: width,
        height: height,
        child: LayrzSkeletonFill(borderRadius: borderRadius),
      ),
    );
  }
}

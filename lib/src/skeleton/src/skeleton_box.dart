import 'package:flutter/widgets.dart';

import 'skeleton_shimmer_box.dart';

/// The standard height of a `LayrzInput` chrome, in logical pixels, used as
/// the preset for [LayrzSkeletonBox.input].
///
/// Derived from the non-dense, regular (viewport ≥ 960px) input chrome:
/// `contentHeight` (20) + two vertical paddings of `tokens.spacing.pd2` (10
/// each, 20 total) + two borders of `tokens.border.base` (1.5 each, 3 total)
/// = 43.0.
///
/// A trailing `.5` is added on top of that geometric `43.0` — not part of
/// the derivation above, but a half-logical-pixel anti-hairline snap. A
/// whole-number height of exactly `43.0` can land the box's top edge on a
/// fractional physical-pixel boundary at certain devicePixelRatios, which
/// anti-aliases into a faint 1px seam rendered just above the box. Adding
/// `.5` nudges the edge off that boundary, matching the identical `+ .5`
/// fix already applied to derived line heights in
/// `skeleton_line.dart:88` (`LayrzSkeletonLine._resolvedHeight`).
///
/// This constant does **not** cover the dense variant (~35lp) or the
/// compact-viewport variant (~51lp) of `LayrzInput` — matching those exactly
/// is a known limitation of [LayrzSkeletonBox.input].
const double kLayrzSkeletonInputHeight = 43.5;

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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

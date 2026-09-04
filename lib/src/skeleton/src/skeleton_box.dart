import 'package:flutter/widgets.dart';

import 'skeleton_shimmer_box.dart';

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

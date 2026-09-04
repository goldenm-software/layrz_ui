import 'package:flutter/widgets.dart';

import 'skeleton_shimmer_box.dart';

/// A circular skeleton shape primitive — the loading placeholder for a
/// round element such as an avatar or a circular icon button.
///
/// [LayrzSkeletonCircle] is used as a child of `LayrzSkeleton`'s `child`
/// tree, alongside other primitives (`LayrzSkeletonBox`, `LayrzSkeletonLine`),
/// composed by the caller into the shape of the real widget being loaded:
///
/// ```dart
/// LayrzSkeleton(
///   child: LayrzSkeletonCircle(diameter: 40),
/// )
/// ```
///
/// **No-reflow**: [diameter] is honored exactly — this primitive never
/// imposes a minimum size — so giving it the same diameter as the real
/// avatar/icon it stands in for guarantees the page does not jump when the
/// real content replaces it.
///
/// Used standalone (outside any `LayrzSkeleton` ancestor), it still shimmers
/// via a self-owned fallback ticker, so it renders sensibly in isolation
/// (e.g. a widget catalog page or a unit test) — see
/// `LayrzSkeletonShimmerBox` for that fallback mechanism.
class LayrzSkeletonCircle extends StatelessWidget {
  /// The diameter of the circle (both width and height), in logical pixels.
  final double diameter;

  /// Creates a new [LayrzSkeletonCircle].
  const LayrzSkeletonCircle({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return LayrzSkeletonShimmerBox(
      shape: SizedBox(
        width: diameter,
        height: diameter,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF000000),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

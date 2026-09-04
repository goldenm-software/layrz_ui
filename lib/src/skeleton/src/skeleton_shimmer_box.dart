import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/skeleton/src/shimmer_painter.dart';

import 'skeleton_scope.dart';

/// Shared rendering plumbing behind every skeleton shape primitive
/// (`LayrzSkeletonBox`, `LayrzSkeletonCircle`, `LayrzSkeletonLine`).
///
/// **Internal, non-public API.** Not exported from any barrel. Each
/// primitive is a thin, differently-shaped [ClipPath]/[DecoratedBox] wrapper
/// around this widget, which owns the one piece of logic all three would
/// otherwise duplicate: reading the shared shimmer animation from
/// [LayrzSkeletonScope] when nested under a [LayrzSkeleton], or falling back
/// to a self-owned [AnimationController] when used standalone (e.g. in a
/// widget catalog page, or a test that renders a single primitive in
/// isolation without a [LayrzSkeleton] ancestor).
///
/// Reduced motion is honored identically in both modes: when
/// [MediaQuery.disableAnimationsOf] is true, the standalone fallback never
/// starts a ticker, and a shared animation from the scope (which
/// [LayrzSkeleton] itself never creates under reduced motion) simply won't
/// be present — either way, [build] paints a single static frame of the
/// shimmer at its base color with no animation applied.
class LayrzSkeletonShimmerBox extends StatefulWidget {
  /// The decorated shape to paint underneath the shimmer sweep — e.g. a
  /// rounded [DecoratedBox] for [LayrzSkeletonBox], a circular one for
  /// [LayrzSkeletonCircle].
  final Widget shape;

  /// Creates a new [LayrzSkeletonShimmerBox] wrapping [shape].
  const LayrzSkeletonShimmerBox({super.key, required this.shape});

  @override
  State<LayrzSkeletonShimmerBox> createState() => _LayrzSkeletonShimmerBoxState();
}

class _LayrzSkeletonShimmerBoxState extends State<LayrzSkeletonShimmerBox> with SingleTickerProviderStateMixin {
  AnimationController? _fallbackController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFallbackController();
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  /// Creates or tears down the self-owned fallback ticker, used only when no
  /// [LayrzSkeletonScope] is found above this widget (standalone usage).
  ///
  /// Re-run on every dependency change so a runtime reduce-motion toggle is
  /// honored without remounting, matching [LayrzSkeleton]'s own behavior.
  void _syncFallbackController() {
    if (LayrzSkeletonScope.maybeOf(context) != null) {
      // A shared animation is available — no fallback ticker needed.
      _fallbackController?.dispose();
      _fallbackController = null;
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _fallbackController?.dispose();
      _fallbackController = null;
      return;
    }
    if (_fallbackController != null) return;
    final tokens = context.tokens;
    _fallbackController = AnimationController(duration: tokens.motion.dIndeterminate, vsync: this)..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final baseColor = tokens.colors.sf3;
    final highlightColor = tokens.colors.sf1;

    final animation = LayrzSkeletonScope.maybeOf(context) ?? _fallbackController;

    if (animation == null) {
      // Reduced motion with no shared scope: paint a static, unshimmered
      // frame at the base color.
      return DecoratedBox(
        decoration: BoxDecoration(color: baseColor),
        child: widget.shape,
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            return LayrzShimmerGradient.forAnimationValue(
              value: animation.value,
              baseColor: baseColor,
              highlightColor: highlightColor,
              shaderRect: rect,
            ).createShader();
          },
          child: child,
        );
      },
      child: widget.shape,
    );
  }
}

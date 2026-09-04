import 'package:flutter/widgets.dart';

/// Propagates the shared shimmer [Animation] owned by an ancestor
/// [LayrzSkeleton] down to descendant skeleton primitives, so every primitive
/// in the tree sweeps in phase.
///
/// **Internal, non-public API.** This file is not exported from
/// `lib/src/skeleton/skeleton.dart` or the root barrel. Skeleton primitives
/// (`LayrzSkeletonBox`, `LayrzSkeletonCircle`, `LayrzSkeletonLine`) look this
/// scope up via [maybeOf]; when it is absent (a primitive used standalone,
/// outside any `LayrzSkeleton`), they fall back to a self-owned
/// [AnimationController] instead, which is why [maybeOf] rather than [of] is
/// the only accessor offered here — there is no scenario where a missing
/// scope should be a programmer error.
class LayrzSkeletonScope extends InheritedWidget {
  /// The shared shimmer animation, in `[0.0, 1.0]`, driven by the ancestor
  /// [LayrzSkeleton]'s single [AnimationController].
  ///
  /// Descendant primitives rebuild from this via [AnimatedBuilder] to paint
  /// their shimmer sweep at the same phase as every sibling primitive.
  final Animation<double> animation;

  /// Creates a [LayrzSkeletonScope] exposing [animation] to [child] and its
  /// descendants.
  const LayrzSkeletonScope({
    super.key,
    required this.animation,
    required super.child,
  });

  /// Returns the nearest [LayrzSkeletonScope]'s [animation], or `null` if
  /// this widget is not nested under a [LayrzSkeleton].
  static Animation<double>? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayrzSkeletonScope>()?.animation;
  }

  @override
  bool updateShouldNotify(LayrzSkeletonScope oldWidget) => animation != oldWidget.animation;
}

import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'skeleton_scope.dart';

/// A loading placeholder that drives ONE shared shimmer sweep over a
/// caller-composed tree of skeleton shape primitives.
///
/// [LayrzSkeleton] is deliberately not a "wrap your real widget and we'll
/// silhouette it for you" component, and it does not know how to render any
/// particular shape itself. Instead, the caller builds the loading
/// boilerplate of their widget out of the shape primitives —
/// `LayrzSkeletonBox`, `LayrzSkeletonCircle`, `LayrzSkeletonLine` — arranged
/// in whatever layout (`Row`, `Column`, nested, …) matches the real content
/// that will eventually replace them:
///
/// ```dart
/// LayrzSkeleton(
///   child: Row(
///     children: [
///       const LayrzSkeletonCircle(diameter: 40),
///       const SizedBox(width: 12),
///       Column(
///         crossAxisAlignment: CrossAxisAlignment.start,
///         children: const [
///           LayrzSkeletonLine(width: 120),
///           SizedBox(height: 6),
///           LayrzSkeletonLine(width: 80),
///         ],
///       ),
///     ],
///   ),
/// )
/// ```
///
/// [LayrzSkeleton] owns exactly ONE [AnimationController] and exposes its
/// animation to every descendant primitive via [LayrzSkeletonScope], an
/// [InheritedWidget]. Every primitive in [child] therefore shimmers in
/// phase — there is no per-primitive drift, because there is only one
/// ticker driving the whole subtree.
///
/// **Reduced motion**: when [MediaQuery.disableAnimationsOf] reports that
/// the user has requested reduced motion, no [AnimationController] is
/// created at all and [child] is rendered as a static block — no shimmer,
/// no scheduled frames. This is re-evaluated on every rebuild and on
/// [didUpdateWidget], so toggling the OS setting at runtime starts or stops
/// the ticker without needing to remount.
///
/// **Semantics**: the entire [child] subtree is wrapped in [ExcludeSemantics]
/// and then in one outer `Semantics(label: 'Loading')` node, so a screen
/// reader announces "Loading" exactly once for the whole placeholder rather
/// than once per shape primitive underneath it — a tree of a dozen
/// `LayrzSkeletonBox`/`LayrzSkeletonLine` instances would otherwise read as a
/// dozen indistinguishable, meaningless announcements.
///
/// **No-reflow**: [LayrzSkeleton] itself imposes no sizing — it defers
/// entirely to [child]'s intrinsic size, which in turn is whatever the
/// caller's primitives declare via their own explicit `width`/`height`. Get
/// those dimensions right and the loading state occupies exactly the box the
/// real content will occupy, so the page does not jump when the real content
/// arrives.
class LayrzSkeleton extends StatefulWidget {
  /// The tree of skeleton shape primitives (`LayrzSkeletonBox`,
  /// `LayrzSkeletonCircle`, `LayrzSkeletonLine`, arranged in ordinary layout
  /// widgets) that stands in for the real content while it loads.
  ///
  /// This is the caller's "boilerplate" of the widget being loaded — its
  /// exact shape and sizing are entirely up to the caller, not inferred from
  /// any real widget. Required.
  final Widget child;

  /// Creates a new [LayrzSkeleton].
  const LayrzSkeleton({super.key, required this.child});

  @override
  State<LayrzSkeleton> createState() => _LayrzSkeletonState();
}

class _LayrzSkeletonState extends State<LayrzSkeleton> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery is only safe to read once dependencies are established,
    // which initState cannot guarantee — the controller is therefore
    // (re)created here rather than in initState, mirroring
    // LayrzProgressBar's indeterminate-sweep controller.
    _syncController();
  }

  @override
  void didUpdateWidget(covariant LayrzSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Creates the shimmer ticker when motion is allowed and one does not
  /// already exist, or tears it down when reduced motion is requested.
  ///
  /// Re-run on every dependency change and every widget update so a runtime
  /// toggle of the OS reduce-motion setting starts or stops the sweep
  /// without requiring [LayrzSkeleton] to be remounted.
  void _syncController() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller != null) return;
    final tokens = context.tokens;
    _controller = AnimationController(duration: tokens.motion.dIndeterminate, vsync: this)..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final excluded = ExcludeSemantics(child: widget.child);
    final content = controller == null ? excluded : LayrzSkeletonScope(animation: controller, child: excluded);

    return Semantics(
      label: 'Loading',
      container: true,
      child: content,
    );
  }
}

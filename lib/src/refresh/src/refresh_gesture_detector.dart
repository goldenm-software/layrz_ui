import 'package:flutter/widgets.dart';

import 'refresh_controller.dart';

/// The optional, touch-only drag-to-refresh entry point for
/// [LayrzRefreshController].
///
/// **This is a secondary affordance.** [LayrzRefreshController.refresh] is
/// the primary, always-available API; this widget exists only so a touch
/// user dragging past the top of a scrollable gets the familiar
/// pull-to-refresh gesture as an alternative way to reach the same
/// controller call. A desktop user with a mouse or trackpad cannot produce
/// the drag this widget listens for and is expected to use the programmatic
/// path instead — that is by design, not a gap.
///
/// Wraps [child] (expected to contain a scrollable) with a
/// [NotificationListener]`<ScrollNotification>` that watches for
/// [OverscrollNotification]s carrying real [DragUpdateDetails] at the start
/// of the scroll extent — i.e. an actual finger/pointer drag past the top,
/// not a ballistic overscroll or a mouse-wheel bounce. **Deliberately does
/// not install or modify any [ScrollPhysics] or [ScrollBehavior]**: per the
/// batch's cross-cutting scroll-integration ruling, decorating every
/// scrollable globally is out of scope for a single widget, and a local
/// notification listener is sufficient for a fixed-threshold v1.
///
/// **v1 has no resistance/overscroll physics.** [dragProgress] is a linear
/// mapping of drag distance to [triggerDistance] — an eased/resisted curve is
/// a polish pass, not required for a working first version.
class LayrzRefreshGestureDetector extends StatelessWidget {
  /// Creates a [LayrzRefreshGestureDetector].
  const LayrzRefreshGestureDetector({
    required this.controller,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 80.0,
    super.key,
  });

  /// The controller whose [LayrzRefreshController.updateDragProgress] and
  /// [LayrzRefreshController.releaseDrag] this widget drives as the user
  /// drags.
  final LayrzRefreshController controller;

  /// Invoked once the drag is released past [triggerDistance].
  ///
  /// The returned `Future` is awaited by the controller before it settles;
  /// see [LayrzRefreshController.refresh].
  final Future<void> Function() onRefresh;

  /// The scrollable content this gesture wraps.
  ///
  /// Must contain a [Scrollable] descendant (e.g. a `ListView`) for
  /// [OverscrollNotification]s to be dispatched at all.
  final Widget child;

  /// How far, in logical pixels, the user must drag past the top of the
  /// scroll extent before releasing commits to a refresh.
  ///
  /// [LayrzRefreshController.dragProgress] is `overscroll / triggerDistance`,
  /// clamped to `[0.0, 1.0]`.
  final double triggerDistance;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification && notification.dragDetails != null) {
          _handleOverscroll(notification);
        } else if (notification is ScrollEndNotification && notification.dragDetails != null) {
          controller.releaseDrag(onRefresh);
        }
        return false;
      },
      child: child,
    );
  }

  void _handleOverscroll(OverscrollNotification notification) {
    // Only the top-side overscroll (negative) drives pull-to-refresh; bottom
    // overscroll is not this widget's concern.
    if (notification.overscroll >= 0) return;
    if (notification.metrics.pixels > notification.metrics.minScrollExtent) return;

    final draggedSoFar = controller.dragProgress * triggerDistance - notification.overscroll;
    controller.updateDragProgress(draggedSoFar / triggerDistance);
  }
}

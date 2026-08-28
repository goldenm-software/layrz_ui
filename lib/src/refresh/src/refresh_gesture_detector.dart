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
///
/// **Reversal-aware by construction.** Under [ClampingScrollPhysics] (and any
/// physics that clamps [ScrollMetrics.pixels] at the boundary), overscroll is
/// a one-way ratchet with no persisted magnitude: [ScrollMetrics.pixels]
/// stays pinned exactly at `minScrollExtent` for the entire pull, and the
/// *only* place the pulled distance ever appears is the transient
/// `overscroll` field of each [OverscrollNotification]. The instant the user
/// reverses direction by any amount at all — even a single logical pixel —
/// the boundary condition clears completely and the scrollable resumes
/// normal scrolling from `pixels == minScrollExtent`; there is no
/// intermediate "still pulling, but less" state to read back from the
/// notification stream. This widget is therefore stateful only in the sense
/// that it accumulates the incoming pull across consecutive
/// [OverscrollNotification]s within one gesture (so a multi-frame pull adds
/// up instead of resetting every frame), while treating any other
/// [ScrollNotification] seen at the top of the list — a plain
/// [ScrollUpdateNotification] once the reversal has cleared the boundary, or
/// [ScrollStartNotification] for a brand new gesture — as the signal that the
/// pull has ended and [_dragDistance] must snap back to zero.
class LayrzRefreshGestureDetector extends StatefulWidget {
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
  State<LayrzRefreshGestureDetector> createState() => _LayrzRefreshGestureDetectorState();
}

class _LayrzRefreshGestureDetectorState extends State<LayrzRefreshGestureDetector> {
  /// How far, in logical pixels, the current gesture has dragged past the
  /// top of the scroll extent.
  ///
  /// Accumulated from each top-side [OverscrollNotification]'s `overscroll`
  /// delta across the life of one gesture. Reset to `0.0` the instant the
  /// pull ends for any reason -- a fresh [ScrollStartNotification], or any
  /// notification other than a top-side overscroll (which, per the
  /// class-level doc, is exactly what a reversal produces the moment it
  /// clears the boundary) -- so neither a new gesture nor a cancelled one
  /// ever inherits a stale distance.
  double _dragDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification && notification.dragDetails != null && _isTopSide(notification)) {
          _handleOverscroll(notification);
        } else if (notification is ScrollEndNotification && notification.dragDetails != null) {
          widget.controller.releaseDrag(widget.onRefresh);
          _dragDistance = 0.0;
        } else {
          // A new gesture starting, or the list resuming normal scroll after
          // a reversal cleared the boundary (see the class-level doc) --
          // either way the pull is over and must not leave a stale distance
          // for the next [OverscrollNotification] to build on.
          _resetDrag();
        }
        return false;
      },
      child: widget.child,
    );
  }

  /// Whether [notification] reports overscroll at the top of the list.
  ///
  /// This check alone is what distinguishes top-side pull-to-refresh
  /// overscroll from bottom-side overscroll -- the sign of `overscroll` is
  /// not sufficient on its own to make that distinction.
  bool _isTopSide(OverscrollNotification notification) {
    return notification.metrics.pixels <= notification.metrics.minScrollExtent;
  }

  void _handleOverscroll(OverscrollNotification notification) {
    _dragDistance -= notification.overscroll;
    widget.controller.updateDragProgress(_dragDistance / widget.triggerDistance);
  }

  /// Ends the current pull, if any, snapping [_dragDistance] and the
  /// controller's `dragProgress` back to zero.
  ///
  /// Called whenever the notification stream reports anything other than an
  /// ongoing top-side overscroll: a new gesture starting, the list resuming
  /// normal scroll after a reversal, or the gesture ending. Guarded by
  /// [_dragDistance] being non-zero so it does not fight the "armed" state
  /// with a redundant zero update on every unrelated notification (e.g. a
  /// bottom-side overscroll) once the pull is already at rest.
  void _resetDrag() {
    if (_dragDistance == 0.0) return;
    _dragDistance = 0.0;
    widget.controller.updateDragProgress(0.0);
  }
}

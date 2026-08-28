import 'package:flutter/foundation.dart';

import 'refresh_state.dart';

/// A controller that drives a [LayrzRefreshIndicator]'s refresh lifecycle.
///
/// This is the **primary public API** for triggering a refresh — not a test
/// hook layered under a gesture. Call [refresh] from a button, a keyboard
/// shortcut, a pull-to-refresh drag, or any other app logic; every entry
/// point drives the same state machine and the same visual.
///
/// **Architecture:**
/// The controller owns [state] and [dragProgress]. [LayrzRefreshIndicator] is
/// a pure observer that subscribes via `addListener` and rebuilds its visual
/// from the current state. This mirrors [LayrzStepperController]'s contract:
/// the controller is the source of truth, the widget is a thin renderer.
///
/// **Lifecycle and disposal:**
/// - **Disposal is caller-owned.** If a [LayrzRefreshIndicator]'s controller
///   is supplied by the caller, the indicator does NOT dispose it. If the
///   indicator creates an internal controller (the constructor's default),
///   the indicator disposes its own instance.
/// - The controller instance must never be swapped on a widget already
///   mounted with one; [LayrzRefreshIndicator] asserts this in
///   `didUpdateWidget`.
///
/// **State machine**: `idle → armed → refreshing → settling → idle`. See
/// [LayrzRefreshState] for what each state means and which paths reach it.
class LayrzRefreshController extends ChangeNotifier {
  /// The controller's current position in the refresh lifecycle.
  LayrzRefreshState get state => _state;
  LayrzRefreshState _state = LayrzRefreshState.idle;

  /// How far the optional drag gesture has progressed toward its trigger
  /// threshold, clamped to `[0.0, 1.0]`.
  ///
  /// `0.0` means no drag (or the gesture layer is not in use at all — a
  /// programmatic [refresh] never touches this field, so it stays `0.0`
  /// throughout a programmatic-only refresh cycle). `1.0` means the drag has
  /// reached (or passed) the trigger threshold and the state has moved to
  /// [LayrzRefreshState.armed]. Read by [LayrzRefreshIndicator]'s visual to
  /// animate the indicator in step with the drag before it commits.
  double get dragProgress => _dragProgress;
  double _dragProgress = 0.0;

  /// Whether a refresh is currently in flight or settling.
  ///
  /// True for [LayrzRefreshState.refreshing] and [LayrzRefreshState.settling];
  /// false for [LayrzRefreshState.idle] and [LayrzRefreshState.armed]. Useful
  /// for callers that want to disable a manual "refresh" button while one is
  /// already running.
  bool get isRefreshing => _state == LayrzRefreshState.refreshing || _state == LayrzRefreshState.settling;

  /// Programmatically starts a refresh cycle.
  ///
  /// This is the controller's **first-class public API** — the way a caller
  /// without a pointing device (or without the patience for a drag) triggers
  /// the exact same loading affordance a gesture would. It is a no-op if a
  /// refresh is already in progress ([isRefreshing] is already true), so it
  /// is always safe to call from a button's `onTap` without guarding first.
  ///
  /// [onRefresh] is awaited; the controller stays in
  /// [LayrzRefreshState.refreshing] until it resolves (or throws — the
  /// controller settles either way, since the caller's loading state is over
  /// regardless of success or failure), then transitions to
  /// [LayrzRefreshState.settling] and finally back to
  /// [LayrzRefreshState.idle] once [settle] is called by the indicator's
  /// retraction animation.
  ///
  /// Returns the same `Future` that [onRefresh] returns, so a caller can
  /// `await` completion (for example to show a snackbar after the data
  /// lands). Rethrows any error from [onRefresh] after settling, so a caller
  /// awaiting [refresh] still observes the failure.
  Future<void> refresh(Future<void> Function() onRefresh) async {
    if (isRefreshing) return;

    _dragProgress = 0.0;
    _state = LayrzRefreshState.refreshing;
    notifyListeners();

    try {
      await onRefresh();
    } finally {
      _state = LayrzRefreshState.settling;
      notifyListeners();
    }
  }

  /// Called by the settling animation once it completes, returning the
  /// controller to [LayrzRefreshState.idle].
  ///
  /// Not intended for direct use by application code — [LayrzRefreshIndicator]
  /// calls this when its retraction animation finishes. Exposed as public API
  /// (rather than library-private) so a custom visual built outside this
  /// package's [LayrzRefreshIndicator] can still drive the same controller
  /// correctly.
  void settle() {
    if (_state != LayrzRefreshState.settling) return;
    _state = LayrzRefreshState.idle;
    _dragProgress = 0.0;
    notifyListeners();
  }

  /// Updates [dragProgress] from the optional gesture layer.
  ///
  /// [progress] is clamped to `[0.0, 1.0]` and only has an effect while the
  /// controller is [LayrzRefreshState.idle] or [LayrzRefreshState.armed] —
  /// once a refresh has committed ([LayrzRefreshState.refreshing] or later),
  /// further drag updates are ignored so an in-flight refresh cannot be
  /// disturbed by a stray overscroll.
  ///
  /// Not intended for direct use by application code — the optional
  /// [LayrzRefreshGestureDetector] calls this as the user drags. Exposed as
  /// public API so a caller building a custom gesture surface can drive the
  /// same controller.
  void updateDragProgress(double progress) {
    if (_state != LayrzRefreshState.idle && _state != LayrzRefreshState.armed) {
      return;
    }

    final clamped = progress.clamp(0.0, 1.0);
    _dragProgress = clamped;
    _state = clamped >= 1.0 ? LayrzRefreshState.armed : LayrzRefreshState.idle;
    notifyListeners();
  }

  /// Commits an armed drag into an actual refresh, or resets to idle if the
  /// drag was released before reaching the trigger threshold.
  ///
  /// Not intended for direct use by application code — the optional
  /// [LayrzRefreshGestureDetector] calls this when the pointer is released.
  /// Exposed as public API so a caller building a custom gesture surface can
  /// drive the same controller. If the controller is [LayrzRefreshState.armed],
  /// starts [onRefresh] via [refresh]; otherwise resets [dragProgress] to
  /// `0.0` without starting a refresh.
  Future<void> releaseDrag(Future<void> Function() onRefresh) async {
    if (_state == LayrzRefreshState.armed) {
      await refresh(onRefresh);
      return;
    }

    _dragProgress = 0.0;
    notifyListeners();
  }
}

/// The lifecycle states of a [LayrzRefreshController]-driven refresh cycle.
///
/// A refresh always progresses through the same four states in order, whether
/// it was triggered programmatically via [LayrzRefreshController.refresh] or
/// by the optional drag gesture:
///
/// [idle] → [armed] → [refreshing] → [settling] → back to [idle].
///
/// [armed] is skipped entirely for a programmatic trigger — there is no drag
/// distance to arm past, so the controller moves straight from [idle] to
/// [refreshing]. [armed] only exists on the gesture path, where it represents
/// the caller having dragged past the trigger threshold but not yet released.
enum LayrzRefreshState {
  /// No refresh is in progress and no gesture has crossed the trigger
  /// threshold. The indicator is fully retracted and invisible.
  idle,

  /// The optional drag gesture has crossed the trigger threshold but the
  /// pointer has not yet been released. Releasing now commits to
  /// [refreshing]; continuing to drag stays in [armed]. Never reached by the
  /// programmatic [LayrzRefreshController.refresh] path.
  armed,

  /// A refresh is actively in progress: the caller's `Future` has been
  /// started and has not yet resolved. The indicator shows its loading
  /// affordance and announces itself to assistive technology.
  refreshing,

  /// The caller's `Future` has resolved and the indicator is animating back
  /// to its retracted resting position. Automatically transitions to [idle]
  /// once the retraction animation completes.
  settling,
}

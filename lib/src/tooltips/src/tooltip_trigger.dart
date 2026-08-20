/// Enumeration of tooltip trigger modes.
///
/// Determines how a [LayrzTooltip] is shown and dismissed:
/// - [pointer]: triggered by hover (desktop) or long-press (touch); dismissed on pointer-exit or tap-away
/// - [tap]: triggered by a single tap; dismissed by another tap or tap-away
enum LayrzTooltipTrigger {
  /// Tooltip is triggered by pointer hover (desktop) or long-press (touch).
  ///
  /// When opened by touch, a full-screen barrier is created so tap-away dismisses
  /// the tooltip. When opened by hover, no barrier is created and the tooltip
  /// dismisses on pointer exit.
  pointer,

  /// Tooltip is triggered and dismissed by single taps.
  ///
  /// A single tap on the child toggles the tooltip open/closed. When open, a full-screen
  /// barrier is always created (regardless of pointer kind), so tapping elsewhere
  /// dismisses the tooltip. Hover has no effect in this mode.
  tap,
}

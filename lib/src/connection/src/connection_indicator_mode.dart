/// The two render modes supported by `LayrzConnectionIndicator`.
enum LayrzConnectionIndicatorMode {
  /// Renders a small colored dot (via `LayrzBadgeVisual`) wrapped in a
  /// `LayrzTooltip` announcing the resolved state and a humanized
  /// "time ago" string.
  ///
  /// Must not be paired with a `child` — see the assertion documented on
  /// `LayrzConnectionIndicator`'s constructor.
  dot,

  /// Renders a self-contained chip showing the resolved state's localized
  /// label (e.g. "Online", "Idle", "Offline", "Disconnected", "No data") on
  /// a state-colored chrome.
  ///
  /// `child` is ignored in this mode — see the class-level doc on
  /// `LayrzConnectionIndicator`.
  full,
}

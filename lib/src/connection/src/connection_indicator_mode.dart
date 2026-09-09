/// The two render modes supported by `LayrzConnectionIndicator`.
enum LayrzConnectionIndicatorMode {
  /// Renders a small colored dot (via `LayrzBadgeVisual`) wrapped in a
  /// `LayrzTooltip` announcing the resolved state and a humanized
  /// "time ago" string.
  ///
  /// Must not be paired with a `child` — see the assertion documented on
  /// `LayrzConnectionIndicator`'s constructor.
  dot,

  /// Renders the given `child` wrapped in a colored pill/chrome whose
  /// background or border reflects the resolved state.
  ///
  /// Requires a non-null `child` — see the assertion documented on
  /// `LayrzConnectionIndicator`'s constructor.
  full,
}

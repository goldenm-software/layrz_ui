/// Duration unit types for time-span input.
///
/// Represents the fixed-length units that map directly to [Duration]: day, hour,
/// minute, and second. Week, month, and year are not supported because they are
/// not fixed-length and cannot be reliably converted to or from [Duration].
enum LayrzDurationUnit {
  /// A day unit (24 hours).
  ///
  /// No upper bound. Represents a full 24-hour period.
  day,

  /// An hour unit (0–23).
  ///
  /// Bounded 0–23 to map unambiguously to [Duration.inHours].
  /// When filled from a stored [Duration], hour is computed as `duration.inHours % 24`.
  hour,

  /// A minute unit (0–59).
  ///
  /// Bounded 0–59 to map unambiguously to the minute component.
  /// When filled from a stored [Duration], minute is computed as `(duration.inMinutes % 60)`.
  minute,

  /// A second unit (0–59).
  ///
  /// Bounded 0–59 to map unambiguously to the second component.
  /// When filled from a stored [Duration], second is computed as `(duration.inSeconds % 60)`.
  second,
}

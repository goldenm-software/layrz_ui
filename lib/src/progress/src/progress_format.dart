/// The rendering format of a `LayrzProgressBar`.
///
/// Selects between the traditional horizontal track ([linear]) and a ring
/// indicator ([circular]). Both formats support the same determinate and
/// indeterminate behaviours, the same semantic color resolution
/// (`LayrzProgressType`), and the same reduced-motion handling — only the
/// geometry painted, and which sizing parameters apply, differs between them.
///
/// This is deliberately a separate enum from `LayrzProgressType`, which
/// selects the semantic accent *color* (info/success/warning/danger/context/
/// custom). `LayrzProgressFormat` selects the *shape*; the two are
/// independent axes and every combination of the two enums is valid.
enum LayrzProgressFormat {
  /// A horizontal bar, filling from the leading edge in determinate mode and
  /// sweeping back and forth across the track in indeterminate mode.
  ///
  /// Sized by `LayrzProgressBar.height` (defaults to `kLayrzProgressBarHeight`).
  linear,

  /// A circular ring, filling clockwise from 12 o'clock in determinate mode
  /// and rotating in indeterminate mode.
  ///
  /// Sized by `LayrzProgressBar.size` (defaults to `kLayrzProgressCircularSize`)
  /// and `LayrzProgressBar.strokeWidth` (defaults to
  /// `kLayrzProgressCircularStrokeWidth`).
  circular,
}

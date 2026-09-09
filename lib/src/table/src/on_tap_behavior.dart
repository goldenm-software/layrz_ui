/// The default cell-tap behavior for a [LayrzTable]-like widget, applied when
/// a column's own `onTap` callback is not supplied.
///
/// This enum is retained for API-surface compatibility with the equivalent
/// `layrz_theme` baseline. It does **not** drive the effective per-cell tap
/// dispatch on its own: that decision is made per-column, by the presence or
/// absence of the column's own `onTap` callback. When a column omits `onTap`,
/// the table falls back to copying the cell's displayed text to the clipboard
/// and showing a confirmation toast — the same effective behavior as
/// [copyToClipboard] — regardless of this enum's value. There is currently no
/// caller-facing switch that changes this fallback; keep exactly these two
/// values.
enum LayrzTableOnTapBehavior {
  /// No default tap behavior is applied to a cell lacking a column-level
  /// `onTap` callback. The cell renders as non-interactive with respect to
  /// tap gestures.
  none,

  /// The default tap behavior copies the cell's displayed text to the
  /// clipboard and shows a confirmation toast. This is the effective
  /// behavior applied whenever a column's `onTap` callback is `null`.
  copyToClipboard,
}

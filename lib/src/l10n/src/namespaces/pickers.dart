/// Picker-specific namespace, covering strings for the shared day/month grid
/// surfaces and their range-selection affordances (`lib/src/pickers/`) that
/// do not already fit an existing namespace.
///
/// Cancel/Save/Reset action labels are deliberately **not** duplicated here —
/// `LayrzUiL10nActionsMixin.actionCancel`/`actionSave`/`actionReset` already
/// cover them and every range picker surface reuses those keys directly.
mixin LayrzUiL10nPickersMixin {
  /// Localized semantics/visible label for the affordance that clears an
  /// in-progress or completed range selection, shown as soon as a range
  /// exists.
  String get pickerRangeReset => 'Clear selection';

  /// Localized semantics announcement for a day or month cell representing
  /// "today", read in addition to the cell's own date/month label.
  String get pickerTodayLabel => 'Today';

  /// Localized semantics announcement appended to a cell that is currently
  /// selected.
  String get pickerSelectedLabel => 'Selected';

  /// Localized semantics announcement appended to a cell that falls inside a
  /// completed range but is not itself an endpoint — used to explain why the
  /// cell rejects taps (see the range selection state machine's interior-tap
  /// rejection rule).
  String get pickerRangeInteriorLabel => 'Within selected range, not selectable';

  /// Localized semantics announcement appended to a cell that is disabled
  /// (outside `firstDay`/`lastDay` bounds or in `disabledDays`/
  /// `disabledMonths`).
  String get pickerDisabledLabel => 'Unavailable';
}

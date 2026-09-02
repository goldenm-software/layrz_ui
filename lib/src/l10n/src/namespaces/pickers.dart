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

  /// Localized overflow summary for `LayrzMonthRangeInput`'s arbitrary
  /// (non-contiguous) mode, shown in the anchor field once the selection
  /// exceeds the widget's comma-joined-list threshold and collapses to a
  /// count instead.
  ///
  /// [count] is the number of selected months; the returned phrase is
  /// singular/plural-aware (`"1 month selected"` vs. `"5 months selected"`),
  /// following the count-aware method pattern established by
  /// `LayrzUiL10nHelpersMixin.helperDurationDays` — pluralization is resolved
  /// here rather than by the caller appending an `s`.
  String pickerMonthRangeCount(int count) => count == 1 ? '$count month selected' : '$count months selected';
}

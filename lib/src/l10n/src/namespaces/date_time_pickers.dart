/// Date & Time Pickers namespace.
mixin LayrzUiL10nDateTimePickersMixin {
  /// Localized text for "Date" tab label in datetime picker.
  String get dateTimePickerDate => 'Date';

  /// Localized text for "Time" tab label in datetime picker.
  String get dateTimePickerTime => 'Time';

  /// Localized label for hours input field.
  String get timePickerHours => 'Hours';

  /// Localized label for minutes input field.
  String get timePickerMinutes => 'Minutes';

  /// Localized label for seconds input field.
  ///
  /// The old layrz_theme time picker had no seconds field at all, so this key
  /// is genuinely new rather than a rename of an existing one.
  String get timePickerSeconds => 'Seconds';

  /// Singular short-form abbreviation of "hour" (1 hour), for
  /// [LayrzPickersTimeFieldsPanel]'s narrow-width field label.
  ///
  /// Mirrors `LayrzUiL10nInputsMixin.durationUnitHourShortSingular`'s
  /// singular/plural split -- see that key's doc comment for why a short
  /// form is needed at all: real translations of the unabridged
  /// `timePickerHours`/`timePickerMinutes`/`timePickerSeconds` labels (e.g.
  /// Spanish "Segundos", 8 characters) overflow `LayrzNumberInput`'s chrome
  /// below a measured width threshold.
  ///
  /// English default: "h"
  String get timePickerHourShortSingular => 'h';

  /// Plural short-form abbreviation of "hour" (2+ hours, or the field's
  /// count-agnostic display when the panel does not track singular/plural).
  ///
  /// See [timePickerHourShortSingular] for why this key exists.
  ///
  /// English default: "h"
  String get timePickerHourShortPlural => 'h';

  /// Singular short-form abbreviation of "minute" (1 minute).
  ///
  /// See [timePickerHourShortSingular] for why this key exists.
  ///
  /// English default: "m"
  String get timePickerMinuteShortSingular => 'm';

  /// Plural short-form abbreviation of "minute" (2+ minutes).
  ///
  /// See [timePickerHourShortSingular] for why this key exists.
  ///
  /// English default: "m"
  String get timePickerMinuteShortPlural => 'm';

  /// Singular short-form abbreviation of "second" (1 second).
  ///
  /// See [timePickerHourShortSingular] for why this key exists.
  ///
  /// English default: "s"
  String get timePickerSecondShortSingular => 's';

  /// Plural short-form abbreviation of "second" (2+ seconds).
  ///
  /// See [timePickerHourShortSingular] for why this key exists.
  ///
  /// English default: "s"
  String get timePickerSecondShortPlural => 's';

  /// Localized label for start time in time range picker.
  String get timePickerStart => 'Start time';

  /// Localized label for end time in time range picker.
  String get timePickerEnd => 'End time';

  /// Localized text for month picker year display with the given year.
  ///
  /// Example: "Year 2024"
  String monthPickerYear(int year) => 'Year $year';

  /// Localized text for "Previous year" navigation button in month picker.
  String get monthPickerBack => 'Previous year';

  /// Localized text for "Next year" navigation button in month picker.
  String get monthPickerNext => 'Next year';

  /// Localized separator rendered between a range's start and end summary
  /// text, e.g. the `" – "` in `"Sep 1, 2026 – Sep 14, 2026"`.
  ///
  /// Deliberately an l10n key rather than a caller-supplied template string:
  /// a template parameter would reopen the same free-form formatting surface
  /// the strftime formatter (`lib/src/formatting/`) exists to replace, this
  /// time for range display specifically. Callers needing full control over
  /// range display should compose their own summary from the range's
  /// [start]/[end] fields and a `formatter` override instead.
  String get dateTimePickerRangeSeparator => ' – ';

  /// Localized label for the ISO week-number gutter alongside a compact day
  /// grid, when the gutter renders a text label rather than staying purely
  /// numeric decoration.
  String get dateTimePickerWeekNumberLabel => 'Wk';
}

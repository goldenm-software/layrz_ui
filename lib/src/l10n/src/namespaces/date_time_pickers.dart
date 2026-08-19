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
}

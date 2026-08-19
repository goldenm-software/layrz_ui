/// Date & Time Pickers namespace.
abstract mixin class LayrzDateTimePickersLocalizations {
  /// Localized text for "Date" tab label in datetime picker.
  String get dateTimePickerDate;

  /// Localized text for "Time" tab label in datetime picker.
  String get dateTimePickerTime;

  /// Localized label for hours input field.
  String get timePickerHours;

  /// Localized label for minutes input field.
  String get timePickerMinutes;

  /// Localized label for start time in time range picker.
  String get timePickerStart;

  /// Localized label for end time in time range picker.
  String get timePickerEnd;

  /// Localized text for month picker year display with the given year.
  ///
  /// Example: "Year 2024"
  String monthPickerYear(int year);

  /// Localized text for "Previous year" navigation button in month picker.
  String get monthPickerBack;

  /// Localized text for "Next year" navigation button in month picker.
  String get monthPickerNext;
}

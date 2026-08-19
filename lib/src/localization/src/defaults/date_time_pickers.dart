import '../contract/date_time_pickers.dart';

/// English default implementations for Date & Time Pickers namespace.
mixin LayrzDefaultDateTimePickersLocalizations implements LayrzDateTimePickersLocalizations {
  @override
  String get dateTimePickerDate => 'Date';

  @override
  String get dateTimePickerTime => 'Time';

  @override
  String get timePickerHours => 'Hours';

  @override
  String get timePickerMinutes => 'Minutes';

  @override
  String get timePickerStart => 'Start time';

  @override
  String get timePickerEnd => 'End time';

  @override
  String monthPickerYear(int year) => 'Year $year';

  @override
  String get monthPickerBack => 'Previous year';

  @override
  String get monthPickerNext => 'Next year';
}

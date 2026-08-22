/// Inputs namespace — localized strings for input components and pickers.
mixin LayrzUiL10nInputsMixin {
  /// Localized default hint text for the search input field.
  ///
  /// Default: "Search"
  String get inputsSearchHint => 'Search';

  /// Singular form of "day" (1 day).
  ///
  /// Used when displaying a duration with exactly one day unit.
  ///
  /// English default: "day"
  String get durationUnitDaySingular => 'day';

  /// Plural form of "day" (2+ days).
  ///
  /// Used when displaying a duration with more than one day unit.
  ///
  /// English default: "days"
  String get durationUnitDayPlural => 'days';

  /// Singular form of "hour" (1 hour).
  ///
  /// Used when displaying a duration with exactly one hour unit.
  ///
  /// English default: "hour"
  String get durationUnitHourSingular => 'hour';

  /// Plural form of "hour" (2+ hours).
  ///
  /// Used when displaying a duration with more than one hour unit.
  ///
  /// English default: "hours"
  String get durationUnitHourPlural => 'hours';

  /// Singular form of "minute" (1 minute).
  ///
  /// Used when displaying a duration with exactly one minute unit.
  ///
  /// English default: "minute"
  String get durationUnitMinuteSingular => 'minute';

  /// Plural form of "minute" (2+ minutes).
  ///
  /// Used when displaying a duration with more than one minute unit.
  ///
  /// English default: "minutes"
  String get durationUnitMinutePlural => 'minutes';

  /// Singular form of "second" (1 second).
  ///
  /// Used when displaying a duration with exactly one second unit.
  ///
  /// English default: "second"
  String get durationUnitSecondSingular => 'second';

  /// Plural form of "second" (2+ seconds).
  ///
  /// Used when displaying a duration with more than one second unit.
  ///
  /// English default: "seconds"
  String get durationUnitSecondPlural => 'seconds';

  /// Label for the reset action in a duration picker.
  ///
  /// Announces the reset button that zeros all time units in the picker.
  ///
  /// English default: "Reset"
  String get durationReset => 'Reset';

  /// Accessible name for the day field in a duration picker.
  ///
  /// Describes the numeric input field for days without relying on visual labels.
  ///
  /// English default: "Days"
  String get durationFieldDay => 'Days';

  /// Accessible name for the hour field in a duration picker.
  ///
  /// Describes the numeric input field for hours without relying on visual labels.
  ///
  /// English default: "Hours"
  String get durationFieldHour => 'Hours';

  /// Accessible name for the minute field in a duration picker.
  ///
  /// Describes the numeric input field for minutes without relying on visual labels.
  ///
  /// English default: "Minutes"
  String get durationFieldMinute => 'Minutes';

  /// Accessible name for the second field in a duration picker.
  ///
  /// Describes the numeric input field for seconds without relying on visual labels.
  ///
  /// English default: "Seconds"
  String get durationFieldSecond => 'Seconds';
}

/// DateTime Helpers — Weekday & Month Names namespace.
mixin LayrzUiL10nWeekdaysMixin {
  /// Localized name for Monday.
  String get dateTimeMonday => 'Monday';

  /// Localized name for Tuesday.
  String get dateTuesday => 'Tuesday';

  /// Localized name for Wednesday.
  String get dateWednesday => 'Wednesday';

  /// Localized name for Thursday.
  String get dateThursday => 'Thursday';

  /// Localized name for Friday.
  String get dateFriday => 'Friday';

  /// Localized name for Saturday.
  String get dateSaturday => 'Saturday';

  /// Localized name for Sunday.
  String get dateSunday => 'Sunday';

  /// Localized single-letter initial for Monday, used in a compact weekday
  /// header row (e.g. picker day grids). Cannot be derived from
  /// [dateTimeMonday] across locales — e.g. Spanish "Miércoles" and
  /// "Martes" both start with "M" — so this carries its own key.
  String get weekdayInitialMonday => 'M';

  /// Localized single-letter initial for Tuesday. See [weekdayInitialMonday].
  String get weekdayInitialTuesday => 'T';

  /// Localized single-letter initial for Wednesday. See [weekdayInitialMonday].
  String get weekdayInitialWednesday => 'W';

  /// Localized single-letter initial for Thursday. See [weekdayInitialMonday].
  String get weekdayInitialThursday => 'T';

  /// Localized single-letter initial for Friday. See [weekdayInitialMonday].
  String get weekdayInitialFriday => 'F';

  /// Localized single-letter initial for Saturday. See [weekdayInitialMonday].
  String get weekdayInitialSaturday => 'S';

  /// Localized single-letter initial for Sunday. See [weekdayInitialMonday].
  String get weekdayInitialSunday => 'S';

  /// Localized abbreviated (three-letter-scale) name for Monday, e.g. "Mon".
  ///
  /// Used by the `%a` strftime directive. Distinct from
  /// [weekdayInitialMonday]'s single-letter form — `%a` needs a short *word*,
  /// not an initial.
  String get weekdayAbbreviatedMonday => 'Mon';

  /// Localized abbreviated name for Tuesday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedTuesday => 'Tue';

  /// Localized abbreviated name for Wednesday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedWednesday => 'Wed';

  /// Localized abbreviated name for Thursday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedThursday => 'Thu';

  /// Localized abbreviated name for Friday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedFriday => 'Fri';

  /// Localized abbreviated name for Saturday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedSaturday => 'Sat';

  /// Localized abbreviated name for Sunday. See [weekdayAbbreviatedMonday].
  String get weekdayAbbreviatedSunday => 'Sun';
}

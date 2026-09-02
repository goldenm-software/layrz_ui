/// DateTime Helpers — Month Names & Meridiem Markers namespace.
mixin LayrzUiL10nMonthsMixin {
  /// Localized name for January.
  String get monthJanuary => 'January';

  /// Localized name for February.
  String get monthFebruary => 'February';

  /// Localized name for March.
  String get monthMarch => 'March';

  /// Localized name for April.
  String get monthApril => 'April';

  /// Localized name for May.
  String get monthMay => 'May';

  /// Localized name for June.
  String get monthJune => 'June';

  /// Localized name for July.
  String get monthJuly => 'July';

  /// Localized name for August.
  String get monthAugust => 'August';

  /// Localized name for September.
  String get monthSeptember => 'September';

  /// Localized name for October.
  String get monthOctober => 'October';

  /// Localized name for November.
  String get monthNovember => 'November';

  /// Localized name for December.
  String get monthDecember => 'December';

  /// Localized abbreviated name for January, e.g. "Jan". Used by the `%b`
  /// strftime directive.
  String get monthAbbreviatedJanuary => 'Jan';

  /// Localized abbreviated name for February. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedFebruary => 'Feb';

  /// Localized abbreviated name for March. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedMarch => 'Mar';

  /// Localized abbreviated name for April. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedApril => 'Apr';

  /// Localized abbreviated name for May. See [monthAbbreviatedJanuary].
  ///
  /// English "May" has no shorter conventional abbreviation; kept
  /// unabbreviated to match common strftime output (`%b` for May is "May").
  String get monthAbbreviatedMay => 'May';

  /// Localized abbreviated name for June. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedJune => 'Jun';

  /// Localized abbreviated name for July. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedJuly => 'Jul';

  /// Localized abbreviated name for August. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedAugust => 'Aug';

  /// Localized abbreviated name for September. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedSeptember => 'Sep';

  /// Localized abbreviated name for October. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedOctober => 'Oct';

  /// Localized abbreviated name for November. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedNovember => 'Nov';

  /// Localized abbreviated name for December. See [monthAbbreviatedJanuary].
  String get monthAbbreviatedDecember => 'Dec';

  /// Localized marker for the ante-meridiem ("AM") half of a 12-hour clock.
  String get timeMeridiemAm => 'AM';

  /// Localized marker for the post-meridiem ("PM") half of a 12-hour clock.
  String get timeMeridiemPm => 'PM';
}

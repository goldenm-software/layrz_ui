/// Helpers — General Utilities namespace.
mixin LayrzUiL10nHelpersMixin {
  /// Localized text for generic "Search" action.
  String get helperSearch => 'Search';
  /// Localized text for "Show" button.
  String get helperButtonsShow => 'Show';
  /// Localized text for "Edit" button.
  String get helperButtonsEdit => 'Edit';
  /// Localized text for "Delete" button.
  String get helperButtonsDelete => 'Delete';
  /// Localized title when multiple items are selected.
  String get helperMultipleSelectionTitle => 'Multiple items selected';
  /// Localized descriptive text for multiple selection context.
  String get helperMultipleSelectionCaption => 'Descriptive text';
  /// Localized text for cancelling bulk actions.
  String get helperMultipleSelectionActionsCancel => 'Cancel';
  /// Localized text for bulk deletion action.
  String get helperMultipleSelectionActionsDelete => 'Delete';
  /// Localized confirmation message when content is copied to clipboard.
  String get helperCopiedToClipboard => 'Copied to clipboard';
  /// Localized button label for copying content to clipboard.
  String get helperCopyToClipboardPost => 'Copy to clipboard';
  /// Localized conjunction word used in lists (e.g., "Item A and Item B").
  String get helperAnd => 'and';
  /// Localized representation of boolean true value.
  String get helperTrue => 'true';
  /// Localized representation of boolean false value.
  String get helperFalse => 'false';
  /// Localized text for year time unit (standalone).
  String get helperYear => 'year';
  /// Localized text for month time unit (standalone).
  String get helperMonth => 'month';
  /// Localized text for days time unit (plural form).
  String get helperDays => 'days';
  /// Localized text for weeks time unit (plural form).
  String get helperWeeks => 'weeks';
  /// Localized text for hours time unit (plural form).
  String get helperHours => 'hours';
  /// Localized text for minutes time unit (plural form).
  String get helperMinutes => 'minutes';
  /// Localized text for seconds time unit (plural form).
  String get helperSeconds => 'seconds';
  /// Localized text for milliseconds time unit (plural form).
  String get helperMilliseconds => 'milliseconds';
  /// Localized duration unit for days with count-aware singular/plural.
  ///
  /// Example: "1 day" or "5 days"
  String helperDurationDays(int count) => count == 1 ? 'day' : 'days';

  /// Localized duration unit for hours with count-aware singular/plural.
  String helperDurationHours(int count) => count == 1 ? 'hour' : 'hours';

  /// Localized duration unit for minutes with count-aware singular/plural.
  String helperDurationMinutes(int count) => count == 1 ? 'minute' : 'minutes';

  /// Localized duration unit for seconds with count-aware singular/plural.
  String helperDurationSeconds(int count) => count == 1 ? 'second' : 'seconds';

  /// Localized duration unit for weeks with count-aware singular/plural.
  String helperDurationWeeks(int count) => count == 1 ? 'week' : 'weeks';

  /// Localized duration unit for months with count-aware singular/plural.
  String helperDurationMonths(int count) => count == 1 ? 'month' : 'months';

  /// Localized duration unit for years with count-aware singular/plural.
  String helperDurationYears(int count) => count == 1 ? 'year' : 'years';

  /// Localized duration unit for milliseconds with count-aware singular/plural.
  String helperDurationMilliseconds(int count) => count == 1 ? 'millisecond' : 'milliseconds';
}

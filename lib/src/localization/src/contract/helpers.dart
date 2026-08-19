/// Helpers — General Utilities namespace.
abstract mixin class LayrzHelpersLocalizations {
  /// Localized text for generic "Search" action.
  String get helperSearch;

  /// Localized text for "Show" button.
  String get helperButtonsShow;

  /// Localized text for "Edit" button.
  String get helperButtonsEdit;

  /// Localized text for "Delete" button.
  String get helperButtonsDelete;

  /// Localized title when multiple items are selected.
  String get helperMultipleSelectionTitle;

  /// Localized descriptive text for multiple selection context.
  String get helperMultipleSelectionCaption;

  /// Localized text for cancelling bulk actions.
  String get helperMultipleSelectionActionsCancel;

  /// Localized text for bulk deletion action.
  String get helperMultipleSelectionActionsDelete;

  /// Localized confirmation message when content is copied to clipboard.
  String get helperCopiedToClipboard;

  /// Localized button label for copying content to clipboard.
  String get helperCopyToClipboardPost;

  /// Localized conjunction word used in lists (e.g., "Item A and Item B").
  String get helperAnd;

  /// Localized representation of boolean true value.
  String get helperTrue;

  /// Localized representation of boolean false value.
  String get helperFalse;

  /// Localized text for year time unit (standalone).
  String get helperYear;

  /// Localized text for month time unit (standalone).
  String get helperMonth;

  /// Localized text for days time unit (plural form).
  String get helperDays;

  /// Localized text for weeks time unit (plural form).
  String get helperWeeks;

  /// Localized text for hours time unit (plural form).
  String get helperHours;

  /// Localized text for minutes time unit (plural form).
  String get helperMinutes;

  /// Localized text for seconds time unit (plural form).
  String get helperSeconds;

  /// Localized text for milliseconds time unit (plural form).
  String get helperMilliseconds;

  /// Localized duration unit for days with count-aware singular/plural.
  ///
  /// Example: "1 day" or "5 days"
  String helperDurationDays(int count);

  /// Localized duration unit for hours with count-aware singular/plural.
  String helperDurationHours(int count);

  /// Localized duration unit for minutes with count-aware singular/plural.
  String helperDurationMinutes(int count);

  /// Localized duration unit for seconds with count-aware singular/plural.
  String helperDurationSeconds(int count);

  /// Localized duration unit for weeks with count-aware singular/plural.
  String helperDurationWeeks(int count);

  /// Localized duration unit for months with count-aware singular/plural.
  String helperDurationMonths(int count);

  /// Localized duration unit for years with count-aware singular/plural.
  String helperDurationYears(int count);

  /// Localized duration unit for milliseconds with count-aware singular/plural.
  String helperDurationMilliseconds(int count);
}

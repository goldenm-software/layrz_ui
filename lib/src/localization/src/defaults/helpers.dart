import '../contract/helpers.dart';

/// English default implementations for Helpers namespace.
mixin LayrzDefaultHelpersLocalizations implements LayrzHelpersLocalizations {
  @override
  String get helperSearch => 'Search';

  @override
  String get helperButtonsShow => 'Show';

  @override
  String get helperButtonsEdit => 'Edit';

  @override
  String get helperButtonsDelete => 'Delete';

  @override
  String get helperMultipleSelectionTitle => 'Multiple items selected';

  @override
  String get helperMultipleSelectionCaption => 'Descriptive text';

  @override
  String get helperMultipleSelectionActionsCancel => 'Cancel';

  @override
  String get helperMultipleSelectionActionsDelete => 'Delete';

  @override
  String get helperCopiedToClipboard => 'Copied to clipboard';

  @override
  String get helperCopyToClipboardPost => 'Copy to clipboard';

  @override
  String get helperAnd => 'and';

  @override
  String get helperTrue => 'true';

  @override
  String get helperFalse => 'false';

  @override
  String get helperYear => 'year';

  @override
  String get helperMonth => 'month';

  @override
  String get helperDays => 'days';

  @override
  String get helperWeeks => 'weeks';

  @override
  String get helperHours => 'hours';

  @override
  String get helperMinutes => 'minutes';

  @override
  String get helperSeconds => 'seconds';

  @override
  String get helperMilliseconds => 'milliseconds';

  @override
  String helperDurationDays(int count) => count == 1 ? 'day' : 'days';

  @override
  String helperDurationHours(int count) => count == 1 ? 'hour' : 'hours';

  @override
  String helperDurationMinutes(int count) => count == 1 ? 'minute' : 'minutes';

  @override
  String helperDurationSeconds(int count) => count == 1 ? 'second' : 'seconds';

  @override
  String helperDurationWeeks(int count) => count == 1 ? 'week' : 'weeks';

  @override
  String helperDurationMonths(int count) => count == 1 ? 'month' : 'months';

  @override
  String helperDurationYears(int count) => count == 1 ? 'year' : 'years';

  @override
  String helperDurationMilliseconds(int count) => count == 1 ? 'millisecond' : 'milliseconds';
}

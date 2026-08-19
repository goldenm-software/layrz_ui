/// Select Input namespace.
mixin LayrzUiL10nSelectMixin {
  /// Localized placeholder for search field in select dialog.
  ///
  /// Default: "Search in the list"
  String get selectSearch => 'Search in the list';

  /// Localized empty state message when no items match the search.
  ///
  /// Default: "No item found"
  String get selectEmpty => 'No item found';

  /// Localized text for "Select all" bulk action.
  String get selectSelectAll => 'Select all';

  /// Localized text for "Unselect all" bulk action.
  String get selectUnselectAll => 'Unselect all';

  /// Localized text for unselect action on a single item.
  String get selectUnselect => 'Unselect';
}

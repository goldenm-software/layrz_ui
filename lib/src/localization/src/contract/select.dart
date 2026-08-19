/// Select Input namespace.
abstract mixin class LayrzSelectLocalizations {
  /// Localized placeholder for search field in select dialog.
  ///
  /// Default: "Search in the list"
  String get selectSearch;

  /// Localized empty state message when no items match the search.
  ///
  /// Default: "No item found"
  String get selectEmpty;

  /// Localized text for "Select all" bulk action.
  String get selectSelectAll;

  /// Localized text for "Unselect all" bulk action.
  String get selectUnselectAll;

  /// Localized text for unselect action on a single item.
  String get selectUnselect;
}

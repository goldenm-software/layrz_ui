/// Dual-List Input namespace.
mixin LayrzUiL10nDualListMixin {
  /// Localized search placeholder with the given list name.
  ///
  /// Example: "Search in Available"
  String dualListSearch(String listName) => 'Search in $listName';

  /// Localized text for "Toggle all to selected" bulk action.
  String get dualListToggleToSelected => 'Toggle all to selected';

  /// Localized text for "Toggle all to available" bulk action.
  String get dualListToggleToAvailable => 'Toggle all to available';

  /// Localized text for left panel header: "Available".
  String get dualListAvailableListName => 'Available';

  /// Localized text for right panel header: "Selected".
  String get dualListSelectedListName => 'Selected';
}

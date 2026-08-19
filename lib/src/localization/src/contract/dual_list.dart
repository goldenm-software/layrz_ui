/// Dual-List Input namespace.
abstract mixin class LayrzDualListLocalizations {
  /// Localized search placeholder with the given list name.
  ///
  /// Example: "Search in Available"
  String dualListSearch(String name);

  /// Localized text for "Toggle all to selected" bulk action.
  String get dualListToggleToSelected;

  /// Localized text for "Toggle all to available" bulk action.
  String get dualListToggleToAvailable;

  /// Localized text for left panel header: "Available".
  String get dualListAvailableListName;

  /// Localized text for right panel header: "Selected".
  String get dualListSelectedListName;
}

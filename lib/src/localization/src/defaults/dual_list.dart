import '../contract/dual_list.dart';

/// English default implementations for Dual-List Input namespace.
mixin LayrzDefaultDualListLocalizations implements LayrzDualListLocalizations {
  @override
  String dualListSearch(String name) => 'Search in $name';

  @override
  String get dualListToggleToSelected => 'Toggle all to selected';

  @override
  String get dualListToggleToAvailable => 'Toggle all to available';

  @override
  String get dualListAvailableListName => 'Available';

  @override
  String get dualListSelectedListName => 'Selected';
}

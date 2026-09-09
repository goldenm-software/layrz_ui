/// Multi-Select Input namespace, covering strings for the checkbox-toggling
/// surface of `LayrzMultiSelectInput` (`lib/src/pickers/src/multi_select/`) —
/// its search hint, empty state, and bulk "select all"/"unselect all"
/// affordances.
///
/// Save/Cancel action labels are deliberately **not** duplicated here —
/// `LayrzUiL10nActionsMixin.actionSave`/`actionCancel` already cover the
/// surface's staged-with-Save actions row and it reuses those keys directly.
/// The bulk "select all"/"unselect all" labels are also deliberately not
/// reused from `LayrzUiL10nSelectMixin.selectSelectAll`/`selectUnselectAll` —
/// those are declared on the single-select surface, which has no such
/// affordance in practice today; multi-select gets its own keys so either
/// surface's wording can evolve independently.
mixin LayrzUiL10nMultiSelectMixin {
  /// Localized placeholder for the search field in the multi-select surface.
  ///
  /// Default: "Search in the list"
  String get multiSelectSearch => 'Search in the list';

  /// Localized empty state message when no items match the search.
  ///
  /// Default: "No item found"
  String get multiSelectEmpty => 'No item found';

  /// Localized text for the bulk action that selects every visible item.
  ///
  /// Default: "Select all"
  String get multiSelectSelectAll => 'Select all';

  /// Localized text for the bulk action that clears every selected item.
  ///
  /// Default: "Unselect all"
  String get multiSelectUnselectAll => 'Unselect all';

  /// Localized label for the "All" tab in the surface's tab strip, carrying
  /// the total (or search-filtered) item count.
  ///
  /// Default: "All ($count)"
  String multiSelectTabAll(int count) => 'All ($count)';

  /// Localized label for the "Selected" tab in the surface's tab strip,
  /// carrying the count of items currently in the draft.
  ///
  /// Default: "Selected ($count)"
  String multiSelectTabSelected(int count) => 'Selected ($count)';
}

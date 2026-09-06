/// Icon Picker namespace, covering strings for the MDI icon-grid surface of
/// `LayrzIconInput` (`lib/src/pickers/src/icon/`) — its search hint and the
/// empty state shown when no icon matches the current search text.
mixin LayrzUiL10nIconPickerMixin {
  /// Localized placeholder for the search field in the icon picker surface.
  ///
  /// Default: "Search icon"
  String get iconPickerSearch => 'Search icon';

  /// Localized empty state message when no icon matches the current search
  /// text.
  ///
  /// Default: "No icon found"
  String get iconPickerEmpty => 'No icon found';
}

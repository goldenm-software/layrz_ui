/// Scaffold namespace.
mixin LayrzUiL10nScaffoldMixin {
  /// Localized empty state message when the list has no items.
  String get scaffoldEmpty => 'No items';

  /// Localized label for `LayrzApp`'s automatic debug-mode watermark.
  ///
  /// Used as the default `LayrzAppBanner.labelText` that `LayrzApp` installs
  /// automatically in debug builds when no caller-supplied `banner` is
  /// provided (see DESIGN-114). Never shown outside `kDebugMode`.
  ///
  /// English default: "DEBUG"
  String get debugBanner => 'DEBUG';
}

/// Scaffold namespace.
mixin LayrzUiL10nScaffoldMixin {
  /// Localized empty state message when the list has no items.
  String get scaffoldEmpty => 'No items';

  /// Localized label (and tooltip hint) for `LayrzScaffoldShell`'s built-in
  /// list-panel footer refresh affordance, shown only when
  /// `LayrzScaffoldShell.onRefresh` is non-null.
  ///
  /// English default: "Refresh"
  String get scaffoldRefresh => 'Refresh';

  /// Localized label (and accessibility/tooltip hint) for the "open item"
  /// affordance in `LayrzScaffoldShell`'s desktop default table view — the
  /// per-row button that opens an item's detail pane, collapsing the shell
  /// from the full-width table into the list-detail split.
  ///
  /// Used as the default `LayrzScaffoldShell.showActionLabel` when the caller
  /// supplies none.
  ///
  /// English default: "Open item"
  String get scaffoldOpenItem => 'Open item';

  /// Localized placeholder message shown in `LayrzScaffoldShell`'s detail pane
  /// (`DetailPane`) whenever it is rendered with no selection — i.e. no
  /// `LayrzScaffoldController.openedBuilder`.
  ///
  /// Used as the built-in default whenever the detail pane's own caller
  /// supplies no override for that slot — e.g. `LayrzScaffoldShell`'s
  /// `dualPaneEmptyState`, consumed only while `preferDualPane` keeps the
  /// split shown with nothing open.
  ///
  /// English default: "No item selected"
  String get scaffoldNoSelection => 'No item selected';

  /// Localized label for `LayrzApp`'s automatic debug-mode watermark.
  ///
  /// Used as the default `LayrzAppBanner.labelText` that `LayrzApp` installs
  /// automatically in debug builds when no caller-supplied `banner` is
  /// provided (see DESIGN-114). Never shown outside `kDebugMode`.
  ///
  /// English default: "DEBUG"
  String get debugBanner => 'DEBUG';
}

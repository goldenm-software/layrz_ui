/// Table Paginator namespace.
abstract mixin class LayrzTableLocalizations {
  /// Localized label for rows per page dropdown.
  String get tableRowsPerPage;

  /// Localized text for first-page navigation button.
  ///
  /// Default: "Start"
  String get tablePaginatorStart;

  /// Localized text for previous-page navigation button.
  String get tablePaginatorPrevious;

  /// Localized text for next-page navigation button.
  String get tablePaginatorNext;

  /// Localized text for last-page navigation button.
  ///
  /// Default: "End"
  String get tablePaginatorEnd;

  /// Localized text showing page range with parameters: start row, end row, total rows.
  ///
  /// Example: "Showing 1 to 10 of 100"
  String tablePaginatorShowing(int start, int end, int total);

  /// Localized compact variant showing displayed count vs total with parameters.
  ///
  /// Example: "10 of 100"
  String tablePaginatorShowingVerySmall(int showing, int total);

  /// Localized text for "Auto" rows-per-page option.
  String get tablePaginatorAuto;
}

/// Table Paginator namespace.
mixin LayrzUiL10nTableMixin {
  /// Localized label for rows per page dropdown.
  String get tableRowsPerPage => 'Rows per page';

  /// Localized text for first-page navigation button.
  ///
  /// Default: "Start"
  String get tablePaginatorStart => 'Start';

  /// Localized text for previous-page navigation button.
  String get tablePaginatorPrevious => 'Previous';

  /// Localized text for next-page navigation button.
  String get tablePaginatorNext => 'Next';

  /// Localized text for last-page navigation button.
  ///
  /// Default: "End"
  String get tablePaginatorEnd => 'End';

  /// Localized text showing page range with parameters: start row, end row, total rows.
  ///
  /// Example: "Showing 1 to 10 of 100"
  String tablePaginatorShowing(int start, int end, int total) => 'Showing $start to $end of $total';

  /// Localized compact variant showing displayed count vs total with parameters.
  ///
  /// Example: "10 of 100"
  String tablePaginatorShowingVerySmall(int showing, int total) => '$showing of $total';

  /// Localized text for "Auto" rows-per-page option.
  String get tablePaginatorAuto => 'Auto';

  /// Localized message shown when a table's dataset is entirely empty (no
  /// rows at all, independent of any search filter).
  ///
  /// Default: "No data to display."
  String get tableEmpty => 'No data to display.';

  /// Localized message shown when a table's dataset is non-empty but the
  /// current search filters every row out.
  ///
  /// Default: "No rows match your search."
  String get tableNoSearchResults => 'No rows match your search.';

  /// Localized accessible name and tooltip for the collapsed row-actions
  /// trigger shown on compact viewports.
  ///
  /// Default: "Actions"
  String get tableActionsHint => 'Actions';

  /// Localized confirmation-toast title shown after a cell's displayed text
  /// is copied to the clipboard.
  ///
  /// Default: "Copied to clipboard"
  String get tableCopiedToClipboard => 'Copied to clipboard';

  /// Localized label for the header context-menu action that sorts a column
  /// in ascending order.
  ///
  /// Default: "Sort ascending"
  String get tableSortAscending => 'Sort ascending';

  /// Localized label for the header context-menu action that sorts a column
  /// in descending order.
  ///
  /// Default: "Sort descending"
  String get tableSortDescending => 'Sort descending';

  /// Localized label for the header context-menu action that clears the
  /// active sort.
  ///
  /// Default: "Clear sort"
  String get tableClearSort => 'Clear sort';

  /// Localized label for the header context-menu action that hides a column.
  ///
  /// Default: "Hide column"
  String get tableHideColumn => 'Hide column';

  /// Localized hint/trigger label for the column-visibility and reorder
  /// menu's trigger button.
  ///
  /// Default: "Columns"
  String get tableColumnsMenu => 'Columns';

  /// Localized label for the column-visibility menu's "Reorder columns"
  /// section heading, shown only on compact viewports.
  ///
  /// Default: "Reorder columns"
  String get tableReorderColumns => 'Reorder columns';

  /// Localized label for the "move column up" reorder action, with the
  /// target column's header text interpolated.
  ///
  /// Example: "Move Name up"
  String tableMoveColumnUp(String columnName) => 'Move $columnName up';

  /// Localized label for the "move column down" reorder action, with the
  /// target column's header text interpolated.
  ///
  /// Example: "Move Name down"
  String tableMoveColumnDown(String columnName) => 'Move $columnName down';
}

import '../contract/table.dart';

/// English default implementations for Table Paginator namespace.
mixin LayrzDefaultTableLocalizations implements LayrzTableLocalizations {
  @override
  String get tableRowsPerPage => 'Rows per page';

  @override
  String get tablePaginatorStart => 'Start';

  @override
  String get tablePaginatorPrevious => 'Previous';

  @override
  String get tablePaginatorNext => 'Next';

  @override
  String get tablePaginatorEnd => 'End';

  @override
  String tablePaginatorShowing(int start, int end, int total) => 'Showing $start to $end of $total';

  @override
  String tablePaginatorShowingVerySmall(int showing, int total) => '$showing of $total';

  @override
  String get tablePaginatorAuto => 'Auto';
}

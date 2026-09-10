import 'package:flutter/widgets.dart' show Key, immutable;

/// Base type for every event emitted on [LayrzTableController.events]
/// (`lib/src/table/src/controller.dart`).
///
/// `LayrzTable`'s controller persists sort, search, column order/visibility
/// and selection state, and reports every mutation of that state as a typed
/// event on a broadcast stream, in addition to the `ChangeNotifier`
/// `notifyListeners()` call it makes for widget rebuilds. Consumers that only
/// need to react to a specific kind of change (e.g. persist the search text,
/// or log selection changes) can `listen` to the stream and `switch` on the
/// concrete subclass, instead of comparing controller snapshots on every
/// `notifyListeners()` call.
///
/// This is a sealed class: the subclass set below (`LayrzTableSortEvent`,
/// `LayrzTableSearchEvent`, `LayrzTableSelectionEvent`, `LayrzTableColumnsEvent`,
/// `LayrzTableRefreshEvent`) is exhaustive, so a `switch` over
/// `LayrzTableEvent<T>` does not need a fallback `default` case.
///
/// The type parameter [T] is the row type of the `LayrzTable<T>` that owns
/// the emitting controller, matching [LayrzTableSelectionEvent]'s payload.
@immutable
sealed class LayrzTableEvent<T> {
  /// Const constructor for subclasses. [LayrzTableEvent] carries no payload
  /// of its own; every field lives on a concrete subclass.
  const LayrzTableEvent();
}

/// Emitted when the controller's sort column or sort direction changes,
/// whether from a header tap, a header context-menu action, or a direct call
/// to `LayrzTableController.sort(...)`.
@immutable
final class LayrzTableSortEvent<T> extends LayrzTableEvent<T> {
  /// Creates a sort-changed event.
  const LayrzTableSortEvent({required this.columnKey, required this.ascending});

  /// The [Key] of the column the table is now sorted by (the same `Key`
  /// supplied to that column's `LayrzColumn.key`). `null` means sorting was
  /// cleared and the table has returned to its unsorted (input) order.
  final Key? columnKey;

  /// Whether the sort is ascending (`true`) or descending (`false`). Its
  /// value is meaningless when [columnKey] is `null`, since no sort is
  /// active in that case.
  final bool ascending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayrzTableSortEvent<T> && other.columnKey == columnKey && other.ascending == ascending);

  @override
  int get hashCode => Object.hash(columnKey, ascending);

  @override
  String toString() => 'LayrzTableSortEvent(columnKey: $columnKey, ascending: $ascending)';
}

/// Emitted when the controller's search text changes, e.g. from a keystroke
/// in the table's search field or a direct call to
/// `LayrzTableController.search(...)`.
@immutable
final class LayrzTableSearchEvent<T> extends LayrzTableEvent<T> {
  /// Creates a search-changed event.
  const LayrzTableSearchEvent({required this.searchText});

  /// The new search text the table now filters rows by. An empty string
  /// means the search filter was cleared.
  final String searchText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LayrzTableSearchEvent<T> && other.searchText == searchText);

  @override
  int get hashCode => searchText.hashCode;

  @override
  String toString() => 'LayrzTableSearchEvent(searchText: $searchText)';
}

/// Emitted when the controller's multi-selection changes, e.g. from a row
/// checkbox toggle, the header "select all" checkbox, a "clear selection"
/// action, or a direct call to one of the controller's selection mutators.
@immutable
final class LayrzTableSelectionEvent<T> extends LayrzTableEvent<T> {
  /// Creates a selection-changed event.
  const LayrzTableSelectionEvent({required this.selection});

  /// The full set of currently-selected rows, of the table's row type [T],
  /// after the change that triggered this event. An empty set means nothing
  /// is selected.
  final Set<T> selection;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LayrzTableSelectionEvent<T>) return false;
    if (other.selection.length != selection.length) return false;
    return other.selection.containsAll(selection);
  }

  @override
  int get hashCode => Object.hashAllUnordered(selection);

  @override
  String toString() => 'LayrzTableSelectionEvent(selection: $selection)';
}

/// Emitted when the controller's column configuration changes — either the
/// set of visible columns or their order — e.g. from the visibility menu, a
/// header drag-to-reorder, or a direct call to `toggleColumn`/
/// `setColumnVisible`/`reorderColumn`.
///
/// Visibility and order are reported together in one event because a single
/// user action (like re-showing a hidden column, which restores its prior
/// order slot) can change both at once; consumers that only care about one
/// aspect can compare [hiddenColumns] against their own last-seen value.
///
/// This payload deliberately mirrors `LayrzTableController`'s own
/// constructor shape (`columnOrder` + `hiddenColumns`, not
/// `visibleColumnKeys`), so a listener reasons about a received event in the
/// same terms the controller itself was seeded with — including being able
/// to feed an event's payload straight into a new controller's constructor,
/// or into [LayrzTableController.setColumnOrder]/
/// [LayrzTableController.setHiddenColumns].
@immutable
final class LayrzTableColumnsEvent<T> extends LayrzTableEvent<T> {
  /// Creates a columns-changed event.
  const LayrzTableColumnsEvent({required this.columnOrder, required this.hiddenColumns});

  /// Every known column's [Key], in the controller's current display order
  /// (hidden columns keep their slot in this list so re-showing them
  /// restores their last position).
  final List<Key> columnOrder;

  /// The subset of [columnOrder] that is currently hidden.
  ///
  /// A column [Key] present in [columnOrder] but absent from this set is
  /// currently visible.
  final Set<Key> hiddenColumns;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LayrzTableColumnsEvent<T>) return false;
    if (other.columnOrder.length != columnOrder.length) return false;
    for (var i = 0; i < columnOrder.length; i++) {
      if (other.columnOrder[i] != columnOrder[i]) return false;
    }
    if (other.hiddenColumns.length != hiddenColumns.length) return false;
    return other.hiddenColumns.containsAll(hiddenColumns);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(columnOrder), Object.hashAllUnordered(hiddenColumns));

  @override
  String toString() => 'LayrzTableColumnsEvent(columnOrder: $columnOrder, hiddenColumns: $hiddenColumns)';
}

/// Emitted when the table is asked to refresh, e.g. from a direct call to
/// `LayrzTableController.refresh()`. Carries no payload — it is a signal
/// that consumers should treat the current data as needing a re-render or
/// re-fetch, not a report of what changed.
@immutable
final class LayrzTableRefreshEvent<T> extends LayrzTableEvent<T> {
  /// Creates a refresh event.
  const LayrzTableRefreshEvent();

  @override
  bool operator ==(Object other) => identical(this, other) || other is LayrzTableRefreshEvent<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'LayrzTableRefreshEvent()';
}

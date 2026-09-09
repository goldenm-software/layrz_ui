import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/events.dart';

/// Owns and persists all interactive state for a `LayrzTable<T>`: column
/// order and visibility, search text, sort column and direction, and
/// multi-row selection.
///
/// A [LayrzTableController] is the recommended way to keep a table's sort,
/// search, and column configuration alive across rebuilds — state that a
/// bare `StatefulWidget` would otherwise lose whenever the table (or its
/// ancestor) rebuilds or remounts. It follows the same `ChangeNotifier`
/// shape as the repo's other stateful controllers (e.g. `LayrzButtonController`):
/// every mutator updates the controller's fields and calls
/// [notifyListeners], so widgets that `listen` to the controller rebuild
/// automatically.
///
/// In addition to `ChangeNotifier` semantics, every mutation is also
/// reported as a typed [LayrzTableEvent] on [events], a broadcast stream.
/// This lets a consumer react to a *specific kind* of change (persist the
/// search text, log a selection change, ...) without diffing controller
/// snapshots on every [notifyListeners] call.
///
/// **Persistence** is in-memory only, for the lifetime of the controller
/// instance. There is no `toJson`/`fromJson` — state does not survive past
/// disposal, and is not meant to.
///
/// **Lifecycle**: like every controller in this design system, disposal is
/// caller-owned. If `LayrzTable` is given an external controller, the table
/// never disposes it; the caller must call [dispose] itself (e.g. from a
/// `State.dispose()`). If `LayrzTable` creates its own internal controller
/// because none was supplied, the table disposes that internal instance
/// when it unmounts.
class LayrzTableController<T> extends ChangeNotifier {
  /// Creates a [LayrzTableController].
  ///
  /// [columnOrder] seeds the controller's known column set and initial
  /// display order; pass the [Key]s of the [LayrzColumn]s the table starts
  /// with, in the order they should first render. Defaults to an empty
  /// list, meaning the table should call [syncColumns] once its columns are
  /// known (this is what `LayrzTable` does internally).
  ///
  /// [hiddenColumns] optionally seeds the set of column [Key]s that start
  /// hidden. Every key here must also appear in [columnOrder]; defaults to
  /// no columns hidden.
  ///
  /// [minVisibleColumns] sets the floor described on [minVisibleColumns] —
  /// defaults to `1` and must be at least `1`.
  LayrzTableController({
    List<Key> columnOrder = const [],
    Set<Key> hiddenColumns = const {},
    this.minVisibleColumns = 1,
  }) : assert(minVisibleColumns >= 1, 'minVisibleColumns must be at least 1'),
       _columnOrder = List<Key>.of(columnOrder),
       _hiddenColumns = Set<Key>.of(hiddenColumns);

  /// The minimum number of columns that must remain visible at all times.
  ///
  /// Defaults to `1`. Any mutation that would drop the number of visible
  /// columns strictly below this floor — [setColumnVisible] hiding a column,
  /// or [toggleColumn] toggling a visible column off — is refused: it is a
  /// no-op that does **not** call [notifyListeners] and does **not** emit a
  /// [LayrzTableColumnsEvent]. This is a backstop; the built-in
  /// column-management UI is expected to disable the offending toggle
  /// before the user can even attempt it, but the controller enforces the
  /// invariant regardless of caller.
  final int minVisibleColumns;

  /// Every known column's [Key], in the controller's current display order.
  ///
  /// This list includes hidden columns — hiding a column never removes its
  /// entry here, only adds it to [hiddenColumns]. Keeping hidden columns in
  /// [columnOrder] is what lets [setColumnVisible] restore a re-shown
  /// column to its previous slot instead of appending it to the end.
  final List<Key> _columnOrder;

  /// The set of column [Key]s that are currently hidden.
  ///
  /// A key present in [columnOrder] but absent from this set is visible.
  final Set<Key> _hiddenColumns;

  /// The current search text used to filter rows.
  ///
  /// An empty string (the default) means no search filter is applied.
  String _searchText = '';

  /// The [Key] of the column the table is currently sorted by, or `null` if
  /// no sort is active.
  Key? _sortColumnKey;

  /// Whether the active sort is ascending. Meaningless while
  /// [sortColumnKey] is `null`.
  bool _sortAscending = true;

  /// The set of currently-selected rows, of the table's row type [T].
  final Set<T> _selection = <T>{};

  /// The broadcast stream controller backing [events]. Created eagerly so
  /// [events] is always listenable, and closed in [dispose].
  final StreamController<LayrzTableEvent<T>> _eventsController = StreamController<LayrzTableEvent<T>>.broadcast();

  /// Every known column's [Key], in the controller's current display order.
  ///
  /// Includes hidden columns — see [hiddenColumns] for which of these are
  /// currently visible. This is the list a header/menu should iterate to
  /// render columns (or their toggles) in order.
  List<Key> get columnOrder => List<Key>.unmodifiable(_columnOrder);

  /// The set of column [Key]s that are currently hidden.
  ///
  /// A key in [columnOrder] but not in this set is visible.
  Set<Key> get hiddenColumns => Set<Key>.unmodifiable(_hiddenColumns);

  /// The subset of [columnOrder] that is currently visible, in the same
  /// relative order.
  Set<Key> get visibleColumnKeys => _columnOrder.where((key) => !_hiddenColumns.contains(key)).toSet();

  /// The current search text used to filter rows. Empty means unfiltered.
  String get searchText => _searchText;

  /// The [Key] of the column currently sorted by, or `null` if unsorted.
  Key? get sortColumnKey => _sortColumnKey;

  /// Whether the active sort is ascending (`true`) or descending (`false`).
  ///
  /// Meaningless while [sortColumnKey] is `null`.
  bool get sortAscending => _sortAscending;

  /// The current set of selected rows, of the table's row type [T].
  Set<T> get selection => Set<T>.unmodifiable(_selection);

  /// A broadcast stream of every state change this controller makes.
  ///
  /// Each mutator that changes state emits exactly one matching event here
  /// in addition to calling [notifyListeners] — e.g. [sort] and
  /// [clearSort] emit [LayrzTableSortEvent], [search] emits
  /// [LayrzTableSearchEvent], the selection mutators emit
  /// [LayrzTableSelectionEvent], the column mutators emit
  /// [LayrzTableColumnsEvent], and [refresh] emits
  /// [LayrzTableRefreshEvent]. A mutation refused by the [minVisibleColumns]
  /// guard emits nothing. The stream is closed in [dispose]; do not listen
  /// to it after the controller is disposed.
  Stream<LayrzTableEvent<T>> get events => _eventsController.stream;

  /// Sorts the table by the column identified by [columnKey], in the
  /// direction given by [ascending].
  ///
  /// Updates [sortColumnKey] and [sortAscending], calls [notifyListeners],
  /// and emits a [LayrzTableSortEvent] on [events].
  void sort(Key columnKey, bool ascending) {
    _sortColumnKey = columnKey;
    _sortAscending = ascending;
    notifyListeners();
    _eventsController.add(LayrzTableSortEvent<T>(columnKey: columnKey, ascending: ascending));
  }

  /// Clears the active sort, returning the table to its unsorted (input)
  /// order.
  ///
  /// Sets [sortColumnKey] to `null`, calls [notifyListeners], and emits a
  /// [LayrzTableSortEvent] with a `null` `columnKey` on [events].
  void clearSort() {
    _sortColumnKey = null;
    _sortAscending = true;
    notifyListeners();
    _eventsController.add(LayrzTableSortEvent<T>(columnKey: null, ascending: _sortAscending));
  }

  /// Sets the search text the table filters rows by.
  ///
  /// [text] replaces [searchText] verbatim (no trimming or normalization).
  /// Calls [notifyListeners] and emits a [LayrzTableSearchEvent] on
  /// [events]. Pass an empty string to clear the filter.
  void search(String text) {
    _searchText = text;
    notifyListeners();
    _eventsController.add(LayrzTableSearchEvent<T>(searchText: text));
  }

  /// Sets whether the column identified by [key] is visible.
  ///
  /// If [visible] is `true` and [key] is not yet known, it is appended to
  /// the end of [columnOrder] before being marked visible. If [key] was
  /// previously hidden, showing it again restores its existing slot in
  /// [columnOrder] rather than moving it — hiding never removes a column's
  /// order entry.
  ///
  /// If [visible] is `false`, hiding [key] is refused as a no-op (no state
  /// change, no [notifyListeners], no emitted event) when doing so would
  /// drop the number of currently-visible columns below [minVisibleColumns].
  /// Otherwise the column is hidden, [notifyListeners] is called, and a
  /// [LayrzTableColumnsEvent] is emitted on [events].
  void setColumnVisible(Key key, bool visible) {
    if (visible) {
      if (!_columnOrder.contains(key)) {
        _columnOrder.add(key);
      }
      if (!_hiddenColumns.remove(key)) {
        // Was already visible (or newly added and already visible by
        // default) — nothing changed, so don't notify.
        return;
      }
    } else {
      if (!_columnOrder.contains(key) || _hiddenColumns.contains(key)) {
        // Unknown column, or already hidden — nothing changed.
        return;
      }
      final currentlyVisible = _columnOrder.length - _hiddenColumns.length;
      if (currentlyVisible - 1 < minVisibleColumns) {
        // Refused: would drop below the visible-columns floor.
        return;
      }
      _hiddenColumns.add(key);
    }
    notifyListeners();
    _eventsController.add(LayrzTableColumnsEvent<T>(columnOrder: columnOrder, visibleColumnKeys: visibleColumnKeys));
  }

  /// Toggles the visibility of the column identified by [key].
  ///
  /// Equivalent to calling [setColumnVisible] with the opposite of the
  /// column's current visibility. If [key] is unknown, this is a no-op — an
  /// unknown column has no visibility to toggle. If toggling a visible
  /// column off would drop below [minVisibleColumns], the toggle is refused
  /// (see [setColumnVisible]).
  void toggleColumn(Key key) {
    if (!_columnOrder.contains(key)) return;
    setColumnVisible(key, _hiddenColumns.contains(key));
  }

  /// Moves the **visible** column identified by [key] to [targetVisibleIndex]
  /// among the currently-visible columns.
  ///
  /// [targetVisibleIndex] is a position within [visibleColumnKeys] (in its
  /// current relative order) — **not** a position in the full [columnOrder]
  /// — clamped to `[0, visibleColumnKeys.length - 1]`. This is the
  /// programmatic reorder entrypoint driven by both the header
  /// drag-to-reorder gesture and the column-management menu's up/down
  /// controls; both operate purely on what the user can see, so they think
  /// in visible positions, not full-list positions.
  ///
  /// [key] must currently be **visible**: if it is hidden or unknown, this
  /// is a no-op — hidden columns have no drag handle and no reorderable
  /// menu row, so there is no visible position to move them to. If
  /// [targetVisibleIndex] (after clamping) is [key]'s current visible
  /// index, this is also a no-op. In either no-op case: no state change, no
  /// [notifyListeners], no emitted event.
  ///
  /// **Hidden columns' stored positions are not perturbed.** Reordering
  /// only changes the relative order of visible columns; every hidden
  /// column stays anchored immediately after the same visible column it
  /// followed before the move (or, if it preceded every visible column,
  /// it stays before the new first visible column). Concretely: before
  /// moving, each hidden key is recorded as anchored to the nearest
  /// visible key at or before it in [columnOrder] (or to "start" if none
  /// precedes it). After computing the new visible order, the full
  /// [columnOrder] is rebuilt by walking that new visible order and
  /// re-inserting each hidden key immediately after its anchor (or before
  /// the first visible key, for "start"-anchored hidden keys), preserving
  /// the relative order hidden keys sharing the same anchor had before.
  ///
  /// On success, [notifyListeners] is called and a [LayrzTableColumnsEvent]
  /// is emitted on [events] carrying the rebuilt [columnOrder] and the
  /// (unchanged, but reordered) [visibleColumnKeys].
  void reorderColumn(Key key, int targetVisibleIndex) {
    if (_hiddenColumns.contains(key) || !_columnOrder.contains(key)) return;

    final visibleKeys = _columnOrder.where((k) => !_hiddenColumns.contains(k)).toList(growable: false);
    final currentVisibleIndex = visibleKeys.indexOf(key);
    final clampedTarget = targetVisibleIndex.clamp(0, visibleKeys.length - 1);
    if (clampedTarget == currentVisibleIndex) return;

    // Anchor each hidden key to the nearest preceding visible key in the
    // CURRENT order (null means "before every visible column").
    final anchors = <Key?, List<Key>>{};
    Key? lastVisibleSeen;
    for (final k in _columnOrder) {
      if (_hiddenColumns.contains(k)) {
        anchors.putIfAbsent(lastVisibleSeen, () => []).add(k);
      } else {
        lastVisibleSeen = k;
      }
    }

    // Compute the new visible order.
    final newVisibleOrder = List<Key>.of(visibleKeys)
      ..removeAt(currentVisibleIndex)
      ..insert(clampedTarget, key);

    // Rebuild the full order: hidden keys anchored to "start" first, then
    // each visible key followed immediately by the hidden keys anchored to it.
    final rebuilt = <Key>[
      ...anchors[null] ?? const [],
    ];
    for (final visibleKey in newVisibleOrder) {
      rebuilt.add(visibleKey);
      rebuilt.addAll(anchors[visibleKey] ?? const []);
    }

    _columnOrder
      ..clear()
      ..addAll(rebuilt);
    notifyListeners();
    _eventsController.add(LayrzTableColumnsEvent<T>(columnOrder: columnOrder, visibleColumnKeys: visibleColumnKeys));
  }

  /// Reconciles the controller's known column set against the [columns]
  /// currently supplied by the table, by pure [Key] set arithmetic.
  ///
  /// Call this whenever the table's column list may have changed shape
  /// between rebuilds (columns added or removed). This is **not** a
  /// positional reconcile — it never reasons about index shifts, only about
  /// key membership:
  /// - Any stored [columnOrder]/[hiddenColumns] entry whose [Key] is no
  ///   longer present in [columns] is dropped.
  /// - Any [Key] in [columns] not yet known to the controller is appended
  ///   to the end of [columnOrder], in the order it appears in [columns],
  ///   and starts visible.
  ///
  /// If dropping stale keys would leave fewer than [minVisibleColumns]
  /// columns visible among the *remaining known* keys, newly-appended keys
  /// are used to backfill visibility (in declaration order) until the floor
  /// is met or no new keys remain — this mirrors the guard in
  /// [setColumnVisible], applied here as a repair rather than a refusal,
  /// since a caller-driven column-set change is not a user toggle to
  /// refuse.
  ///
  /// If the resulting order and visible set are identical to the current
  /// ones (no columns actually added or removed), this is a no-op: no
  /// [notifyListeners] call, no emitted event.
  void syncColumns(List<LayrzColumn<T>> columns) {
    final currentKeys = columns.map((column) => column.key).toList(growable: false);
    final currentKeySet = currentKeys.toSet();

    final staleKeys = _columnOrder.where((key) => !currentKeySet.contains(key)).toList(growable: false);
    final newKeys = currentKeys.where((key) => !_columnOrder.contains(key)).toList(growable: false);

    if (staleKeys.isEmpty && newKeys.isEmpty) {
      // Membership is already in sync — nothing to do.
      return;
    }

    for (final key in staleKeys) {
      _columnOrder.remove(key);
      _hiddenColumns.remove(key);
    }
    _columnOrder.addAll(newKeys);

    // Backfill visibility if dropping stale keys left too few visible.
    var currentlyVisible = _columnOrder.length - _hiddenColumns.length;
    for (final key in newKeys) {
      if (currentlyVisible >= minVisibleColumns) break;
      if (_hiddenColumns.remove(key)) {
        currentlyVisible++;
      }
    }

    notifyListeners();
    _eventsController.add(LayrzTableColumnsEvent<T>(columnOrder: columnOrder, visibleColumnKeys: visibleColumnKeys));
  }

  /// Adds [item] to the current selection.
  ///
  /// If [item] is already selected, this is a no-op. Otherwise
  /// [notifyListeners] is called and a [LayrzTableSelectionEvent] is
  /// emitted on [events].
  void selectItem(T item) {
    if (!_selection.add(item)) return;
    notifyListeners();
    _eventsController.add(LayrzTableSelectionEvent<T>(selection: selection));
  }

  /// Removes [item] from the current selection.
  ///
  /// If [item] is not selected, this is a no-op. Otherwise
  /// [notifyListeners] is called and a [LayrzTableSelectionEvent] is
  /// emitted on [events].
  void deselectItem(T item) {
    if (!_selection.remove(item)) return;
    notifyListeners();
    _eventsController.add(LayrzTableSelectionEvent<T>(selection: selection));
  }

  /// Toggles whether [item] is selected.
  ///
  /// Equivalent to calling [deselectItem] if [item] is currently selected,
  /// or [selectItem] otherwise.
  void toggleSelection(T item) {
    if (_selection.contains(item)) {
      deselectItem(item);
    } else {
      selectItem(item);
    }
  }

  /// Replaces the current selection with every item in [items].
  ///
  /// Typically driven by a header "select all" checkbox over the table's
  /// currently filtered/visible rows. If the resulting selection is
  /// identical to the current one, this is a no-op. Otherwise
  /// [notifyListeners] is called and a [LayrzTableSelectionEvent] is
  /// emitted on [events].
  void selectAll(Iterable<T> items) {
    final next = Set<T>.of(items);
    if (next.length == _selection.length && _selection.containsAll(next)) return;
    _selection
      ..clear()
      ..addAll(next);
    notifyListeners();
    _eventsController.add(LayrzTableSelectionEvent<T>(selection: selection));
  }

  /// Clears the current selection.
  ///
  /// If nothing is selected, this is a no-op. Otherwise [notifyListeners]
  /// is called and a [LayrzTableSelectionEvent] is emitted on [events] with
  /// an empty [Set].
  void clearSelection() {
    if (_selection.isEmpty) return;
    _selection.clear();
    notifyListeners();
    _eventsController.add(LayrzTableSelectionEvent<T>(selection: selection));
  }

  /// Signals that the table should refresh, e.g. re-fetch or re-render its
  /// current data.
  ///
  /// Carries no state change of its own: always calls [notifyListeners] and
  /// emits a [LayrzTableRefreshEvent] on [events].
  void refresh() {
    notifyListeners();
    _eventsController.add(LayrzTableRefreshEvent<T>());
  }

  @override
  void dispose() {
    _eventsController.close();
    super.dispose();
  }
}

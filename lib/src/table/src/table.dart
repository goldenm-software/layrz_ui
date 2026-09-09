import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/progress/progress.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/controller.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/table/src/sort.dart';
import 'package:layrz_ui/src/table/src/table_action.dart';
import 'package:layrz_ui/src/table/src/table_header.dart';
import 'package:layrz_ui/src/table/src/table_row.dart';

/// A generic, virtualized, Material-free data table.
///
/// [LayrzTable] renders [items] across [columns], with sorting, search,
/// optional multiselect, and per-row actions. It has **no paginator** — the
/// whole (filtered/sorted) dataset is rendered through a single virtualized
/// vertical `ListView.builder` of [LayrzTableRow]s, below one frozen
/// [LayrzTableHeader]. Both share one [LayrzTableRowScrollSync] instance so
/// their scrolling-middle regions (the data columns) stay pixel-aligned and
/// move together, while each row's pinned-left checkbox and pinned-right
/// actions cells stay fixed at the row's own edges.
///
/// **State**: sort column/direction, search text, column order/visibility,
/// and multi-selection all live on a [LayrzTableController]. Pass one via
/// [controller] to read or drive that state from outside the table (e.g. to
/// persist it across a rebuild higher up the tree, or to render your own
/// column-management UI in addition to the built-in one). When [controller]
/// is omitted, [LayrzTable] creates and owns an internal controller for its
/// own lifetime, disposing it when the table is removed from the tree —
/// external controllers are never disposed by the table.
///
/// **Column identity**: every [LayrzColumn] carries a required, caller-unique
/// [LayrzColumn.key]. On first build, and again whenever [columns] changes
/// shape between rebuilds, the table calls [LayrzTableController.syncColumns]
/// so the controller's stored order/visibility stays in step with the
/// current column set (see that method's own doc for the membership-sync
/// rules).
///
/// **Filtering and sorting**: on every rebuild driven by a data or controller
/// change, the table precomputes each visible column's display string for
/// every item (a cache parallel to [items]), filters by
/// [LayrzTableController.searchText] (case-insensitive `contains` across the
/// currently-visible columns' precomputed strings), and — when a sort column
/// is active — precomputes that column's sort keys and sorts the filtered
/// list off the UI thread via [sortTableItemsOffThread]. The resulting
/// filtered+sorted count is reported through [onFilteredCountChanged]
/// whenever it changes.
///
/// **Column widths**: computed once per [LayoutBuilder] pass from the
/// available width — fixed-width columns ([LayrzColumn.width] non-null) keep
/// their own width; the remaining space is split evenly among flex columns
/// ([LayrzColumn.width] null), floored at [minColumnWidth]. The same
/// resolved widths are handed to [LayrzTableHeader] (as a `Map<Key, double>`)
/// and to every [LayrzTableRow] (as a parallel `List<double>`, in the same
/// order as that row's visible columns), so header and body columns always
/// agree pixel-for-pixel.
class LayrzTable<T> extends StatefulWidget {
  /// The rows to render, before filtering and sorting.
  final List<T> items;

  /// The full set of columns this table can render.
  ///
  /// Actual rendered order and visibility are driven by [controller] (or the
  /// table's internal controller), not by this list's own order — [columns]
  /// is the lookup table [LayrzTableController] resolves its stored [Key]s
  /// against. Every [LayrzColumn.key] must be unique within this list.
  final List<LayrzColumn<T>> columns;

  /// The controller holding this table's sort, search, column, and selection
  /// state.
  ///
  /// When `null`, the table creates and owns an internal
  /// [LayrzTableController], disposing it when the table unmounts. When
  /// non-`null`, the caller owns disposal — the table never disposes an
  /// externally-supplied controller.
  final LayrzTableController<T>? controller;

  /// Builds the row-level actions rendered in the trailing pinned-right cell
  /// for a given item.
  ///
  /// When `null`, no row renders a pinned-right actions cell at all.
  final List<LayrzTableAction> Function(T item)? actionsBuilder;

  /// Whether rows render a pinned-left multiselect checkbox cell.
  ///
  /// Defaults to `false` (opt-in) — unlike the `layrz_theme` baseline, which
  /// defaulted to `true` while also asserting at least one multiselect action
  /// was supplied. When `true`, tapping a row's checkbox toggles its
  /// selection via the controller.
  final bool hasMultiselect;

  /// Whether the table renders a search field above the header.
  ///
  /// Defaults to `true`. When `false`, no search field is rendered and the
  /// controller's [LayrzTableController.searchText] (if ever set
  /// programmatically) still applies as a filter.
  final bool canSearch;

  /// The minimum width, in logical pixels, a flex column (one with a `null`
  /// [LayrzColumn.width]) may be laid out at.
  ///
  /// Must be greater than `0`. Defaults to `150`.
  final double minColumnWidth;

  /// The fixed height, in logical pixels, of every data row.
  ///
  /// Defaults to `50`.
  final double height;

  /// The fixed height, in logical pixels, of the frozen header row.
  ///
  /// Defaults to `40`.
  final double headerHeight;

  /// The message shown when [items] is empty (no rows at all, independent of
  /// any search filter).
  ///
  /// When `null`, a house default string is used.
  final String? emptyText;

  /// The message shown when [items] is non-empty but the current search
  /// filters every row out.
  ///
  /// When `null`, a house default string is used, distinct from [emptyText]
  /// so a caller can tell a truly-empty dataset apart from a search with no
  /// matches.
  final String? emptySearchText;

  /// The label shown alongside the loading indicator while [isLoading] is
  /// `true`.
  ///
  /// When `null`, a house default string is used.
  final String? loadingLabelText;

  /// The confirmation-toast title shown after a cell's displayed text is
  /// copied to the clipboard (the default tap behavior for a column without
  /// its own [LayrzColumn.onTap]).
  ///
  /// When `null`, [LayrzTableRow] applies its own house default. Forwarded
  /// verbatim to every [LayrzTableRow].
  final String? copyToClipboardText;

  /// Called whenever the filtered+sorted row count changes.
  ///
  /// Invoked with the number of rows currently passing the active search
  /// filter, after every filter/sort recomputation whose resulting count
  /// differs from the last one reported. `null` by default (no callback).
  final void Function(int count)? onFilteredCountChanged;

  /// Whether the table is in a caller-driven loading state.
  ///
  /// When `true`, the table renders a centered progress indicator and
  /// [loadingLabelText] instead of the header/body, regardless of [items].
  /// Defaults to `false`.
  final bool isLoading;

  /// Creates a [LayrzTable].
  ///
  /// [items] and [columns] are required. [columns] must be non-empty, and
  /// every [LayrzColumn.key] in it must be unique. [minColumnWidth] must be
  /// greater than `0`.
  LayrzTable({
    required this.items,
    required this.columns,
    this.controller,
    this.actionsBuilder,
    this.hasMultiselect = false,
    this.canSearch = true,
    this.minColumnWidth = 150,
    this.height = 50,
    this.headerHeight = 40,
    this.emptyText,
    this.emptySearchText,
    this.loadingLabelText,
    this.copyToClipboardText,
    this.onFilteredCountChanged,
    this.isLoading = false,
    super.key,
  }) : assert(columns.isNotEmpty, 'columns must not be empty'),
       assert(minColumnWidth > 0, 'minColumnWidth must be greater than 0'),
       assert(
         columns.map((column) => column.key).toSet().length == columns.length,
         'every LayrzColumn.key must be unique within columns',
       );

  @override
  State<LayrzTable<T>> createState() => _LayrzTableState<T>();
}

class _LayrzTableState<T> extends State<LayrzTable<T>> {
  late LayrzTableController<T> _controller;
  bool _ownsController = false;

  final LayrzTableRowScrollSync _scrollSync = LayrzTableRowScrollSync();

  List<T> _displayedItems = const [];
  int? _lastReportedCount;
  bool _isComputing = false;

  /// `true` while the very first [_recompute] (the one kicked off from
  /// [initState]) has not yet reported through
  /// [LayrzTable.onFilteredCountChanged]. That first recompute runs
  /// synchronously up to its first `await` — which never executes when no
  /// sort column is active — so it can finish, and therefore try to notify,
  /// while this widget's owner is still inside its own `build()`. Notifying
  /// synchronously at that point calls the consumer's callback mid-build; if
  /// that callback calls `setState` (the obvious, expected thing to do with
  /// a "count changed" notification) Flutter throws "setState() or
  /// markNeedsBuild() called during build". So the first notification is
  /// deferred to a post-frame callback instead of being dropped.
  bool _pendingInitialNotify = true;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _recompute();
  }

  @override
  void didUpdateWidget(covariant LayrzTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _detachController();
      _attachController(widget.controller);
    }

    if (!identical(widget.columns, oldWidget.columns) || widget.columns.length != oldWidget.columns.length) {
      _controller.syncColumns(widget.columns);
    }

    if (!identical(widget.items, oldWidget.items) ||
        !identical(widget.columns, oldWidget.columns) ||
        widget.canSearch != oldWidget.canSearch) {
      _recompute();
    }
  }

  /// Wires [controller] (or a freshly-created internal one when `null`) as
  /// this table's active controller: syncs it against [LayrzTable.columns],
  /// attaches [_onControllerChanged], and records [_ownsController] so
  /// [dispose] disposes only a controller this state created itself.
  void _attachController(LayrzTableController<T>? controller) {
    if (controller != null) {
      _controller = controller;
      _ownsController = false;
    } else {
      _controller = LayrzTableController<T>();
      _ownsController = true;
    }
    _controller.syncColumns(widget.columns);
    _controller.addListener(_onControllerChanged);
  }

  /// Detaches [_onControllerChanged] from the current controller, and
  /// disposes it if this state owns it (see [_attachController]).
  void _detachController() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  /// Re-runs the filter/sort pipeline whenever the controller notifies —
  /// covers search text, sort column/direction, and column visibility/order
  /// changes (which can change which columns participate in the search).
  void _onControllerChanged() {
    _recompute();
  }

  /// Runs the filter → sort pipeline for the current [LayrzTable.items],
  /// [LayrzTable.columns], and controller state, then updates
  /// [_displayedItems] and reports [LayrzTable.onFilteredCountChanged] if the
  /// resulting count changed.
  ///
  /// Precomputes each row's display string per currently-visible column on
  /// the main thread (so `LayrzColumn.valueBuilder` never itself crosses the
  /// isolate boundary), applies the case-insensitive search filter, then —
  /// only when a sort column is active — precomputes that column's sort keys
  /// and sorts off the UI thread via [sortTableItemsOffThread].
  Future<void> _recompute() async {
    final items = widget.items;
    final columns = widget.columns;
    final visibleKeys = _controller.visibleColumnKeys;
    final visibleColumns = columns.where((column) => visibleKeys.contains(column.key)).toList(growable: false);

    final searchText = _controller.searchText.trim().toLowerCase();
    List<T> filtered;
    if (searchText.isEmpty) {
      filtered = List<T>.of(items);
    } else {
      filtered = [
        for (final item in items)
          if (visibleColumns.any((column) => column.valueBuilder(item).toLowerCase().contains(searchText))) item,
      ];
    }

    final sortColumnKey = _controller.sortColumnKey;
    if (sortColumnKey != null) {
      final sortColumn = columns.where((column) => column.key == sortColumnKey).firstOrNull;
      if (sortColumn != null) {
        final ascending = _controller.sortAscending;
        final customSort = sortColumn.customSort;
        final sortKeys = customSort == null
            ? [for (final item in filtered) sortColumn.valueBuilder(item)]
            : const <String>[];

        setState(() => _isComputing = true);
        try {
          filtered = await sortTableItemsOffThread<T>(
            SortParams<T>(items: filtered, sortKeys: sortKeys, ascending: ascending, customSort: customSort),
          );
        } finally {
          if (mounted) setState(() => _isComputing = false);
        }
      }
    }

    if (!mounted) return;
    setState(() => _displayedItems = filtered);

    if (_lastReportedCount != filtered.length) {
      _lastReportedCount = filtered.length;
      _notifyFilteredCountChanged(filtered.length);
    }
  }

  /// Reports [count] through [LayrzTable.onFilteredCountChanged], deferring
  /// the very first report (the one produced by the [initState]-triggered
  /// recompute) to a post-frame callback so it never runs while this
  /// widget's owner is mid-`build()` — see [_pendingInitialNotify]. Every
  /// later report (search, sort, or item/column changes triggered from
  /// outside the build phase) is delivered synchronously as before. Guards
  /// against notifying after [dispose] in both paths.
  void _notifyFilteredCountChanged(int count) {
    if (_pendingInitialNotify) {
      _pendingInitialNotify = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFilteredCountChanged?.call(count);
      });
      return;
    }
    widget.onFilteredCountChanged?.call(count);
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  /// Resolves the ordered, currently-visible [LayrzColumn] list from
  /// [_controller], looked up against [LayrzTable.columns].
  List<LayrzColumn<T>> _visibleColumns() {
    final visibleKeys = _controller.visibleColumnKeys;
    final columnsByKey = HashMap<Key, LayrzColumn<T>>.fromIterable(
      widget.columns,
      key: (column) => (column as LayrzColumn<T>).key,
    );
    return [
      for (final key in _controller.columnOrder)
        if (visibleKeys.contains(key)) ?columnsByKey[key],
    ];
  }

  /// Computes each visible column's resolved width for the given
  /// [availableWidth], per the fixed/flex rule documented on [LayrzTable].
  ///
  /// Returns a `List<double>` parallel to [visibleColumns], which callers use
  /// both to build the `Map<Key, double>` handed to [LayrzTableHeader] and as
  /// the per-row `List<double>` handed to every [LayrzTableRow].
  List<double> _resolveColumnWidths(List<LayrzColumn<T>> visibleColumns, double availableWidth) {
    var fixedTotal = 0.0;
    var flexCount = 0;
    for (final column in visibleColumns) {
      final width = column.width;
      if (width != null) {
        fixedTotal += width;
      } else {
        flexCount++;
      }
    }

    final remaining = availableWidth - fixedTotal;
    final flexWidth = flexCount == 0
        ? widget.minColumnWidth
        : (remaining / flexCount).clamp(widget.minColumnWidth, double.infinity);

    return [for (final column in visibleColumns) column.width ?? flexWidth];
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSearchMiss}) {
    final tokens = context.tokens;
    final text = isSearchMiss
        ? (widget.emptySearchText ?? 'No rows match your search.')
        : (widget.emptyText ?? 'No data to display.');
    return Padding(
      padding: tokens.spacing.pd3,
      child: Text(text, style: tokens.typography.label),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: tokens.spacing.pd3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LayrzProgressBar(format: LayrzProgressFormat.circular, semanticLabel: 'Loading table data'),
            SizedBox(height: tokens.spacing.sp2),
            Text(widget.loadingLabelText ?? 'Computing data, please wait...', style: tokens.typography.label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.canSearch)
          Padding(
            padding: EdgeInsets.only(bottom: context.tokens.spacing.sp2),
            child: LayrzSearchInput(value: _controller.searchText, onSearch: _controller.search),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final visibleColumns = _visibleColumns();
              final widths = _resolveColumnWidths(visibleColumns, constraints.maxWidth);
              final columnWidths = <Key, double>{
                for (var i = 0; i < visibleColumns.length; i++) visibleColumns[i].key: widths[i],
              };

              final items = _displayedItems;
              final isEmpty = items.isEmpty;
              final isSearchMiss = isEmpty && widget.items.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayrzTableHeader<T>(
                    columns: widget.columns,
                    controller: _controller,
                    columnWidths: columnWidths,
                    scrollSync: _scrollSync,
                    height: widget.headerHeight,
                    fallbackColumnWidth: widget.minColumnWidth,
                    hasMultiselect: widget.hasMultiselect,
                    checkboxCellSize: widget.height,
                    // Select-all is computed against the FULL dataset
                    // (widget.items), not `_displayedItems` — the search
                    // filter must not hide rows out of "select all", per the
                    // documented behavior: it selects everything regardless
                    // of what is currently visible.
                    allSelected:
                        widget.items.isNotEmpty && widget.items.every((item) => _controller.selection.contains(item)),
                    onSelectAllChanged: widget.hasMultiselect
                        ? (selectAll) {
                            if (selectAll) {
                              _controller.selectAll(widget.items);
                            } else {
                              _controller.clearSelection();
                            }
                          }
                        : null,
                  ),
                  if (_isComputing)
                    LayrzProgressBar(format: LayrzProgressFormat.linear, semanticLabel: 'Sorting table data'),
                  Expanded(
                    child: isEmpty
                        ? _buildEmptyState(context, isSearchMiss: isSearchMiss)
                        : ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) {
                              return ListView.builder(
                                itemCount: items.length,
                                itemExtent: widget.height,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return LayrzTableRow<T>(
                                    key: ValueKey('layrz-table-row-$index-${item.hashCode}'),
                                    item: item,
                                    rowIndex: index,
                                    visibleColumns: visibleColumns,
                                    columnWidths: widths,
                                    height: widget.height,
                                    scrollSync: _scrollSync,
                                    hasMultiselect: widget.hasMultiselect,
                                    isSelected: _controller.selection.contains(item),
                                    onSelectedChanged: widget.hasMultiselect
                                        ? (_) => _controller.toggleSelection(item)
                                        : null,
                                    actions: widget.actionsBuilder?.call(item) ?? const [],
                                    copyToClipboardText: widget.copyToClipboardText,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  /// Returns the first element, or `null` if this iterable is empty.
  ///
  /// Local helper kept private to this file rather than pulled from
  /// `package:collection`, since this is the only place in the module that
  /// needs it.
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

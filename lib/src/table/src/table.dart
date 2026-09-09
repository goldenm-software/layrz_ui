import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/progress/progress.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/column_menu.dart';
import 'package:layrz_ui/src/table/src/controller.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/table/src/sort.dart';
import 'package:layrz_ui/src/table/src/table_action.dart';
import 'package:layrz_ui/src/table/src/table_header.dart';
import 'package:layrz_ui/src/table/src/table_row.dart';

/// The fixed height, in logical pixels, of the loading-indicator strip
/// pinned above [LayrzTable]'s header.
///
/// This space is always reserved, whether or not the strip is currently
/// animating — see [LayrzTable]'s "Loading indicator" doc section and
/// decision D15 (interaction/state changes never move geometry).
const double _kTableTopProgressHeight = 2.0;

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
/// **Filtering and sorting**: the table maintains a lowercased display-string
/// cache for every column of every item (parallel to [items]), rebuilt only
/// when [items] or [columns] change identity — not on every keystroke. Each
/// recompute (triggered by a data/column change or by a controller change
/// such as search text, sort, selection, or column visibility) filters by
/// [LayrzTableController.searchText] (case-insensitive `contains` across the
/// currently-visible columns' cached strings), and — when a sort column is
/// active — sorts the filtered list off the UI thread, via
/// [sortIndexesOffThread] (sending only precomputed sort keys, reordering by
/// the returned index order) for the default comparator, or via
/// [sortTableItemsOffThread] when `LayrzColumn.customSort` is set. The
/// resulting filtered+sorted count is reported through
/// [onFilteredCountChanged] whenever it changes.
///
/// **Loading indicator**: a 2-logical-pixel-tall linear progress strip is
/// pinned above the header, and its height is reserved unconditionally — it
/// occupies the same 2px regardless of loading state, so toggling loading
/// never shifts the header or rows (see decision D15: interaction/state
/// changes vary color/opacity, never geometry). The strip animates
/// (indeterminate sweep) whenever [isLoading] is `true`, or while the table
/// is running its own off-thread sort/filter recompute (see
/// [LayrzTableController]'s change notifications above); it is present but
/// visually empty otherwise. This is the table's only loading affordance —
/// there is no separate full-table spinner, and the header/body are always
/// rendered regardless of [isLoading].
///
/// **Column widths**: computed once per [LayoutBuilder] pass from the
/// available width — fixed-width columns ([LayrzColumn.width] non-null) keep
/// their own width; the remaining space is split evenly among flex columns
/// ([LayrzColumn.width] null), floored at [minColumnWidth]. The same
/// resolved widths are handed to [LayrzTableHeader] (as a `Map<Key, double>`)
/// and to every [LayrzTableRow] (as a parallel `List<double>`, in the same
/// order as that row's visible columns), so header and body columns always
/// agree pixel-for-pixel. The pinned-right actions column, when
/// [actionsCount] is greater than `0`, is computed the same way — once, and
/// handed verbatim to both the header and every row — but by a fixed formula
/// over [actionsCount] rather than by this fixed/flex split; see
/// [actionsCount]'s own doc.
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
  /// Whether a pinned-right actions cell is rendered at all is controlled
  /// solely by [actionsCount] — see that field's doc — not by whether this
  /// builder is `null` or by how many actions it returns. When [actionsCount]
  /// is `0`, this builder is never even called: the actions column does not
  /// exist, regardless of what would be supplied here.
  final List<LayrzTableAction> Function(T item)? actionsBuilder;

  /// The number of row-level actions the table reserves pinned-right column
  /// space for.
  ///
  /// This is the **single source of truth** for the actions column — not
  /// [actionsBuilder]. Defaults to `0`, meaning no actions column is
  /// rendered at all (no width reserved, no cell in the header or in any
  /// row) **even when [actionsBuilder] is supplied**: a non-zero count is
  /// what turns the column on.
  ///
  /// When greater than `0`, the actions column's width is computed
  /// deterministically from this count rather than from actual button
  /// content, so the header's actions cell and every row's actions cell
  /// always agree pixel-for-pixel:
  /// - **Wide viewports** (`!context.isCompact`): the column fits exactly
  ///   [actionsCount] individual fab buttons side by side, each
  ///   [kLayrzButtonHeight] square, plus the same horizontal gap
  ///   [LayrzTableRow] already applies around each one.
  /// - **Compact viewports** (`context.isCompact`): row actions collapse
  ///   into a single overflow trigger (see `LayrzTableRow`'s
  ///   `_buildCompactActions`), so the column fits exactly one
  ///   [kLayrzButtonCompactHeight]-square trigger regardless of
  ///   [actionsCount], as long as it is greater than `0`.
  ///
  /// Pass a count higher than [actionsBuilder] ever actually returns and the
  /// column will simply be wider than its content needs; pass a lower count
  /// and actions beyond it will be clipped. Callers are expected to keep
  /// this in step with what [actionsBuilder] returns.
  final int actionsCount;

  /// Whether rows render a pinned-left multiselect checkbox cell.
  ///
  /// Defaults to `false` (opt-in) — unlike the `layrz_theme` baseline, which
  /// defaulted to `true` while also asserting at least one multiselect action
  /// was supplied. When `true`, tapping a row's checkbox toggles its
  /// selection via the controller.
  final bool hasMultiselect;

  /// Whether the table renders a search field in its toolbar row, above the
  /// header.
  ///
  /// Defaults to `true`. When `false`, no search field is rendered and the
  /// controller's [LayrzTableController.searchText] (if ever set
  /// programmatically) still applies as a filter. Either way, the toolbar
  /// row itself is always rendered — its trailing column-visibility/reorder
  /// menu trigger must stay reachable regardless of [canSearch]; see
  /// `_buildToolbar`.
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

  /// Previously the label shown alongside a centered loading spinner while
  /// [isLoading] was `true`.
  ///
  /// That centered spinner has been replaced by a thin progress strip pinned
  /// above the header (see [isLoading]), which has no room for a label — so
  /// this parameter is currently unused. It is kept, rather than removed, to
  /// avoid a breaking constructor change; a future loading-text treatment may
  /// give it a home again.
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
  /// The table always reserves a thin (2 logical pixel) strip above its
  /// header for a linear progress indicator — see the class-level doc's
  /// "Loading indicator" section. That strip animates whenever [isLoading] is
  /// `true`, or while the table is sorting/filtering off the UI thread
  /// internally; it stays present but inert otherwise. Unlike the previous
  /// behavior, the header and rows are never hidden or replaced while
  /// loading. Defaults to `false`.
  final bool isLoading;

  /// Creates a [LayrzTable].
  ///
  /// [items] and [columns] are required. [columns] must be non-empty, and
  /// every [LayrzColumn.key] in it must be unique. [minColumnWidth] must be
  /// greater than `0`. [actionsCount] defaults to `0` (no actions column)
  /// and must not be negative.
  LayrzTable({
    required this.items,
    required this.columns,
    this.controller,
    this.actionsBuilder,
    this.actionsCount = 0,
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
       assert(actionsCount >= 0, 'actionsCount must not be negative'),
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

  /// Per-row, per-column lowercased display-string cache, parallel to
  /// [LayrzTable.items] and [LayrzTable.columns] (outer list indexed by item,
  /// inner list indexed by column, in [LayrzTable.columns] order).
  ///
  /// Built once in [_rebuildSearchCache] whenever [LayrzTable.items] or
  /// [LayrzTable.columns] change identity, rather than on every search
  /// keystroke — this is the whole point of the cache: at large row counts,
  /// recomputing `LayrzColumn.valueBuilder(item).toLowerCase()` for every
  /// column of every row on every recompute is the dominant cost of typing
  /// into the search field. All columns are cached regardless of current
  /// visibility (not just the currently-visible subset), so a column
  /// show/hide toggle — which does not change [LayrzTable.items] or
  /// [LayrzTable.columns] identity — never needs to invalidate this cache;
  /// [_recompute] simply reads the cached strings for whichever columns are
  /// visible at filter time.
  List<List<String>> _searchCache = const [];

  /// The [LayrzTable.items] and [LayrzTable.columns] instances [_searchCache]
  /// was built from, so a later [_recompute] (e.g. triggered by a
  /// controller-only change, like search text) can tell the cache is still
  /// valid without rebuilding it.
  List<T>? _searchCacheItems;
  List<LayrzColumn<T>>? _searchCacheColumns;

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
  /// Ensures [_searchCache] is up to date (see [_ensureSearchCache] — a
  /// no-op unless [LayrzTable.items] or [LayrzTable.columns] changed
  /// identity), applies the case-insensitive search filter against the
  /// cached strings for whichever columns are currently visible, then — only
  /// when a sort column is active — sorts off the UI thread: via
  /// [sortIndexesOffThread] for the default comparator (sending only
  /// precomputed sort keys and getting back an index order, so
  /// `LayrzColumn.valueBuilder` never itself crosses the isolate boundary and
  /// neither does the row data), or via [sortTableItemsOffThread] when
  /// `LayrzColumn.customSort` is set (which must compare actual row objects).
  Future<void> _recompute() async {
    final items = widget.items;
    final columns = widget.columns;
    final visibleKeys = _controller.visibleColumnKeys;
    final visibleColumnIndexes = [
      for (var i = 0; i < columns.length; i++)
        if (visibleKeys.contains(columns[i].key)) i,
    ];

    _ensureSearchCache(items, columns);

    final searchText = _controller.searchText.trim().toLowerCase();
    List<T> filtered;
    if (searchText.isEmpty) {
      filtered = List<T>.of(items);
    } else {
      filtered = [
        for (var i = 0; i < items.length; i++)
          if (visibleColumnIndexes.any((columnIndex) => _searchCache[i][columnIndex].contains(searchText))) items[i],
      ];
    }

    final sortColumnKey = _controller.sortColumnKey;
    if (sortColumnKey != null) {
      final sortColumn = columns.where((column) => column.key == sortColumnKey).firstOrNull;
      if (sortColumn != null) {
        final ascending = _controller.sortAscending;
        final customSort = sortColumn.customSort;

        setState(() => _isComputing = true);
        try {
          if (customSort != null) {
            // customSort must compare the actual T objects, so there is no
            // precomputed-key shortcut available here — the full (filtered)
            // item list crosses the isolate boundary, as before.
            filtered = await sortTableItemsOffThread<T>(
              SortParams<T>(items: filtered, customSort: customSort, ascending: ascending),
            );
          } else {
            // Default comparator path: only string sort keys + an index
            // array cross the isolate boundary, never the row objects
            // themselves, so the copy cost is independent of how large or
            // deeply-nested T is. The isolate returns the sorted index
            // order; reordering `filtered` by it here is cheap reference
            // shuffling on the main thread.
            final sortKeys = [for (final item in filtered) sortColumn.valueBuilder(item)];
            final order = await sortIndexesOffThread(SortKeysParams(sortKeys: sortKeys, ascending: ascending));
            filtered = [for (final index in order) filtered[index]];
          }
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

  /// Rebuilds [_searchCache] from [items]/[columns] if it is stale — i.e. if
  /// either instance differs from the one the cache currently reflects — and
  /// is a no-op otherwise.
  ///
  /// This is the guard that keeps the cache from being rebuilt on every
  /// keystroke: a search-text-only [_recompute] (the overwhelming majority of
  /// calls) sees the same [items]/[columns] instances as last time and skips
  /// straight past this to the `contains` filter. Identity (`==`, which for
  /// `List` defaults to identity) is enough here because [_recompute] is only
  /// ever invoked for a data/column change from [didUpdateWidget]'s identity
  /// check, or for a controller-only change (search/sort/column visibility)
  /// that leaves [LayrzTable.items] and [LayrzTable.columns] untouched.
  void _ensureSearchCache(List<T> items, List<LayrzColumn<T>> columns) {
    if (identical(items, _searchCacheItems) && identical(columns, _searchCacheColumns)) return;

    _searchCache = [
      for (final item in items) [for (final column in columns) column.valueBuilder(item).toLowerCase()],
    ];
    _searchCacheItems = items;
    _searchCacheColumns = columns;
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

  /// Computes whether every item in [LayrzTable.items] (the full dataset,
  /// not the search-filtered [_displayedItems] — see the call site's own
  /// comment) is currently selected, for the header's select-all checkbox.
  ///
  /// Cheap for the common case: [LayrzTableController.selection] can only
  /// contain every item once `selection.length >= items.length`, so a
  /// mismatched length short-circuits before ever walking [_controller]'s
  /// `Set`-backed `contains` per item — the walk this method exists to gate
  /// only runs when the lengths actually allow "all selected" to be true.
  /// This keeps an unrelated parent rebuild (which re-evaluates this every
  /// `build()`, selection unchanged or not) cheap even at very large row
  /// counts, without caching a value that could otherwise go stale against
  /// the controller.
  bool _computeAllSelected() {
    final items = widget.items;
    final selection = _controller.selection;
    if (items.isEmpty || selection.length < items.length) return false;
    return items.every(selection.contains);
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
    final l10n = context.l10n;
    final text = isSearchMiss
        ? (widget.emptySearchText ?? l10n.tableNoSearchResults)
        : (widget.emptyText ?? l10n.tableEmpty);
    return Padding(
      padding: tokens.spacing.pd3,
      child: Text(text, style: tokens.typography.label),
    );
  }

  /// Computes the deterministic actions-column width for
  /// [LayrzTable.actionsCount], or `null` when it is `0` (no actions column
  /// at all).
  ///
  /// This is the single place the width is computed — both
  /// [LayrzTableHeader] and every [LayrzTableRow] receive this exact value,
  /// so their actions cells always align pixel-for-pixel (see
  /// [LayrzTable.actionsCount]'s doc for the formula's rationale).
  ///
  /// - **Wide** (`!isCompact`): [LayrzTableRow]'s `_buildWideActions` renders
  ///   one [kLayrzButtonHeight]-square fab per action, each wrapped in
  ///   `EdgeInsets.symmetric(horizontal: tokens.spacing.sp1 / 2)` — i.e. each
  ///   fab contributes `kLayrzButtonHeight + tokens.spacing.sp1` to the row
  ///   of fabs — inside the actions cell's own
  ///   `EdgeInsets.symmetric(horizontal: tokens.spacing.sp1)` padding (see
  ///   `_buildActionsCell`). The total is therefore
  ///   `actionsCount * (kLayrzButtonHeight + sp1) + sp1 * 2`.
  /// - **Compact** (`isCompact`): actions collapse into a single
  ///   [kLayrzButtonCompactHeight]-square overflow trigger (fab sizing is
  ///   viewport-driven, not style-driven — see `LayrzButton._resolveDimensions`),
  ///   inside the same cell padding: `kLayrzButtonCompactHeight + sp1 * 2`.
  double? _computeActionsColumnWidth(BuildContext context) {
    final actionsCount = widget.actionsCount;
    if (actionsCount <= 0) return null;

    final sp1 = context.tokens.spacing.sp1;
    if (context.isCompact) {
      return kLayrzButtonCompactHeight + sp1 * 2;
    }
    return actionsCount * (kLayrzButtonHeight + sp1) + sp1 * 2;
  }

  /// Builds the always-present, always-2px-tall strip pinned above the
  /// header (see [LayrzTable]'s "Loading indicator" doc section).
  ///
  /// The outer [SizedBox] height is exactly [_kTableTopProgressHeight]
  /// regardless of [_isTopProgressVisible] — that is what keeps toggling
  /// loading from ever moving the header or rows. When inactive, an empty
  /// [SizedBox] is rendered instead of the bar itself, so no sweep animation
  /// ticker exists (and no repaint cost is paid) while idle.
  Widget _buildTopProgressStrip(BuildContext context) {
    return SizedBox(
      height: _kTableTopProgressHeight,
      child: _isTopProgressVisible
          ? const LayrzProgressBar(
              format: LayrzProgressFormat.linear,
              height: _kTableTopProgressHeight,
              borderRadius: 0,
              semanticLabel: 'Loading table data',
            )
          : const SizedBox.shrink(),
    );
  }

  /// Whether the top progress strip (see [_buildTopProgressStrip]) should
  /// currently animate: either the caller set [LayrzTable.isLoading], or the
  /// table itself is mid off-thread sort/filter recompute ([_isComputing]).
  bool get _isTopProgressVisible => widget.isLoading || _isComputing;

  /// Builds the toolbar row above the loading strip/header/rows: the search
  /// field (when [LayrzTable.canSearch] is `true`) and, always, the trailing
  /// [LayrzColumnMenu] trigger.
  ///
  /// The column-visibility/reorder menu trigger lives here — beside the
  /// search field — rather than inside [LayrzTableHeader], so it reads as a
  /// table-level control, not a per-column one. It must stay reachable
  /// regardless of [LayrzTable.canSearch]: when search is enabled, the
  /// search field fills the remaining width to its left ([Expanded]); when
  /// disabled, this row still renders with just the trigger, right-aligned,
  /// rather than disappearing along with the search field.
  Widget _buildToolbar(BuildContext context) {
    final sp2 = context.tokens.spacing.sp2;
    return Padding(
      padding: EdgeInsets.only(bottom: sp2),
      child: Row(
        children: [
          if (widget.canSearch) ...[
            Expanded(
              child: LayrzSearchInput(
                value: _controller.searchText,
                onSearch: _controller.search,
                mode: LayrzSearchInputMode.field,
              ),
            ),
            SizedBox(width: sp2),
          ] else
            const Spacer(),
          LayrzColumnMenu<T>(columns: widget.columns, controller: _controller),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context),
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
              final actionsColumnWidth = _computeActionsColumnWidth(context);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopProgressStrip(context),
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
                    allSelected: _computeAllSelected(),
                    onSelectAllChanged: widget.hasMultiselect
                        ? (selectAll) {
                            if (selectAll) {
                              _controller.selectAll(widget.items);
                            } else {
                              _controller.clearSelection();
                            }
                          }
                        : null,
                    actionsColumnWidth: actionsColumnWidth,
                  ),
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
                                    actions: widget.actionsCount > 0
                                        ? (widget.actionsBuilder?.call(item) ?? const [])
                                        : const [],
                                    actionsColumnWidth: actionsColumnWidth,
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

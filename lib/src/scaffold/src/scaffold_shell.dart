import "package:flutter/widgets.dart";
import "package:flutter_material_design_icons/flutter_material_design_icons.dart";
import "package:layrz_ui/src/cards/cards.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/refresh/refresh.dart";
import "package:layrz_ui/src/scaffold/src/scaffold_item.dart";
import "package:layrz_ui/src/sheets/sheets.dart";
import "package:layrz_ui/src/table/table.dart";
import "package:layrz_ui/src/tokens/tokens.dart";

import "detail_pane.dart";
import "list_panel.dart";
import "scaffold_controller.dart";

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
///
/// **Wide containers** (`!context.isCompact`, i.e. width ≥ 960px) have two
/// presentations, chosen by whether an item is open ([LayrzScaffoldController.isOpen]):
///
/// - **Nothing open** → the shell fills its whole width with a [LayrzTable]
///   built from [items] and [tableColumns]. A table shows far more per row than
///   a list tile can, which is the better default for scanning a dataset. Each
///   table row carries one built-in "open" button (see [showActionLabel]) that
///   invokes [onItemTap] for that item — there is no whole-row tap. Opening an
///   item flips the shell into the split below.
/// - **An item open** → the classic side-by-side split: the list panel (300px)
///   on the left, the detail pane on the right. The list panel's header renders
///   [title] with a leading close button that calls [LayrzScaffoldController.close]
///   to return to the table.
///
/// The two wide presentations cross-fade into each other (see the motion tokens'
/// standard transition), so opening or closing an item is a fade rather than an
/// instant swap.
///
/// On narrow containers (xs, sm breakpoints), the list panel is always shown;
/// opening an item presents the detail content in a modal [LayrzBottomSheet]
/// layered over the list. Dismissing the sheet closes the controller. A resize
/// from narrow to wide pops the sheet but preserves the selection, and a resize
/// to narrow auto-opens the sheet for any already-selected item. [tableColumns]
/// never affects the narrow layout, and the narrow header renders [title] as-is
/// with no close button.
///
/// **Narrow layout constraint:** The shell requires a [Navigator] ancestor (e.g. [LayrzApp])
/// to show the detail sheet on narrow breakpoints. If no Navigator is present, the list
/// still renders without the detail, and a debug assertion fires on the sheet attempt.
///
/// The consuming app passes items and owns the controller; the shell owns the
/// layout and search filtering.
class LayrzScaffoldShell<T> extends StatefulWidget {
  /// The items to display in the list.
  final List<LayrzScaffoldItem<T>> items;

  /// Called when a list row (or a desktop table row's open button) is activated.
  ///
  /// The shell never opens the detail pane by itself — the caller decides what
  /// happens, typically by opening the detail pane for the activated item's own
  /// content:
  ///
  /// ```dart
  /// onItemTap: (item) => controller.open(key: item.key, builder: (_) => Detail(item.item)),
  /// ```
  ///
  /// Both the list rows (narrow, and the wide split) and the desktop table's
  /// built-in per-row open button route through this same callback. Leaving it
  /// null makes rows inert (no detail pane, no highlight change) — useful for a
  /// purely informational list. Defaults to null.
  final void Function(LayrzScaffoldItem<T> item)? onItemTap;

  /// Controller for managing the opened item.
  final LayrzScaffoldController controller;

  /// Optional footer widget for the list panel.
  final Widget? footer;

  /// Whether the search field is visible.
  final bool searchable;

  /// The title widget rendered above the search field in the list panel.
  ///
  /// On wide containers, while an item is open, the list panel's header renders
  /// this title in a row with a leading close button that returns to the table;
  /// on narrow containers it renders as-is. Required.
  final Widget title;

  /// The item extent for the list panel.
  final double itemExtent;

  /// Optional widget to display when the list is empty.
  ///
  /// If null, a localized default message is displayed.
  final Widget? emptyState;

  /// Called to refresh the list's data, or null to disable the refresh affordance
  /// entirely.
  ///
  /// The shell's refresh affordance is scoped to the LIST PANEL only, never the
  /// whole shell: internally, [ListPanel] wraps just its own scrollable in a
  /// [LayrzRefreshIndicator] (drag gesture + pull visual) and renders a small,
  /// always-available refresh control in its footer region, alongside
  /// [footer] rather than replacing it — this is what lets a consumer stop
  /// wrapping the entire [LayrzScaffoldShell] in their own
  /// [LayrzRefreshIndicator], which previously floated its fallback button
  /// over BOTH panes (list and detail) instead of just the list.
  ///
  /// There is deliberately no floating fallback button and no header/toolbar
  /// button at the shell level — desktop's always-available affordance is the
  /// footer control described above. Touch platforms additionally keep the
  /// drag-to-refresh gesture on the list's scrollable.
  ///
  /// Defaults to null, which is fully backward compatible: no indicator is
  /// built around the list, and no refresh control appears in the footer
  /// region — [footer] renders exactly as it did before this parameter
  /// existed.
  final Future<void> Function()? onRefresh;

  /// Optional controller for the list panel's refresh lifecycle.
  ///
  /// Ignored when [onRefresh] is null. When [onRefresh] is non-null and this
  /// is left null, the shell creates and owns its own internal controller.
  /// Pass an explicit [LayrzRefreshController] to also trigger a refresh
  /// programmatically from outside the shell (e.g. a keyboard shortcut, a
  /// toolbar action elsewhere in the app) via [LayrzRefreshController.refresh] —
  /// the same controller instance drives both the drag gesture/pull visual
  /// and the footer refresh control, so every trigger path animates in
  /// lockstep.
  final LayrzRefreshController? refreshController;

  /// The columns for the desktop default table view.
  ///
  /// On a wide container (`!context.isCompact`) with **nothing open**, the shell
  /// renders a full-width [LayrzTable] over [items] and these columns. Each
  /// [LayrzColumn.valueBuilder] reads directly off the item's own data object
  /// (`LayrzScaffoldItem.item`, of type [T]), so no per-item cell data is needed
  /// on [LayrzScaffoldItem] itself; the shell unwraps `items.map((i) => i.item)`
  /// into the table.
  ///
  /// Opening an item (via the table's built-in per-row open button, which invokes
  /// [onItemTap]) collapses the shell into the list-detail split for as long as
  /// something is open. Required; the narrow layout ignores this field entirely.
  final List<LayrzColumn<T>> tableColumns;

  /// The controller for the desktop default table's own state — sort, search,
  /// column order/visibility, and selection.
  ///
  /// Passed straight through to the internal [LayrzTable]. This is the app's
  /// handle for observing or driving that table state from outside the shell
  /// (e.g. a listener on sort/search, or reading the current selection).
  /// Required, and **caller-owned**: the shell never disposes it, mirroring
  /// [LayrzTable]'s own controller-ownership contract.
  ///
  /// The desktop table only mounts on wide viewports (`!context.isCompact`), so
  /// on a compact-only shell this controller stays idle-but-valid — it simply
  /// has no table to drive until the viewport is wide. It remains the caller's
  /// to dispose regardless.
  final LayrzTableController<T> tableController;

  /// The label (and accessibility/tooltip hint) for the desktop table's
  /// built-in per-row "open" button.
  ///
  /// Only used while the desktop table default view is showing. When null, the
  /// shell uses the localized `LayrzUiL10n.scaffoldOpenItem` ("Open item")
  /// default.
  final String? showActionLabel;

  /// Creates a new [LayrzScaffoldShell].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [onItemTap]: Called when a row (or the table's open button) is activated.
  ///   Defaults to null, which leaves rows inert.
  /// - [controller]: Controller for managing the opened item. Required.
  /// - [footer]: Optional footer widget for the list panel. Defaults to null.
  /// - [searchable]: Whether the search field is visible. Defaults to true.
  /// - [title]: The title widget rendered above the search field. Required.
  /// - [itemExtent]: The height of each list item. Required.
  /// - [emptyState]: Optional widget to display when the list is empty. Defaults to null.
  /// - [onRefresh]: Called to refresh the list's data. Defaults to null, which disables
  ///   the refresh affordance entirely (no indicator, no footer control).
  /// - [refreshController]: Optional controller for the refresh lifecycle. Defaults to
  ///   null, ignored unless [onRefresh] is also non-null.
  /// - [tableColumns]: Columns for the desktop default table view. Required. Ignored on
  ///   the narrow layout.
  /// - [tableController]: Controller for the desktop table's sort/search/column/selection
  ///   state, passed through to the internal [LayrzTable]. Required and caller-owned (the
  ///   shell never disposes it). Idle-but-valid on a compact-only shell.
  /// - [showActionLabel]: Label/tooltip for the desktop table's built-in per-row open
  ///   button. Defaults to null, which uses the localized "Open item" string.
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    this.onItemTap,
    required this.controller,
    this.footer,
    this.searchable = true,
    required this.title,
    required this.itemExtent,
    this.emptyState,
    this.onRefresh,
    this.refreshController,
    required this.tableColumns,
    required this.tableController,
    this.showActionLabel,
  });

  @override
  State<LayrzScaffoldShell<T>> createState() => _LayrzScaffoldShellState<T>();
}

class _LayrzScaffoldShellState<T> extends State<LayrzScaffoldShell<T>> {
  late VoidCallback _controllerListener;
  late ValueNotifier<int> _itemsChangeNotifier;

  /// Whether a detail sheet is currently open on narrow layouts.
  bool _sheetOpen = false;

  /// Whether the shell initiated the last sheet pop (band transition).
  /// If true, don't close the controller when the sheet closes.
  bool _dismissedByShell = false;

  /// Reference to the builder context from the narrow sheet, used to pop it specifically.
  BuildContext? _narrowSheetContext;

  /// The desktop table's rows — `widget.items` unwrapped to their underlying
  /// data objects — cached across builds.
  ///
  /// **Why this must be cached and not rebuilt per build:** `LayrzTable`
  /// re-runs its full string-cache rebuild and off-thread sort whenever the
  /// `items` list it receives is not `identical` to the previous one
  /// (`LayrzTable.didUpdateWidget`). On web there is no isolate, so that
  /// "off-thread" recompute runs synchronously on the UI thread — a ~150ms
  /// main-thread stall was measured on every open/close when the shell handed
  /// the table a freshly-allocated `items.map(...).toList()` each build (the
  /// `AnimatedSwitcher` cross-fade rebuilds this subtree repeatedly). Caching
  /// the unwrapped list and only re-deriving it when `widget.items` changes
  /// identity keeps the reference stable across those rebuilds, so the table
  /// recomputes only when the data genuinely changes.
  List<T>? _tableRows;

  /// The source `items` list [_tableRows] was last derived from, used to
  /// detect an actual data change vs. an incidental rebuild.
  List<LayrzScaffoldItem<T>>? _tableRowsSource;

  /// The stable unwrapped-rows list for the desktop table, re-derived only
  /// when [LayrzScaffoldShell.items] changes identity. See [_tableRows].
  List<T> get _cachedTableRows {
    if (!identical(_tableRowsSource, widget.items) || _tableRows == null) {
      _tableRowsSource = widget.items;
      _tableRows = widget.items.map((item) => item.item).toList(growable: false);
    }
    return _tableRows!;
  }

  double get _itemExtent => widget.itemExtent + context.tokens.spacing.pd2.vertical;

  @override
  void initState() {
    super.initState();
    _controllerListener = () {
      setState(() {});
    };
    _itemsChangeNotifier = ValueNotifier(widget.items.length);
    widget.controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
    }
    // Notify when items list instance changes (handles refetches with same keys but new instances),
    // but only while the narrow sheet's ListenableBuilder is actually listening to this notifier —
    // otherwise the bump is both unobserved and unsafe.
    //
    // The bump is deferred to a post-frame callback rather than applied synchronously here: this
    // notifier is merged into the Listenable driving the sheet's ListenableBuilder, so an immediate
    // `.value++` fires `notifyListeners()` -> `setState()` on that (possibly still-mounted, e.g.
    // mid exit-animation) builder while the framework may already be building this shell's own
    // subtree (e.g. from a LayoutBuilder-driven breakpoint change). That is an illegal
    // setState-during-build. Deferring costs at most one extra frame, and only when the sheet is
    // actually open to observe it.
    if (_sheetOpen && !identical(oldWidget.items, widget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetOpen) {
          _itemsChangeNotifier.value++;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    _itemsChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.tokens;
        // Wide vs. compact is the design system's single source of truth:
        // `isWide == !context.isCompact` (compact is width < 960px).
        final isWide = !context.isCompact;

        // A resize from narrow to wide pops a currently-open sheet without
        // closing the controller, so the selection survives the switch into
        // the wide (table/split) layout, which never shows the sheet.
        if (_sheetOpen && isWide) {
          // Schedule the pop for after the build, to avoid modifying the widget tree during build.
          // Mark it as shell-initiated so the sheet dismissal callback doesn't close the controller.
          _dismissedByShell = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_narrowSheetContext != null && _narrowSheetContext!.mounted) {
              Navigator.of(_narrowSheetContext!).pop();
              _narrowSheetContext = null;
            }
          });
        }

        if (isWide) {
          return _buildWideLayout(context, tokens);
        } else {
          return _buildNarrowLayout(context, tokens);
        }
      },
    );
  }

  /// Builds the wide layout used on wide containers (`!context.isCompact`).
  ///
  /// Two presentations, per DESIGN-216, chosen by [LayrzScaffoldController.isOpen]:
  ///
  /// - Nothing open → the whole width is a [LayrzTable] default view (see
  ///   [_buildDefaultTable]).
  /// - An item open → the side-by-side split (see [_buildWideSplit]).
  ///
  /// **The table is kept permanently mounted**, with the split layered above it
  /// in a [Stack] and cross-faded in/out via [AnimatedOpacity] on the split
  /// layer alone. This is deliberate and load-bearing for performance: an
  /// earlier version used an [AnimatedSwitcher] that swapped the two subtrees,
  /// which DISPOSED and RE-CREATED the whole [LayrzTable] on every open/close.
  /// The table's first-mount build/layout of its header, virtualized rows and
  /// sync-scroll controllers costs ~150ms on web (measured), so re-creating it
  /// on each toggle produced a ~150ms stall per open and per close. Keeping it
  /// mounted pays that cost once. While the split is shown it fully, opaquely
  /// covers the table, and the table layer is wrapped in [IgnorePointer]/
  /// [ExcludeSemantics] so the covered table takes no input and adds no
  /// duplicate semantics.
  ///
  /// The fade duration/curve come from the motion tokens (dTransition, easing),
  /// obeying the design system's animation contract — a standard transition
  /// under the 250ms cap, with the standard easing curve.
  Widget _buildWideLayout(BuildContext context, LayrzTokens tokens) {
    final isOpen = widget.controller.isOpen;

    return Stack(
      fit: StackFit.expand,
      children: [
        // The table is always mounted (never disposed on open/close); it is
        // simply covered by the split while an item is open. It stops taking
        // input and stops contributing semantics while covered.
        IgnorePointer(
          ignoring: isOpen,
          child: ExcludeSemantics(
            excluding: isOpen,
            child: _buildDefaultTable(context, tokens),
          ),
        ),
        // Only the (lightweight) split fades in/out over the persistent table,
        // via an AnimatedSwitcher whose child is an empty box while closed —
        // so the heavy LayrzTable is never disposed/recreated by the toggle,
        // while the split still cross-fades on open and close.
        AnimatedSwitcher(
          duration: tokens.motion.dTransition,
          switchInCurve: tokens.motion.easing,
          switchOutCurve: tokens.motion.easing,
          child: isOpen
              ? KeyedSubtree(
                  key: const ValueKey('layrz-scaffold-wide-split'),
                  child: _buildWideSplit(context, tokens),
                )
              : const SizedBox.shrink(key: ValueKey('layrz-scaffold-wide-none')),
        ),
      ],
    );
  }

  /// Builds the classic wide side-by-side split: the list panel on the left and
  /// the detail pane (wrapped in a [LayrzCard]) on the right.
  ///
  /// Returning to the table (closing the open item) is the caller's
  /// responsibility — the app places whatever close/back affordance it wants
  /// inside its own detail builder and calls [LayrzScaffoldController.close].
  /// The shell only cross-fades table<->split off [LayrzScaffoldController.isOpen].
  ///
  /// The detail pane is wrapped in a [LayrzCard] rather than separated from the
  /// list panel by a hairline divider — a card reads as its own object (echoing
  /// the narrow layout's floating bottom sheet) instead of a bare rule down the
  /// middle. A [LayrzSpacingTokens.sp3] gutter surrounds the card on every side.
  ///
  /// The whole split paints an opaque `sf1` ground, because the desktop table
  /// stays mounted BEHIND it (see [_buildWideLayout]) — without an opaque
  /// backing the table would show through the gutter around the detail card and
  /// any gap the list panel does not itself cover.
  Widget _buildWideSplit(BuildContext context, LayrzTokens tokens) {
    return ColoredBox(
      color: tokens.colors.sf1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListPanel<T>(
            items: widget.items,
            openedKey: widget.controller.openedKey,
            controller: widget.controller,
            onTap: widget.onItemTap,
            searchable: widget.searchable,
            footer: widget.footer,
            title: widget.title,
            itemExtent: _itemExtent,
            emptyState: widget.emptyState,
            onRefresh: widget.onRefresh,
            refreshController: widget.refreshController,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.sp3),
              child: LayrzCard(
                elevation: 1,
                child: DetailPane(
                  builder: widget.controller.openedBuilder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the desktop default full-width [LayrzTable] view (DESIGN-216).
  ///
  /// Renders [LayrzScaffoldShell.title] above the table, matching the title's
  /// presence in the wide split's [ListPanel] header — otherwise the title is
  /// only ever visible once an item is open, never in this default table mode.
  ///
  /// The table's rows are the items' own data objects — `widget.items` unwrapped
  /// via [LayrzScaffoldItem.item] — since each [LayrzColumn.valueBuilder] reads
  /// off [T] directly. No per-item cell data lives on [LayrzScaffoldItem].
  ///
  /// [LayrzTable] has no whole-row tap affordance, so the shell recycles the
  /// table's own per-row actions slot ([LayrzTable.actionsBuilder] with
  /// [LayrzTable.actionsCount] `1`) for a single built-in "open" button. Its tap
  /// resolves the tapped data object back to its [LayrzScaffoldItem] and fires
  /// [LayrzScaffoldShell.onItemTap] — the same callback the list rows use — so
  /// the app opens the detail exactly as it does from the list, collapsing the
  /// shell into the split.
  ///
  /// The table's [LayrzTable.onFilteredCountChanged] is wired straight into
  /// [LayrzScaffoldShell.controller] (the SCAFFOLD controller, not
  /// [LayrzScaffoldShell.tableController]) via [_publishTableCounts], so a
  /// consumer observing only [LayrzScaffoldController.totalCount]/
  /// [LayrzScaffoldController.filteredCount] sees correct counts in table mode
  /// too — mirroring what [ListPanel] already does for the narrow/split layout.
  /// `LayrzTable` itself defers its very first report to a post-frame callback
  /// and never calls back synchronously during build, so no extra initial
  /// publish is needed here.
  Widget _buildDefaultTable(BuildContext context, LayrzTokens tokens) {
    final openLabel = widget.showActionLabel ?? context.l10n.scaffoldOpenItem;

    // The table gets the same sp3 gutter the split's detail card uses, so it
    // reads as a padded surface rather than sitting flush against the shell's
    // own edges. `_cachedTableRows` is a reference-stable list (see its doc) so
    // the table does not re-run its off-thread sort on every rebuild.
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.spacing.sp1,
        children: [
          widget.title,
          Expanded(
            child: LayrzTable<T>(
              items: _cachedTableRows,
              columns: widget.tableColumns,
              controller: widget.tableController,
              canSearch: widget.searchable,
              actionsCount: 1,
              actionsBuilder: (data) => [
                LayrzTableAction(
                  icon: MdiIcons.eyeOutline,
                  labelText: openLabel,
                  onTap: () => _openFromTable(data),
                ),
              ],
              onFilteredCountChanged: _publishTableCounts,
            ),
          ),
        ],
      ),
    );
  }

  /// Publishes the desktop table's filtered row [count] to
  /// [LayrzScaffoldShell.controller] (the scaffold controller), so a consumer
  /// using only [LayrzScaffoldController] — not
  /// [LayrzScaffoldShell.tableController] — still gets correct
  /// [LayrzScaffoldController.totalCount]/[LayrzScaffoldController.filteredCount]
  /// values while the wide/table layout is showing.
  ///
  /// [count] is [LayrzTable]'s own filtered+sorted row count; [total] is always
  /// [_cachedTableRows]'s length, which is `widget.items.length` unwrapped
  /// one-to-one (no filtering applied), so it matches exactly what
  /// [ListPanel] reports as `total` for the narrow/split layout — keeping the
  /// reported total consistent across both layouts.
  ///
  /// `LayrzTable` never invokes [LayrzTable.onFilteredCountChanged]
  /// synchronously during its owner's build (it defers its first report to a
  /// post-frame callback internally), so this can call
  /// [LayrzScaffoldController.updateCounts] directly; the `mounted` guard only
  /// protects against this shell having been unmounted by the time the
  /// callback runs.
  void _publishTableCounts(int count) {
    if (!mounted) return;
    widget.controller.updateCounts(total: _cachedTableRows.length, filtered: count);
  }

  /// Resolves the table row's data object [data] back to its owning
  /// [LayrzScaffoldItem] and fires [LayrzScaffoldShell.onItemTap] for it, if any.
  ///
  /// The lookup is by identity of the underlying data object: the table renders
  /// exactly the same [T] instances the shell was handed (unwrapped in
  /// [_buildDefaultTable]), so the first item whose `.item` is identical to
  /// [data] is the one that produced this row. A caller with no [onItemTap]
  /// leaves the open button inert.
  void _openFromTable(T data) {
    final onItemTap = widget.onItemTap;
    if (onItemTap == null) return;
    for (final item in widget.items) {
      if (identical(item.item, data)) {
        onItemTap(item);
        return;
      }
    }
  }

  Widget _buildNarrowLayout(BuildContext context, LayrzTokens tokens) {
    // Always show the list panel on narrow layouts. The narrow header renders
    // the title as-is — no close button, since the sheet has its own dismiss.
    final panel = ListPanel<T>(
      items: widget.items,
      openedKey: widget.controller.openedKey,
      controller: widget.controller,
      onTap: widget.onItemTap,
      searchable: widget.searchable,
      footer: widget.footer,
      title: widget.title,
      itemExtent: _itemExtent,
      emptyState: widget.emptyState,
      onRefresh: widget.onRefresh,
      refreshController: widget.refreshController,
    );

    // Schedule the sheet presentation in a post-frame callback to avoid building during build.
    // Only schedule if controller is open and no sheet is already open.
    if (widget.controller.isOpen && !_sheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNarrowDetailSheet(context);
        }
      });
    }

    return panel;
  }

  /// Shows the detail sheet for narrow layouts.
  ///
  /// Opens a LayrzBottomSheet rendering [LayrzScaffoldController.openedBuilder].
  /// Handles the case where the controller closes (or is re-opened with a null
  /// builder, which cannot happen through [LayrzScaffoldController.open] but is
  /// guarded defensively) while the sheet is still open, and manages dismissal to
  /// close the controller (unless the shell initiated the pop via band transition).
  Future<void> _showNarrowDetailSheet(BuildContext context) async {
    // Guard: if sheet is already open, do not open again (prevents stacking)
    if (_sheetOpen) return;

    // Reset the shell-dismissal flag so a stale value doesn't leak across presentations
    _dismissedByShell = false;

    // Mark the sheet as open before checking anything else
    _sheetOpen = true;

    // Guard: check if the ROOT Navigator is reachable -- LayrzBottomSheet.show
    // always pushes there intrinsically, so this must validate the same
    // Navigator it pushes to. Checking the nearest one instead would pass
    // here and still throw at the push if only a nested Navigator exists
    // with no root above it (impossible under LayrzApp in practice, but the
    // guard should not claim success for a Navigator it isn't actually
    // going to use).
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) {
      assert(
        false,
        'LayrzScaffoldShell on narrow breakpoints requires a Navigator ancestor '
        '(e.g., inside LayrzApp) to present the detail sheet. No Navigator found in context.',
      );
      _sheetOpen = false;
      return;
    }

    // If there is no detail content to show, close the controller instead of
    // presenting an empty sheet.
    if (widget.controller.openedBuilder == null) {
      _sheetOpen = false;
      if (mounted) {
        widget.controller.close();
      }
      return;
    }

    // Show the sheet
    //
    // LayrzBottomSheet.show always pushes on the root Navigator intrinsically,
    // which is exactly what this shell needs: it is meant to be composed under
    // an app shell that owns its own nested Navigator (e.g. go_router's
    // ShellRoute -- "All ShellRoutes build a Navigator by default. Child
    // GoRoutes are placed onto this Navigator instead of the root Navigator.")
    // sitting inside a LayrzLayout ancestor. Pushing to the nearest Navigator
    // would resolve to that nested one, whose Overlay is a descendant of
    // LayrzLayout's own SelectableRegion -- so the sheet's content would be a
    // genuine widget-tree descendant of the page's selection scope, and a
    // double-tap physically on the sheet's own text could resolve against a
    // page-body row behind it instead. That nested Overlay would also be
    // bounded by LayrzLayout's body, not the full physical screen, so the
    // sheet's own barrier could not cover LayrzLayout's own chrome (e.g. the
    // narrow-mode top bar) either -- a tap on that chrome while the sheet is
    // open would reach the chrome's own controls instead of being blocked by
    // the modal scrim. Pushing to the root Navigator escapes both: the sheet's
    // Overlay entry sits above LayrzLayout entirely, genuinely outside its
    // SelectableRegion and genuinely covering the full screen. A modal sheet
    // belongs above the app's chrome, not nested inside the page's own
    // subtree, independent of either symptom.
    await LayrzBottomSheet.show<void>(
      context,
      builder: (sheetContext) {
        _narrowSheetContext = sheetContext;
        return ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _itemsChangeNotifier]),
          builder: (context, _) {
            final openedBuilder = widget.controller.openedBuilder;
            if (openedBuilder == null) {
              // The controller closed (or was re-opened with nothing to show) while
              // the sheet is genuinely still open; pop the sheet in the next frame.
              // Guarding on `_sheetOpen` (not just context-mounted) matters: this
              // `ListenableBuilder` stays mounted for the sheet route's own exit
              // animation, so a user-initiated dismiss (barrier tap / drag) reaches
              // here too — via `widget.controller.close()` notifying this same
              // listenable while the route animates out. At that point `_sheetOpen`
              // is already false (set right after the dismiss's
              // `await LayrzBottomSheet.show` resolves, before this rebuild runs), so
              // it is a clean discriminator between "still open, must pop" and
              // "already closing, must not pop again" — unlike context.mounted, which
              // stays true throughout the exit animation either way.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _sheetOpen && _narrowSheetContext != null && _narrowSheetContext!.mounted) {
                  Navigator.of(_narrowSheetContext!).pop();
                }
              });
              return const SizedBox.shrink();
            }
            return DetailPane(
              builder: openedBuilder,
            );
          },
        );
      },
    );

    // Mark the sheet as closed
    _sheetOpen = false;

    // When the sheet is dismissed (user dragged down, tapped barrier, etc.),
    // close the controller to match the screen state — unless the shell initiated
    // the pop (band transition). In that case, the selection should be preserved.
    if (_dismissedByShell) {
      _dismissedByShell = false;
    } else {
      if (mounted) {
        widget.controller.close();
      }
    }
  }
}

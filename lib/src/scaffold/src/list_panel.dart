import "package:flutter/widgets.dart";
import "package:layrz_ui/src/constants/constants.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/inputs/inputs.dart";
import "package:layrz_ui/src/refresh/refresh.dart";
import "package:layrz_ui/src/tokens/src/tokens.dart";

import "list_panel_refresh_footer.dart";
import "scaffold_controller.dart";
import "scaffold_item.dart";
import "scaffold_row.dart";

/// The left list panel of the scaffold shell.
///
/// Renders the search header, filtered list of items, footer, and empty states.
/// The panel owns search state and filtering logic internally.
class ListPanel<T> extends StatefulWidget {
  /// The items to display.
  final List<LayrzScaffoldItem<T>> items;

  /// The key of the currently opened item, or null.
  final Key? openedKey;

  /// The shell's controller, used to publish [LayrzScaffoldController.totalCount] and
  /// [LayrzScaffoldController.filteredCount] each time this panel recomputes its
  /// filtered items. Optional so the panel remains constructible standalone (e.g. in
  /// existing tests) without a controller; when null, counts are simply not published.
  final LayrzScaffoldController? controller;

  /// Callback when an item is tapped.
  final ValueChanged<LayrzScaffoldItem<T>>? onTap;

  /// Whether the search field is visible.
  final bool searchable;

  /// Optional footer widget.
  final Widget? footer;

  /// Optional title
  final Widget? title;

  /// Item extent for the list panel.
  final double itemExtent;

  /// Optional widget to display when the list is empty.
  ///
  /// If null, a localized default message is displayed.
  final Widget? emptyState;

  /// The panel's fixed width, in logical pixels.
  ///
  /// If null, the panel uses its default width of [kLayrzScaffoldListWidth]. A
  /// fold-aware layout passes the leading pane's extent (mapped from the
  /// physical seam) here instead, so the list panel occupies exactly the space
  /// up to the crease rather than its usual fixed width.
  final double? width;

  /// Called to refresh the list's data, or null to disable the refresh affordance.
  ///
  /// When non-null:
  /// - The list's own scrollable is wrapped in a [LayrzRefreshIndicator] (drag
  ///   gesture and pull visual only — its built-in fallback button is disabled,
  ///   since this panel supplies its own always-visible affordance instead; see
  ///   [ListPanelRefreshFooter]).
  /// - A [ListPanelRefreshFooter] renders in the footer region, alongside
  ///   [footer] rather than replacing it, giving every platform (not just
  ///   touch) a reachable refresh control.
  ///
  /// When null (the default), neither the indicator nor the footer affordance
  /// is built at all — fully backward compatible with existing callers.
  final Future<void> Function()? onRefresh;

  /// Optional controller driving the [LayrzRefreshIndicator] wrapping the
  /// list's scrollable, and the [ListPanelRefreshFooter]'s busy state.
  ///
  /// Ignored when [onRefresh] is null. If null while [onRefresh] is non-null,
  /// [LayrzRefreshIndicator] creates and owns its own internal controller —
  /// see [LayrzRefreshIndicator.controller]. Pass an explicit controller to
  /// also trigger a refresh programmatically from outside this panel (e.g. a
  /// keyboard shortcut or another part of the app), via
  /// [LayrzRefreshController.refresh].
  final LayrzRefreshController? refreshController;

  /// Creates a new [ListPanel].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [openedKey]: The key of the currently opened item, or null. Required.
  /// - [controller]: The shell's controller, used to publish item counts. Defaults to
  ///   null, which simply skips publishing counts.
  /// - [onTap]: Callback when an item is tapped. Required.
  /// - [searchable]: Whether to show the search field. Defaults to true.
  /// - [footer]: Optional footer widget. Defaults to null.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The item extent for the list panel. Required.
  /// - [emptyState]: Optional widget to display when the list is empty. Defaults to null.
  /// - [width]: The panel's fixed width, in logical pixels. Defaults to null, which
  ///   keeps the panel's default width of [kLayrzScaffoldListWidth].
  /// - [onRefresh]: Called to refresh the list's data, or null (the default) to
  ///   disable the refresh affordance entirely.
  /// - [refreshController]: Optional controller for the refresh lifecycle. Defaults
  ///   to null, ignored unless [onRefresh] is also non-null.
  const ListPanel({
    super.key,
    required this.items,
    required this.openedKey,
    this.controller,
    this.onTap,
    this.searchable = true,
    this.footer,
    this.title,
    required this.itemExtent,
    this.emptyState,
    this.width,
    this.onRefresh,
    this.refreshController,
  });

  @override
  State<ListPanel<T>> createState() => _ListPanelState<T>();
}

class _ListPanelState<T> extends State<ListPanel<T>> {
  late TextEditingController _searchController;

  /// Filtered items based on the current search query.
  List<LayrzScaffoldItem<T>> _filteredItems = [];

  /// This panel's own [LayrzRefreshController], created only when
  /// [ListPanel.onRefresh] is non-null AND [ListPanel.refreshController] was
  /// left null.
  ///
  /// **Why this panel owns it instead of leaving [LayrzRefreshIndicator] to
  /// create its own internal one** (which is what passing `controller: null`
  /// to it would normally do): the SAME controller instance must drive both
  /// the [LayrzRefreshIndicator] wrapping the list (drag gesture + pull
  /// visual) and the [ListPanelRefreshFooter] in the footer region (the
  /// always-available tap affordance) — otherwise a drag-triggered refresh
  /// would never animate the footer button's spinner, and a footer-triggered
  /// refresh would never animate the pull visual. Owning one shared instance
  /// here, rather than each child creating its own, is what keeps both in
  /// lockstep.
  LayrzRefreshController? _ownedRefreshController;

  /// The controller actually passed to both [LayrzRefreshIndicator] and
  /// [ListPanelRefreshFooter]: [ListPanel.refreshController] if the caller
  /// supplied one, otherwise [_ownedRefreshController], created lazily on
  /// first use and disposed by this state.
  LayrzRefreshController get _effectiveRefreshController {
    final supplied = widget.refreshController;
    if (supplied != null) return supplied;
    return _ownedRefreshController ??= LayrzRefreshController();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_updateFiltered);
    _updateFiltered();
  }

  @override
  void didUpdateWidget(ListPanel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If items changed, reapply filter
    if (oldWidget.items != widget.items) {
      _updateFiltered();
    } else if (oldWidget.controller != widget.controller) {
      // The controller instance itself changed (items and search are unchanged) — still
      // push the already-computed counts to the new controller so it isn't left at 0.
      _publishCounts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Only disposed when this panel created it itself — a caller-supplied
    // widget.refreshController is caller-owned, mirroring
    // LayrzRefreshIndicator's own controller-disposal contract.
    _ownedRefreshController?.dispose();
    super.dispose();
  }

  /// Filter items based on the search query.
  void _updateFiltered() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items
          .where(
            (item) => item.searchableStrings.any(
              (s) => s.toLowerCase().contains(query),
            ),
          )
          .toList();
    }
    setState(() {});
    _publishCounts();
  }

  /// Publishes the current total/filtered item counts to [ListPanel.controller], if any.
  ///
  /// Deferred to a post-frame callback: [_updateFiltered] runs from [initState] (during
  /// this widget's own build), from the search controller's listener, and from
  /// [didUpdateWidget] — all contexts where mutating [LayrzScaffoldController]'s
  /// `ValueNotifier`s synchronously could notify a listener that is itself mid-build
  /// (e.g. a `ValueListenableBuilder` elsewhere in the same frame). Mirrors the same
  /// post-frame-callback discipline `scaffold_shell.dart` already uses for
  /// `_itemsChangeNotifier`.
  void _publishCounts() {
    final controller = widget.controller;
    if (controller == null) return;
    final total = widget.items.length;
    final filtered = _filteredItems.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.updateCounts(total: total, filtered: filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: widget.width ?? kLayrzScaffoldListWidth,
      margin: EdgeInsets.only(top: tokens.spacing.sp1),
      padding: tokens.spacing.pd1,
      color: tokens.colors.sf1,
      child: Column(
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        spacing: tokens.spacing.sp1,
        children: [
          if (widget.title != null) widget.title!,
          if (widget.searchable)
            LayrzSearchInput(
              controller: _searchController,
              hintText: 'Search items',
              dense: true,
              mode: LayrzSearchInputMode.field,
            ),
          Expanded(
            child: _buildListArea(context, tokens),
          ),
          if (_hasFooterRegion) ...[
            Container(height: 1, color: tokens.colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _buildFooterRegion(context),
            ),
          ],
        ],
      ),
    );
  }

  /// Whether the footer region (the hairline plus its padded content) should
  /// render at all — true when either the consumer's own [ListPanel.footer]
  /// or the built-in refresh affordance ([ListPanel.onRefresh] non-null) has
  /// something to show.
  bool get _hasFooterRegion => widget.footer != null || widget.onRefresh != null;

  /// Builds the list's scrollable content, optionally wrapped in a
  /// [LayrzRefreshIndicator] when [ListPanel.onRefresh] is non-null.
  ///
  /// The indicator wraps ONLY this scrollable — not the search field, title,
  /// or footer region above/below it, and never the shell's detail pane —
  /// which is the entire point of a list-level (rather than shell-level)
  /// refresh: nothing floats over content outside the list itself. Its
  /// built-in fallback button is explicitly disabled
  /// ([LayrzRefreshFallbackButtonMode.disabled]): this panel's own
  /// [ListPanelRefreshFooter], rendered in the footer region below, is the
  /// always-available affordance instead — see [ListPanelRefreshFooter]'s own
  /// class doc for why.
  Widget _buildListArea(BuildContext context, LayrzTokens tokens) {
    final list = _filteredItems.isEmpty ? _buildEmptyState(tokens) : _buildListView(context, tokens);

    final onRefresh = widget.onRefresh;
    if (onRefresh == null) {
      return list;
    }

    return LayrzRefreshIndicator(
      onRefresh: onRefresh,
      controller: _effectiveRefreshController,
      fallbackButtonMode: LayrzRefreshFallbackButtonMode.disabled,
      child: list,
    );
  }

  /// Builds the virtualized [ListView] of filtered rows.
  Widget _buildListView(BuildContext context, LayrzTokens tokens) {
    return ListView.builder(
      // Reserves the vertical scrollbar's gutter (LayrzScrollBehavior
      // installs one globally on pointer platforms — see
      // kLayrzScrollbarThickness) so its thumb paints clear of the
      // rows' own content, most visibly the trailing-edge action
      // reveal in ScaffoldRow.
      //
      // This padding MUST live on the ListView itself, not on a
      // Padding wrapped around it. LayrzScrollBehavior installs the
      // RawScrollbar inside the Scrollable (via ScrollConfiguration),
      // so the thumb paints flush against the ListView's own render
      // box, at whatever width that box ends up being. A Padding
      // wrapping the ListView shrinks the Scrollable's box by the
      // same amount it insets the content, so the thumb and the
      // rows' right edge still land on the same X — no gutter is
      // actually created. Passing the padding to ListView.padding
      // keeps the Scrollable/Viewport at the panel's full content
      // width (so the thumb paints at that outer edge) while only
      // the sliver content is inset, leaving a real gap between the
      // rows and the thumb. Mirrors how the calendar's day/week hour
      // grid reserves kLayrzCalendarHourGridEndPadding *inside* its
      // SingleChildScrollView's child instead of around the
      // scrollable — see calendar_day_surface.dart.
      padding: const EdgeInsets.only(right: kLayrzScrollbarThickness),
      itemCount: _filteredItems.length,
      itemExtent: widget.itemExtent,
      itemBuilder: (context, index) {
        return _buildListItem(context, tokens, _filteredItems[index], index);
      },
    );
  }

  /// Builds the footer region's content: the consumer's own [ListPanel.footer]
  /// (if any) alongside the built-in [ListPanelRefreshFooter] (if
  /// [ListPanel.onRefresh] is non-null) — coexisting as siblings in a [Row],
  /// never one replacing the other. When only one of the two is present, that
  /// one alone fills the row (the footer expands to take the remaining
  /// space so its own internal layout, e.g. a results label, is unaffected).
  Widget _buildFooterRegion(BuildContext context) {
    final footer = widget.footer;
    final onRefresh = widget.onRefresh;

    if (footer != null && onRefresh != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: footer),
          ListPanelRefreshFooter(
            controller: _effectiveRefreshController,
            onRefresh: onRefresh,
          ),
        ],
      );
    }

    if (onRefresh != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ListPanelRefreshFooter(
          controller: _effectiveRefreshController,
          onRefresh: onRefresh,
        ),
      );
    }

    return footer!;
  }

  /// Builds the [ScaffoldRow] for [item] at its position ([index]) within the
  /// current filtered/on-screen list.
  ///
  /// [index] is forwarded as [ScaffoldRow.isEvenRow] (`index.isEven`) so the
  /// row can paint the table-matching zebra stripe (`sf1`/`sf2`) — using the
  /// filtered list's index parity rather than the unfiltered [widget.items]
  /// index keeps the stripe matching what the user actually sees on screen.
  Widget _buildListItem(BuildContext context, LayrzTokens tokens, LayrzScaffoldItem<T> item, int index) {
    final isSelected = item.key == widget.openedKey;

    return ScaffoldRow<T>(
      key: item.key,
      item: item,
      isSelected: isSelected,
      isEvenRow: index.isEven,
      onTap: widget.onTap != null ? () => widget.onTap!(item) : null,
    );
  }

  Widget _buildEmptyState(LayrzTokens tokens) {
    if (widget.emptyState != null) {
      return widget.emptyState!;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: SelectionContainer.disabled(
          child: Text(
            context.l10n.scaffoldEmpty,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
          ),
        ),
      ),
    );
  }
}

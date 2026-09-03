import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/inputs/inputs.dart";
import "package:layrz_ui/src/tappable/tappable.dart";
import "package:layrz_ui/src/tokens/src/tokens.dart";

import "scaffold_item.dart";

/// The left list panel of the scaffold shell.
///
/// Renders the search header, filtered list of items, footer, and empty states.
/// The panel owns search state and filtering logic internally.
class ListPanel<T> extends StatefulWidget {
  /// The items to display.
  final List<LayrzScaffoldItem<T>> items;

  /// The key of the currently opened item, or null.
  final Key? openedKey;

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
  /// If null, the panel uses its default width of `300`. A fold-aware layout
  /// passes the leading pane's extent (mapped from the physical seam) here
  /// instead, so the list panel occupies exactly the space up to the crease
  /// rather than its usual fixed width.
  final double? width;

  /// Creates a new [ListPanel].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [openedKey]: The key of the currently opened item, or null. Required.
  /// - [onTap]: Callback when an item is tapped. Required.
  /// - [searchable]: Whether to show the search field. Defaults to true.
  /// - [footer]: Optional footer widget. Defaults to null.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The item extent for the list panel. Required.
  /// - [emptyState]: Optional widget to display when the list is empty. Defaults to null.
  /// - [width]: The panel's fixed width, in logical pixels. Defaults to null, which
  ///   keeps the panel's default width of `300`.
  const ListPanel({
    super.key,
    required this.items,
    required this.openedKey,
    this.onTap,
    this.searchable = true,
    this.footer,
    this.title,
    required this.itemExtent,
    this.emptyState,
    this.width,
  });

  @override
  State<ListPanel<T>> createState() => _ListPanelState<T>();
}

class _ListPanelState<T> extends State<ListPanel<T>> {
  late TextEditingController _searchController;

  /// Filtered items based on the current search query.
  List<LayrzScaffoldItem<T>> _filteredItems = [];

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
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: widget.width ?? 300,
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
            child: _filteredItems.isEmpty
                ? _buildEmptyState(tokens)
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemExtent: widget.itemExtent,
                    itemBuilder: (context, index) {
                      return _buildListItem(context, tokens, _filteredItems[index]);
                    },
                  ),
          ),
          if (widget.footer != null) ...[
            Container(height: 1, color: tokens.colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: widget.footer!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, LayrzTokens tokens, LayrzScaffoldItem<T> item) {
    final isSelected = item.key == widget.openedKey;

    return LayrzTappable(
      disabled: isSelected,
      onTap: widget.onTap != null ? () => widget.onTap!(item) : null,
      borderRadius: tokens.radius.br2,
      color: isSelected ? tokens.colors.sf4 : tokens.colors.sf1,
      child: Padding(
        padding: tokens.spacing.pd2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The tappable tile
            Expanded(child: item.tile),
            if (isSelected) ...[
              // Indicator bar — reserved space always (same width whether selected or not)
              Container(
                width: 3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: tokens.colors.primary,
                  borderRadius: tokens.radius.br3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LayrzTokens tokens) {
    if (widget.emptyState != null) {
      return widget.emptyState!;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Text(
          context.l10n.scaffoldEmpty,
          textAlign: TextAlign.center,
          style: tokens.typography.label.copyWith(color: tokens.colors.fg3),
        ),
      ),
    );
  }
}

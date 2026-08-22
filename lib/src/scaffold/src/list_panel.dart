import "package:flutter/widgets.dart";
import "package:layrz_ui/src/constants/constants.dart";
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

  /// Creates a new [ListPanel].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [openedKey]: The key of the currently opened item, or null. Required.
  /// - [onTap]: Callback when an item is tapped. Required.
  /// - [searchable]: Whether to show the search field. Defaults to true.
  /// - [footer]: Optional footer widget. Defaults to null.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The item extent for the list panel. Required.
  const ListPanel({
    super.key,
    required this.items,
    required this.openedKey,
    this.onTap,
    this.searchable = true,
    this.footer,
    this.title,
    required this.itemExtent,
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
      width: 300,
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

    return Container(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp1),
      // Selected background is sf3; unselected is transparent (no color property)
      color: isSelected ? tokens.colors.sf3 : null,
      child: Row(
        children: [
          // Indicator bar — reserved space always (same width whether selected or not)
          SizedBox(
            width: kLayrzLayoutActiveIndicatorReservedWidth,
            child: isSelected
                ? Container(
                    width: kLayrzLayoutActiveIndicatorWidth,
                    color: tokens.colors.fg1,
                  )
                : null,
          ),
          // The tappable tile
          Expanded(
            child: LayrzTappable(
              onTap: widget.onTap != null ? () => widget.onTap!(item) : null,
              borderRadius: BorderRadius.zero,
              child: item.tile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LayrzTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Text(
          "No items",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: tokens.colors.fg3),
        ),
      ),
    );
  }
}

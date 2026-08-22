import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/inputs/inputs.dart";
import "package:layrz_ui/src/tokens/src/tokens.dart";

import "scaffold_item.dart";

/// The left list panel of the scaffold shell.
///
/// Renders the search header, list of items, footer, and empty states.
class ListPanel<T> extends StatefulWidget {
  /// The items to display.
  final List<LayrzScaffoldItem<T>> items;

  /// Callback to build a tile for each item.
  final Widget Function(T) onBuild;

  /// The currently opened item, or null.
  final T? opened;

  /// Callback when an item is tapped.
  final ValueChanged<T>? onTap;

  /// Callback when search changes.
  final ValueChanged<String>? onSearch;

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
  /// - [onBuild]: Callback to build a tile for each item. Required.
  /// - [opened]: The currently opened item, or null. Required.
  /// - [onTap]: Callback when a row is tapped, or null. Defaults to null.
  /// - [onSearch]: Callback when the search query changes, or null. Defaults to null.
  /// - [searchable]: Whether to show the search field. Defaults to true.
  /// - [footer]: Optional footer widget. Defaults to null.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The item extent for the list panel. Required.
  const ListPanel({
    super.key,
    required this.items,
    required this.onBuild,
    required this.opened,
    this.onTap,
    this.onSearch,
    this.searchable = true,
    this.footer,
    this.title,
    required this.itemExtent,
  });

  @override
  State<ListPanel<T>> createState() => _ListPanelState<T>();
}

class _ListPanelState<T> extends State<ListPanel<T>> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
          if (widget.searchable) LayrzSearchInput(),
          Expanded(
            child: widget.items.isEmpty
                ? _buildEmptyState(tokens)
                : ListView.builder(
                    itemCount: widget.items.length,
                    itemExtent: widget.itemExtent,
                    itemBuilder: (context, index) {
                      return _buildListItem(context, tokens, index);
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

  Widget _buildListItem(BuildContext context, LayrzTokens tokens, int index) {
    final item = widget.items[index];
    final isSelected = identical(widget.opened, item.item);
    final tile = widget.onBuild(item.item);

    return Container(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp1),
      child: tile,
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

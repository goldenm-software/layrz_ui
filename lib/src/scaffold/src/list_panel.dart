import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/tokens/tokens.dart";

import "list_header.dart";
import "list_item.dart";
import "scaffold_tile.dart";

/// The left list panel of the scaffold shell.
///
/// Renders the search header, list of items, footer, and empty states.
class ListPanel<T> extends StatefulWidget {
  /// The items to display.
  final List<T> items;

  /// Callback to build a tile for each item.
  final LayrzScaffoldTile Function(BuildContext, T) onBuild;

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

  /// Creates a new [ListPanel].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [onBuild]: Callback to build a tile for each item. Required.
  /// - [opened]: The currently opened item, or null. Required.
  /// - [onTap]: Callback when a row is tapped, or null. Defaults to null.
  /// - [onSearch]: Callback when the search query changes, or null. Defaults to null.
  /// - [searchable]: Whether to show the search field. Defaults to true.
  /// - [footer]: Optional footer widget. Defaults to null.
  const ListPanel({
    super.key,
    required this.items,
    required this.onBuild,
    required this.opened,
    this.onTap,
    this.onSearch,
    this.searchable = true,
    this.footer,
  });

  @override
  State<ListPanel<T>> createState() => _ListPanelState<T>();
}

class _ListPanelState<T> extends State<ListPanel<T>> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: 250,
      color: tokens.colors.sf1,
      child: Column(
        children: [
          ListHeader(
            searchable: widget.searchable,
            onSearch: widget.onSearch,
          ),
          Expanded(
            child: widget.items.isEmpty
                ? _buildEmptyState(tokens)
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          for (int i = 0; i < widget.items.length; i++) _buildListItem(context, tokens, i),
                        ],
                      ),
                    ),
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
    final tile = widget.onBuild(context, item);
    final isSelected = identical(widget.opened, item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: ListItem(
        tile: tile,
        isSelected: isSelected,
        onTap: () => widget.onTap?.call(item),
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

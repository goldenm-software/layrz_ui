import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'group_header.dart';
import 'group_mode.dart';
import 'list_header.dart';
import 'list_item.dart';
import 'scaffold_item.dart';

/// Private list panel widget.
class ListPanel extends StatefulWidget {
  /// The list of items to display in the panel.
  final List<LayrzScaffoldItem> items;

  /// The ID of the currently selected item.
  final String? selectedId;

  /// Callback fired when the user selects an item.
  final ValueChanged<String> onSelected;

  /// Controller for the filter text field.
  final TextEditingController filterController;

  /// The current group mode (grouped or flat).
  final LayrzScaffoldGroupMode groupMode;

  /// Callback fired when the group mode is changed.
  final ValueChanged<LayrzScaffoldGroupMode> onGroupModeChanged;

  /// Optional title for the list panel.
  final String? listTitle;

  /// Whether the list panel includes a search/filter field.
  final bool searchable;

  /// Optional footer widget for the list panel.
  final Widget? footer;

  /// Creates a new [ListPanel].
  const ListPanel({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.filterController,
    required this.groupMode,
    required this.onGroupModeChanged,
    this.listTitle,
    required this.searchable,
    this.footer,
  });

  @override
  State<ListPanel> createState() => _ListPanelState();
}

class _ListPanelState extends State<ListPanel> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final query = widget.filterController.text.toLowerCase();

    final filtered = widget.items.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query);
      final subtitleMatch = (item.subtitle ?? '').toLowerCase().contains(query);
      return titleMatch || subtitleMatch;
    }).toList();

    final hasGroupedItems = widget.items.any((item) => item.group != null);

    return Container(
      color: t.colors.surface,
      child: Flex(
        direction: Axis.vertical,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: t.colors.divider, width: 1),
              ),
            ),
            child: ListHeader(
              title: widget.listTitle,
              itemCount: filtered.length,
              hasGroupedItems: hasGroupedItems,
              groupMode: widget.groupMode,
              onGroupModeChanged: widget.onGroupModeChanged,
              searchable: widget.searchable,
              filterController: widget.filterController,
              onFilterChanged: () => setState(() {}),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: filtered.isEmpty
                  ? ListBodyEmpty(query: query)
                  : ListBody(
                      items: filtered,
                      selectedId: widget.selectedId,
                      onSelected: widget.onSelected,
                      groupMode: widget.groupMode,
                    ),
            ),
          ),
          if (widget.footer != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: t.colors.divider, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: kLayrzScaffoldFooterVerticalPadding,
                horizontal: kLayrzScaffoldFooterHorizontalPadding,
              ),
              child: widget.footer,
            ),
        ],
      ),
    );
  }
}

/// Private list body widget.
class ListBody extends StatelessWidget {
  /// The list of items to display.
  final List<LayrzScaffoldItem> items;

  /// The ID of the currently selected item.
  final String? selectedId;

  /// Callback fired when the user selects an item.
  final ValueChanged<String> onSelected;

  /// The current group mode (grouped or flat).
  final LayrzScaffoldGroupMode groupMode;

  /// Creates a new [ListBody].
  const ListBody({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.groupMode,
  });

  @override
  Widget build(BuildContext context) {
    if (groupMode == LayrzScaffoldGroupMode.flat) {
      return Padding(
        padding: const EdgeInsets.all(kLayrzScaffoldBodyPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              ListItem(
                item: items[i],
                isSelected: items[i].id == selectedId,
                onTap: () => onSelected(items[i].id),
              ),
              if (i < items.length - 1) SizedBox(height: kLayrzScaffoldBodyGap),
            ],
          ],
        ),
      );
    }

    final grouped = <String?, List<LayrzScaffoldItem>>{};
    for (final item in items) {
      if (!grouped.containsKey(item.group)) {
        grouped[item.group] = [];
      }
      grouped[item.group]!.add(item);
    }

    final sortedKeys = [
      ...grouped.keys.where((k) => k != null).toList()..sort(),
      null,
    ];

    final children = <Widget>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final groupItems = grouped[key]!;
      if (key != null) {
        children.add(GroupHeader(groupName: key));
      }
      for (int j = 0; j < groupItems.length; j++) {
        children.add(
          ListItem(
            item: groupItems[j],
            isSelected: groupItems[j].id == selectedId,
            onTap: () => onSelected(groupItems[j].id),
          ),
        );
        if (j < groupItems.length - 1) {
          children.add(SizedBox(height: kLayrzScaffoldBodyGap));
        }
      }
      if (i < sortedKeys.length - 1) {
        children.add(SizedBox(height: kLayrzScaffoldBodyGap));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(kLayrzScaffoldBodyPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Private empty state widget for list body.
class ListBodyEmpty extends StatelessWidget {
  /// The search query that resulted in no matches.
  final String query;

  /// Creates a new [ListBodyEmpty].
  const ListBodyEmpty({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kLayrzScaffoldEmptyStateVerticalPadding,
        horizontal: kLayrzScaffoldEmptyStateHorizontalPadding,
      ),
      child: Text(
        'No items match "$query"',
        style: TextStyle(
          fontSize: kLayrzScaffoldEmptyStateFontSize,
          color: t.colors.fg3,
        ),
      ),
    );
  }
}

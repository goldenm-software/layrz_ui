import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'group_mode.dart';
import 'scaffold_item.dart';

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
/// On wide containers (md, lg, xl breakpoints), the list panel (250px) and detail pane
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), a single pane
/// is shown: the list by default, and the detail after selection. The shell owns the layout,
/// visibility, and state; the consuming app owns which item is selected.
///
/// **Core contract:**
/// - The consuming app passes [items] and [selectedId], and receives [onSelected] callbacks.
/// - The shell owns the filter query, group mode, and detail visibility on narrow containers.
/// - The [contentBuilder] callback receives the selected item and returns the detail widget.
///
/// **Narrow-mode behaviour:**
/// - When no item is selected ([selectedId] is null), the list is shown.
/// - When an item is selected ([selectedId] is non-null), the detail is shown.
/// - A back affordance in the detail header returns to the list without modifying [selectedId].
/// - This is a pure state transition, not a navigation operation (no [Navigator] calls).
///
/// **Filtering and grouping:**
/// - The filter query is applied case-insensitively as a substring match over [title] and [subtitle].
/// - The group mode toggle is rendered only when at least one item has a non-null [group].
/// - When no items match the filter, an empty state is shown quoting the active query.
class LayrzScaffoldShell extends StatefulWidget {
  /// Creates a new [LayrzScaffoldShell].
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.contentBuilder,
    this.listTitle,
    this.footer,
    this.detailActions = const [],
    this.detailTitle,
    this.detailSubtitle,
    this.searchable = true,
    this.initialGroupMode = LayrzScaffoldGroupMode.grouped,
  });

  /// The list of items to display in the list panel.
  ///
  /// When empty, the list shows as empty. When the filter query matches no items,
  /// the empty state is shown. Otherwise, the matching items are displayed.
  final List<LayrzScaffoldItem> items;

  /// The [id] of the currently selected item.
  ///
  /// When null or matching no item, the detail pane shows an empty state.
  /// When non-null and matching an item, the detail pane shows the result
  /// of [contentBuilder] called with the selected item.
  /// Owned by the consuming app; changes are reported via [onSelected].
  final String? selectedId;

  /// Callback fired when the user selects an item in the list panel.
  ///
  /// The callback receives the [id] of the selected item. The consuming app
  /// is responsible for updating [selectedId] in response.
  final ValueChanged<String> onSelected;

  /// Builds the detail widget for the currently selected item.
  ///
  /// Called with the selected [LayrzScaffoldItem]. The returned widget is displayed
  /// in the detail pane. When [selectedId] is null or matches no item, the detail pane
  /// shows an empty state and this callback is not called.
  final Widget Function(BuildContext, LayrzScaffoldItem) contentBuilder;

  /// Optional title for the list panel.
  ///
  /// When non-null, this title is displayed in the list header above the filter field.
  /// Defaults to null.
  final String? listTitle;

  /// Optional footer widget for the list panel.
  ///
  /// When non-null, this widget is displayed in a footer section below the list body.
  /// The footer receives 1px divider above it, padding, and is scrolled with the panel.
  /// Defaults to null.
  final Widget? footer;

  /// List of action widgets to display in the detail pane header.
  ///
  /// These widgets are right-aligned in the detail header, after the title/subtitle block.
  /// Useful for edit, delete, or other item-specific actions. Defaults to an empty list.
  final List<Widget> detailActions;

  /// Optional title to override the selected item's title in the detail header.
  ///
  /// When non-null, this title is displayed instead of [LayrzScaffoldItem.title].
  /// When null, the selected item's [title] is displayed. Defaults to null.
  final String? detailTitle;

  /// Optional subtitle to display in the detail header.
  ///
  /// When non-null, this subtitle is displayed below the detail title.
  /// Defaults to null.
  final String? detailSubtitle;

  /// Whether the list panel includes a search/filter field.
  ///
  /// When true, the filter field is rendered in the list header, allowing the user
  /// to narrow the list by substring match over [title] and [subtitle].
  /// When false, the filter field is hidden. Defaults to true.
  final bool searchable;

  /// The initial group mode for the list panel.
  ///
  /// Sets the default arrangement of items (grouped vs. flat). The user can toggle
  /// this if at least one item has a non-null [group]. Defaults to [LayrzScaffoldGroupMode.grouped].
  final LayrzScaffoldGroupMode initialGroupMode;

  @override
  State<LayrzScaffoldShell> createState() => _LayrzScaffoldShellState();
}

class _LayrzScaffoldShellState extends State<LayrzScaffoldShell> {
  late TextEditingController _filterController;
  late LayrzScaffoldGroupMode _groupMode;
  late bool _showDetailOnNarrow;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
    _groupMode = widget.initialGroupMode;
    _showDetailOnNarrow = false;
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGroupMode != widget.initialGroupMode) {
      _groupMode = widget.initialGroupMode;
    }
    if (oldWidget.selectedId != widget.selectedId && widget.selectedId == null) {
      _showDetailOnNarrow = false;
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final band = context.tokens.breakpoints.bandAt(constraints.maxWidth);
        final isNarrow = band == LayrzBreakpoint.xs || band == LayrzBreakpoint.sm;

        return Flex(
          direction: Axis.horizontal,
          children: [
            if (isNarrow && _showDetailOnNarrow)
              Expanded(
                child: _buildDetailPane(context, isNarrow),
              )
            else if (!isNarrow)
              SizedBox(
                width: kLayrzScaffoldListWidth,
                child: _buildListPanel(context),
              )
            else
              Expanded(
                child: _buildListPanel(context),
              ),
            if (!isNarrow)
              Expanded(
                child: _buildDetailPane(context, isNarrow),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListPanel(BuildContext context) {
    return _ListPanel(
      items: widget.items,
      selectedId: widget.selectedId,
      onSelected: (id) {
        widget.onSelected(id);
        setState(() => _showDetailOnNarrow = true);
      },
      filterController: _filterController,
      groupMode: _groupMode,
      onGroupModeChanged: (mode) => setState(() => _groupMode = mode),
      listTitle: widget.listTitle,
      searchable: widget.searchable,
      footer: widget.footer,
    );
  }

  Widget _buildDetailPane(BuildContext context, bool isNarrow) {
    final selectedItem = widget.items.cast<LayrzScaffoldItem?>().firstWhere(
      (item) => item?.id == widget.selectedId,
      orElse: () => null,
    );

    return _DetailPane(
      selectedItem: selectedItem,
      contentBuilder: selectedItem == null ? null : (ctx) => widget.contentBuilder(ctx, selectedItem),
      onBack: () => setState(() => _showDetailOnNarrow = false),
      detailTitle: widget.detailTitle ?? selectedItem?.title,
      detailSubtitle: widget.detailSubtitle,
      detailActions: widget.detailActions,
      showBack: isNarrow,
    );
  }
}

class _ListPanel extends StatefulWidget {
  final List<LayrzScaffoldItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final TextEditingController filterController;
  final LayrzScaffoldGroupMode groupMode;
  final ValueChanged<LayrzScaffoldGroupMode> onGroupModeChanged;
  final String? listTitle;
  final bool searchable;
  final Widget? footer;

  const _ListPanel({
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
  State<_ListPanel> createState() => _ListPanelState();
}

class _ListPanelState extends State<_ListPanel> {
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
            child: _ListHeader(
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
                  ? _EmptyState(query: query)
                  : _ListBody(
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

class _DetailPane extends StatelessWidget {
  final LayrzScaffoldItem? selectedItem;
  final Widget Function(BuildContext)? contentBuilder;
  final VoidCallback onBack;
  final String? detailTitle;
  final String? detailSubtitle;
  final List<Widget> detailActions;
  final bool showBack;

  const _DetailPane({
    required this.selectedItem,
    required this.contentBuilder,
    required this.onBack,
    required this.detailTitle,
    required this.detailSubtitle,
    required this.detailActions,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (selectedItem == null || contentBuilder == null) {
      return Container(
        color: t.colors.surface,
        child: const Center(
          child: Text('No item selected'),
        ),
      );
    }

    return Container(
      color: t.colors.surface,
      child: Flex(
        direction: Axis.vertical,
        children: [
          _DetailHeader(
            title: detailTitle,
            subtitle: detailSubtitle,
            actions: detailActions,
            onBack: showBack ? onBack : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kLayrzScaffoldDetailBodyPadding),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kLayrzScaffoldDetailMaxWidth,
                    ),
                    child: contentBuilder!(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Private list header widget.
class _ListHeader extends StatefulWidget {
  final String? title;
  final int itemCount;
  final bool hasGroupedItems;
  final LayrzScaffoldGroupMode groupMode;
  final ValueChanged<LayrzScaffoldGroupMode> onGroupModeChanged;
  final bool searchable;
  final TextEditingController filterController;
  final VoidCallback onFilterChanged;

  const _ListHeader({
    required this.title,
    required this.itemCount,
    required this.hasGroupedItems,
    required this.groupMode,
    required this.onGroupModeChanged,
    required this.searchable,
    required this.filterController,
    required this.onFilterChanged,
  });

  @override
  State<_ListHeader> createState() => _ListHeaderState();
}

class _ListHeaderState extends State<_ListHeader> {
  late FocusNode _filterFocusNode;

  @override
  void initState() {
    super.initState();
    _filterFocusNode = FocusNode();
    widget.filterController.addListener(widget.onFilterChanged);
  }

  @override
  void dispose() {
    _filterFocusNode.dispose();
    widget.filterController.removeListener(widget.onFilterChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kLayrzScaffoldHeaderHorizontalPadding,
        kLayrzScaffoldHeaderTopPadding,
        kLayrzScaffoldHeaderHorizontalPadding,
        kLayrzScaffoldHeaderBottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null || widget.hasGroupedItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: kLayrzScaffoldHeaderTitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: t.colors.fg1,
                        ),
                      ),
                    ),
                  if (widget.title != null)
                    Text(
                      widget.itemCount.toString(),
                      style: TextStyle(
                        fontSize: kLayrzScaffoldHeaderCountFontSize,
                        color: t.colors.fg3,
                      ),
                    ),
                  if (widget.hasGroupedItems) ...[
                    const SizedBox(width: kLayrzScaffoldHeaderGap),
                    _GroupToggle(
                      groupMode: widget.groupMode,
                      onChanged: widget.onGroupModeChanged,
                    ),
                  ],
                ],
              ),
            ),
          if (widget.searchable)
            _FilterField(
              controller: widget.filterController,
              focusNode: _filterFocusNode,
            ),
        ],
      ),
    );
  }
}

/// Private filter field widget.
class _FilterField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _FilterField({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return SizedBox(
      height: kLayrzScaffoldFilterHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colors.surface2,
          border: Border.all(color: t.colors.divider, width: 1),
          borderRadius: BorderRadius.circular(kLayrzScaffoldFilterHeight / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kLayrzScaffoldFilterHorizontalPadding,
          ),
          child: Row(
            children: [
              Icon(
                LayrzIcons.solarBoldMagnifer,
                size: kLayrzScaffoldFilterIconSize,
                color: t.colors.fg3,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: EditableText(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontSize: kLayrzScaffoldFilterFontSize,
                    color: t.colors.fg1,
                  ),
                  cursorColor: t.colors.primary,
                  backgroundCursorColor: t.colors.surface2,
                  selectionColor: t.colors.primary.withOpacityValue(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private group toggle widget.
class _GroupToggle extends StatelessWidget {
  final LayrzScaffoldGroupMode groupMode;
  final ValueChanged<LayrzScaffoldGroupMode> onChanged;

  const _GroupToggle({
    required this.groupMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: t.colors.surface3,
        borderRadius: BorderRadius.circular(kLayrzScaffoldToggleBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: LayrzIcons.solarBoldLayers,
            isActive: groupMode == LayrzScaffoldGroupMode.grouped,
            onTap: () => onChanged(LayrzScaffoldGroupMode.grouped),
          ),
          _ToggleSegment(
            icon: LayrzIcons.solarBoldList,
            isActive: groupMode == LayrzScaffoldGroupMode.flat,
            onTap: () => onChanged(LayrzScaffoldGroupMode.flat),
          ),
        ],
      ),
    );
  }
}

/// Private toggle segment widget.
class _ToggleSegment extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? t.colors.surface : null,
          borderRadius: BorderRadius.circular(kLayrzScaffoldToggleBorderRadius - 2),
          boxShadow: isActive ? t.shadow.compact1 : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kLayrzScaffoldToggleSegmentHorizontalPadding,
          vertical: kLayrzScaffoldToggleSegmentVerticalPadding,
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? t.colors.primary : t.colors.fg2,
        ),
      ),
    );
  }
}

/// Private list item widget.
class _ListItem extends StatefulWidget {
  final LayrzScaffoldItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final item = widget.item;

    final backgroundColor = widget.isSelected
        ? t.colors.primary.withOpacityValue(
            kLayrzScaffoldListItemSelectedRowBackgroundOpacity,
          )
        : (_isHovered
              ? t.colors.primary.withOpacityValue(
                  kLayrzScaffoldListItemHoverBackgroundOpacity,
                )
              : null);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(kLayrzScaffoldListItemRadius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: kLayrzScaffoldListItemVerticalPadding,
            horizontal: kLayrzScaffoldListItemHorizontalPadding,
          ),
          child: Row(
            children: [
              _IconTile(
                icon: item.icon,
                isSelected: widget.isSelected,
                tint: item.tint,
              ),
              const SizedBox(width: kLayrzScaffoldListItemGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: kLayrzScaffoldListItemLabelFontSize,
                        fontWeight:
                            FontWeight.values[(widget.isSelected
                                    ? kLayrzScaffoldListItemSelectedLabelFontWeight
                                    : kLayrzScaffoldListItemUnselectedLabelFontWeight)
                                .toInt()],
                        color: widget.isSelected ? t.colors.primary : t.colors.fg1,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: kLayrzScaffoldListItemMetaFontSize,
                          color: t.colors.fg3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private icon tile widget.
class _IconTile extends StatelessWidget {
  final IconData? icon;
  final bool isSelected;
  final Color? tint;

  const _IconTile({
    required this.icon,
    required this.isSelected,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final tileColor = isSelected
        ? t.colors.primary.withOpacityValue(
            kLayrzScaffoldListItemSelectedIconTileBackgroundOpacity,
          )
        : (tint ?? t.colors.surface3);

    return Container(
      width: kLayrzScaffoldListItemIconTileSize,
      height: kLayrzScaffoldListItemIconTileSize,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(kLayrzScaffoldListItemIconTileRadius),
      ),
      child: icon == null
          ? const SizedBox.shrink()
          : Center(
              child: Icon(
                icon,
                size: kLayrzScaffoldListItemIconSize,
                color: isSelected ? t.colors.primary : t.colors.fg3,
              ),
            ),
    );
  }
}

/// Private group header widget.
class _GroupHeader extends StatelessWidget {
  final String groupName;

  const _GroupHeader({required this.groupName});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      color: t.colors.surface2,
      padding: const EdgeInsets.symmetric(
        vertical: kLayrzScaffoldGroupHeaderVerticalPadding,
        horizontal: kLayrzScaffoldGroupHeaderHorizontalPadding,
      ),
      child: Text(
        groupName,
        style: TextStyle(
          fontSize: kLayrzScaffoldGroupHeaderFontSize,
          fontWeight: FontWeight.w600,
          color: t.colors.fg3,
          letterSpacing: kLayrzScaffoldGroupHeaderLetterSpacing * kLayrzScaffoldGroupHeaderFontSize,
        ),
      ),
    );
  }
}

/// Private detail header widget.
class _DetailHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: t.colors.surface,
        border: Border(
          bottom: BorderSide(color: t.colors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kLayrzScaffoldDetailHeaderVerticalPadding,
        horizontal: kLayrzScaffoldDetailHeaderHorizontalPadding,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LayrzIcons.solarBoldArrowLeft,
                  size: 20,
                  color: t.colors.fg1,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: kLayrzScaffoldDetailHeaderTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: t.colors.fg1,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: kLayrzScaffoldDetailHeaderSubtitleFontSize,
                      color: t.colors.fg3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: kLayrzScaffoldDetailHeaderGap),
            Wrap(
              spacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// Private list body widget.
class _ListBody extends StatelessWidget {
  final List<LayrzScaffoldItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final LayrzScaffoldGroupMode groupMode;

  const _ListBody({
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
              _ListItem(
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
        children.add(_GroupHeader(groupName: key));
      }
      for (int j = 0; j < groupItems.length; j++) {
        children.add(
          _ListItem(
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

/// Private empty state widget.
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

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

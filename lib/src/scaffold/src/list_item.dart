import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'scaffold_item.dart';

/// Private list item widget.
class ListItem extends StatefulWidget {
  /// The item data to display.
  final LayrzScaffoldItem item;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Callback fired when the item is tapped.
  final VoidCallback onTap;

  /// Creates a new [ListItem].
  const ListItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
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
              IconTile(
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
                        fontWeight: widget.isSelected
                            ? kLayrzScaffoldListItemSelectedLabelFontWeight
                            : kLayrzScaffoldListItemUnselectedLabelFontWeight,
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
class IconTile extends StatelessWidget {
  /// The icon to display, or null for no icon.
  final IconData? icon;

  /// Whether this tile's item is currently selected.
  final bool isSelected;

  /// Optional tint color for the tile background.
  final Color? tint;

  /// Creates a new [IconTile].
  const IconTile({
    super.key,
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

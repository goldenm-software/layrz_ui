import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/menus/menus.dart';

import 'scaffold_tile.dart';

/// Renders a single row in the scaffold list.
///
/// This widget displays a tile's title, subtitle, and actions menu.
/// The row shows selected state via background color and title color change (no geometry change per D15).
///
/// - [tile]: The tile data to render.
/// - [isSelected]: Whether this row is currently selected.
/// - [onTap]: Callback when the row is tapped.
/// - [onActionTap]: Callback when an action is tapped, called with the action item.
class ListItem<T> extends StatefulWidget {
  /// The tile to render.
  final LayrzScaffoldTile tile;

  /// Whether this row is currently selected.
  final bool isSelected;

  /// Callback when the row is tapped to select it.
  final VoidCallback? onTap;

  /// Callback when an action menu item is tapped.
  ///
  /// Called with the tapped [LayrzDropdownItem].
  final ValueChanged<LayrzDropdownItem>? onActionTap;

  /// Creates a new [ListItem].
  ///
  /// - [tile]: The tile to render. Required.
  /// - [isSelected]: Whether this row is selected. Required.
  /// - [onTap]: Callback when tapped, or null. Defaults to null.
  /// - [onActionTap]: Callback for action taps, or null. Defaults to null.
  const ListItem({
    super.key,
    required this.tile,
    required this.isSelected,
    this.onTap,
    this.onActionTap,
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tile = widget.tile;

    final backgroundColor = widget.isSelected
        ? tokens.colors.primary.withValues(alpha: 0.07)
        : _isHovered
        ? tokens.colors.primary.withValues(alpha: 0.04)
        : const Color(0x00000000);

    final titleColor = widget.isSelected ? tokens.colors.primary : tokens.colors.fg1;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [tile.titleRichText],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: titleColor,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tile.subtitleRichText != null) ...[
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [tile.subtitleRichText!],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: tokens.colors.fg3,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (tile.actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                LayrzDropdownMenu(
                  items: tile.actions,
                  builder: (context, controller) {
                    return GestureDetector(
                      onTap: controller.open,
                      child: Icon(
                        MdiIcons.dotsVertical,
                        size: 16,
                        color: tokens.colors.fg3,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

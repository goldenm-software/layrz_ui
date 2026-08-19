import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'navigator_item.dart';

/// A single item row in the rail or drawer.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutRailItem extends StatefulWidget {
  /// Creates a rail item.
  const LayrzLayoutRailItem({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The navigator page data for this item.
    required this.page,

    /// Whether this item is currently selected.
    required this.isSelected,

    /// Callback fired when the item is tapped.
    required this.onTap,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The navigator page data for this item.
  final LayrzNavigatorPage page;

  /// Whether this item is currently selected.
  final bool isSelected;

  /// Callback fired when the item is tapped.
  final VoidCallback onTap;

  @override
  State<LayrzLayoutRailItem> createState() => _LayrzLayoutRailItemState();
}

class _LayrzLayoutRailItemState extends State<LayrzLayoutRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final backgroundColor = widget.isSelected
        ? tokens.colors.primary.withValues(alpha: kLayrzLayoutItemSelectedBackgroundOpacity)
        : _isHovered
        ? tokens.colors.primary.withValues(alpha: kLayrzLayoutItemHoverBackgroundOpacity)
        : const Color(0x00000000);

    final labelColor = widget.isSelected ? tokens.colors.primary : tokens.colors.fg2;
    final labelWeight = widget.isSelected
        ? kLayrzLayoutItemLabelSelectedFontWeight
        : kLayrzLayoutItemLabelUnselectedFontWeight;

    return Container(
      margin: const EdgeInsets.only(bottom: kLayrzLayoutItemMarginBottom),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kLayrzLayoutItemPaddingVertical,
              horizontal: kLayrzLayoutItemPaddingHorizontal,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(kLayrzLayoutItemRadius),
            ),
            child: Row(
              children: [
                // Icon
                if (widget.page.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: kLayrzLayoutItemGap),
                    child: Icon(
                      widget.page.icon,
                      size: kLayrzLayoutItemIconSize,
                      color: widget.isSelected ? tokens.colors.primary : tokens.colors.fg3,
                    ),
                  ),

                // Label
                Expanded(
                  child: Text(
                    widget.page.labelText,
                    style: TextStyle(
                      fontSize: kLayrzLayoutItemLabelFontSize,
                      fontWeight: labelWeight,
                      color: labelColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Count badge
                if (widget.page.count != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      widget.page.count.toString(),
                      style: TextStyle(
                        fontSize: kLayrzLayoutItemCountFontSize,
                        fontWeight: FontWeight.w500,
                        color: tokens.colors.fg2,
                      ),
                    ),
                  ),

                // Reserved space for trailing active indicator bar (width: 6.0 + 3.0 = 9.0)
                SizedBox(width: 6.0),

                // Active indicator bar (reserved space even when inactive)
                Container(
                  width: kLayrzLayoutActiveIndicatorWidth,
                  height: kLayrzLayoutActiveIndicatorHeight,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? tokens.colors.primary : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(kLayrzLayoutActiveIndicatorWidth / 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

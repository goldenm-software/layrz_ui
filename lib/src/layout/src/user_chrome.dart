import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The user information block displayed in the rail footer or drawer.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutUserChrome extends StatelessWidget {
  /// Creates the user chrome block.
  const LayrzLayoutUserChrome({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The user's display name.
    required this.userName,

    /// The user's avatar source.
    required this.userAvatar,

    /// The menu items displayed when the user chrome block is tapped.
    required this.userMenuItems,

    /// Function to derive initials from a name.
    required this.getInitials,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The user's display name.
  final String? userName;

  /// The user's avatar source.
  final LayrzAvatarSource? userAvatar;

  /// The menu items displayed when the user chrome block is tapped.
  final List<LayrzDropdownItem> userMenuItems;

  /// Function to derive initials from a name.
  final String Function(String?) getInitials;

  @override
  Widget build(BuildContext context) {
    final hasMenu = userMenuItems.isNotEmpty;
    final content = _buildContent(showChevron: hasMenu);

    if (!hasMenu) return content;

    return LayrzDropdownMenu(
      items: userMenuItems,
      builder: (context, controller) => GestureDetector(
        onTap: controller.isOpen ? controller.close : controller.open,
        child: content,
      ),
    );
  }

  /// Builds the shared content for both the static and menu-backed presentations.
  ///
  /// Renders a [Container] with [tokens.colors.surface3] background, [tokens.radius.r2]
  /// border radius, and [tokens.spacing.sp2] padding on all sides. The container holds
  /// a [Row] displaying the user avatar ([LayrzAvatar]), user name ([Text]), and optionally
  /// a chevron icon when [showChevron] is true. This single implementation is used by both
  /// the no-menu presentation (no chevron) and the menu-backed presentation (with chevron),
  /// ensuring visual consistency and avoiding duplication.
  ///
  /// Avatar size and font size scale for compact viewports (xs and sm breakpoints).
  ///
  /// The [showChevron] parameter is true when a menu is present and false otherwise.
  Widget _buildContent({required bool showChevron}) {
    // Use a Builder to access context.isCompact for responsive sizing
    return Builder(
      builder: (context) {
        final isCompact = context.isCompact;
        final avatarSize = isCompact ? kLayrzLayoutCompactUserAvatarSize : kLayrzLayoutUserAvatarSize;
        final fontSize = isCompact ? tokens.typography.body.fontSize : tokens.typography.label.fontSize;
        final iconSize = isCompact ? kLayrzLayoutCompactIconSize : kLayrzLayoutIconSize;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spacing.sp2,
            horizontal: tokens.spacing.sp2,
          ),
          decoration: BoxDecoration(
            color: tokens.colors.surface3,
            borderRadius: BorderRadius.circular(tokens.radius.r2),
          ),
          child: Row(
            children: [
              // Avatar with rounded square shape
              LayrzAvatar(
                source: userAvatar,
                size: avatarSize,
                nameText: userName,
                borderRadius: tokens.radius.r2,
              ),

              SizedBox(width: tokens.spacing.sp2),

              // Name
              Expanded(
                child: userName != null && userName!.isNotEmpty
                    ? Text(
                        userName!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: kLayrzLayoutUserNameFontWeight,
                          color: tokens.colors.fg1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),

              // Chevron (shown only when menu is present)
              if (showChevron) ...[
                SizedBox(width: tokens.spacing.sp2),
                Icon(
                  MdiIcons.chevronUp,
                  size: iconSize,
                  color: tokens.colors.fg3,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

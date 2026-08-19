import 'package:layrz_icons/layrz_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
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

    if (!hasMenu) {
      // No menu: render a static user chrome without interaction
      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: kLayrzLayoutUserChromePaddingVertical,
          horizontal: kLayrzLayoutUserChromePaddingHorizontal,
        ),
        decoration: BoxDecoration(
          color: tokens.colors.surface3,
          borderRadius: BorderRadius.circular(kLayrzLayoutUserChromeRadius),
        ),
        child: Row(
          children: [
            // Avatar
            SizedBox(
              width: kLayrzLayoutUserAvatarSize,
              height: kLayrzLayoutUserAvatarSize,
              child: LayrzAvatar(
                source: userAvatar,
                size: kLayrzLayoutUserAvatarSize,
                nameText: userName,
              ),
            ),

            SizedBox(width: 8.0),

            // Name
            Expanded(
              child: userName != null && userName!.isNotEmpty
                  ? Text(
                      userName!,
                      style: TextStyle(
                        fontSize: kLayrzLayoutUserNameFontSize,
                        fontWeight: kLayrzLayoutUserNameFontWeight,
                        color: tokens.colors.fg1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    // With menu: render via LayrzDropdownMenu
    return LayrzDropdownMenu(
      items: userMenuItems,
      builder: (context, controller) => GestureDetector(
        onTap: controller.isOpen ? controller.close : controller.open,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: kLayrzLayoutUserChromePaddingVertical,
            horizontal: kLayrzLayoutUserChromePaddingHorizontal,
          ),
          decoration: BoxDecoration(
            color: tokens.colors.surface,
            borderRadius: BorderRadius.circular(kLayrzLayoutUserChromeRadius),
          ),
          child: Row(
            children: [
              // Avatar
              SizedBox(
                width: kLayrzLayoutUserAvatarSize,
                height: kLayrzLayoutUserAvatarSize,
                child: LayrzAvatar(
                  source: userAvatar,
                  size: kLayrzLayoutUserAvatarSize,
                  nameText: userName,
                ),
              ),

              SizedBox(width: 8.0),

              // Name
              Expanded(
                child: userName != null && userName!.isNotEmpty
                    ? Text(
                        userName!,
                        style: TextStyle(
                          fontSize: kLayrzLayoutUserNameFontSize,
                          fontWeight: kLayrzLayoutUserNameFontWeight,
                          color: tokens.colors.fg1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),

              // Chevron
              SizedBox(width: 6.0),
              Icon(
                LayrzIcons.solarOutlineAltArrowUp,
                size: kLayrzLayoutUserChromeChevronSize,
                color: tokens.colors.fg3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

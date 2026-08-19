import 'package:layrz_icons/layrz_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'navigator_item.dart';
import 'notification_item.dart';
import 'rail_item.dart';
import 'user_chrome.dart';

/// The navigation rail widget displayed in expanded presentation.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutRail extends StatelessWidget {
  /// Creates a navigation rail.
  const LayrzLayoutRail({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The navigation items to display.
    required this.items,

    /// A widget displayed in the rail header.
    required this.logo,

    /// The user's display name.
    required this.userName,

    /// The user's avatar source.
    required this.userAvatar,

    /// The menu items displayed when the user chrome block is tapped.
    required this.userMenuItems,

    /// The list of notifications to display.
    required this.notifications,

    /// Callback fired when a notification is tapped.
    required this.onNotificationTap,

    /// Function to derive initials from a name.
    required this.getInitials,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The navigation items to display.
  final List<LayrzNavigatorItem> items;

  /// A widget displayed in the rail header.
  final Widget? logo;

  /// The user's display name.
  final String? userName;

  /// The user's avatar source.
  final LayrzAvatarSource? userAvatar;

  /// The menu items displayed when the user chrome block is tapped.
  final List<LayrzDropdownItem> userMenuItems;

  /// The list of notifications to display.
  final List<LayrzNotificationItem> notifications;

  /// Callback fired when a notification is tapped.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// Function to derive initials from a name.
  final String Function(String?) getInitials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kLayrzLayoutRailWidth,
      color: tokens.colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo block
          if (logo != null)
            Padding(
              padding: const EdgeInsets.only(
                left: kLayrzLayoutLogoLeftPadding,
                top: kLayrzLayoutRailPaddingVertical,
                bottom: kLayrzLayoutLogoBottomPadding,
              ),
              child: SizedBox(
                height: kLayrzLayoutLogoTileSize,
                child: logo!,
              ),
            ),

          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kLayrzLayoutRailPaddingVertical,
                horizontal: kLayrzLayoutRailPaddingHorizontal,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildItems(),
                ),
              ),
            ),
          ),

          // Footer: 1px divider + user chrome + notifications
          Container(
            height: 1.0,
            color: tokens.colors.divider,
          ),
          Padding(
            padding: const EdgeInsets.only(top: kLayrzLayoutFooterPaddingTop),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notifications bell or nothing
                if (notifications.isNotEmpty || onNotificationTap != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kLayrzLayoutRailPaddingHorizontal,
                      vertical: 4.0,
                    ),
                    child: _buildNotificationsBell(),
                  ),

                SizedBox(height: notifications.isNotEmpty || onNotificationTap != null ? 6.0 : 0.0),

                // User chrome
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kLayrzLayoutRailPaddingHorizontal,
                  ),
                  child: LayrzLayoutUserChrome(
                    tokens: tokens,
                    userName: userName,
                    userAvatar: userAvatar,
                    userMenuItems: userMenuItems,
                    getInitials: getInitials,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems() {
    final widgets = <Widget>[];

    for (final item in items) {
      switch (item) {
        case LayrzNavigatorPage():
          widgets.add(
            LayrzLayoutRailItem(
              tokens: tokens,
              page: item,
              isSelected: item.isSelected,
              onTap: () {
                item.onTap?.call();
              },
            ),
          );
        case LayrzNavigatorLabel():
          widgets.add(_buildSectionCaption(item.labelText));
      }
    }

    return widgets;
  }

  Widget _buildSectionCaption(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: kLayrzLayoutSectionCaptionPaddingTop,
        left: kLayrzLayoutSectionCaptionPaddingLeft,
        bottom: kLayrzLayoutSectionCaptionPaddingBottom,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: kLayrzLayoutSectionCaptionFontSize,
          fontWeight: kLayrzLayoutSectionCaptionFontWeight,
          letterSpacing: kLayrzLayoutSectionCaptionLetterSpacing,
          color: tokens.colors.fg3,
        ),
      ),
    );
  }

  Widget _buildNotificationsBell() {
    return SizedBox(
      height: 32.0,
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          LayrzIcons.solarOutlineBell,
          size: 20.0,
          color: tokens.colors.fg2,
        ),
      ),
    );
  }
}

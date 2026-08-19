import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'navigator_item.dart';
import 'rail_item.dart';
import 'user_chrome.dart';

/// The off-canvas drawer widget displayed in drawer presentation.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutDrawer extends StatelessWidget {
  /// Creates an off-canvas drawer.
  const LayrzLayoutDrawer({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The navigation items to display in the drawer.
    required this.items,

    /// A widget displayed in the drawer header.
    required this.logo,

    /// The user's display name.
    required this.userName,

    /// The user's avatar source.
    required this.userAvatar,

    /// The menu items displayed when the user chrome block is tapped.
    required this.userMenuItems,

    /// Callback fired when the drawer is closed.
    required this.onClose,

    /// Function to derive initials from a name.
    required this.getInitials,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The navigation items to display in the drawer.
  final List<LayrzNavigatorItem> items;

  /// A widget displayed in the drawer header.
  final Widget? logo;

  /// The user's display name.
  final String? userName;

  /// The user's avatar source.
  final LayrzAvatarSource? userAvatar;

  /// The menu items displayed when the user chrome block is tapped.
  final List<LayrzDropdownItem> userMenuItems;

  /// Callback fired when the drawer is closed.
  final VoidCallback onClose;

  /// Function to derive initials from a name.
  final String Function(String?) getInitials;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrim
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: tokens.colors.overlay,
          ),
        ),

        // Drawer panel
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: kLayrzLayoutDrawerWidth,
            color: tokens.colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo block
                if (logo != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 36.0,
                      child: logo!,
                    ),
                  ),

                // Navigation items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 10.0,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildItems(),
                      ),
                    ),
                  ),
                ),

                // Footer: 1px divider + user chrome
                Container(
                  height: 1.0,
                  color: tokens.colors.divider,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                    child: LayrzLayoutUserChrome(
                      tokens: tokens,
                      userName: userName,
                      userAvatar: userAvatar,
                      userMenuItems: userMenuItems,
                      getInitials: getInitials,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
}

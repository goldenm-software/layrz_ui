import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'notification_item.dart';
import 'top_bar_icon_button.dart';

/// The top bar widget displayed in drawer presentation.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutTopBar extends StatelessWidget {
  /// Creates a top bar.
  const LayrzLayoutTopBar({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// A widget displayed in the top bar center.
    required this.logo,

    /// The list of notifications to display (for backwards compatibility).
    required this.notifications,

    /// Callback fired when a notification is tapped (for backwards compatibility).
    required this.onNotificationTap,

    /// Callback fired when the drawer trigger is tapped.
    required this.onDrawerTap,

    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// A widget displayed in the top bar center.
  final String logo;

  /// The list of notifications to display.
  final List<LayrzNotificationItem> notifications;

  /// Callback fired when a notification is tapped.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// Callback fired when the drawer trigger is tapped.
  final VoidCallback onDrawerTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colors.background,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kLayrzLayoutTopBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kLayrzLayoutTopBarPaddingHorizontal),
            child: Row(
              children: [
                // Drawer trigger
                LayrzLayoutTopBarIconButton(
                  key: const ValueKey('drawer_trigger_button'),
                  icon: MdiIcons.menu,
                  iconColor: tokens.colors.fg2,
                  iconSize: kLayrzLayoutDrawerTriggerIconSize,
                  onTap: onDrawerTap,
                ),

                SizedBox(width: kLayrzLayoutTopBarGap),

                // Logo/mark
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LayrzImage(
                      source: logo,
                      width: kLayrzLayoutTopBarLogoWidth,
                      height: kLayrzLayoutTopBarLogoHeight,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
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

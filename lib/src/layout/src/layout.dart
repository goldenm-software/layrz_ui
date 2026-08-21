import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/preview.dart';

import 'drawer_scaffold.dart';
import 'navigator_item.dart';
import 'navigator_panel.dart';
import 'notification_item.dart';
import 'presentation.dart';
import 'top_bar.dart';

/// An opinionated application shell layout for layrz_ui apps.
///
/// [LayrzLayout] provides a two-presentation responsive container designed to
/// organize an app's main navigation and content. The presentation switches
/// between expanded (md, lg, xl breakpoints) and drawer (xs, sm breakpoints)
/// modes based on the available width, detected via [LayoutBuilder] constraints.
///
/// ## Expanded Presentation (md, lg, xl)
///
/// The expanded presentation displays a fixed 178-pixel navigation rail on the
/// left side of the screen, with the body content to its right.
///
/// ## Drawer Presentation (xs, sm)
///
/// The drawer presentation displays a compact 56-pixel top bar above the body,
/// with navigation hidden in an off-canvas drawer.
///
/// ## Responsiveness
///
/// The layout detects its available width via [LayoutBuilder] and resolves
/// the presentation using [resolveLayrzLayoutPresentation]. This allows
/// [LayrzLayout] to be used in constrained containers.
class LayrzLayout extends StatefulWidget {
  /// Creates a responsive application shell layout.
  ///
  /// The [body] and [items] parameters are required. All other parameters
  /// are optional and default to null or empty collections.
  const LayrzLayout({
    required this.body,
    required this.items,
    required this.logo,
    this.userName,
    this.userAvatar,
    this.userMenuItems = const [],
    this.notifications = const [],
    this.onNotificationTap,
    this.backgroundColor,
    super.key,
  });

  /// The main content widget displayed in the layout.
  ///
  /// In expanded presentation, this is displayed to the right of the 178-pixel
  /// navigation rail. In drawer presentation, this is displayed below the
  /// 56-pixel top bar.
  final Widget body;

  /// The navigation items displayed in the rail (expanded) or drawer (drawer).
  ///
  /// Items are instances of [LayrzNavigatorPage] or [LayrzNavigatorLabel].
  /// The list is rendered in order, with labels and pages interspersed.
  /// Selection state is determined by the [LayrzNavigatorPage.isSelected] field
  /// on each page item.
  final List<LayrzNavigatorItem> items;

  /// A string source for the layout's logo image, displayed in the rail (expanded) or top bar (drawer).
  ///
  /// This source is passed to [LayrzImage] and can be a network URL, asset path, or base64 string.
  final String logo;

  /// The user's display name.
  ///
  /// Displayed in the user chrome block. Used to derive initials for the
  /// avatar fallback if [userAvatar] is null.
  final String? userName;

  /// The user's avatar source.
  ///
  /// Can be a [LayrzAvatarUrl], [LayrzAvatarBase64], [LayrzAvatarIcon],
  /// or [LayrzAvatarEmoji]. If null, initials are derived from [userName].
  final LayrzAvatarSource? userAvatar;

  /// The menu items displayed when the user chrome block is tapped.
  ///
  /// A list of [LayrzDropdownItem] (either [LayrzDropdownEntry] or [LayrzDropdownLabel]).
  /// When empty, the user chrome block is not interactive and displays no chevron.
  /// Each entry carries its own [LayrzDropdownEntry.onTap] callback.
  final List<LayrzDropdownItem> userMenuItems;

  /// The list of notifications to display in the notifications panel.
  ///
  /// Defaults to an empty list. When empty and [onNotificationTap] is null,
  /// the notifications bell is hidden entirely.
  final List<LayrzNotificationItem> notifications;

  /// Fired when the user taps a notification in the notifications panel.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// The background color of the layout.
  ///
  /// Defaults to [LayrzTokens.colors.background].
  final Color? backgroundColor;

  @override
  State<LayrzLayout> createState() => _LayrzLayoutState();
}

class _LayrzLayoutState extends State<LayrzLayout> {
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.theme.tokens;
    final backgroundColor = widget.backgroundColor ?? tokens.colors.background;

    return LayoutBuilder(
      builder: (context, constraints) {
        final presentation = resolveLayrzLayoutPresentation(
          width: constraints.maxWidth,
          tokens: tokens,
        );

        if (presentation == LayrzLayoutPresentation.expanded) {
          return _buildExpanded(context, tokens, backgroundColor);
        } else {
          return _buildDrawer(context, tokens, backgroundColor);
        }
      },
    );
  }

  Widget _buildExpanded(BuildContext context, LayrzTokens tokens, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      child: Row(
        children: [
          LayrzLayoutNavigatorPanel(
            tokens: tokens,
            width: kLayrzLayoutRailWidth,
            items: widget.items,
            logo: widget.logo,
            userName: widget.userName,
            userAvatar: widget.userAvatar,
            userMenuItems: widget.userMenuItems,
            notifications: widget.notifications,
            onNotificationTap: widget.onNotificationTap,
            onClose: null,
            getInitials: _getInitials,
          ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, LayrzTokens tokens, Color backgroundColor) {
    return LayrzLayoutDrawerScaffold(
      backgroundColor: backgroundColor,
      drawerBackgroundColor: tokens.colors.surface,
      topBarBuilder: (openDrawer) => LayrzLayoutTopBar(
        tokens: tokens,
        logo: widget.logo,
        notifications: widget.notifications,
        onNotificationTap: widget.onNotificationTap,
        onDrawerTap: openDrawer,
      ),
      body: widget.body,
      drawerBuilder: (closeDrawer) => LayrzLayoutNavigatorPanel(
        tokens: tokens,
        width: kLayrzLayoutDrawerWidth,
        items: widget.items,
        logo: widget.logo,
        userName: widget.userName,
        userAvatar: widget.userAvatar,
        userMenuItems: widget.userMenuItems,
        notifications: widget.notifications,
        onNotificationTap: widget.onNotificationTap,
        onClose: closeDrawer,
        getInitials: _getInitials,
      ),
    );
  }
}

/// Preview widget for LayrzLayout in expanded presentation mode.
@Preview(
  name: 'Light',
  size: Size(1200, 600),
  theme: layrzPreviewLightTheme,
)
Widget previewLayrzLayout() => LayrzLayout(
  logo: 'https://cdn.layrz.com/resources/com.layrz.one/logo/normal.png',
  items: [
    LayrzNavigatorPage(
      id: 'dashboard',
      icon: MdiIcons.viewDashboardOutline,
      labelText: 'Dashboard',
      isSelected: true,
    ),
    LayrzNavigatorPage(
      id: 'devices',
      icon: MdiIcons.cellphoneLink,
      labelText: 'Devices',
    ),
    LayrzNavigatorLabel('Settings'),
    LayrzNavigatorPage(
      id: 'config',
      icon: MdiIcons.cogOutline,
      labelText: 'Configuration',
    ),
  ],
  userName: 'John Doe',
  userMenuItems: [
    LayrzDropdownEntry(
      labelText: 'Profile',
      icon: MdiIcons.accountOutline,
      onTap: () {},
    ),
    LayrzDropdownEntry(
      labelText: 'Settings',
      icon: MdiIcons.cogOutline,
      onTap: () {},
    ),
  ],
  body: Center(
    child: Text('Body content goes here'),
  ),
);

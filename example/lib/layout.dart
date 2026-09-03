import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Wraps a showroom page in the application shell.
///
/// [ShowroomLayout] is a stateless container that renders a page inside
/// [LayrzLayout]. The currently selected navigation entry is derived from the
/// active route path via [GoRouterState.of].
class ShowroomLayout extends StatelessWidget {
  /// The page content rendered inside the layout's body slot.
  final Widget child;

  /// Creates a new [ShowroomLayout].
  const ShowroomLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final routePath = GoRouterState.of(context).uri.path;
    final items = _buildNavigationItems(context, routePath);

    return LayrzLayout(
      items: items,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: child,
      ),
      logo: 'https://cdn.layrz.com/resources/com.layrz.ui/logo.png?3',
      userName: 'John Doe',
      userMenuItems: [
        LayrzDropdownEntry(
          labelText: 'Profile',
          icon: MdiIcons.accountOutline,
          onTap: () => debugPrint('Profile tapped'),
        ),
        LayrzDropdownEntry(
          labelText: 'Settings',
          icon: MdiIcons.cogOutline,
          onTap: () => debugPrint('Settings tapped'),
        ),
        LayrzDropdownLabel(labelText: 'Account'),
        LayrzDropdownEntry(
          labelText: 'Sign out',
          icon: MdiIcons.logout,
          onTap: () => debugPrint('Sign out tapped'),
        ),
      ],
      notifications: [
        LayrzNotificationItem(
          id: '1',
          title: 'System Update',
          content: 'A new version is available',
        ),
        LayrzNotificationItem(
          id: '2',
          title: 'New Message',
          content: 'You have a new message from Admin',
        ),
        LayrzNotificationItem(
          id: '3',
          title: 'Alert',
          content: 'Critical: High CPU usage detected',
        ),
      ],
    );
  }

  List<LayrzNavigatorItem> _buildNavigationItems(BuildContext context, String currentRoute) {
    return [
      LayrzNavigatorLabel('FOUNDATION'),
      LayrzNavigatorPage(
        id: '/typography',
        labelText: 'Typography',
        icon: MdiIcons.formatText,
        isSelected: currentRoute == '/typography',
        onTap: () => _navigateTo(context, '/typography'),
      ),
      LayrzNavigatorPage(
        id: '/colors',
        labelText: 'Colors',
        icon: MdiIcons.palette,
        isSelected: currentRoute == '/colors',
        onTap: () => _navigateTo(context, '/colors'),
      ),
      LayrzNavigatorPage(
        id: '/spacing',
        labelText: 'Spacing',
        icon: MdiIcons.arrowDownBox,
        isSelected: currentRoute == '/spacing',
        onTap: () => _navigateTo(context, '/spacing'),
      ),
      LayrzNavigatorPage(
        id: '/radius',
        labelText: 'Radius',
        icon: MdiIcons.refresh,
        isSelected: currentRoute == '/radius',
        onTap: () => _navigateTo(context, '/radius'),
      ),
      LayrzNavigatorPage(
        id: '/elevation',
        labelText: 'Elevation',
        icon: MdiIcons.chevronUp,
        isSelected: currentRoute == '/elevation',
        onTap: () => _navigateTo(context, '/elevation'),
      ),
      LayrzNavigatorPage(
        id: '/borders',
        labelText: 'Borders',
        icon: MdiIcons.flashOutline,
        isSelected: currentRoute == '/borders',
        onTap: () => _navigateTo(context, '/borders'),
      ),
      LayrzNavigatorPage(
        id: '/motion',
        labelText: 'Motion',
        icon: MdiIcons.play,
        isSelected: currentRoute == '/motion',
        onTap: () => _navigateTo(context, '/motion'),
      ),
      LayrzNavigatorPage(
        id: '/access-paths',
        labelText: 'Access Paths',
        icon: MdiIcons.serverNetwork,
        isSelected: currentRoute == '/access-paths',
        onTap: () => _navigateTo(context, '/access-paths'),
      ),
      LayrzNavigatorLabel('COMPONENTS'),
      LayrzNavigatorPage(
        id: '/buttons',
        labelText: 'Buttons',
        icon: MdiIcons.checkboxOutline,
        isSelected: currentRoute == '/buttons',
        onTap: () => _navigateTo(context, '/buttons'),
      ),
      LayrzNavigatorPage(
        id: '/button-group',
        labelText: 'Button Group',
        icon: MdiIcons.checkCircleOutline,
        isSelected: currentRoute == '/button-group',
        onTap: () => _navigateTo(context, '/button-group'),
      ),
      LayrzNavigatorPage(
        id: '/alerts',
        labelText: 'Alerts',
        icon: MdiIcons.informationBoxOutline,
        isSelected: currentRoute == '/alerts',
        onTap: () => _navigateTo(context, '/alerts'),
      ),
      LayrzNavigatorPage(
        id: '/tooltips',
        labelText: 'Tooltips',
        icon: MdiIcons.informationBoxOutline,
        isSelected: currentRoute == '/tooltips',
        onTap: () => _navigateTo(context, '/tooltips'),
      ),
      LayrzNavigatorPage(
        id: '/images',
        labelText: 'Images',
        icon: MdiIcons.imageOutline,
        isSelected: currentRoute == '/images',
        onTap: () => _navigateTo(context, '/images'),
      ),
      LayrzNavigatorPage(
        id: '/menus',
        labelText: 'Menus',
        icon: MdiIcons.dotsSquare,
        isSelected: currentRoute == '/menus',
        onTap: () => _navigateTo(context, '/menus'),
      ),
      LayrzNavigatorPage(
        id: '/dialogs',
        labelText: 'Dialogs',
        icon: MdiIcons.windowMaximize,
        isSelected: currentRoute == '/dialogs',
        onTap: () => _navigateTo(context, '/dialogs'),
      ),
      LayrzNavigatorPage(
        id: '/responsive-modal',
        labelText: 'Responsive Modal',
        icon: MdiIcons.monitorCellphone,
        isSelected: currentRoute == '/responsive-modal',
        onTap: () => _navigateTo(context, '/responsive-modal'),
      ),
      LayrzNavigatorPage(
        id: '/sheets',
        labelText: 'Sheets',
        icon: MdiIcons.trayArrowUp,
        isSelected: currentRoute == '/sheets',
        onTap: () => _navigateTo(context, '/sheets'),
      ),
      LayrzNavigatorPage(
        id: '/steppers',
        labelText: 'Steppers',
        icon: MdiIcons.formatListNumberedRtl,
        isSelected: currentRoute == '/steppers',
        onTap: () => _navigateTo(context, '/steppers'),
      ),
      LayrzNavigatorPage(
        id: '/chips',
        labelText: 'Chips',
        icon: MdiIcons.tagOutline,
        isSelected: currentRoute == '/chips',
        onTap: () => _navigateTo(context, '/chips'),
      ),
      LayrzNavigatorPage(
        id: '/text',
        labelText: 'Text',
        icon: MdiIcons.formatBold,
        isSelected: currentRoute == '/text',
        onTap: () => _navigateTo(context, '/text'),
      ),
      LayrzNavigatorPage(
        id: '/inputs',
        labelText: 'Inputs',
        icon: MdiIcons.formTextboxPassword,
        isSelected: currentRoute == '/inputs',
        onTap: () => _navigateTo(context, '/inputs'),
      ),
      LayrzNavigatorPage(
        id: '/grid',
        labelText: 'Grid',
        icon: MdiIcons.arrowRightBox,
        isSelected: currentRoute == '/grid',
        onTap: () => _navigateTo(context, '/grid'),
      ),
      LayrzNavigatorPage(
        id: '/calendar',
        labelText: 'Calendar',
        icon: MdiIcons.calendarOutline,
        isSelected: currentRoute == '/calendar',
        onTap: () => _navigateTo(context, '/calendar'),
      ),
      LayrzNavigatorPage(
        id: '/progress',
        labelText: 'Progress Bar',
        icon: MdiIcons.progressClock,
        isSelected: currentRoute == '/progress',
        onTap: () => _navigateTo(context, '/progress'),
      ),
      LayrzNavigatorPage(
        id: '/timeline',
        labelText: 'Timeline',
        icon: MdiIcons.timelineTextOutline,
        isSelected: currentRoute == '/timeline',
        onTap: () => _navigateTo(context, '/timeline'),
      ),
      LayrzNavigatorPage(
        id: '/tree-view',
        labelText: 'Tree View',
        icon: MdiIcons.fileTreeOutline,
        isSelected: currentRoute == '/tree-view',
        onTap: () => _navigateTo(context, '/tree-view'),
      ),
      LayrzNavigatorPage(
        id: '/badges',
        labelText: 'Badges',
        icon: MdiIcons.badgeAccountOutline,
        isSelected: currentRoute == '/badges',
        onTap: () => _navigateTo(context, '/badges'),
      ),
      LayrzNavigatorPage(
        id: '/transitions',
        labelText: 'Page Transitions',
        icon: MdiIcons.swapHorizontal,
        isSelected: currentRoute == '/transitions',
        onTap: () => _navigateTo(context, '/transitions'),
      ),
      LayrzNavigatorPage(
        id: '/refresh',
        labelText: 'Refresh',
        icon: MdiIcons.autorenew,
        isSelected: currentRoute == '/refresh',
        onTap: () => _navigateTo(context, '/refresh'),
      ),
    ];
  }

  /// Navigate to the specified route path using go_router.
  void _navigateTo(BuildContext context, String route) {
    context.go(route);
  }
}

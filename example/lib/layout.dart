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
        child: SingleChildScrollView(child: child),
      ),
      logo: 'https://cdn.layrz.com/resources/com.layrz.one/logo/normal.png',
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
      LayrzNavigatorLabel('FOUNDATION', color: context.tokens.colors.primary),
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
      LayrzNavigatorLabel('COMPONENTS', color: context.tokens.colors.primary),
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
    ];
  }

  /// Navigate to the specified route path using go_router.
  void _navigateTo(BuildContext context, String route) {
    context.go(route);
  }
}

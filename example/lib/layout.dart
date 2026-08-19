import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

/// Wraps a showroom page in the application shell.
///
/// [ShowroomLayout] is a stateless container that renders a page inside
/// [LayrzLayout]. The currently selected navigation entry is derived from the
/// active route name via [ModalRoute.of].
class ShowroomLayout extends StatelessWidget {
  /// The page content rendered inside the layout's body slot.
  final Widget child;

  /// Creates a new [ShowroomLayout].
  const ShowroomLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name ?? '/buttons';
    final items = _buildNavigationItems(context, routeName);

    return LayrzLayout(
      items: items,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: child,
            ),
          ),
        ),
      ),
      logo: 'https://cdn.layrz.com/resources/com.layrz.one/logo/normal.png',
      userName: 'John Doe',
      userMenuItems: [
        LayrzDropdownEntry(
          labelText: 'Profile',
          icon: LayrzIcons.solarOutlineUser,
          onTap: () => debugPrint('Profile tapped'),
        ),
        LayrzDropdownEntry(
          labelText: 'Settings',
          icon: LayrzIcons.solarOutlineSettings,
          onTap: () => debugPrint('Settings tapped'),
        ),
        LayrzDropdownLabel(labelText: 'Account'),
        LayrzDropdownEntry(
          labelText: 'Sign out',
          icon: LayrzIcons.solarOutlineLogout,
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
        icon: LayrzIcons.solarOutlineText,
        isSelected: currentRoute == '/typography',
        onTap: () => _navigateTo(context, '/typography'),
      ),
      LayrzNavigatorPage(
        id: '/colors',
        labelText: 'Colors',
        icon: LayrzIcons.solarOutlinePalette,
        isSelected: currentRoute == '/colors',
        onTap: () => _navigateTo(context, '/colors'),
      ),
      LayrzNavigatorPage(
        id: '/spacing',
        labelText: 'Spacing',
        icon: LayrzIcons.solarOutlineSquareArrowDown,
        isSelected: currentRoute == '/spacing',
        onTap: () => _navigateTo(context, '/spacing'),
      ),
      LayrzNavigatorPage(
        id: '/radius',
        labelText: 'Radius',
        icon: LayrzIcons.solarOutlineRefreshCircle,
        isSelected: currentRoute == '/radius',
        onTap: () => _navigateTo(context, '/radius'),
      ),
      LayrzNavigatorPage(
        id: '/elevation',
        labelText: 'Elevation',
        icon: LayrzIcons.solarOutlineAltArrowUp,
        isSelected: currentRoute == '/elevation',
        onTap: () => _navigateTo(context, '/elevation'),
      ),
      LayrzNavigatorPage(
        id: '/borders',
        labelText: 'Borders',
        icon: LayrzIcons.solarOutlineBoltCircle,
        isSelected: currentRoute == '/borders',
        onTap: () => _navigateTo(context, '/borders'),
      ),
      LayrzNavigatorPage(
        id: '/motion',
        labelText: 'Motion',
        icon: LayrzIcons.solarOutlinePlay,
        isSelected: currentRoute == '/motion',
        onTap: () => _navigateTo(context, '/motion'),
      ),
      LayrzNavigatorPage(
        id: '/access-paths',
        labelText: 'Access Paths',
        icon: LayrzIcons.solarOutlineServerPath,
        isSelected: currentRoute == '/access-paths',
        onTap: () => _navigateTo(context, '/access-paths'),
      ),
      LayrzNavigatorLabel('COMPONENTS'),
      LayrzNavigatorPage(
        id: '/buttons',
        labelText: 'Buttons',
        icon: LayrzIcons.solarOutlineCheckSquare,
        isSelected: currentRoute == '/buttons',
        onTap: () => _navigateTo(context, '/buttons'),
      ),
      LayrzNavigatorPage(
        id: '/button-group',
        labelText: 'Button Group',
        icon: LayrzIcons.solarOutlineCheckCircle,
        isSelected: currentRoute == '/button-group',
        onTap: () => _navigateTo(context, '/button-group'),
      ),
      LayrzNavigatorPage(
        id: '/alerts',
        labelText: 'Alerts',
        icon: LayrzIcons.solarOutlineInfoSquare,
        isSelected: currentRoute == '/alerts',
        onTap: () => _navigateTo(context, '/alerts'),
      ),
      LayrzNavigatorPage(
        id: '/tooltips',
        labelText: 'Tooltips',
        icon: LayrzIcons.solarOutlineInfoSquare,
        isSelected: currentRoute == '/tooltips',
        onTap: () => _navigateTo(context, '/tooltips'),
      ),
      LayrzNavigatorPage(
        id: '/images',
        labelText: 'Images',
        icon: LayrzIcons.solarOutlineGalleryCircle,
        isSelected: currentRoute == '/images',
        onTap: () => _navigateTo(context, '/images'),
      ),
      LayrzNavigatorPage(
        id: '/menus',
        labelText: 'Menus',
        icon: LayrzIcons.solarOutlineMenuDotsSquare,
        isSelected: currentRoute == '/menus',
        onTap: () => _navigateTo(context, '/menus'),
      ),
      LayrzNavigatorPage(
        id: '/chips',
        labelText: 'Chips',
        icon: LayrzIcons.solarOutlineTag,
        isSelected: currentRoute == '/chips',
        onTap: () => _navigateTo(context, '/chips'),
      ),
      LayrzNavigatorPage(
        id: '/text',
        labelText: 'Text',
        icon: LayrzIcons.solarOutlineTextBold,
        isSelected: currentRoute == '/text',
        onTap: () => _navigateTo(context, '/text'),
      ),
      LayrzNavigatorPage(
        id: '/inputs',
        labelText: 'Inputs',
        icon: LayrzIcons.solarOutlinePasswordMinimalisticInput,
        isSelected: currentRoute == '/inputs',
        onTap: () => _navigateTo(context, '/inputs'),
      ),
      LayrzNavigatorPage(
        id: '/grid',
        labelText: 'Grid',
        icon: LayrzIcons.solarOutlineSquareForward,
        isSelected: currentRoute == '/grid',
        onTap: () => _navigateTo(context, '/grid'),
      ),
    ];
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }
}

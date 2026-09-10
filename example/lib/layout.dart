import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:layrz_ui/layrz_ui.dart';

import 'src/providers/theme_mode_provider.dart';

/// The showroom logo, light-background variant.
const _kLightLogo = 'https://cdn.layrz.com/resources/com.layrz.ui/logo.png?3';

/// The showroom logo, dark-background variant.
const _kDarkLogo = 'https://cdn.layrz.com/resources/com.layrz.ui/logo-white.png?3';

/// Wraps a showroom page in the application shell.
///
/// [ShowroomLayout] is a container that renders a page inside [LayrzLayout].
/// The currently selected navigation entry is derived from the active route
/// path via [GoRouterState.of]. Reads [themeModeProvider] to swap the logo for
/// its dark-background variant and to mark the active entry in the Theme
/// section of the user menu.
class ShowroomLayout extends ConsumerWidget {
  /// The page content rendered inside the layout's body slot.
  final Widget child;

  /// Creates a new [ShowroomLayout].
  const ShowroomLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routePath = GoRouterState.of(context).uri.path;
    final items = _buildNavigationItems(context, routePath);

    final mode = ref.watch(themeModeProvider);
    final isDark = switch (mode) {
      LayrzThemeMode.light => false,
      LayrzThemeMode.dark => true,
      LayrzThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final accent = context.theme.primaryColor;

    return LayrzLayout(
      items: items,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: child,
      ),
      logo: isDark ? _kDarkLogo : _kLightLogo,
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
        LayrzDropdownLabel(labelText: 'Theme'),
        LayrzDropdownEntry(
          labelText: 'Light',
          icon: MdiIcons.weatherSunny,
          color: mode == LayrzThemeMode.light ? accent : null,
          onTap: () => ref.read(themeModeProvider.notifier).state = LayrzThemeMode.light,
        ),
        LayrzDropdownEntry(
          labelText: 'Dark',
          icon: MdiIcons.weatherNight,
          color: mode == LayrzThemeMode.dark ? accent : null,
          onTap: () => ref.read(themeModeProvider.notifier).state = LayrzThemeMode.dark,
        ),
        LayrzDropdownEntry(
          labelText: 'System',
          icon: MdiIcons.themeLightDark,
          color: mode == LayrzThemeMode.system ? accent : null,
          onTap: () => ref.read(themeModeProvider.notifier).state = LayrzThemeMode.system,
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
      LayrzNavigatorPage(
        id: '/home',
        labelText: 'Home',
        icon: MdiIcons.homeOutline,
        isSelected: currentRoute == '/home',
        onTap: () => _navigateTo(context, '/home'),
      ),
      LayrzNavigatorLabel('FOUNDATION'),
      LayrzNavigatorPage(
        id: '/access-paths',
        labelText: 'Access Paths',
        icon: MdiIcons.serverNetwork,
        isSelected: currentRoute == '/access-paths',
        onTap: () => _navigateTo(context, '/access-paths'),
      ),
      LayrzNavigatorPage(
        id: '/borders',
        labelText: 'Borders',
        icon: MdiIcons.flashOutline,
        isSelected: currentRoute == '/borders',
        onTap: () => _navigateTo(context, '/borders'),
      ),
      LayrzNavigatorPage(
        id: '/colors',
        labelText: 'Colors',
        icon: MdiIcons.palette,
        isSelected: currentRoute == '/colors',
        onTap: () => _navigateTo(context, '/colors'),
      ),
      LayrzNavigatorPage(
        id: '/elevation',
        labelText: 'Elevation',
        icon: MdiIcons.chevronUp,
        isSelected: currentRoute == '/elevation',
        onTap: () => _navigateTo(context, '/elevation'),
      ),
      LayrzNavigatorPage(
        id: '/motion',
        labelText: 'Motion',
        icon: MdiIcons.play,
        isSelected: currentRoute == '/motion',
        onTap: () => _navigateTo(context, '/motion'),
      ),
      LayrzNavigatorPage(
        id: '/radius',
        labelText: 'Radius',
        icon: MdiIcons.refresh,
        isSelected: currentRoute == '/radius',
        onTap: () => _navigateTo(context, '/radius'),
      ),
      LayrzNavigatorPage(
        id: '/spacing',
        labelText: 'Spacing',
        icon: MdiIcons.arrowDownBox,
        isSelected: currentRoute == '/spacing',
        onTap: () => _navigateTo(context, '/spacing'),
      ),
      LayrzNavigatorPage(
        id: '/typography',
        labelText: 'Typography',
        icon: MdiIcons.formatText,
        isSelected: currentRoute == '/typography',
        onTap: () => _navigateTo(context, '/typography'),
        contextMenuActions: [
          LayrzContextMenuLabel(labelText: 'Typography actions'),
          LayrzContextMenuEntry(
            labelText: 'Open Typography',
            icon: MdiIcons.openInNew,
            onTap: () => _navigateTo(context, '/typography'),
          ),
          const LayrzContextMenuDivider(),
          LayrzContextMenuEntry(
            labelText: 'Copy route',
            icon: MdiIcons.contentCopy,
            onTap: () => Clipboard.setData(const ClipboardData(text: '/typography')),
          ),
          LayrzContextMenuEntry(
            labelText: 'Pin page (disabled)',
            icon: MdiIcons.pinOutline,
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
      LayrzNavigatorLabel('COMPONENTS'),
      LayrzNavigatorPage(
        id: '/accordion',
        labelText: 'Accordion',
        icon: MdiIcons.unfoldMoreHorizontal,
        isSelected: currentRoute == '/accordion',
        onTap: () => _navigateTo(context, '/accordion'),
      ),
      LayrzNavigatorPage(
        id: '/ai-marker',
        labelText: 'AI Marker',
        icon: MdiIcons.creationOutline,
        isSelected: currentRoute == '/ai-marker',
        onTap: () => _navigateTo(context, '/ai-marker'),
      ),
      LayrzNavigatorPage(
        id: '/alerts',
        labelText: 'Alerts',
        icon: MdiIcons.informationBoxOutline,
        isSelected: currentRoute == '/alerts',
        onTap: () => _navigateTo(context, '/alerts'),
      ),
      LayrzNavigatorPage(
        id: '/app-banner',
        labelText: 'App Banner',
        icon: MdiIcons.flaskOutline,
        isSelected: currentRoute == '/app-banner',
        onTap: () => _navigateTo(context, '/app-banner'),
      ),
      LayrzNavigatorPage(
        id: '/badges',
        labelText: 'Badges',
        icon: MdiIcons.badgeAccountOutline,
        isSelected: currentRoute == '/badges',
        onTap: () => _navigateTo(context, '/badges'),
      ),
      LayrzNavigatorPage(
        id: '/button-group',
        labelText: 'Button Group',
        icon: MdiIcons.checkCircleOutline,
        isSelected: currentRoute == '/button-group',
        onTap: () => _navigateTo(context, '/button-group'),
      ),
      LayrzNavigatorPage(
        id: '/buttons',
        labelText: 'Buttons',
        icon: MdiIcons.checkboxOutline,
        isSelected: currentRoute == '/buttons',
        onTap: () => _navigateTo(context, '/buttons'),
      ),
      LayrzNavigatorPage(
        id: '/calendar',
        labelText: 'Calendar',
        icon: MdiIcons.calendarOutline,
        isSelected: currentRoute == '/calendar',
        onTap: () => _navigateTo(context, '/calendar'),
      ),
      LayrzNavigatorPage(
        id: '/cards',
        labelText: 'Cards',
        icon: MdiIcons.cardOutline,
        isSelected: currentRoute == '/cards',
        onTap: () => _navigateTo(context, '/cards'),
      ),
      LayrzNavigatorPage(
        id: '/chips',
        labelText: 'Chips',
        icon: MdiIcons.tagOutline,
        isSelected: currentRoute == '/chips',
        onTap: () => _navigateTo(context, '/chips'),
      ),
      LayrzNavigatorPage(
        id: '/code',
        labelText: 'Code',
        icon: MdiIcons.codeTags,
        isSelected: currentRoute == '/code',
        onTap: () => _navigateTo(context, '/code'),
      ),
      LayrzNavigatorPage(
        id: '/connection-indicator',
        labelText: 'Connection Indicator',
        icon: MdiIcons.wifiStrength3,
        isSelected: currentRoute == '/connection-indicator',
        onTap: () => _navigateTo(context, '/connection-indicator'),
      ),
      LayrzNavigatorPage(
        id: '/context-menu',
        labelText: 'Context Menu',
        icon: MdiIcons.cursorDefaultClickOutline,
        isSelected: currentRoute == '/context-menu',
        onTap: () => _navigateTo(context, '/context-menu'),
      ),
      LayrzNavigatorPage(
        id: '/dialogs',
        labelText: 'Dialogs',
        icon: MdiIcons.windowMaximize,
        isSelected: currentRoute == '/dialogs',
        onTap: () => _navigateTo(context, '/dialogs'),
      ),
      LayrzNavigatorPage(
        id: '/file-input',
        labelText: 'File Input',
        icon: MdiIcons.fileUploadOutline,
        isSelected: currentRoute == '/file-input',
        onTap: () => _navigateTo(context, '/file-input'),
      ),
      LayrzNavigatorPage(
        id: '/form',
        labelText: 'Form',
        icon: MdiIcons.formTextbox,
        isSelected: currentRoute == '/form',
        onTap: () => _navigateTo(context, '/form'),
      ),
      LayrzNavigatorPage(
        id: '/grid',
        labelText: 'Grid',
        icon: MdiIcons.arrowRightBox,
        isSelected: currentRoute == '/grid',
        onTap: () => _navigateTo(context, '/grid'),
      ),
      LayrzNavigatorPage(
        id: '/images',
        labelText: 'Images',
        icon: MdiIcons.imageOutline,
        isSelected: currentRoute == '/images',
        onTap: () => _navigateTo(context, '/images'),
      ),
      LayrzNavigatorPage(
        id: '/inputs',
        labelText: 'Inputs',
        icon: MdiIcons.formTextboxPassword,
        isSelected: currentRoute == '/inputs',
        onTap: () => _navigateTo(context, '/inputs'),
      ),
      LayrzNavigatorPage(
        id: '/pickers',
        labelText: 'Pickers',
        icon: MdiIcons.calendarCursorOutline,
        isSelected: currentRoute == '/pickers',
        onTap: () => _navigateTo(context, '/pickers'),
      ),
      LayrzNavigatorPage(
        id: '/layo',
        labelText: 'Layo',
        icon: MdiIcons.robotHappyOutline,
        isSelected: currentRoute == '/layo',
        onTap: () => _navigateTo(context, '/layo'),
      ),
      LayrzNavigatorPage(
        id: '/markdown',
        labelText: 'Markdown',
        icon: MdiIcons.fileDocumentOutline,
        isSelected: currentRoute == '/markdown',
        onTap: () => _navigateTo(context, '/markdown'),
      ),
      LayrzNavigatorPage(
        id: '/menus',
        labelText: 'Menus',
        icon: MdiIcons.dotsSquare,
        isSelected: currentRoute == '/menus',
        onTap: () => _navigateTo(context, '/menus'),
      ),
      LayrzNavigatorPage(
        id: '/transitions',
        labelText: 'Page Transitions',
        icon: MdiIcons.swapHorizontal,
        isSelected: currentRoute == '/transitions',
        onTap: () => _navigateTo(context, '/transitions'),
      ),
      LayrzNavigatorPage(
        id: '/progress',
        labelText: 'Progress Bar',
        icon: MdiIcons.progressClock,
        isSelected: currentRoute == '/progress',
        onTap: () => _navigateTo(context, '/progress'),
      ),
      LayrzNavigatorPage(
        id: '/refresh',
        labelText: 'Refresh',
        icon: MdiIcons.autorenew,
        isSelected: currentRoute == '/refresh',
        onTap: () => _navigateTo(context, '/refresh'),
      ),
      LayrzNavigatorPage(
        id: '/responsive-modal',
        labelText: 'Responsive Modal',
        icon: MdiIcons.monitorCellphone,
        isSelected: currentRoute == '/responsive-modal',
        onTap: () => _navigateTo(context, '/responsive-modal'),
      ),
      LayrzNavigatorPage(
        id: '/scaffold-shell',
        labelText: 'Scaffold Shell',
        icon: MdiIcons.viewSplitVertical,
        isSelected: currentRoute == '/scaffold-shell',
        onTap: () => _navigateTo(context, '/scaffold-shell'),
      ),
      LayrzNavigatorPage(
        id: '/sheets',
        labelText: 'Sheets',
        icon: MdiIcons.trayArrowUp,
        isSelected: currentRoute == '/sheets',
        onTap: () => _navigateTo(context, '/sheets'),
      ),
      LayrzNavigatorPage(
        id: '/skeleton',
        labelText: 'Skeleton',
        icon: MdiIcons.viewGridOutline,
        isSelected: currentRoute == '/skeleton',
        onTap: () => _navigateTo(context, '/skeleton'),
      ),
      LayrzNavigatorPage(
        id: '/snackbar',
        labelText: 'Snackbar',
        icon: MdiIcons.messageAlert,
        isSelected: currentRoute == '/snackbar',
        onTap: () => _navigateTo(context, '/snackbar'),
      ),
      LayrzNavigatorPage(
        id: '/steppers',
        labelText: 'Steppers',
        icon: MdiIcons.formatListNumberedRtl,
        isSelected: currentRoute == '/steppers',
        onTap: () => _navigateTo(context, '/steppers'),
      ),
      LayrzNavigatorPage(
        id: '/tab-view',
        labelText: 'Tab View',
        icon: MdiIcons.tabUnselected,
        isSelected: currentRoute == '/tab-view',
        onTap: () => _navigateTo(context, '/tab-view'),
      ),
      LayrzNavigatorPage(
        id: '/table',
        labelText: 'Table',
        icon: MdiIcons.table,
        isSelected: currentRoute == '/table',
        onTap: () => _navigateTo(context, '/table'),
      ),
      LayrzNavigatorPage(
        id: '/text',
        labelText: 'Text',
        icon: MdiIcons.formatBold,
        isSelected: currentRoute == '/text',
        onTap: () => _navigateTo(context, '/text'),
      ),
      LayrzNavigatorPage(
        id: '/timeline',
        labelText: 'Timeline',
        icon: MdiIcons.timelineTextOutline,
        isSelected: currentRoute == '/timeline',
        onTap: () => _navigateTo(context, '/timeline'),
      ),
      LayrzNavigatorPage(
        id: '/tooltips',
        labelText: 'Tooltips',
        icon: MdiIcons.informationBoxOutline,
        isSelected: currentRoute == '/tooltips',
        onTap: () => _navigateTo(context, '/tooltips'),
      ),
      LayrzNavigatorPage(
        id: '/tree-view',
        labelText: 'Tree View',
        icon: MdiIcons.fileTreeOutline,
        isSelected: currentRoute == '/tree-view',
        onTap: () => _navigateTo(context, '/tree-view'),
      ),
      LayrzNavigatorPage(
        id: '/workspace-tabs',
        labelText: 'Workspace Tabs',
        icon: MdiIcons.tab,
        isSelected: currentRoute == '/workspace-tabs',
        onTap: () => _navigateTo(context, '/workspace-tabs'),
      ),
    ];
  }

  /// Navigate to the specified route path using go_router.
  void _navigateTo(BuildContext context, String route) {
    context.go(route);
  }
}

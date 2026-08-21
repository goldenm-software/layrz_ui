import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'notification_item.dart';

/// The notifications panel widget that opens from a bell icon.
///
/// Displays a list of [LayrzNotificationItem] entries in a dropdown panel
/// anchored to the bell icon. Tapping a notification fires [onNotificationTap].
/// The panel dismisses on Escape key or tap-outside.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutNotificationsPanel extends StatefulWidget {
  /// Creates a notifications panel.
  const LayrzLayoutNotificationsPanel({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The list of notifications to display.
    ///
    /// When empty and [onNotificationTap] is null, the bell is hidden entirely.
    required this.notifications,

    /// Callback fired when a notification is tapped.
    required this.onNotificationTap,

    /// Callback fired when the panel is closed.
    required this.onClose,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The list of notifications to display.
  ///
  /// When empty and [onNotificationTap] is null, the bell is hidden entirely.
  final List<LayrzNotificationItem> notifications;

  /// Callback fired when a notification is tapped.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// Callback fired when the panel is closed.
  final VoidCallback onClose;

  @override
  State<LayrzLayoutNotificationsPanel> createState() => _LayrzLayoutNotificationsPanelState();
}

class _LayrzLayoutNotificationsPanelState extends State<LayrzLayoutNotificationsPanel> {
  late MenuController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
  }

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  void _handleCloseRequested(VoidCallback hideOverlay) {
    hideOverlay();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide bell when notifications empty and callback is null
    if (widget.notifications.isEmpty && widget.onNotificationTap == null) {
      return SizedBox.shrink();
    }

    return RawMenuAnchor(
      controller: _menuController,
      useRootOverlay: true,
      consumeOutsideTaps: true,
      onCloseRequested: _handleCloseRequested,
      overlayBuilder: _buildOverlay,
      builder: (context, controller, child) {
        final isCompact = context.isCompact;
        final iconSize = isCompact ? kLayrzLayoutCompactIconSize : kLayrzLayoutIconSize;

        return GestureDetector(
          onTap: controller.isOpen ? controller.close : controller.open,
          child: Icon(
            MdiIcons.bellRingOutline,
            size: iconSize,
            color: widget.tokens.colors.fg2,
          ),
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280.0, maxWidth: 320.0),
      decoration: BoxDecoration(
        color: widget.tokens.colors.sf2,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0x00000000).withValues(alpha: 0.12),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: widget.notifications
              .map(
                (notification) => _buildNotificationEntry(context, notification),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationEntry(
    BuildContext context,
    LayrzNotificationItem notification,
  ) {
    final isCompact = context.isCompact;
    final iconSize = isCompact ? kLayrzLayoutCompactIconSize : kLayrzLayoutIconSize;

    return GestureDetector(
      onTap: () {
        notification.onTap?.call();
        widget.onNotificationTap?.call(notification);
        // Keep panel open unless callback closes it
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: widget.tokens.colors.divider,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            if (notification.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 2.0),
                child: Icon(
                  notification.icon,
                  size: iconSize,
                  color: widget.tokens.colors.fg2,
                ),
              ),

            // Title and content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: widget.tokens.colors.fg1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: widget.tokens.colors.fg2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

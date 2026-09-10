import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'notification_item.dart';

/// Signature for building the visual anchor of [LayrzLayoutNotificationsPanel].
///
/// Implementations receive the current [BuildContext], whether the [MenuController]
/// reports the panel as currently open, and a [VoidCallback] that toggles the panel
/// (opens it when closed, closes it when open). The returned widget is the tappable
/// bell affordance — a row (rail footer) or an icon button (top bar) — and does not
/// need to attach its own gesture detector beyond wiring [onTap] to the toggle.
typedef LayrzLayoutNotificationsAnchorBuilder = Widget Function(BuildContext context, bool isOpen, VoidCallback onTap);

/// The notifications panel widget that opens from a bell icon.
///
/// Displays a list of [LayrzNotificationItem] entries in a dropdown panel
/// anchored to a caller-supplied bell affordance. Tapping the anchor toggles the
/// panel open/closed; tapping a notification fires [onNotificationTap]. The panel
/// dismisses on Escape key or tap-outside.
///
/// The visual anchor itself is supplied by the caller via [anchorBuilder], so the
/// same open/close/overlay mechanics can be reused for both the rail footer's row
/// style and the top bar's icon-button style. The panel always opens on tap, even
/// when [notifications] is empty — the overlay then renders an empty-state message
/// instead of leaving the bell an inert, data-gated no-op.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutNotificationsPanel extends StatefulWidget {
  /// Creates a notifications panel.
  const LayrzLayoutNotificationsPanel({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The list of notifications to display.
    ///
    /// When empty, the overlay renders an empty-state message instead of hiding
    /// the anchor or refusing to open.
    required this.notifications,

    /// Callback fired when a notification is tapped.
    required this.onNotificationTap,

    /// Builds the tappable bell affordance that anchors the panel.
    required this.anchorBuilder,
    super.key,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The list of notifications to display.
  ///
  /// When empty, the overlay renders an empty-state message instead of hiding
  /// the anchor or refusing to open.
  final List<LayrzNotificationItem> notifications;

  /// Callback fired when a notification is tapped.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// Builds the tappable bell affordance that anchors the panel.
  final LayrzLayoutNotificationsAnchorBuilder anchorBuilder;

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
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menuController,
      useRootOverlay: true,
      // False (matching LayrzDropdownMenu's proven pattern) because the overlay
      // content below installs its own [TapRegion] with [info.tapRegionGroupId]
      // and handles outside-tap dismissal itself. Setting this to true here
      // caused every tap that lands on the overlay's own content — including a
      // second tap on the anchor, and taps on notification entries — to be
      // treated as "outside" the anchor's tap region and swallowed before
      // reaching the entry's own GestureDetector.
      consumeOutsideTaps: false,
      onCloseRequested: _handleCloseRequested,
      overlayBuilder: _buildOverlay,
      builder: (context, controller, child) {
        return widget.anchorBuilder(
          context,
          controller.isOpen,
          controller.isOpen ? controller.close : controller.open,
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    return TapRegion(
      groupId: info.tapRegionGroupId,
      onTapOutside: (PointerDownEvent event) {
        MenuController.maybeOf(context)?.close();
      },
      child: CustomSingleChildLayout(
        delegate: _NotificationsPanelLayoutDelegate(anchorRect: info.anchorRect),
        // The drop shadow and the rounded-corner clip are deliberately split
        // across two boxes: a [BoxShadow] painted by a decoration that also
        // clips (e.g. via `clipBehavior`) clips its own shadow away, since the
        // shadow is painted just outside the clipped box's edge. So the outer
        // [Container] carries the shadow only (no clip), and the inner
        // [ClipRRect] — with the same radius — clips the scrollable content
        // (entry dividers, hover tint) to the rounded corners. This mirrors
        // [LayrzDropdownMenu]'s panel structure, reusing the same floating-panel
        // elevation token (`tokens.shadow.elevation3`) for visual consistency
        // across the design system's overlay menus.
        child: Container(
          constraints: const BoxConstraints(minWidth: 280.0, maxWidth: 320.0),
          decoration: BoxDecoration(
            color: widget.tokens.colors.sf2,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: widget.tokens.shadow.elevation3,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: widget.notifications.isEmpty
                    ? [_buildEmptyState(context)]
                    : widget.notifications
                          .map(
                            (notification) => _NotificationEntry(
                              tokens: widget.tokens,
                              notification: notification,
                              onNotificationTap: widget.onNotificationTap,
                              onClose: () => MenuController.maybeOf(context)?.close(),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isCompact = context.isCompact;
    final iconSize =
        (isCompact ? widget.tokens.typography.body.fontSize : widget.tokens.typography.label.fontSize) ??
        (isCompact ? 14.0 : 12.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            MdiIcons.bellOffOutline,
            size: iconSize * 2,
            color: widget.tokens.colors.fg3,
          ),
          const SizedBox(height: 8.0),
          SelectionContainer.disabled(
            child: Text(
              'No notifications',
              style: TextStyle(
                fontSize: 13.0,
                color: widget.tokens.colors.fg3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single notification row rendered inside the notifications panel overlay.
///
/// Mirrors [LayrzLayoutRailItem]'s vertical rhythm — the same [LayrzTokens]
/// spacing pattern (`pd3` on compact viewports, `pd2` on wide ones) and the
/// same icon-to-text gap (`sp2`) — and the same hover treatment (a
/// [MouseRegion] with a click cursor, tinting the background with
/// `tokens.colors.primary` at [kLayrzLayoutItemHoverBackgroundOpacity]). Hover
/// state is tracked per entry, which is why this is a small [StatefulWidget]
/// rather than a builder method on the panel — each row needs its own
/// `_isHovered` flag.
///
/// Whether a row shows this interactive affordance at all is decided solely by
/// [LayrzNotificationItem.onTap]: a row with no per-item `onTap` renders flat
/// — [SystemMouseCursors.basic] and no hover tint — even though the
/// panel-level `onNotificationTap` may still fire when it is tapped. The panel
/// callback is a passive "you tapped a notification" reporter, not a per-row
/// affordance signal, so it never gates hover/cursor.
///
/// A tappable row (per-item `onTap` set) also closes the notifications panel
/// after firing its callbacks — a tap normally navigates the user somewhere,
/// so the panel should dismiss the way a menu item would. A non-tappable row
/// has no tap handler at all, so this never applies to it.
///
/// This widget is private to the layout module and is not exported.
class _NotificationEntry extends StatefulWidget {
  /// Creates a notification entry row.
  const _NotificationEntry({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The notification data rendered by this row.
    required this.notification,

    /// Callback fired (in addition to [LayrzNotificationItem.onTap]) when this
    /// row is tapped.
    required this.onNotificationTap,

    /// Closes the notifications panel.
    ///
    /// Invoked after [LayrzNotificationItem.onTap] and [onNotificationTap] fire,
    /// but only for a tappable row (per-item `onTap` set) — a non-tappable row
    /// has no tap handler and never calls this.
    required this.onClose,
  });

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The notification data rendered by this row.
  final LayrzNotificationItem notification;

  /// Callback fired (in addition to [LayrzNotificationItem.onTap]) when this
  /// row is tapped.
  final void Function(LayrzNotificationItem)? onNotificationTap;

  /// Closes the notifications panel.
  ///
  /// Invoked after [LayrzNotificationItem.onTap] and [onNotificationTap] fire,
  /// but only for a tappable row (per-item `onTap` set) — a non-tappable row
  /// has no tap handler and never calls this.
  final VoidCallback onClose;

  @override
  State<_NotificationEntry> createState() => _NotificationEntryState();
}

class _NotificationEntryState extends State<_NotificationEntry> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final notification = widget.notification;
    final isCompact = context.isCompact;
    final iconSize =
        (isCompact ? tokens.typography.body.fontSize : tokens.typography.label.fontSize) ?? (isCompact ? 14.0 : 12.0);
    final entryPadding = isCompact ? tokens.spacing.pd3 : tokens.spacing.pd2;

    // Hover/cursor affordance is gated on the per-item onTap ONLY. The
    // panel-level onNotificationTap may still fire on tap (see below), but it
    // does not make a row read as interactive — only LayrzNotificationItem.onTap does.
    final isTappable = notification.onTap != null;

    final backgroundColor = (isTappable && _isHovered)
        ? tokens.colors.primary.withValues(alpha: kLayrzLayoutItemHoverBackgroundOpacity)
        : const Color(0x00000000);

    return MouseRegion(
      cursor: isTappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isTappable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isTappable) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        key: ValueKey('notification_entry_${notification.id}'),
        onTap: () {
          notification.onTap?.call();
          widget.onNotificationTap?.call(notification);
          // A tappable row (per-item onTap set) closes the panel after firing
          // its callbacks — a tap normally navigates the user somewhere, so
          // the panel dismisses like a menu item would. A non-tappable row has
          // no onTap and is excluded from this by the isTappable guard.
          if (isTappable) widget.onClose();
        },
        child: Container(
          padding: entryPadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: tokens.colors.divider,
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
                  padding: EdgeInsets.only(right: tokens.spacing.sp2, top: 2.0),
                  child: Icon(
                    notification.icon,
                    size: iconSize,
                    color: tokens.colors.fg2,
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
                        color: tokens.colors.fg1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: tokens.spacing.sp2),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: tokens.colors.fg2,
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
      ),
    );
  }
}

/// Positions the notifications panel relative to its anchor rect.
///
/// Prefers opening below the anchor (the typical case for the top bar's bell,
/// which sits near the top of the screen); falls back to opening above when
/// there is insufficient space below (the typical case for the rail's bell
/// row, which sits at the bottom of the navigation panel). Horizontally, the
/// panel's right edge aligns with the anchor's right edge and then clamps
/// into the overlay bounds, matching the leading-edge-agnostic placement used
/// by [LayrzDropdownMenu]'s own layout delegate.
class _NotificationsPanelLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates a layout delegate for the notifications panel.
  _NotificationsPanelLayoutDelegate({
    /// The anchor widget's position and size, supplied by [RawMenuOverlayInfo].
    required this.anchorRect,
  });

  /// The anchor widget's position and size, supplied by [RawMenuOverlayInfo].
  final Rect anchorRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 280.0,
      maxWidth: 320.0,
      maxHeight: (constraints.maxHeight - 16.0).clamp(0.0, double.infinity),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 4.0;

    final belowY = anchorRect.bottom + gap;
    final aboveY = anchorRect.top - childSize.height - gap;

    final y = (belowY + childSize.height <= size.height) ? belowY : (aboveY >= 0 ? aboveY : belowY);
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    final x = anchorRect.right - childSize.width;
    final clampedX = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));

    return Offset(clampedX, clampedY);
  }

  @override
  bool shouldRelayout(_NotificationsPanelLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect;
  }
}

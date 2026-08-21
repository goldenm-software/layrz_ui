import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'navigator_item.dart';
import 'notification_item.dart';
import 'rail_item.dart';
import 'user_chrome.dart';

/// A unified navigation panel widget for both expanded (rail) and drawer presentations.
///
/// This widget is private to the layout module and is not exported. It renders a
/// vertical navigation panel with search, items, and user chrome. The presentation
/// is controlled via the [width] and [onClose] parameters:
///
/// - Persistent (rail) mode: [onClose] is null, panel casts a shadow, no close affordance
/// - Drawer mode: [onClose] is non-null, panel has no shadow, tapping items calls [onClose]
class LayrzLayoutNavigatorPanel extends StatefulWidget {
  /// Creates a navigation panel.
  const LayrzLayoutNavigatorPanel({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The width of the panel in logical pixels.
    ///
    /// Typically [kLayrzLayoutRailWidth] (220.0) for persistent mode
    /// or [kLayrzLayoutDrawerWidth] (260.0) for drawer mode.
    required this.width,

    /// The navigation items to display.
    required this.items,

    /// A widget displayed in the panel header.
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

    /// Callback fired when the panel should close.
    ///
    /// When null, the panel is persistent (rail mode) and does not show a close affordance.
    /// When non-null, the panel is in drawer mode and invokes this callback when navigation
    /// items are tapped. The panel does not render a close button; the affordance is
    /// provided by the enclosing drawer scaffold (swipe, tap outside).
    this.onClose,

    /// Function to derive initials from a name.
    required this.getInitials,
    super.key,
  });

  @override
  State<LayrzLayoutNavigatorPanel> createState() => _LayrzLayoutNavigatorPanelState();

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The width of the panel in logical pixels.
  final double width;

  /// The navigation items to display.
  final List<LayrzNavigatorItem> items;

  /// A source image for the layout's logo, displayed in the panel header.
  final String logo;

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

  /// Callback fired when the panel should close (drawer mode only).
  final VoidCallback? onClose;

  /// Function to derive initials from a name.
  final String Function(String?) getInitials;
}

class _LayrzLayoutNavigatorPanelState extends State<LayrzLayoutNavigatorPanel> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final isPersistent = widget.onClose == null;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: tokens.colors.sf1,
        boxShadow: isPersistent ? tokens.shadow.elevation2 : null,
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo block with edge-to-edge width and 100px height ceiling
            if (widget.logo.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: tokens.spacing.sp2,
                  right: tokens.spacing.sp2,
                  top: tokens.spacing.sp3,
                  bottom: tokens.spacing.sp2,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: LayrzImage(
                    source: widget.logo,
                    width: 80,
                    height: 30,
                    fit: BoxFit.contain,
                    alignment: .centerLeft,
                  ),
                ),
              ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.sp2,
              ),
              child: LayrzTextInput(
                hintText: context.l10n.actionSearch,
                hideDetails: true,
                controller: _searchController,
                onChanged: (_) {},
                prefixIcon: MdiIcons.magnify,
              ),
            ),

            // Navigation items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildFilteredItems(tokens),
                ),
              ),
            ),

            // Footer: 1px divider + notifications + user chrome
            Container(
              height: 1.0,
              color: tokens.colors.divider,
            ),
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.sp2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Notifications row
                  if (widget.notifications.isNotEmpty || widget.onNotificationTap != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.sp2,
                      ),
                      child: _buildNotificationsRow(tokens),
                    ),

                  if (widget.notifications.isNotEmpty || widget.onNotificationTap != null)
                    SizedBox(height: tokens.spacing.sp2),

                  // User chrome
                  Padding(
                    padding: EdgeInsets.only(
                      left: tokens.spacing.sp2,
                      right: tokens.spacing.sp2,
                      bottom: tokens.spacing.sp2,
                    ),
                    child: LayrzLayoutUserChrome(
                      tokens: tokens,
                      userName: widget.userName,
                      userAvatar: widget.userAvatar,
                      userMenuItems: widget.userMenuItems,
                      getInitials: widget.getInitials,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredItems(LayrzTokens tokens) {
    LayrzNavigatorLabel? currentLabel;
    bool currentLabelHasMatches = false;
    final results = <Widget>[];

    for (final item in widget.items) {
      switch (item) {
        case LayrzNavigatorPage():
          final matches = _searchQuery.isEmpty || item.labelText.toLowerCase().contains(_searchQuery);

          if (matches) {
            if (currentLabel != null && !currentLabelHasMatches) {
              results.add(_buildSectionCaption(currentLabel));
              currentLabelHasMatches = true;
            }

            results.add(
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.sp2,
                ),
                child: LayrzLayoutRailItem(
                  tokens: tokens,
                  page: item,
                  isSelected: item.isSelected,
                  onTap: () {
                    item.onTap?.call();
                    widget.onClose?.call();
                  },
                ),
              ),
            );
          }

        case LayrzNavigatorLabel():
          currentLabel = item;
          currentLabelHasMatches = false;
      }
    }

    if (results.isEmpty && _searchQuery.isNotEmpty) {
      results.add(
        Padding(
          padding: EdgeInsets.only(
            top: tokens.spacing.sp3,
            left: tokens.spacing.sp2,
          ),
          child: Text(
            'No results',
            style: TextStyle(
              fontSize: tokens.typography.label.fontSize,
              fontWeight: kLayrzLayoutNoResultsFontWeight,
              color: tokens.colors.fg3,
            ),
          ),
        ),
      );
    }

    return results.isEmpty && _searchQuery.isEmpty ? _buildAllItems(tokens) : results;
  }

  List<Widget> _buildAllItems(LayrzTokens tokens) {
    final widgets = <Widget>[];

    for (final item in widget.items) {
      switch (item) {
        case LayrzNavigatorPage():
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.sp2,
              ),
              child: LayrzLayoutRailItem(
                tokens: tokens,
                page: item,
                isSelected: item.isSelected,
                onTap: () {
                  item.onTap?.call();
                  widget.onClose?.call();
                },
              ),
            ),
          );
        case LayrzNavigatorLabel():
          widgets.add(_buildSectionCaption(item));
      }
    }

    return widgets;
  }

  Widget _buildSectionCaption(LayrzNavigatorLabel label) {
    final tokens = widget.tokens;
    final effectiveColor = label.color ?? tokens.colors.primary;
    final band = effectiveColor.withOpacityValue(tokens.colors.tonalOpacity).flattenOn(tokens.colors.sf1);

    return Container(
      margin: EdgeInsets.only(
        top: tokens.spacing.sp2,
        bottom: tokens.spacing.sp2,
      ),
      child: Container(
        width: double.infinity,
        color: band,
        padding: EdgeInsets.only(
          left: tokens.spacing.sp2,
          right: tokens.spacing.sp2,
          top: tokens.spacing.sp2,
          bottom: tokens.spacing.sp2,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label.labelText.toUpperCase(),
            style: tokens.typography.label.copyWith(
              color: effectiveColor,
              letterSpacing: 0.11 * (tokens.typography.label.fontSize ?? 14),
              fontWeight: kLayrzLayoutSectionCaptionFontWeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsRow(LayrzTokens tokens) {
    return Builder(
      builder: (context) {
        final isCompact = context.isCompact;
        final rowHeight = isCompact ? kLayrzLayoutCompactNotificationsRowHeight : kLayrzLayoutNotificationsRowHeight;
        final iconSize = isCompact ? kLayrzLayoutCompactIconSize : kLayrzLayoutIconSize;
        final fontSize = isCompact ? tokens.typography.body.fontSize : tokens.typography.label.fontSize;

        return Container(
          height: rowHeight,
          decoration: BoxDecoration(
            color: tokens.colors.sf3,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Icon(
                  MdiIcons.bellRingOutline,
                  size: iconSize,
                  color: tokens.colors.fg2,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: kLayrzLayoutNotificationsLabelFontWeight,
                      color: tokens.colors.fg1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    widget.notifications.length.toString(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: tokens.colors.fg2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

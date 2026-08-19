import 'package:layrz_icons/layrz_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'navigator_item.dart';
import 'notification_item.dart';
import 'rail_item.dart';
import 'user_chrome.dart';

/// The navigation rail widget displayed in expanded presentation.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutRail extends StatefulWidget {
  /// Creates a navigation rail.
  const LayrzLayoutRail({
    /// The design tokens for colors and spacing.
    required this.tokens,

    /// The navigation items to display.
    required this.items,

    /// A widget displayed in the rail header.
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

    /// Function to derive initials from a name.
    required this.getInitials,
    super.key,
  });

  @override
  State<LayrzLayoutRail> createState() => _LayrzLayoutRailState();

  /// The design tokens for colors and spacing.
  final LayrzTokens tokens;

  /// The navigation items to display.
  final List<LayrzNavigatorItem> items;

  /// A widget displayed in the rail header.
  final Widget? logo;

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

  /// Function to derive initials from a name.
  final String Function(String?) getInitials;
}

class _LayrzLayoutRailState extends State<LayrzLayoutRail> {
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
    return Container(
      width: kLayrzLayoutRailWidth,
      decoration: BoxDecoration(
        color: tokens.colors.surface,
        boxShadow: tokens.shadow.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo block (constrained to 80% width, 40px height)
          if (widget.logo != null)
            Padding(
              padding: const EdgeInsets.only(
                left: kLayrzLayoutLogoLeftPadding,
                top: kLayrzLayoutRailPaddingVertical,
                bottom: kLayrzLayoutLogoBottomPadding,
              ),
              child: SizedBox(
                width: kLayrzLayoutRailWidth * kLayrzLayoutLogoWidthFactor,
                height: kLayrzLayoutLogoHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: widget.logo!,
                ),
              ),
            ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kLayrzLayoutRailPaddingHorizontal,
            ),
            child: _buildSearchField(tokens),
          ),

          SizedBox(height: kLayrzLayoutRailPaddingVertical),

          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kLayrzLayoutRailPaddingHorizontal,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildFilteredItems(tokens),
                ),
              ),
            ),
          ),

          // Footer: 1px divider + notifications + user chrome
          Container(
            height: 1.0,
            color: tokens.colors.divider,
          ),
          Padding(
            padding: const EdgeInsets.only(top: kLayrzLayoutFooterPaddingTop),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notifications row
                if (widget.notifications.isNotEmpty || widget.onNotificationTap != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kLayrzLayoutRailPaddingHorizontal,
                    ),
                    child: _buildNotificationsRow(tokens),
                  ),

                if (widget.notifications.isNotEmpty || widget.onNotificationTap != null)
                  const SizedBox(height: kLayrzLayoutFooterGap),

                // User chrome
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kLayrzLayoutRailPaddingHorizontal,
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
    );
  }

  Widget _buildSearchField(LayrzTokens tokens) {
    return SizedBox(
      height: kLayrzLayoutSearchFieldHeight,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.colors.surface2,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: tokens.colors.divider,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                LayrzIcons.solarOutlineMagnifer,
                size: kLayrzLayoutSearchFieldIconSize,
                color: tokens.colors.fg3,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kLayrzLayoutSearchFieldInternalPaddingHorizontal,
                ),
                child: EditableText(
                  controller: _searchController,
                  focusNode: FocusNode(),
                  style: TextStyle(
                    fontSize: kLayrzLayoutSearchFieldFontSize,
                    color: tokens.colors.fg1,
                  ),
                  cursorColor: tokens.colors.primary,
                  backgroundCursorColor: tokens.colors.surface2,
                ),
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
              results.add(_buildSectionCaption(currentLabel.labelText));
              currentLabelHasMatches = true;
            }

            results.add(
              LayrzLayoutRailItem(
                tokens: tokens,
                page: item,
                isSelected: item.isSelected,
                onTap: () {
                  item.onTap?.call();
                },
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
          padding: const EdgeInsets.only(
            top: kLayrzLayoutSectionCaptionPaddingTop,
            left: kLayrzLayoutSectionCaptionPaddingLeft,
          ),
          child: Text(
            'No results',
            style: TextStyle(
              fontSize: kLayrzLayoutSectionCaptionFontSize,
              fontWeight: kLayrzLayoutSectionCaptionFontWeight,
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
          color: widget.tokens.colors.fg3,
        ),
      ),
    );
  }

  Widget _buildNotificationsRow(LayrzTokens tokens) {
    return Container(
      height: kLayrzLayoutNotificationsRowHeight,
      decoration: BoxDecoration(
        color: tokens.colors.surface3,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Icon(
              LayrzIcons.solarOutlineBell,
              size: 16.0,
              color: tokens.colors.fg2,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: kLayrzLayoutNotificationsLabelFontSize,
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
                  fontSize: kLayrzLayoutNotificationsCountFontSize,
                  fontWeight: FontWeight.w500,
                  color: tokens.colors.fg2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

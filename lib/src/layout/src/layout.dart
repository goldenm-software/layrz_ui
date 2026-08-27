import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/images.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

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
  /// are optional and default to null or empty collections. The [selectableContent]
  /// parameter defaults to `true`, enabling text selection within the layout's body.
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
    this.selectableContent = true,
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
  /// Defaults to [LayrzTokens.colors.sf1].
  final Color? backgroundColor;

  /// Whether text selection should be enabled within the layout.
  ///
  /// When `true` (the default), a single [SelectableRegion] wraps the layout's body,
  /// allowing users to select and copy text across the page content with drag selection
  /// and Ctrl+A / Ctrl+C keyboard shortcuts.
  ///
  /// When `false`, no [SelectableRegion] is present and text selection is disabled for
  /// content within this layout. The selection region is entirely absent from the widget
  /// tree, not merely inert.
  ///
  /// **Toolbar behavior**: When text is selected, a Copy-only toolbar appears above
  /// the selection (or below if insufficient space above). The toolbar contains only
  /// the Copy action; cut, paste, and select all are hidden to keep the read-only
  /// page focused. The copy action wires directly to the system clipboard.
  ///
  /// **Desktop behavior**: Text can be selected with click-drag and Ctrl+A, and
  /// copied with Ctrl+C or the toolbar Copy button.
  ///
  /// **Touch behavior**: Selection works with long-press magnifier and selection handles.
  /// The same Copy-only toolbar appears above the selection.
  ///
  /// **Scope**: The region encompasses the layout's body and all widgets mounted within it.
  /// Overlays (dialogs, bottom sheets, menus, tooltips) mounted into the app's Overlay
  /// are outside this region and cannot be selected.
  final bool selectableContent;

  @override
  State<LayrzLayout> createState() => _LayrzLayoutState();
}

class _LayrzLayoutState extends State<LayrzLayout> {
  /// The long-lived [FocusNode] for text selection within the layout.
  ///
  /// Created once when the state is initialized and reused across all rebuilds.
  /// Disposed when the state is disposed. Only created if [selectableContent] is true.
  late FocusNode _selectableFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.selectableContent) {
      _selectableFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(LayrzLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If selectableContent changed from false to true, create the node
    if (!oldWidget.selectableContent && widget.selectableContent) {
      _selectableFocusNode = FocusNode();
    }
    // If selectableContent changed from true to false, dispose the node
    if (oldWidget.selectableContent && !widget.selectableContent) {
      _selectableFocusNode.dispose();
    }
  }

  @override
  void dispose() {
    if (widget.selectableContent) {
      _selectableFocusNode.dispose();
    }
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Builds the context menu for text selection, displaying a Copy-only toolbar.
  ///
  /// This builder is passed to [SelectableRegion] to render a toolbar when the user
  /// triggers a selection context menu (long-press or right-click). The toolbar is
  /// positioned automatically above or below the selection using the standard
  /// [TextSelectionToolbarLayoutDelegate].
  ///
  /// The toolbar displays only the Copy action (no cut, paste, or select all),
  /// keeping the read-only page-wide selection focused on copying selected text.
  /// The copy action invokes the selection state's clipboard copy handler, which
  /// handles clipboard transfer via the platform channels.
  Widget _buildContextMenu(
    BuildContext context,
    SelectableRegionState state,
  ) {
    final tokens = context.theme.tokens;
    final anchors = state.contextMenuAnchors;

    final toolbar = LayrzSelectionToolbar(
      actions: {LayrzSelectableAction.copy},
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor,
      tokens: tokens,
      onActionPressed: (actionType) {
        if (actionType == 'copy') {
          // ignore: deprecated_member_use
          state.copySelection(SelectionChangedCause.toolbar);
        }
      },
    );

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
      ),
      child: toolbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.theme.tokens;
    final backgroundColor = widget.backgroundColor ?? tokens.colors.sf1;

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
    final bodyWidget = widget.selectableContent
        ? SelectableRegion(
            focusNode: _selectableFocusNode,
            selectionControls: LayrzTextSelectionControls.instance,
            contextMenuBuilder: _buildContextMenu,
            child: widget.body,
          )
        : widget.body;

    // Scaffold-style keyboard handling: reduce the bottom of both the body and the rail
    // panel by viewInsets.bottom, then zero viewInsets for their subtrees so nested widgets
    // that read MediaQuery.viewInsetsOf do not double-count the same inset.
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          Positioned.directional(
            textDirection: Directionality.of(context),
            start: kLayrzLayoutRailWidth,
            end: 0,
            top: 0,
            bottom: viewInsets.bottom,
            // Both removals are composed in one MediaQuery, built by chaining on the
            // MediaQueryData itself (removeViewInsets(...).removePadding(...)) rather than
            // nesting two MediaQuery.removeXxx(context: context, ...) widgets -- each of
            // those factories independently re-reads MediaQuery.of(context) from the same
            // outer context, so a nested inner call would rebuild from the untouched
            // ambient data and silently discard the outer removal (see
            // LayrzLayoutDrawerScaffold for the same fix and its full derivation).
            //
            // Unlike the drawer presentation, this body is a Positioned sibling of the
            // rail panel in a Stack, with no SafeArea or other chrome of its own consuming
            // padding.top before the body sees it. The rail panel (below) does consume its
            // OWN padding.top, via navigator_panel.dart's SafeArea(right: false) -- but
            // that only affects the panel's own subtree, not this sibling. So a bare
            // ListView.builder in the body still falls back to the ambient
            // MediaQuery.padding for its scroll axis (scroll_view.dart:897-925) and
            // double-insets by the same status-bar height, exactly as in the drawer
            // presentation, just via a Stack instead of a Column.
            child: MediaQuery(
              data: MediaQuery.of(context).removeViewInsets(removeBottom: true).removePadding(removeTop: true),
              child: bodyWidget,
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: viewInsets.bottom,
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: LayrzLayoutNavigatorPanel(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, LayrzTokens tokens, Color backgroundColor) {
    final bodyWidget = widget.selectableContent
        ? SelectableRegion(
            focusNode: _selectableFocusNode,
            selectionControls: LayrzTextSelectionControls.instance,
            contextMenuBuilder: _buildContextMenu,
            child: widget.body,
          )
        : widget.body;

    return LayrzLayoutDrawerScaffold(
      backgroundColor: backgroundColor,
      drawerBackgroundColor: tokens.colors.sf1,
      topBarBuilder: (openDrawer) => LayrzLayoutTopBar(
        tokens: tokens,
        logo: widget.logo,
        notifications: widget.notifications,
        onNotificationTap: widget.onNotificationTap,
        onDrawerTap: openDrawer,
      ),
      body: bodyWidget,
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

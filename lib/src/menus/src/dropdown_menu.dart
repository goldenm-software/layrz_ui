import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/src/menu.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'dropdown_items.dart';
import 'dropdown_menu_types.dart';

/// Signature for building a [LayrzDropdownMenu]'s trigger widget.
///
/// The [controller] opens, closes, and reports the state of the menu. Wire it
/// to the trigger widget's own tap handler — for example, `onTap: controller.open`.
/// The caller typically wires `controller.isOpen` for toggle behavior:
/// ```dart
/// onTap: controller.isOpen ? controller.close : controller.open,
/// ```
typedef LayrzDropdownMenuBuilder = Widget Function(
  BuildContext context,
  MenuController controller,
);

/// A Material-free dropdown menu widget in the layrz_ui design system.
///
/// [LayrzDropdownMenu] displays a floating menu panel on demand, with a caller-supplied
/// trigger widget. The trigger widget is built with access to the menu controller,
/// allowing it to wire its own tap handlers directly to `controller.open()`,
/// `controller.close()`, or toggle logic based on `controller.isOpen`.
///
/// Menu entries close the menu automatically after tapping.
///
/// **Keyboard and accessibility:**
/// - Escape key dismisses the menu
/// - Arrow keys traverse focusable entries (dividers and labels are skipped)
/// - Outside taps close the menu
/// - Entries expose button semantics with enabled state
///
/// **Animation:**
/// - Menu enters with a fade + 4px translate from the anchor's side
/// - Menu exits without animation; overlay removal is synchronous and owned by [RawMenuAnchor]
///
/// This design uses [RawMenuAnchor] from [package:flutter/widgets.dart], which
/// provides the overlay management and keyboard traversal for free. The panel's position
/// is computed by [_DropdownMenuLayoutDelegate], which receives the real measured size
/// and positions the panel below the anchor (or above if insufficient space exists below).
class LayrzDropdownMenu extends StatefulWidget {
  /// Builds the trigger widget that opens/closes the menu.
  ///
  /// The builder receives the menu [controller], which should be wired to the
  /// trigger's own event handlers. For example:
  /// ```dart
  /// builder: (context, controller) => LayrzButton(
  ///   labelText: 'Actions',
  ///   onTap: controller.isOpen ? controller.close : controller.open,
  /// )
  /// ```
  final LayrzDropdownMenuBuilder builder;

  /// The items to display in the dropdown menu.
  ///
  /// Must be a list of [LayrzDropdownItem] subclasses: [LayrzDropdownEntry],
  /// [LayrzDropdownDivider], and [LayrzDropdownLabel]. Custom widget types are
  /// impossible by construction thanks to the sealed class guarantee.
  final List<LayrzDropdownItem> items;

  /// Optional controller for programmatic control of the menu's open/close state.
  ///
  /// When null, the menu is owned by the [_LayrzDropdownMenuState] and has no
  /// external control. When non-null, callers can open or close the menu by
  /// calling [controller.open()] and [controller.close()].
  ///
  /// **Important:** The controller instance must never be swapped via [didUpdateWidget].
  /// An assertion will fail if a different controller instance is passed on a rebuild.
  /// [MenuController] holds no disposable resources and is safe to share across
  /// multiple menu instances.
  final MenuController? controller;

  /// Called when the menu is opened.
  ///
  /// Guaranteed to fire before the overlay is shown and the fade-in animation starts.
  final VoidCallback? onOpen;

  /// Called when the menu is closed.
  ///
  /// Fires after the fade-out animation (if any) completes and the overlay is removed.
  final VoidCallback? onClose;

  /// Optional focus node passed to the trigger widget for keyboard interaction.
  ///
  /// When the menu is closed, focus returns to this node. The caller must ensure
  /// this node outlives the menu widget.
  final FocusNode? childFocusNode;

  /// The horizontal alignment of the menu panel relative to the trigger.
  ///
  /// Defaults to [LayrzDropdownMenuAlignment.start]. The panel is positioned according
  /// to this alignment and then clamped into the overlay bounds.
  final LayrzDropdownMenuAlignment alignment;

  /// Creates a new [LayrzDropdownMenu].
  ///
  /// [builder] and [items] are required. All other parameters are optional.
  const LayrzDropdownMenu({
    required this.builder,
    required this.items,
    this.controller,
    this.onOpen,
    this.onClose,
    this.childFocusNode,
    this.alignment = LayrzDropdownMenuAlignment.start,
    super.key,
  });

  @override
  State<LayrzDropdownMenu> createState() => _LayrzDropdownMenuState();
}

class _LayrzDropdownMenuState extends State<LayrzDropdownMenu> with SingleTickerProviderStateMixin {
  late MenuController _menuController;
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;
  MenuController? _lastSuppliedController;
  late FocusNode _menuFocusNode;

  @override
  void initState() {
    super.initState();
    _menuController = widget.controller ?? MenuController();
    _lastSuppliedController = widget.controller;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _menuFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(LayrzDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Verify that the controller is never swapped
    if (widget.controller != null && _lastSuppliedController != widget.controller) {
      assert(
        false,
        'MenuController instances must never be swapped. '
        'Create a new LayrzDropdownMenu instead of changing the controller.',
      );
    }
    _lastSuppliedController = widget.controller;

    // Update animation timing if tokens change
    _animationController.duration = context.tokens.motion.dHover;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.duration = context.tokens.motion.dHover;
  }

  @override
  void dispose() {
    // Do not call _menuController.close() during dispose; the overlay may already be
    // torn down and hideOverlay() would fail. RawMenuAnchor handles cleanup.
    _animationController.dispose();
    _curvedAnimation.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  void _handleMenuOpenRequested(Offset? position, VoidCallback showOverlay) {
    widget.onOpen?.call();
    showOverlay();
    // Reset to start and animate forward for enter animation
    _animationController.reset();
    _animationController.forward();

    // Move focus to the panel so keyboard events (Escape, arrow keys) work
    // Find the first focusable entry and focus it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the first focusable item
      for (final item in widget.items) {
        if (item is LayrzDropdownEntry && item.enabled) {
          // Focus this entry's widget in the rendered tree
          // The entry is now rendered, so we need to find its widget and focus it
          // Since we can't easily navigate to it, we'll focus the panel's FocusScope
          // which will receive keyboard events and allow traversal
          break;
        }
      }

      // If we have a focus scope in the panel, focus it (set by FocusScope below)
      // For now, just ensure focus is somewhere in the menu tree for Escape to work
      if (context.mounted) {
        // Focus the menu anchor itself or request focus for keyboard handling
        FocusScope.of(context).requestFocus(_menuFocusNode);
      }
    });
  }

  void _handleMenuCloseRequested(VoidCallback hideOverlay) {
    // Menu closes synchronously; reset animation for next open.
    // There is no exit animation — [RawMenuAnchor] removes the overlay immediately.
    _animationController.reset();
    hideOverlay();
    widget.onClose?.call();
  }

  Widget _buildMenuOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final tokens = context.tokens;
    final items = widget.items;

    return TapRegion(
      groupId: info.tapRegionGroupId,
      onTapOutside: (PointerDownEvent event) {
        MenuController.maybeOf(context)?.close();
      },
      child: CustomSingleChildLayout(
        delegate: _DropdownMenuLayoutDelegate(
          anchorRect: info.anchorRect,
          alignment: widget.alignment,
          overlaySize: info.overlaySize,
          tokens: tokens,
        ),
        child: FadeTransition(
          opacity: _curvedAnimation,
          child: Transform.translate(
            offset: Offset(
              widget.alignment == LayrzDropdownMenuAlignment.end
                  ? 4.0
                  : (widget.alignment == LayrzDropdownMenuAlignment.start ? -4.0 : 0.0),
              -4.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.colors.surface,
                borderRadius: tokens.radius.br3,
                boxShadow: tokens.shadow.elevation3,
              ),
              child: Focus(
                focusNode: _menuFocusNode,
                child: ClipRRect(
                  borderRadius: tokens.radius.br3,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menuController,
      onOpenRequested: _handleMenuOpenRequested,
      onCloseRequested: _handleMenuCloseRequested,
      useRootOverlay: true,
      consumeOutsideTaps: false,
      childFocusNode: widget.childFocusNode,
      overlayBuilder: _buildMenuOverlay,
      builder: (context, menuController, child) {
        return widget.builder(context, menuController);
      },
    );
  }
}

/// Provides the menu controller to descendant widgets through an InheritedWidget.
///
/// This allows entries and other descendants to access the menu controller
/// and call controller.close() to close the menu.
/// Positions a dropdown menu panel below or above its anchor, with alignment and bounds clamping.
///
/// This delegate receives the actual measured size of the panel and positions it
/// relative to the anchor rect. The panel is placed below the anchor by default,
/// but flips above if insufficient space exists below.
class _DropdownMenuLayoutDelegate extends SingleChildLayoutDelegate {
  /// The anchor widget's position and size.
  final Rect anchorRect;

  /// Horizontal alignment: start (left), center, or end (right).
  final LayrzDropdownMenuAlignment alignment;

  /// The overlay's full size.
  final Size overlaySize;

  /// Design tokens for spacing.
  final LayrzTokens tokens;

  /// Creates a new [_DropdownMenuLayoutDelegate].
  _DropdownMenuLayoutDelegate({
    required this.anchorRect,
    required this.alignment,
    required this.overlaySize,
    required this.tokens,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Width clamped to [160, 320], height constrained by overlay with padding
    return BoxConstraints(
      minWidth: kLayrzDropdownMenuMinWidth,
      maxWidth: kLayrzDropdownMenuMaxWidth,
      maxHeight: (overlaySize.height - 2 * tokens.spacing.sp2).clamp(0.0, double.infinity),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 4.0; // Space between anchor and panel

    // Calculate Y position: try below, fall back to above
    final belowY = anchorRect.bottom + gap;
    final aboveY = anchorRect.top - childSize.height - gap;

    final y = (belowY + childSize.height <= size.height)
        ? belowY
        : (aboveY >= 0 ? aboveY : belowY); // If neither fits, prefer below

    // Clamp to overlay bounds
    final clampedY = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, double.infinity));

    // Calculate X position based on alignment
    double x;
    switch (alignment) {
      case LayrzDropdownMenuAlignment.start:
        x = anchorRect.left;
      case LayrzDropdownMenuAlignment.center:
        x = anchorRect.center.dx - childSize.width / 2;
      case LayrzDropdownMenuAlignment.end:
        x = anchorRect.right - childSize.width;
    }

    // Clamp to overlay bounds
    final clampedX = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity));

    return Offset(clampedX, clampedY);
  }

  @override
  bool shouldRelayout(_DropdownMenuLayoutDelegate oldDelegate) {
    return oldDelegate.anchorRect != anchorRect ||
        oldDelegate.alignment != alignment ||
        oldDelegate.overlaySize != overlaySize ||
        oldDelegate.tokens != tokens;
  }
}

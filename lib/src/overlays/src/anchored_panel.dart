import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/positioning/positioning.dart';

import 'anchored_panel_layout_delegate.dart';

/// Signature for building an anchored panel's anchor/trigger widget.
///
/// The [controller] opens, closes, and reports the state of the panel. Wire it
/// to the anchor widget's own event handlers — for example, `onTap: controller.open`.
typedef LayrzAnchoredPanelBuilder = Widget Function(
  BuildContext context,
  MenuController controller,
);

/// A Material-free anchored overlay panel in the layrz_ui design system.
///
/// [LayrzAnchoredPanel] displays a floating panel anchored to a trigger widget,
/// with the trigger widget built with access to the panel controller.
/// The panel flips above or below the anchor depending on available space,
/// similar to a web combobox or select dropdown.
///
/// **Sizing:**
/// - **Width:** Configured via [widthPolicy]:
///   - [LayrzAnchoredPanelWidthPolicy.matchAnchor]: panel width equals anchor width (default, suitable for input fields)
///   - [LayrzAnchoredPanelWidthPolicy.contentSized]: panel width clamped to [widthBounds] (suitable for icon buttons)
/// - **Height:** Constrained by [maxHeight] (if provided) and overlay bounds minus padding.
///   Content overflows are handled via scrolling inside the panel.
///
/// **Positioning:**
/// - Panel is positioned on [preferredSide] of the anchor (default
///   [LayrzPreferredSide.bottom] — existing call sites do not move), separated by
///   [gap] (default 4.0).
/// - If the panel does not fit on [preferredSide], it flips unconditionally to the
///   opposite side — there is no second fit test. When neither side fits, the
///   panel lands on the opposite side and is clamped into the overlay.
/// - Cross-axis alignment relative to the resolved side is controlled by
///   [alignment] (start, center, end).
/// - Panel is clamped to overlay bounds on both axes; its width is additionally
///   clamped to the space actually available in the overlay.
///
/// **Keyboard and accessibility:**
/// - Escape key dismisses the panel
/// - Focus can be managed via [childFocusNode]
/// - Tap outside closes the panel
/// - Keyboard traversal into the panel is supported
///
/// **Animation:**
/// - Panel enters with a fade transition
/// - Panel exits without animation
///
/// This design uses [RawMenuAnchor] from [package:flutter/widgets.dart], which
/// provides overlay management and keyboard traversal.
class LayrzAnchoredPanel extends StatefulWidget {
  /// Builds the anchor/trigger widget that opens/closes the panel.
  ///
  /// The builder receives the panel [controller], which should be wired to the
  /// anchor's event handlers. For example:
  /// ```dart
  /// builder: (context, controller) => LayrzButton(
  ///   labelText: 'Open',
  ///   onTap: controller.isOpen ? controller.close : controller.open,
  /// )
  /// ```
  final LayrzAnchoredPanelBuilder builder;

  /// The content to display in the anchored panel.
  ///
  /// This widget is constrained by [maxHeight] and overlay bounds, with scrolling
  /// applied if content overflows.
  final Widget child;

  /// How to size the panel's width.
  ///
  /// - [LayrzAnchoredPanelWidthPolicy.matchAnchor]: Width equals anchor width (default).
  ///   Use this for input fields where the dropdown should match the field width.
  /// - [LayrzAnchoredPanelWidthPolicy.contentSized]: Width is sized to content,
  ///   clamped to [widthBounds]. Use this for icon buttons or other small anchors.
  final LayrzAnchoredPanelWidthPolicy widthPolicy;

  /// Width bounds for content-sized policy.
  ///
  /// Only used when [widthPolicy] is [LayrzAnchoredPanelWidthPolicy.contentSized].
  /// Specifies the minimum and maximum width of the panel.
  final LayrzAnchoredPanelWidthBounds widthBounds;

  /// Optional maximum height for the panel's content in logical pixels.
  ///
  /// When null, the panel height is constrained only by overlay bounds minus padding.
  /// When set, content taller than this value will scroll.
  final double? maxHeight;

  /// Space between the anchor and panel in logical pixels.
  ///
  /// Defaults to 4.0. The gap is applied on the perpendicular axis
  /// (vertical when panel is below/above anchor).
  final double gap;

  /// Alignment of the panel along the cross axis of its resolved side.
  ///
  /// Defaults to [LayrzAnchoredPanelAlignment.start].
  /// The panel is positioned according to this alignment and then clamped
  /// into the overlay bounds. See [LayrzAnchoredPanelAlignment] for how the
  /// cross axis is chosen from the resolved side.
  final LayrzAnchoredPanelAlignment alignment;

  /// The preferred side on which the panel is placed relative to the anchor.
  ///
  /// Defaults to [LayrzPreferredSide.bottom] — existing call sites do not move.
  /// If the panel does not fit on this side, it flips unconditionally to
  /// [LayrzPreferredSideExtension.opposite]; there is no second fit test.
  final LayrzPreferredSide preferredSide;

  /// Optional controller for programmatic control of the panel's open/close state.
  ///
  /// When null, the panel is owned by the [_LayrzAnchoredPanelState] and has no
  /// external control. When non-null, callers can open or close the panel by
  /// calling [controller.open()] and [controller.close()].
  ///
  /// **Important:** The controller instance must never be swapped via [didUpdateWidget].
  /// An assertion will fail if a different controller instance is passed on a rebuild.
  final MenuController? controller;

  /// Called when the panel is opened.
  ///
  /// Guaranteed to fire before the overlay is shown.
  final VoidCallback? onOpen;

  /// Called when the panel is closed.
  ///
  /// Fires after the panel is removed from the overlay.
  final VoidCallback? onClose;

  /// Optional focus node passed to the anchor widget for keyboard interaction.
  ///
  /// When the panel is closed, focus returns to this node. The caller must ensure
  /// this node outlives the panel widget.
  final FocusNode? childFocusNode;

  /// Optional callback reporting whether the panel flipped to the side opposite
  /// [preferredSide].
  ///
  /// Called with `true` when the panel was placed on the side opposite to
  /// [preferredSide], `false` when it landed on [preferredSide] itself. For the
  /// default [LayrzPreferredSide.bottom], this is bit-identical to "above" vs
  /// "below". Useful for adapting corner radius on the side adjacent to the
  /// anchor.
  final void Function(bool flippedUp)? onFlipped;

  /// Optional semantic label for the panel overlay.
  ///
  /// When provided, the panel overlay is wrapped with a Semantics node using
  /// this label. This helps screen readers understand the purpose of the
  /// floating panel.
  ///
  /// Must be caller-supplied for localization support. If null, no semantic
  /// label is added to the panel.
  final String? panelSemanticLabel;

  /// Creates a new [LayrzAnchoredPanel].
  ///
  /// [builder] and [child] are required. All other parameters are optional.
  const LayrzAnchoredPanel({
    required this.builder,
    required this.child,
    this.widthPolicy = LayrzAnchoredPanelWidthPolicy.matchAnchor,
    this.widthBounds = const LayrzAnchoredPanelWidthBounds(minWidth: 160.0, maxWidth: 320.0),
    this.maxHeight,
    this.gap = 4.0,
    this.alignment = LayrzAnchoredPanelAlignment.start,
    this.preferredSide = LayrzPreferredSide.bottom,
    this.controller,
    this.onOpen,
    this.onClose,
    this.childFocusNode,
    this.onFlipped,
    this.panelSemanticLabel,
    super.key,
  });

  @override
  State<LayrzAnchoredPanel> createState() => _LayrzAnchoredPanelState();
}

class _LayrzAnchoredPanelState extends State<LayrzAnchoredPanel> with SingleTickerProviderStateMixin {
  late MenuController _panelController;
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;
  MenuController? _lastSuppliedController;
  late FocusNode _panelFocusNode;

  @override
  void initState() {
    super.initState();
    _panelController = widget.controller ?? MenuController();
    _lastSuppliedController = widget.controller;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _panelFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(LayrzAnchoredPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Verify that the controller is never swapped
    if (widget.controller != null && _lastSuppliedController != widget.controller) {
      assert(
        false,
        'MenuController instances must never be swapped. '
        'Create a new LayrzAnchoredPanel instead of changing the controller.',
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
    // Do not call _panelController.close() during dispose; the overlay may already be
    // torn down. RawMenuAnchor handles cleanup.
    _animationController.dispose();
    _curvedAnimation.dispose();
    _panelFocusNode.dispose();
    super.dispose();
  }

  void _handlePanelOpenRequested(Offset? position, VoidCallback showOverlay) {
    widget.onOpen?.call();
    showOverlay();
    // Reset to start and animate forward for enter animation
    _animationController.reset();
    _animationController.forward();

    // Move focus to the panel so keyboard events (Escape, arrow keys) work
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(_panelFocusNode);
      }
    });
  }

  void _handlePanelCloseRequested(VoidCallback hideOverlay) {
    // Panel closes synchronously; reset animation for next open.
    _animationController.reset();
    hideOverlay();
    widget.onClose?.call();
  }

  Widget _buildPanelOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final tokens = context.tokens;

    // Wrapped in [TextFieldTapRegion] so a tap on the panel's content is never
    // treated as "outside" a nearby [EditableText] (e.g. the field that anchors
    // this panel, when the anchor is an editable field such as in
    // `LayrzComboBoxInput`). Without this, `EditableText`'s own tap-outside
    // handling — which is unconditional for a mouse pointer, unlike touch, per
    // its own platform-conditional design — unfocuses the field before the tap
    // on a panel option reaches pointer-up, destroying the tap. Grouping the
    // panel with the field is the mechanism the framework documents for exactly
    // this case; see [TextFieldTapRegion]'s own doc comment. This nests inside
    // the [TapRegion] below, which is a separate group (`info.tapRegionGroupId`)
    // used by [RawMenuAnchor] itself to detect genuine outside taps and close
    // the panel — the two groups serve different purposes and do not conflict.
    Widget panelContent = TextFieldTapRegion(
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (PointerDownEvent event) {
          MenuController.maybeOf(context)?.close();
        },
        child: CustomSingleChildLayout(
          delegate: LayrzAnchoredPanelLayoutDelegate(
            anchorRect: info.anchorRect,
            preferredSide: widget.preferredSide,
            alignment: widget.alignment,
            widthPolicy: widget.widthPolicy,
            widthBounds: widget.widthBounds,
            gap: widget.gap,
            overlaySize: info.overlaySize,
            tokens: tokens,
            maxHeight: widget.maxHeight,
            onFlipped: widget.onFlipped,
          ),
          child: FadeTransition(
            opacity: _curvedAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.colors.sf1,
                borderRadius: tokens.radius.br3,
                boxShadow: tokens.shadow.elevation3,
              ),
              child: Focus(
                focusNode: _panelFocusNode,
                child: ClipRRect(
                  borderRadius: tokens.radius.br3,
                  child: SingleChildScrollView(
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with semantics if a label is provided.
    if (widget.panelSemanticLabel != null) {
      panelContent = Semantics(
        label: widget.panelSemanticLabel,
        container: true,
        child: panelContent,
      );
    }

    return panelContent;
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _panelController,
      onOpenRequested: _handlePanelOpenRequested,
      onCloseRequested: _handlePanelCloseRequested,
      useRootOverlay: true,
      consumeOutsideTaps: false,
      childFocusNode: widget.childFocusNode,
      overlayBuilder: _buildPanelOverlay,
      builder: (context, panelController, child) {
        return widget.builder(context, panelController);
      },
    );
  }
}

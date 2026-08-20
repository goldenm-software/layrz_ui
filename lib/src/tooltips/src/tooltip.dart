import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'tooltip_position.dart';
import 'tooltip_trigger.dart';

/// A Material-free tooltip widget in the layrz_ui design system.
///
/// [LayrzTooltip] wraps its child and shows a styled text surface on long-press
/// or hover, positioned relative to the child. The tooltip has no custom color or
/// widget content parameters — the surface is standardized with `fg1` background
/// and `background` text color. Callers needing mixed text styling use [contentRichText]
/// to specify per-span overrides.
///
/// **Surface styling is fixed** to ensure visual consistency:
/// - Background color: `tokens.colors.fg1`
/// - Text color: `tokens.colors.background`
/// - Text style: `tokens.typography.label`
/// - Padding: horizontal `sp12`, vertical `sp6`
/// - Border radius: `r8`
///
/// **Graceful degradation:** If the widget tree has no [Overlay] ancestor,
/// [LayrzTooltip] returns its [child] unchanged (no tooltip is shown).
/// This allows tooltips to work in test harnesses that do not provide a full
/// ancestor tree.
///
/// **Pass-through:** While the tooltip surface is shown, it is not hit-tested
/// (`ignorePointer: true`), so the widget painted behind the surface remains
/// interactive.
///
/// **Invariant:** The tooltip ALWAYS renders outside the bounding box of the anchor.
/// This prevents the anchor from losing hover state and entering a flicker loop.
///
/// **Trigger modes:**
/// - **[LayrzTooltipTrigger.pointer]** (default): long-press (touch) or hover (desktop);
///   dismissed on next touch or pointer exit. On touch-only devices (no mouse), a global
///   pointer route dismisses the tooltip on the next PointerDown event anywhere on screen.
///   On mouse-connected devices, hover opens via MouseRegion and pointer events pass through.
/// - **[LayrzTooltipTrigger.tap]**: toggled by single tap; uses global pointer route so
///   the next PointerDown anywhere dismisses the tooltip. Hover has no effect.
///
/// Parameters:
/// - [child]: the widget to be wrapped (mandatory)
/// - [titleText]: optional title text rendered above the content in a heavier weight
/// - [contentText]: plain-text tooltip content (mutually exclusive with [contentRichText])
/// - [contentRichText]: rich-text content with optional per-span styling (mutually exclusive with [contentText])
/// - [position]: preferred position relative to the anchor (default: [LayrzTooltipPosition.bottom])
/// - [trigger]: the trigger mode for showing/dismissing the tooltip (default: [LayrzTooltipTrigger.pointer])
class LayrzTooltip extends StatefulWidget {
  /// The widget to be wrapped with the tooltip.
  final Widget child;

  /// Optional title text rendered above the tooltip content.
  ///
  /// When non-null, the title is rendered above the content in `tokens.typography.body`
  /// (heavier than the content's `label` style) with the same color scheme.
  /// When null, only the content is rendered.
  final String? titleText;

  /// Plain-text content for the tooltip.
  ///
  /// Mutually exclusive with [contentRichText]. Exactly one of the two must be non-null.
  final String? contentText;

  /// Rich-text content for the tooltip with optional per-span styling.
  ///
  /// Mutually exclusive with [contentText]. Exactly one of the two must be non-null.
  final TextSpan? contentRichText;

  /// The preferred position of the tooltip relative to its anchor.
  ///
  /// Defaults to [LayrzTooltipPosition.bottom]. If the tooltip would overflow the
  /// overlay bounds on the preferred side, it automatically flips to the opposite side.
  final LayrzTooltipPosition position;

  /// The trigger mode for showing and dismissing the tooltip.
  ///
  /// Defaults to [LayrzTooltipTrigger.pointer]. See [LayrzTooltipTrigger] for details
  /// on each mode's behavior.
  final LayrzTooltipTrigger trigger;

  /// Creates a new [LayrzTooltip] with the given properties.
  ///
  /// Exactly one of [contentText] or [contentRichText] must be non-null.
  /// Providing both or neither triggers an assertion error.
  const LayrzTooltip({
    super.key,
    required this.child,
    this.titleText,
    this.contentText,
    this.contentRichText,
    this.position = LayrzTooltipPosition.bottom,
    this.trigger = LayrzTooltipTrigger.pointer,
  }) : assert(
         (contentText == null) != (contentRichText == null),
         'Provide exactly one of contentText or contentRichText.',
       );

  @override
  State<LayrzTooltip> createState() => _LayrzTooltipState();
}

class _LayrzTooltipState extends State<LayrzTooltip> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;

  /// Controller for the overlay portal in mouse/hover mode.
  late OverlayPortalController _overlayControllerMouse;

  /// Controller for the overlay portal in tap mode.
  late OverlayPortalController _overlayControllerTap;

  /// Whether a mouse is currently connected to the device.
  ///
  /// True when `RendererBinding.instance.mouseTracker.mouseIsConnected` is true,
  /// indicating mouse/desktop mode where hover tooltips work and pointer events pass through.
  /// False on touch-only devices, where a global pointer route dismisses the tooltip.
  late bool _hasMouseDetected;

  Timer? _hideTimer;
  final GlobalKey _anchorKey = GlobalKey();
  bool _themedInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize overlay portal controllers.
    _overlayControllerMouse = OverlayPortalController();
    _overlayControllerTap = OverlayPortalController();

    // Use placeholder durations initially; they will be updated in didChangeDependencies.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.addStatusListener(_handleAnimationStatusChange);

    // Detect current mouse presence and listen for changes.
    _hasMouseDetected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    RendererBinding.instance.mouseTracker.addListener(_handleMouseTrackerChange);

    // Register global pointer route to dismiss tooltip on touch.
    // This is added here to intercept all pointer events, but is only active
    // when the tooltip is open on a touch-only device.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);

    // Observe app lifecycle for dismissal on pause/suspend.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update animation durations and curves based on tokens once.
    if (!_themedInitialized) {
      try {
        final tokens = context.tokens;
        _animationController.duration = tokens.motion.dHover;
        _animationController.reverseDuration = tokens.motion.dPress;
        // Dispose old animation and create new one with correct curve
        _curvedAnimation.dispose();
        _curvedAnimation = CurvedAnimation(
          parent: _animationController,
          curve: tokens.motion.easingEnter,
          reverseCurve: tokens.motion.easingExit,
        );
        _themedInitialized = true;
      } catch (e) {
        // Theme not available yet, will retry on next didChangeDependencies
      }
    }
  }

  /// Called when the mouse connection status changes.
  ///
  /// Detects when a mouse is connected or disconnected and updates [_hasMouseDetected]
  /// to branch between hover mode (mouse) and touch mode (no mouse) in [build].
  void _handleMouseTrackerChange() {
    if (!mounted) return;

    final bool hasMouseDetected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (hasMouseDetected != _hasMouseDetected) {
      setState(() => _hasMouseDetected = hasMouseDetected);
    }
  }

  /// Returns whether the anchor widget contains the given global position.
  ///
  /// Used by the global pointer route to determine whether a PointerDown event
  /// landed on the anchor itself, in which case the anchor's own gesture detector
  /// (for tap mode) should own the event rather than the global route dismissing.
  bool _anchorContainsGlobalPosition(Offset globalPosition) {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.contains(globalPosition);
  }

  /// Handles global pointer events to dismiss the tooltip on touch.
  ///
  /// **CRITICAL: Dismisses on PointerDown ONLY, NOT on PointerUp.**
  ///
  /// The long-press gesture that OPENS the tooltip ends with a PointerUpEvent
  /// (when the finger lifts). If we dismissed on PointerUp, the tooltip would close
  /// immediately on release, contradicting DESIGN-77 (stay open until tapped away).
  /// Instead, we dismiss only on PointerDown (next touch anywhere), which allows:
  ///
  /// - Long-press opens → PointerUp on release (ignored) → **tooltip stays open** ✓
  /// - Next touch anywhere (PointerDown) → dismisses ✓
  /// - Swipe → PointerDown dismisses, gesture continues to scroll ✓
  /// - Existing `tester.longPress()` tests stay valid (assert tooltip visible) ✓
  ///
  /// **In tap mode only**: The anchor's own GestureDetector(onTap:) owns the toggle
  /// behavior, so pointer-downs on the anchor must not also dismiss here — otherwise
  /// the route hides the tooltip before onTap fires, then onTap reopens it immediately,
  /// making it impossible to close by tapping. This exclusion is ONLY for tap mode;
  /// in pointer mode there is no onTap conflict, so pointer-downs anywhere should dismiss.
  void _handlePointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) return;

    // In tap mode, exclude pointer-downs on the anchor so the anchor's own
    // GestureDetector(onTap) can own the toggle without the global route interfering.
    if (widget.trigger == LayrzTooltipTrigger.tap && _anchorContainsGlobalPosition(event.position)) {
      return;
    }

    _hideTooltip();
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    // Hide the overlay portals when animation completes dismissal.
    if (status == AnimationStatus.dismissed) {
      if (_overlayControllerMouse.isShowing) {
        _overlayControllerMouse.hide();
      }
      if (_overlayControllerTap.isShowing) {
        _overlayControllerTap.hide();
      }
    }
  }

  void _handleMouseEnter() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTooltip();
  }

  void _handleMouseExit() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 100), _hideTooltip);
  }

  void _handleLongPress() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _showTooltip();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    // When the user releases the long-press, the tooltip remains visible.
    // It is dismissed only by the next PointerDownEvent (tap or new gesture).
  }

  void _handleLongPressCancel() {
    // When the long-press is cancelled, the tooltip remains visible.
    // It is dismissed only by the next PointerDownEvent (tap or new gesture).
  }

  void _handleTap() {
    // In tap mode, a single tap toggles the tooltip open/closed.
    if (widget.trigger == LayrzTooltipTrigger.tap) {
      if (_animationController.status == AnimationStatus.completed) {
        _hideTooltip();
      } else {
        _showTooltip();
      }
    }
  }

  void _showTooltip() {
    if (!mounted || Overlay.maybeOf(context) == null) return;

    // Determine which controller to use based on trigger mode and mouse presence.
    final controller = widget.trigger == LayrzTooltipTrigger.tap || !_hasMouseDetected
        ? _overlayControllerTap
        : _overlayControllerMouse;

    if (!controller.isShowing) {
      controller.show();
    }

    if (_animationController.status != AnimationStatus.completed) {
      _animationController.forward();
    }
  }

  void _hideTooltip() {
    if (!mounted) return;
    if (_animationController.status == AnimationStatus.dismissed) return;
    _animationController.reverse();
  }

  /// Builds the tooltip overlay content.
  ///
  /// This is called by the [OverlayPortal]'s overlayChildBuilder, which means it
  /// rebuilds whenever the host widget rebuilds. This ensures the position is
  /// always computed fresh based on the anchor's current location, even after scrolling.
  Widget _buildTooltipContent(BuildContext overlayContext) {
    final tokens = overlayContext.tokens;
    final baseStyle = tokens.typography.label.copyWith(
      color: tokens.colors.background,
    );
    final titleStyle = tokens.typography.body.copyWith(
      color: tokens.colors.background,
    );

    // Build content widget
    final contentWidget = widget.contentText != null
        ? Text(
            widget.contentText!,
            style: baseStyle,
          )
        : Text.rich(
            widget.contentRichText!,
            style: baseStyle,
          );

    // Build the surface widget
    final surface = Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sp12,
        vertical: tokens.spacing.sp6,
      ),
      decoration: BoxDecoration(
        color: tokens.colors.fg1,
        borderRadius: BorderRadius.circular(tokens.radius.r8),
      ),
      child: widget.titleText != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titleText!,
                  style: titleStyle,
                ),
                SizedBox(height: tokens.spacing.sp4),
                contentWidget,
              ],
            )
          : contentWidget,
    );

    // Predict surface size before placing
    final surfaceSize = _predictTooltipSize(
      baseStyle: baseStyle,
      screenSize: MediaQuery.sizeOf(overlayContext),
      tokens: tokens,
    );

    // Get anchor geometry — FRESH on every rebuild
    final anchorRenderBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorRenderBox == null) {
      return const SizedBox.shrink();
    }

    // Get the overlay's render box to resolve anchor position in overlay space (not window space).
    // The bug: without ancestor:, the anchor is in window coordinates, but Positioned uses overlay coords.
    // This causes 2x movement during scroll when overlay and window spaces diverge.
    final overlayRenderBox = Overlay.of(overlayContext).context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null || !overlayRenderBox.hasSize) {
      return const SizedBox.shrink();
    }

    // Compute localToGlobal INSIDE the builder so it recomputes on every host rebuild.
    // Pass ancestor: overlayRenderBox to get coordinates in overlay space.
    final anchorOffsetInOverlay = anchorRenderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayRenderBox,
    );
    final anchorRect = anchorOffsetInOverlay & anchorRenderBox.size;

    // Compute tooltip position using the position delegate.
    // Use overlay's own size (not MediaQuery) so placement decisions happen in the same space.
    final overlaySize = overlayRenderBox.size;
    final delegate = positionDelegate(widget.position);
    final positionContext = TooltipPositionContext(
      target: Offset(anchorRect.center.dx, anchorRect.center.dy),
      targetSize: anchorRect.size,
      tooltipSize: surfaceSize,
      overlaySize: overlaySize,
      preferBelow: widget.position == LayrzTooltipPosition.bottom,
      verticalOffset: 0,
    );

    final tooltipOffset = delegate(positionContext);

    final tooltipWidget = Positioned(
      left: tooltipOffset.dx,
      top: tooltipOffset.dy,
      child: IgnorePointer(
        ignoring: true,
        child: FadeTransition(
          opacity: _curvedAnimation,
          child: surface,
        ),
      ),
    );

    return tooltipWidget;
  }

  Size _predictTooltipSize({
    required TextStyle baseStyle,
    required Size screenSize,
    required LayrzTokens tokens,
  }) {
    final maxWidth = screenSize.width * kLayrzTooltipMaxWidthFactor;
    final textSpan = widget.contentText != null
        ? TextSpan(text: widget.contentText, style: baseStyle)
        : _mergeTextStyleWithSpan(widget.contentRichText!, baseStyle);

    final painter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    painter.layout(maxWidth: maxWidth);

    double contentHeight = painter.height;
    double contentWidth = painter.width;

    // If there's a title, add its height and the separator gap
    if (widget.titleText != null) {
      final titleStyle = tokens.typography.body.copyWith(
        color: tokens.colors.background,
      );
      final titlePainter = TextPainter(
        text: TextSpan(text: widget.titleText, style: titleStyle),
        textDirection: TextDirection.ltr,
      );
      titlePainter.layout(maxWidth: maxWidth);

      contentHeight = titlePainter.height + tokens.spacing.sp4 + painter.height;
      contentWidth = [titlePainter.width, painter.width].reduce((a, b) => a > b ? a : b);
    }

    return Size(
      contentWidth + tokens.spacing.sp12 * 2,
      contentHeight + tokens.spacing.sp6 * 2,
    );
  }

  /// Merge a base text style with a [TextSpan], applying the base style to all children recursively.
  TextSpan _mergeTextStyleWithSpan(TextSpan span, TextStyle baseStyle) {
    final mergedStyle = baseStyle.merge(span.style);
    final mergedChildren = span.children
        ?.map((child) => child is TextSpan ? _mergeTextStyleWithSpan(child, baseStyle) : child)
        .toList();

    return TextSpan(
      text: span.text,
      style: mergedStyle,
      children: mergedChildren,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
    );
  }

  /// Respond to app lifecycle changes - dismiss tooltip when app is suspended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _hideTooltip();
    }
  }

  @override
  void dispose() {
    // Dispose order: cancel timer → remove listeners → hide portals →
    // dispose animations → dispose controller
    _hideTimer?.cancel();
    _hideTimer = null;

    // Remove listeners before disposing the overlay to prevent fires during teardown.
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance.mouseTracker.removeListener(_handleMouseTrackerChange);
    WidgetsBinding.instance.removeObserver(this);

    // Hide the overlay portals on dispose.
    if (_overlayControllerMouse.isShowing) {
      _overlayControllerMouse.hide();
    }
    if (_overlayControllerTap.isShowing) {
      _overlayControllerTap.hide();
    }

    _animationController.removeStatusListener(_handleAnimationStatusChange);
    _curvedAnimation.dispose();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Graceful degradation: if no Overlay ancestor, return child unchanged
    if (Overlay.maybeOf(context) == null) {
      return widget.child;
    }

    final plainText = widget.contentText ?? widget.contentRichText!.toPlainText();
    final child = KeyedSubtree(key: _anchorKey, child: widget.child);

    // On mouse-connected devices: use hover for pointer mode, ignore for tap mode.
    if (_hasMouseDetected && widget.trigger != LayrzTooltipTrigger.tap) {
      return Semantics(
        tooltip: plainText,
        child: MouseRegion(
          opaque: false,
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: (_) => _handleMouseEnter(),
          onExit: (_) => _handleMouseExit(),
          child: OverlayPortal(
            controller: _overlayControllerMouse,
            overlayChildBuilder: _buildTooltipContent,
            child: child,
          ),
        ),
      );
    }

    // On touch-only devices or in tap mode: use long-press / tap, with global
    // pointer route dismissing on next touch (PointerDownEvent).
    if (widget.trigger == LayrzTooltipTrigger.tap) {
      return Semantics(
        tooltip: plainText,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          excludeFromSemantics: true,
          child: OverlayPortal(
            controller: _overlayControllerTap,
            overlayChildBuilder: _buildTooltipContent,
            child: child,
          ),
        ),
      );
    }

    // Pointer mode on touch device: long-press opens, global route dismisses.
    return Semantics(
      tooltip: plainText,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _handleLongPress,
        onLongPressEnd: _handleLongPressEnd,
        onLongPressCancel: _handleLongPressCancel,
        excludeFromSemantics: true,
        child: OverlayPortal(
          controller: _overlayControllerTap,
          overlayChildBuilder: _buildTooltipContent,
          child: child,
        ),
      ),
    );
  }
}

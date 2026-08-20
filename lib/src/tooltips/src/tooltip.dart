import 'dart:async';

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
///   dismissed on pointer-exit or tap-away. When opened by touch, a barrier is created;
///   when opened by hover, no barrier is created.
/// - **[LayrzTooltipTrigger.tap]**: toggled by single tap; a full-screen barrier is
///   always created so tap-away dismisses the tooltip. Hover has no effect.
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

class _LayrzTooltipState extends State<LayrzTooltip> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late CurvedAnimation _curvedAnimation;

  /// The overlay entry for the tooltip widget itself.
  OverlayEntry? _tooltipEntry;

  /// The barrier entry that intercepts tap-away when the tooltip is opened by touch.
  ///
  /// Only created when [_openedByTouch] is true. Sits BELOW the tooltip entry
  /// in the overlay stack. Hover-opened tooltips do not create a barrier.
  OverlayEntry? _barrierEntry;

  /// Whether the tooltip was opened by a long-press (touch) gesture.
  ///
  /// True when opened via [_handleLongPress], false when opened via [_handleMouseEnter].
  /// Used to determine whether to create a tap-away barrier.
  bool _openedByTouch = false;

  Timer? _hideTimer;
  final GlobalKey _anchorKey = GlobalKey();
  bool _themedInitialized = false;

  @override
  void initState() {
    super.initState();
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

  void _handleAnimationStatusChange(AnimationStatus status) {
    // Remove both overlay entries when animation completes dismissal.
    if (status == AnimationStatus.dismissed) {
      if (_tooltipEntry != null && _tooltipEntry!.mounted) {
        _tooltipEntry!.remove();
      }
      _tooltipEntry = null;

      if (_barrierEntry != null && _barrierEntry!.mounted) {
        _barrierEntry!.remove();
      }
      _barrierEntry = null;
    }
  }

  void _handleMouseEnter() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _openedByTouch = false;
    _showTooltip();
  }

  void _handleMouseExit() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 100), _hideTooltip);
  }

  void _handleLongPress() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _openedByTouch = true;
    _showTooltip();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    // When the user releases the long-press, the tooltip remains visible.
    // It is dismissed only by tapping elsewhere (barrier tap) or by other explicit dismissal.
  }

  void _handleLongPressCancel() {
    // When the long-press is cancelled, the tooltip remains visible.
    // It is dismissed only by tapping elsewhere (barrier tap) or by other explicit dismissal.
  }

  void _handleTap() {
    // In tap mode, a single tap toggles the tooltip open/closed.
    if (widget.trigger == LayrzTooltipTrigger.tap) {
      if (_animationController.status == AnimationStatus.completed) {
        _hideTooltip();
      } else {
        _openedByTouch = true; // Treat tap like a touch gesture for barrier creation
        _showTooltip();
      }
    }
  }

  void _showTooltip() {
    if (!mounted || Overlay.maybeOf(context) == null) return;

    if (_tooltipEntry == null) {
      // Create a barrier when:
      // 1. Opened by touch (long-press), OR
      // 2. Trigger mode is tap (always create barrier for tap-away dismissal)
      // Insert the barrier FIRST so the tooltip sits on top of it in the overlay stack.
      if (_openedByTouch || widget.trigger == LayrzTooltipTrigger.tap) {
        _barrierEntry = OverlayEntry(
          builder: (context) => Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideTooltip,
            ),
          ),
        );
        Overlay.of(context).insert(_barrierEntry!);
      }

      _tooltipEntry = OverlayEntry(
        builder: (overlayContext) => _buildTooltipOverlay(overlayContext),
      );
      Overlay.of(context).insert(_tooltipEntry!);
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

  Widget _buildTooltipOverlay(BuildContext overlayContext) {
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

    // Get anchor geometry
    final anchorRenderBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorRenderBox == null) {
      return const SizedBox.shrink();
    }

    final anchorGlobalOffset = anchorRenderBox.localToGlobal(Offset.zero);
    final anchorRect = anchorGlobalOffset & anchorRenderBox.size;

    // Compute tooltip position using the position delegate
    final overlaySize = MediaQuery.sizeOf(overlayContext);
    final delegate = positionDelegate(widget.position);
    final context = TooltipPositionContext(
      target: Offset(anchorRect.center.dx, anchorRect.center.dy),
      targetSize: anchorRect.size,
      tooltipSize: surfaceSize,
      overlaySize: overlaySize,
      preferBelow: widget.position == LayrzTooltipPosition.bottom,
      verticalOffset: 0,
    );

    final tooltipOffset = delegate(context);

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

  @override
  void dispose() {
    // Dispose order: cancel timer → remove overlay entries → dispose animations → dispose controller
    _hideTimer?.cancel();
    _hideTimer = null;

    if (_tooltipEntry != null && _tooltipEntry!.mounted) {
      _tooltipEntry!.remove();
    }
    _tooltipEntry = null;

    if (_barrierEntry != null && _barrierEntry!.mounted) {
      _barrierEntry!.remove();
    }
    _barrierEntry = null;

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

    // In tap mode, use tap to toggle; ignore hover and long-press
    if (widget.trigger == LayrzTooltipTrigger.tap) {
      return Semantics(
        tooltip: plainText,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          child: KeyedSubtree(key: _anchorKey, child: widget.child),
        ),
      );
    }

    // In pointer mode (default), use hover + long-press
    return Semantics(
      tooltip: plainText,
      child: MouseRegion(
        opaque: false,
        hitTestBehavior: HitTestBehavior.translucent,
        onEnter: (_) => _handleMouseEnter(),
        onExit: (_) => _handleMouseExit(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: _handleLongPress,
          onLongPressEnd: _handleLongPressEnd,
          onLongPressCancel: _handleLongPressCancel,
          child: KeyedSubtree(key: _anchorKey, child: widget.child),
        ),
      ),
    );
  }
}

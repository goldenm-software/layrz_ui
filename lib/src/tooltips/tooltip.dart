import 'dart:async';

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/preview.dart';
import 'package:layrz_ui/tokens.dart';

import 'tooltip_position.dart';

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
/// - Text style: `tokens.typography.labelSmall`
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
/// - **Trigger:** long-press (touch) or hover (desktop)
/// - **Dismiss:** automatic on pointer-exit, or tap
///
/// Parameters:
/// - [child]: the widget to be wrapped (mandatory)
/// - [contentText]: plain-text tooltip content (mutually exclusive with [contentRichText])
/// - [contentRichText]: rich-text content with optional per-span styling (mutually exclusive with [contentText])
/// - [position]: preferred position relative to the anchor (default: [LayrzTooltipPosition.bottom])
class LayrzTooltip extends StatefulWidget {
  /// The widget to be wrapped with the tooltip.
  final Widget child;

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

  /// Creates a new [LayrzTooltip] with the given properties.
  ///
  /// Exactly one of [contentText] or [contentRichText] must be non-null.
  /// Providing both or neither triggers an assertion error.
  const LayrzTooltip({
    super.key,
    required this.child,
    this.contentText,
    this.contentRichText,
    this.position = LayrzTooltipPosition.bottom,
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
  OverlayEntry? _overlayEntry;
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
    // Remove the overlay entry only when animation completes dismissal.
    if (status == AnimationStatus.dismissed) {
      _overlayEntry?.remove();
      _overlayEntry = null;
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

  void _showTooltip() {
    if (!mounted || Overlay.maybeOf(context) == null) return;

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (overlayContext) => _buildTooltipOverlay(overlayContext),
      );
      Overlay.of(context).insert(_overlayEntry!);
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
    final baseStyle = tokens.typography.labelSmall.copyWith(
      color: tokens.colors.background,
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
      child: widget.contentText != null
          ? Text(
              widget.contentText!,
              style: baseStyle,
            )
          : Text.rich(
              widget.contentRichText!,
              style: baseStyle,
            ),
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
    final delegate = layrzTooltipPositionDelegate(widget.position);
    final context = TooltipPositionContext(
      target: Offset(anchorRect.center.dx, anchorRect.center.dy),
      targetSize: anchorRect.size,
      tooltipSize: surfaceSize,
      overlaySize: overlaySize,
      preferBelow: widget.position == LayrzTooltipPosition.bottom,
      verticalOffset: 0,
    );

    final tooltipOffset = delegate(context);

    return Positioned(
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

    return Size(
      painter.width + tokens.spacing.sp12 * 2,
      painter.height + tokens.spacing.sp6 * 2,
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
    // Dispose order: cancel timer → remove overlay entry → dispose animations → dispose controller
    _hideTimer?.cancel();
    _hideTimer = null;

    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;

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
          child: KeyedSubtree(key: _anchorKey, child: widget.child),
        ),
      ),
    );
  }
}

/// Preview of [LayrzTooltip] in light theme.
///
/// Demonstrates the tooltip surface styling and positioning below the anchor.
@Preview(
  name: 'Light',
  theme: LayrzPreviewTheme.light,
)
Widget previewLayrzTooltip() {
  return Overlay(
    initialEntries: [
      OverlayEntry(
        builder: (context) => Center(
          child: LayrzTooltip(
            contentText: 'Tooltip text',
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Anchor',
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/preview.dart';

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
/// ancestor tree. [RawTooltip] otherwise asserts an [Overlay] via [debugCheckHasOverlay].
///
/// **Pass-through:** While the tooltip surface is shown, it is not hit-tested
/// (`ignorePointer: true`), so the widget painted behind the surface remains
/// interactive.
///
/// **Known limitation:** [RawTooltip] wraps its child in a [Listener] with
/// [HitTestBehavior.opaque], so wrapping a transparent, non-interactive widget in a
/// [LayrzTooltip] makes it absorb hit-tests that would otherwise pass through to
/// whatever is painted beneath it. This is only observable in overlapping [Stack]
/// layouts. Tracked for a future rebuild on [OverlayPortal].
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
class LayrzTooltip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Degrade gracefully with no Overlay ancestor.
    if (Overlay.maybeOf(context) == null) {
      return child;
    }

    final tokens = context.tokens;

    final plainText = contentText ?? contentRichText!.toPlainText();

    final baseStyle = tokens.typography.labelSmall.copyWith(
      color: tokens.colors.background,
    );

    final surface = Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sp12,
        vertical: tokens.spacing.sp6,
      ),
      decoration: BoxDecoration(
        color: tokens.colors.fg1,
        borderRadius: BorderRadius.circular(tokens.radius.r8),
      ),
      child: contentText != null
          ? Text(
              contentText!,
              style: baseStyle,
            )
          : Text.rich(
              contentRichText!,
              style: baseStyle,
            ),
    );

    final constrainedSurface = MediaQuery.maybeSizeOf(context) != null
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * kLayrzTooltipMaxWidthFactor,
            ),
            child: surface,
          )
        : surface;

    return RawTooltip(
      semanticsTooltip: plainText,
      ignorePointer: true,
      hoverDelay: Duration.zero,
      triggerMode: TooltipTriggerMode.longPress,
      positionDelegate: layrzTooltipPositionDelegate(position),
      animationStyle: AnimationStyle(
        duration: tokens.motion.dHover,
        curve: tokens.motion.easingEnter,
        reverseDuration: tokens.motion.dPress,
        reverseCurve: tokens.motion.easingExit,
      ),
      tooltipBuilder: (context, animation) => FadeTransition(
        opacity: animation,
        child: constrainedSurface,
      ),
      child: child,
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

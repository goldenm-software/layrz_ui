import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'selection_handle_painter.dart';

/// Material-free text selection controls for layrz_ui.
///
/// [LayrzTextSelectionControls] implements the [TextSelectionControls] interface
/// to provide selection handles and toolbar integration. Handles are styled
/// using design system tokens (colors, radius, spacing).
///
/// Mixes in [TextSelectionHandleControls] so that [EditableText.contextMenuBuilder]
/// is called instead of the deprecated [buildToolbar]. The action toolbar is rendered
/// by [LayrzSelectionToolbar] via the context menu builder.
///
/// **Stability**: This class is a singleton to prevent the EditableText widget from
/// disposing and recreating the selection overlay on every rebuild. Tokens are accessed
/// from the build context at render time, so theme changes are reflected without
/// needing to recreate this instance.
class LayrzTextSelectionControls extends TextSelectionControls with TextSelectionHandleControls {
  /// Singleton instance of [LayrzTextSelectionControls].
  static final LayrzTextSelectionControls _instance = LayrzTextSelectionControls._internal();

  /// Creates a new [LayrzTextSelectionControls]. Use [LayrzTextSelectionControls.instance]
  /// to get the singleton instance.
  LayrzTextSelectionControls._internal();

  /// Returns the singleton instance of [LayrzTextSelectionControls].
  static LayrzTextSelectionControls get instance => _instance;

  @override
  bool operator ==(Object other) {
    // All instances are the same (singleton), so we use identity equality.
    return identical(this, other) || other is LayrzTextSelectionControls;
  }

  @override
  int get hashCode => 0; // Constant hash for singleton.

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    // Read tokens from context at render time.
    final tokens = context.tokens;

    // The handle is a small rounded rectangle positioned at the selection endpoint.
    // Size is proportional to text line height but capped at reasonable bounds.
    final handleHeight = (textLineHeight * 0.25).clamp(6.0, 24.0);
    final handleWidth = handleHeight * 0.6;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: CustomPaint(
          size: Size(handleWidth, handleHeight),
          painter: LayrzSelectionHandlePainter(
            color: tokens.colors.primary,
            borderRadius: BorderRadius.all(
              Radius.circular(tokens.radius.r2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // The anchor point is the bottom-center of the handle, positioned
    // at the text selection endpoint.
    final handleHeight = (textLineHeight * 0.25).clamp(6.0, 24.0);
    final handleWidth = handleHeight * 0.6;
    return Offset(handleWidth / 2, handleHeight);
  }

  @override
  Size getHandleSize(double textLineHeight) {
    final handleHeight = (textLineHeight * 0.25).clamp(6.0, 24.0);
    final handleWidth = handleHeight * 0.6;
    return Size(handleWidth, handleHeight);
  }
}

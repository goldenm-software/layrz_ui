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

    // The handle is a fixed-size teardrop (22x22) that points toward the text.
    // A larger hit area (48x48) is provided for comfortable dragging without
    // affecting the visual size.
    const handleSize = Size(22.0, 22.0);
    const hitAreaSize = Size(48.0, 48.0);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: SizedBox(
          width: hitAreaSize.width,
          height: hitAreaSize.height,
          child: Center(
            child: CustomPaint(
              size: handleSize,
              painter: LayrzSelectionHandlePainter(
                type: type,
                color: tokens.colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // The anchor point determines where the handle's teardrop points attach to the text.
    // Each handle type uses a different anchor to align the square corner with the selection edge.
    // These anchors match the fixed 22x22 handle size.
    const handleSize = 22.0;
    return switch (type) {
      // Collapsed: anchor at the center-top, with teardrop hanging below
      TextSelectionHandleType.collapsed => Offset(handleSize / 2, -4),
      // Left: anchor at the right edge, teardrop points up-right
      TextSelectionHandleType.left => Offset(handleSize, 0),
      // Right: anchor at the left edge, teardrop points up-left
      TextSelectionHandleType.right => Offset.zero,
    };
  }

  @override
  Size getHandleSize(double textLineHeight) {
    // Fixed handle size: 22x22 pixels, independent of text line height.
    // This ensures handles are consistently sized and align properly with selection edges.
    return const Size(22.0, 22.0);
  }
}

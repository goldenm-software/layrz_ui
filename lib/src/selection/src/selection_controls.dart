import 'dart:math' as math;

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
    // The hit area is sized to match getHandleSize to ensure draggable region
    // aligns with the visual handle. GestureDetector uses translucent hit test
    // behavior to allow the framework's drag recognizers to work.
    const handleSize = Size(22.0, 22.0);

    final handle = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: SizedBox(
          width: handleSize.width,
          height: handleSize.height,
          child: CustomPaint(
            size: handleSize,
            painter: LayrzSelectionHandlePainter(
              color: tokens.colors.primary,
            ),
          ),
        ),
      ),
    );

    // Rotate the handle based on type to point in the correct direction.
    // The base teardrop points toward the top-left (up-left for right handle).
    // We rotate it based on the handle type:
    // - left: rotate 90° (π/2) to point up-right
    // - right: no rotation, points up-left
    // - collapsed: rotate 45° (π/4) to point up
    return switch (type) {
      TextSelectionHandleType.left => Transform.rotate(
        angle: math.pi / 2.0,
        child: handle,
      ), // points up-right
      TextSelectionHandleType.right => handle, // points up-left
      TextSelectionHandleType.collapsed => Transform.rotate(
        angle: math.pi / 4.0,
        child: handle,
      ), // points up
    };
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // The anchor point determines where the handle's teardrop points attach to the text.
    // Each handle type uses a different anchor to align the square corner with the selection edge.
    // These anchors match the fixed 22x22 handle size and Material's implementation.
    const handleSize = 22.0;
    return switch (type) {
      // Collapsed: anchor at the center-top, point hanging above (after rotation)
      TextSelectionHandleType.collapsed => Offset(handleSize / 2, -4),
      // Left: anchor at the right edge (after rotation to point up-right)
      TextSelectionHandleType.left => Offset(handleSize, 0),
      // Right: anchor at the left edge (base position, points up-left)
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

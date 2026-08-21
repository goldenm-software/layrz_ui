import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';

/// Widget that displays a magnifier tracking the user's finger during text selection.
///
/// [_LayrzMagnifierWidget] listens to [MagnifierInfo] changes and updates the magnifier's
/// position and focal point in real time. The magnifier:
/// - Positions horizontally at the finger's x-coordinate, clamped to field bounds
/// - Sits vertically above the current line of text
/// - Sets [RawMagnifier.focalPointOffset] to magnify the text under the finger
class _LayrzMagnifierWidget extends StatelessWidget {
  /// The magnification scale factor applied to the magnified view.
  ///
  /// Drives both the [RawMagnifier.magnificationScale] and the focal point edge insets.
  /// This value determines how much content is magnified and must match the geometry
  /// constants (22.0 shift, 77.37×37.9 lens) for correct focal point positioning.
  final double scale;

  /// The [ValueNotifier] containing current magnifier information.
  final ValueNotifier<MagnifierInfo> magnifierInfo;

  /// Creates a new [_LayrzMagnifierWidget].
  ///
  /// Parameters:
  ///   - [scale]: The magnification scale factor applied to magnified content.
  ///   - [magnifierInfo]: The [ValueNotifier] containing [MagnifierInfo] updates.
  const _LayrzMagnifierWidget({
    required this.scale,
    required this.magnifierInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MagnifierInfo>(
      valueListenable: magnifierInfo,
      builder: (context, info, child) {
        return _buildMagnifier(context, info);
      },
    );
  }

  /// Builds the magnifier widget with position and focal point updates.
  ///
  /// Implements Material's magnifier positioning and focal point algorithm:
  /// - The magnifier size is 77.37 × 37.9 (wide and short)
  /// - Magnifier X position: finger position, clamped to current line boundaries
  /// - Magnifier Y position: based on caret's center, positioned above with fixed offset
  /// - Focal point: calculated relative to magnifier position, shows content under finger
  /// - Returns a Positioned widget to place the magnifier on screen
  Widget _buildMagnifier(BuildContext context, MagnifierInfo info) {
    final tokens = context.tokens;

    // Material's magnifier dimensions: wide and short (77.37 × 37.9)
    const magnifierSize = Size(77.37, 37.9);
    final magnificationScale = scale;
    const kStandardVerticalFocalPointShift = 22.0;

    // Basic magnifier offset: half width horizontally, height + shift vertically
    final basicMagnifierOffset = Offset(
      magnifierSize.width / 2,
      magnifierSize.height + kStandardVerticalFocalPointShift,
    );

    // Magnifier X position: finger position, clamped to current line boundaries
    final fingerX = info.globalGesturePosition.dx;
    final magnifierX = fingerX.clamp(
      info.currentLineBoundaries.left,
      info.currentLineBoundaries.right,
    );

    // Magnifier Y position: use caret's center, positioned above by the offset
    final caretCenterY = info.caretRect.center.dy;

    // Unadjusted magnifier position (may be off-screen)
    final Rect unadjustedMagnifierRect = Offset(magnifierX, caretCenterY) - basicMagnifierOffset & magnifierSize;

    // Clamp magnifier to screen bounds
    final screenRect = Offset.zero & MediaQuery.sizeOf(context);
    final Rect screenBoundsAdjustedMagnifierRect = MagnifierController.shiftWithinBounds(
      bounds: screenRect,
      rect: unadjustedMagnifierRect,
    );

    final magnifierPosition = screenBoundsAdjustedMagnifierRect.topLeft;

    // Calculate focal point based on finger position relative to magnifier
    // The focal point is what part of the text appears in the magnifier view
    final horizontalMaxFocalPointEdgeInsets = (magnifierSize.width / 2) / magnificationScale;

    // Determine the global focal point X position
    final double newGlobalFocalPointX;
    if (info.fieldBounds.width < horizontalMaxFocalPointEdgeInsets * 2) {
      // Field is narrow: center the focal point in the field
      newGlobalFocalPointX = info.fieldBounds.center.dx;
    } else {
      // Field is wide: clamp focal point to keep text visible in magnifier
      final minX = info.fieldBounds.left + horizontalMaxFocalPointEdgeInsets;
      final maxX = info.fieldBounds.right - horizontalMaxFocalPointEdgeInsets;
      newGlobalFocalPointX = screenBoundsAdjustedMagnifierRect.center.dx.clamp(minX, maxX);
    }

    // Convert global focal point to magnifier-relative offset
    final newRelativeFocalPointX = newGlobalFocalPointX - screenBoundsAdjustedMagnifierRect.center.dx;

    // Y component adjustment for screen bounds: if magnifier was shifted up/down,
    // we need to adjust the focal point to account for that shift
    final focalPointAdjustmentY = unadjustedMagnifierRect.top - screenBoundsAdjustedMagnifierRect.top;

    // Vertical focal point: standard offset + half magnifier height + adjustment for screen bounds
    // Material's geometry constants (22.0 shift, 77.37×37.9 lens) require the focal point
    // to be at the center of the magnifier vertically (standard shift + height/2 = 22.0 + 18.95 = 40.95)
    final focalPointY = kStandardVerticalFocalPointShift + magnifierSize.height / 2 + focalPointAdjustmentY;

    return Positioned(
      left: magnifierPosition.dx,
      top: magnifierPosition.dy,
      child: RawMagnifier(
        size: magnifierSize,
        magnificationScale: magnificationScale,
        decoration: MagnifierDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius.full),
          ),
          shadows: tokens.shadow.elevation2,
        ),
        clipBehavior: Clip.hardEdge,
        focalPointOffset: Offset(newRelativeFocalPointX, focalPointY),
      ),
    );
  }
}

/// A Material-free text magnifier for touch platform selection.
///
/// [LayrzSelectionMagnifier] provides a magnified view of text around the current
/// selection point. It is only enabled on touch platforms (iOS and Android) and is
/// disabled on desktop platforms.
///
/// The magnifier is positioned above the cursor/selection point and displays a
/// zoomed portion of the text being edited, helping users make precise selections.
///
/// **Platform gating**: This magnifier is only available on iOS and Android.
/// On desktop platforms (Windows, macOS, Linux) and web, the configuration
/// will be null.
class LayrzSelectionMagnifier extends StatelessWidget {
  /// The magnification scale factor applied to the magnified view.
  ///
  /// Determines how much the content is magnified. Must align with the geometry
  /// constants (22.0 vertical shift, 77.37×37.9 lens size) for correct focal point
  /// positioning. Defaults to 1.25.
  final double scale;

  /// Creates a new [LayrzSelectionMagnifier].
  ///
  /// Parameters:
  ///   - [scale]: The magnification scale factor. Defaults to 1.25.
  const LayrzSelectionMagnifier({
    super.key,
    this.scale = 1.25,
  });

  /// Returns a [TextMagnifierConfiguration] suitable for touch platforms, or null
  /// if the current platform is desktop or web.
  ///
  /// This is the primary entry point for wiring magnification into [EditableText.magnifierConfiguration].
  ///
  /// The magnifier listens to [MagnifierInfo] updates and:
  /// - Positions horizontally at the finger position, clamped to field bounds
  /// - Positions vertically above the current line
  /// - Sets the focal point offset to magnify text under the finger
  static TextMagnifierConfiguration? magnifierConfigurationFor({
    double scale = 1.25,
  }) {
    // Magnifier is only enabled on touch platforms
    if (!LayrzPlatform.isMobile) {
      return null;
    }

    return TextMagnifierConfiguration(
      magnifierBuilder: (BuildContext context, MagnifierController magnet, ValueNotifier<MagnifierInfo> info) {
        return _LayrzMagnifierWidget(scale: scale, magnifierInfo: info);
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

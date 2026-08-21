import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/platform/platform.dart';

/// Widget that displays a magnifier tracking the user's finger during text selection.
///
/// [_LayrzMagnifierWidget] listens to [MagnifierInfo] changes and updates the magnifier's
/// position and focal point in real time. The magnifier:
/// - Positions horizontally at the finger's x-coordinate, clamped to field bounds
/// - Sits vertically above the current line of text
/// - Sets [RawMagnifier.focalPointOffset] to magnify the text under the finger
class _LayrzMagnifierWidget extends StatelessWidget {
  /// The magnification scale factor (e.g., 1.5 for 1.5x magnification).
  final double scale;

  /// The [ValueNotifier] containing current magnifier information.
  final ValueNotifier<MagnifierInfo> magnifierInfo;

  /// Creates a new [_LayrzMagnifierWidget].
  ///
  /// Parameters:
  ///   - [scale]: The magnification scale factor.
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
        return _buildMagnifier(info);
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
  Widget _buildMagnifier(MagnifierInfo info) {
    // Material's magnifier dimensions: wide and short (77.37 × 37.9)
    const magnifierSize = Size(77.37, 37.9);
    const magnificationScale = 1.25;
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
    final magnifierTopLeft = Offset(magnifierX, caretCenterY) - basicMagnifierOffset;

    // Calculate focal point based on finger position relative to magnifier
    // The focal point is what part of the text appears in the magnifier view
    final horizontalMaxFocalPointEdgeInsets = (magnifierSize.width / 2) / magnificationScale;

    // Determine the global focal point X position
    final double focalPointGlobalX;
    if (info.fieldBounds.width < horizontalMaxFocalPointEdgeInsets * 2) {
      // Field is narrow: center the focal point in the field
      focalPointGlobalX = info.fieldBounds.center.dx;
    } else {
      // Field is wide: clamp focal point to keep text visible in magnifier
      focalPointGlobalX = (magnifierTopLeft.dx + magnifierSize.width / 2).clamp(
        info.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
        info.fieldBounds.right - horizontalMaxFocalPointEdgeInsets,
      );
    }

    // Convert global focal point to magnifier-relative offset
    final focalPointRelativeX = focalPointGlobalX - magnifierTopLeft.dx;

    // Vertical focal point: standard offset + half magnifier height
    final focalPointY = kStandardVerticalFocalPointShift + magnifierSize.height / 2;

    return RawMagnifier(
      size: magnifierSize,
      magnificationScale: magnificationScale,
      decoration: MagnifierDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(magnifierSize.height / 2),
        ),
        shadows: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      focalPointOffset: Offset(focalPointRelativeX, focalPointY),
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
  /// The magnification scale factor (e.g., 1.5 for 1.5x magnification).
  ///
  /// Defaults to 1.5 if not specified.
  final double scale;

  /// Creates a new [LayrzSelectionMagnifier].
  ///
  /// Parameters:
  ///   - [scale]: The magnification scale factor. Defaults to 1.5.
  const LayrzSelectionMagnifier({
    super.key,
    this.scale = 1.5,
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
    double scale = 1.5,
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

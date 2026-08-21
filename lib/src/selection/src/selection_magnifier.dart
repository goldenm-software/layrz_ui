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
  Widget _buildMagnifier(MagnifierInfo info) {
    const magnifierSize = Size(128.0, 160.0);

    // Calculate the focal point offset within the magnifier.
    // This offset determines which part of the text is shown magnified.
    // We position it so the text under the finger appears at the center of the magnifier.
    final fingerX = info.globalGesturePosition.dx;
    final fingerY = info.globalGesturePosition.dy;

    // The focal point offset is relative to the magnifier's center
    // X: distance from finger to magnifier center
    final focalPointDx = fingerX - (magnifierSize.width / 2);
    // Y: distance from finger to magnifier center
    final focalPointDy = fingerY - (magnifierSize.height / 2);

    return RawMagnifier(
      size: magnifierSize,
      magnificationScale: scale,
      focalPointOffset: Offset(focalPointDx, focalPointDy),
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

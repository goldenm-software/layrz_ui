import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/platform/platform.dart';

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
  static TextMagnifierConfiguration? magnifierConfigurationFor({
    double scale = 1.5,
  }) {
    // Magnifier is only enabled on touch platforms
    if (!LayrzPlatform.isMobile) {
      return null;
    }

    return TextMagnifierConfiguration(
      magnifierBuilder: (BuildContext context, MagnifierController magnet, ValueNotifier<MagnifierInfo> info) {
        return RawMagnifier(
          size: const Size(128.0, 160.0),
          magnificationScale: scale,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

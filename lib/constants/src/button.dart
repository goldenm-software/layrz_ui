/// Height of a standard [LayrzButton] in logical pixels.
const double kLayrzButtonHeight = 45.0;

/// Size of the icon within a [LayrzButton] in logical pixels.
const double kLayrzButtonIconSize = 22.0;

/// Spacing between the icon and label in a [LayrzButton] when both are present.
const double kLayrzButtonIconSeparator = 8.0;

/// Font size of the [LayrzButton] label text.
const double kLayrzButtonFontSize = 14.0;

/// Opacity applied to outlined tonal button backgrounds.
///
/// Used to create a subtle fill effect for [LayrzButtonStyle.outlinedTonal]
/// variants without full solid colors.
const double kLayrzButtonOutlinedTonalOpacity = 0.15;

/// Horizontal padding applied to [LayrzButton] non-Fab variants.
///
/// Controls the spacing between button edges and internal content (icon and label).
const double kLayrzButtonHorizontalPadding = 16.0;

/// Vertical offset between the bottom of a [LayrzButton] and its tooltip.
///
/// Provides visual separation so the tooltip does not visually overlap the button.
/// Measured in logical pixels below the button's lower edge.
const double kLayrzButtonTooltipVerticalOffset = 10.0;

/// Minimum duration a busy state (loading or cooldown) remains visible on [LayrzButton].
///
/// When a button enters a busy state, it remains visually and interactively disabled for at least
/// this duration, even if the underlying busy condition (loading, cooldown) expires sooner.
///
/// **Purpose:** Prevents flicker and rapid state changes from quick server responses.
/// A 20ms loading state would otherwise strobe, confusing the user. This floor ensures visual
/// calm by holding the busy indicator visible for a full frame (~100ms at 60fps).
///
/// **Tradeoff:** The indicator can briefly outlive the real busy state, deliberately trading
/// strict truthfulness for visual calm and tactile responsiveness. The button stays disabled
/// for the entire held window, so a tap cannot land mid-fade.
const Duration kLayrzButtonMinBusyDuration = Duration(milliseconds: 100);

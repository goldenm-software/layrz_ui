/// Height of a standard [LayrzButton] in logical pixels on regular (non-compact) viewports.
const double kLayrzButtonHeight = 45.0;

/// Height of a standard [LayrzButton] on compact (mobile/small tablet) viewports.
///
/// When [LayrzContextExtensions.isCompact] is true (viewport width < 960), the button
/// height increases to 50 logical pixels to improve touch target size. The font size
/// and icon size scale proportionally with the height change.
const double kLayrzButtonCompactHeight = 50.0;

/// Height of the progress indicator bar in [LayrzButton] (loading or cooldown state).
///
/// Renders as a thin horizontal bar at the bottom of the button. At 3 logical pixels,
/// the bar remains visible without obscuring the button label or icon. The bar is inset
/// by the button's border width to stay inside the button's outline.
const double kLayrzButtonIndicatorHeight = 3.0;

/// Bottom inset applied to the progress indicator bar in [LayrzButton].
///
/// The indicator is positioned inset from the button's bottom edge by this amount
/// to maintain visual separation from the very edge. A smaller value than the horizontal inset
/// keeps the bar close to the bottom inner edge for better visual balance.
///
/// Set to 1.0 logical pixel to keep the bar near the bottom edge while avoiding the very edge.
const double kLayrzButtonIndicatorInsetBottom = 1.0;

/// Size of the icon within a [LayrzButton] in logical pixels on regular viewports.
const double kLayrzButtonIconSize = 22.0;

/// Size of the icon within a [LayrzButton] on compact viewports.
///
/// When [LayrzContextExtensions.isCompact] is true (viewport width < 960), the icon
/// size increases to 24.0 logical pixels to maintain visual proportion as the button
/// height grows from 45 to 50 (a 1.11x scale). The icon size is scaled proportionally:
/// 22 * (50 / 45) ≈ 24.44, rounded to 24.
const double kLayrzButtonCompactIconSize = 24.0;

/// Font size of the [LayrzButton] label text on regular viewports.
const double kLayrzButtonFontSize = 14.0;

/// Font size of the [LayrzButton] label text on compact viewports.
///
/// When [LayrzContextExtensions.isCompact] is true (viewport width < 960), the button
/// font size increases to 16.0 logical pixels (matching the body typography token)
/// to improve readability and maintain visual hierarchy as the button height grows to 50.
const double kLayrzButtonCompactFontSize = 16.0;

/// Opacity applied to outlined tonal button backgrounds.
///
/// Used to create a subtle fill effect for [LayrzButtonStyle.outlinedTonal]
/// variants without full solid colors.
const double kLayrzButtonOutlinedTonalOpacity = 0.15;

/// Hovered rung opacity for text and fab styles on the fill ladder.
///
/// Text and fab buttons use a transparent → tonal → stronger tonal ladder.
/// This is the tonal opacity applied on hover.
const double kLayrzButtonTextHoveredOpacity = 0.20;

/// Pressed rung opacity for text and fab styles on the fill ladder.
///
/// Text and fab buttons reach stronger tonal opacity when pressed.
const double kLayrzButtonTextPressedOpacity = 0.35;

/// Hovered rung opacity for outlined styles on the fill ladder.
///
/// Outlined buttons climb from transparent → tonal → solid.
/// This is the tonal opacity applied on hover.
const double kLayrzButtonOutlinedHoveredOpacity = 0.20;

/// Hovered rung opacity for filledTonal styles on the fill ladder.
///
/// FilledTonal buttons climb from tonal → stronger → solid.
/// This is the stronger tonal opacity applied on hover (base + delta).
const double kLayrzButtonFilledTonalHoveredDelta = 0.18;

/// Pressed rung opacity for filledTonal styles on the fill ladder.
///
/// FilledTonal buttons reach solid (1.0) when pressed.
/// This is the delta added to base opacity to compute the pressed opacity.
const double kLayrzButtonFilledTonalPressedDelta = 0.80;

/// Hovered rung opacity for outlinedTonal styles on the fill ladder.
///
/// OutlinedTonal buttons climb from tonal → stronger → solid.
/// This is the stronger tonal opacity applied on hover (base + delta).
const double kLayrzButtonOutlinedTonalHoveredDelta = 0.17;

/// Pressed rung opacity for outlinedTonal styles on the fill ladder.
///
/// OutlinedTonal buttons reach solid (1.0) when pressed.
/// This is the delta added to base opacity to compute the pressed opacity.
const double kLayrzButtonOutlinedTonalPressedDelta = 0.85;

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

/// Minimum duration the pressed visual feedback remains visible on [LayrzButton].
///
/// When the user taps the button, the pressed state becomes visible for at least this duration,
/// even if the pointer is released sooner. This floor ensures the user perceives tactile feedback
/// for all but the fastest taps.
///
/// **Purpose:** Prevents the pressed visual from flashing imperceptibly on quick taps. Without
/// this window, a very fast tap could release before the 100ms AnimatedContainer transition
/// begins animating, resulting in zero visible feedback. A 120ms floor guarantees at least 20ms
/// of the transition is visible (120 − 100 = 20ms headroom), providing unmistakable tactile
/// confirmation that the tap registered.
///
/// **How it works:** On pointer-down, the pressed state is set immediately. On pointer-up or
/// pointer-cancel, if less than 120ms has elapsed since the press, a Timer delays the clear
/// until the remainder expires. This ensures the visual feedback is always perceptible without
/// blocking the tap's action callback.
const Duration kLayrzButtonMinPressedDuration = Duration(milliseconds: 120);

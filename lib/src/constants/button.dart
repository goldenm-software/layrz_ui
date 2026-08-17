/// Height of a standard [LayrzButton] in logical pixels.
const double kLayrzButtonHeight = 45.0;

/// Height of the progress indicator bar in [LayrzButton] (loading or cooldown state).
///
/// Renders as a thin horizontal bar at the bottom of the button. At 3 logical pixels,
/// the bar remains visible without obscuring the button label or icon. The bar is inset
/// by the button's border width to stay inside the button's outline.
const double kLayrzButtonIndicatorHeight = 3.0;

/// Horizontal inset applied to the progress indicator bar in [LayrzButton].
///
/// The indicator is positioned inset from the button's left and right edges by this amount
/// to maintain visual clearance from the button's rounded corners. This inset is applied in addition
/// to the button's border width.
///
/// Set to 8.0 to match the button's base corner radius ([tokens.radius.base]), ensuring the
/// progress bar's pill-shaped ends remain visually distinct and do not clash with the
/// button's corner curve.
const double kLayrzButtonIndicatorInsetHorizontal = 8.0;

/// Bottom inset applied to the progress indicator bar in [LayrzButton].
///
/// The indicator is positioned inset from the button's bottom edge by this amount
/// to maintain visual separation from the very edge. A smaller value than the horizontal inset
/// keeps the bar close to the bottom inner edge for better visual balance.
///
/// Set to 1.0 logical pixel to keep the bar near the bottom edge while avoiding the very edge.
const double kLayrzButtonIndicatorInsetBottom = 1.0;

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

/// Horizontal padding applied to [LayrzButton] non-Fab variants.
///
/// Controls the spacing between button edges and internal content (icon and label).
const double kLayrzButtonHorizontalPadding = 16.0;

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

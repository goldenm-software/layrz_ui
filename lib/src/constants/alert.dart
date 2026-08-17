/// Side length of the circular icon chip in a [LayrzAlert].
///
/// This defines the width and height of the icon container that holds the alert's
/// semantic icon. The container is a perfect square with rounded corners, providing
/// a consistent visual accent across all alert styles.
const double kLayrzAlertIconBoxSize = 34.0;

/// Icon glyph size inside a [LayrzAlert] for all styles except filledIcon.
///
/// This is the size of the icon asset (in logical pixels) when rendered in
/// layrz, filledTonal, filled, and outlined styles.
const double kLayrzAlertIconSize = 22.0;

/// Icon glyph size inside a [LayrzAlert] when the style is filledIcon.
///
/// The filledIcon style uses a larger icon size to fill the left panel more
/// prominently than other styles.
const double kLayrzAlertFilledIconSize = 25.0;

/// Default outer size of a standalone [LayrzAlertIcon].
///
/// [LayrzAlertIcon] can be used independently from [LayrzAlert] as a building block.
/// This constant defines its default container dimensions (width and height).
const double kLayrzAlertIconWidgetSize = 30.0;

/// Default glyph size of a standalone [LayrzAlertIcon].
///
/// This is the size of the icon asset rendered inside a standalone [LayrzAlertIcon]
/// when no explicit iconSize is provided.
const double kLayrzAlertIconWidgetIconSize = 20.0;

/// Vertical lift distance for an interactive [LayrzAlert] on hover or focus.
///
/// When an alert is interactive (has an [onTap] callback), hovering or focusing
/// the surface causes it to lift by this distance (in logical pixels). The lift is
/// paint-only (via transform) and does not affect layout or hit-testing regions.
const double kLayrzAlertHoverLift = 4.0;

/// Gap in logical pixels between a tooltip and the edge of its anchor.
///
/// Required because [RawTooltip] hardcodes `TooltipPositionContext.verticalOffset`
/// to `0.0` whenever a custom `positionDelegate` is supplied, so the spacing cannot
/// come from the SDK.
const double kLayrzTooltipOffset = 10.0;

/// Fraction of the available viewport width a tooltip may occupy at most.
const double kLayrzTooltipMaxWidthFactor = 0.8;

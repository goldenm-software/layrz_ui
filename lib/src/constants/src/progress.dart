/// Default height, in logical pixels, for `LayrzProgressBar` in
/// `LayrzProgressFormat.linear` mode.
///
/// `16.0` does not correspond to any existing `LayrzSpacingTokens` level
/// (`sp1`–`sp5` are `6/10/14/20/32`), so it is kept as its own constant rather
/// than forced onto a spacing token. This reads as a substantial, modern bar
/// rather than the earlier `10.0`/`8.0` hairline values.
const double kLayrzProgressBarHeight = 16.0;

/// Default diagonal size, in logical pixels, for `LayrzProgressBar` in
/// `LayrzProgressFormat.circular` mode.
///
/// The circular indicator is always painted in a square box of this side
/// length (`50.0` × `50.0`), caller-overridable via `LayrzProgressBar.size`.
const double kLayrzProgressCircularSize = 50.0;

/// Default stroke thickness, in logical pixels, for the ring painted by
/// `LayrzProgressBar` in `LayrzProgressFormat.circular` mode.
///
/// Caller-overridable via `LayrzProgressBar.strokeWidth`.
const double kLayrzProgressCircularStrokeWidth = 4.0;

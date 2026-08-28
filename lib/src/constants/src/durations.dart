/// Standard duration for hover / micro-interaction animations.
const Duration kHoverDuration = Duration(milliseconds: 100);

/// Standard duration for page transition animations.
const Duration kPageTransitionDuration = Duration(milliseconds: 250);

/// Standard duration for a single indeterminate sweep cycle (e.g. a looping
/// progress bar), in milliseconds.
///
/// 1500ms matches `LayrzButtonIndicator`'s hardcoded indeterminate duration
/// (`button_indicator.dart:57`), so the two loading affordances in the design
/// system cycle at the same visible speed.
const Duration kIndeterminateDuration = Duration(milliseconds: 1500);

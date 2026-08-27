/// Quantises [value] to the nearest one of [divisions] equally-spaced steps
/// between [min] and [max], then clamps the result back into `[min, max]`.
///
/// When [divisions] is `null`, `0`, or `1`, no quantisation is meaningful (a
/// single division has nowhere to snap to other than its own endpoints), so
/// [value] is returned unchanged aside from the same clamp. This is a pure
/// function with no widget dependency, so it is directly unit-testable
/// without pumping a tree — the same shape as `resolveLayrzLayoutPresentation`.
///
/// [min] must be less than or equal to [max]; when they are equal (a
/// degenerate, zero-width range) the clamp collapses both bounds to that
/// single value and quantisation is a no-op.
double quantizeLayrzSliderValue({
  required double value,
  required double min,
  required double max,
  required int? divisions,
}) {
  if (max <= min) return min;
  final clamped = value.clamp(min, max);
  if (divisions == null || divisions < 2) return clamped;

  final stepSize = (max - min) / divisions;
  final steppedIndex = ((clamped - min) / stepSize).round();
  final snapped = min + steppedIndex * stepSize;
  return snapped.clamp(min, max);
}

/// Converts a slider [value] within `[min, max]` to a fraction in `[0.0, 1.0]`.
///
/// Returns `0.0` when [max] and [min] are equal, avoiding a division by zero
/// for a degenerate zero-width range — the thumb then always renders at the
/// track's start.
double layrzSliderValueToFraction({
  required double value,
  required double min,
  required double max,
}) {
  if (max <= min) return 0.0;
  return ((value - min) / (max - min)).clamp(0.0, 1.0);
}

/// Converts a track [fraction] in `[0.0, 1.0]` back to a value within `[min, max]`.
///
/// This is the inverse of [layrzSliderValueToFraction], used to translate a
/// drag or tap position on the track back into the slider's value domain
/// before quantisation is applied.
double layrzSliderFractionToValue({
  required double fraction,
  required double min,
  required double max,
}) {
  return min + (max - min) * fraction.clamp(0.0, 1.0);
}

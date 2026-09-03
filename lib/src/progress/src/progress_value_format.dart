/// Formats a determinate progress fraction as a percentage string, biasing
/// away from the two endpoints when rounding would misrepresent them.
///
/// Both `LayrzLabeledProgressBar`'s visible label and `LayrzProgressBar`'s
/// `Semantics.value` announcement call this single function, so the two
/// never disagree about what a given [value] reads as — see each call site
/// for why that agreement matters.
///
/// **The problem this solves.** A plain `(value * 100).toStringAsFixed(decimals)`
/// rounds any sufficiently small non-zero value down to all-zero digits —
/// e.g. `0.001` at `decimals: 0` formats as `'0%'`, indistinguishable from a
/// bar that has not started at all. Symmetrically, a value just short of
/// `1.0` can round up to all-nines-plus-one — e.g. `0.999` at `decimals: 0`
/// formats as `'100%'`, claiming a completion that has not actually happened.
/// Both are the same failure in opposite directions: the formatted string
/// claims a state ("not started" / "complete") that the underlying value has
/// not reached.
///
/// **The fix.** [value] is only ever adjusted at the two boundaries, and only
/// when the naive formatting would cross them:
/// - `value == 0.0` exactly always formats as `'0%'` — a truly empty bar must
///   still read as empty. Nothing is adjusted here.
/// - `value > 0.0` (however small) never formats as all-zero digits. When
///   naive rounding would produce that, the smallest positive value
///   representable at [decimals] is substituted instead — `1%` at
///   `decimals: 0`, `0.1%` at `decimals: 1`, `0.01%` at `decimals: 2` — i.e.
///   `pow(10, -decimals)` percent. This generalizes to any [decimals] rather
///   than hardcoding the `decimals: 0` case.
/// - `value == 1.0` exactly always formats as `'100%'`. Nothing is adjusted.
/// - `value < 1.0` (however close) never formats as `100%` (or, more
///   generally, never rounds up to the next whole unit at [decimals]'
///   precision — see below). When naive rounding would produce that, the
///   largest value below `100` representable at [decimals] is substituted
///   instead — `99%` at `decimals: 0`, `99.9%` at `decimals: 1`, `99.99%` at
///   `decimals: 2` — i.e. `100 - pow(10, -decimals)` percent.
///
/// Every other value formats exactly as `toStringAsFixed` already produces
/// it — this function only intervenes at the two edges, never in the middle
/// of the range (`50%`, `67.89%`, and so on are unaffected).
///
/// Uses `num.toStringAsFixed` throughout, matching `LayrzProgressBar.decimals`'
/// own documented choice — `package:intl` is deliberately not a dependency of
/// this package.
String formatLayrzProgressValue(double value, int decimals) {
  final clamped = value.clamp(0.0, 1.0);
  final step = 1 / _pow10(decimals);

  if (clamped <= 0.0) return '0%';
  if (clamped >= 1.0) return '100%';

  final percentage = clamped * 100;
  final naive = percentage.toStringAsFixed(decimals);

  // The naive string rounded a genuinely positive value down to all-zero
  // digits (e.g. '0.001' at decimals: 0 -> '0'). Floor it up to the smallest
  // positive step instead, so a started-but-tiny value never reads as 0%.
  if (double.parse(naive) <= 0.0) {
    return '${step.toStringAsFixed(decimals)}%';
  }

  // The naive string rounded a genuinely sub-1.0 value up to a full 100 (e.g.
  // '0.999' at decimals: 0 -> '100'). Ceil it down to the largest value below
  // 100 at this precision instead, so an incomplete bar never reads as 100%.
  if (double.parse(naive) >= 100.0) {
    return '${(100 - step).toStringAsFixed(decimals)}%';
  }

  return '$naive%';
}

/// Returns `10^exponent` as a [double], used to derive the smallest positive
/// step representable at a given decimal precision (e.g. `_pow10(2) == 100`,
/// so `1 / _pow10(2) == 0.01`).
double _pow10(int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

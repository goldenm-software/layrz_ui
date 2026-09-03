import 'package:flutter/widgets.dart';

/// An immutable, always-valid, always-contiguous span between two dates.
///
/// Both [start] and [end] are non-nullable and [start] is always less than
/// or equal to [end] — [LayrzDateRange] cannot represent a half-open
/// selection, an empty range, or a reversed pair. This deliberately makes
/// the old layrz_theme API's runtime `assert(list.length == 0 || list.length
/// == 2)` on a `List` of `DateTime` unrepresentable: there is no length-zero or
/// length-one state to guard against here, because a [LayrzDateRange]
/// instance only exists once both endpoints are known.
///
/// The in-progress, "only one endpoint chosen so far" state that the old API
/// modeled with a short list is represented in this batch by a nullable
/// [LayrzDateRange]`?` field being `null` combined with the surface's own
/// internal draft state — never by a [LayrzDateRange] with an unset field.
///
/// [start] and [end] may carry a `TZDateTime` (from `package:timezone`); this
/// type places no constraint on the [DateTime] subtype used.
@immutable
class LayrzDateRange {
  /// The start of the range, inclusive.
  final DateTime start;

  /// The end of the range, inclusive.
  final DateTime end;

  /// Creates a new [LayrzDateRange].
  ///
  /// [start] must not be after [end]. This is a `const`-compatible
  /// constructor, so the ordering is a documented caller contract rather than
  /// a runtime assertion — callers assembling a range from two
  /// possibly-reversed taps should use [LayrzDateRange.fromUnordered]
  /// instead, which normalizes (swaps) unconditionally. This mirrors the
  /// range selection state machine's auto-swap rule, implemented by the
  /// range policy classes.
  const LayrzDateRange({required this.start, required this.end});

  /// Creates a [LayrzDateRange] from two dates in either order, swapping them
  /// if necessary so [start] never falls after [end].
  ///
  /// This is the constructor callers assembling a range from two independent
  /// taps should use, rather than [LayrzDateRange.new] directly, since taps
  /// carry no inherent ordering guarantee.
  factory LayrzDateRange.fromUnordered(DateTime a, DateTime b) =>
      a.isAfter(b) ? LayrzDateRange(start: b, end: a) : LayrzDateRange(start: a, end: b);

  /// The inclusive span of this range, in whole days.
  ///
  /// A range where [start] and [end] fall on the same calendar day returns
  /// `1`, not `0` — the range covers one day.
  int get lengthInDays => end.difference(start).inDays + 1;

  /// Whether [date] falls within this range, inclusive of both endpoints.
  ///
  /// Compares calendar-day fields only (year/month/day); the time-of-day
  /// components of [start], [end], and [date] are ignored.
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  /// Returns a copy of this range with the given fields replaced.
  LayrzDateRange copyWith({DateTime? start, DateTime? end}) =>
      LayrzDateRange(start: start ?? this.start, end: end ?? this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LayrzDateRange && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'LayrzDateRange(start: $start, end: $end)';
}

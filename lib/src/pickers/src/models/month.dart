import 'package:flutter/widgets.dart';

/// An immutable, calendar-day-free representation of a single month.
///
/// Unlike [DateTime], [LayrzMonth] carries no day, hour, or timezone
/// component — it is a pure `(year, month)` pair. This is the value type
/// [LayrzMonthInput] and [LayrzMonthRangeInput] operate on, so a caller
/// picking "September 2026" gets exactly that, with no incidental day-of-month
/// value (e.g. always the 1st) to accidentally rely on.
///
/// Comparable via [compareTo] and the `<`/`<=`/`>`/`>=` operators, which order
/// months chronologically (year first, then month).
@immutable
class LayrzMonth implements Comparable<LayrzMonth> {
  /// The four-digit calendar year, e.g. `2026`.
  final int year;

  /// The calendar month, `1` (January) through `12` (December).
  final int month;

  /// Creates a new [LayrzMonth].
  ///
  /// [month] must be between 1 and 12 inclusive; asserted in debug builds.
  const LayrzMonth({required this.year, required this.month})
    : assert(month >= 1 && month <= 12, 'month must be between 1 and 12, got $month.');

  /// Creates a [LayrzMonth] from [dateTime]'s year and month, discarding the
  /// day, time-of-day, and timezone components.
  factory LayrzMonth.fromDateTime(DateTime dateTime) => LayrzMonth(year: dateTime.year, month: dateTime.month);

  /// Returns a plain (non-timezone-aware) [DateTime] for the first day of
  /// this month at midnight.
  ///
  /// Useful for feeding this value into calendar-grid arithmetic that expects
  /// a [DateTime]. Callers needing a specific [DateTime] subtype (e.g.
  /// `TZDateTime`) should construct it themselves from [year]/[month] instead.
  DateTime toDateTime() => DateTime(year, month);

  /// Returns a copy of this month with the given fields replaced.
  LayrzMonth copyWith({int? year, int? month}) => LayrzMonth(year: year ?? this.year, month: month ?? this.month);

  /// Returns the month immediately following this one, rolling [year] over
  /// at a December-to-January boundary.
  LayrzMonth get next => month == 12 ? LayrzMonth(year: year + 1, month: 1) : LayrzMonth(year: year, month: month + 1);

  /// Returns the month immediately preceding this one, rolling [year] back
  /// at a January-to-December boundary.
  LayrzMonth get previous =>
      month == 1 ? LayrzMonth(year: year - 1, month: 12) : LayrzMonth(year: year, month: month - 1);

  @override
  int compareTo(LayrzMonth other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }

  /// Whether this month is chronologically before [other].
  bool operator <(LayrzMonth other) => compareTo(other) < 0;

  /// Whether this month is chronologically before or equal to [other].
  bool operator <=(LayrzMonth other) => compareTo(other) <= 0;

  /// Whether this month is chronologically after [other].
  bool operator >(LayrzMonth other) => compareTo(other) > 0;

  /// Whether this month is chronologically after or equal to [other].
  bool operator >=(LayrzMonth other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LayrzMonth && other.year == year && other.month == month);

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'LayrzMonth(year: $year, month: $month)';
}

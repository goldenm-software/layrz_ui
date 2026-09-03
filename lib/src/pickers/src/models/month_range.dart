import 'package:flutter/widgets.dart';

import 'month.dart';

/// An immutable, always-valid, always-contiguous span between two months.
///
/// Mirrors [LayrzDateRange]'s design: [start] and [end] are non-nullable and
/// [start] is always less than or equal to [end], making the old
/// layrz_theme runtime-`assert`ed list shape unrepresentable. See
/// [LayrzDateRange]'s class doc for the fuller rationale, which applies here
/// unchanged.
///
/// **[LayrzMonthRange] models only the contiguous (consecutive-months) case.**
/// [LayrzMonthRangeInput]'s default arbitrary (non-contiguous) multi-select
/// mode is represented by `List<LayrzMonth>` instead — a discontinuous
/// selection of months has no single start/end pair to hold. This type
/// exists for the widget's optional consecutive mode, where the contiguous
/// range policy applies.
@immutable
class LayrzMonthRange {
  /// The first month of the range, inclusive.
  final LayrzMonth start;

  /// The last month of the range, inclusive.
  final LayrzMonth end;

  /// Creates a new [LayrzMonthRange].
  ///
  /// [start] must not be after [end]. As with [LayrzDateRange], this is a
  /// documented caller contract rather than a runtime assertion — see
  /// [LayrzMonthRange.fromUnordered] for the normalizing constructor.
  const LayrzMonthRange({required this.start, required this.end});

  /// Creates a [LayrzMonthRange] from two months in either order, swapping
  /// them if necessary so [start] never falls after [end].
  factory LayrzMonthRange.fromUnordered(LayrzMonth a, LayrzMonth b) =>
      a > b ? LayrzMonthRange(start: b, end: a) : LayrzMonthRange(start: a, end: b);

  /// The inclusive span of this range, in whole months.
  ///
  /// A range where [start] equals [end] returns `1`, not `0`.
  int get lengthInMonths => (end.year - start.year) * 12 + (end.month - start.month) + 1;

  /// Whether [month] falls within this range, inclusive of both endpoints.
  bool contains(LayrzMonth month) => month >= start && month <= end;

  /// Returns every [LayrzMonth] in this range, inclusive of both endpoints,
  /// in chronological order.
  List<LayrzMonth> toList() {
    final months = <LayrzMonth>[];
    var cursor = start;
    while (cursor <= end) {
      months.add(cursor);
      cursor = cursor.next;
    }
    return months;
  }

  /// Returns a copy of this range with the given fields replaced.
  LayrzMonthRange copyWith({LayrzMonth? start, LayrzMonth? end}) =>
      LayrzMonthRange(start: start ?? this.start, end: end ?? this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LayrzMonthRange && other.start == start && other.end == end);

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'LayrzMonthRange(start: $start, end: $end)';
}

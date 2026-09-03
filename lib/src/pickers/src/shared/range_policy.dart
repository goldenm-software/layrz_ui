import 'package:flutter/foundation.dart';

import 'range_draft.dart';

/// Shared contract for turning a single cell tap into the range selection
/// state machine's next [LayrzRangeDraft], for a value type [T].
///
/// **Two concrete implementations, not one generic policy** — see
/// [LayrzContiguousRangePolicy] and [LayrzArbitraryRangePolicy]. The domains
/// differ in kind, not merely in type: contiguous ranges (dates, datetimes,
/// times, and month-range in consecutive mode) need an adjacency concept —
/// "is this cell between the two endpoints" — driven by calendar-day or
/// month stepping, including leap years and month boundaries.
/// [LayrzMonthRangeInput]'s default arbitrary mode needs no adjacency
/// concept at all, only set membership. Forcing both through one generic
/// class would mean threading a stepping function through the arbitrary
/// case where it has no meaning, or threading a membership predicate through
/// the contiguous case where "between" already fully determines membership —
/// either way, one implementation ends up half-unused for every call.
///
/// **The interior-lock model (only first/last endpoints deselectable, every
/// interior cell locked as a matched pair) is retired and must not be
/// implemented by either policy.** The maintainer's endpoint-adjust ruling —
/// re-tapping either endpoint of a *complete* range picks that edge up and
/// makes it movable, the other edge stays fixed — governs both concrete
/// policies below. See the range selection state machine table for the full
/// per-state tap outcomes this interface's [onTap] implements.
///
/// **Naming note:** the plan's working names for the two concrete classes
/// were `_ContiguousRangePolicy`/`_ArbitraryRangePolicy`. They are declared
/// as ordinary (non-underscore) top-level classes here — [LayrzContiguousRangePolicy]
/// and [LayrzArbitraryRangePolicy] — because Dart's `_` privacy is
/// file-scoped, and every per-widget surface file (`date_range_surface.dart`,
/// `month_grid.dart`, etc.) living in a *different* file under
/// `lib/src/pickers/src/` must be able to construct them. "Library-private"
/// in this module's sense (see the module-boundary rule in the implementation
/// plan) means **not exported from `pickers.dart`**, not Dart-file-private —
/// these classes are absent from the per-module barrel and therefore
/// unreachable from outside `package:layrz_ui/src/pickers/...`, which is the
/// actual contract being enforced.
abstract interface class LayrzRangePolicy<T> {
  /// Computes the next [LayrzRangeDraft] resulting from tapping [tapped],
  /// given the [current] draft.
  ///
  /// Implementations must never mutate [current] — [LayrzRangeDraft] is
  /// immutable — and must return a *new* draft reflecting exactly one of the
  /// state machine's per-state outcomes for the tapped state
  /// (empty/half-open/complete).
  LayrzRangeDraft<T> onTap(LayrzRangeDraft<T> current, T tapped);

  /// Whether [candidate] would be **rejected** if tapped given [current] —
  /// i.e. an interior cell of an already-complete contiguous range, or (for
  /// the arbitrary policy) never, since arbitrary selection has no interior
  /// concept. Used by the day/month grid to render persistent, non-
  /// interactive styling on cells that would reject a tap **before** they
  /// are tapped, per the "silent rejection is forbidden" requirement —
  /// interior cells must read as locked from the moment a range exists, not
  /// only after an ignored tap.
  bool isRejected(LayrzRangeDraft<T> current, T candidate);
}

/// Range policy for domains with a well-defined adjacency/ordering —
/// contiguous dates, datetimes, times, and month-range in consecutive mode.
///
/// [compare] orders two values of [T] (typically `Comparable.compareTo`, or
/// a `DateTime`-specific comparison ignoring time-of-day where the caller
/// wants calendar-day granularity). [stepBetween] and [isBetween] both rely
/// only on [compare] — this policy needs no separate calendar-day stepping
/// function, because "is this cell between the endpoints" is fully
/// determined by ordering alone; actual calendar-day/month stepping (leap
/// years, month-length boundaries) lives in the caller's grid-generation
/// code (`grid_math.dart`, `month_grid.dart`), not in this policy.
class LayrzContiguousRangePolicy<T> implements LayrzRangePolicy<T> {
  /// Orders two values of [T]; negative when `a` precedes `b`, zero when
  /// equal, positive when `a` follows `b`.
  final int Function(T a, T b) compare;

  /// Creates a new [LayrzContiguousRangePolicy].
  const LayrzContiguousRangePolicy({required this.compare});

  bool _isBefore(T a, T b) => compare(a, b) < 0;
  bool _isAfter(T a, T b) => compare(a, b) > 0;
  bool _isEqual(T a, T b) => compare(a, b) == 0;

  @override
  LayrzRangeDraft<T> onTap(LayrzRangeDraft<T> current, T tapped) {
    // Empty -> half-open: anchor set, nothing else changes.
    if (current.anchor == null && !current.isComplete) {
      return LayrzRangeDraft.anchored(tapped);
    }

    // Half-open -> complete, auto-swapped so start <= end.
    if (!current.isComplete && current.anchor != null) {
      final anchor = current.anchor as T;
      final start = _isAfter(anchor, tapped) ? tapped : anchor;
      final end = _isAfter(anchor, tapped) ? anchor : tapped;
      return LayrzRangeDraft.complete(anchor: start, end: end);
    }

    // Complete: either endpoint re-tapped picks that edge up.
    final start = current.anchor as T;
    final end = current.end as T;
    if (_isEqual(tapped, start)) {
      return current.copyWith(movableEndpoint: LayrzRangeEndpoint.start);
    }
    if (_isEqual(tapped, end)) {
      return current.copyWith(movableEndpoint: LayrzRangeEndpoint.end);
    }

    // Complete, an endpoint already picked up: move that edge to the
    // tapped value, auto-swapping if it crosses the fixed edge.
    if (current.movableEndpoint != null) {
      if (current.movableEndpoint == LayrzRangeEndpoint.start) {
        final fixedEnd = end;
        final newStart = _isAfter(tapped, fixedEnd) ? fixedEnd : tapped;
        final newEnd = _isAfter(tapped, fixedEnd) ? tapped : fixedEnd;
        return LayrzRangeDraft.complete(anchor: newStart, end: newEnd);
      } else {
        final fixedStart = start;
        final newStart = _isBefore(tapped, fixedStart) ? tapped : fixedStart;
        final newEnd = _isBefore(tapped, fixedStart) ? fixedStart : tapped;
        return LayrzRangeDraft.complete(anchor: newStart, end: newEnd);
      }
    }

    // Complete, no endpoint picked up, interior cell tapped: rejected, no
    // change.
    if (_isBetween(tapped, start, end)) {
      return current;
    }

    // Complete, cell outside the range tapped: extend the nearer endpoint.
    final distanceToStart = (compare(tapped, start)).abs();
    final distanceToEnd = (compare(tapped, end)).abs();
    if (_isBefore(tapped, start)) {
      return LayrzRangeDraft.complete(anchor: tapped, end: end);
    }
    if (_isAfter(tapped, end)) {
      return LayrzRangeDraft.complete(anchor: start, end: tapped);
    }
    // Unreachable in practice (covered by the between/before/after checks
    // above), kept for exhaustiveness against a degenerate `compare`.
    return distanceToStart <= distanceToEnd
        ? LayrzRangeDraft.complete(anchor: tapped, end: end)
        : LayrzRangeDraft.complete(anchor: start, end: tapped);
  }

  @override
  bool isRejected(LayrzRangeDraft<T> current, T candidate) {
    if (!current.isComplete || current.movableEndpoint != null) return false;
    final start = current.anchor as T;
    final end = current.end as T;
    if (_isEqual(candidate, start) || _isEqual(candidate, end)) return false;
    return _isBetween(candidate, start, end);
  }

  bool _isBetween(T value, T start, T end) => !_isBefore(value, start) && !_isAfter(value, end);
}

/// Range policy for the non-contiguous (arbitrary) domain — set membership,
/// no adjacency concept. [LayrzMonthRangeInput]'s default mode: any subset
/// of months may be selected, including a discontinuous one.
///
/// A tap on an already-selected value removes it; a tap on an unselected
/// value adds it. There is no anchor/end pair, no auto-swap, and no
/// "interior" concept to reject — every unselected candidate is always
/// selectable, which is exactly what makes this policy able to produce gaps
/// where [LayrzContiguousRangePolicy] cannot.
@immutable
class LayrzArbitraryRangePolicy<T> implements LayrzRangePolicy<T> {
  /// Creates a new [LayrzArbitraryRangePolicy].
  const LayrzArbitraryRangePolicy();

  @override
  LayrzRangeDraft<T> onTap(LayrzRangeDraft<T> current, T tapped) {
    final next = Set<T>.of(current.arbitrarySelection);
    if (!next.add(tapped)) {
      next.remove(tapped);
    }
    return LayrzRangeDraft.arbitrary(next);
  }

  @override
  bool isRejected(LayrzRangeDraft<T> current, T candidate) => false;
}

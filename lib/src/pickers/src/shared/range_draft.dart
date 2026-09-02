import 'package:flutter/foundation.dart';

/// The in-progress selection state a range surface holds while a range is
/// being built or adjusted, before it is reported via `onChanged`/committed
/// via Save.
///
/// A [LayrzRangeDraft] models exactly the three states the range selection
/// state machine defines: **empty** (`anchor == null`, `isComplete == false`),
/// **half-open/anchor-set** (`anchor != null`, `isComplete == false`), and
/// **complete** (`isComplete == true`, both endpoints resolved). It is
/// generic over [T] so the same shape serves both the contiguous date/month
/// domain and (via [LayrzRangeDraft.arbitrary]) a non-contiguous set of
/// values — see `range_policy.dart` for the two concrete policies that
/// mutate a draft of this shape.
///
/// **This type intentionally holds no result-producing logic itself** — it
/// is a plain state container. The policy classes in `range_policy.dart`
/// compute the *next* draft from a tap; this type just carries whichever
/// draft resulted.
@immutable
class LayrzRangeDraft<T> {
  /// The first endpoint chosen so far.
  ///
  /// `null` when the draft is empty (nothing chosen yet). Non-null in both
  /// the half-open and complete states.
  final T? anchor;

  /// The second endpoint, once chosen.
  ///
  /// `null` until the draft becomes complete. Always non-null when
  /// [isComplete] is `true`.
  final T? end;

  /// Which endpoint ([anchor] or [end]) was most recently picked up and made
  /// movable by an endpoint re-tap, if any.
  ///
  /// `null` when no endpoint is currently "picked up" — the ordinary
  /// resting state after a range first completes, or after Cancel/Save.
  /// Non-null only in the "complete, one edge movable" state the range
  /// selection state machine describes for a re-tap on either endpoint.
  final LayrzRangeEndpoint? movableEndpoint;

  /// Every value currently selected, for the non-contiguous (arbitrary)
  /// domain only.
  ///
  /// Empty for the contiguous domain, which uses [anchor]/[end] instead.
  /// See [LayrzRangeDraft.arbitrary].
  final Set<T> arbitrarySelection;

  /// Whether this draft represents a completed range: both endpoints are
  /// resolved (contiguous domain) or [arbitrarySelection] is non-empty
  /// (arbitrary domain).
  final bool isComplete;

  /// Creates a new [LayrzRangeDraft] directly.
  ///
  /// Most callers should use [LayrzRangeDraft.empty], [LayrzRangeDraft.anchored],
  /// [LayrzRangeDraft.complete], or [LayrzRangeDraft.arbitrary] instead of this
  /// constructor, which places no consistency checks between its fields.
  const LayrzRangeDraft({
    this.anchor,
    this.end,
    this.movableEndpoint,
    this.arbitrarySelection = const {},
    this.isComplete = false,
  });

  /// The empty draft: nothing chosen yet.
  const LayrzRangeDraft.empty() : this();

  /// A half-open draft with only [anchor] chosen.
  const LayrzRangeDraft.anchored(T anchor) : this(anchor: anchor);

  /// A complete contiguous draft spanning [anchor] to [end].
  const LayrzRangeDraft.complete({required T anchor, required T end, LayrzRangeEndpoint? movableEndpoint})
    : this(anchor: anchor, end: end, isComplete: true, movableEndpoint: movableEndpoint);

  /// A draft for the arbitrary (non-contiguous) domain, holding [selection]
  /// directly with no anchor/end concept.
  ///
  /// Not a `const` constructor — `Set.isNotEmpty` is not evaluable in a
  /// constant context, so `LayrzRangeDraft.arbitrary(const {})` cannot be
  /// combined with `const`. Construct non-const instances instead (still
  /// cheap: this is a plain state container, not something built per frame
  /// in a hot loop).
  LayrzRangeDraft.arbitrary(Set<T> selection) : this(arbitrarySelection: selection, isComplete: selection.isNotEmpty);

  /// Returns a copy of this draft with the given fields replaced.
  ///
  /// [clearMovableEndpoint] resets [movableEndpoint] to `null` even though
  /// the ordinary `??`-based `copyWith` pattern cannot distinguish "leave
  /// unchanged" from "set to null" for a nullable field.
  LayrzRangeDraft<T> copyWith({
    T? anchor,
    T? end,
    LayrzRangeEndpoint? movableEndpoint,
    bool clearMovableEndpoint = false,
    Set<T>? arbitrarySelection,
    bool? isComplete,
  }) {
    return LayrzRangeDraft<T>(
      anchor: anchor ?? this.anchor,
      end: end ?? this.end,
      movableEndpoint: clearMovableEndpoint ? null : (movableEndpoint ?? this.movableEndpoint),
      arbitrarySelection: arbitrarySelection ?? this.arbitrarySelection,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayrzRangeDraft<T> &&
          other.anchor == anchor &&
          other.end == end &&
          other.movableEndpoint == movableEndpoint &&
          setEquals(other.arbitrarySelection, arbitrarySelection) &&
          other.isComplete == isComplete);

  @override
  int get hashCode =>
      Object.hash(anchor, end, movableEndpoint, Object.hashAllUnordered(arbitrarySelection), isComplete);

  @override
  String toString() =>
      'LayrzRangeDraft(anchor: $anchor, end: $end, movableEndpoint: $movableEndpoint, '
      'arbitrarySelection: $arbitrarySelection, isComplete: $isComplete)';
}

/// Identifies which side of a completed contiguous range a re-tap picked up,
/// per the range selection state machine's endpoint-adjust rule.
enum LayrzRangeEndpoint {
  /// The range's start/anchor edge.
  start,

  /// The range's end edge.
  end,
}

import 'package:flutter/widgets.dart';

/// One matched [SemanticsNode] found by a browser-style "find in page" query.
///
/// Produced by `walkSemantics` in `semantics_walker.dart` — see that
/// function's doc for the full matching algorithm. A [FindMatch] is a pure
/// snapshot: it does not hold a live reference to the [SemanticsNode] it was
/// derived from, only the data a highlight overlay or a "jump to match" action
/// needs — the node's stable [nodeId], its on-screen [globalRect], the text
/// [label] that was searched, and the substring [hits] within that text.
///
/// This is a SPIKE-stage type: the shape (in particular, whether a match
/// should also carry the originating node's [SemanticsAction] bitmask, so a
/// highlight overlay can tell a scrollable match from a plain one without a
/// second tree walk) is expected to evolve once the production
/// `LayrzFindInPage` widget is designed. Treat it as a proof of the mechanism,
/// not a frozen contract.
@immutable
class FindMatch {
  /// The stable identifier of the matched [SemanticsNode], as returned by
  /// `SemanticsNode.id`.
  ///
  /// Stable for the lifetime of the node (it does not change across
  /// rebuilds/relayouts of the same underlying widget), which is what makes it
  /// safe to pass back into `SemanticsOwner.performAction` — for example to
  /// invoke `SemanticsAction.showOnScreen` and scroll a match into view — from
  /// a later frame than the one that produced this [FindMatch].
  final int nodeId;

  /// The matched node's bounding box in the global (root) coordinate space.
  ///
  /// Computed by accumulating every ancestor's [SemanticsNode.transform] down
  /// to this node and applying it to the node's own (parent-relative)
  /// [SemanticsNode.rect] via `MatrixUtils.transformRect`. Suitable for
  /// painting a highlight directly over the rendered widget, since it is
  /// already in the same coordinate space the root [CustomPainter] paints in.
  final Rect globalRect;

  /// The searched text this match was found in — the node's semantics
  /// `label`, or `label` and `value` joined with a space when both are
  /// present (see `walkSemantics`'s haystack-construction rule).
  ///
  /// Kept alongside [hits] (rather than requiring the caller to re-read the
  /// live [SemanticsNode]) so a highlight overlay or a debug view can render
  /// the matched text without walking the tree again.
  final String label;

  /// The substring ranges within [label] that matched the query, in the order
  /// they occur in [label].
  ///
  /// Always non-empty for a constructed [FindMatch] — `walkSemantics` only
  /// emits a match when at least one occurrence was found. Each [TextRange]
  /// is a `[start, end)` offset pair into [label], suitable for driving a
  /// `TextSpan`-based highlight of the matched substrings within their
  /// surrounding text.
  final List<TextRange> hits;

  /// Whether the originating [SemanticsNode] was flagged
  /// [SemanticsFlags.isHidden] at the time this match was produced.
  ///
  /// A node built by a [Scrollable] descendant but currently scrolled out of
  /// the viewport is still present in the semantics tree — Flutter marks it
  /// `isHidden` rather than omitting it — so `walkSemantics` includes it as a
  /// real, jumpable match (mirroring a browser's Ctrl+F, which finds text
  /// anywhere in the document, not just in the current viewport). [isHidden]
  /// is what lets a caller tell the two cases apart: a highlight overlay
  /// should skip painting a hidden match (its [globalRect] reflects wherever
  /// the offscreen content currently sits, which is not meaningful to draw
  /// until the match is scrolled into view via
  /// `SemanticsAction.showOnScreen`), while the match counter and "Next"
  /// navigation must still count and cycle through it.
  final bool isHidden;

  /// Creates a [FindMatch].
  const FindMatch({
    required this.nodeId,
    required this.globalRect,
    required this.label,
    required this.hits,
    this.isHidden = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FindMatch &&
        other.nodeId == nodeId &&
        other.globalRect == globalRect &&
        other.label == label &&
        other.isHidden == isHidden &&
        _hitsEqual(other.hits, hits);
  }

  /// Compares two match lists for equality by value.
  ///
  /// `List<TextRange>` has no built-in value equality, so [==] cannot simply
  /// compare [hits] with `==` — this walks both lists pairwise instead.
  static bool _hitsEqual(List<TextRange> a, List<TextRange> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(nodeId, globalRect, label, isHidden, Object.hashAll(hits));

  @override
  String toString() =>
      'FindMatch(nodeId: $nodeId, globalRect: $globalRect, label: $label, hits: $hits, isHidden: $isHidden)';
}

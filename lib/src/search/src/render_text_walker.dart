import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A single piece of painted text discovered by [findRenderTextSources], with
/// enough of its own [RenderObject] exposed to compute word-level highlight
/// geometry without this file needing to know whether the underlying widget
/// was a [Text], a [RichText], or an [EditableText].
///
/// ### Why this exists at all
/// A [SemanticsNode] (what `walkSemantics` in `semantics_walker.dart` finds
/// matches against) has no public path back to the [RenderObject] that
/// produced it — that mapping simply isn't exposed by the framework outside
/// of a debug-only accessor (see the example find-in-page spike's
/// `_findBarSubtreeId` doc, in
/// `example/lib/src/sections/find_in_page/find_spike.dart`, for the one place
/// that spike does rely on that debug accessor, and why it is an accepted
/// spike-only limitation there).
///
/// Rather than trying to resolve "this semantics match's exact
/// [RenderObject]", this walks the **render tree** directly — independently
/// of semantics entirely — collecting every [RenderParagraph] (backing
/// [Text] and [RichText]) and [RenderEditable] (backing [EditableText]) it
/// finds, each already carrying both the text it painted *and* the geometry
/// to compute per-character boxes from ([RenderParagraph.getBoxesForSelection]
/// / [RenderEditable.getBoxesForSelection]). A caller then correlates one of
/// these against a given [FindMatch.globalRect] by simple rect containment
/// (see [findAllTextOccurrences] callers in the example find-in-page spike's
/// `find_spike.dart`, at `example/lib/src/sections/find_in_page/`) — geometry
/// is a far more stable correlation key here than any node-identity scheme would
/// be, since a [Text]/[RichText]'s own [Semantics] wrapper paints at exactly
/// the same box as the [RenderParagraph] beneath it (no intervening padding),
/// and an unscrolled, single-line [EditableText]'s [RenderEditable] does the
/// same relative to its own [Semantics] node.
///
/// This is intentionally *not* wired into every match — see the example
/// find-in-page spike's `build()` (in
/// `example/lib/src/sections/find_in_page/find_spike.dart`) for why only the
/// currently-**visible** matches are ever resolved against this list:
/// [getBoxesForSelection] is
/// real per-glyph layout work, and paying it for dozens of scrolled-away
/// matches on every frame would be wasted cost for boxes nobody can see
/// anyway.
@immutable
class RenderTextSource {
  /// The exact text this render object painted, suitable for locating query
  /// occurrences at the same character offsets [boxesForSelection] expects.
  ///
  /// Deliberately **not** the originating [Semantics] node's accessibility
  /// label — [Text.semanticsLabel] (and, more subtly, how [RichText] combines
  /// its spans' `semanticsLabel`s) can legitimately differ from what was
  /// actually painted on screen, and it is the painted text a visual
  /// highlight must be measured against.
  ///
  /// **Must be built with `includePlaceholders: true`** (see
  /// [InlineSpan.toPlainText]) — a [WidgetSpan] (an inline icon or other
  /// embedded widget) occupies exactly one `0xFFFC` object-replacement
  /// character in [TextSelection]'s own offset space (the same space
  /// [TextPainter]'s internal layout counts against), so this string's
  /// character offsets only line up with what [boxesForSelection] indexes
  /// into when placeholders are counted here exactly as the layout counts
  /// them. Building this with placeholders stripped would silently shift
  /// every occurrence found *after* a placeholder in the searched text by
  /// however many placeholder characters were dropped, while
  /// [boxesForSelection] keeps indexing against the placeholder-inclusive
  /// layout — a caller comparing an occurrence found in a stripped string
  /// against boxes measured in the placeholder-inclusive space is exactly
  /// how a "found the right word, painted the wrong one" bug like this one
  /// happens. See [_fromParagraph]/[_fromEditable] for where this is built.
  final String plainText;

  /// This render object's bounding box in the same global (screen-origin)
  /// coordinate space `walkSemantics` computes [FindMatch.globalRect] in —
  /// see [RenderObject.getTransformTo] (called with a `null` target) for why
  /// the two coordinate spaces coincide.
  final Rect globalRect;

  /// Returns the global-space rectangles covering [selection] within this
  /// source's painted text — one per visually-distinct run (a wrapped word
  /// spans two boxes; a bidirectional boundary can too).
  ///
  /// A thin wrapper closing over whichever of
  /// [RenderParagraph.getBoxesForSelection] or
  /// [RenderEditable.getBoxesForSelection] this source was built from, with
  /// the local [TextBox]es already converted to global coordinates via the
  /// same transform used for [globalRect] — callers never need to know which
  /// of the two render object types is underneath.
  final List<Rect> Function(TextSelection selection) boxesForSelection;

  /// The underlying [RenderParagraph] or [RenderEditable] this source was
  /// built from.
  ///
  /// Exposed purely as an escape hatch for a caller that needs render-tree
  /// identity or ancestry (for example, telling whether this source sits
  /// inside a particular subtree — see the example find-in-page spike's
  /// diagnostic logging in `_resolveHighlights`
  /// (`example/lib/src/sections/find_in_page/find_spike.dart`) for why that
  /// matters: the top bar's own
  /// query field is itself a source, and correlating a content match against
  /// it by mistake would look exactly like this module's consumers
  /// correlating against the wrong candidate). Ordinary geometry
  /// and text resolution never needs this — [globalRect], [plainText], and
  /// [boxesForSelection] already cover that.
  final RenderObject renderObject;

  /// Creates a [RenderTextSource].
  const RenderTextSource({
    required this.plainText,
    required this.globalRect,
    required this.boxesForSelection,
    required this.renderObject,
  });
}

/// Walks the live render tree rooted at [root], collecting a
/// [RenderTextSource] for every [RenderParagraph] and [RenderEditable] found,
/// in depth-first traversal order.
///
/// [root] is normally obtained the same way the example find-in-page spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`) obtains its
/// semantics root — via the relevant [PipelineOwner]'s render tree root (see
/// `PipelineOwner.rootNode`) rather than any deprecated flat binding accessor.
///
/// This is a **pure, read-only** traversal: it never mutates layout, never
/// triggers a rebuild, and is safe to call from within a frame callback once
/// layout has settled (the same timing `walkSemantics` already requires — see
/// that spike's `_scheduleWalk`). Calling it before the first layout
/// has completed for a given subtree throws the same assertion
/// [RenderParagraph.getBoxesForSelection]/[RenderEditable.getBoxesForSelection]
/// would (`debugNeedsLayout`), so callers must only invoke this after layout,
/// exactly like every other geometry read in this module.
///
/// A node that is a [RenderParagraph] or [RenderEditable] still has its own
/// children visited afterward (an [InlineSpan] can embed a
/// [WidgetSpan]-backed child render object with its own nested text) —
/// nothing is pruned once a match is found, unlike `walkSemantics`'s
/// `excludeSubtreeRootIds` pruning, since there is no equivalent "this
/// subtree is UI chrome" concept at the render-tree level; the find bar's own
/// text fields are filtered out later by the caller correlating against
/// already semantics-filtered [FindMatch]es, not here.
List<RenderTextSource> findRenderTextSources(RenderObject root) {
  final sources = <RenderTextSource>[];

  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      sources.add(_fromParagraph(node));
    } else if (node is RenderEditable) {
      sources.add(_fromEditable(node));
    }
    node.visitChildren(visit);
  }

  visit(root);
  return sources;
}

/// Builds a [RenderTextSource] backed by a [RenderParagraph] (the
/// [RenderObject] behind both [Text] and [RichText]).
///
/// See [_localToGlobalRect]'s doc for why each rect is converted corner-wise
/// via [RenderBox.localToGlobal] rather than via a single cached
/// [RenderObject.getTransformTo] matrix applied through [MatrixUtils].
RenderTextSource _fromParagraph(RenderParagraph paragraph) {
  return RenderTextSource(
    // includePlaceholders defaults to true, but is passed explicitly here —
    // see plainText's own doc for why this must never be false: stripping
    // placeholders would desynchronize this string's offsets from what
    // getBoxesForSelection indexes into below.
    plainText: paragraph.text.toPlainText(includeSemanticsLabels: false, includePlaceholders: true),
    globalRect: _localToGlobalRect(paragraph, Offset.zero & paragraph.size),
    boxesForSelection: (selection) => paragraph
        .getBoxesForSelection(selection)
        .map((box) => _localToGlobalRect(paragraph, box.toRect()))
        .toList(growable: false),
    renderObject: paragraph,
  );
}

/// Builds a [RenderTextSource] backed by a [RenderEditable] (the
/// [RenderObject] behind [EditableText], and so every text-input widget built
/// on it).
///
/// See [_localToGlobalRect]'s doc for why each rect is converted corner-wise
/// via [RenderBox.localToGlobal] rather than via a single cached
/// [RenderObject.getTransformTo] matrix applied through [MatrixUtils].
RenderTextSource _fromEditable(RenderEditable editable) {
  return RenderTextSource(
    // Same explicit includePlaceholders: true as _fromParagraph — see
    // plainText's own doc for why.
    plainText: editable.text?.toPlainText(includeSemanticsLabels: false, includePlaceholders: true) ?? '',
    globalRect: _localToGlobalRect(editable, Offset.zero & editable.size),
    boxesForSelection: (selection) => editable
        .getBoxesForSelection(selection)
        .map((box) => _localToGlobalRect(editable, box.toRect()))
        .toList(growable: false),
    renderObject: editable,
  );
}

/// Converts [localRect] — expressed in [box]'s own local coordinate system —
/// to the global (screen-origin) coordinate space, via
/// [RenderBox.localToGlobal] applied to each corner independently.
///
/// ### Why not a single cached transform matrix
/// An earlier version of this file computed `box.getTransformTo(null)` once
/// and reused that one [Matrix4] (via [MatrixUtils.transformRect]) for every
/// rect a given render object needed converted. [RenderBox.localToGlobal]
/// with no `ancestor` argument calls exactly that same
/// `getTransformTo(null)` internally per point — so on a per-call basis the
/// two approaches are mathematically identical — but converting
/// [localRect]'s corners individually here (rather than caching the matrix
/// once per source and reusing it across every occurrence's boxes) keeps
/// every conversion self-contained and unambiguous about which coordinate
/// space it targets, and matches [RenderBox.localToGlobal] being the
/// documented, public spelling of "map a point on this box to the screen"
/// (`getTransformTo` is the lower-level primitive `localToGlobal` itself is
/// built on).
///
/// [Rect.fromPoints] rather than [MatrixUtils.transformRect] on the whole
/// rect: the two agree for the pure translation/scale case this module deals
/// with (no rotation), so this is a spelling choice, not a behavior change.
Rect _localToGlobalRect(RenderBox box, Rect localRect) {
  return Rect.fromPoints(
    box.localToGlobal(localRect.topLeft),
    box.localToGlobal(localRect.bottomRight),
  );
}

/// Finds the best [RenderTextSource] in [sources] to resolve word-level
/// geometry for a semantics match whose whole-node box is [targetGlobalRect],
/// or `null` when nothing in [sources] plausibly backs that match.
///
/// ### Why containment, not equality
/// A [Text]/[RichText]'s [Semantics] node and its [RenderParagraph] paint at
/// exactly the same box in the common case, but small sub-pixel rounding
/// differences between the two coordinate computations (semantics transforms
/// accumulate via [SemanticsNode.transform]; render geometry via
/// [RenderObject.getTransformTo]) make exact equality an unnecessarily
/// brittle check. Instead, a candidate qualifies when [targetGlobalRect]'s
/// center point falls inside the candidate's [RenderTextSource.globalRect]
/// (inflated by a tiny epsilon to tolerate that rounding) — a semantics
/// node's rect and its backing paragraph's rect always share substantially
/// the same area, so the node's own center is reliably inside the paragraph
/// whenever the two genuinely correspond, while a same-screen but unrelated
/// paragraph elsewhere essentially never happens to contain that same point.
///
/// When more than one candidate contains the center (nested inline widgets
/// can in principle overlap), the smallest-area candidate wins — the most
/// specific (innermost) match is preferred over a coarser ancestor.
RenderTextSource? resolveRenderTextSource(Rect targetGlobalRect, List<RenderTextSource> sources) {
  final center = targetGlobalRect.center;
  RenderTextSource? best;
  double bestArea = double.infinity;

  for (final source in sources) {
    // A generous inflate (rather than a strict `contains`) absorbs the kind
    // of sub-pixel rounding described above without needing a bespoke
    // "almost contains" comparison.
    final inflated = source.globalRect.inflate(0.5);
    if (!inflated.contains(center)) continue;

    final area = source.globalRect.width * source.globalRect.height;
    if (area < bestArea) {
      best = source;
      bestArea = area;
    }
  }

  return best;
}

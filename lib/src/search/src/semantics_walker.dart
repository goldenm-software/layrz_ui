import 'package:flutter/rendering.dart';

import 'find_match.dart';
import 'find_text_occurrences.dart';

/// Walks the semantics tree rooted at [root], collecting every node whose
/// text contains [query] as a substring, and returns them as [FindMatch]es
/// ordered in reading order (top-to-bottom, then left-to-right).
///
/// This is the testable core of the DESIGN-109 find-in-page spike: a pure
/// function over an already-built semantics tree, with no dependency on any
/// widget, painter, or binding beyond the [SemanticsNode] API itself. A
/// caller obtains [root] from a live tree via
/// `WidgetsBinding.instance.pipelineOwner.semanticsOwner?.rootSemanticsNode`
/// (which requires an active [SemanticsHandle] — see
/// `SemanticsBinding.instance.ensureSemantics()` — since the semantics tree is
/// only built at all while at least one handle is held).
///
/// ### Browser-parity behavior: hidden (scrolled-out-of-view) nodes count
/// A node whose [RenderObject] lives under a [Scrollable] but is currently
/// scrolled outside the viewport is **not removed** from the semantics tree —
/// Flutter keeps the node and flags it [SemanticsFlags.isHidden] instead (see
/// `RenderViewport`'s use of `SemanticsConfiguration.isHidden`). A real
/// browser's Ctrl+F finds matches anywhere in the document regardless of
/// scroll position, so this walk **includes** `isHidden` nodes in the
/// haystack search by default — matching that behavior — and records the
/// flag on the resulting [FindMatch.isHidden] so a caller can still tell a
/// currently-visible match from an offscreen one (for example, to skip
/// painting a highlight whose rect isn't meaningful until the match is
/// scrolled into view).
///
/// [includeHidden] defaults to `true` for that reason. Passing `false`
/// restores the pre-DESIGN-109-correction "visible content only" behavior
/// (matching what an [ExcludeSemantics]-style, non-scrolling audit would
/// want), and is kept as a parameter — rather than deleting the old
/// behavior outright — purely so both semantics remain independently
/// testable.
///
/// A node whose flags mark it [SemanticsFlags.scopesRoute] is always skipped
/// (excluded from the haystack search, though its children are still
/// visited) regardless of [includeHidden] — such a node is a route boundary
/// (dialog/page) whose own label is a navigational landmark, not page
/// content a "find" query should surface as a match. A node whose haystack is
/// empty (no label, no value) is never indexed, regardless of flags.
///
/// ### Excluding the find bar's own subtree
/// A find-in-page UI's own query field, buttons, and match counter are
/// themselves part of the semantics tree the walk runs over — without
/// exclusion, typing "mango" into the query field makes the field match its
/// own current value. [excludeSubtreeRootIds] prunes the node with each
/// given [SemanticsNode.id] *and all of its descendants* from the walk
/// entirely (they contribute no [FindMatch] and are not visited further).
/// This is a set (rather than a single id) so a caller composed of more than
/// one disjoint region needing exclusion (e.g. a floating find bar plus a
/// separate results-count badge) can exclude all of them in one call. Pass
/// `const {}` (the default) to exclude nothing.
///
/// The id-based approach is preferred over wrapping the excluded region in
/// [ExcludeSemantics] because that would also strip the region's *own*
/// accessibility semantics (e.g. the query [EditableText] would stop being
/// announced to screen readers) — this walk needs to hide that subtree from
/// *its own query results* without hiding it from assistive technology.
/// Obtaining the id in the first place means resolving the excluded widget's
/// [GlobalKey] to a live [RenderObject] and reading a
/// [SemanticsNode.id] off it — see the example find-in-page spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`) for how the
/// spike does this, and its doc for a caveat on the API used.
///
/// ### Algorithm
/// A depth-first traversal (`node.visitChildren`) accumulates each ancestor's
/// [SemanticsNode.transform] into a running [Matrix4] (parent transform
/// composed with the node's own, `null` treated as identity), so every node's
/// [SemanticsNode.rect] — which is expressed in its **parent's** coordinate
/// space — can be converted to the root's (global) coordinate space via
/// `MatrixUtils.transformRect`. This is the same accumulation
/// [SemanticsNode.transform]'s own doc describes ("the transform from this
/// node's coordinate system to its parent's coordinate system"). A hidden
/// node's global rect may legitimately sit far outside the current viewport
/// (large or negative offsets) — that is expected and correct; it reflects
/// wherever the offscreen content actually is, and becomes meaningful again
/// once the node is scrolled into view.
///
/// For each non-excluded, non-route-scoping node, [SemanticsNode.getSemanticsData]
/// is read once and used to build a "haystack": the node's `label`, and — if
/// non-empty — its `value`, joined with a single space (`"$label $value"`).
///
/// [caseSensitive] controls whether the match is exact-case (`false`, the
/// default, folds both [query] and the haystack via [String.toLowerCase]
/// before comparing) or case-sensitive.
///
/// Matching finds **every non-overlapping occurrence** of [query] in the
/// haystack (a simple left-to-right scan, advancing past each match by its
/// full length so `"aa"` in `"aaaa"` yields two hits, not three) and records
/// each as a [TextRange] into the *original-case* haystack. A node with zero
/// occurrences contributes no [FindMatch]. Each [SemanticsNode.id] is only
/// ever emitted once — the traversal visits each node exactly once by
/// construction, so no separate de-duplication pass is needed.
///
/// The returned list is sorted by [FindMatch.globalRect]'s `top`, then `left`
/// — an approximation of reading order that is exact for the spike's
/// single-column layouts and "good enough" for the general case; true
/// bidi/RTL-aware reading order is out of scope for this proof of mechanism.
/// A hidden node below the fold simply has a larger `top`, so it sorts after
/// the currently-visible matches above it — which is exactly the order a
/// "Next" action should visit it in.
///
/// An empty or all-whitespace [query] returns `const []` immediately — there
/// is no such thing as a "match everything" query in a find-in-page UI, and
/// this also protects [findAllTextOccurrences] from being asked to search for
/// an empty string (which would otherwise match at every offset).
List<FindMatch> walkSemantics(
  SemanticsNode root,
  String query, {
  bool caseSensitive = false,
  bool includeHidden = true,
  Set<int> excludeSubtreeRootIds = const {},
}) {
  if (query.trim().isEmpty) {
    return const [];
  }

  final needle = caseSensitive ? query : query.toLowerCase();
  final matches = <FindMatch>[];

  void visit(SemanticsNode node, Matrix4 ancestorTransform) {
    if (excludeSubtreeRootIds.contains(node.id)) {
      return;
    }

    final nodeTransform = node.transform;
    final transform = nodeTransform == null ? ancestorTransform : ancestorTransform.multiplied(nodeTransform);

    final data = node.getSemanticsData();
    final isHidden = data.flagsCollection.isHidden;
    if ((includeHidden || !isHidden) && !data.flagsCollection.scopesRoute) {
      final haystack = data.value.isEmpty ? data.label : '${data.label} ${data.value}';
      if (haystack.isNotEmpty) {
        final hits = findAllTextOccurrences(haystack, needle, caseSensitive: caseSensitive);
        if (hits.isNotEmpty) {
          matches.add(
            FindMatch(
              nodeId: node.id,
              globalRect: MatrixUtils.transformRect(transform, node.rect),
              label: haystack,
              hits: hits,
              isHidden: isHidden,
            ),
          );
        }
      }
    }

    node.visitChildren((child) {
      visit(child, transform);
      return true;
    });
  }

  visit(root, Matrix4.identity());

  matches.sort((a, b) {
    final topCompare = a.globalRect.top.compareTo(b.globalRect.top);
    if (topCompare != 0) return topCompare;
    return a.globalRect.left.compareTo(b.globalRect.left);
  });

  return matches;
}

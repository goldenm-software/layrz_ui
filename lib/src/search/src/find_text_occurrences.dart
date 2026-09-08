import 'package:flutter/widgets.dart';

/// Finds every non-overlapping occurrence of [needle] within [haystack],
/// returning each as a [TextRange] expressed in [haystack]'s own (original
/// case) offsets.
///
/// Shared by `walkSemantics` (matching against a [SemanticsNode]'s label) and
/// the render-tree word-level resolver in `render_text_walker.dart` (matching
/// against a [RenderParagraph]/[RenderEditable]'s painted plain text) — both
/// need the identical left-to-right, non-overlapping scan so that "how many
/// times does the query occur" and "where do I draw a box for each occurrence"
/// never disagree with each other for the same text.
///
/// [needle] is expected to already be case-folded by the caller when
/// [caseSensitive] is `false` — this function folds a throwaway copy of
/// [haystack] the same way purely to locate offsets, then reports those
/// offsets against the original-case [haystack] so callers can still render
/// or index into the true text.
///
/// A given match advances the scan past its own full length, so `"aa"` in
/// `"aaaa"` yields two hits, not three (three would double-count the middle
/// `"a"`).
List<TextRange> findAllTextOccurrences(String haystack, String needle, {required bool caseSensitive}) {
  final searchSpace = caseSensitive ? haystack : haystack.toLowerCase();
  final hits = <TextRange>[];
  var start = 0;
  while (true) {
    final index = searchSpace.indexOf(needle, start);
    if (index < 0) break;
    hits.add(TextRange(start: index, end: index + needle.length));
    start = index + needle.length;
  }
  return hits;
}

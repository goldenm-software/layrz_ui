import 'package:flutter/widgets.dart';

import 'find_match.dart';
import 'find_text_occurrences.dart';
import 'render_text_walker.dart';

/// The highlight geometry to paint for one [FindMatch]: either word-level
/// boxes around each occurrence of the query, or a single whole-node box when
/// word-level geometry could not be resolved.
///
/// Produced by [resolveWordHighlights] — see that function's doc for when
/// each case applies.
@immutable
class MatchHighlight {
  /// The rectangles to paint for this match, in global (screen-origin)
  /// coordinates — the same space as [FindMatch.globalRect].
  ///
  /// One or more per occurrence when [isWordLevel] is `true` (a wrapped word
  /// spans more than one box), or exactly one (the match's own
  /// [FindMatch.globalRect]) when `false`.
  final List<Rect> rects;

  /// Whether [rects] are word-level (tight around the matched text) or a
  /// fallback whole-node box.
  ///
  /// Callers do not currently need to render the two cases differently — the
  /// same fill/stroke applies either way — but this is kept so a future
  /// caller (or a test asserting the resolver actually achieved word-level
  /// geometry rather than merely falling back and happening to look similar)
  /// can tell them apart without comparing [rects] against
  /// [FindMatch.globalRect] itself.
  final bool isWordLevel;

  /// Creates a [MatchHighlight].
  const MatchHighlight({required this.rects, required this.isWordLevel});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MatchHighlight || other.isWordLevel != isWordLevel || other.rects.length != rects.length) {
      return false;
    }
    for (var i = 0; i < rects.length; i++) {
      if (other.rects[i] != rects[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(isWordLevel, Object.hashAll(rects));
}

/// Resolves the highlight geometry to paint for [match], given the query text
/// that produced it and every text-bearing render object currently in the
/// tree ([sources], as returned by `findRenderTextSources` in
/// `render_text_walker.dart`).
///
/// ### Word-level, when resolvable
/// When a [RenderTextSource] in [sources] plausibly backs [match] (see
/// `resolveRenderTextSource`'s doc for the containment test used), this finds
/// every occurrence of [query] within that source's own painted
/// [RenderTextSource.plainText] — **not** [FindMatch.label] (the semantics
/// haystack), since the two can differ (a [Text.semanticsLabel] override, or
/// how [RichText] joins its spans' accessibility labels, need not match what
/// was actually painted) — and asks the source for the on-screen box(es)
/// covering each occurrence via [RenderTextSource.boxesForSelection]. A word
/// that wraps across a line break comes back as more than one box; all of
/// them are included.
///
/// A source can paint the same text at more than one position in principle,
/// so occurrences are found independently within the resolved source's own
/// text, not by re-using [FindMatch.hits] (which were computed against the
/// semantics label and may not share the same offsets as the painted text
/// even when the visible characters happen to read the same).
///
/// ### Fallback, when not
/// When no source in [sources] resolves against [match] — the match came
/// from a [CustomPaint]-drawn label wrapped in an explicit [Semantics] (this
/// example find-in-page spike's `find_spike_label_painter.dart` case (see
/// `example/lib/src/sections/find_in_page/`): no [RenderParagraph]/
/// [RenderEditable] backs it at all), or from a merged semantics blob whose
/// painted text genuinely doesn't contain [query] as an exact substring (a
/// case-folding or punctuation-joining difference between the label and the
/// painted text) — this returns [match]'s own whole-node
/// [FindMatch.globalRect] as the sole rect, exactly as the pre-word-level
/// highlighting behaved. A find-in-page overlay must always highlight
/// *something* for a reported match; falling back to the coarser box is
/// preferred over silently painting nothing.
MatchHighlight resolveWordHighlights({
  required FindMatch match,
  required String query,
  required List<RenderTextSource> sources,
  bool caseSensitive = false,
}) {
  final source = resolveRenderTextSource(match.globalRect, sources);
  if (source == null) {
    return MatchHighlight(rects: [match.globalRect], isWordLevel: false);
  }

  final needle = caseSensitive ? query : query.toLowerCase();
  final occurrences = findAllTextOccurrences(source.plainText, needle, caseSensitive: caseSensitive);
  if (occurrences.isEmpty) {
    // The resolved source's painted text doesn't actually contain the query
    // as a literal substring (see the fallback doc above) — the whole-node
    // box is the only geometry left that is still guaranteed accurate.
    return MatchHighlight(rects: [match.globalRect], isWordLevel: false);
  }

  final rects = <Rect>[
    for (final occurrence in occurrences)
      ...source.boxesForSelection(TextSelection(baseOffset: occurrence.start, extentOffset: occurrence.end)),
  ];

  if (rects.isEmpty) {
    // Occurrences were found in the text but produced no boxes (e.g. a
    // whitespace-only query, already excluded upstream by `walkSemantics`'s
    // own empty/whitespace guard, but kept here as a defensive fallback
    // rather than painting nothing for a reported match).
    return MatchHighlight(rects: [match.globalRect], isWordLevel: false);
  }

  return MatchHighlight(rects: rects, isWordLevel: true);
}

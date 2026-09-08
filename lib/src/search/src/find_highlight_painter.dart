import 'package:flutter/widgets.dart';

import 'find_match.dart';
import 'word_highlight_resolver.dart';

/// The stroke width applied to every match's highlight definition outline, in
/// logical pixels.
///
/// A module-level constant (rather than a [FindHighlightPainter] field)
/// because the spike does not yet need callers to customize it — the
/// production widget may promote this to a constructor parameter once real
/// visual review happens.
const double kFindHighlightStrokeWidth = 2.0;

/// The corner radius applied to every match's highlight rectangle, in logical
/// pixels.
const double kFindHighlightCornerRadius = 3.0;

/// Paints a filled, rounded-rect highlight over every rect in every
/// [MatchHighlight] in [highlights], the way a browser's native Ctrl+F
/// renders its find results — each occurrence gets a solid highlight box
/// behind the matched text, with the entry at [currentIndex] painted in a
/// visually distinct color so a find-in-page overlay can show "you are here"
/// among possibly many results.
///
/// This is deliberately **token-free**: [currentColor] and [otherColor] are
/// resolved by the caller (typically via `context.tokens` plus the
/// `LayrzColors` palette) and passed in as plain [Color]s, so this painter has
/// no [BuildContext] dependency and can be unit-tested (or reused) without a
/// theme in scope.
///
/// Each [MatchHighlight] can carry more than one [MatchHighlight.rects] entry
/// — word-level geometry for a word that wraps across a line break resolves
/// to one box per visual line — and every one of them is painted, all in the
/// same color for that match, so a wrapped word still reads as a single
/// highlighted occurrence rather than two unrelated boxes.
///
/// This painter draws every entry in [highlights] unconditionally — it has no
/// opinion on [FindMatch.isHidden]. A hidden (scrolled-out-of-view) match's
/// rect can legitimately sit far outside the current viewport, so **the
/// caller is responsible for filtering matches down to only the
/// currently-visible ones** (`!match.isHidden`) before resolving and passing
/// [highlights] in — see `LayrzFindSpike._resolveHighlights` (via
/// `_visibleMatches`) in the example find-in-page spike
/// (`example/lib/src/sections/find_in_page/find_spike.dart`) for the
/// reference filtering. Drawing an off-screen rect
/// here would either be invisible (harmless) or, worse, land coincidentally
/// on top of unrelated on-screen content — so the filtering happens upstream
/// rather than being silently tolerated here.
///
/// The rects in [highlights] are **global** (screen) coordinates (see
/// `FindMatch.globalRect`/`MatchHighlight.rects`), so this painter must be
/// given a canvas whose local `(0, 0)` coincides with the true screen
/// origin — a page-level [Stack] is not necessarily that: a page can render
/// behind chrome (a sidebar, an app bar) that offsets its content area away
/// from the screen origin, which would silently shift every painted box by
/// exactly that offset. The reference wiring instead inserts this painter's
/// [CustomPaint] into the application's **root** [Overlay]
/// (`Overlay.of(context, rootOverlay: true)`), which is always anchored at
/// the screen origin regardless of what chrome the current page sits behind
/// — see `LayrzFindSpike` (the example find-in-page spike, in
/// `example/lib/src/sections/find_in_page/find_spike.dart`) for that
/// reference wiring.
class FindHighlightPainter extends CustomPainter {
  /// The resolved highlight geometry to paint — one [MatchHighlight] per
  /// currently-visible match, each carrying the rect(s) to fill.
  final List<MatchHighlight> highlights;

  /// The index into [highlights] that should be drawn as the "current"
  /// match — filled with [currentColor] instead of [otherColor].
  ///
  /// Out-of-range values (negative, or `>= highlights.length`) are treated as
  /// "no current match" — every entry is then painted with [otherColor]
  /// only. This makes it safe to pass a stale index for one frame (e.g. right
  /// after [highlights] shrinks) without an index-out-of-range failure.
  final int currentIndex;

  /// The fill color used for the current match's highlight
  /// (semi-transparent, so the underlying content stays legible beneath it).
  final Color currentColor;

  /// The fill color used for every non-current match's highlight
  /// (semi-transparent, so the underlying content stays legible beneath it).
  final Color otherColor;

  /// Creates a [FindHighlightPainter].
  FindHighlightPainter({
    required this.highlights,
    required this.currentIndex,
    required this.currentColor,
    required this.otherColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < highlights.length; i++) {
      final isCurrent = i == currentIndex;
      final color = isCurrent ? currentColor : otherColor;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      // A thin same-color stroke at a higher alpha than the fill gives each
      // box a defined edge, the way a browser's find highlight reads as a
      // solid block rather than a soft smudge — the fill remains the primary
      // visual, this is just definition.
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kFindHighlightStrokeWidth
        ..color = color.withValues(alpha: 1.0);

      for (final rect in highlights[i].rects) {
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(kFindHighlightCornerRadius));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FindHighlightPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.otherColor != otherColor ||
        !_highlightsEqual(oldDelegate.highlights, highlights);
  }

  /// Compares two highlight lists for equality by value, used by
  /// [shouldRepaint] to avoid repainting when an equivalent (but not
  /// `identical`) list is passed in — e.g. a rebuild that reconstructs the
  /// same highlights from an unchanged tree.
  static bool _highlightsEqual(List<MatchHighlight> a, List<MatchHighlight> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

import 'package:flutter/widgets.dart';

/// Escape hatch that makes custom-painted content findable by
/// [LayrzFindInPageHost]'s Ctrl/Cmd+F search, for content that has no
/// [RenderParagraph] or [RenderEditable] of its own — a chart axis label
/// drawn directly via [CustomPainter]/`TextPainter`, for instance.
///
/// `walkSemantics` (the mechanism behind [LayrzFindInPageHost]'s match
/// search — see `search/src/semantics_walker.dart`) finds matches by reading
/// each [SemanticsNode]'s own `label`/`value`, not by inspecting how a widget
/// paints. A plain [Text] or [RichText] gets that label automatically from
/// its own [InlineSpan] content, but a [CustomPaint]-drawn label — proven as
/// exactly this case by the DESIGN-109 spike's
/// `find_spike_label_painter.dart` (see
/// `example/lib/src/sections/find_in_page/`) — paints text the semantics
/// tree never learns about on its own, so it is invisible to a find query no
/// matter how legible it is on screen.
///
/// [LayrzSearchable] wraps [child] in an explicit [Semantics] node carrying
/// [text] as its `label`, with [child] itself wrapped in [ExcludeSemantics] —
/// so the walk sees exactly one node (this wrapper's own, labelled [text])
/// for the whole subtree, rather than whatever semantics [child] might
/// otherwise contribute (typically none, for a bare [CustomPaint], but this
/// keeps the contract exact regardless of what [child] turns out to be).
///
/// Because no [RenderParagraph]/[RenderEditable] backs this content,
/// `resolveWordHighlights` (`search/src/word_highlight_resolver.dart`) can
/// never resolve word-level geometry for a match found here — it falls back
/// to painting the match's whole-node box (this widget's own bounding rect)
/// instead, exactly the same fallback that function's doc describes for any
/// unresolvable match. A find highlight over [LayrzSearchable] content is
/// therefore always a single box around the whole widget, never
/// per-occurrence boxes around individual words within [text].
///
/// ### Usage
/// ```dart
/// LayrzSearchable(
///   text: 'Revenue by quarter',
///   child: CustomPaint(painter: MyChartAxisLabelPainter()),
/// )
/// ```
class LayrzSearchable extends StatelessWidget {
  /// The text a find query should be able to match against — typically the
  /// exact string [child] paints, though this widget has no way to verify
  /// that; a mismatch just means the query and the on-screen text disagree,
  /// the same class of mismatch `RenderTextSource.plainText`'s own doc
  /// describes for a [Text.semanticsLabel] override.
  final String text;

  /// The custom-painted (or otherwise semantics-invisible) content this
  /// widget makes findable. Wrapped in [ExcludeSemantics] so it never
  /// contributes semantics of its own alongside this wrapper's [text] label.
  final Widget child;

  /// Creates a [LayrzSearchable] wrapping [child], making it findable via
  /// [text].
  const LayrzSearchable({super.key, required this.text, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(child: child),
    );
  }
}

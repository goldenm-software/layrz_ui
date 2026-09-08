/// Find-in-page search tools — pure, framework-adjacent building blocks for
/// locating and highlighting text matches across the semantics and render
/// trees.
///
/// This module exports only the reusable TOOLS behind the DESIGN-109
/// find-in-page work: a semantics-tree walker, a render-tree walker, a
/// substring-occurrence finder, a word-level highlight resolver, a
/// [CustomPainter] for drawing the resolved highlights, and a conditional
/// browser-level Ctrl/Cmd+F key-capture selector. None of these render any UI
/// of their own — they are the mechanism a find-in-page widget composes, not
/// a widget itself.
///
/// The DESIGN-109 spike demo widgets (`LayrzFindSpike` and its supporting
/// demo-only widgets) are intentionally **not** exported here — they live in
/// the showcase app (`example/lib/src/sections/find_in_page/`), not in the
/// published library.
library;

export 'src/find_match.dart';
export 'src/find_text_occurrences.dart';
export 'src/semantics_walker.dart';
export 'src/render_text_walker.dart';
export 'src/word_highlight_resolver.dart';
export 'src/find_highlight_painter.dart';
export 'src/find_key_capture.dart';

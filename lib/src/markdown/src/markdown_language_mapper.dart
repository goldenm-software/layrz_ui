import 'package:layrz_ui/src/highlight/highlight.dart';

/// Maps a fenced code block's Markdown info string to a [LayrzCodeLanguage].
///
/// [info] is the text immediately following the opening fence markers (e.g.
/// the `python` in ` ```python `), or `null`/empty when the fence carries no
/// language hint. Matching is case-insensitive and trims surrounding
/// whitespace before comparing.
///
/// Recognized aliases:
/// - `python` or `py` → [LayrzCodeLanguage.python]
/// - `lcl` → [LayrzCodeLanguage.lcl]
/// - `lml` → [LayrzCodeLanguage.lml]
///
/// Every other value — including `null`, an empty string, or any language
/// this design system does not (yet) have a grammar for — maps to
/// [LayrzCodeLanguage.plain], so [LayrzMarkdown] can always render a fenced
/// block uniformly. This function never returns `null`.
LayrzCodeLanguage mapMarkdownLanguage(String? info) {
  final normalized = (info ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'python':
    case 'py':
      return LayrzCodeLanguage.python;
    case 'lcl':
      return LayrzCodeLanguage.lcl;
    case 'lml':
      return LayrzCodeLanguage.lml;
    default:
      return LayrzCodeLanguage.plain;
  }
}

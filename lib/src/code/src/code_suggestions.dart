import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

/// The identifier word immediately to the left of a caret, together with the
/// range it occupies, used to drive autocomplete in [LayrzCodeEditor].
///
/// [word] is the run of identifier characters (`[A-Za-z0-9_]`) ending at the
/// caret; [start] and [end] are its offsets in the source text (`end` is the
/// caret). An empty [word] means the caret is not sitting after an identifier
/// character, so no completion should be offered.
@immutable
class LayrzCaretWord {
  /// The identifier text ending at the caret (possibly empty).
  final String word;

  /// The inclusive start offset of [word] in the source text.
  final int start;

  /// The exclusive end offset of [word] — i.e. the caret position.
  final int end;

  /// Creates a [LayrzCaretWord].
  const LayrzCaretWord({required this.word, required this.start, required this.end});
}

/// Pure helpers backing [LayrzCodeEditor]'s autocomplete popup.
///
/// Kept free of widget state so the matching rules can be reasoned about (and
/// later unit-tested) in isolation from the editor's rendering.
abstract final class LayrzCodeSuggestions {
  /// The built-in completion symbols for [language].
  ///
  /// Python contributes its keywords and builtins; Layrz Compute Language its
  /// function names. Layrz Markup Language and plain text have none — LML is
  /// prose (its only completions are the caller-supplied `{{variable}}`
  /// names) and plain text carries no grammar to draw symbols from.
  static List<String> builtinsFor(LayrzCodeLanguage language) {
    switch (language) {
      case LayrzCodeLanguage.python:
        return const [...pythonKeywords, ...pythonBuiltins];
      case LayrzCodeLanguage.lcl:
        return lclFunctionNames;
      case LayrzCodeLanguage.lml:
      case LayrzCodeLanguage.plain:
        return const [];
    }
  }

  /// Extracts the identifier word ending at [caret] in [text].
  ///
  /// Walks left from [caret] over identifier characters; the returned
  /// [LayrzCaretWord] spans exactly those characters. When [caret] is out of
  /// range or does not follow an identifier character, the word is empty.
  static LayrzCaretWord caretWord(String text, int caret) {
    if (caret < 0 || caret > text.length) {
      return LayrzCaretWord(word: '', start: caret, end: caret);
    }
    var start = caret;
    while (start > 0 && _isIdentifierChar(text.codeUnitAt(start - 1))) {
      start--;
    }
    return LayrzCaretWord(word: text.substring(start, caret), start: start, end: caret);
  }

  /// Returns the completions offered for [prefix], drawn from [builtins] plus
  /// [extras], case-insensitively prefix-matched and de-duplicated.
  ///
  /// A one-character (or longer) [prefix] normally drives the popup; an empty
  /// prefix returns nothing so the popup never opens on a bare caret while the
  /// user types. Set [includeAllOnEmpty] `true` — used by the manual
  /// Ctrl/Cmd+Space trigger — to instead return the full de-duplicated list
  /// when [prefix] is empty. Matches preserve the order builtins-then-extras
  /// and drop any entry equal to the prefix itself (nothing to complete).
  /// Results are capped at [limit] to keep the popup bounded.
  static List<String> matches(
    String prefix, {
    required List<String> builtins,
    required List<String> extras,
    bool includeAllOnEmpty = false,
    int limit = 12,
  }) {
    if (prefix.isEmpty && !includeAllOnEmpty) {
      return const [];
    }
    final lower = prefix.toLowerCase();
    final seen = <String>{};
    final result = <String>[];
    for (final candidate in [...builtins, ...extras]) {
      if (prefix.isNotEmpty) {
        if (candidate.length <= prefix.length) {
          // Skip anything that can't extend the prefix (exact match included).
          continue;
        }
        if (!candidate.toLowerCase().startsWith(lower)) continue;
      }
      if (!seen.add(candidate)) continue;
      result.add(candidate);
      if (result.length >= limit) break;
    }
    return result;
  }

  static bool _isIdentifierChar(int codeUnit) {
    // A-Z, a-z, 0-9, underscore.
    return (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
        (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        codeUnit == 0x5F;
  }
}

/// The floating autocomplete list shown beneath the caret in [LayrzCodeEditor].
///
/// Renders [matches] as a compact, dark-surfaced menu using the code theme's
/// colors, with [selectedIndex] highlighted. Tapping an entry calls [onAccept]
/// with it. This widget is purely presentational — the editor owns the match
/// list, the selected index, keyboard navigation, and positioning.
class LayrzCodeSuggestionList extends StatelessWidget {
  /// The completion entries to display, already filtered and ordered.
  final List<String> matches;

  /// The index in [matches] currently highlighted (keyboard selection).
  final int selectedIndex;

  /// The code theme supplying the popup's surface and text colors.
  final LayrzCodeThemeExtension codeTheme;

  /// The font size used to render the entries, matching the code.
  final double fontSize;

  /// Called with the chosen entry when a row is tapped.
  final ValueChanged<String> onAccept;

  /// The maximum width of the popup, in logical pixels.
  final double maxWidth;

  /// Creates a [LayrzCodeSuggestionList].
  const LayrzCodeSuggestionList({
    super.key,
    required this.matches,
    required this.selectedIndex,
    required this.codeTheme,
    required this.fontSize,
    required this.onAccept,
    this.maxWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    const font = LayrzJetBrainsMonoFont();
    final textStyle = font.body.copyWith(fontSize: fontSize, color: codeTheme.foreground);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 6.5 * (fontSize + 12)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: codeTheme.gutterBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: codeTheme.foreground.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < matches.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onAccept(matches[i]),
                    child: ColoredBox(
                      color: i == selectedIndex ? codeTheme.currentLineBackground : const Color(0x00000000),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: fontSize * 0.25),
                        child: Text(matches[i], style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

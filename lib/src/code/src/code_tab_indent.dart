import 'package:flutter/widgets.dart';

/// Applies a Tab or Shift+Tab keystroke to [value], returning the resulting
/// [TextEditingValue].
///
/// Backs `LayrzCodeEditor.applyTabIndent` — split into its own file because it
/// is a pure, self-contained text transformation with no dependency on the
/// editor widget itself, and carries most of that widget's test coverage on
/// its own. It never touches a controller or widget state, so it can be
/// exhaustively unit-tested in isolation. It handles both directions:
///
/// - **Indent** (`outdent: false`): if the selection is collapsed, inserts
///   [tabSpaces] spaces (or a single `\t` when [useSpaces] is `false`) at the
///   caret and moves the caret past the inserted text. If the selection spans
///   one or more line breaks, every line touched by the selection is indented
///   at its start instead, and the selection is extended to keep covering the
///   same logical lines.
/// - **Outdent** (`outdent: true`): removes up to [tabSpaces] leading spaces
///   (or a single leading `\t`) from the start of every line touched by the
///   selection (or just the caret's line, for a collapsed selection). A line
///   with no leading whitespace to remove is left unchanged.
TextEditingValue applyTabIndent(
  TextEditingValue value, {
  required int tabSpaces,
  required bool useSpaces,
  required bool outdent,
}) {
  final text = value.text;
  final selection = value.selection;
  final start = selection.start < 0 ? 0 : selection.start;
  final end = selection.end < 0 ? 0 : selection.end;

  final indentUnit = useSpaces ? ' ' * tabSpaces : '\t';

  // A collapsed selection with no newline in play just inserts/removes at
  // the caret for `indent`, but still operates on the whole current line
  // for `outdent` (there is no meaningful "outdent the caret" operation).
  final touchesMultipleLines = text.substring(start, end).contains('\n');

  if (!outdent && selection.isCollapsed) {
    final newText = text.replaceRange(start, start, indentUnit);
    final caret = start + indentUnit.length;
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  if (!outdent && !touchesMultipleLines) {
    final newText = text.replaceRange(start, end, indentUnit);
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + indentUnit.length,
      ),
    );
  }

  // Multi-line indent, or any outdent: operate line-by-line over the range
  // of lines the selection touches. `String.lastIndexOf` requires its start
  // index to be >= 0, so the search is skipped outright (yielding -1, i.e.
  // "no earlier newline") when the caret is already at offset 0.
  final lineStart = (start > 0 ? text.lastIndexOf('\n', start - 1) : -1) + 1;
  var lineEndSearchFrom = end;
  if (end > 0 && end <= text.length && text.substring(0, end).endsWith('\n') && end > start) {
    // A selection ending exactly at a newline should not pull in the (empty)
    // following line.
    lineEndSearchFrom = end - 1;
  }
  var lineEnd = text.indexOf('\n', lineEndSearchFrom);
  if (lineEnd == -1) {
    lineEnd = text.length;
  }

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');

  var startDelta = 0;
  var totalDelta = 0;
  final newLines = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (outdent) {
      final removed = _leadingIndentLength(line, tabSpaces);
      newLines.add(line.substring(removed));
      totalDelta -= removed;
      if (i == 0) {
        startDelta -= removed;
      }
    } else {
      newLines.add(indentUnit + line);
      totalDelta += indentUnit.length;
      if (i == 0) {
        startDelta += indentUnit.length;
      }
    }
  }

  final newBlock = newLines.join('\n');
  final newText = text.replaceRange(lineStart, lineEnd, newBlock);

  final newStart = (start + startDelta).clamp(lineStart, newText.length);
  final newEnd = (end + totalDelta).clamp(lineStart, newText.length);

  return TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: newStart,
      extentOffset: newEnd,
    ),
  );
}

/// Returns the number of leading indent characters removable from [line], for
/// the outdent path of [applyTabIndent].
///
/// Removes up to [tabSpaces] leading space characters; if the line has no
/// leading spaces at all but starts with a single `\t`, that tab is removed
/// instead. A line with neither leading spaces nor a leading tab returns 0.
int _leadingIndentLength(String line, int tabSpaces) {
  if (line.startsWith('\t')) {
    return 1;
  }
  var count = 0;
  while (count < tabSpaces && count < line.length && line[count] == ' ') {
    count++;
  }
  return count;
}

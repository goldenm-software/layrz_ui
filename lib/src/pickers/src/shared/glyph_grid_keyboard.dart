import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The signature `LayrzGlyphGrid`'s injectable keyboard handler satisfies —
/// see `glyph_grid.dart`.
///
/// Distinct from the `DateTime`-typed `LayrzGridKeyboardHandler` in
/// `grid_keyboard_handler.dart`: that one navigates a 7-wide day grid or a
/// 3-wide month grid by calendar arithmetic (weeks, months, years), while
/// this one navigates an arbitrary flat item list by plain integer index —
/// see `grid_math.dart`'s doc comment for why the date grids' own
/// arithmetic is not reused here (it does not fit a non-`DateTime` glyph
/// list at all, not merely "differently").
///
/// Returns [KeyEventResult.handled] when [event] was consumed, otherwise
/// [KeyEventResult.ignored] so it falls through to Flutter's default focus
/// traversal (e.g. Tab/Shift+Tab). [focusedIndex] is the flat index (into
/// the caller's item list) currently focused. [requestFocus] lets the
/// handler move focus to a different index.
typedef LayrzGlyphGridKeyboardHandler = KeyEventResult Function(
  KeyEvent event,
  int focusedIndex,
  void Function(int index) requestFocus,
);

/// Builds a [LayrzGlyphGridKeyboardHandler] for `LayrzGlyphGrid` — arrow-key,
/// Home/End, and Enter/Space navigation over a flat item list rendered as an
/// [itemCount]-item grid with [columns] columns per row.
///
/// **Key bindings:**
/// - `ArrowLeft`/`ArrowRight` move focus by one item, clamped to
///   `[0, itemCount - 1]` (no wraparound at a row's own edge — moving left
///   from the first column of a row lands on the previous row's last
///   column, matching how the flat list is actually laid out).
/// - `ArrowUp`/`ArrowDown` move focus by one full row ([columns] items),
///   clamped to the valid index range. A move that would land past the
///   final item (the grid's last, ragged row) clamps to the last valid
///   index instead of no-op'ing, so `ArrowDown` from a cell above a short
///   last row still lands somewhere sensible.
/// - `Home`/`End` move to the first/last item of [focusedIndex]'s own row
///   — mirroring `buildDayGridKeyboardHandler`'s identical row-local
///   convention (see that function's doc for the rationale: a flat grid has
///   no single "whole list" that Home/End could mean without a row to
///   anchor it, only this one navigable per-row unit).
/// - `Enter`/`Space` invokes [onSelect] with the focused index. Never fires
///   for an index [isDisabled] reports as unselectable.
///
/// **Disabled items are skipped, not landed on inert** — mirroring
/// `buildDayGridKeyboardHandler`'s identical reasoning: stopping focus on
/// a dead cell forces a keyboard user to reverse out of it with no
/// feedback for why Enter did nothing, whereas skipping past disabled
/// items (bounded by [itemCount] itself, so this can never loop
/// unboundedly) reaches the next selectable item directly.
///
/// [columns] must be at least 1. [itemCount] is the total number of items
/// in the flat list (the grid's last row may be shorter than [columns] when
/// [itemCount] does not divide evenly).
///
/// [isDisabled] should report `true` for exactly the same set of indices the
/// grid itself renders as disabled — the caller building both the grid and
/// this handler is expected to pass the same predicate to both.
LayrzGlyphGridKeyboardHandler buildGlyphGridKeyboardHandler({
  required int columns,
  required int itemCount,
  required bool Function(int index) isDisabled,
  required ValueChanged<int> onSelect,
}) {
  assert(columns >= 1, 'columns must be at least 1, got $columns.');

  return (event, focusedIndex, requestFocus) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (itemCount == 0) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _step(focusedIndex, -1, itemCount, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _step(focusedIndex, 1, itemCount, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _step(focusedIndex, -columns, itemCount, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _step(focusedIndex, columns, itemCount, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _moveToRowEdge(focusedIndex, columns, itemCount, toStart: true, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _moveToRowEdge(focusedIndex, columns, itemCount, toStart: false, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
        if (!isDisabled(focusedIndex)) onSelect(focusedIndex);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  };
}

/// Steps [from] by [delta] positions, clamped to `[0, itemCount - 1]`, then
/// skips forward (in the direction of [delta]'s sign) past any index
/// [isDisabled] reports as unselectable, before calling [requestFocus] with
/// the first selectable candidate found (or the final clamped candidate
/// anyway, if every remaining index in that direction is disabled).
void _step(
  int from,
  int delta,
  int itemCount,
  bool Function(int) isDisabled,
  void Function(int) requestFocus,
) {
  var candidate = (from + delta).clamp(0, itemCount - 1);
  final step = delta.sign;
  while (isDisabled(candidate) && candidate + step >= 0 && candidate + step <= itemCount - 1) {
    candidate += step;
  }
  requestFocus(candidate);
}

/// Moves focus to the first or last item of [from]'s own row (a
/// [columns]-wide slice of the flat list), skipping disabled items inward
/// from that edge — so `Home` on a row whose first item is disabled lands
/// on the first selectable item instead of a dead one.
void _moveToRowEdge(
  int from,
  int columns,
  int itemCount,
  bool Function(int) isDisabled,
  void Function(int) requestFocus, {
  required bool toStart,
}) {
  final rowIndex = from ~/ columns;
  final rowStart = rowIndex * columns;
  final rowEnd = (rowStart + columns - 1).clamp(0, itemCount - 1);
  var candidate = toStart ? rowStart : rowEnd;
  final step = toStart ? 1 : -1;
  while (isDisabled(candidate) && candidate != (toStart ? rowEnd : rowStart)) {
    candidate += step;
  }
  requestFocus(candidate);
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'day_grid.dart' show LayrzGridFocusKey, LayrzGridKeyboardHandler;

/// Builds a [LayrzGridKeyboardHandler] for [LayrzPickersDayGrid] — arrow-key,
/// Home/End, PageUp/PageDown, and Enter/Space navigation over a 7-wide,
/// 6-row day grid.
///
/// **Key bindings:**
/// - `ArrowLeft`/`ArrowRight` move focus by one day.
/// - `ArrowUp`/`ArrowDown` move focus by one week (7 days).
/// - `Home`/`End` move to the first/last day of the **focused cell's own
///   displayed week row** — not the whole month — mirroring the row-local
///   convention native `<input type="date">` grid widgets and ARIA's
///   grid-navigation pattern both use, since a day grid has no single
///   "period" a lone Home/End could mean without a row to anchor it.
/// - `PageUp`/`PageDown` step the displayed month by one, via
///   [LayrzPickersDayGrid.onDisplayedMonthChanged], and land focus on the
///   same day-of-month in the new page's month via `requestFocus` (clamped
///   to that month's own last day when it's shorter, e.g. stepping from
///   Jan 31 to Feb lands on Feb 28/29).
/// - `Enter`/`Space` invokes [onSelect] with the focused date. Never fires
///   for a date [isDisabled] reports as unselectable.
///
/// **Disabled cells are skipped, not landed on inert.** Arrow/Home/End/
/// PageUp/PageDown movement keeps stepping past a date for which
/// [isDisabled] returns `true` until it finds a selectable one (bounded —
/// see [_kMaxSkipSteps]), rather than stopping focus on a dead cell a
/// keyboard user would then have to reverse out of with no feedback for why
/// Enter did nothing. This matches the convention native `<select>`
/// controls and ARIA menus use for disabled options, and is more usable
/// than landing on an inert cell — the tradeoff is that a keyboard user
/// might notice fewer of a page's disabled cells individually, which the
/// visible-but-greyed cell styling (see `LayrzPickersDayGridCell`'s own D15
/// note) already covers for a sighted user, and a screen-reader user gets
/// the "Unavailable" announcement on every cell it does land on regardless.
///
/// [isDisabled] should report `true` for exactly the same set of dates the
/// grid itself renders as disabled — the caller building both the grid and
/// this handler is expected to pass the same predicate to both, since
/// [LayrzPickersDayGrid] does not expose its own resolved disabled set for
/// this handler to read back.
///
/// [firstDayOfWeek] must match the value passed to the
/// [LayrzPickersDayGrid] this handler is attached to — see
/// [LayrzPickersDayGrid.firstDayOfWeek] — so `Home`/`End`'s row-edge
/// computation agrees with which column the grid itself renders as each
/// row's first/last cell. Defaults to [DateTime.monday], matching
/// [LayrzPickersDayGrid]'s own default.
LayrzGridKeyboardHandler buildDayGridKeyboardHandler({
  required bool Function(DateTime date) isDisabled,
  required ValueChanged<DateTime> onSelect,
  int firstDayOfWeek = DateTime.monday,
}) {
  return (event, focusedKey, requestFocus) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _stepDays(focusedKey, -1, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _stepDays(focusedKey, 1, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _stepDays(focusedKey, -7, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _stepDays(focusedKey, 7, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _moveToRowEdge(focusedKey, firstDayOfWeek, toStart: true, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _moveToRowEdge(focusedKey, firstDayOfWeek, toStart: false, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        _stepMonths(focusedKey, -1, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        _stepMonths(focusedKey, 1, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
        if (!isDisabled(focusedKey)) onSelect(focusedKey);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  };
}

/// Builds a [LayrzGridKeyboardHandler] for [LayrzPickersMonthGrid] — arrow-
/// key, Home/End, PageUp/PageDown, and Enter/Space navigation over a
/// 3-wide, 4-row month grid.
///
/// **Key bindings:**
/// - `ArrowLeft`/`ArrowRight` move focus by one month.
/// - `ArrowUp`/`ArrowDown` move focus by one row (3 months).
/// - `Home`/`End` move to the first/last month of the **focused cell's own
///   row** (January/March, April/June, …) — see [buildDayGridKeyboardHandler]
///   for why this row-local convention was chosen over "first/last month of
///   the year" for both grids alike.
/// - `PageUp`/`PageDown` step the displayed year by one, via
///   [LayrzPickersMonthGrid.onYearChanged] (already an existing field — no
///   grid change needed for the month grid, unlike the day grid), landing
///   focus on the same month-of-year in the new year.
/// - `Enter`/`Space` invokes [onSelect] with the focused month. Never fires
///   for a month [isDisabled] reports as unselectable.
///
/// **Disabled cells are skipped, not landed on inert** — see
/// [buildDayGridKeyboardHandler]'s doc for the identical reasoning, shared
/// verbatim between both grids.
///
/// [isDisabled] should report `true` for exactly the same set of months the
/// grid itself renders as disabled — see [buildDayGridKeyboardHandler]'s
/// identical caller-supplied-predicate note.
LayrzGridKeyboardHandler buildMonthGridKeyboardHandler({
  required bool Function(DateTime month) isDisabled,
  required ValueChanged<DateTime> onSelect,
  required ValueChanged<int> onYearChanged,
}) {
  return (event, focusedKey, requestFocus) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _stepMonthGridCells(focusedKey, -1, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _stepMonthGridCells(focusedKey, 1, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _stepMonthGridCells(focusedKey, -3, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _stepMonthGridCells(focusedKey, 3, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _moveToMonthRowEdge(focusedKey, toStart: true, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _moveToMonthRowEdge(focusedKey, toStart: false, isDisabled, requestFocus);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        onYearChanged(focusedKey.year - 1);
        requestFocus(DateTime(focusedKey.year - 1, focusedKey.month));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        onYearChanged(focusedKey.year + 1);
        requestFocus(DateTime(focusedKey.year + 1, focusedKey.month));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
        if (!isDisabled(focusedKey)) onSelect(focusedKey);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  };
}

/// Safety bound on how many consecutive disabled cells a single key press
/// will skip past before giving up and landing on the last candidate
/// anyway, so a pathological "everything disabled" configuration can never
/// hang a key event in an unbounded loop. 3660 covers a full decade of
/// disabled days in one `ArrowRight`/`ArrowLeft` sweep, which is already far
/// beyond any real picker configuration.
const int _kMaxSkipSteps = 3660;

/// Steps [from] by [days], skipping any date [isDisabled] reports as
/// unselectable, then calls [requestFocus] with the first selectable date
/// found (or, if every candidate within [_kMaxSkipSteps] is disabled, the
/// final candidate anyway — see [_kMaxSkipSteps]).
void _stepDays(
  LayrzGridFocusKey from,
  int days,
  bool Function(DateTime) isDisabled,
  void Function(LayrzGridFocusKey) requestFocus,
) {
  var candidate = from.add(Duration(days: days));
  var steps = 0;
  while (isDisabled(candidate) && steps < _kMaxSkipSteps) {
    candidate = candidate.add(Duration(days: days.sign));
    steps++;
  }
  requestFocus(candidate);
}

/// Moves focus to the start ([firstDayOfWeek]-relative first cell) or end
/// (last cell) of [from]'s own 7-day row, skipping disabled cells inward
/// from that edge — so `Home` on a row whose first cell is disabled lands
/// on the first selectable cell instead of a dead one.
void _moveToRowEdge(
  LayrzGridFocusKey from,
  int firstDayOfWeek,
  bool Function(DateTime) isDisabled,
  void Function(LayrzGridFocusKey) requestFocus, {
  required bool toStart,
}) {
  final offsetFromRowStart = (from.weekday - firstDayOfWeek) % 7;
  final rowStart = from.subtract(Duration(days: offsetFromRowStart));
  var candidate = toStart ? rowStart : rowStart.add(const Duration(days: 6));
  final step = toStart ? 1 : -1;
  var steps = 0;
  while (isDisabled(candidate) && steps < 7) {
    candidate = candidate.add(Duration(days: step));
    steps++;
  }
  requestFocus(candidate);
}

/// Steps the displayed month by [months] via
/// [LayrzPickersDayGrid.onDisplayedMonthChanged] (delivered through
/// [requestFocus] — see that field's doc on how a caller detects an
/// out-of-page target and routes it there), landing on the same
/// day-of-month clamped to the new month's own length.
void _stepMonths(LayrzGridFocusKey from, int months, void Function(LayrzGridFocusKey) requestFocus) {
  final targetMonth = DateTime(from.year, from.month + months);
  final daysInTargetMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final clampedDay = from.day.clamp(1, daysInTargetMonth);
  requestFocus(DateTime(targetMonth.year, targetMonth.month, clampedDay));
}

/// Steps [from] by [cells] positions in the month grid's row-major 3-column
/// layout, skipping disabled months, then calls [requestFocus].
void _stepMonthGridCells(
  LayrzGridFocusKey from,
  int cells,
  bool Function(DateTime) isDisabled,
  void Function(LayrzGridFocusKey) requestFocus,
) {
  var candidate = DateTime(from.year, from.month + cells);
  var steps = 0;
  while (isDisabled(candidate) && steps < _kMaxSkipSteps) {
    candidate = DateTime(candidate.year, candidate.month + cells.sign);
    steps++;
  }
  requestFocus(candidate);
}

/// Moves focus to the first or last month of [from]'s own 3-month row
/// (Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec), skipping disabled months inward
/// from that edge.
void _moveToMonthRowEdge(
  LayrzGridFocusKey from,
  bool Function(DateTime) isDisabled,
  void Function(LayrzGridFocusKey) requestFocus, {
  required bool toStart,
}) {
  final rowIndex = (from.month - 1) ~/ 3;
  final rowStartMonth = rowIndex * 3 + 1;
  var candidate = DateTime(from.year, toStart ? rowStartMonth : rowStartMonth + 2);
  final step = toStart ? 1 : -1;
  var steps = 0;
  while (isDisabled(candidate) && steps < 3) {
    candidate = DateTime(candidate.year, candidate.month + step);
    steps++;
  }
  requestFocus(candidate);
}

import 'package:flutter/foundation.dart';

import 'calendar_mode.dart';

/// A controller that drives the focused date and view mode of a
/// [LayrzCalendar].
///
/// **Architecture:** mirrors `LayrzStepperController` — the controller owns
/// the state, the calendar widget is a pure observer that subscribes via
/// [addListener] and reads [focusedDate]/[mode]. Multiple calendar surfaces
/// can share a single controller instance to stay in sync.
///
/// **Lifecycle and disposal:** disposal is caller-owned. If a
/// [LayrzCalendar]'s controller is supplied by the caller, the calendar does
/// **not** dispose it. If the calendar creates an internal controller (no
/// controller passed), the calendar disposes its own instance. See
/// `LayrzCalendar`'s constructor documentation for the exact contract, and
/// `LayrzStepperController` for the pattern this mirrors.
///
/// **Controller immutability guarantee:** an assertion fails if a different
/// controller instance is passed via `LayrzCalendar.controller` on a rebuild
/// of the same calendar widget. The instance must never be swapped mid
/// lifecycle.
///
/// This pass exposes navigation only — no selected-date concept exists here,
/// since [LayrzCalendar] remains display-only (no date selection, no return
/// value).
class LayrzCalendarController extends ChangeNotifier {
  /// Creates a [LayrzCalendarController].
  ///
  /// [initialDate] seeds [focusedDate]; when null, defaults to the current
  /// date at construction time. [initialMode] seeds [mode]; defaults to
  /// [LayrzCalendarMode.month], the only mode this pass renders.
  LayrzCalendarController({
    DateTime? initialDate,
    LayrzCalendarMode initialMode = LayrzCalendarMode.month,
  }) : _focusedDate = _dateOnly(initialDate ?? DateTime.now()),
       _mode = initialMode;

  /// The calendar date currently in view.
  ///
  /// For [LayrzCalendarMode.month], this is any date within the visible
  /// month — [LayrzCalendarMonthSurface] derives the grid from its
  /// year/month components only, ignoring the day. Always normalized to
  /// midnight (time-of-day components discarded) by every mutator on this
  /// controller.
  DateTime get focusedDate => _focusedDate;
  DateTime _focusedDate;

  /// The view mode currently selected.
  ///
  /// All three [LayrzCalendarMode] values render as of this pass; see
  /// [LayrzCalendarHeader] for how the active mode selects which of
  /// [nextMonth]/[nextWeek]/[nextDay] (and their `previous*` counterparts)
  /// the navigation buttons dispatch to.
  LayrzCalendarMode get mode => _mode;
  LayrzCalendarMode _mode;

  /// Moves [focusedDate] to the first day of the next month and notifies
  /// listeners.
  void nextMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    notifyListeners();
  }

  /// Moves [focusedDate] to the first day of the previous month and
  /// notifies listeners.
  void previousMonth() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    notifyListeners();
  }

  /// Moves [focusedDate] forward by exactly 7 calendar days and notifies
  /// listeners.
  ///
  /// Steps via the [DateTime] constructor's field-overflow normalization
  /// (`DateTime(y, m, day + 7)`), never `Duration(days: 7)` — `Duration`
  /// arithmetic is absolute elapsed time and silently lands on the wrong
  /// local day across a DST transition. See `LayrzCalendarMonthSurface` for
  /// the same rule applied to grid-start math.
  void nextWeek() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day + 7);
    notifyListeners();
  }

  /// Moves [focusedDate] back by exactly 7 calendar days and notifies
  /// listeners. See [nextWeek] for the DST-safe stepping rule this mirrors.
  void previousWeek() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day - 7);
    notifyListeners();
  }

  /// Moves [focusedDate] forward by exactly one calendar day and notifies
  /// listeners. See [nextWeek] for the DST-safe stepping rule this mirrors.
  void nextDay() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day + 1);
    notifyListeners();
  }

  /// Moves [focusedDate] back by exactly one calendar day and notifies
  /// listeners. See [nextWeek] for the DST-safe stepping rule this mirrors.
  void previousDay() {
    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day - 1);
    notifyListeners();
  }

  /// Sets [focusedDate] to today's date (time-of-day discarded) and
  /// notifies listeners.
  void goToToday() {
    _focusedDate = _dateOnly(DateTime.now());
    notifyListeners();
  }

  /// Sets [focusedDate] to [date] (time-of-day discarded) and notifies
  /// listeners.
  void goToDate(DateTime date) {
    _focusedDate = _dateOnly(date);
    notifyListeners();
  }

  /// Sets [mode] and notifies listeners.
  ///
  /// All three [LayrzCalendarMode] values are valid and render as of this
  /// pass, so this always succeeds.
  void setMode(LayrzCalendarMode newMode) {
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Disposes the controller and releases resources.
  ///
  /// Must be called exactly once, and only by whichever party owns the
  /// instance per this class's lifecycle contract.
  @override
  void dispose() {
    super.dispose();
  }
}

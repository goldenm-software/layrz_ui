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
/// since pass 1 is display-only (no date selection, no return value).
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
  /// Only [LayrzCalendarMode.month] renders content in this pass; setting
  /// [LayrzCalendarMode.week] or [LayrzCalendarMode.day] via [setMode] is
  /// still tracked here (so a caller's view-switcher chrome has somewhere to
  /// write), but [LayrzCalendar] itself throws when asked to render either.
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
  /// Setting a mode does not itself validate that the mode is implemented —
  /// [LayrzCalendar] is what throws for [LayrzCalendarMode.week] and
  /// [LayrzCalendarMode.day] when it next builds. Setting the mode here
  /// always succeeds so a view-switcher's own state stays consistent even
  /// before the calendar rebuilds.
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

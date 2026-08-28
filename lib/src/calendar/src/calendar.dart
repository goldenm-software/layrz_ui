import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/cards/cards.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'calendar_controller.dart';
import 'calendar_day_surface.dart';
import 'calendar_entry.dart';
import 'calendar_header.dart';
import 'calendar_mode.dart';
import 'calendar_month_surface.dart';
import 'calendar_time_format.dart';
import 'calendar_week_surface.dart';

/// A calendar surface with support for disabled dates, single- and
/// multi-day events, and switching between month, week and day views.
///
/// [LayrzCalendar] is a thin coordinator in the `LayrzStepper` template
/// sense: it owns the [LayrzCalendarController] lifecycle and delegates all
/// grid painting to a per-mode layout surface — [LayrzCalendarMonthSurface],
/// [LayrzCalendarWeekSurface], or [LayrzCalendarDaySurface] — the same shape
/// `LayrzTimeline` uses for its own two surfaces.
///
/// **This is display-and-navigate, plus a coordinate handed back on tap —
/// still not a selection surface.** [onTap] hands the caller a `DateTime`
/// when empty calendar space is tapped; this calendar does not remember it
/// as "the chosen one," has no return value of its own, and keeps no
/// selection state. Tapping an event entry instead fires that entry's own
/// [LayrzCalendarEntry.onTap] — there is no entry-tap callback on this
/// widget at all; see that field's doc for why the callback lives on the
/// entry rather than here. Two other targets navigate internally instead of
/// calling out: a month cell's day-of-month number (see
/// [dayNumberOpensDayView]), its overflow ("+N") chip (see
/// `LayrzCalendarDayCell`'s `onOverflowTap` doc), and the month grid's
/// week-number gutter (see [showWeekNumbers]) — the first two navigate
/// internally to day view for that date, the gutter to week view for that
/// week. None of that exposes anything new to a caller, since it only drives
/// this calendar's own controller, observable through the already-existing
/// [onModeChanged]. See `engineering/decisions.md`'s D72 for why this still
/// falls short of what a date picker needs (a persisted selection model and
/// a compact chrome-free grid), and is not meant to.
///
/// **All three [LayrzCalendarMode] values render.** `engineering/decisions.md`'s
/// D11 named four view modes (day, week, month, year) as part of its original
/// full-refactor scope review for this component; three of the four ship in
/// this pass. Year view remains unbuilt — this correction is documentation
/// only and is not licence for year-view work.
///
/// **Disabled dates are a distinct code path from "no events that day."** A
/// disabled date is purely visual (nothing is tappable on a disabled date
/// beyond the date number and the overflow chip, neither of which is
/// affected by disabled state) and never shares a render branch with an
/// empty day — see `LayrzCalendarDayCell`'s class doc.
///
/// **Lifecycle:** if [controller] is null, the calendar creates and disposes
/// its own; if non-null, the caller owns disposal and the instance must
/// never be swapped — enforced by an assertion in [didUpdateWidget],
/// mirroring `LayrzStepper`.
class LayrzCalendar extends StatefulWidget {
  /// Creates a [LayrzCalendar].
  const LayrzCalendar({
    this.controller,
    this.entries = const [],
    this.isDateDisabled,
    this.initialMode = LayrzCalendarMode.month,
    this.initialDate,
    this.firstDayOfWeek = DateTime.sunday,
    this.timeFormat = LayrzTimeFormat.h24,
    this.dayNumberOpensDayView = true,
    this.showWeekNumbers = true,
    this.onModeChanged,
    this.onTap,
    super.key,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7).',
       );

  /// Optional controller for programmatic navigation (change period, jump to
  /// today, switch mode).
  ///
  /// If null, the calendar creates, owns and disposes an internal
  /// controller. If non-null, the caller owns disposal and the instance must
  /// never be swapped; an assertion fails if a different controller is
  /// passed on a rebuild.
  final LayrzCalendarController? controller;

  /// The events to render across every visible day cell, day column, or hour
  /// grid, depending on the active mode.
  ///
  /// A [LayrzCalendarEntry] is placed wherever it
  /// [LayrzCalendarEntry.occupies], so a multi-day entry appears once per day
  /// it spans. Defaults to an empty, immutable list.
  final List<LayrzCalendarEntry> entries;

  /// Predicate deciding whether a given date is disabled.
  ///
  /// A predicate (rather than a `List<DateTime>`, a min/max range, or a
  /// `Set<DateTime>`) is the primitive this ships, because it is the only
  /// form that expresses an open-ended rule like "weekends" or "dates before
  /// today" without the caller precomputing a bounded collection. Null means
  /// no date is disabled.
  final bool Function(DateTime date)? isDateDisabled;

  /// The view mode used when [controller] is null and the calendar creates
  /// its own internal controller.
  ///
  /// Ignored when [controller] is non-null — the controller's own
  /// constructor argument governs the initial mode in that case. Defaults to
  /// [LayrzCalendarMode.month].
  final LayrzCalendarMode initialMode;

  /// The focused date used when [controller] is null and the calendar
  /// creates its own internal controller.
  ///
  /// Ignored when [controller] is non-null. Defaults to the current date
  /// when null.
  final DateTime? initialDate;

  /// The weekday the month grid's columns and the week view's day columns
  /// start from.
  ///
  /// One of `DateTime.monday` (1) through `DateTime.sunday` (7); asserted at
  /// construction. **Defaults to `DateTime.sunday`, which changes pass 1's
  /// shipped behaviour** — the month grid previously hardcoded a
  /// Monday-first layout. Pass `firstDayOfWeek: DateTime.monday` to restore
  /// the previous grid. Applies to both [LayrzCalendarMode.month] and
  /// [LayrzCalendarMode.week]; [LayrzCalendarMode.day] has no columns to
  /// order.
  final int firstDayOfWeek;

  /// The clock convention the week and day surfaces render hour-axis labels
  /// and timed-event times in.
  ///
  /// Defaults to [LayrzTimeFormat.h24]. Has no effect on
  /// [LayrzCalendarMode.month] — month cells render event titles only, never
  /// times.
  final LayrzTimeFormat timeFormat;

  /// Whether tapping a month cell's day-of-month number navigates to day
  /// view for that date.
  ///
  /// Defaults to `true`. When `false`, the date number renders fully inert —
  /// no hover state, no pointer cursor, no interactive semantics node —
  /// rather than merely suppressing the navigation behind a still-present
  /// hoverable region. Has no effect on the "+N" overflow chip, which always
  /// navigates to day view regardless of this flag. Has no effect outside
  /// [LayrzCalendarMode.month] — week and day views have no day-of-month
  /// number cell.
  final bool dayNumberOpensDayView;

  /// Whether a week-number gutter renders to the left of the month grid,
  /// showing each week row's ISO 8601 week number as a tap target that
  /// switches to week view focused on that week.
  ///
  /// Defaults to `true`. Has no effect outside [LayrzCalendarMode.month] —
  /// week view has only one row, so a week number there would label nothing
  /// to compare it against. See `LayrzCalendarWeekGutter`'s class doc for the
  /// numbering rule (each row is labeled with the ISO week of its own first
  /// day) and for why the gutter never affects the grid's own column
  /// geometry.
  final bool showWeekNumbers;

  /// Called with the newly selected mode whenever the header's view
  /// switcher changes it, or whenever a month cell's date number or overflow
  /// chip internally navigates to day view.
  ///
  /// This is a notification, not a gate — the controller's mode has already
  /// changed by the time this fires.
  final void Function(LayrzCalendarMode mode)? onModeChanged;

  /// Called when the calendar surface is tapped somewhere that is not an
  /// event entry, the day-of-month number, the "+N" overflow chip, or the
  /// week-number gutter.
  ///
  /// **This is the ONLY tap callback this widget carries.** Tapping an event
  /// entry never calls this — it fires that entry's own
  /// [LayrzCalendarEntry.onTap] instead, whose own doc explains why the
  /// callback lives on the entry rather than here. This fires only for a tap
  /// that lands on empty calendar surface: a month cell's body outside any
  /// event chip, or an hour-grid slot outside any timed block.
  ///
  /// The payload's precision depends on the active [LayrzCalendarMode]:
  /// [LayrzCalendarMode.month] reports the tapped date at midnight (hour,
  /// minute, second and millisecond all zero); [LayrzCalendarMode.week] and
  /// [LayrzCalendarMode.day] report the tapped date **and** time, snapped to
  /// the nearest 15-minute boundary at or before the tapped y-offset within
  /// its hour row, with seconds and milliseconds always zero.
  ///
  /// **The snap governs the returned value, not the hit target.** A whole
  /// hour row remains one tappable region — a 15-minute slice of it is not
  /// separately hit-tested — so a caller wiring "create an entry here" gets
  /// a value already rounded to a sensible granularity, rather than a raw
  /// pointer-position timestamp it would have to re-round itself.
  ///
  /// Null (the default) leaves every tappable surface exactly as
  /// display-only as it was before this parameter existed: no hover
  /// affordance, no pointer cursor, and no interactive semantics node on the
  /// surfaces this governs.
  final void Function(DateTime date)? onTap;

  @override
  State<LayrzCalendar> createState() => _LayrzCalendarState();
}

class _LayrzCalendarState extends State<LayrzCalendar> {
  late LayrzCalendarController _internalController;
  late LayrzCalendarController _effectiveController;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _internalController = LayrzCalendarController(
        initialDate: widget.initialDate,
        initialMode: widget.initialMode,
      );
      _effectiveController = _internalController;
    }

    _effectiveController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(LayrzCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    assert(
      widget.controller == oldWidget.controller,
      'LayrzCalendar does not support changing the controller instance. '
      'The same controller must be passed, or null must remain null.',
    );
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);

    // Caller-supplied controllers are caller-disposed; see field doc on
    // [LayrzCalendar.controller].
    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleModeChanged(LayrzCalendarMode mode) {
    _effectiveController.setMode(mode);
    widget.onModeChanged?.call(mode);
  }

  /// Handles a tap on a month cell's overflow ("+N") chip or its
  /// day-of-month number: jumps [_effectiveController] to [date] and
  /// switches to day view, mirroring [_handleModeChanged] so both paths fire
  /// [LayrzCalendar.onModeChanged] through the one notification path.
  ///
  /// Shared by both tap targets — they perform the identical navigation, and
  /// `LayrzCalendarMonthSurface`/`LayrzCalendarDayCell` gate whether either
  /// one is actually reachable (`onOverflowTap` non-null; `onDateNumberTap`
  /// non-null and [LayrzCalendar.dayNumberOpensDayView] `true`).
  void _handleDayCellNavigation(DateTime date) {
    _effectiveController.goToDate(date);
    _handleModeChanged(LayrzCalendarMode.day);
  }

  /// Handles a tap on the month grid's week-number gutter: jumps
  /// [_effectiveController] to [weekStart] and switches to week view,
  /// mirroring [_handleDayCellNavigation]'s day-view navigation so both paths
  /// fire [LayrzCalendar.onModeChanged] through the one notification path.
  void _handleWeekNumberTap(DateTime weekStart) {
    _effectiveController.goToDate(weekStart);
    _handleModeChanged(LayrzCalendarMode.week);
  }

  /// Forwards a month-view surface tap to [LayrzCalendar.onTap], normalizing
  /// [date] to midnight — hour, minute, second and millisecond all zero —
  /// per [LayrzCalendar.onTap]'s doc.
  void _handleMonthTap(DateTime date) {
    widget.onTap?.call(DateTime(date.year, date.month, date.day));
  }

  /// Returns the "previous period" callback for the currently active mode.
  VoidCallback get _onPrevious {
    switch (_effectiveController.mode) {
      case LayrzCalendarMode.month:
        return _effectiveController.previousMonth;
      case LayrzCalendarMode.week:
        return _effectiveController.previousWeek;
      case LayrzCalendarMode.day:
        return _effectiveController.previousDay;
    }
  }

  /// Returns the "next period" callback for the currently active mode.
  VoidCallback get _onNext {
    switch (_effectiveController.mode) {
      case LayrzCalendarMode.month:
        return _effectiveController.nextMonth;
      case LayrzCalendarMode.week:
        return _effectiveController.nextWeek;
      case LayrzCalendarMode.day:
        return _effectiveController.nextDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mode = _effectiveController.mode;

    // The whole rendered calendar is display surface, not copyable text --
    // one wrapper here covers every `Text` this widget and its surfaces
    // render, present and future, rather than each of the dozen call sites
    // wrapping itself. `SelectionContainer.disabled` resolves to a plain
    // `InheritedWidget` override (`updateShouldNotify` only) with no gesture
    // detector and no semantics node of its own, so it cannot interfere with
    // any interactive element beneath it -- see the class doc's "not a
    // selection surface" note for the unrelated sense of "selection" this
    // guards against (text selection, not day/event selection).
    return SelectionContainer.disabled(
      child: LayrzCard(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.sp2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayrzCalendarHeader(
                focusedDate: _effectiveController.focusedDate,
                mode: mode,
                onPrevious: _onPrevious,
                onNext: _onNext,
                onToday: _effectiveController.goToToday,
                onModeChanged: _handleModeChanged,
              ),
              SizedBox(height: tokens.spacing.sp2),
              Expanded(child: _buildSurface(mode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurface(LayrzCalendarMode mode) {
    switch (mode) {
      case LayrzCalendarMode.month:
        return LayrzCalendarMonthSurface(
          focusedDate: _effectiveController.focusedDate,
          entries: widget.entries,
          isDateDisabled: widget.isDateDisabled,
          firstDayOfWeek: widget.firstDayOfWeek,
          onOverflowTap: _handleDayCellNavigation,
          dayNumberOpensDayView: widget.dayNumberOpensDayView,
          onDateNumberTap: _handleDayCellNavigation,
          showWeekNumbers: widget.showWeekNumbers,
          onWeekNumberTap: _handleWeekNumberTap,
          onTap: widget.onTap == null ? null : _handleMonthTap,
        );
      case LayrzCalendarMode.week:
        return LayrzCalendarWeekSurface(
          focusedDate: _effectiveController.focusedDate,
          entries: widget.entries,
          isDateDisabled: widget.isDateDisabled,
          firstDayOfWeek: widget.firstDayOfWeek,
          timeFormat: widget.timeFormat,
          onTap: widget.onTap,
        );
      case LayrzCalendarMode.day:
        return LayrzCalendarDaySurface(
          focusedDate: _effectiveController.focusedDate,
          entries: widget.entries,
          isDateDisabled: widget.isDateDisabled,
          timeFormat: widget.timeFormat,
          onTap: widget.onTap,
        );
    }
  }
}

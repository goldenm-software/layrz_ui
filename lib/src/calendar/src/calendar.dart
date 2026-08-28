import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/cards/cards.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'calendar_controller.dart';
import 'calendar_entry.dart';
import 'calendar_header.dart';
import 'calendar_mode.dart';
import 'calendar_month_surface.dart';

/// A calendar surface with support for disabled dates, single- and
/// multi-day events, and switching between month, week and day views.
///
/// [LayrzCalendar] is a thin coordinator in the `LayrzStepper` template
/// sense: it owns the [LayrzCalendarController] lifecycle and delegates all
/// grid painting to a per-mode layout surface
/// ([LayrzCalendarMonthSurface] in this pass).
///
/// **This pass is display-and-navigate only.** There is no date selection,
/// no `onDaySelected` callback, and no return value — tapping a day does
/// nothing. Kenny's framing ("just a calendar") together with the
/// already-written `calendarPickMonth` l10n string (a *modal-trigger*
/// label, not a day-selection one) settle chrome interaction — navigating
/// months, switching views — as in scope, while day-level data interaction
/// is a different question left to a future date-picker input that wraps
/// this calendar. See the plan's §5.1 for the full reasoning.
///
/// **Only [LayrzCalendarMode.month] renders.** The enum ships with `week`
/// and `day` values so a caller's code compiles against the full pass-2
/// surface today, but selecting either mode makes [build] throw an
/// [UnimplementedError] rather than silently rendering an empty box — see
/// [mode]'s field doc.
///
/// **No year view.** The l10n namespace happens to carry
/// `calendarViewYear`/`calendarYearBack`/`calendarYearNext` strings, but
/// their existence is not a mandate — `engineering/decisions.md`'s D11 does
/// not discuss calendar view modes at all (re-verified against the plan).
/// Those strings are intentionally not wired here.
///
/// **Disabled dates are a distinct code path from "no events that day."** A
/// disabled date is purely visual in this pass (nothing is tappable yet, so
/// there is nothing to disable functionally) and never shares a render
/// branch with an empty day — see `LayrzCalendarDayCell`'s class doc.
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
    this.onModeChanged,
    super.key,
  });

  /// Optional controller for programmatic navigation (change month, jump to
  /// today, switch mode).
  ///
  /// If null, the calendar creates, owns and disposes an internal
  /// controller. If non-null, the caller owns disposal and the instance must
  /// never be swapped; an assertion fails if a different controller is
  /// passed on a rebuild.
  final LayrzCalendarController? controller;

  /// The events to render across every visible day cell.
  ///
  /// A [LayrzCalendarEntry] is placed in every day cell it
  /// [LayrzCalendarEntry.occupies], so a multi-day entry appears once per
  /// day it spans. Defaults to an empty, immutable list.
  final List<LayrzCalendarEntry> entries;

  /// Predicate deciding whether a given date is disabled.
  ///
  /// A predicate (rather than a `List<DateTime>`, a min/max range, or a
  /// `Set<DateTime>`) is the primitive this pass ships, because it is the
  /// only form that expresses an open-ended rule like "weekends" or "dates
  /// before today" without the caller precomputing a bounded collection. A
  /// set/range convenience may be layered on top of this in a later pass;
  /// this parameter itself is not expected to change shape. Null means no
  /// date is disabled.
  final bool Function(DateTime date)? isDateDisabled;

  /// The view mode used when [controller] is null and the calendar creates
  /// its own internal controller.
  ///
  /// Ignored when [controller] is non-null — the controller's own
  /// constructor argument governs the initial mode in that case. Defaults to
  /// [LayrzCalendarMode.month], the only mode this pass renders.
  final LayrzCalendarMode initialMode;

  /// The focused date used when [controller] is null and the calendar
  /// creates its own internal controller.
  ///
  /// Ignored when [controller] is non-null. Defaults to the current date
  /// when null.
  final DateTime? initialDate;

  /// Called with the newly selected mode whenever the header's view
  /// switcher changes it.
  ///
  /// This is a notification, not a gate — the controller's mode has already
  /// changed by the time this fires. Only [LayrzCalendarMode.month] can
  /// actually be selected in this pass (see the class doc), so in practice
  /// this never fires with any other value yet.
  final void Function(LayrzCalendarMode mode)? onModeChanged;

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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mode = _effectiveController.mode;

    return LayrzCard(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.sp2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayrzCalendarHeader(
              focusedDate: _effectiveController.focusedDate,
              mode: mode,
              onPrevious: _effectiveController.previousMonth,
              onNext: _effectiveController.nextMonth,
              onToday: _effectiveController.goToToday,
              onModeChanged: _handleModeChanged,
            ),
            SizedBox(height: tokens.spacing.sp2),
            Expanded(child: _buildSurface(mode)),
          ],
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
        );
      case LayrzCalendarMode.week:
        throw UnimplementedError(
          'LayrzCalendarMode.week is not implemented in this pass of LayrzCalendar.',
        );
      case LayrzCalendarMode.day:
        throw UnimplementedError(
          'LayrzCalendarMode.day is not implemented in this pass of LayrzCalendar.',
        );
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'day_grid_cell.dart';
import 'grid_math.dart';
import 'week_number_gutter.dart';
import 'weekday_header.dart';

/// The maximum width, in logical pixels, [LayrzPickersDayGrid] centres
/// itself within under a wide anchor.
///
/// Prevents a ~7-column day grid from stretching illegibly thin-and-wide
/// under [LayrzAnchoredPanelWidthPolicy.matchAnchor] on a very wide field —
/// see the implementation plan's Risk section, which cites
/// `LayrzDurationInput`'s `contentSized` rejection for the *inverse* failure
/// (too narrow) as the reason this grid must handle its own width instead of
/// assuming the panel already constrains it usefully.
const double kDayGridMaxWidth = 360.0;

/// A single key mapped to a cell's [FocusNode], used by [LayrzPickersDayGrid]
/// to build the grid's [FocusTraversalGroup] and by an injected
/// [LayrzGridKeyboardHandler] (see that typedef) to move focus between
/// cells.
typedef LayrzGridFocusKey = DateTime;

/// The signature `U10`'s keyboard-handler implementations satisfy.
///
/// [LayrzPickersDayGrid] and [LayrzPickersMonthGrid] own focus-traversal
/// *structure* (the [FocusTraversalGroup] and one [FocusNode] per cell) so
/// callers never re-wire keyboard behavior themselves, but delegate actual
/// key handling — arrow-key movement between cells, Enter/Space to select —
/// through this injectable seam rather than hardcoding it, so `U10` can land
/// its own `grid_keyboard_handler.dart` against this contract without
/// editing any file this unit owns.
///
/// Returns [KeyEventResult.handled] when [event] was consumed, otherwise
/// [KeyEventResult.ignored] so it falls through to Flutter's default focus
/// traversal. [focusedKey] is the grid value ([DateTime] for the day grid,
/// also [DateTime] — the first-of-month — for the month grid) currently
/// focused. [requestFocus] lets the handler move focus to a different cell
/// by key.
typedef LayrzGridKeyboardHandler = KeyEventResult Function(
  KeyEvent event,
  LayrzGridFocusKey focusedKey,
  void Function(LayrzGridFocusKey key) requestFocus,
);

/// A compact, purpose-built month-grid day picker surface.
///
/// **Built fresh per D72** — this widget does not import, wrap, subclass, or
/// extract from `lib/src/calendar/src/*`; `grid_math.dart`'s doc comment
/// records why the underlying arithmetic is deliberately re-derived rather
/// than shared.
///
/// Renders a Monday-first-by-default (see [firstDayOfWeek]) 6-row grid: a
/// [LayrzPickersWeekdayHeader], optionally a [LayrzPickersWeekNumberGutter],
/// and 42 [LayrzPickersDayGridCell]s spanning the leading/trailing edges of
/// adjacent months. Selection/today/range/disabled vocabulary is entirely
/// [LayrzPickersDayGridCell]'s — this widget only classifies each date into
/// a role and wires taps to [onDayTap].
///
/// **Own focus traversal.** Every cell gets its own [FocusNode], wrapped in
/// one [FocusTraversalGroup] for the whole grid, so a caller never has to
/// re-wire arrow-key or tab behavior. Actual key handling is delegated
/// through [keyboardHandler] — see [LayrzGridKeyboardHandler]'s doc for why
/// this is an injectable seam rather than hardcoded here.
///
/// **Stays legible under `matchAnchor` on a wide field** via the outer
/// [LayoutBuilder]: the grid centres itself and caps at [kDayGridMaxWidth]
/// rather than stretching its 7 columns across the full panel width.
class LayrzPickersDayGrid extends StatefulWidget {
  /// The month this grid page displays, as any [DateTime] within that month
  /// (only its year/month fields are read). Also supplies the [DateTime]
  /// subtype (plain or `TZDateTime`) every generated cell date is built in,
  /// via `sameZoneDate`.
  final DateTime displayedMonth;

  /// The currently selected single date, or `null`. Renders as
  /// [LayrzPickerCellRole.selected]. Mutually exclusive with [rangeStart]/
  /// [rangeEnd] — callers pass one or the other, never both.
  final DateTime? selectedDate;

  /// The start of a completed or in-progress contiguous range, or `null`.
  final DateTime? rangeStart;

  /// The end of a completed contiguous range, or `null`. `null` while the
  /// range is half-open (only [rangeStart] chosen).
  final DateTime? rangeEnd;

  /// Dates that render as [LayrzPickerCellRole.rangeInterior] and reject
  /// taps — supplied by the caller's range policy (`isRejected`) rather than
  /// recomputed here, so this widget stays a pure renderer of whatever
  /// selection state it is handed.
  final Set<DateTime> rejectedDates;

  /// The earliest selectable date, inclusive. `null` means no lower bound.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive. `null` means no upper bound.
  final DateTime? lastDay;

  /// Individually disabled dates, beyond the [firstDay]/[lastDay] bounds.
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week. Defaults to
  /// [DateTime.monday] — deliberately differing from `LayrzCalendar`'s
  /// `DateTime.sunday` default; see the implementation plan's Q16.
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders. Defaults to `true`; cut to
  /// a thin decorative strip below `isCompact` regardless of this value —
  /// see [LayrzPickersWeekNumberGutter]'s class doc.
  final bool showWeekNumbers;

  /// Called when a selectable day cell is tapped, with the tapped date.
  /// Never called for a disabled or rejected cell.
  final ValueChanged<DateTime> onDayTap;

  /// Optional keyboard-handling delegate — see [LayrzGridKeyboardHandler].
  /// `null` means only Flutter's default [FocusTraversalGroup] behavior
  /// (Tab/Shift+Tab) applies; arrow-key movement is a no-op until `U10`
  /// supplies a handler.
  final LayrzGridKeyboardHandler? keyboardHandler;

  /// Creates a new [LayrzPickersDayGrid].
  const LayrzPickersDayGrid({
    super.key,
    required this.displayedMonth,
    this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    this.rejectedDates = const {},
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    required this.onDayTap,
    this.keyboardHandler,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
       );

  @override
  State<LayrzPickersDayGrid> createState() => _LayrzPickersDayGridState();
}

class _LayrzPickersDayGridState extends State<LayrzPickersDayGrid> {
  final Map<DateTime, FocusNode> _focusNodes = {};

  FocusNode _focusNodeFor(DateTime date) => _focusNodes.putIfAbsent(date, () => FocusNode(debugLabel: '$date'));

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isDisabled(DateTime date) {
    if (widget.firstDay != null && date.isBefore(_dayOnly(widget.firstDay!))) return true;
    if (widget.lastDay != null && date.isAfter(_dayOnly(widget.lastDay!))) return true;
    return widget.disabledDays.any((d) => isSameDay(d, date));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  LayrzPickerCellRole _roleFor(DateTime date, DateTime today) {
    if (widget.rangeStart != null) {
      final start = widget.rangeStart!;
      final end = widget.rangeEnd;
      if (isSameDay(date, start) || (end != null && isSameDay(date, end))) {
        return LayrzPickerCellRole.rangeEndpoint;
      }
      if (end != null && date.isAfter(start) && date.isBefore(end)) {
        return LayrzPickerCellRole.rangeInterior;
      }
    }
    if (widget.selectedDate != null && isSameDay(date, widget.selectedDate!)) {
      return LayrzPickerCellRole.selected;
    }
    if (isSameDay(date, today)) {
      return LayrzPickerCellRole.today;
    }
    return LayrzPickerCellRole.none;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final today = DateTime.now();

    final gridDates = gridPageFor(
      reference: widget.displayedMonth,
      year: widget.displayedMonth.year,
      month: widget.displayedMonth.month,
      firstDayOfWeek: widget.firstDayOfWeek,
    );

    final rows = <List<DateTime>>[
      for (var r = 0; r < 6; r++) gridDates.sublist(r * 7, r * 7 + 7),
    ];
    final rowStartDates = [for (final row in rows) row.first];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, kDayGridMaxWidth)
            : kDayGridMaxWidth;
        final gutterWidth = widget.showWeekNumbers
            ? (context.isCompact ? kWeekNumberGutterCompactWidth : kWeekNumberGutterWidth)
            : 0.0;
        const rowHeight = 40.0;

        return Center(
          child: SizedBox(
            width: availableWidth,
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayrzPickersWeekdayHeader(firstDayOfWeek: widget.firstDayOfWeek, gutterWidth: gutterWidth),
                  SizedBox(height: tokens.spacing.sp1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayrzPickersWeekNumberGutter(
                        rowStartDates: rowStartDates,
                        rowHeight: rowHeight,
                        visible: widget.showWeekNumbers,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            for (final row in rows)
                              SizedBox(
                                height: rowHeight,
                                child: Row(
                                  children: [
                                    for (final date in row)
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final isAdjacent = !isInGridMonth(
                                              date,
                                              year: widget.displayedMonth.year,
                                              month: widget.displayedMonth.month,
                                            );
                                            final isDisabled = _isDisabled(date) || isAdjacent;
                                            final isRejected = widget.rejectedDates.any((d) => isSameDay(d, date));
                                            return Focus(
                                              onKeyEvent: widget.keyboardHandler == null
                                                  ? null
                                                  : (node, event) => widget.keyboardHandler!(
                                                      event,
                                                      date,
                                                      (key) => _focusNodeFor(key).requestFocus(),
                                                    ),
                                              child: LayrzPickersDayGridCell(
                                                label: '${date.day}',
                                                semanticLabel: _semanticDateLabel(date, l10n),
                                                role: _roleFor(date, today),
                                                isAdjacentPeriod: isAdjacent,
                                                isDisabled: isDisabled,
                                                isRejected: isRejected,
                                                onTap: (isDisabled || isRejected) ? null : () => widget.onDayTap(date),
                                                focusNode: _focusNodeFor(date),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Builds a full localized "Weekday, Month D, Year" screen-reader label for
/// [date], independent of the visible cell text (which is just the day
/// number).
String _semanticDateLabel(DateTime date, LayrzUiL10n l10n) {
  final monthName = _monthNameOf(date.month, l10n);
  final weekdayName = weekdayFullNameFor(date.weekday, l10n);
  return '$weekdayName, $monthName ${date.day}, ${date.year}';
}

String _monthNameOf(int month, LayrzUiL10n l10n) {
  switch (month) {
    case 1:
      return l10n.monthJanuary;
    case 2:
      return l10n.monthFebruary;
    case 3:
      return l10n.monthMarch;
    case 4:
      return l10n.monthApril;
    case 5:
      return l10n.monthMay;
    case 6:
      return l10n.monthJune;
    case 7:
      return l10n.monthJuly;
    case 8:
      return l10n.monthAugust;
    case 9:
      return l10n.monthSeptember;
    case 10:
      return l10n.monthOctober;
    case 11:
      return l10n.monthNovember;
    default:
      return l10n.monthDecember;
  }
}

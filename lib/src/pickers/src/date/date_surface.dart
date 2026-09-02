import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../shared/day_grid.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/grid_math.dart';

/// The desktop/mobile-shared surface content for [LayrzDateInput]: a month
/// navigation header above a single [LayrzPickersDayGrid] page. Composed by
/// [LayrzDateInput] inside either [LayrzAnchoredPanel] (desktop) or
/// [LayrzBottomSheet] (compact) — see that widget's own doc for the
/// surface-selection rule (D52/D70).
///
/// **Commit on tap.** [onDateSelected] fires once, with the tapped date, and
/// [LayrzDateInput] is responsible for closing whichever surface hosts this
/// widget immediately afterward — this widget itself has no notion of
/// "close". There is no Cancel/Save footer: single-valued widgets in this
/// batch commit on the one atomic tap.
///
/// **Owns its own month-navigation header.** Unlike
/// [LayrzPickersMonthGrid] — which renders its year-navigation chrome
/// inline because year-stepping is the whole of its own selection state —
/// [LayrzPickersDayGrid] renders only a single page and exposes no
/// navigation of its own; a caller supplies whichever month it wants
/// rendered. This widget is that caller: it owns [_displayedMonth] and
/// steps it with a `‹ "Month YYYY" › ` header built the same way
/// [LayrzPickersMonthGrid]'s year header is, reusing the existing
/// `calendarMonthBack`/`calendarMonthNext` l10n keys (already public,
/// already generic "previous/next month" navigation labels — reusing them
/// here needs no new l10n surface).
class LayrzDateSurface extends StatefulWidget {
  /// The currently selected date, or `null`.
  final DateTime? value;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which weekday starts each week. Defaults to [DateTime.monday].
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// Called with the tapped date. Never called for a disabled cell.
  final ValueChanged<DateTime> onDateSelected;

  /// Creates a new [LayrzDateSurface].
  const LayrzDateSurface({
    super.key,
    required this.value,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    required this.onDateSelected,
  });

  @override
  State<LayrzDateSurface> createState() => _LayrzDateSurfaceState();
}

class _LayrzDateSurfaceState extends State<LayrzDateSurface> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzDateSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Involuntary-close discipline: re-seed from `widget.value` on every
    // incoming update, not only in `initState` -- see the implementation
    // plan's "Involuntary close" section for why this is load-bearing.
    // `LayrzAnchoredPanel` constructs `child` eagerly and does not recreate
    // its `State` between an involuntary close and the next open, so this
    // re-seed is the only thing that discards a stale browsed-to month.
    if (oldWidget.value != widget.value) {
      _seed();
    }
  }

  void _seed() {
    _displayedMonth = widget.value ?? DateTime.now();
  }

  /// Steps [_displayedMonth] by [months], through [sameZoneDate] rather
  /// than [Duration] arithmetic so a `TZDateTime` value steps according to
  /// its own zone's calendar-field rules rather than absolute elapsed time
  /// — see `sameZoneDate`'s own doc for why `Duration` is unsafe here.
  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

  /// Whether [date] is unselectable — mirrors [LayrzPickersDayGrid]'s own
  /// internal `_isDisabled || isAdjacent` combination exactly (bounds,
  /// [disabledDays], and outside-the-displayed-month), so
  /// `buildDayGridKeyboardHandler`'s skip-disabled-cells and
  /// Enter/Space-never-selects-a-disabled-cell behavior agrees with what
  /// the grid itself would actually let a tap select. Duplicated rather
  /// than read back from the grid because [LayrzPickersDayGrid] does not
  /// expose its resolved disabled set — see `grid_keyboard_handler.dart`'s
  /// `isDisabled` parameter doc.
  bool _isDisabled(DateTime date) {
    if (!isInGridMonth(date, year: _displayedMonth.year, month: _displayedMonth.month)) return true;
    if (widget.firstDay != null && date.isBefore(_dayOnly(widget.firstDay!))) return true;
    if (widget.lastDay != null && date.isAfter(_dayOnly(widget.lastDay!))) return true;
    return widget.disabledDays.any((d) => isSameDay(d, date));
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Widget _buildHeader(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final label = formatStrftime(_displayedMonth, '%B %Y', l10n);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          button: true,
          label: l10n.calendarMonthBack,
          onTap: () => _stepMonth(-1),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => _stepMonth(-1),
              child: Icon(MdiIcons.chevronLeft, color: tokens.colors.fg2),
            ),
          ),
        ),
        Text(label, style: tokens.typography.title),
        Semantics(
          button: true,
          label: l10n.calendarMonthNext,
          onTap: () => _stepMonth(1),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => _stepMonth(1),
              child: Icon(MdiIcons.chevronRight, color: tokens.colors.fg2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: tokens.spacing.sp2),
          LayrzPickersDayGrid(
            displayedMonth: _displayedMonth,
            selectedDate: widget.value,
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            disabledDays: widget.disabledDays,
            firstDayOfWeek: widget.firstDayOfWeek,
            showWeekNumbers: widget.showWeekNumbers,
            onDayTap: widget.onDateSelected,
            keyboardHandler: buildDayGridKeyboardHandler(
              isDisabled: _isDisabled,
              onSelect: widget.onDateSelected,
              firstDayOfWeek: widget.firstDayOfWeek,
            ),
            onDisplayedMonthChanged: _stepMonth,
          ),
        ],
      ),
    );
  }
}

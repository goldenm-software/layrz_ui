import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../models/date_range.dart';
import '../shared/day_grid.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/grid_math.dart';
import '../shared/range_draft.dart';
import '../shared/range_policy.dart';

/// The surface content for [LayrzDateRangeInput]: a [LayrzPickersDayGrid]
/// plus a Cancel/Save/Reset footer, driven by [LayrzContiguousRangePolicy].
///
/// Implements the range selection state machine in full: empty -> anchor ->
/// complete (auto-swapped) -> endpoint re-tap adjusts that edge, other edge
/// fixed -> interior tap visibly rejected -> outside tap extends the nearer
/// endpoint. **The interior-lock model is retired and is not implemented.**
///
/// **Cancel/Save live inside this panel, visible from the first frame** —
/// `liliana`'s hard requirement that a range surface never leave the user
/// guessing whether a tap already counted. Reset is visible as soon as a
/// range exists.
///
/// **Involuntary close discards the draft**: [initState] and
/// [didUpdateWidget] both re-seed [_draft] from [widget.value], so a
/// dismissed panel never leaves stale in-progress state for the next open —
/// see the implementation plan's "Involuntary close" section, which cites
/// `LayrzAnchoredPanel`'s eager-child `State` reuse as the mechanism this
/// guards against.
///
/// **Owns its own month-navigation header**, exactly like [LayrzDateSurface]
/// — this widget renders only a single page and exposes no navigation of its
/// own, so this surface steps [_displayedMonth] itself with a
/// `‹ "Month YYYY" › ` header, reusing the existing `calendarMonthBack`/
/// `calendarMonthNext` l10n keys.
class LayrzDateRangeSurface extends StatefulWidget {
  /// The currently committed range, or `null`.
  final LayrzDateRange? value;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which weekday starts each week.
  final int firstDayOfWeek;

  /// Whether the ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// Called with the saved range when the user presses Save.
  final ValueChanged<LayrzDateRange> onSave;

  /// Called when the user presses Cancel or otherwise dismisses the panel
  /// involuntarily. The caller is responsible for actually closing the
  /// hosting surface; this widget only reports the intent.
  final VoidCallback onCancel;

  /// Creates a new [LayrzDateRangeSurface].
  const LayrzDateRangeSurface({
    super.key,
    required this.value,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<LayrzDateRangeSurface> createState() => _LayrzDateRangeSurfaceState();
}

class _LayrzDateRangeSurfaceState extends State<LayrzDateRangeSurface> {
  late LayrzRangeDraft<DateTime> _draft;
  late DateTime _displayedMonth;
  final _policy = LayrzContiguousRangePolicy<DateTime>(compare: (a, b) => _dayOnly(a).compareTo(_dayOnly(b)));

  /// Truncates [d] to calendar-day granularity (year/month/day, time zeroed)
  /// while preserving [d]'s own [DateTime] subtype and zone, via
  /// [sameZoneDate] (the S5 exception to D72) rather than the plain
  /// `DateTime(d.year, d.month, d.day)` constructor the scaffold used —
  /// which always returns a **local** `DateTime` and silently drops a
  /// `TZDateTime` argument's zone. `sameZoneDate(d, d.year, d.month, d.day)`
  /// builds the truncated date through `d`'s own constructor instead, so a
  /// `TZDateTime` endpoint stays a `TZDateTime` in the same [Location]
  /// through every draft mutation and the final saved [LayrzDateRange].
  static DateTime _dayOnly(DateTime d) => sameZoneDate(d, d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzDateRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _seed();
  }

  void _seed() {
    final value = widget.value;
    _draft = value == null
        ? const LayrzRangeDraft<DateTime>.empty()
        : LayrzRangeDraft<DateTime>.complete(anchor: _dayOnly(value.start), end: _dayOnly(value.end));
    _displayedMonth = value?.start ?? DateTime.now();
  }

  /// Steps [_displayedMonth] by [months], through [sameZoneDate] rather
  /// than [Duration] arithmetic so a `TZDateTime` value steps according to
  /// its own zone's calendar-field rules rather than absolute elapsed time
  /// — mirrors [LayrzDateInput]'s surface exactly; see `sameZoneDate`'s own
  /// doc for why [Duration] is unsafe here.
  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

  void _handleTap(DateTime tapped) {
    setState(() => _draft = _policy.onTap(_draft, _dayOnly(tapped)));
  }

  Set<DateTime> _rejectedDates(List<DateTime> visibleDates) => {
    for (final d in visibleDates)
      if (_policy.isRejected(_draft, _dayOnly(d))) d,
  };

  /// Whether [date] is unselectable — mirrors [LayrzPickersDayGrid]'s own
  /// internal `_isDisabled || isAdjacent` combination plus this surface's
  /// own range-interior rejection, so `buildDayGridKeyboardHandler`'s
  /// skip-disabled-cells and Enter/Space-never-selects behavior agrees with
  /// what the grid itself would actually let a tap select. See
  /// `LayrzDateSurface._isDisabled`'s identical doc for why this is
  /// duplicated rather than read back from the grid.
  bool _isDisabled(DateTime date) {
    if (!isInGridMonth(date, year: _displayedMonth.year, month: _displayedMonth.month)) return true;
    if (widget.firstDay != null && date.isBefore(_dayOnly(widget.firstDay!))) return true;
    if (widget.lastDay != null && date.isAfter(_dayOnly(widget.lastDay!))) return true;
    if (widget.disabledDays.any((d) => isSameDay(d, date))) return true;
    return _policy.isRejected(_draft, _dayOnly(date));
  }

  void _handleReset() => setState(() => _draft = const LayrzRangeDraft<DateTime>.empty());

  void _handleSave() {
    if (!_draft.isComplete) return;
    widget.onSave(LayrzDateRange(start: _draft.anchor as DateTime, end: _draft.end as DateTime));
  }

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
    final l10n = context.l10n;

    final visible = gridPageFor(
      reference: _displayedMonth,
      year: _displayedMonth.year,
      month: _displayedMonth.month,
      firstDayOfWeek: widget.firstDayOfWeek,
    );

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: tokens.spacing.sp2),
          LayrzPickersDayGrid(
            displayedMonth: _displayedMonth,
            rangeStart: _draft.anchor,
            rangeEnd: _draft.end,
            rejectedDates: _rejectedDates(visible),
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            disabledDays: widget.disabledDays,
            firstDayOfWeek: widget.firstDayOfWeek,
            showWeekNumbers: widget.showWeekNumbers,
            onDayTap: _handleTap,
            keyboardHandler: buildDayGridKeyboardHandler(
              isDisabled: _isDisabled,
              onSelect: _handleTap,
              firstDayOfWeek: widget.firstDayOfWeek,
            ),
            onDisplayedMonthChanged: _stepMonth,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              if (_draft.anchor != null)
                Expanded(
                  child: LayrzButton(
                    labelText: l10n.pickerRangeReset,
                    onTap: _handleReset,
                    type: LayrzButtonType.warning,
                  ),
                ),
              if (_draft.anchor != null) SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: LayrzButton.cancel(labelText: l10n.actionCancel, onTap: widget.onCancel),
              ),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: LayrzButton.save(
                  labelText: l10n.actionSave,
                  onTap: _handleSave,
                  isDisabled: !_draft.isComplete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

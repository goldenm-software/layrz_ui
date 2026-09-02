import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/calendar/calendar.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/formatting/formatting.dart';

import '../models/date_range.dart';
import '../models/time_of_day.dart';
import '../shared/day_grid.dart';
import '../shared/grid_keyboard_handler.dart';
import '../shared/grid_math.dart';
import '../shared/picker_inline_footer.dart';
import '../shared/range_draft.dart';
import '../shared/range_policy.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzDateTimeRangeInput]: the contiguous date
/// policy plus a time cluster per endpoint, with Cancel/Clear/Save inside
/// its hosting surface — per the maintainer's ruling for uniformity with the
/// other range widgets (recorded as R1 in the dossier: `simoncito` argued
/// for a dialog here, the maintainer ruled a shared container with Save for
/// consistency across the whole batch). **No dialog variant.**
///
/// **Hosted in [LayrzEndDrawer] on desktop as of DESIGN-98** (previously the
/// picker-private `LayrzPickerDrawer`, and before that [LayrzAnchoredPanel]).
/// On desktop, Cancel/Clear/Save are built by [LayrzDateTimeRangeInput] and
/// passed to [LayrzEndDrawer.show]'s `actions` parameter — see
/// [LayrzDateTimeRangeSurfaceState]'s class doc. Order and styling follow
/// `LayrzPickerDrawerFooter.build`'s own doc (DESIGN-46: Cancel, Clear, Save
/// — Clear only once a selection exists).
///
/// **No midnight default.** [_startTime]/[_endTime] seed from
/// [LayrzDateTimeRangeInput]'s own `startTime`/`endTime` when non-null and
/// stay genuinely `null` otherwise — never defaulted to `00:00`/`23:59`. Save
/// is disabled ([_canSave]) until the date range is complete **and both**
/// time parts have been actually chosen, mirroring [LayrzDateTimeSurface]'s
/// identical rule; see that class's doc for why a silent default is exactly
/// the problem the Save boundary exists to remove.
///
/// **Preserves `TZDateTime` zones**: date-only truncation goes through
/// [sameZoneDate] (the S5 exception to D72) rather than the plain
/// `DateTime(y, m, d)` constructor, which always returns a **local**
/// `DateTime` and would silently drop a `TZDateTime` endpoint's zone. The
/// final combine in [_handleSave] goes through [sameZoneDateTime] for the
/// same reason.
///
/// **Auto-swap covers the full datetime, not just the date.** Two taps that
/// land on the same calendar day still produce a valid, orderable pair once
/// their times are combined — see [_handleSave], which swaps the two
/// *combined* datetimes (not just the two time-of-day values) whenever the
/// resulting end precedes the resulting start. This subsumes the ordinary
/// date-only auto-swap the policy already performs on tap, and additionally
/// catches the same-day/reversed-time case the date policy alone cannot see.
///
/// **Involuntary close discards the draft**: [initState] and
/// [didUpdateWidget] both re-seed every draft field from [widget], so a
/// dismissed panel never leaves stale in-progress state for the next open.
///
/// **Owns its own month-navigation header**, exactly like
/// [LayrzDateRangeSurface] — this widget renders only a single page and
/// exposes no navigation of its own.
class LayrzDateTimeRangeSurface extends StatefulWidget {
  /// The currently committed date range, or `null`.
  final LayrzDateRange? value;

  /// The start endpoint's time-of-day, seeded independently of [value] so a
  /// caller-supplied [value] never silently discards a previously chosen
  /// time. `null` means genuinely unset — never defaulted to midnight.
  final LayrzTimeOfDay? startTime;

  /// The end endpoint's time-of-day. `null` means genuinely unset.
  final LayrzTimeOfDay? endTime;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Which [DateTime] weekday constant starts each week in the day grid.
  final int firstDayOfWeek;

  /// Whether the day grid's ISO week-number gutter renders.
  final bool showWeekNumbers;

  /// Whether the seconds fields are shown.
  final bool showSeconds;

  /// Whether the hour fields use 24-hour form.
  final bool use24HourFormat;

  /// Called with the saved, auto-swapped-if-needed (start, end) datetimes.
  final void Function(DateTime start, DateTime end) onSave;

  /// Called when the user presses Cancel.
  final VoidCallback onCancel;

  /// Called on every draft mutation (a day tap, a time field edit, or
  /// Clear), so [LayrzDateTimeRangeInput] can refresh the `actions` it
  /// builds outside this surface. Ignored when [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Clear/Save footer inline,
  /// as the last child of its scrolling body.
  ///
  /// Defaults to `true`, preserving the mobile [LayrzBottomSheet] path
  /// exactly as it behaved before DESIGN-98. Pass `false` when hosting this
  /// surface in [LayrzEndDrawer] — see [LayrzDateRangeSurface.showInlineFooter]'s
  /// identical doc for the full rationale.
  final bool showInlineFooter;

  /// Creates a new [LayrzDateTimeRangeSurface].
  const LayrzDateTimeRangeSurface({
    super.key,
    required this.value,
    required this.startTime,
    required this.endTime,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.firstDayOfWeek = DateTime.monday,
    this.showWeekNumbers = true,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onSave,
    required this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = true,
  });

  @override
  State<LayrzDateTimeRangeSurface> createState() => LayrzDateTimeRangeSurfaceState();
}

/// State for [LayrzDateTimeRangeSurface].
///
/// **Public, not library-private, so [LayrzDateTimeRangeInput] can reach it
/// through a [GlobalKey]** (DESIGN-98) — see [LayrzDateRangeSurfaceState]'s
/// identical class doc for the full rationale.

class LayrzDateTimeRangeSurfaceState extends State<LayrzDateTimeRangeSurface> {
  late LayrzRangeDraft<DateTime> _draft;
  late DateTime _displayedMonth;

  /// The start endpoint's time-of-day. `null` until the user edits the start
  /// fields — see the class doc's "No midnight default" note.
  LayrzTimeOfDay? _startTime;

  /// The end endpoint's time-of-day. `null` until the user edits the end
  /// fields.
  LayrzTimeOfDay? _endTime;

  final _policy = LayrzContiguousRangePolicy<DateTime>(compare: (a, b) => _dayOnly(a).compareTo(_dayOnly(b)));

  /// Truncates [d] to calendar-day granularity while preserving [d]'s own
  /// [DateTime] subtype and zone, via [sameZoneDate] (the S5 exception to
  /// D72) rather than the plain `DateTime(d.year, d.month, d.day)`
  /// constructor, which always returns a **local** `DateTime` and silently
  /// drops a `TZDateTime` argument's zone. `sameZoneDate(d, d.year, d.month,
  /// d.day)` builds the truncated date through `d`'s own constructor
  /// instead, so a `TZDateTime` endpoint stays a `TZDateTime` in the same
  /// [Location] through every draft mutation and the final saved value.
  static DateTime _dayOnly(DateTime d) => sameZoneDate(d, d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _seed();
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzDateTimeRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      _seed();
    }
  }

  void _seed() {
    final value = widget.value;
    _draft = value == null
        ? const LayrzRangeDraft<DateTime>.empty()
        : LayrzRangeDraft<DateTime>.complete(anchor: _dayOnly(value.start), end: _dayOnly(value.end));
    _displayedMonth = value?.start ?? DateTime.now();
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  /// Steps [_displayedMonth] by [months] through [sameZoneDate], mirroring
  /// [LayrzDateRangeSurface]'s identical stepping — see [sameZoneDate]'s own
  /// doc for why [Duration] arithmetic is unsafe here.
  void _stepMonth(int months) {
    setState(() {
      _displayedMonth = sameZoneDate(_displayedMonth, _displayedMonth.year, _displayedMonth.month + months);
    });
  }

  void _handleTap(DateTime tapped) {
    setState(() => _draft = _policy.onTap(_draft, _dayOnly(tapped)));
    widget.onDraftChanged?.call();
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

  /// Clears the in-progress draft back to empty. Invoked by
  /// [LayrzDateTimeRangeInput] through a [GlobalKey] when the Clear action
  /// it builds is pressed.
  void clear() {
    setState(() => _draft = const LayrzRangeDraft<DateTime>.empty());
    widget.onDraftChanged?.call();
  }

  /// Whether the draft is complete and Save is reachable. Read by
  /// [LayrzDateTimeRangeInput] through a [GlobalKey].
  bool get hasSelection => _draft.anchor != null;

  /// Whether Save is reachable: the date range must be complete **and both**
  /// time parts must have been genuinely chosen. Never `true` from a
  /// silently-substituted default — see the class doc's "No midnight
  /// default" note. Read by [LayrzDateTimeRangeInput] through a [GlobalKey].
  bool get canSave => _draft.isComplete && _startTime != null && _endTime != null;

  /// Commits the draft via [LayrzDateTimeRangeSurface.onSave]. Invoked by
  /// [LayrzDateTimeRangeInput] through a [GlobalKey] when the Save action it
  /// builds is pressed.
  void save() {
    final startDate = _draft.anchor;
    final endDate = _draft.end;
    final startTime = _startTime;
    final endTime = _endTime;
    if (startDate == null || endDate == null || startTime == null || endTime == null) return;

    var start = sameZoneDateTime(
      startDate,
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
      startTime.second,
    );
    var end = sameZoneDateTime(
      endDate,
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
      endTime.second,
    );

    // Auto-swap the full combined datetimes, not just the dates: the date
    // policy already guarantees startDate <= endDate, but two taps landing
    // on the same calendar day can still produce a reversed pair once their
    // times are combined (e.g. same day, end time chosen earlier than start
    // time) -- see the class doc's "Auto-swap covers the full datetime" note.
    if (end.isBefore(start)) {
      final swapped = start;
      start = end;
      end = swapped;
    }

    widget.onSave(start, end);
  }

  Widget _buildMonthHeader(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(context),
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
          Text(l10n.timePickerStart, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            // Genuinely unset until the user edits a field -- never
            // defaulted to midnight (see the class doc). The panel itself
            // requires a non-null `value` to render, so an unset draft is
            // shown as 00:00 without ever being *reported* as 00:00:
            // `onChanged` below is the only path that sets `_startTime`, and
            // it only runs when the user actually edits a field.
            value: _startTime ?? const LayrzTimeOfDay(hour: 0, minute: 0),
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (t) {
              setState(() => _startTime = t);
              widget.onDraftChanged?.call();
            },
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerEnd, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            value: _endTime ?? const LayrzTimeOfDay(hour: 0, minute: 0),
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (t) {
              setState(() => _endTime = t);
              widget.onDraftChanged?.call();
            },
          ),
          if (widget.showInlineFooter) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel,
              onClear: _draft.anchor != null ? clear : null,
              onSave: canSave ? save : null,
            ),
          ],
        ],
      ),
    );
  }
}

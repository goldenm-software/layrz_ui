import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/date_range.dart';
import '../models/time_of_day.dart';
import '../shared/day_grid.dart';
import '../shared/grid_math.dart';
import '../shared/range_draft.dart';
import '../shared/range_policy.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzDateTimeRangeInput]: the contiguous date
/// policy plus a time cluster per endpoint, with Cancel/Save inside the
/// panel — per the maintainer's ruling for uniformity with the other range
/// widgets (recorded as R1 in the dossier: `simoncito` argued for a dialog
/// here, the maintainer ruled anchored-panel-with-Save for consistency
/// across the whole batch). **No dialog variant.**
class LayrzDateTimeRangeSurface extends StatefulWidget {
  /// The currently committed range, or `null`.
  final LayrzDateRange? value;

  /// The start endpoint's time-of-day, seeded independently of [value]'s own
  /// time component so a caller-supplied [value] with a zeroed time-of-day
  /// does not silently discard a previously chosen time.
  final LayrzTimeOfDay? startTime;

  /// The end endpoint's time-of-day.
  final LayrzTimeOfDay? endTime;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Whether the seconds fields are shown.
  final bool showSeconds;

  /// Whether the hour fields use 24-hour form.
  final bool use24HourFormat;

  /// Called with the saved (start, end) datetimes.
  final void Function(DateTime start, DateTime end) onSave;

  /// Called when the user presses Cancel.
  final VoidCallback onCancel;

  /// Creates a new [LayrzDateTimeRangeSurface].
  const LayrzDateTimeRangeSurface({
    super.key,
    required this.value,
    required this.startTime,
    required this.endTime,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<LayrzDateTimeRangeSurface> createState() => _LayrzDateTimeRangeSurfaceState();
}

class _LayrzDateTimeRangeSurfaceState extends State<LayrzDateTimeRangeSurface> {
  late LayrzRangeDraft<DateTime> _draft;
  late DateTime _displayedMonth;
  late LayrzTimeOfDay _startTime;
  late LayrzTimeOfDay _endTime;
  final _policy = LayrzContiguousRangePolicy<DateTime>(compare: (a, b) => _dayOnly(a).compareTo(_dayOnly(b)));

  static const _defaultStart = LayrzTimeOfDay(hour: 0, minute: 0);
  static const _defaultEnd = LayrzTimeOfDay(hour: 23, minute: 59);

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _seed();
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
    _startTime = widget.startTime ?? _defaultStart;
    _endTime = widget.endTime ?? _defaultEnd;
  }

  void _handleTap(DateTime tapped) {
    setState(() => _draft = _policy.onTap(_draft, _dayOnly(tapped)));
  }

  Set<DateTime> _rejectedDates(List<DateTime> visibleDates) => {
    for (final d in visibleDates)
      if (_policy.isRejected(_draft, _dayOnly(d))) d,
  };

  void _handleReset() => setState(() => _draft = const LayrzRangeDraft<DateTime>.empty());

  void _handleSave() {
    if (!_draft.isComplete) return;
    final start = _draft.anchor as DateTime;
    final end = _draft.end as DateTime;
    widget.onSave(
      DateTime(start.year, start.month, start.day, _startTime.hour, _startTime.minute, _startTime.second),
      DateTime(end.year, end.month, end.day, _endTime.hour, _endTime.minute, _endTime.second),
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
      firstDayOfWeek: DateTime.monday,
    );

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayrzPickersDayGrid(
            displayedMonth: _displayedMonth,
            rangeStart: _draft.anchor,
            rangeEnd: _draft.end,
            rejectedDates: _rejectedDates(visible),
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            disabledDays: widget.disabledDays,
            onDayTap: _handleTap,
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerStart, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            value: _startTime,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (t) => setState(() => _startTime = t),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerEnd, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            value: _endTime,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (t) => setState(() => _endTime = t),
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
                child: LayrzButton.save(labelText: l10n.actionSave, onTap: _handleSave, isDisabled: !_draft.isComplete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

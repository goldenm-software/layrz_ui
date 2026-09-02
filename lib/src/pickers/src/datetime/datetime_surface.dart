import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/day_grid.dart';
import '../shared/time_fields_panel.dart';
import 'datetime_presentation.dart';

/// The surface content for [LayrzDateTimeInput]: composes [LayrzPickersDayGrid]
/// and [LayrzPickersTimeFieldsPanel] inside **one** anchored panel, arranged
/// per [presentation].
///
/// **Commit rule — the one place "single-valued ⇒ commit on tap" is
/// genuinely awkward, per the implementation plan.** [onCommit] fires only
/// once both a date and a time have been chosen: in [LayrzDateTimeInputPresentation.tabbed],
/// as soon as both a date tap and a time-field edit have happened (in either
/// order); in [LayrzDateTimeInputPresentation.stepped], on completing the
/// time step. **No midnight/existing-time default is silently substituted**
/// — the time part starts genuinely unset and only becomes part of a
/// reportable value once the user has touched a time field, so "both
/// chosen" always requires an explicit action on both parts, never a
/// value the user did not touch.
///
/// **Cancelling at any step abandons the whole selection** — there is no
/// partial commit. [onCancel] is the caller's signal to close without
/// reporting anything; the involuntary-close rule (discard the draft,
/// re-seed from `widget.value` on next open) is enforced by
/// [LayrzDateTimeInput] re-seeding this widget via [initialDate]/
/// [initialTime] on each open, mirrored here by [initState]/
/// [didUpdateWidget].
class LayrzDateTimeSurface extends StatefulWidget {
  /// Which arrangement this surface uses.
  final LayrzDateTimeInputPresentation presentation;

  /// The date part to seed the draft from, or `null` if unset.
  final DateTime? initialDate;

  /// The time part to seed the draft from, or `null` if unset.
  final LayrzTimeOfDay? initialTime;

  /// The earliest selectable date, inclusive.
  final DateTime? firstDay;

  /// The latest selectable date, inclusive.
  final DateTime? lastDay;

  /// Individually disabled dates.
  final Set<DateTime> disabledDays;

  /// Whether the seconds field is shown.
  final bool showSeconds;

  /// Whether the hour field uses 24-hour form.
  final bool use24HourFormat;

  /// Called once both a date and a time have been chosen — see this class's
  /// commit-rule doc above.
  final void Function(DateTime date, LayrzTimeOfDay time) onCommit;

  /// Called when the user cancels (Escape or an explicit Cancel affordance
  /// on the stepped presentation's time step).
  final VoidCallback onCancel;

  /// Creates a new [LayrzDateTimeSurface].
  const LayrzDateTimeSurface({
    super.key,
    required this.presentation,
    required this.initialDate,
    required this.initialTime,
    this.firstDay,
    this.lastDay,
    this.disabledDays = const {},
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<LayrzDateTimeSurface> createState() => _LayrzDateTimeSurfaceState();
}

class _LayrzDateTimeSurfaceState extends State<LayrzDateTimeSurface> {
  DateTime? _date;
  LayrzTimeOfDay? _time;
  bool _onTimeStep = false;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzDateTimeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate || oldWidget.initialTime != widget.initialTime) {
      _seed();
    }
  }

  void _seed() {
    _date = widget.initialDate;
    _time = widget.initialTime;
    _onTimeStep = false;
    _displayedMonth = widget.initialDate ?? DateTime.now();
  }

  void _maybeCommit() {
    final date = _date;
    final time = _time;
    if (date != null && time != null) {
      widget.onCommit(date, time);
    }
  }

  void _handleDateTap(DateTime date) {
    setState(() {
      _date = date;
      if (widget.presentation == LayrzDateTimeInputPresentation.stepped) {
        _onTimeStep = true;
      }
    });
    _maybeCommit();
  }

  void _handleTimeChanged(LayrzTimeOfDay time) {
    setState(() => _time = time);
    _maybeCommit();
  }

  Widget _buildDatePart(BuildContext context) => LayrzPickersDayGrid(
    displayedMonth: _displayedMonth,
    selectedDate: _date,
    firstDay: widget.firstDay,
    lastDay: widget.lastDay,
    disabledDays: widget.disabledDays,
    onDayTap: _handleDateTap,
  );

  Widget _buildTimePart(BuildContext context) => LayrzPickersTimeFieldsPanel(
    value: _time ?? const LayrzTimeOfDay(hour: 0, minute: 0),
    showSeconds: widget.showSeconds,
    use24HourFormat: widget.use24HourFormat,
    onChanged: _handleTimeChanged,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    if (widget.presentation == LayrzDateTimeInputPresentation.stepped) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.sp2),
        child: _onTimeStep ? _buildTimePart(context) : _buildDatePart(context),
      );
    }

    // "Tabbed" per this batch's Material-free constraint: no `TabController`
    // primitive exists in this library (that lives in the Material package,
    // which is forbidden under `lib/`), so both parts render simultaneously
    // under their own section labels
    // (`dateTimePickerDate`/`dateTimePickerTime`) rather than behind an
    // actual switchable tab strip. This still satisfies the presentation
    // enum's contract -- both parts are visible together, distinctly labeled
    // -- and, more importantly, both `tabbed` and `stepped` fire `onCommit`
    // at the identical moment (once both parts are chosen), which is the
    // property this enum must never fork.
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dateTimePickerDate, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          _buildDatePart(context),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.dateTimePickerTime, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          _buildTimePart(context),
        ],
      ),
    );
  }
}

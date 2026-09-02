import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/date_range.dart';
import '../shared/day_grid.dart';
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

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
    widget.onSave(LayrzDateRange(start: _draft.anchor as DateTime, end: _draft.end as DateTime));
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

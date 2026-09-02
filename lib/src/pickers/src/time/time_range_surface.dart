import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzTimeRangeInput]: two
/// [LayrzPickersTimeFieldsPanel] clusters (Start / End) plus a Cancel/Save
/// footer — **`LayrzTimeRangeInput` counts as a range and gets Save**, per
/// the implementation plan's explicit ruling.
///
/// Auto-swaps if the end draft precedes the start draft at Save time, rather
/// than rejecting — consistent with the contiguous range state machine's
/// "reverse-order selection auto-swaps, never rejects" rule.
class LayrzTimeRangeSurface extends StatefulWidget {
  /// The currently committed start time, or `null`.
  final LayrzTimeOfDay? startValue;

  /// The currently committed end time, or `null`.
  final LayrzTimeOfDay? endValue;

  /// Whether the seconds fields are shown.
  final bool showSeconds;

  /// Whether the hour fields use 24-hour form.
  final bool use24HourFormat;

  /// Called with the saved, auto-swapped-if-needed (start, end) pair.
  final void Function(LayrzTimeOfDay start, LayrzTimeOfDay end) onSave;

  /// Called when the user presses Cancel.
  final VoidCallback onCancel;

  /// Creates a new [LayrzTimeRangeSurface].
  const LayrzTimeRangeSurface({
    super.key,
    required this.startValue,
    required this.endValue,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<LayrzTimeRangeSurface> createState() => _LayrzTimeRangeSurfaceState();
}

class _LayrzTimeRangeSurfaceState extends State<LayrzTimeRangeSurface> {
  static const _defaultStart = LayrzTimeOfDay(hour: 9, minute: 0);
  static const _defaultEnd = LayrzTimeOfDay(hour: 17, minute: 0);

  late LayrzTimeOfDay _start;
  late LayrzTimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzTimeRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startValue != widget.startValue || oldWidget.endValue != widget.endValue) _seed();
  }

  void _seed() {
    _start = widget.startValue ?? _defaultStart;
    _end = widget.endValue ?? _defaultEnd;
  }

  void _handleSave() {
    final swapped = _start.compareTo(_end) > 0;
    widget.onSave(swapped ? _end : _start, swapped ? _start : _end);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.timePickerStart, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            value: _start,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) => setState(() => _start = time),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerEnd, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            value: _end,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) => setState(() => _end = time),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Row(
            children: [
              Expanded(
                child: LayrzButton.cancel(labelText: l10n.actionCancel, onTap: widget.onCancel),
              ),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: LayrzButton.save(labelText: l10n.actionSave, onTap: _handleSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/time_fields_panel.dart';
import '../shared/picker_drawer_footer.dart';

/// The surface content for [LayrzTimeRangeInput]: two
/// [LayrzPickersTimeFieldsPanel] clusters (Start / End) plus a Cancel/Save
/// footer — **`LayrzTimeRangeInput` counts as a range and gets Save**, per
/// the implementation plan's explicit ruling.
///
/// **Hosted in [LayrzPickerDrawer] on desktop as of DESIGN-49** (previously
/// [LayrzAnchoredPanel]); this widget's own content is unaffected by the
/// container change beyond the shared [LayrzPickerDrawerFooter] button order
/// (DESIGN-46: Cancel, then Save — no Clear affordance existed here before
/// or after, this cluster pair has nothing to reset to an empty state the
/// way a range grid does).
///
/// Auto-swaps if the end draft precedes the start draft at Save time, rather
/// than rejecting — consistent with the contiguous range state machine's
/// "reverse-order selection auto-swaps, never rejects" rule.
///
/// **No 9:00–17:00 default.** [_start]/[_end] seed from
/// [LayrzTimeRangeSurface.startValue]/[LayrzTimeRangeSurface.endValue] when
/// non-null and stay genuinely `null` otherwise — never defaulted to
/// business hours. Save is disabled ([_canSave]) until **both** clusters have
/// been actually edited, mirroring [LayrzDateTimeSurface]'s identical rule;
/// see that class's doc for why a silently-substituted default is exactly
/// the problem the Save boundary exists to remove.
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
  /// The start cluster's draft. `null` until the user actually edits the
  /// start fields — see the class doc's "No 9:00–17:00 default" note.
  LayrzTimeOfDay? _start;

  /// The end cluster's draft. `null` until the user actually edits the end
  /// fields.
  LayrzTimeOfDay? _end;

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
    _start = widget.startValue;
    _end = widget.endValue;
  }

  /// Whether Save is reachable: both clusters must have been genuinely
  /// chosen. Never `true` from a silently-substituted default — see the
  /// class doc's "No 9:00–17:00 default" note.
  bool get _canSave => _start != null && _end != null;

  void _handleSave() {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return;
    final swapped = start.compareTo(end) > 0;
    widget.onSave(swapped ? end : start, swapped ? start : end);
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
            // Genuinely unset until the user edits a field -- never
            // defaulted to 9:00 (see the class doc). The panel itself
            // requires a non-null `value` to render, so an unset draft is
            // shown as 00:00 without ever being *reported* as 00:00: the
            // `onChanged` callback below is the only path that sets
            // `_start`, and it only runs when the user actually edits a
            // field.
            value: _start ?? const LayrzTimeOfDay(hour: 0, minute: 0),
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) => setState(() => _start = time),
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerEnd, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            // See the start cluster's identical comment above.
            value: _end ?? const LayrzTimeOfDay(hour: 0, minute: 0),
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) => setState(() => _end = time),
          ),
          SizedBox(height: tokens.spacing.sp3),
          LayrzPickerDrawerFooter(
            onCancel: widget.onCancel,
            onSave: _canSave ? _handleSave : null,
          ),
        ],
      ),
    );
  }
}

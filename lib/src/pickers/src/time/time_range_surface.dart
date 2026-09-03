import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/time_of_day.dart';
import '../shared/picker_inline_footer.dart';
import '../shared/time_fields_panel.dart';

/// The surface content for [LayrzTimeRangeInput]: two
/// [LayrzPickersTimeFieldsPanel] clusters (Start / End) plus, on the mobile
/// bottom-sheet path, a Cancel/Save footer — **`LayrzTimeRangeInput` counts
/// as a range and gets Save**, per the implementation plan's explicit ruling.
///
/// **Hosted in [LayrzEndDrawer] on desktop as of DESIGN-98** (previously the
/// picker-private `LayrzPickerDrawer`, and before that [LayrzAnchoredPanel]).
/// On desktop, Cancel/Save are built by [LayrzTimeRangeInput] and passed to
/// [LayrzEndDrawer.show]'s `actions` parameter instead of composed inline —
/// see [LayrzTimeRangeSurfaceState]'s class doc. No Clear affordance existed
/// here before or after (DESIGN-46): this cluster pair has nothing to reset
/// to an empty state the way a range grid does.
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

  /// Called on every draft mutation (a start/end field edit), so
  /// [LayrzTimeRangeInput] can refresh the `actions` it builds outside this
  /// surface — see [LayrzTimeRangeSurfaceState]'s own doc for why the actions
  /// live outside rather than being composed into this widget's own build.
  /// Ignored when [showInlineFooter] is `true`.
  final VoidCallback? onDraftChanged;

  /// Whether this surface renders its own Cancel/Save footer inline, as the
  /// last child of its scrolling body.
  ///
  /// Defaults to `true`, preserving the mobile [LayrzBottomSheet] path
  /// exactly as it behaved before DESIGN-98. Pass `false` when hosting this
  /// surface in [LayrzEndDrawer] — see [LayrzDateRangeSurface.showInlineFooter]'s
  /// identical doc for the full rationale.
  final bool showInlineFooter;

  /// Creates a new [LayrzTimeRangeSurface].
  const LayrzTimeRangeSurface({
    super.key,
    required this.startValue,
    required this.endValue,
    this.showSeconds = false,
    this.use24HourFormat = true,
    required this.onSave,
    required this.onCancel,
    this.onDraftChanged,
    this.showInlineFooter = true,
  });

  @override
  State<LayrzTimeRangeSurface> createState() => LayrzTimeRangeSurfaceState();
}

/// State for [LayrzTimeRangeSurface].
///
/// **Public, not library-private, so [LayrzTimeRangeInput] can reach it
/// through a [GlobalKey]** (DESIGN-98) — see [LayrzDateRangeSurfaceState]'s
/// identical class doc for the full rationale, which applies here unchanged.
class LayrzTimeRangeSurfaceState extends State<LayrzTimeRangeSurface> {
  /// The start cluster's draft. `null` until the user actually edits the
  /// start fields — see the class doc's "No 9:00–17:00 default" note.
  late LayrzTimeOfDay _start;

  /// The end cluster's draft. `null` until the user actually edits the end
  /// fields.
  late LayrzTimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _seed();
    // Syncs the caller's external draft-state mirror immediately -- see
    // LayrzDateRangeSurfaceState's identical initState comment for why.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDraftChanged?.call());
  }

  @override
  void didUpdateWidget(LayrzTimeRangeSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startValue != widget.startValue || oldWidget.endValue != widget.endValue) _seed();
  }

  void _seed() {
    _start = widget.startValue ?? LayrzTimeOfDay(hour: 0, minute: 0, second: 0);
    _end = widget.endValue ?? LayrzTimeOfDay(hour: 0, minute: 0, second: 0);
  }

  /// Commits the draft via [LayrzTimeRangeSurface.onSave]. Invoked by
  /// [LayrzTimeRangeInput] through a [GlobalKey] when the Save action it
  /// builds is pressed.
  void save() {
    final start = _start;
    final end = _end;
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
            value: _start,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) {
              setState(() => _start = time);
              widget.onDraftChanged?.call();
            },
          ),
          SizedBox(height: tokens.spacing.sp3),
          Text(l10n.timePickerEnd, style: tokens.typography.label.copyWith(color: tokens.colors.fg2)),
          SizedBox(height: tokens.spacing.sp1),
          LayrzPickersTimeFieldsPanel(
            // See the start cluster's identical comment above.
            value: _end,
            showSeconds: widget.showSeconds,
            use24HourFormat: widget.use24HourFormat,
            onChanged: (time) {
              setState(() => _end = time);
              widget.onDraftChanged?.call();
            },
          ),
          if (widget.showInlineFooter) ...[
            SizedBox(height: tokens.spacing.sp3),
            LayrzPickerInlineFooter(
              onCancel: widget.onCancel,
              onSave: save,
            ),
          ],
        ],
      ),
    );
  }
}

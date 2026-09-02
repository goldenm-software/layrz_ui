import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../shared/day_grid.dart';

/// The desktop/mobile-shared surface content for [LayrzDateInput]: a single
/// [LayrzPickersDayGrid] page. Composed by [LayrzDateInput] inside either
/// [LayrzAnchoredPanel] (desktop) or [LayrzBottomSheet] (compact) — see that
/// widget's own doc for the surface-selection rule (D52/D70).
///
/// **Commit on tap.** [onDateSelected] fires once, with the tapped date, and
/// [LayrzDateInput] is responsible for closing whichever surface hosts this
/// widget immediately afterward — this widget itself has no notion of
/// "close". There is no Cancel/Save footer: single-valued widgets in this
/// batch commit on the one atomic tap.
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
    // plan's "Involuntary close" section for why this is load-bearing
    // (`LayrzAnchoredPanel` does not recreate this State per open).
    if (oldWidget.value != widget.value) {
      _seed();
    }
  }

  void _seed() {
    _displayedMonth = widget.value ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: LayrzPickersDayGrid(
        displayedMonth: _displayedMonth,
        selectedDate: widget.value,
        firstDay: widget.firstDay,
        lastDay: widget.lastDay,
        disabledDays: widget.disabledDays,
        firstDayOfWeek: widget.firstDayOfWeek,
        showWeekNumbers: widget.showWeekNumbers,
        onDayTap: widget.onDateSelected,
      ),
    );
  }
}

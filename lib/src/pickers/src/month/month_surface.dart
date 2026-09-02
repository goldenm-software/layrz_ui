import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/month.dart';
import '../shared/month_grid.dart';

/// The surface content for [LayrzMonthInput]: a single
/// [LayrzPickersMonthGrid] page with its own year-navigation state.
///
/// **Commit on tap, no Cancel/Save footer** — screenshot 2 (per the
/// implementation plan) reads as "the 4×3 grid" rather than "a dialog", so
/// its footer buttons are deliberately not reproduced here.
class LayrzMonthSurface extends StatefulWidget {
  /// The currently selected month, or `null`.
  final LayrzMonth? value;

  /// The earliest selectable month, inclusive.
  final LayrzMonth? minimum;

  /// The latest selectable month, inclusive.
  final LayrzMonth? maximum;

  /// Individually disabled months.
  final Set<LayrzMonth> disabledMonths;

  /// Called with the tapped month. Never called for a disabled cell.
  final ValueChanged<LayrzMonth> onMonthSelected;

  /// Creates a new [LayrzMonthSurface].
  const LayrzMonthSurface({
    super.key,
    required this.value,
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    required this.onMonthSelected,
  });

  @override
  State<LayrzMonthSurface> createState() => _LayrzMonthSurfaceState();
}

class _LayrzMonthSurfaceState extends State<LayrzMonthSurface> {
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(LayrzMonthSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _seed();
  }

  void _seed() {
    _displayedYear = widget.value?.year ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: LayrzPickersMonthGrid(
        displayedYear: _displayedYear,
        onYearChanged: (year) => setState(() => _displayedYear = year),
        reference: DateTime.now(),
        selectedMonth: widget.value?.toDateTime(),
        minimum: widget.minimum?.toDateTime(),
        maximum: widget.maximum?.toDateTime(),
        disabledMonths: widget.disabledMonths.map((m) => m.toDateTime()).toSet(),
        onMonthTap: (date) => widget.onMonthSelected(LayrzMonth.fromDateTime(date)),
      ),
    );
  }
}

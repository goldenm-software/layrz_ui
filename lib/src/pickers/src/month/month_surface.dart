import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import '../models/month.dart';
import '../shared/grid_keyboard_handler.dart';
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

  void _handleYearChanged(int year) => setState(() => _displayedYear = year);

  void _handleMonthTap(DateTime date) => widget.onMonthSelected(LayrzMonth.fromDateTime(date));

  /// Whether [month] is unselectable — mirrors [LayrzPickersMonthGrid]'s own
  /// internal `_isDisabled` exactly ([minimum]/[maximum] bounds plus
  /// [disabledMonths]), so `buildMonthGridKeyboardHandler`'s
  /// skip-disabled-cells and Enter/Space-never-selects-a-disabled-cell
  /// behavior agrees with what the grid itself would actually let a tap
  /// select. Duplicated rather than read back from the grid because
  /// [LayrzPickersMonthGrid] does not expose its resolved disabled set —
  /// see `grid_keyboard_handler.dart`'s `isDisabled` parameter doc.
  bool _isDisabled(DateTime month) {
    final minimum = widget.minimum?.toDateTime();
    final maximum = widget.maximum?.toDateTime();
    if (minimum != null && month.isBefore(DateTime(minimum.year, minimum.month))) return true;
    if (maximum != null && month.isAfter(DateTime(maximum.year, maximum.month))) return true;
    return widget.disabledMonths.any((m) => m.year == month.year && m.month == month.month);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: LayrzPickersMonthGrid(
        displayedYear: _displayedYear,
        onYearChanged: _handleYearChanged,
        reference: DateTime.now(),
        selectedMonth: widget.value?.toDateTime(),
        minimum: widget.minimum?.toDateTime(),
        maximum: widget.maximum?.toDateTime(),
        disabledMonths: widget.disabledMonths.map((m) => m.toDateTime()).toSet(),
        onMonthTap: _handleMonthTap,
        keyboardHandler: buildMonthGridKeyboardHandler(
          isDisabled: _isDisabled,
          onSelect: _handleMonthTap,
          onYearChanged: _handleYearChanged,
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import 'day_grid.dart' show LayrzGridKeyboardHandler, kDayGridMaxWidth;
import 'day_grid_cell.dart' show LayrzPickerCellRole;
import 'focus_ring.dart';
import 'grid_math.dart';
import 'month_grid_cell.dart';
import 'range_bar.dart';

/// A purpose-built month-selection grid with year navigation, laid out as
/// 3 rows of 4 columns (January–April on the top row, three rows deep).
///
/// **Built fresh per D72**, same as [LayrzPickersDayGrid] — no import of
/// `lib/src/calendar/src/*`. Renders all 12 full month names for
/// [displayedYear] (no abbreviation) plus a `‹ "Year YYYY" ›` header driven
/// by `monthPickerYear`/`monthPickerBack`/`monthPickerNext`.
///
/// Shares [LayrzPickersDayGridCell]'s selected/today/range/disabled
/// vocabulary via [LayrzPickersMonthGridCell] and the same
/// [LayrzGridKeyboardHandler] injectable keyboard seam as the day grid.
///
/// **Visible keyboard focus**, same as [LayrzPickersDayGrid]: each cell is
/// wrapped in a [LayrzFocusRing] listening to that cell's own [FocusNode],
/// so arrow-key navigation is visible (WCAG 2.4.7) and not merely
/// functional — see [LayrzFocusRing]'s own D15 compliance doc.
class LayrzPickersMonthGrid extends StatefulWidget {
  /// The year currently displayed.
  final int displayedYear;

  /// Called when the user navigates to the previous or next year.
  final ValueChanged<int> onYearChanged;

  /// The reference [DateTime] supplying the subtype (plain or `TZDateTime`)
  /// every generated month date is built in, via `sameZoneDate`.
  final DateTime reference;

  /// The currently selected single month, or `null`. Mutually exclusive with
  /// [rangeStart]/[rangeEnd].
  final DateTime? selectedMonth;

  /// The start of a completed or in-progress contiguous month range.
  final DateTime? rangeStart;

  /// The end of a completed contiguous month range.
  final DateTime? rangeEnd;

  /// Every month currently selected in arbitrary (non-contiguous) mode.
  final Set<DateTime> arbitrarySelection;

  /// Months that render as rejected (contiguous range interior).
  final Set<DateTime> rejectedMonths;

  /// The earliest selectable month, inclusive. `null` means no lower bound.
  final DateTime? minimum;

  /// The latest selectable month, inclusive. `null` means no upper bound.
  final DateTime? maximum;

  /// Individually disabled months.
  final Set<DateTime> disabledMonths;

  /// Called when a selectable month cell is tapped.
  final ValueChanged<DateTime> onMonthTap;

  /// Optional keyboard-handling delegate — see [LayrzGridKeyboardHandler].
  final LayrzGridKeyboardHandler? keyboardHandler;

  /// Creates a new [LayrzPickersMonthGrid].
  const LayrzPickersMonthGrid({
    super.key,
    required this.displayedYear,
    required this.onYearChanged,
    required this.reference,
    this.selectedMonth,
    this.rangeStart,
    this.rangeEnd,
    this.arbitrarySelection = const {},
    this.rejectedMonths = const {},
    this.minimum,
    this.maximum,
    this.disabledMonths = const {},
    required this.onMonthTap,
    this.keyboardHandler,
  });

  @override
  State<LayrzPickersMonthGrid> createState() => _LayrzPickersMonthGridState();
}

class _LayrzPickersMonthGridState extends State<LayrzPickersMonthGrid> {
  final Map<DateTime, FocusNode> _focusNodes = {};

  FocusNode _focusNodeFor(DateTime date) => _focusNodes.putIfAbsent(date, () => FocusNode(debugLabel: '$date'));

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isDisabled(DateTime month) {
    if (widget.minimum != null && month.isBefore(DateTime(widget.minimum!.year, widget.minimum!.month))) {
      return true;
    }
    if (widget.maximum != null && month.isAfter(DateTime(widget.maximum!.year, widget.maximum!.month))) {
      return true;
    }
    return widget.disabledMonths.any((m) => m.year == month.year && m.month == month.month);
  }

  LayrzPickerCellRole _roleFor(DateTime month, DateTime today) {
    if (widget.arbitrarySelection.any((m) => m.year == month.year && m.month == month.month)) {
      return LayrzPickerCellRole.selected;
    }
    if (widget.rangeStart != null) {
      final start = widget.rangeStart!;
      final end = widget.rangeEnd;
      final isStart = start.year == month.year && start.month == month.month;
      final isEnd = end != null && end.year == month.year && end.month == month.month;
      if (isStart || isEnd) return LayrzPickerCellRole.rangeEndpoint;
      if (end != null && month.isAfter(start) && month.isBefore(end)) {
        return LayrzPickerCellRole.rangeInterior;
      }
    }
    if (widget.selectedMonth != null &&
        widget.selectedMonth!.year == month.year &&
        widget.selectedMonth!.month == month.month) {
      return LayrzPickerCellRole.selected;
    }
    if (today.year == month.year && today.month == month.month) {
      return LayrzPickerCellRole.today;
    }
    return LayrzPickerCellRole.none;
  }

  /// Classifies [month] for [LayrzPickersRangeBar] — see
  /// `LayrzPickersDayGrid._rangeBarColumnFor`'s doc comment for the full
  /// reasoning, which applies identically here.
  ///
  /// **Arbitrary (non-consecutive) mode never reaches a non-[none] branch**:
  /// [widget.rangeStart] is only ever supplied by a consecutive-mode caller
  /// (`LayrzMonthRangeSurface` threads `rangeStart`/`rangeEnd` only when
  /// `consecutive: true`; arbitrary mode's selection lives in
  /// [widget.arbitrarySelection] instead, which this method never reads) —
  /// so arbitrary mode's `start == null` short-circuit above is what keeps
  /// its selected months as individual filled pills with no interior bar,
  /// satisfying Finding 2's "arbitrary month mode has no interior" carve-out
  /// without a separate `widget.consecutive` check here.
  LayrzRangeBarColumn _rangeBarColumnFor(DateTime month) {
    final start = widget.rangeStart;
    final end = widget.rangeEnd;
    if (start == null || end == null) return LayrzRangeBarColumn.none;
    final isStart = start.year == month.year && start.month == month.month;
    final isEnd = end.year == month.year && end.month == month.month;
    if (isStart && isEnd) return LayrzRangeBarColumn.rangeStartAndEnd;
    if (isStart) return LayrzRangeBarColumn.rangeStart;
    if (isEnd) return LayrzRangeBarColumn.rangeEnd;
    if (month.isAfter(start) && month.isBefore(end)) return LayrzRangeBarColumn.rangeInterior;
    return LayrzRangeBarColumn.none;
  }

  String _monthLabel(int month, LayrzUiL10n l10n) {
    const getters = <int, String Function(LayrzUiL10n)>{
      1: _jan,
      2: _feb,
      3: _mar,
      4: _apr,
      5: _may,
      6: _jun,
      7: _jul,
      8: _aug,
      9: _sep,
      10: _oct,
      11: _nov,
      12: _dec,
    };
    return getters[month]!(l10n);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final today = DateTime.now();

    final months = monthGridPageFor(reference: widget.reference, year: widget.displayedYear);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, kDayGridMaxWidth * 1.4)
            : kDayGridMaxWidth * 1.4;

        return Center(
          child: SizedBox(
            width: availableWidth,
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        button: true,
                        label: l10n.monthPickerBack,
                        onTap: () => widget.onYearChanged(widget.displayedYear - 1),
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            onTap: () => widget.onYearChanged(widget.displayedYear - 1),
                            child: Icon(MdiIcons.chevronLeft, color: tokens.colors.fg2),
                          ),
                        ),
                      ),
                      Text(l10n.monthPickerYear(widget.displayedYear), style: tokens.typography.title),
                      Semantics(
                        button: true,
                        label: l10n.monthPickerNext,
                        onTap: () => widget.onYearChanged(widget.displayedYear + 1),
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            onTap: () => widget.onYearChanged(widget.displayedYear + 1),
                            child: Icon(MdiIcons.chevronRight, color: tokens.colors.fg2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacing.sp2),
                  for (var row = 0; row < 3; row++)
                    // Stack, not a bare Row: the range bar paints as a
                    // background sibling *behind* this row's cells, per
                    // Finding 2 -- see `LayrzPickersRangeBar`'s own "Sizing"
                    // doc for why the Row of cells (not the bar) is the
                    // Stack's only non-positioned child. The Stack sizes to
                    // that Row's own intrinsic (pill) height, then
                    // Positioned.fill stretches the bar to match -- D15: the
                    // cell row's own geometry is completely unaffected by
                    // the bar's presence.
                    Stack(
                      children: [
                        Positioned.fill(
                          child: LayrzPickersRangeBar(
                            columns: [for (var col = 0; col < 4; col++) _rangeBarColumnFor(months[row * 4 + col])],
                          ),
                        ),
                        Row(
                          children: [
                            for (var col = 0; col < 4; col++)
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final month = months[row * 4 + col];
                                    final isDisabled = _isDisabled(month);
                                    final isRejected = widget.rejectedMonths.any(
                                      (m) => m.year == month.year && m.month == month.month,
                                    );
                                    return Focus(
                                      onKeyEvent: widget.keyboardHandler == null
                                          ? null
                                          : (node, event) => widget.keyboardHandler!(
                                              event,
                                              month,
                                              (key) => _focusNodeFor(key).requestFocus(),
                                            ),
                                      child: LayrzFocusRing(
                                        focusNode: _focusNodeFor(month),
                                        child: LayrzPickersMonthGridCell(
                                          label: _monthLabel(month.month, l10n),
                                          semanticLabel: '${_monthLabel(month.month, l10n)} ${month.year}',
                                          role: _roleFor(month, today),
                                          isDisabled: isDisabled,
                                          isRejected: isRejected,
                                          onTap: (isDisabled || isRejected) ? null : () => widget.onMonthTap(month),
                                          focusNode: _focusNodeFor(month),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _jan(LayrzUiL10n l10n) => l10n.monthJanuary;
String _feb(LayrzUiL10n l10n) => l10n.monthFebruary;
String _mar(LayrzUiL10n l10n) => l10n.monthMarch;
String _apr(LayrzUiL10n l10n) => l10n.monthApril;
String _may(LayrzUiL10n l10n) => l10n.monthMay;
String _jun(LayrzUiL10n l10n) => l10n.monthJune;
String _jul(LayrzUiL10n l10n) => l10n.monthJuly;
String _aug(LayrzUiL10n l10n) => l10n.monthAugust;
String _sep(LayrzUiL10n l10n) => l10n.monthSeptember;
String _oct(LayrzUiL10n l10n) => l10n.monthOctober;
String _nov(LayrzUiL10n l10n) => l10n.monthNovember;
String _dec(LayrzUiL10n l10n) => l10n.monthDecember;

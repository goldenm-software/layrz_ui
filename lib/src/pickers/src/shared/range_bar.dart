import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// One column's membership in a contiguous range, as painted by
/// [LayrzPickersRangeBar].
///
/// Distinct from [LayrzPickerCellRole][^1] (`day_grid_cell.dart`) — that
/// enum drives the individual cell's own foreground styling (fill, ring,
/// text colour); this one only tells the bar which columns to fill and
/// where its rounded caps belong. A cell can be [rangeStart]/[rangeEnd] and
/// simultaneously read as `today` in [LayrzPickerCellRole]'s vocabulary —
/// the two enums answer different questions about the same cell.
///
/// [^1]: See `day_grid_cell.dart`.
enum LayrzRangeBarColumn {
  /// Not part of the range at all — the bar paints nothing under this
  /// column.
  none,

  /// The range's true start — the bar's leading edge rounds off here,
  /// regardless of which column of the row this is.
  rangeStart,

  /// An interior column, between the true start and true end.
  rangeInterior,

  /// The range's true end — the bar's trailing edge rounds off here,
  /// regardless of which column of the row this is.
  rangeEnd,

  /// Both the true start and true end — a single-cell range, i.e.
  /// `rangeStart == rangeEnd`. The bar rounds off both edges under this one
  /// column.
  rangeStartAndEnd,
}

/// Paints a continuous, edge-to-edge background bar behind one row of a
/// [LayrzPickersDayGrid]/[LayrzPickersMonthGrid] page, so a contiguous
/// range reads as one unbroken line rather than a string of separate
/// tinted circles/pills.
///
/// **Finding 2's ruling, implemented literally**: a light primary bar
/// connects the range edge-to-edge across [columns], with **no gap**
/// between adjacent in-range columns. The bar is **square** where the
/// range continues past this row's own leading/trailing edge (i.e. the
/// range carries on into the previous/next grid row) and **rounded** only
/// at the range's true start/end column — see [LayrzRangeBarColumn].
///
/// **Never changes cell geometry (D15).** This widget paints a background
/// **behind** the row of cells it is composed with — see
/// [LayrzPickersDayGrid]/[LayrzPickersMonthGrid]'s own `build`, which
/// stacks this under the existing `Row` of cells rather than folding it
/// into any individual cell's own box. The row of cells above measures
/// identically whether or not a range is present.
///
/// Each column gets equal width, matching the `Expanded` cells it sits
/// behind — this widget assumes it is stacked under a `Row` of
/// [columns.length] equally-`Expanded` children and does not itself read
/// their actual rendered widths.
///
/// **Sizing**: always composed as the `Positioned.fill` layer of a `Stack`
/// whose other (non-positioned) child is the actual row of cells — see
/// [LayrzPickersDayGrid]/[LayrzPickersMonthGrid]'s own `build`. This widget
/// therefore never picks its own height: `Positioned.fill` stretches it to
/// whatever height the `Stack` already resolved from the cell row (fixed
/// `rowHeight` for the day grid; intrinsic pill height for the month
/// grid), via `CrossAxisAlignment.stretch` on its own root `Row` filling
/// that box vertically.
class LayrzPickersRangeBar extends StatelessWidget {
  /// This row's per-column range membership, one entry per grid column,
  /// left to right. Must be the same length as the row of cells this bar
  /// is stacked behind.
  final List<LayrzRangeBarColumn> columns;

  /// Creates a new [LayrzPickersRangeBar].
  const LayrzPickersRangeBar({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fillColor = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);
    // Matches the day cell's own 32.0-diameter circle -- see
    // `LayrzPickersDayGridCell`'s `LayrzTappable.borderRadius` doc comment
    // for why this is a literal geometric derivation (half the cell's own
    // fixed diameter), not a design-token pick: the bar's rounded cap must
    // trace the exact same curve the endpoint's own filled circle already
    // draws on top of it. In the month grid, whose pill cells are shorter
    // than 32.0 tall, [BorderRadius.circular] clamps down to half of
    // whichever box is actually smaller, so the cap still closes correctly.
    const capRadius = Radius.circular(16.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final column in columns)
          Expanded(
            child: switch (column) {
              LayrzRangeBarColumn.none => const SizedBox.shrink(),
              LayrzRangeBarColumn.rangeInterior => ColoredBox(color: fillColor),
              LayrzRangeBarColumn.rangeStart => DecoratedBox(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: const BorderRadius.only(topLeft: capRadius, bottomLeft: capRadius),
                ),
              ),
              LayrzRangeBarColumn.rangeEnd => DecoratedBox(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: const BorderRadius.only(topRight: capRadius, bottomRight: capRadius),
                ),
              ),
              LayrzRangeBarColumn.rangeStartAndEnd => DecoratedBox(
                decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.all(capRadius)),
              ),
            },
          ),
      ],
    );
  }
}

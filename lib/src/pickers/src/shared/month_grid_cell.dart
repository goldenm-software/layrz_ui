import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import 'day_grid_cell.dart' show LayrzPickerCellRole;

/// One cell of [LayrzPickersMonthGrid]: a full month name in the
/// 3-rows-by-4-columns month grid.
///
/// Shares [LayrzPickerCellRole]'s vocabulary with [LayrzPickersDayGridCell]
/// so both grids read consistently, but renders as a filled/outlined
/// **rounded rectangle** sized to its full month-name text rather than a
/// fixed-diameter circle — a circle sized for the widest month name
/// ("September") would look absurdly oversized for "May". **No
/// abbreviation**: an unrecognizable three-letter form is worse than a
/// cramped-but-readable full word, per the implementation plan.
class LayrzPickersMonthGridCell extends StatelessWidget {
  /// The full, localized month name rendered as this cell's label.
  final String label;

  /// Full localized description for screen readers (month + year).
  final String semanticLabel;

  /// This cell's role — see [LayrzPickerCellRole].
  final LayrzPickerCellRole role;

  /// Whether this cell is disabled — outside `minimum`/`maximum` bounds or
  /// in `disabledMonths`.
  final bool isDisabled;

  /// Whether this cell would currently reject a tap because it is a
  /// completed contiguous range's interior month.
  final bool isRejected;

  /// Called when this cell is tapped. `null` when [isDisabled] or
  /// [isRejected] is `true`.
  final VoidCallback? onTap;

  /// The [FocusNode] this cell attaches to the focus tree.
  final FocusNode focusNode;

  /// Creates a new [LayrzPickersMonthGridCell].
  const LayrzPickersMonthGridCell({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.role,
    this.isDisabled = false,
    this.isRejected = false,
    required this.onTap,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isInert = isDisabled || isRejected;

    var textColor = isDisabled ? tokens.colors.fg4 : tokens.colors.fg1;
    Color? fillColor;
    Border? border;

    switch (role) {
      case LayrzPickerCellRole.none:
        break;
      case LayrzPickerCellRole.selected:
      case LayrzPickerCellRole.rangeEndpoint:
        fillColor = tokens.colors.primary;
        textColor = tokens.colors.sf1;
      case LayrzPickerCellRole.today:
        border = Border.all(color: tokens.colors.primary, width: tokens.border.base);
      case LayrzPickerCellRole.rangeInterior:
        // No pill fill here in consecutive-range mode -- the continuous
        // range bar ([LayrzPickersMonthGrid]'s own per-row background,
        // painted behind this cell) already provides the interior's light
        // primary tint edge-to-edge across the row. Painting a second,
        // separately-shaped fill on top of it would double the tint and
        // reintroduce the "separate pills" look Finding 2 replaces. Text
        // stays at its ordinary (non-selected) color, set above. Arbitrary
        // (non-consecutive) mode never assigns this role -- see
        // `LayrzPickersMonthGrid._roleFor`'s `arbitrarySelection` branch,
        // which reads `selected` instead -- so arbitrary-mode months keep
        // their individual filled pills exactly as before.
        break;
    }

    // A rejected cell that is not itself a range-interior cell (defensive,
    // same reasoning as `LayrzPickersDayGridCell`) falls back to a light
    // primary tint. `primary.shade50` is not used here: see
    // `LayrzPickersDayGridCell.build`'s own doc comment on this exact
    // point -- [LayrzColorSwatch.fromColor] derives shade50 by subtracting
    // 0.40 from the seed's HSL lightness, which clamps to fully opaque
    // black for a dark seed (e.g. the default `kPrimaryColor`). Applying
    // [tokens.colors.tonalOpacity] alpha to the seed colour directly
    // sidesteps that defect entirely.
    if (isRejected && role != LayrzPickerCellRole.rangeInterior) {
      fillColor = tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity);
    }

    final semanticsExtras = StringBuffer(semanticLabel);
    if (role == LayrzPickerCellRole.today) semanticsExtras.write(', ${l10n.pickerTodayLabel}');
    if (role == LayrzPickerCellRole.selected || role == LayrzPickerCellRole.rangeEndpoint) {
      semanticsExtras.write(', ${l10n.pickerSelectedLabel}');
    }
    if (isRejected) semanticsExtras.write(', ${l10n.pickerRangeInteriorLabel}');
    if (isDisabled) semanticsExtras.write(', ${l10n.pickerDisabledLabel}');

    return Semantics(
      label: semanticsExtras.toString(),
      button: !isInert,
      enabled: !isInert,
      selected: role == LayrzPickerCellRole.selected || role == LayrzPickerCellRole.rangeEndpoint,
      onTap: isInert ? null : onTap,
      child: Focus(
        focusNode: focusNode,
        skipTraversal: isInert,
        child: ExcludeSemantics(
          child: Container(
            margin: EdgeInsets.all(tokens.spacing.sp1),
            // [LayrzTappable] paints its own hover/pressed surface via a
            // plain [DecoratedBox]/[AnimatedContainer] *underneath* [child]
            // -- `borderRadius: tokens.radius.br2` matches the same rounded
            // rectangle the fill itself paints below, so hover/press never
            // reads as a squared-off surface behind a rounded pill. Inert
            // cells (disabled/rejected) pass a `null` `onTap`, which routes
            // [LayrzTappable] through its own "inert path": a bare
            // [DecoratedBox] with no [MouseRegion]/[GestureDetector] at
            // all -- no hover tint, no pointer cursor. D15: only the
            // tappable's own colour/opacity vary by state; this outer
            // [Container]'s margin/size never changes.
            child: LayrzTappable(
              onTap: isInert ? null : onTap,
              // Same reasoning as LayrzPickersDayGridCell: a completed
              // range's endpoint month is re-tapped in quick succession to
              // pick it back up as the movable endpoint, which the default
              // double-tap cooldown would otherwise swallow on this cell.
              collapseDoubleTap: false,
              borderRadius: tokens.radius.br2,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fillColor,
                  border: border,
                  borderRadius: tokens.radius.br2,
                ),
                padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp2),
                child: Text(
                  label,
                  style: tokens.typography.body.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

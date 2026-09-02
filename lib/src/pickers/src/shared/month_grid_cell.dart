import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'day_grid_cell.dart' show LayrzPickerCellRole;

/// One cell of [LayrzPickersMonthGrid]: a full month name in a 4×3 grid.
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
        fillColor = tokens.colors.primary.shade50;
    }

    if (isRejected && role != LayrzPickerCellRole.rangeInterior) {
      fillColor = tokens.colors.primary.shade50;
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
      child: MouseRegion(
        cursor: isInert ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isInert ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: Focus(
            focusNode: focusNode,
            skipTraversal: isInert,
            child: ExcludeSemantics(
              child: Container(
                margin: EdgeInsets.all(tokens.spacing.sp1),
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

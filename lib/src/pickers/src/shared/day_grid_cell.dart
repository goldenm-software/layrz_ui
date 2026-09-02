import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// The visual/interaction role a single [LayrzPickersDayGridCell] plays
/// within its grid, driving which of the mutually-exclusive selected/today
/// readings (never both at once) and range treatments apply.
enum LayrzPickerCellRole {
  /// Not selected, not today, not part of any range.
  none,

  /// The single selected value (single-valued widgets), rendered as a
  /// filled circle.
  selected,

  /// Today's date, rendered as a hollow ring — never combined with
  /// [selected]'s filled-circle reading on the same cell in this enum, even
  /// though a cell can independently be "today" and "the range's start
  /// endpoint" (see [isRangeEndpoint]).
  today,

  /// A completed range's start or end endpoint, rendered at full strength.
  rangeEndpoint,

  /// A completed range's interior cell — tinted, persistently
  /// non-interactive.
  rangeInterior,
}

/// One cell of [LayrzPickersDayGrid] or, via the same visual vocabulary,
/// [LayrzPickersMonthGrid]'s month cells.
///
/// **Feedback is colour/opacity only (D15)** — disabled, rejected, hovered,
/// and pressed states never change this cell's size, padding, or border
/// width, so a state change never reflows the grid around it.
class LayrzPickersDayGridCell extends StatelessWidget {
  /// The label rendered inside the cell, e.g. `"14"` for a day or
  /// `"September"` for a month.
  final String label;

  /// Full localized description for screen readers, e.g. a full date or
  /// month+year, independent of [label]'s (possibly abbreviated) text.
  final String semanticLabel;

  /// This cell's role — see [LayrzPickerCellRole].
  final LayrzPickerCellRole role;

  /// Whether this cell falls outside the grid's own month (a greyed
  /// leading/trailing adjacent-month day). Ignored by [LayrzPickersMonthGrid],
  /// which has no adjacent-page cells.
  final bool isAdjacentPeriod;

  /// Whether this cell is disabled — outside `firstDay`/`lastDay` bounds or
  /// in `disabledDays`/`disabledMonths`. Disabled cells are genuinely inert
  /// (no `onTap`, no hover, no pointer cursor) but **never invisible** — a
  /// missing cell reads as "did I lose my place", which is worse than a
  /// visibly greyed one.
  final bool isDisabled;

  /// Whether this cell would currently reject a tap because it is a
  /// completed contiguous range's interior cell. Distinct from [isDisabled]:
  /// a rejected cell is still "in range", just not independently
  /// selectable, and carries its own semantics/styling rather than reading
  /// as unavailable.
  final bool isRejected;

  /// Called when this cell is tapped. `null` when [isDisabled] or
  /// [isRejected] is `true`, so the [GestureDetector] and [Semantics] node
  /// both report no tap handler.
  final VoidCallback? onTap;

  /// The [FocusNode] this cell attaches to the focus tree.
  ///
  /// Grid focus-traversal ownership lives in [LayrzPickersDayGrid]/
  /// [LayrzPickersMonthGrid], which allocate one node per cell — see those
  /// widgets' class docs for the [FocusTraversalGroup] contract this
  /// supports.
  final FocusNode focusNode;

  /// Creates a new [LayrzPickersDayGridCell].
  const LayrzPickersDayGridCell({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.role,
    this.isAdjacentPeriod = false,
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

    Color textColor;
    Color? fillColor;
    Border? ring;

    if (isDisabled) {
      textColor = tokens.colors.fg4;
    } else if (isAdjacentPeriod) {
      textColor = tokens.colors.fg4;
    } else {
      textColor = tokens.colors.fg1;
    }

    switch (role) {
      case LayrzPickerCellRole.none:
        break;
      case LayrzPickerCellRole.selected:
        fillColor = tokens.colors.primary;
        textColor = tokens.colors.sf1;
      case LayrzPickerCellRole.today:
        ring = Border.all(color: tokens.colors.primary, width: tokens.border.base);
      case LayrzPickerCellRole.rangeEndpoint:
        fillColor = tokens.colors.primary;
        textColor = tokens.colors.sf1;
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
              child: Center(
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: ring,
                    shape: BoxShape.circle,
                  ),
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
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

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
        // No circle fill here -- the continuous range bar
        // ([LayrzPickersDayGrid]'s own per-row background, painted behind
        // this cell) already provides the interior's light primary tint
        // edge-to-edge across the row. Painting a second, separately-shaped
        // fill on top of it would double the tint and reintroduce the
        // "separate circles" look Finding 2 replaces. Text stays at its
        // ordinary (non-selected) color, set above.
        break;
    }

    // A rejected cell that is not itself a range-interior cell (defensive:
    // every current caller only ever marks interior cells as rejected, but
    // this keeps a rejected cell visibly distinct even if that ever
    // changes) falls back to a light primary tint. `primary.shade50` is not
    // used here: [LayrzColorSwatch.fromColor] derives shade50 by
    // subtracting 0.40 from the seed's HSL lightness, which clamps to fully
    // opaque black for any seed under that lightness (e.g. the default
    // `kPrimaryColor`, ~0.19) -- this is the exact "solid black" defect
    // already diagnosed and worked around the same way in
    // `LayrzTreeRowStyleSpec.resolve` (see that file's doc comment).
    // Applying [tokens.colors.tonalOpacity] alpha to the seed colour itself
    // sidesteps the swatch derivation entirely and can never clamp to black.
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
          child: Center(
            // A circular 32x32 hit/paint target. [LayrzTappable] renders its
            // own hover/pressed surface *underneath* [child] via a plain
            // [DecoratedBox]/[AnimatedContainer] -- `borderRadius: 16.0`
            // (half of 32.0) rounds that surface to the same circle the
            // cell itself paints, rather than a hover square peeking out
            // from behind a circular label. Inert cells (disabled/rejected)
            // never reach [LayrzTappable] with a non-null `onTap`, so they
            // stay genuinely inert: no hover tint, no pointer cursor -- see
            // [LayrzTappable]'s own "inert path" branch, which renders a
            // bare [DecoratedBox] with no [MouseRegion]/[GestureDetector]
            // at all when `onTap`/`onLongPress`/`onSecondaryTap` are all
            // null. D15: only the tappable's own colour/opacity vary by
            // state; this cell's 32x32 box never changes size.
            child: LayrzTappable(
              onTap: isInert ? null : onTap,
              borderRadius: BorderRadius.circular(16.0),
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
    );
  }
}

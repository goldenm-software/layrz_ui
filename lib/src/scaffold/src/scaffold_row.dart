import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'scaffold_item.dart';

/// A single row in [ListPanel]'s list, rendering [LayrzScaffoldItem.tile].
///
/// The row is a plain [LayrzTappable]-wrapped tile: tapping the row body opens
/// the detail pane for its item (see [onTap]). The row has no trailing quick
/// actions — the design deliberately routes every interaction through
/// "tap to open the detail, then act from there" rather than exposing edit or
/// delete affordances directly on the list row.
///
/// A selected row ([isSelected]) renders disabled (its own detail pane is
/// already open) and paints the selection surface plus a trailing indicator bar.
class ScaffoldRow<T> extends StatelessWidget {
  /// The item this row represents.
  final LayrzScaffoldItem<T> item;

  /// Whether this row is the currently opened/selected item.
  final bool isSelected;

  /// Whether this row sits at an even position within the on-screen (filtered)
  /// list, used to alternate the idle background between `tokens.colors.sf1`
  /// (even) and `tokens.colors.sf2` (odd) — the same zebra-striping convention
  /// `LayrzTable` uses (see `table_row.dart`'s `rowIndex.isEven` check).
  ///
  /// Ignored when [isSelected] is true: a selected row always paints `sf4`
  /// regardless of parity.
  final bool isEvenRow;

  /// Called when the row body is tapped, to open the detail pane for [item].
  ///
  /// `null` when the list panel has no tap handler configured, in which case the
  /// row is rendered disabled/inert exactly as [LayrzTappable] would.
  final VoidCallback? onTap;

  /// Creates a new [ScaffoldRow].
  ///
  /// - [item]: The item this row represents. Required.
  /// - [isSelected]: Whether this row is the currently opened/selected item. Required.
  /// - [isEvenRow]: Whether this row sits at an even position in the on-screen list,
  ///   used for zebra striping. Defaults to true (matching the previous single-tone
  ///   `sf1` idle color for a row built without this parameter).
  /// - [onTap]: Called when the row body is tapped. Defaults to null (inert row).
  const ScaffoldRow({
    super.key,
    required this.item,
    required this.isSelected,
    this.isEvenRow = true,
    this.onTap,
  });

  /// The row's own idle surface color: selected (`sf4`) wins outright; otherwise
  /// the idle color alternates `sf1`/`sf2` by row parity, matching `LayrzTable`'s
  /// zebra striping.
  Color _rowIdleColor(LayrzTokens tokens) {
    if (isSelected) return tokens.colors.sf4;
    return isEvenRow ? tokens.colors.sf1 : tokens.colors.sf2;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayrzTappable(
      disabled: isSelected,
      onTap: onTap,
      borderRadius: tokens.radius.br2,
      // Precedence: selected (sf4) wins outright; otherwise the idle color
      // alternates sf1/sf2 by row parity (matching LayrzTable's zebra striping —
      // see table_row.dart's `rowIndex.isEven` check) and LayrzTappable itself
      // still overrides this with sf3 on hover / sf4 on press.
      color: _rowIdleColor(tokens),
      child: _buildRowContent(tokens),
    );
  }

  /// Builds the row's own content: the item tile plus the selection indicator bar.
  Widget _buildRowContent(LayrzTokens tokens) {
    return Padding(
      padding: tokens.spacing.pd2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tappable tile
          Expanded(child: item.tile),
          if (isSelected) ...[
            // Indicator bar — reserved space always (same width whether selected or not)
            Container(
              width: 3,
              height: double.infinity,
              decoration: BoxDecoration(
                color: tokens.colors.primary,
                borderRadius: tokens.radius.br3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

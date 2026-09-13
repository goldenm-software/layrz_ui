import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/snackbar/snackbar.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/table_action.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// The even/odd zebra-stripe background for the row at [rowIndex].
///
/// Even rows use `sf1`, odd rows `sf2`. Shared by all three column regions so
/// a row reads as one continuous stripe across the pinned-left, scrollable
/// middle, and pinned-right regions even though each is built by a separate
/// vertical list (the column-major layout, ported from `ThemedTable2`).
Color layrzTableRowStripe(BuildContext context, int rowIndex) {
  final tokens = context.tokens;
  return rowIndex.isEven ? tokens.colors.sf1 : tokens.colors.sf2;
}

/// The pinned-left multiselect checkbox cell for one row.
///
/// Rendered as the item of the pinned-left vertical list. Draws the row's
/// stripe fill plus the right column divider and the bottom row divider so the
/// row-to-row line runs unbroken across the full width of the table.
class LayrzTableCheckboxCell extends StatelessWidget {
  /// Creates a [LayrzTableCheckboxCell].
  const LayrzTableCheckboxCell({
    required this.rowIndex,
    required this.height,
    required this.isSelected,
    required this.onSelectedChanged,
    super.key,
  });

  /// The zero-based index of the row this cell belongs to, used for the stripe.
  final int rowIndex;

  /// The fixed row height, in logical pixels.
  final double height;

  /// Whether this row is currently selected.
  final bool isSelected;

  /// Called when the checkbox is toggled, or `null` to render it read-only.
  final ValueChanged<bool?>? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final stripeColor = layrzTableRowStripe(context, rowIndex);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stripeColor,
        border: Border(right: tokens.border.light, bottom: tokens.border.light),
      ),
      child: SizedBox(
        width: height,
        height: height,
        child: Center(
          child: LayrzCheckboxInput(value: isSelected, onChanged: onSelectedChanged, hideDetails: true),
        ),
      ),
    );
  }
}

/// The scrollable-middle data cells for one row, laid out left-to-right in a
/// single [Row] (one child per visible column).
///
/// Rendered as the item of the scrollable-middle vertical list; the whole
/// middle list is placed inside one horizontal viewport, so these rows scroll
/// sideways together and stay column-aligned with the header.
class LayrzTableDataRowCell<T> extends StatelessWidget {
  /// Creates a [LayrzTableDataRowCell].
  const LayrzTableDataRowCell({
    required this.item,
    required this.rowIndex,
    required this.visibleColumns,
    required this.columnWidths,
    required this.height,
    this.copyToClipboardText,
    super.key,
  });

  /// The domain object this row renders.
  final T item;

  /// The zero-based index of this row, used for the stripe.
  final int rowIndex;

  /// The currently-visible columns, in display order.
  final List<LayrzColumn<T>> visibleColumns;

  /// The resolved pixel width of each column in [visibleColumns], same order.
  final List<double> columnWidths;

  /// The fixed row height, in logical pixels.
  final double height;

  /// Optional override for the "copied to clipboard" snackbar title.
  final String? copyToClipboardText;

  String _displayedText(LayrzColumn<T> column) {
    final richSpans = column.richTextBuilder?.call(item);
    if (richSpans != null) {
      return TextSpan(children: richSpans).toPlainText();
    }
    return column.valueBuilder(item);
  }

  Future<void> _handleCellTap(BuildContext context, LayrzColumn<T> column) async {
    final onTap = column.onTap;
    if (onTap != null) {
      onTap(item);
      return;
    }

    final text = _displayedText(column);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    LayrzSnackbarMessenger.of(context).show(
      LayrzSnackbar(
        titleText: copyToClipboardText ?? context.l10n.tableCopiedToClipboard,
        descriptionText: text,
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, LayrzColumn<T> column, double width, Color stripeColor) {
    final tokens = context.tokens;
    final richSpans = column.richTextBuilder?.call(item);

    return SizedBox(
      width: width,
      height: height,
      // Right column divider + bottom row divider are painted in the
      // FOREGROUND, on top of the LayrzTappable, so they show regardless of the
      // tappable's idle/hover/pressed fill (which covers this exact rect). The
      // bottom side matches every other cell so the row-to-row line is unbroken.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(right: tokens.border.light, bottom: tokens.border.light),
        ),
        child: LayrzTappable(
          borderRadius: BorderRadius.zero,
          // Idle must equal the row's stripe color, not transparent: otherwise
          // hover animates transparent -> hover and reads as a blink on enter.
          // Idle == stripeColor makes hover a plain color-to-color ramp (D15).
          color: stripeColor,
          onTap: () => _handleCellTap(context, column),
          child: Align(
            alignment: column.alignment,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
              child: richSpans != null
                  ? RichText(
                      text: TextSpan(style: tokens.typography.body, children: richSpans),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      column.valueBuilder(item),
                      style: tokens.typography.body,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stripeColor = layrzTableRowStripe(context, rowIndex);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visibleColumns.length; i++)
            _buildDataCell(context, visibleColumns[i], columnWidths[i], stripeColor),
        ],
      ),
    );
  }
}

/// The pinned-right actions cell for one row.
///
/// Rendered as the item of the pinned-right vertical list. Draws the row's
/// stripe fill, a left column divider, and the bottom row divider. On wide
/// viewports it lays each action out as an icon fab; on compact viewports it
/// collapses them into a single overflow dropdown.
class LayrzTableActionsCell<T> extends StatelessWidget {
  /// Creates a [LayrzTableActionsCell].
  const LayrzTableActionsCell({
    required this.rowIndex,
    required this.height,
    required this.width,
    required this.actions,
    super.key,
  });

  /// The zero-based index of this row, used for the stripe.
  final int rowIndex;

  /// The fixed row height, in logical pixels.
  final double height;

  /// The resolved pixel width of the pinned-right actions column.
  final double width;

  /// The row-level actions to render.
  final List<LayrzTableAction> actions;

  Widget _buildWideActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final action in actions)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.tokens.spacing.sp1 / 2),
            child: LayrzButton(
              labelText: action.labelText,
              icon: action.icon,
              type: LayrzButtonType.custom,
              color: action.color,
              style: (action.style ?? LayrzButtonStyle.text).asFab,
              isDisabled: action.disabled,
              onTap: action.disabled ? null : action.onTap,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactActions(BuildContext context) {
    return LayrzButtonGroup(
      useDropdown: true,
      triggerHintText: context.l10n.tableActionsHint,
      items: [
        for (final action in actions)
          LayrzDropdownEntry(
            labelText: action.labelText,
            icon: action.icon,
            onTap: action.onTap,
            enabled: !action.disabled,
            color: action.color,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final stripeColor = layrzTableRowStripe(context, rowIndex);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stripeColor,
        border: Border(left: tokens.border.light, bottom: tokens.border.light),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
          child: context.isCompact ? _buildCompactActions(context) : _buildWideActions(context),
        ),
      ),
    );
  }
}

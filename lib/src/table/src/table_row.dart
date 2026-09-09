import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/snackbar/snackbar.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/table/src/table_action.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// Renders one data row of a `LayrzTable<T>`, as three cell regions rather
/// than a set of side-by-side column widgets.
///
/// ```
/// [ pinned-left: checkbox ] [ scrolling-middle: data cells ] [ pinned-right: actions ]
/// ```
///
/// - The **pinned-left** cell holds the multiselect checkbox, and is only
///   rendered when [hasMultiselect] is `true`. It never scrolls.
/// - The **scrolling-middle** region lays out one cell per entry in
///   [visibleColumns], at the corresponding width from [columnWidths]. It is
///   wrapped in a horizontally-scrolling [SingleChildScrollView] driven by a
///   [ScrollController] obtained from [scrollSync], so this row's middle
///   region moves in lockstep with every other row's middle region and with
///   the table header, however the user drags any one of them.
/// - The **pinned-right** cell renders [actions] as buttons, and is only
///   rendered when [actions] is non-empty. It never scrolls.
///
/// **Cell tap**: tapping a data cell invokes that column's
/// [LayrzColumn.onTap] when non-null. Otherwise, the cell's *displayed*
/// text — [LayrzColumn.richTextBuilder]'s reconstructed plain text when set,
/// else [LayrzColumn.valueBuilder]'s string — is copied to the clipboard and
/// a confirmation toast is shown. This is separate from any header tap,
/// which a `LayrzTable`'s header widget handles on its own.
///
/// **Row striping**: alternates `tokens.colors.sf1` (even [rowIndex]) and
/// `tokens.colors.sf2` (odd [rowIndex]) as the row's background, and paints
/// a single hairline divider (`tokens.border.light`) along the row's bottom
/// edge.
class LayrzTableRow<T> extends StatefulWidget {
  /// The row's underlying data object.
  final T item;

  /// The zero-based index of this row within the table's current
  /// filtered+sorted list.
  ///
  /// Used to alternate row striping (even/odd) and to derive each data
  /// cell's widget key by combining it with that column's [LayrzColumn.key].
  final int rowIndex;

  /// The columns to render in the scrolling-middle region, in display order,
  /// already filtered down to the currently-visible set and already
  /// reordered to match the table's current column order.
  ///
  /// This is `LayrzTableController.visibleColumnKeys`'s corresponding
  /// [LayrzColumn] list, resolved and ordered by the assembling `LayrzTable`
  /// widget — this row widget does not consult the controller directly.
  final List<LayrzColumn<T>> visibleColumns;

  /// The rendered width, in logical pixels, of each entry in
  /// [visibleColumns], at the same index.
  ///
  /// Must be the same length as [visibleColumns]. Computed once by the
  /// assembling `LayrzTable` widget from fixed/flex column-width rules, so
  /// every row (and the header) lays out identically.
  final List<double> columnWidths;

  /// The row's fixed height, in logical pixels.
  ///
  /// Applied to every cell region so the pinned-left, scrolling-middle, and
  /// pinned-right regions all agree on the row's total height.
  final double height;

  /// Whether the pinned-left multiselect checkbox cell is rendered.
  ///
  /// When `false`, the row has no pinned-left cell at all — not even an
  /// empty placeholder — and the scrolling-middle region starts at the
  /// row's leading edge.
  final bool hasMultiselect;

  /// Whether this row's [item] is currently selected.
  ///
  /// Meaningless when [hasMultiselect] is `false`. Reflects
  /// `LayrzTableController.selection.contains(item)`, read by the
  /// assembling `LayrzTable` widget so this row widget stays a pure
  /// function of its parameters.
  final bool isSelected;

  /// Called when the pinned-left checkbox is toggled by the user.
  ///
  /// Meaningless when [hasMultiselect] is `false`. Typically wired to
  /// `LayrzTableController.toggleSelection(item)` by the assembling
  /// `LayrzTable` widget.
  final ValueChanged<bool>? onSelectedChanged;

  /// The row-level actions rendered in the pinned-right actions cell, for
  /// this row's [item].
  ///
  /// When empty, no pinned-right cell is rendered at all — not even an
  /// empty placeholder — and the scrolling-middle region extends to the
  /// row's trailing edge.
  final List<LayrzTableAction> actions;

  /// The shared scroll-sync helper this row's middle region joins.
  ///
  /// [LayrzTableRowScrollSync.join] is called once, in [initState], to
  /// obtain this row's own linked [ScrollController]; the same
  /// [LayrzTableRowScrollSync] instance must also be given to every other
  /// row and to the table header so all of their middle regions move
  /// together.
  final LayrzTableRowScrollSync scrollSync;

  /// The fallback confirmation toast title shown after a cell's displayed
  /// text is copied to the clipboard.
  ///
  /// When `null`, a house default string is used.
  final String? copyToClipboardText;

  /// Creates a [LayrzTableRow].
  ///
  /// [item], [rowIndex], [visibleColumns], [columnWidths], [height], and
  /// [scrollSync] are required. [visibleColumns] and [columnWidths] must be
  /// the same length. [hasMultiselect] defaults to `false`; when `true`,
  /// [isSelected] and [onSelectedChanged] are meaningful. [actions] defaults
  /// to an empty list, meaning no pinned-right cell is rendered.
  const LayrzTableRow({
    super.key,
    required this.item,
    required this.rowIndex,
    required this.visibleColumns,
    required this.columnWidths,
    required this.height,
    required this.scrollSync,
    this.hasMultiselect = false,
    this.isSelected = false,
    this.onSelectedChanged,
    this.actions = const [],
    this.copyToClipboardText,
  }) : assert(visibleColumns.length == columnWidths.length, 'visibleColumns and columnWidths must be the same length');

  @override
  State<LayrzTableRow<T>> createState() => _LayrzTableRowState<T>();
}

class _LayrzTableRowState<T> extends State<LayrzTableRow<T>> {
  late final ScrollController _middleController;

  @override
  void initState() {
    super.initState();
    _middleController = widget.scrollSync.join();
  }

  @override
  void dispose() {
    _middleController.dispose();
    super.dispose();
  }

  /// Reconstructs the plain text actually shown in a cell, for either
  /// column-rendering mode.
  ///
  /// When [column] supplies a [LayrzColumn.richTextBuilder], the spans it
  /// returns for [widget.item] are what the user sees, so they — not
  /// [LayrzColumn.valueBuilder]'s raw string — are what copy-to-clipboard
  /// must reproduce. [TextSpan.toPlainText] walks the span tree (including
  /// nested spans) and concatenates their text.
  String _displayedText(LayrzColumn<T> column) {
    final richSpans = column.richTextBuilder?.call(widget.item);
    if (richSpans != null) {
      return TextSpan(children: richSpans).toPlainText();
    }
    return column.valueBuilder(widget.item);
  }

  Future<void> _handleCellTap(LayrzColumn<T> column) async {
    final onTap = column.onTap;
    if (onTap != null) {
      onTap(widget.item);
      return;
    }

    final text = _displayedText(column);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    LayrzSnackbarMessenger.of(context).show(
      LayrzSnackbar(titleText: widget.copyToClipboardText ?? 'Copied to clipboard', descriptionText: text),
    );
  }

  Widget _buildCheckboxCell(BuildContext context, Color stripeColor) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stripeColor,
        // The bottom side here is the row's horizontal divider, matching the
        // one every other cell paints (see `_buildDataCell` and
        // `_buildActionsCell`) so the row-to-row line runs unbroken across
        // the full width of the table.
        border: Border(right: tokens.border.light, bottom: tokens.border.light),
      ),
      child: SizedBox(
        width: widget.height,
        height: widget.height,
        child: Center(
          child: LayrzCheckboxInput(value: widget.isSelected, onChanged: widget.onSelectedChanged, hideDetails: true),
        ),
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, LayrzColumn<T> column, double width, Color stripeColor) {
    final tokens = context.tokens;
    final richSpans = column.richTextBuilder?.call(widget.item);

    return SizedBox(
      width: width,
      height: widget.height,
      // The right-side column divider and the bottom row divider are both
      // painted in the FOREGROUND, on top of the LayrzTappable below, rather
      // than as a background the tappable's own fill would sit above.
      // LayrzTappable paints an opaque AnimatedContainer covering this exact
      // rect (idle == stripeColor, see below) — a background-positioned
      // border drawn behind that fill is fully covered and invisible;
      // DecorationPosition.foreground paints this border last, after the
      // tappable's content, so it always shows regardless of the tappable's
      // current (idle/hover/pressed) color. The bottom side matches the one
      // every other cell paints (see `_buildCheckboxCell` and
      // `_buildActionsCell`) so the row-to-row line runs unbroken across the
      // full width of the table.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(right: tokens.border.light, bottom: tokens.border.light),
        ),
        child: LayrzTappable(
          borderRadius: BorderRadius.zero,
          // Idle must equal this row's own stripe color, not transparent:
          // with a transparent idle, the hover transition animates
          // transparent -> hover instead of stripe -> hover, and since the
          // stripe itself is painted on a DecoratedBox *behind* this
          // tappable (see build()'s outer background), the
          // transparent-to-opaque ramp reads as a visible "blink" the
          // instant the pointer enters. Idle == stripeColor makes hover a
          // plain color-to-color transition (D15).
          color: stripeColor,
          onTap: () => _handleCellTap(column),
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
                      column.valueBuilder(widget.item),
                      style: tokens.typography.body,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleRegion(BuildContext context, Color stripeColor) {
    return Expanded(
      child: SingleChildScrollView(
        controller: _middleController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < widget.visibleColumns.length; i++)
              _buildDataCell(context, widget.visibleColumns[i], widget.columnWidths[i], stripeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(BuildContext context) {
    final isCompact = context.isCompact;
    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        // The bottom side is the row's horizontal divider, matching the one
        // every other cell now paints explicitly (see `_buildCheckboxCell`
        // and `_buildDataCell`) rather than relying solely on the outer row
        // `DecoratedBox`'s own bottom border in `build()`, so all three cell
        // regions draw the exact same border on the exact same layer.
        decoration: BoxDecoration(
          border: Border(left: context.tokens.border.light, bottom: context.tokens.border.light),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.tokens.spacing.sp1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in widget.actions)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.tokens.spacing.sp1 / 2),
                  child: LayrzButton(
                    labelText: action.labelText,
                    icon: action.icon,
                    // `LayrzButton`'s constructor only accepts a non-null
                    // `color` when `type` is `custom` — `LayrzTableAction`
                    // always models its accent as a plain nullable `color`
                    // (never a semantic `LayrzButtonType`), so `custom` is
                    // the only type that can render it, and it degrades to
                    // the button's own primary-color default when `color`
                    // is null.
                    type: LayrzButtonType.custom,
                    color: action.color,
                    style: isCompact
                        ? (action.style ?? LayrzButtonStyle.text)
                        : (action.style ?? LayrzButtonStyle.text).asFab,
                    isDisabled: action.disabled,
                    onTap: action.disabled ? null : action.onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final background = widget.rowIndex.isEven ? tokens.colors.sf1 : tokens.colors.sf2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: tokens.border.light),
      ),
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.hasMultiselect) _buildCheckboxCell(context, background),
            _buildMiddleRegion(context, background),
            if (widget.actions.isNotEmpty) _buildActionsCell(context),
          ],
        ),
      ),
    );
  }
}

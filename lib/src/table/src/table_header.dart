import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/context_menu/context_menu.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/controller.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

/// The frozen header row of a `LayrzTable<T>`: one cell per visible column,
/// each carrying up to three interactions.
///
/// This header does **not** render the column-visibility/reorder menu
/// trigger (`LayrzColumnMenu`) — the assembling `LayrzTable` widget places
/// that trigger in its own toolbar row, beside the search field, rather
/// than in this header. See `LayrzColumnMenu`'s own doc for what it drives.
///
/// **Structural seam (a note for whoever assembles `LayrzTable` in U9):**
/// this widget does not compute column widths itself — the widget that owns
/// the global column-width math (fixed columns subtract, flex columns split
/// evenly, both floored at `minColumnWidth`) must compute one resolved width
/// per visible column **once** and hand the same [columnWidths] map to both
/// this header and every `LayrzTableRow`, so the two stay pixel-aligned. The
/// header DOES join the shared scroll-sync group itself: it takes the same
/// [LayrzTableRowScrollSync] instance the assembling widget constructs once
/// and shares with every row, and calls [LayrzTableRowScrollSync.join] for
/// its own linked controller in `initState`, disposing that controller in
/// `dispose` — the same lifecycle `LayrzTableRow` follows.
///
/// **The three header interactions (wide viewport only, per
/// [context.isCompact]):**
/// 1. **Tap anywhere on a sortable column's cell except its drag handle** —
///    toggles that column's sort via [LayrzTableController.sort]/
///    [LayrzTableController.clearSort] and shows the current sort-direction
///    glyph. Works on every viewport.
/// 2. **A dedicated, always-visible drag-handle grip icon** —
///    `MdiIcons.dragHorizontalVariant` — is the *only* drag-to-reorder
///    target, built from raw [Draggable]/[DragTarget] (there is no
///    Material `ReorderableListView` in this design system). **Rendered only
///    when `!context.isCompact`** — on compact, reorder lives entirely in
///    `LayrzColumnMenu`'s up/down controls.
/// 3. **Right-click or long-press opens a per-column [LayrzContextMenu]**
///    with explicit "Sort ascending" / "Sort descending" / "Clear sort" /
///    "Hide column" actions, the last disabled at the
///    [LayrzTableController.minVisibleColumns] boundary. **Only wired when
///    `!context.isCompact`** — compact devices get neither gesture.
///
/// Overflowing header text is wrapped in a [LayrzTooltip] showing the full
/// [LayrzColumn.headerText].
///
/// **Drag semantics:** the drag handle carries its own
/// [Semantics.label] plus [CustomSemanticsAction]s for "Move left"/"Move
/// right", entirely separate from the header cell's own tap-to-sort
/// [Semantics.button] — a screen-reader user is told these are two distinct
/// affordances, not one overloaded gesture. The handle itself does not need
/// to be operable by keyboard alone: `LayrzColumnMenu`'s "Move up"/"Move
/// down" entries are the keyboard-accessible reorder route (WCAG 2.1.1) on
/// every viewport, per the plan's explicit call-out.
class LayrzTableHeader<T> extends StatefulWidget {
  /// Every column the owning `LayrzTable<T>` was given, in the caller's
  /// declared order.
  ///
  /// Used to resolve each of [controller]'s `columnOrder` keys back to a
  /// [LayrzColumn] to render. Rendering itself always follows
  /// [LayrzTableController.columnOrder]/`visibleColumnKeys`, never this
  /// list's own order — [columns] exists only as a lookup table.
  final List<LayrzColumn<T>> columns;

  /// The controller this header reads sort/column state from and mutates.
  final LayrzTableController<T> controller;

  /// The resolved width, in logical pixels, of every currently-visible
  /// column, keyed by [LayrzColumn.key].
  ///
  /// Computed once by the assembling `LayrzTable` widget (fixed columns keep
  /// their own [LayrzColumn.width]; flex columns split the remaining space
  /// evenly, floored at the table's `minColumnWidth`) and shared verbatim
  /// with every `LayrzTableRow`'s cells so header and body columns stay
  /// aligned. A visible column absent from this map renders at
  /// [fallbackColumnWidth].
  final Map<Key, double> columnWidths;

  /// The width used for a visible column that has no entry in
  /// [columnWidths].
  ///
  /// This should not happen once the assembling widget's width math is
  /// wired correctly; it exists so this widget still renders something
  /// reasonable in isolation (e.g. a unit test that only exercises a subset
  /// of columns) instead of crashing on a missing map entry.
  final double fallbackColumnWidth;

  /// The height of the header row, in logical pixels.
  final double height;

  /// The shared scroll-sync group this header's middle region joins.
  ///
  /// The assembling widget constructs exactly one [LayrzTableRowScrollSync]
  /// and shares it with this header and with every `LayrzTableRow` — this
  /// widget calls [LayrzTableRowScrollSync.join] once, in
  /// `State.initState`, to obtain its own linked [ScrollController], so
  /// scrolling any row's middle region (or this header's) moves all of them
  /// in lockstep.
  final LayrzTableRowScrollSync scrollSync;

  /// Whether the header renders a pinned-left select-all checkbox cell.
  ///
  /// Mirrors `LayrzTableRow.hasMultiselect`: when `true`, this header's
  /// pinned-left region reserves the same width as every row's checkbox
  /// cell ([checkboxCellSize]), so the header's columns stay pixel-aligned
  /// with the body's. When `false`, no pinned-left cell is rendered here
  /// at all, matching a row with `hasMultiselect: false`.
  final bool hasMultiselect;

  /// The width and height, in logical pixels, of the pinned-left checkbox
  /// cell, when [hasMultiselect] is `true`.
  ///
  /// Must equal the value the assembling `LayrzTable` widget passes as every
  /// `LayrzTableRow.height` — that is the same value `LayrzTableRow` itself
  /// uses as its checkbox cell's (square) side length — otherwise the header
  /// and body checkbox columns will not line up.
  final double checkboxCellSize;

  /// Whether every row in the table's full (unfiltered) dataset is currently
  /// selected.
  ///
  /// Meaningless when [hasMultiselect] is `false`. Drives the select-all
  /// checkbox's checked state: checked only when this is `true`, unchecked
  /// otherwise. There is no indeterminate/tristate rendering — a partial
  /// selection still renders unchecked.
  final bool allSelected;

  /// Called when the select-all checkbox is toggled by the user.
  ///
  /// Meaningless when [hasMultiselect] is `false`. Receives `true` when the
  /// user checks the box (select every row in the full dataset, ignoring any
  /// active search filter) and `false` when the user unchecks it (clear the
  /// selection). Typically wired to `LayrzTableController.selectAll`/
  /// [LayrzTableController.clearSelection] by the assembling `LayrzTable`
  /// widget.
  final ValueChanged<bool>? onSelectAllChanged;

  /// The resolved width, in logical pixels, of the pinned-right actions
  /// cell, or `null` when the table renders no actions column at all.
  ///
  /// Computed once by the assembling `LayrzTable` widget from
  /// `LayrzTable.actionsCount` — deterministically, not from any button's
  /// intrinsic content size — and handed verbatim to every `LayrzTableRow`'s
  /// own actions cell as well, so this header's trailing edge always lines up
  /// with the rows' actions column pixel-for-pixel. `null` (or `<= 0`) means
  /// `LayrzTable.actionsCount` is `0`: no actions column is reserved here,
  /// matching a row with no actions cell.
  final double? actionsColumnWidth;

  /// Creates a [LayrzTableHeader].
  ///
  /// [columns], [controller], [columnWidths], and [scrollSync] are
  /// required. [height] defaults to `40` (the baseline's header height).
  /// [fallbackColumnWidth] defaults to `150`. [hasMultiselect] defaults to
  /// `false`; when `true`, [checkboxCellSize], [allSelected], and
  /// [onSelectAllChanged] become meaningful. [checkboxCellSize] defaults to
  /// `50`, matching `LayrzTable`'s own default row height. [allSelected]
  /// defaults to `false`. [actionsColumnWidth] defaults to `null` (no actions
  /// column reserved).
  const LayrzTableHeader({
    required this.columns,
    required this.controller,
    required this.columnWidths,
    required this.scrollSync,
    this.height = 40,
    this.fallbackColumnWidth = 150,
    this.hasMultiselect = false,
    this.checkboxCellSize = 50,
    this.allSelected = false,
    this.onSelectAllChanged,
    this.actionsColumnWidth,
    super.key,
  });

  @override
  State<LayrzTableHeader<T>> createState() => _LayrzTableHeaderState<T>();
}

class _LayrzTableHeaderState<T> extends State<LayrzTableHeader<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollSync.join();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Looks up the [LayrzColumn] whose [LayrzColumn.key] equals [key].
  ///
  /// Returns `null` if no such column exists in [LayrzTableHeader.columns]
  /// — this can happen transiently if [LayrzTableHeader.controller] has not
  /// yet been synced via [LayrzTableController.syncColumns] against a
  /// changed columns list.
  LayrzColumn<T>? _columnFor(Key key) {
    for (final column in widget.columns) {
      if (column.key == key) return column;
    }
    return null;
  }

  /// Handles a tap on [column]'s header cell (outside the drag handle).
  ///
  /// No-ops when [LayrzColumn.isSortable] is `false`. Otherwise cycles
  /// through ascending → descending → cleared, mirroring the baseline's
  /// three-state header tap.
  void _handleSortTap(LayrzColumn<T> column) {
    if (!column.isSortable) return;
    final controller = widget.controller;
    if (controller.sortColumnKey != column.key) {
      controller.sort(column.key, true);
    } else if (controller.sortAscending) {
      controller.sort(column.key, false);
    } else {
      controller.clearSort();
    }
  }

  /// Builds the per-column right-click/long-press context menu entries for
  /// [column].
  ///
  /// "Hide column" is disabled whenever hiding [column] would drop the
  /// number of visible columns below [LayrzTableController.minVisibleColumns]
  /// — the same guard `LayrzColumnMenu` applies to its own visibility
  /// checklist, so both entry points agree at the boundary.
  ///
  List<LayrzContextMenuItem> _buildContextMenuEntries(BuildContext context, LayrzColumn<T> column) {
    final l10n = context.l10n;
    final controller = widget.controller;
    final wouldBreachFloor = controller.visibleColumnKeys.length <= controller.minVisibleColumns;

    return [
      LayrzContextMenuEntry(
        labelText: l10n.tableSortAscending,
        icon: MdiIcons.sortAscending,
        enabled: column.isSortable,
        onTap: () => controller.sort(column.key, true),
      ),
      LayrzContextMenuEntry(
        labelText: l10n.tableSortDescending,
        icon: MdiIcons.sortDescending,
        enabled: column.isSortable,
        onTap: () => controller.sort(column.key, false),
      ),
      LayrzContextMenuEntry(
        labelText: l10n.tableClearSort,
        icon: MdiIcons.eraser,
        enabled: controller.sortColumnKey == column.key,
        onTap: controller.clearSort,
      ),
      const LayrzContextMenuDivider(),
      LayrzContextMenuEntry(
        labelText: l10n.tableHideColumn,
        icon: MdiIcons.eyeOffOutline,
        enabled: !wouldBreachFloor,
        onTap: () => controller.setColumnVisible(column.key, false),
      ),
    ];
  }

  /// Renders the sort-direction glyph for [column], or an invisible
  /// placeholder of the same size when [column] is not the active sort
  /// column — keeping every header cell's layout geometry identical whether
  /// or not it currently carries the indicator (see D15: interaction/state
  /// changes must never perturb geometry).
  Widget _buildSortGlyph(BuildContext context, LayrzColumn<T> column) {
    final tokens = context.tokens;
    final controller = widget.controller;
    final isActive = controller.sortColumnKey == column.key;

    return SizedBox(
      width: tokens.spacing.sp3,
      height: tokens.spacing.sp3,
      child: isActive
          ? Icon(
              controller.sortAscending ? MdiIcons.sortAscending : MdiIcons.sortDescending,
              size: tokens.spacing.sp3,
              color: tokens.colors.primary.shade500,
            )
          : null,
    );
  }

  /// Builds the drag handle for [column]'s wide-viewport reorder gesture.
  ///
  /// The handle is both the [Draggable] source (dragging it starts a
  /// reorder for [column]) and, implicitly, the only part of the header cell
  /// that does not also carry the tap-to-sort gesture — the two gestures
  /// never compete for the same pixels. [feedback] is a translucent copy of
  /// the header's own label so the user sees what is being dragged;
  /// [childWhenDragging] dims the handle in place to signal an active drag
  /// without shifting layout (again per D15).
  Widget _buildDragHandle(BuildContext context, LayrzColumn<T> column) {
    final tokens = context.tokens;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Semantics(
        // MANDATORY per D64: without container: true, this label and its
        // custom actions merge into the header cell's own sort-button node
        // instead of forming a distinct one. See input_chrome.dart.
        container: true,
        label: 'Reorder ${column.headerText} column',
        customSemanticsActions: {
          CustomSemanticsAction(label: 'Move ${column.headerText} left'): () => _moveByOneVisibleStep(column.key, -1),
          CustomSemanticsAction(label: 'Move ${column.headerText} right'): () => _moveByOneVisibleStep(column.key, 1),
        },
        child: Draggable<Key>(
          data: column.key,
          feedback: LayrzTableHeaderDragFeedback(headerText: column.headerText),
          childWhenDragging: Icon(
            MdiIcons.dragHorizontalVariant,
            size: tokens.spacing.sp3,
            color: tokens.colors.fg4,
          ),
          child: Icon(
            MdiIcons.dragHorizontalVariant,
            size: tokens.spacing.sp3,
            color: tokens.colors.fg3,
          ),
        ),
      ),
    );
  }

  /// Moves [key] one step up or down ([delta] is `-1` or `1`) among the
  /// currently-visible columns, clamped to the visible range.
  ///
  /// Backs the drag handle's [CustomSemanticsAction]s — an assistive
  /// technology user can trigger the same one-step move a mouse drag would
  /// produce, without needing to perform the drag gesture itself.
  void _moveByOneVisibleStep(Key key, int delta) {
    final controller = widget.controller;
    final visible = controller.visibleColumnKeys.toList(growable: false);
    final currentIndex = visible.indexOf(key);
    if (currentIndex == -1) return;
    controller.reorderColumn(key, currentIndex + delta);
  }

  /// Builds one header cell for [column], wired with tap-to-sort,
  /// drag-to-reorder (wide only), and the right-click/long-press context
  /// menu (wide only).
  ///
  /// **Semantics structure (why the drag handle is a sibling, not a
  /// descendant):** the sort region below wraps itself in
  /// `Semantics(excludeSemantics: true)` so the visible header [Text]'s own
  /// implicit label doesn't bleed into the explicit "Sort by X" label (see
  /// the comment on that Semantics node). `excludeSemantics` has no "except
  /// this subtree" escape hatch — it discards every descendant's semantics
  /// unconditionally. The drag handle carries its own distinct
  /// [Semantics.label] and [CustomSemanticsAction]s (built in
  /// [_buildDragHandle]), so if it were nested inside the sort region's
  /// excluded subtree — as it was before this fix — its node would vanish
  /// too, leaving a screen-reader user with a sort button and no reorder
  /// affordance. Making it a sibling under the shared `Row` in
  /// [cellChildren] keeps both nodes distinct.
  Widget _buildHeaderCell(BuildContext context, LayrzColumn<T> column, bool isCompact) {
    final tokens = context.tokens;

    final width = widget.columnWidths[column.key] ?? widget.fallbackColumnWidth;

    if (isCompact) {
      // Compact has no drag target underneath, so the sort region always
      // sits directly on the header's own `sf2` background.
      return SizedBox(
        width: width,
        height: widget.height,
        child: _buildSortRegion(context, column, tokens.colors.sf2),
      );
    }

    // Wide viewport: the drag handle is a sibling of the sort region, sharing
    // the cell's overall `width` with it instead of living inside it, so the
    // handle keeps its own semantics node (see dartdoc above) while the
    // total footprint still equals `width` — the same budget the pre-fix
    // single-Row layout consumed, just split across two widgets instead of
    // one Row's children.
    final controller = widget.controller;
    final dragTarget = DragTarget<Key>(
      onWillAcceptWithDetails: (details) => details.data != column.key,
      onAcceptWithDetails: (details) {
        final visible = controller.visibleColumnKeys.toList(growable: false);
        final targetIndex = visible.indexOf(column.key);
        if (targetIndex == -1) return;
        controller.reorderColumn(details.data, targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;
        // The sort region's tappable idle color must match whichever
        // background is actually painted behind it right now — `sf2`
        // normally, or `sf3` while this column is a live drop target —
        // otherwise the sort cell would show a mismatched patch (or, if left
        // transparent, blink on hover: see the dartdoc note on
        // `_buildSortRegion`).
        final backgroundColor = isDragTarget ? tokens.colors.sf3 : tokens.colors.sf2;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(right: tokens.border.light),
            color: backgroundColor,
          ),
          child: Row(
            children: [
              Expanded(child: _buildSortRegion(context, column, backgroundColor)),
              SizedBox(width: tokens.spacing.sp1),
              Padding(
                padding: EdgeInsets.only(right: tokens.spacing.sp2),
                child: _buildDragHandle(context, column),
              ),
            ],
          ),
        );
      },
    );

    return SizedBox(width: width, height: widget.height, child: dragTarget);
  }

  /// Builds the tap-to-sort region of [column]'s header cell: the label,
  /// sort-direction glyph, and the [LayrzTappable] that makes the whole area
  /// tappable.
  ///
  /// [backgroundColor] must equal whatever color is actually painted behind
  /// this region at call time — the header's own `sf2` background normally,
  /// or the `sf3` drag-target highlight while the owning column is a live
  /// drop target (see the two call sites in [_buildHeaderCell]). It becomes
  /// the tappable's idle [LayrzTappable.color]: with a transparent idle, the
  /// hover transition animates transparent -> hover instead of
  /// background -> hover, which reads as a visible "blink" the instant the
  /// pointer enters, since the real background is painted on a widget
  /// *behind* this tappable. Idle == backgroundColor makes hover a plain
  /// color-to-color transition (D15), mirroring the same fix applied to
  /// `LayrzTableRow`'s data cells.
  Widget _buildSortRegion(BuildContext context, LayrzColumn<T> column, Color backgroundColor) {
    final tokens = context.tokens;

    final label = LayrzTooltip(
      titleText: column.headerText,
      contentText: column.headerText,
      trigger: LayrzTooltipTrigger.pointer,
      child: Text(
        column.headerText,
        style: tokens.typography.label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    final sortContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: label),
        SizedBox(width: tokens.spacing.sp1),
        _buildSortGlyph(context, column),
      ],
    );

    return Semantics(
      // MANDATORY per D64: without container: true, the LayrzTooltip's
      // semantics merge into this button's node instead of remaining
      // distinct. See input_chrome.dart.
      //
      // excludeSemantics: true additionally discards the visible header
      // Text's (and LayrzTooltip's) own implicit label, which would otherwise
      // merge INTO this node's explicit label — e.g. "Sort by Col 1\nCol 1"
      // instead of "Sort by Col 1". container: true alone only stops this
      // node merging UPWARD into an ancestor; it says nothing about a
      // descendant's own label merging down. Matches the same
      // Semantics(button:, label:) + excludeSemantics: true shape used for a
      // tooltip-wrapped visible label in button.dart.
      //
      // onTap is required here too: excludeSemantics: true also discards the
      // descendant LayrzTappable's own tap action, so without redeclaring it
      // on this node directly, the sort button would carry a label and
      // isButton flag but no invokable action for assistive tech. Matches the
      // Semantics(button:, label:, onTap:, excludeSemantics:) shape in
      // glyph_grid.dart and the pickers' shared headers.
      //
      // The drag handle is deliberately NOT inside this subtree — see the
      // dartdoc above [_buildHeaderCell] for why nesting it here would
      // silently discard its semantics node.
      container: true,
      button: column.isSortable,
      label: column.isSortable ? 'Sort by ${column.headerText}' : null,
      onTap: column.isSortable ? () => _handleSortTap(column) : null,
      excludeSemantics: true,
      child: LayrzTappable(
        color: backgroundColor,
        onTap: column.isSortable ? () => _handleSortTap(column) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
          child: Align(alignment: column.alignment, child: sortContent),
        ),
      ),
    );
  }

  /// Builds the pinned-left select-all checkbox cell, mirroring
  /// `LayrzTableRow`'s own checkbox cell exactly in size and border so the
  /// header and body pinned-left regions occupy the same width.
  ///
  /// Checked only when [LayrzTableHeader.allSelected] is `true` — there is no
  /// indeterminate/tristate rendering for a partial selection, matching
  /// [LayrzCheckboxInput]'s own boolean-only contract. Toggling this checkbox
  /// calls [LayrzTableHeader.onSelectAllChanged] with the new checked state;
  /// the assembling `LayrzTable` widget is responsible for turning `true`
  /// into "select every row in the full dataset" and `false` into "clear the
  /// selection".
  Widget _buildCheckboxCell(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(right: tokens.border.light)),
      child: SizedBox(
        width: widget.checkboxCellSize,
        height: widget.checkboxCellSize,
        child: Center(
          child: LayrzCheckboxInput(
            value: widget.allSelected,
            onChanged: widget.onSelectAllChanged,
            hideDetails: true,
          ),
        ),
      ),
    );
  }

  /// Builds the pinned-right actions-column placeholder cell, reserving
  /// exactly [LayrzTableHeader.actionsColumnWidth] so this header's trailing
  /// edge aligns with every `LayrzTableRow`'s own actions cell.
  ///
  /// Carries no interactive content of its own — the header has nothing to
  /// show per-column here, unlike a row's per-item action buttons — it only
  /// exists to reserve the same width and paint the same borders every row's
  /// actions cell paints, so the column reads as one continuous strip instead
  /// of the rows' actions column floating unaligned under the header.
  Widget _buildActionsCell(BuildContext context, double width) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(left: tokens.border.light)),
      child: SizedBox(width: width, height: widget.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompact = context.isCompact;
    final controller = widget.controller;
    final visibleKeys = controller.columnOrder.where((key) => controller.visibleColumnKeys.contains(key));
    final actionsColumnWidth = widget.actionsColumnWidth;
    final hasActionsColumn = actionsColumnWidth != null && actionsColumnWidth > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        border: Border(bottom: tokens.border.normal),
      ),
      child: SizedBox(
        height: widget.height,
        child: Row(
          children: [
            if (widget.hasMultiselect) _buildCheckboxCell(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (final key in visibleKeys)
                      if (_columnFor(key) case final column?)
                        isCompact
                            ? _buildHeaderCell(context, column, true)
                            : LayrzContextMenu(
                                entries: _buildContextMenuEntries(context, column),
                                child: _buildHeaderCell(context, column, false),
                              ),
                  ],
                ),
              ),
            ),
            if (hasActionsColumn) _buildActionsCell(context, actionsColumnWidth),
          ],
        ),
      ),
    );
  }
}

/// A translucent copy of a header cell's label, shown under the pointer
/// while a column drag is in flight.
///
/// Kept as its own tiny widget (rather than inline in [Draggable.feedback])
/// so its `Material`-free surface styling — a themed card with the dragged
/// column's [headerText] — is easy to read in isolation and to unit test.
class LayrzTableHeaderDragFeedback extends StatelessWidget {
  /// The dragged column's [LayrzColumn.headerText], shown as this
  /// feedback card's only content.
  final String headerText;

  /// Creates a [LayrzTableHeaderDragFeedback].
  ///
  /// [headerText] is required.
  const LayrzTableHeaderDragFeedback({required this.headerText, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Opacity(
      opacity: 0.85,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.sf1,
          borderRadius: tokens.radius.br2,
          border: Border.fromBorderSide(tokens.border.normal),
          boxShadow: tokens.shadow.elevation3,
        ),
        child: Padding(
          padding: tokens.spacing.pd2,
          child: Text(headerText, style: tokens.typography.label),
        ),
      ),
    );
  }
}

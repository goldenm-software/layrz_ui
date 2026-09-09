import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/context_menu/context_menu.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/table/src/column.dart';
import 'package:layrz_ui/src/table/src/column_menu.dart';
import 'package:layrz_ui/src/table/src/controller.dart';
import 'package:layrz_ui/src/table/src/row_scroll_sync.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

/// The frozen header row of a `LayrzTable<T>`: one cell per visible column,
/// each carrying up to three interactions, plus the trigger for
/// [LayrzColumnMenu].
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
///    [LayrzColumnMenu]'s up/down controls.
/// 3. **Right-click or long-press opens a per-column [LayrzContextMenu]**
///    with explicit "Sort ascending" / "Sort descending" / "Clear sort" /
///    "Hide column" actions, the last disabled at the
///    [LayrzTableController.minVisibleColumns] boundary. **Only wired when
///    `!context.isCompact`** — compact devices get neither gesture.
///
/// Overflowing header text is wrapped in a [LayrzTooltip] showing the full
/// [LayrzColumn.headerText]. The trailing [LayrzColumnMenu] trigger is
/// rendered once, after every column cell, regardless of viewport (it is the
/// only reorder/visibility surface on compact and coexists with the header
/// drag handle on wide).
///
/// **Drag semantics:** the drag handle carries its own
/// [Semantics.label] plus [CustomSemanticsAction]s for "Move left"/"Move
/// right", entirely separate from the header cell's own tap-to-sort
/// [Semantics.button] — a screen-reader user is told these are two distinct
/// affordances, not one overloaded gesture. The handle itself does not need
/// to be operable by keyboard alone: [LayrzColumnMenu]'s "Move up"/"Move
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

  /// Creates a [LayrzTableHeader].
  ///
  /// [columns], [controller], [columnWidths], and [scrollSync] are
  /// required. [height] defaults to `40` (the baseline's header height).
  /// [fallbackColumnWidth] defaults to `150`.
  const LayrzTableHeader({
    required this.columns,
    required this.controller,
    required this.columnWidths,
    required this.scrollSync,
    this.height = 40,
    this.fallbackColumnWidth = 150,
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
  /// — the same guard [LayrzColumnMenu] applies to its own visibility
  /// checklist, so both entry points agree at the boundary.
  ///
  /// **i18n note:** this menu's labels are plain string fallbacks, not
  /// `context.l10n` getters — no `LayrzUiL10n` mixin defines
  /// sort/hide-column context-menu strings yet (the existing
  /// `LayrzUiL10nTableMixin` covers only the legacy paginator). Per the
  /// dossier's OQ8, a full key audit/addition is an explicit fast-follow,
  /// not a blocker for this component's first ship.
  List<LayrzContextMenuItem> _buildContextMenuEntries(LayrzColumn<T> column) {
    final controller = widget.controller;
    final wouldBreachFloor = controller.visibleColumnKeys.length <= controller.minVisibleColumns;

    return [
      LayrzContextMenuEntry(
        labelText: 'Sort ascending',
        icon: MdiIcons.sortAscending,
        enabled: column.isSortable,
        onTap: () => controller.sort(column.key, true),
      ),
      LayrzContextMenuEntry(
        labelText: 'Sort descending',
        icon: MdiIcons.sortDescending,
        enabled: column.isSortable,
        onTap: () => controller.sort(column.key, false),
      ),
      LayrzContextMenuEntry(
        labelText: 'Clear sort',
        icon: MdiIcons.eraser,
        enabled: controller.sortColumnKey == column.key,
        onTap: controller.clearSort,
      ),
      const LayrzContextMenuDivider(),
      LayrzContextMenuEntry(
        labelText: 'Hide column',
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

    final sortRegion = Semantics(
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
        // Idle must stay transparent, not the LayrzTappable default opaque
        // `sf1`: this cell sits on top of the header's own `sf2` background
        // (and, on a drag target, a `sf3` highlight), and an opaque `sf1`
        // square would paint over both instead of letting them show through.
        color: const Color(0x00000000),
        onTap: column.isSortable ? () => _handleSortTap(column) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
          child: Align(alignment: column.alignment, child: sortContent),
        ),
      ),
    );

    final width = widget.columnWidths[column.key] ?? widget.fallbackColumnWidth;

    if (isCompact) {
      return SizedBox(width: width, height: widget.height, child: sortRegion);
    }

    // Wide viewport: the drag handle is a sibling of `sortRegion`, sharing
    // the cell's overall `width` with it instead of living inside it, so the
    // handle keeps its own semantics node (see dartdoc above) while the
    // total footprint still equals `width` — the same budget the pre-fix
    // single-Row layout consumed, just split across two widgets instead of
    // one Row's children.
    final cell = Row(
      children: [
        Expanded(child: sortRegion),
        SizedBox(width: tokens.spacing.sp1),
        Padding(
          padding: EdgeInsets.only(right: tokens.spacing.sp2),
          child: _buildDragHandle(context, column),
        ),
      ],
    );

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
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(right: tokens.border.light),
            color: isDragTarget ? tokens.colors.sf3 : null,
          ),
          child: cell,
        );
      },
    );

    return SizedBox(width: width, height: widget.height, child: dragTarget);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompact = context.isCompact;
    final controller = widget.controller;
    final visibleKeys = controller.columnOrder.where((key) => controller.visibleColumnKeys.contains(key));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colors.sf2,
        border: Border(bottom: tokens.border.normal),
      ),
      child: SizedBox(
        height: widget.height,
        child: Row(
          children: [
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
                                entries: _buildContextMenuEntries(column),
                                child: _buildHeaderCell(context, column, false),
                              ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
              child: LayrzColumnMenu<T>(columns: widget.columns, controller: controller),
            ),
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

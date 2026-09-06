import 'package:flutter/widgets.dart';

import 'focus_ring.dart';
import 'glyph_grid_keyboard.dart';

/// Builds the visible content for one cell of a [LayrzGlyphGrid].
///
/// [context] is the cell's own build context. [item] is the value at
/// [index] in [LayrzGlyphGrid.items]. [isFocused] reflects whether this
/// cell's [FocusNode] currently holds primary focus — a builder that wants
/// its own additional focus-driven styling (beyond the grid's own
/// [LayrzFocusRing] overlay) can read it, but most callers can ignore it
/// entirely since the ring is already applied by the grid.
typedef LayrzGlyphGridItemBuilder<T> = Widget Function(BuildContext context, T item, int index, bool isFocused);

/// Builds the semantic label announced for one cell, given [item] at
/// [index]. Used as the [Semantics.label] wrapping each cell — see
/// [LayrzGlyphGrid.semanticLabelBuilder].
typedef LayrzGlyphGridSemanticLabelBuilder<T> = String Function(T item, int index);

/// A generic, keyboard-navigable, lazily-rendered MxN grid of glyph-shaped
/// items — the shared surface both the emoji picker (thousands of emoji)
/// and the icon picker (7000+ MDI icons) render their content into.
///
/// **Generic over an arbitrary item type [T]**, unlike
/// `day_grid.dart`/`month_grid.dart` (both hard-`DateTime`-typed and
/// unsuitable for a glyph list — see `grid_math.dart`'s doc comment for why
/// that pair was purpose-built for calendar arithmetic and is not reused
/// here). This widget owns none of the domain vocabulary those two carry
/// (no selected/today/range roles) — it is a pure "flat list of cells,
/// arranged into columns, keyboard-navigable" primitive; [itemBuilder]
/// supplies 100% of each cell's visible content and any selected/disabled
/// styling the caller wants.
///
/// **Built for large item counts.** [items] backing an emoji or icon picker
/// can run into the thousands, so this widget renders through
/// [GridView.builder] (viewport-based, lazy) rather than eagerly building
/// every cell up front — only cells within (and slightly beyond, per
/// [GridView]'s own `cacheExtent`) the visible viewport are ever built or
/// given a [FocusNode]. [FocusNode]s are allocated lazily per index (a
/// `Map<int, FocusNode>`, mirroring `day_grid.dart`'s own `_focusNodeFor`
/// pattern) and disposed together with the widget, not per-scroll — an
/// index scrolled out of view keeps its node allocated (cheap: a bare
/// [FocusNode] costs little) so focus is not lost merely by scrolling past
/// the focused cell and back.
///
/// **Keyboard navigation** is delegated through [keyboardHandler] — see
/// [LayrzGlyphGridKeyboardHandler] — exactly mirroring how
/// [LayrzGridKeyboardHandler] is injected into the date grids rather than
/// hardcoded, so `buildGlyphGridKeyboardHandler` (this module's own
/// generic handler) can be swapped or wrapped by a caller without editing
/// this file. Passing `null` degrades gracefully to Flutter's default
/// [FocusTraversalGroup] (Tab/Shift+Tab only, no arrow-key movement).
///
/// **Focus ring.** Every cell is wrapped in the shared, reusable
/// [LayrzFocusRing] — the same D15-compliant overlay
/// `LayrzPickersDayGrid`/`LayrzPickersMonthGrid` already use — so keyboard
/// focus is visibly indicated (WCAG 2.4.7) without this widget or
/// [itemBuilder] needing to hand-roll it.
///
/// **A keyboard move that lands on an index outside the currently built
/// viewport** is handled by [ScrollController.animateTo]/[jumpTo]-driven
/// scrolling in [_ensureIndexVisible], scheduled after the frame in which
/// the new index becomes the requested focus target, so `GridView.builder`
/// has a chance to build that index's cell (and allocate its [FocusNode])
/// before focus is actually requested on it.
class LayrzGlyphGrid<T> extends StatefulWidget {
  /// The flat list of items this grid renders, one cell per entry. May be
  /// very large (thousands) — see the class doc's "Built for large item
  /// counts" note.
  final List<T> items;

  /// The number of columns each row contains. Must be at least 1.
  final int columns;

  /// Builds each cell's visible content — see [LayrzGlyphGridItemBuilder].
  final LayrzGlyphGridItemBuilder<T> itemBuilder;

  /// Called when an item is activated — a tap, or Enter/Space via
  /// [keyboardHandler] (when supplied by [buildGlyphGridKeyboardHandler]'s
  /// own `onSelect`, which this grid does not construct itself; see
  /// [keyboardHandler]'s doc). `null` items are never passed; the index is
  /// always a valid index into [items].
  final ValueChanged<T> onItemActivated;

  /// Optional injectable keyboard-navigation delegate, built via
  /// `buildGlyphGridKeyboardHandler` — see [LayrzGlyphGridKeyboardHandler].
  /// `null` (the default) means only Flutter's default focus traversal
  /// (Tab/Shift+Tab) applies; arrow-key/Home/End/Enter/Space movement is a
  /// no-op until a handler is supplied.
  final LayrzGlyphGridKeyboardHandler? keyboardHandler;

  /// Whether item at [index] is disabled — inert (no tap, no keyboard
  /// activation) but still rendered, matching the date grids' "never make
  /// a cell disappear" convention. Defaults to a function that always
  /// returns `false` (nothing disabled).
  final bool Function(int index) isDisabled;

  /// The fixed side length, in logical pixels, of each square cell.
  /// Defaults to `40.0`, matching the day grid's cell scale.
  final double cellExtent;

  /// Spacing, in logical pixels, between cells both horizontally and
  /// vertically. Defaults to `4.0`.
  final double cellSpacing;

  /// Builds the semantic label announced for each cell — see
  /// [LayrzGlyphGridSemanticLabelBuilder]. `null` (the default) means no
  /// [Semantics] wrapper is applied by this widget itself, leaving
  /// [itemBuilder]'s own content to supply (or omit) semantics — used by
  /// callers whose [itemBuilder] already wraps its content in its own
  /// [Semantics] node (avoiding doubled/merged semantics).
  final LayrzGlyphGridSemanticLabelBuilder<T>? semanticLabelBuilder;

  /// Creates a new [LayrzGlyphGrid].
  const LayrzGlyphGrid({
    super.key,
    required this.items,
    required this.columns,
    required this.itemBuilder,
    required this.onItemActivated,
    this.keyboardHandler,
    this.isDisabled = _neverDisabled,
    this.cellExtent = 40.0,
    this.cellSpacing = 4.0,
    this.semanticLabelBuilder,
  }) : assert(columns >= 1, 'columns must be at least 1, got $columns.');

  @override
  State<LayrzGlyphGrid<T>> createState() => _LayrzGlyphGridState<T>();
}

/// Default [LayrzGlyphGrid.isDisabled] — every index is enabled.
bool _neverDisabled(int index) => false;

class _LayrzGlyphGridState<T> extends State<LayrzGlyphGrid<T>> {
  final Map<int, FocusNode> _focusNodes = {};
  final ScrollController _scrollController = ScrollController();

  /// An index requested via keyboard movement that fell outside the
  /// currently-built viewport at request time, applied once
  /// [_ensureIndexVisible] has scrolled it into range — see
  /// [_requestFocus].
  int? _pendingFocusIndex;

  FocusNode _focusNodeFor(int index) => _focusNodes.putIfAbsent(index, () => FocusNode(debugLabel: 'glyph-$index'));

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// The [requestFocus] callback passed into [LayrzGlyphGridKeyboardHandler]
  /// invocations. A direct [FocusNode.requestFocus] works whenever [index]'s
  /// cell has already been built by [GridView.builder] (i.e. its
  /// [FocusNode] already exists in [_focusNodes]); otherwise the index is
  /// staged as [_pendingFocusIndex] and the grid is scrolled toward it so a
  /// following frame builds the cell and its node.
  void _requestFocus(int index) {
    final existing = _focusNodes[index];
    if (existing != null) {
      existing.requestFocus();
      return;
    }
    _pendingFocusIndex = index;
    _ensureIndexVisible(index);
  }

  /// Scrolls [_scrollController] so the row containing [index] is within
  /// the viewport, then schedules [_applyPendingFocus] for the frame after
  /// that scroll lands (so `GridView.builder` has built the target cell).
  void _ensureIndexVisible(int index) {
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyPendingFocus();
      });
      return;
    }

    final row = index ~/ widget.columns;
    final rowOffset = row * (widget.cellExtent + widget.cellSpacing);
    final target = rowOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(target, duration: const Duration(milliseconds: 1), curve: Curves.linear).then((_) {
      if (mounted) _applyPendingFocus();
    });
  }

  /// Focuses [_pendingFocusIndex] once its cell has actually been built —
  /// scheduled from [_ensureIndexVisible] after the scroll animation
  /// settles, so [_focusNodeFor] has had a chance to allocate the node for
  /// the newly-visible cell.
  void _applyPendingFocus() {
    final pending = _pendingFocusIndex;
    if (pending == null) return;
    _pendingFocusIndex = null;
    _focusNodeFor(pending).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: GridView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.columns,
          mainAxisSpacing: widget.cellSpacing,
          crossAxisSpacing: widget.cellSpacing,
          childAspectRatio: 1.0,
        ),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final focusNode = _focusNodeFor(index);
          final isDisabled = widget.isDisabled(index);

          return _LayrzGlyphGridCell<T>(
            item: item,
            index: index,
            isDisabled: isDisabled,
            focusNode: focusNode,
            itemBuilder: widget.itemBuilder,
            onItemActivated: widget.onItemActivated,
            semanticLabel: widget.semanticLabelBuilder?.call(item, index),
            onKeyEvent: widget.keyboardHandler == null
                ? null
                : (node, event) => widget.keyboardHandler!(event, index, _requestFocus),
          );
        },
      ),
    );
  }
}

/// A single [LayrzGlyphGrid] cell — wires the caller's [itemBuilder] content
/// to focus, keyboard handling, tap activation, and (optionally) semantics,
/// in one place so [_LayrzGlyphGridState.build] itself stays a plain
/// `GridView.builder` wiring without inline per-cell gesture/semantics
/// logic.
///
/// **Composition order matches `day_grid_cell.dart`'s own**: an outer
/// [Semantics] node (when [semanticLabel] is supplied) wraps [Focus], which
/// wraps [LayrzFocusRing], which wraps the tappable content — *not* the
/// reverse. [Focus] annotates its own `isFocusable`/`focus` semantics onto
/// whatever leaf node ends up representing it; wrapping [Focus] *inside* a
/// [Semantics] node (rather than the other way around) is what lets this
/// cell's `label`/`button`/`onTap` semantics still surface to a screen
/// reader instead of being replaced by [Focus]'s own bare focus-only node.
class _LayrzGlyphGridCell<T> extends StatefulWidget {
  final T item;
  final int index;
  final bool isDisabled;
  final FocusNode focusNode;
  final LayrzGlyphGridItemBuilder<T> itemBuilder;
  final ValueChanged<T> onItemActivated;
  final String? semanticLabel;
  final FocusOnKeyEventCallback? onKeyEvent;

  const _LayrzGlyphGridCell({
    required this.item,
    required this.index,
    required this.isDisabled,
    required this.focusNode,
    required this.itemBuilder,
    required this.onItemActivated,
    required this.semanticLabel,
    required this.onKeyEvent,
  });

  @override
  State<_LayrzGlyphGridCell<T>> createState() => _LayrzGlyphGridCellState<T>();
}

class _LayrzGlyphGridCellState<T> extends State<_LayrzGlyphGridCell<T>> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _LayrzGlyphGridCell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.itemBuilder(context, widget.item, widget.index, _isFocused);

    final tappable = GestureDetector(
      onTap: widget.isDisabled ? null : () => widget.onItemActivated(widget.item),
      behavior: HitTestBehavior.opaque,
      child: content,
    );

    final focusable = Focus(
      focusNode: widget.focusNode,
      onKeyEvent: widget.onKeyEvent,
      child: LayrzFocusRing(focusNode: widget.focusNode, child: tappable),
    );

    if (widget.semanticLabel == null) return focusable;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: !widget.isDisabled,
      onTap: widget.isDisabled ? null : () => widget.onItemActivated(widget.item),
      excludeSemantics: true,
      child: focusable,
    );
  }
}

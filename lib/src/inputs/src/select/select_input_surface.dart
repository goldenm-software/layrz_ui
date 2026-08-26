import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// The selection surface content used by [LayrzSelectInput].
///
/// This widget renders a scrollable list of items and manages keyboard navigation
/// (arrow keys, Enter, Escape) and item selection. It no longer owns a search field of
/// its own (DESIGN-40/144's redesign): when [enableSearch] is true, the caller's own
/// field is the searcher, and [query] is fed in from there; when false, this is a pure
/// picker and [query] is ignored (always treated as empty).
///
/// This is a private implementation detail; consumers use [LayrzSelectInput] instead.
class LayrzSelectInputSurface<T> extends StatefulWidget {
  /// The list of items to display.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected item (for visual highlighting).
  final LayrzSelectItem<T>? selectedItem;

  /// Whether the caller's own field is the searcher for this surface.
  ///
  /// When true, [query] carries the caller's field's current text and this surface
  /// never requests keyboard focus for its list on open -- the caller's field keeps
  /// focus so typing keeps working. When false, this is a pure picker: [query] is
  /// ignored, and the list requests focus on open so arrow keys/Enter/Escape work.
  final bool enableSearch;

  /// Whether an item with `value: null` can be selected.
  final bool canUnselect;

  /// Optional custom filter function; if null, uses [LayrzSelectItem.matches].
  ///
  /// Applied regardless of whether [query] is empty -- an empty query still runs
  /// through this callback rather than short-circuiting to "show all".
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text shown when search finds no matching items.
  final String? emptyListText;

  /// Callback when an item is selected or cleared.
  final void Function(LayrzSelectItem<T>?) onItemSelected;

  /// Optional menu controller to close the panel after selection.
  ///
  /// When provided, the surface will call [controller.close()] after an item is selected.
  /// This is used when the surface is displayed in an anchored panel on desktop.
  final MenuController? panelController;

  /// The current search query, typed into the caller's own field.
  ///
  /// Ignored when [enableSearch] is false. Defaults to `''` (show everything, subject
  /// to [filter] if provided).
  final String query;

  /// Defines the expected height of each item in the list.
  final double itemExtent;

  /// Creates a new [LayrzSelectInputSurface].
  const LayrzSelectInputSurface({
    super.key,
    required this.items,
    this.selectedItem,
    required this.enableSearch,
    required this.canUnselect,
    this.filter,
    this.emptyListText,
    required this.onItemSelected,
    this.panelController,
    this.query = '',
    required this.itemExtent,
  });

  @override
  State<LayrzSelectInputSurface<T>> createState() => _LayrzSelectInputSurfaceState<T>();
}

class _LayrzSelectInputSurfaceState<T> extends State<LayrzSelectInputSurface<T>> {
  late FocusNode _listFocusNode;
  int _highlightedIndex = -1;
  List<LayrzSelectItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _listFocusNode = FocusNode();
    _updateFilteredItems();
    _setInitialHighlight();

    // The list only claims focus for itself when it is the sole way to navigate
    // (no search field, caller's field is not the searcher): with `enableSearch`
    // true, the caller's own field keeps focus (see `LayrzSelectInput`), and
    // stealing it here would break typing the moment the surface opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && !widget.enableSearch) {
        _listFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(LayrzSelectInputSurface<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query || widget.items != oldWidget.items || widget.filter != oldWidget.filter) {
      _updateFilteredItems();
    }
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    super.dispose();
  }

  /// Updates the filtered items list based on [LayrzSelectInputSurface.query].
  void _updateFilteredItems() {
    final query = widget.enableSearch ? widget.query : '';
    final filter = widget.filter;

    _filteredItems = widget.items.where((item) {
      // Always apply custom filter if provided
      if (filter != null) {
        return filter(query, item);
      }
      // If no custom filter and query is empty, show all
      if (query.isEmpty) {
        return true;
      }
      // Otherwise apply default search filter
      return item.matches(query);
    }).toList();

    // Reset highlight when filter changes
    _highlightedIndex = -1;
  }

  /// Sets the initial highlight to the selected item (or none).
  void _setInitialHighlight() {
    if (widget.selectedItem != null) {
      _highlightedIndex = _filteredItems.indexOf(widget.selectedItem!);
    } else {
      _highlightedIndex = -1;
    }
  }

  /// Handles keyboard events (arrow keys, Enter, Escape).
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < _filteredItems.length - 1) {
          _highlightedIndex++;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = 0;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = _filteredItems.length - 1;
        }
      });
    } else if (key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
        widget.onItemSelected(_filteredItems[_highlightedIndex]);
        widget.panelController?.close();
      }
    } else if (key == LogicalKeyboardKey.escape) {
      if (widget.panelController != null) {
        widget.panelController!.close();
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final tokens = context.tokens;

    // Items list with keyboard support. No search field here anymore -- see the
    // class doc: the caller's own field is the searcher when `enableSearch` is true.
    if (_filteredItems.isEmpty) {
      return Padding(
        padding: tokens.spacing.pd3,
        child: Text(
          widget.emptyListText ?? l10n.selectEmpty,
          style: tokens.typography.body.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      );
    }

    // No height CAP here: the 300px maximum is still applied exactly once, by
    // the caller (`LayrzAnchoredPanel.maxHeight` on desktop, or the bottom
    // sheet's own scrollable on mobile) -- a second, disagreeing cap here is
    // DESIGN-40's original root cause, see `select_input.dart`.
    //
    // A definite height IS given here, though, and that is a different thing:
    // both hosts place this surface inside their own `SingleChildScrollView`,
    // which -- regardless of what height cap it itself receives from above --
    // always relaxes its *child's* incoming height constraint to unbounded
    // along the scroll axis, so the child can be taller than the viewport and
    // still scroll. A `Column` (what this surface built before `ListView`
    // replaced it) tolerates that fine, since its own height is simply the sum
    // of its children's, computable with no bound at all. A `ListView` cannot:
    // as a lazy, non-shrinkWrap viewport it must know its own extent to lay
    // out, and an unbounded incoming height throws (`Vertical viewport was
    // given unbounded height`) before the caller's cap ever gets a chance to
    // clamp anything -- this was a real crash on both the desktop panel and
    // the mobile sheet, not a test-only artifact. Wrapping it in a `SizedBox`
    // sized to its own full, uncapped content height restores exactly the
    // shape `Column` provided implicitly, so the caller's single external cap
    // keeps clamping and scrolling it precisely as it did before.
    // Sizing the `ListView` to its own full content height also makes its own
    // scroll extent zero -- it never needs to scroll on its own, since it is
    // never taller than its own viewport. Left with the default physics, that
    // still leaves it a second same-axis `Scrollable` co-located with the
    // caller's outer one, and a plain drag on that region resolves to whichever
    // of the two wins the gesture arena rather than reliably reaching the
    // caller's scrollable. `NeverScrollableScrollPhysics` removes it from that
    // arena entirely, so the caller's `SingleChildScrollView` is unambiguously
    // the one that scrolls -- exactly as when this was a non-scrollable `Column`.
    return SizedBox(
      height: _filteredItems.length * widget.itemExtent,
      child: KeyboardListener(
        focusNode: _listFocusNode,
        onKeyEvent: _handleKeyEvent,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemExtent: widget.itemExtent,
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            return _SelectItemRow(
              key: ValueKey(_filteredItems[index].value),
              item: _filteredItems[index],
              isHighlighted: _highlightedIndex == index,
              isSelected: _filteredItems[index] == widget.selectedItem,
              onTap: () {
                widget.onItemSelected(_filteredItems[index]);
                widget.panelController?.close();
              },
            );
          },
        ),
      ),
    );
  }
}

/// A single item row in the select input surface.
///
/// Displays the item's [LayrzSelectItem.child] alongside selection/highlight states.
class _SelectItemRow<T> extends StatelessWidget {
  final LayrzSelectItem<T> item;
  final bool isHighlighted;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectItemRow({
    super.key,
    required this.item,
    required this.isHighlighted,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Determine background color: selected or highlighted
    final backgroundColor = isSelected
        ? tokens.colors.primary.withValues(alpha: 0.1)
        : isHighlighted
        ? tokens.colors.fg3.withValues(alpha: 0.1)
        : Color.fromARGB(0, 0, 0, 0);

    return Semantics(
      // No explicit `label` here -- `item.child` is the item's only presentation
      // (BREAKING: `LayrzSelectItem.labelText` is gone), so it is left un-excluded
      // below and its own semantics (a plain `Text`, most commonly) merge upward into
      // this node instead of being replaced by a separate string. A caller whose
      // `child` carries no text semantics of its own (icon-only, a color swatch)
      // announces with no name unless that `child` supplies its own `Semantics(label:)`
      // -- this type no longer owns any text to fall back to.
      button: true,
      selected: isSelected,
      onTap: onTap,
      child: LayrzTappable(
        onTap: onTap,
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sp2,
            vertical: tokens.spacing.sp1,
          ),
          child: Row(
            children: [
              // `item.child` is force-wrapped in its own `DefaultTextStyle`: it must
              // never depend on whatever `DefaultTextStyle` happens to be ambient at
              // its mount point. Left bare, a plain `Text` inside `child` (with no
              // explicit color of its own) resolves `style.color` to `null` whenever
              // there is no real ancestor `DefaultTextStyle` supplying one -- which the
              // rendering engine then paints as solid white, not the theme's body color.
              Expanded(
                child: DefaultTextStyle(
                  style: context.titleStyle,
                  child: item.child,
                ),
              ),

              // Selection indicator
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(left: tokens.spacing.sp2),
                  child: Icon(
                    MdiIcons.check,
                    size: 20,
                    color: tokens.colors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

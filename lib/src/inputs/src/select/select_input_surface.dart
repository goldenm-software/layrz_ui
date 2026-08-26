import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

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

    // No height cap here: the 300px maximum is applied exactly once,
    // by the caller (`LayrzAnchoredPanel.maxHeight` on desktop, or the
    // bottom sheet's own scrollable on mobile). A second, disagreeing
    // cap here is DESIGN-40's root cause -- see `select_input.dart`.
    return KeyboardListener(
      focusNode: _listFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_filteredItems.length, (index) {
          final item = _filteredItems[index];
          final isHighlighted = _highlightedIndex == index;
          final isSelected = item.value == widget.selectedItem?.value;

          return _SelectItemRow(
            key: ValueKey(item.value),
            item: item,
            isHighlighted: isHighlighted,
            isSelected: isSelected,
            onTap: () {
              widget.onItemSelected(item);
              widget.panelController?.close();
            },
          );
        }),
      ),
    );
  }
}

/// A single item row in the select input surface.
///
/// Displays the item with optional custom rendering and selection/highlight states.
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
      // and its own semantics (if it has any, e.g. a plain `Text`) merge upward into
      // this node instead of being replaced by a separate string. A caller whose
      // `child` carries no text semantics of its own (icon-only, a color swatch)// announces with no name unless that `child` supplies its own `Semantics(label:)` --
      // this type no longer owns any text to fall back to.
      button: true,
      selected: isSelected,
      onTap: onTap,
      child: GestureDetector(
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
              // there is no real ancestor `DefaultTextStyle` supplying one -- which
              // the rendering engine then paints as solid white, not the theme's
              // body color. See the regression test for this exact failure mode.
              Expanded(
                child: DefaultTextStyle(
                  style: tokens.typography.body,
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

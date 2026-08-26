import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';

/// The selection surface content used by [LayrzSelectInput].
///
/// This widget renders its own search field (when [enableSearch] is true) followed by
/// a scrollable list of items, and manages keyboard navigation (arrow keys, Enter,
/// Escape) and item selection.
///
/// **Search ownership (DESIGN-145, reverting part of DESIGN-40/144):** this surface now
/// owns its own search text state again -- it is no longer fed a [query] from the
/// caller. This follows from the "elevated field" redesign in [LayrzSelectInput]: since
/// the surface is now presented as a floating card that covers [LayrzSelectInput]'s own
/// field, that underlying field is never the searcher (and never needs focus while the
/// surface is open) -- typing happens in this surface's own internal search field
/// instead, which is what removes the focus fight DESIGN-40/144 was fighting in the
/// first place, without bringing the fight back.
///
/// This is a private implementation detail; consumers use [LayrzSelectInput] instead.
class LayrzSelectInputSurface<T> extends StatefulWidget {
  /// The list of items to display.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected item (for visual highlighting).
  final LayrzSelectItem<T>? selectedItem;

  /// Whether this surface renders its own search field above the list.
  ///
  /// When true, a search field is rendered at the top of the surface and typing into
  /// it filters the list live. When false, no search field is rendered and the list
  /// shows every item, unfiltered.
  final bool enableSearch;

  /// Whether an item with `value: null` can be selected.
  final bool canUnselect;

  /// Optional custom filter function; if null, uses [LayrzSelectItem.matches].
  ///
  /// Applied regardless of whether the search text is empty -- an empty query still
  /// runs through this callback rather than short-circuiting to "show all".
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
    required this.itemExtent,
  });

  @override
  State<LayrzSelectInputSurface<T>> createState() => _LayrzSelectInputSurfaceState<T>();
}

class _LayrzSelectInputSurfaceState<T> extends State<LayrzSelectInputSurface<T>> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late FocusNode _listFocusNode;
  final Set<WidgetState> _searchStates = {};
  int _highlightedIndex = -1;
  List<LayrzSelectItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _listFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _updateFilteredItems();
    _setInitialHighlight();

    // Whichever of the search field or the plain list is the way to type/navigate
    // gets focus once the surface is actually visible. Double-nested: when this
    // surface is presented inside `LayrzAnchoredPanel`, that panel's own
    // `_handlePanelOpenRequested` registers a *second* post-frame callback (after
    // this widget has already mounted and registered its first one) that steals
    // focus to its own wrapping `_panelFocusNode` -- a single post-frame callback
    // here would win the race backwards (fire first, get stolen from one tick
    // later). Nesting a second callback inside the first pushes this request to
    // the frame *after* that steal, so it reliably wins. Harmless extra one-frame
    // delay on hosts with no such steal (e.g. the mobile bottom sheet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.enableSearch) {
          _searchFocusNode.requestFocus();
        } else {
          _listFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void didUpdateWidget(LayrzSelectInputSurface<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items || widget.filter != oldWidget.filter) {
      setState(_updateFilteredItems);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  /// Tracks focus on the internal search field, purely for its own visual state
  /// (hover/focus colors resolved by [LayrzInputChrome]).
  void _handleSearchFocusChanged() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _searchStates.add(WidgetState.focused);
      } else {
        _searchStates.remove(WidgetState.focused);
      }
    });
  }

  /// Handles a genuine edit to the internal search field's text.
  void _handleSearchChanged(String text) {
    setState(_updateFilteredItems);
  }

  /// Updates the filtered items list based on the internal search text.
  void _updateFilteredItems() {
    final query = widget.enableSearch ? _searchController.text : '';
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
  ///
  /// Bound to a [Focus] wrapping the *entire* surface (search field and list alike,
  /// see [build]), so this fires via bubbling regardless of whether the search field
  /// or nothing currently holds primary focus.
  ///
  /// **Must return [KeyEventResult.handled] for Escape, not merely act on it.** A
  /// bare [KeyboardListener] (which this used to be) never marks an event handled,
  /// so it always keeps bubbling upward -- on mobile, past this surface's own
  /// `Navigator.pop(context)`, into the framework's own default Escape-to-dismiss
  /// shortcut, which then pops a *second* time. With nothing left on the stack to
  /// distinguish "the sheet" from "the app", that second pop tore down the entire
  /// test app, not just this surface. Harmless before this surface grew its own
  /// search field (nothing here had focus for `enableSearch: true`, so this handler
  /// never ran at all in that combination) -- but a real, reachable bug once the
  /// search field is a focus descendant of this node on every `enableSearch` value.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < _filteredItems.length - 1) {
          _highlightedIndex++;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = 0;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else if (_filteredItems.isNotEmpty) {
          _highlightedIndex = _filteredItems.length - 1;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
        widget.onItemSelected(_filteredItems[_highlightedIndex]);
        widget.panelController?.close();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    } else if (key == LogicalKeyboardKey.escape) {
      if (widget.panelController != null) {
        widget.panelController!.close();
      } else {
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Builds the internal search field row, shown above the list when
  /// [LayrzSelectInputSurface.enableSearch] is true.
  ///
  /// Deliberately borderless ([LayrzInputChrome.showBorder] false): the border that
  /// sells the "elevated field" illusion belongs to the floating card as a whole
  /// (drawn by [LayrzSelectInput] around this entire surface), not to this row on
  /// its own -- a second, inner border here would read as two competing fields
  /// instead of one continuous surface.
  Widget _buildSearchField(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);

    final fieldConfig = LayrzEditableFieldConfig(
      labelText: null,
      hintText: l10n.selectSearch,
      disabled: false,
      readOnly: false,
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _handleSearchChanged,
      onSubmit: null,
      onFocusChanged: null,
      onTap: null,
      keyboardType: TextInputType.text,
      textInputAction: null,
      inputFormatters: const [],
      maxLength: null,
      autofocus: false,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: false,
      enableSuggestions: false,
      actions: null,
      minLines: 1,
      maxLines: 1,
      expands: false,
    );

    return LayrzInputChrome(
      labelText: null,
      hintText: l10n.selectSearch,
      isRequired: false,
      prefixSlot: resolvePrefixSlot(prefixIcon: MdiIcons.magnify, isDecorative: true),
      suffixSlot: resolveSuffixSlot(
        suffixIcon: _searchController.text.isNotEmpty ? MdiIcons.close : null,
        onSuffixTap: _searchController.text.isNotEmpty
            ? () {
                _searchController.clear();
                setState(_updateFilteredItems);
              }
            : null,
        semanticLabel: _searchController.text.isNotEmpty ? l10n.inputsSearchClear : null,
      ),
      disabled: false,
      readOnly: false,
      errors: const [],
      hideDetails: true,
      states: _searchStates,
      controller: _searchController,
      showBorder: false,
      borderRadius: BorderRadius.zero,
      child: LayrzEditableField(config: fieldConfig),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final tokens = context.tokens;

    final Widget listOrEmptyState;
    if (_filteredItems.isEmpty) {
      listOrEmptyState = Padding(
        padding: tokens.spacing.pd3,
        child: Text(
          widget.emptyListText ?? l10n.selectEmpty,
          style: tokens.typography.label,
        ),
      );
    } else {
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
      listOrEmptyState = SizedBox(
        height: _filteredItems.length * widget.itemExtent,
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
      );
    }

    // `Focus`, not `KeyboardListener`: `_handleKeyEvent` must be able to mark
    // Escape/Enter/arrows as `handled` (see its own doc comment) to stop them from
    // also reaching the framework's default shortcuts above this. Wraps the WHOLE
    // column (search field and list alike), not just the list: when `enableSearch`
    // is true, `_searchFocusNode` (a descendant of `_listFocusNode`'s `Focus` node)
    // holds primary focus, and key events bubble up through their focus ancestor
    // chain -- which includes this node -- reaching `_handleKeyEvent` regardless of
    // which child actually has focus. `skipTraversal: true` keeps `_listFocusNode`
    // itself out of Tab order (it is never meant to be a stop on its own -- only
    // the search field, or a direct `.requestFocus()` call, ever holds it).
    return Focus(
      focusNode: _listFocusNode,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableSearch) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
              child: _buildSearchField(context),
            ),
            Container(height: 1, color: tokens.colors.divider),
          ],
          listOrEmptyState,
        ],
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
                  style: context.bodyStyle,
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

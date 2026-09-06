import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import '../../../inputs/src/shared/editable_field.dart';
import '../../../inputs/src/shared/input_chrome.dart';
import '../../../inputs/src/shared/input_slot.dart';

/// The selection surface content used by [LayrzMultiSelectInput].
///
/// This widget renders a search field followed by a scrollable list of
/// items, each carrying a per-row selected-state indicator. Unlike
/// [LayrzSelectInputSurface] (which commits on tap and closes), this surface
/// mutates only its own internal draft — see the class doc's **staged-with-
/// Save** section for the full contract.
///
/// **staged-with-Save (Decision, deliberate divergence from
/// `ThemedMultiSelectInput`'s per-tap default):** tapping a row toggles that
/// item in [_draft] only — it neither calls [onDraftCommitted] nor closes the
/// surface. The caller ([LayrzMultiSelectInput]) hosts this surface inside a
/// [LayrzEndDrawer]/[LayrzBottomSheet] with a Cancel/Select-All(Unselect-
/// All)/Save actions row built from [draftSelection] (see
/// [LayrzMultiSelectInput]'s own class doc for why this diverges from
/// `layrz_theme`'s `ThemedMultiSelectInput`, which fires `onChanged` on every
/// tap by default). Save reads the current [_draft] via [save] and calls
/// [onDraftCommitted] with it; Cancel simply closes the hosting surface
/// without calling [save] at all, discarding [_draft] entirely.
///
/// **Select-All / Unselect-All mutate the draft only**, exactly like a row
/// tap — see [selectAll] and [unselectAll], both called by
/// [LayrzMultiSelectInput] through a [GlobalKey], mirroring how the
/// date/time pickers reach their own surface state.
///
/// This is a private implementation detail; consumers use
/// [LayrzMultiSelectInput] instead.
class LayrzMultiSelectInputSurface<T> extends StatefulWidget {
  /// The list of items to display.
  final List<LayrzSelectItem<T>> items;

  /// The values selected when the surface was opened.
  ///
  /// Seeds the internal draft (see [LayrzMultiSelectInputSurfaceState._draft])
  /// — this surface never mutates [initialValues] itself, it only ever reads
  /// it once, in [State.initState]/[State.didUpdateWidget].
  final List<T> initialValues;

  /// Whether this surface renders its own search field above the list.
  final bool enableSearch;

  /// Optional custom filter function; if null, uses [LayrzSelectItem.matches].
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text shown when search finds no matching items.
  final String? emptyListText;

  /// Called on every draft mutation (a row tap, Select All, or Unselect
  /// All), so [LayrzMultiSelectInput] can refresh the `actions` row it
  /// builds outside this surface. Never called with the committed value —
  /// see [onDraftCommitted] for that.
  final VoidCallback? onDraftChanged;

  /// Called with the drafted list of values when the user presses Save.
  ///
  /// Invoked from [save], which [LayrzMultiSelectInput] calls through a
  /// [GlobalKey] when its own Save action fires. Never called for Cancel or
  /// any other dismissal — those discard [_draft] without calling this.
  final ValueChanged<List<T>> onDraftCommitted;

  /// Defines the expected height of each item in the list.
  final double itemExtent;

  /// Creates a new [LayrzMultiSelectInputSurface].
  const LayrzMultiSelectInputSurface({
    super.key,
    required this.items,
    required this.initialValues,
    required this.enableSearch,
    this.filter,
    this.emptyListText,
    this.onDraftChanged,
    required this.onDraftCommitted,
    required this.itemExtent,
  });

  @override
  State<LayrzMultiSelectInputSurface<T>> createState() => LayrzMultiSelectInputSurfaceState<T>();
}

/// State for [LayrzMultiSelectInputSurface].
///
/// **Public, not library-private, so [LayrzMultiSelectInput] can reach it
/// through a [GlobalKey]** — mirrors `LayrzDateSurfaceState`'s identical
/// pattern (`date_surface.dart`) exactly. [canSave], [hasSelection],
/// [selectAll], [unselectAll], and [save] are the surface of the draft that
/// the input reads and drives from its own `actions` row.
class LayrzMultiSelectInputSurfaceState<T> extends State<LayrzMultiSelectInputSurface<T>> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late FocusNode _listFocusNode;
  final Set<WidgetState> _searchStates = {};
  int _highlightedIndex = -1;
  List<LayrzSelectItem<T>> _filteredItems = [];

  /// The tapped-but-unsaved set of selected values.
  ///
  /// Seeded from [LayrzMultiSelectInputSurface.initialValues] in [initState]
  /// and re-seeded on an involuntary external value change (see
  /// [didUpdateWidget]). A [Set] rather than a [List] so toggling membership
  /// is O(1) and order-independent — the surface's own row order (from
  /// [LayrzMultiSelectInputSurface.items]) is what [save] reports back in,
  /// not draft-mutation order.
  late Set<T> _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValues.toSet();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _listFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _updateFilteredItems();

    // Syncs the caller's external draft-state mirror immediately, mirroring
    // `LayrzDateSurfaceState`'s identical `initState` comment: the caller's
    // `ValueNotifier` seed already reflects `initialValues` (see
    // `LayrzMultiSelectInput._openDesktopDrawer`'s own seeding), so this is
    // a no-op refresh in the common case and a real correction the one time
    // it is not.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onDraftChanged?.call();
        if (widget.enableSearch) {
          _searchFocusNode.requestFocus();
        } else {
          _listFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void didUpdateWidget(LayrzMultiSelectInputSurface<T> oldWidget) {
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

  /// Whether at least one row is currently selected in the draft. Read by
  /// [LayrzMultiSelectInput] through a [GlobalKey] to decide the label
  /// ("Select all" vs "Unselect all") and gate Save.
  bool get hasSelection => _draft.isNotEmpty;

  /// Whether Save is reachable. Always true for multi-select — an empty
  /// selection (clearing every value) is itself a valid commit, unlike the
  /// single-date surface's `canSave` (which gates on "a date was ever
  /// tapped"). Kept as a getter (not a hardcoded `true` at the call site) so
  /// [LayrzMultiSelectInput] reads it the same uniform way every other
  /// picker surface's `canSave` is read.
  bool get canSave => true;

  /// Toggles [value]'s membership in the draft, without committing or
  /// closing. Wired to each row's tap handler.
  void _toggle(T value) {
    setState(() {
      if (_draft.contains(value)) {
        _draft.remove(value);
      } else {
        _draft.add(value);
      }
    });
    widget.onDraftChanged?.call();
  }

  /// Mutates the draft to every non-null value in
  /// [LayrzMultiSelectInputSurface.items] — the draft only, never
  /// [LayrzMultiSelectInputSurface.onDraftCommitted]. Called by
  /// [LayrzMultiSelectInput] through a [GlobalKey] when the actions row's
  /// "Select all" is pressed.
  void selectAll() {
    setState(() {
      _draft = {
        for (final item in widget.items)
          if (item.value != null) item.value as T,
      };
    });
    widget.onDraftChanged?.call();
  }

  /// Empties the draft — the draft only, mirroring [selectAll]. Called by
  /// [LayrzMultiSelectInput] through a [GlobalKey] when the actions row's
  /// "Unselect all" is pressed.
  void unselectAll() {
    setState(_draft.clear);
    widget.onDraftChanged?.call();
  }

  /// Commits the current draft via
  /// [LayrzMultiSelectInputSurface.onDraftCommitted], in
  /// [LayrzMultiSelectInputSurface.items]' own order. Invoked by
  /// [LayrzMultiSelectInput] through a [GlobalKey] when the actions row's
  /// Save is pressed. Never called by a row tap, Select All, or Unselect All
  /// directly — those mutate [_draft] only (see the class doc).
  void save() {
    final ordered = [
      for (final item in widget.items)
        if (item.value != null && _draft.contains(item.value as T)) item.value as T,
    ];
    widget.onDraftCommitted(ordered);
  }

  /// Tracks focus on the internal search field, purely for its own visual
  /// state (hover/focus colors resolved by [LayrzInputChrome]).
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
      if (filter != null) {
        return filter(query, item);
      }
      if (query.isEmpty) {
        return true;
      }
      return item.matches(query);
    }).toList();

    _highlightedIndex = -1;
  }

  /// Handles keyboard events (arrow keys, Enter, Escape).
  ///
  /// Mirrors `LayrzSelectInputSurface._handleKeyEvent` exactly, except Enter
  /// toggles the highlighted row's draft membership instead of committing
  /// and closing — consistent with the tap handler on the same row (see the
  /// class doc's staged-with-Save section). Escape must return
  /// [KeyEventResult.handled], not merely act on it — see that method's own
  /// doc comment for the double-pop bug this avoids.
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
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
        final value = _filteredItems[_highlightedIndex].value;
        if (value != null) _toggle(value);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    } else if (key == LogicalKeyboardKey.escape) {
      LayrzModalRoute.popIfCurrent(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Builds the internal search field row, shown above the list when
  /// [LayrzMultiSelectInputSurface.enableSearch] is true. Deliberately
  /// borderless — mirrors `LayrzSelectInputSurface._buildSearchField`
  /// exactly, see that method's own doc for why.
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
      // No height cap here -- see `LayrzSelectInputSurface`'s identical
      // class-level doc for why the 300px maximum is the caller's concern,
      // and why the `ListView` still needs a definite `SizedBox` height and
      // `NeverScrollableScrollPhysics` regardless of that cap living
      // elsewhere.
      listOrEmptyState = SizedBox(
        height: _filteredItems.length * widget.itemExtent,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemExtent: widget.itemExtent,
          itemCount: _filteredItems.length,
          itemBuilder: (context, index) {
            final item = _filteredItems[index];
            final isSelected = item.value != null && _draft.contains(item.value as T);
            return _MultiSelectItemRow<T>(
              key: ValueKey(item.value),
              item: item,
              isHighlighted: _highlightedIndex == index,
              isSelected: isSelected,
              onTap: item.value == null ? null : () => _toggle(item.value as T),
            );
          },
        ),
      );
    }

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

/// A single item row in the multi-select surface.
///
/// Displays the item's [LayrzSelectItem.child] alongside its own
/// draft-selected/highlight state — mirrors `_SelectItemRow` from
/// `select_input_surface.dart`, except [isSelected] here reflects the
/// surface's own [Set]-backed draft rather than a single committed value.
class _MultiSelectItemRow<T> extends StatelessWidget {
  /// The item this row renders.
  final LayrzSelectItem<T> item;

  /// Whether this row is the keyboard-navigated highlight target.
  final bool isHighlighted;

  /// Whether this row's value is a member of the current draft.
  final bool isSelected;

  /// Called when the row is tapped, toggling its draft membership. Null
  /// when [item]'s value is null (an item with a null value can never be a
  /// member of a `Set<T>` draft where `T` is non-nullable at the call site).
  final VoidCallback? onTap;

  /// Creates a new [_MultiSelectItemRow].
  const _MultiSelectItemRow({
    super.key,
    required this.item,
    required this.isHighlighted,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final backgroundColor = isSelected
        ? tokens.colors.primary.withValues(alpha: 0.1)
        : isHighlighted
        ? tokens.colors.fg3.withValues(alpha: 0.1)
        : const Color(0x00000000);

    return Semantics(
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
              Expanded(
                child: DefaultTextStyle(
                  style: context.bodyStyle,
                  child: item.child,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: tokens.spacing.sp2),
                child: Icon(
                  isSelected ? MdiIcons.checkboxMarkedOutline : MdiIcons.checkboxBlankOutline,
                  size: 20,
                  color: isSelected ? tokens.colors.primary : tokens.colors.fg3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

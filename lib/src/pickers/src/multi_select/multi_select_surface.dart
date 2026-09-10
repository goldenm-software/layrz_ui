import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tabs/tabs.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import '../../../inputs/src/shared/editable_field.dart';
import '../../../inputs/src/shared/input_chrome.dart';
import '../../../inputs/src/shared/input_slot.dart';
import '../shared/picker_dialog_header.dart';

/// Which partition of items [LayrzMultiSelectInputSurface] is currently
/// showing in its list.
///
/// Formerly declared alongside the now-removed `LayrzMultiSelectTabStrip` (a
/// hand-rolled tab bar); it now lives here since [LayrzMultiSelectInputSurface]
/// is this enum's only owner, having replaced that strip with a strip-only
/// [LayrzTabView] (see the class doc's tab section).
enum LayrzMultiSelectTab {
  /// Every (search-filtered) item, regardless of draft membership.
  all,

  /// Only the items currently present in the surface's draft.
  selected,
}

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
/// surface. The caller ([LayrzMultiSelectInput]) hosts this surface via
/// [LayrzResponsiveModal.show] (a dialog or a [LayrzBottomSheet]) with a
/// Cancel/Select-All(Unselect-All)/Save actions row built from
/// [draftSelection] (see
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
/// **"All (count)" / "Selected (count)" tabs (DESIGN-43).** A [LayrzTabView]
/// sits between the header divider and the scrolling list, switching which
/// partition of [_filteredItems] the list shows: [LayrzMultiSelectTab.all]
/// shows every (search-filtered) item, [LayrzMultiSelectTab.selected] shows
/// only the ones currently in [_draft]. This is a **light re-filter of the
/// one existing `ListView`**, not a second content tree — [LayrzTabView] is
/// used **strip-only** here: both its [LayrzTab] entries carry a
/// `SizedBox.shrink()` child (so the tab view renders no content of its
/// own, `contentGap: 0` suppresses the gap it would otherwise leave for that
/// empty child) and [_visibleItems] — not [LayrzTabView] — is what actually
/// re-filters the surface's single, always-mounted `ListView`. Both counts
/// are live and update on every draft mutation and every search keystroke,
/// since the tab labels are computed fresh from [_filteredItems] and
/// [_draft] on every [build] (see [_visibleItems]).
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

  /// The title shown in this surface's own [LayrzPickerDialogHeader], normally
  /// [LayrzMultiSelectInput.labelText]. `null` renders an empty title slot
  /// rather than no header at all — see that widget's own doc.
  final String? labelText;

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
    this.labelText,
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

  /// Which partition of [_filteredItems] the list currently shows — see the
  /// class doc's tab-strip section. Defaults to [LayrzMultiSelectTab.all].
  LayrzMultiSelectTab _activeTab = LayrzMultiSelectTab.all;

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

  /// The rows the list actually renders: [_filteredItems] (already narrowed
  /// by search) further narrowed to [_activeTab]'s partition.
  ///
  /// [LayrzMultiSelectTab.all] passes every filtered item through unchanged;
  /// [LayrzMultiSelectTab.selected] keeps only the ones already in [_draft].
  /// This is what the [ListView.builder], keyboard navigation, and the
  /// empty-state check in [build] all read — never [_filteredItems] directly
  /// once a tab exists.
  List<LayrzSelectItem<T>> get _visibleItems {
    if (_activeTab == LayrzMultiSelectTab.all) return _filteredItems;
    return _filteredItems.where((item) => item.value != null && _draft.contains(item.value as T)).toList();
  }

  /// Switches [_activeTab] and resets keyboard highlight, since the
  /// highlighted index no longer necessarily points at the same row once the
  /// visible partition changes.
  void _handleTabChanged(LayrzMultiSelectTab tab) {
    if (tab == _activeTab) return;
    setState(() {
      _activeTab = tab;
      _highlightedIndex = -1;
    });
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

    final visibleItems = _visibleItems;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_highlightedIndex < visibleItems.length - 1) {
          _highlightedIndex++;
        } else if (visibleItems.isNotEmpty) {
          _highlightedIndex = 0;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
        } else if (visibleItems.isNotEmpty) {
          _highlightedIndex = visibleItems.length - 1;
        }
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_highlightedIndex >= 0 && _highlightedIndex < visibleItems.length) {
        final value = visibleItems[_highlightedIndex].value;
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

  /// Builds the internal search field, rendered inline in the header row
  /// (title | dense search | X) when [LayrzMultiSelectInputSurface.enableSearch]
  /// is true — see [build]'s own doc for the pinned-header layout this feeds.
  /// Deliberately borderless and `dense: true` — mirrors
  /// `LayrzSelectInputSurface._buildSearchField`'s borderless reasoning, plus
  /// the dense density so the field is compact enough to sit inline between
  /// the title and the close button.
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
      dense: true,
      child: LayrzEditableField(config: fieldConfig),
    );
  }

  /// Builds this surface's content.
  ///
  /// **Pinned header + search, scrolling list only (maintainer review).**
  /// Restructured from a single `Column` that let its item list grow to its
  /// own full, uncapped height (relying entirely on an outer host to cap and
  /// scroll it — see the removed height-cap comment this replaced) into a
  /// `Column` of exactly three parts: the header row (never scrolls), an
  /// [Expanded] `ListView` (the only scrolling region), and nothing else —
  /// this surface has no actions row of its own (see
  /// [LayrzMultiSelectInput._openPicker], which pins its Cancel/Select-All/
  /// Save row outside this widget entirely, via
  /// [LayrzResponsiveModal.show]'s own `actions` parameter). This requires a
  /// bounded incoming height (an [Expanded] only works inside one), which
  /// [LayrzMultiSelectInput._openPicker] now supplies directly via a bigger
  /// [LayrzDialogConfig] (dialog branch) and `scrollable: false` (sheet
  /// branch) — see that method's own doc for why the previous
  /// `ConstrainedBox(maxHeight: 300)` + `SingleChildScrollView` pairing is
  /// gone.
  ///
  /// **Search moved into the header row itself (title | dense search | X),**
  /// via [LayrzPickerDialogHeader.middleSlot] — see that parameter's own doc.
  /// The search field is always visible while the list scrolls underneath it,
  /// rather than scrolling away with the list the way a search row placed
  /// above the list inside the same scrollable would.
  ///
  /// **"All (count)" / "Selected (count)" tab strip (DESIGN-43)** sits
  /// between the header divider and the scrolling list, as its own fixed
  /// (never-scrolling) row — see [_visibleItems] and the class doc's tab
  /// section for how it re-filters the one `ListView` rather than swapping
  /// content trees.
  @override
  Widget build(BuildContext context) {
    final l10n = LayrzUiL10n.of(context);
    final tokens = context.tokens;
    final visibleItems = _visibleItems;

    final Widget listOrEmptyState;
    if (visibleItems.isEmpty) {
      listOrEmptyState = Padding(
        padding: tokens.spacing.pd3,
        child: Text(
          widget.emptyListText ?? l10n.selectEmpty,
          style: tokens.typography.label,
        ),
      );
    } else {
      listOrEmptyState = ListView.builder(
        padding: EdgeInsets.zero,
        itemExtent: widget.itemExtent,
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          final isSelected = item.value != null && _draft.contains(item.value as T);
          return _MultiSelectItemRow<T>(
            key: ValueKey(item.value),
            item: item,
            isHighlighted: _highlightedIndex == index,
            isSelected: isSelected,
            onTap: item.value == null ? null : () => _toggle(item.value as T),
          );
        },
      );
    }

    return Focus(
      focusNode: _listFocusNode,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2),
            child: LayrzPickerDialogHeader(
              labelText: widget.labelText,
              onClose: () => LayrzModalRoute.popIfCurrent(context),
              middleSlot: widget.enableSearch ? _buildSearchField(context) : null,
            ),
          ),
          Container(height: 1, color: tokens.colors.divider),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
            child: LayrzTabView(
              // Strip-only usage (see the class doc): both tabs carry an
              // empty `child` and `contentGap: 0` suppresses the gap
              // `LayrzTabView` would otherwise leave beneath the strip for
              // that (never-rendered) content. `initialIndex` seeds the
              // strip's own internal selection from `_activeTab` on first
              // mount only -- `_handleTabChanged` (via `onTabChanged`) is
              // what keeps them in agreement afterward, mirroring how every
              // other `LayrzTabView` caller owns the source of truth outside
              // the widget.
              isScrollable: false,
              contentGap: 0,
              initialIndex: _activeTab == LayrzMultiSelectTab.all ? 0 : 1,
              onTabChanged: (index) =>
                  _handleTabChanged(index == 0 ? LayrzMultiSelectTab.all : LayrzMultiSelectTab.selected),
              tabs: [
                LayrzTab(labelText: l10n.multiSelectTabAll(_filteredItems.length), child: const SizedBox.shrink()),
                LayrzTab(labelText: l10n.multiSelectTabSelected(_draft.length), child: const SizedBox.shrink()),
              ],
            ),
          ),
          Expanded(child: listOrEmptyState),
        ],
      ),
    );
  }
}

/// A single item row in the multi-select surface.
///
/// Displays the item's [LayrzSelectItem.child] alongside a real
/// [LayrzCheckboxInput] reflecting its own draft-selected/highlight state —
/// mirrors `_SelectItemRow` from `select_input_surface.dart`, except
/// [isSelected] here reflects the surface's own [Set]-backed draft rather
/// than a single committed value, and the selection indicator is an actual
/// checkbox control (maintainer review), not a check/blank icon pair.
///
/// **Both the checkbox and the row tap toggle selection.** [onTap] already
/// fires on any tap within the row (see [build]'s [LayrzTappable]); the
/// checkbox's own `onChanged` is wired to the same callback rather than a
/// second, independent toggle path, so tapping either the row or the
/// checkbox itself always agrees on the resulting state.
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
                // `IgnorePointer`: the row's own `LayrzTappable.onTap` above
                // already toggles selection for a tap anywhere in the row,
                // checkbox included -- a second, independent tap target here
                // would fight that gesture rather than compose with it (see
                // this class's own doc). The checkbox's `onChanged` is not
                // wired at all for the same reason; its `value` is purely a
                // reflection of [isSelected], never itself a trigger.
                child: IgnorePointer(
                  child: LayrzCheckboxInput(
                    value: isSelected,
                    onChanged: (_) {},
                    hideDetails: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

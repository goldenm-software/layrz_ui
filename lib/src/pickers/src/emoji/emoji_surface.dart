import 'package:emojis/emoji.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';
import 'package:layrz_ui/src/tabs/tabs.dart';

import '../shared/glyph_grid.dart';
import '../shared/glyph_grid_keyboard.dart';
import '../shared/picker_dialog_header.dart';

/// The number of grid columns rendered per row of emoji cells.
///
/// A fixed column count (rather than one derived from the surface's own
/// width) keeps cell size predictable across the [LayrzBottomSheet] and the
/// dialog branch of `LayrzResponsiveModal.show`, both of which already constrain this surface to a
/// known width band — mirroring how `LayrzPickersDayGrid` fixes its own
/// 7-column count rather than deriving it.
const int _kEmojiGridColumns = 8;

/// The side length, in logical pixels, of each emoji cell — sized to make a
/// glyph comfortably tappable and legible without being decided by
/// `LayrzGlyphGrid`'s own smaller default (`40.0`), which reads slightly
/// cramped for an emoji character at this surface's typical width.
const double _kEmojiCellExtent = 44.0;

/// One entry in this surface's group-filter row: either "All emoji" (no
/// [group]) or one specific [EmojiGroup], paired with its localized [label].
///
/// A private, file-local record-like class rather than a bare
/// `(EmojiGroup?, String)` tuple, so [_EmojiGroupFilter.label] and
/// [_EmojiGroupFilter.group] read as named fields at every call site below.
class _EmojiGroupFilter {
  /// The group this entry filters to, or `null` for "All emoji" (no group
  /// filter applied).
  final EmojiGroup? group;

  /// The localized label shown for this entry in the filter row.
  final String label;

  /// Creates a new [_EmojiGroupFilter].
  const _EmojiGroupFilter({required this.group, required this.label});
}

/// Builds the ten [EmojiGroup]-backed entries plus a leading "All emoji"
/// entry, in [EmojiGroup]'s own declaration order — matching the order the
/// `emojis` package itself declares the enum in, so the filter row reads in
/// the same sequence a caller skimming the package source would expect.
///
/// `EmojiGroup.component` (skin-tone/hair-style modifier building blocks) is
/// deliberately included for completeness — see
/// [LayrzUiL10nEmojiPickerMixin.emojiPickerGroupComponent]'s own doc — even
/// though this surface never renders modified variants (skin-tone is out of
/// scope for v1, per the implementation plan).
List<_EmojiGroupFilter> _buildGroupFilters(LayrzUiL10n l10n) {
  return [
    _EmojiGroupFilter(group: null, label: _kAllEmojiLabel),
    _EmojiGroupFilter(group: EmojiGroup.smileysEmotion, label: l10n.emojiPickerGroupSmileysEmotion),
    _EmojiGroupFilter(group: EmojiGroup.peopleBody, label: l10n.emojiPickerGroupPeopleBody),
    _EmojiGroupFilter(group: EmojiGroup.animalsNature, label: l10n.emojiPickerGroupAnimalsNature),
    _EmojiGroupFilter(group: EmojiGroup.foodDrink, label: l10n.emojiPickerGroupFoodDrink),
    _EmojiGroupFilter(group: EmojiGroup.travelPlaces, label: l10n.emojiPickerGroupTravelPlaces),
    _EmojiGroupFilter(group: EmojiGroup.activities, label: l10n.emojiPickerGroupActivities),
    _EmojiGroupFilter(group: EmojiGroup.objects, label: l10n.emojiPickerGroupObjects),
    _EmojiGroupFilter(group: EmojiGroup.symbols, label: l10n.emojiPickerGroupSymbols),
    _EmojiGroupFilter(group: EmojiGroup.flags, label: l10n.emojiPickerGroupFlags),
    _EmojiGroupFilter(group: EmojiGroup.component, label: l10n.emojiPickerGroupComponent),
  ];
}

/// The literal "All emoji" filter label. Not part of
/// [LayrzUiL10nEmojiPickerMixin] (U1's namespace has no such getter), so this
/// is a plain English constant — mirrored by every other picker surface's
/// occasional literal string for a concept the shared l10n namespace does not
/// carry (e.g. `select_input_surface.dart`'s reuse of existing getters only
/// where they already exist).
const String _kAllEmojiLabel = 'All emoji';

/// The surface content for [LayrzEmojiInput]: a group-filter row, a search
/// field, and a [LayrzGlyphGrid] of [Emoji] entries.
///
/// **Commit-on-tap.** Unlike the Save-carrying date/month/time surfaces in
/// this module, tapping an emoji cell both commits the pick (via
/// [onEmojiSelected]) and is expected to close the hosting
/// [LayrzBottomSheet] or dialog surface immediately — this surface renders no
/// Cancel/Save footer of its own and takes no [onDraftChanged] callback,
/// because there is no in-progress draft to track: a tap is the entire
/// interaction, mirroring how `layrz_theme`'s `ThemedEmojiPicker` and the
/// user's own explicit ruling (see the work-unit brief) both treat "commit
/// on tap, no Save row" as this picker's contract.
///
/// **Search (v1, not optional).** [Emoji.shortName] and [Emoji.keywords] are
/// both matched, case-insensitively, against the search field's text — see
/// [_matchesQuery]. Applied on top of whichever group filter is currently
/// selected, so "search within a group" and "search across all emoji" both
/// fall out of the same filter pipeline (search first narrows within
/// [_selectedGroup]'s own emoji list; see [_filteredEmoji]).
///
/// **No skin-tone variants.** [Emoji.modifiable] and `Emoji.modify` are never
/// consulted — every cell renders exactly [Emoji.char] as authored by the
/// `emojis` package, with no per-tone expansion. Out of scope for this batch
/// (see the implementation plan's "skin-tone out" ruling).
class LayrzEmojiSurface extends StatefulWidget {
  /// The title shown in this surface's own [LayrzPickerDialogHeader], normally
  /// [LayrzEmojiInput.labelText]. `null` renders an empty title slot rather
  /// than no header at all — see that widget's own doc.
  final String? labelText;

  /// Called with the tapped emoji's raw character when the user picks one.
  /// The caller is expected to close the hosting surface immediately after
  /// this fires (see [LayrzEmojiInput]'s own open methods).
  final ValueChanged<String> onEmojiSelected;

  /// Creates a new [LayrzEmojiSurface].
  const LayrzEmojiSurface({super.key, this.labelText, required this.onEmojiSelected});

  @override
  State<LayrzEmojiSurface> createState() => LayrzEmojiSurfaceState();
}

/// The [State] for [LayrzEmojiSurface] — public so a caller (mirroring the
/// date/month surfaces' own `GlobalKey<...State>` convention, even though
/// this surface currently exposes no externally-invoked method) can attach a
/// [GlobalKey] to it without a private-type analyzer warning, should a future
/// caller need to reach into it.
class LayrzEmojiSurfaceState extends State<LayrzEmojiSurface> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Set<WidgetState> _searchStates = {};

  /// The currently selected group filter, or `null` for "All emoji" — the
  /// index into [_buildGroupFilters]'s own list is not tracked separately
  /// because [EmojiGroup] values are already distinct and comparable.
  EmojiGroup? _selectedGroup;

  /// The memoized result of [_computeFilteredEmoji], recomputed only when
  /// [_selectedGroup] or the search text actually changes (see
  /// [_recomputeFilteredEmoji]) rather than on every `build()`.
  ///
  /// Without this cache, [build] re-ran `Emoji.all()` (or
  /// `Emoji.byGroup(...)`) plus a `.where().toList()` filter over
  /// ~1900 entries on every rebuild — including every focus change on the
  /// search field and every keystroke's `setState` — which is the second
  /// half of the scroll-lag report: a fresh ~1900-item list was being
  /// allocated on frames that never even touched the grid.
  late List<Emoji> _filteredEmojiCache;

  /// The search query the current [_filteredEmojiCache] was computed
  /// against, so [_recomputeFilteredEmoji] can tell whether the text
  /// actually changed (vs. a `setState` triggered by an unrelated field,
  /// e.g. search-focus tracking) before redoing the filter work.
  String _cachedQuery = '';

  /// The group the current [_filteredEmojiCache] was computed against —
  /// paired with [_cachedQuery], see that field's doc.
  EmojiGroup? _cachedGroup;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _filteredEmojiCache = _computeFilteredEmoji();
    _cachedQuery = _searchController.text;
    _cachedGroup = _selectedGroup;
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Tracks focus on the search field for its own visual state (hover/focus
  /// colors resolved by [LayrzInputChrome]) — mirrors
  /// `select_input_surface.dart`'s identical `_handleSearchFocusChanged`.
  void _handleSearchFocusChanged() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _searchStates.add(WidgetState.focused);
      } else {
        _searchStates.remove(WidgetState.focused);
      }
    });
  }

  /// Whether [emoji] matches [query] — case-insensitive, checked against
  /// both [Emoji.shortName] and every entry in [Emoji.keywords] (OQ-6,
  /// resolved: search both fields, not [shortName] alone).
  ///
  /// An empty [query] always matches (the "no search text" case shows every
  /// emoji in the currently selected group).
  bool _matchesQuery(Emoji emoji, String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    if (emoji.shortName.toLowerCase().contains(lowerQuery)) return true;
    return emoji.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
  }

  /// Computes the emoji list for the currently selected group (or all
  /// emoji, when no group is selected) filtered by the current search text.
  ///
  /// This is the actual filter work — called only from
  /// [_recomputeFilteredEmoji] (and once from [initState]), never directly
  /// from `build()`. Use [_filteredEmojiCache] to read the current result.
  List<Emoji> _computeFilteredEmoji() {
    final base = _selectedGroup == null ? Emoji.all() : Emoji.byGroup(_selectedGroup!).toList();
    final query = _searchController.text;
    if (query.isEmpty) return base;
    return base.where((emoji) => _matchesQuery(emoji, query)).toList();
  }

  /// Refreshes [_filteredEmojiCache] only if [_selectedGroup] or the search
  /// text has actually changed since it was last computed — called from
  /// `build()` so a rebuild triggered by something unrelated (e.g. the
  /// search field's own focus-state `setState`) reuses the existing list
  /// instead of reallocating a ~1900-entry filter result.
  void _recomputeFilteredEmoji() {
    final query = _searchController.text;
    if (query == _cachedQuery && _selectedGroup == _cachedGroup) return;
    _filteredEmojiCache = _computeFilteredEmoji();
    _cachedQuery = query;
    _cachedGroup = _selectedGroup;
  }

  /// Applies a newly selected [LayrzTabView] tab index, re-running the
  /// search against the newly selected group's own emoji list.
  ///
  /// [filters] is the same list [build] derives via [_buildGroupFilters] for
  /// this build -- passed in rather than recomputed here so the index this
  /// callback receives (from [LayrzTabView.onTabChanged]) is resolved
  /// against the exact list that produced the tapped tab, not a
  /// freshly-rebuilt one that could disagree if `l10n` ever changed between
  /// builds.
  void _handleGroupTabChanged(int index, List<_EmojiGroupFilter> filters) {
    setState(() => _selectedGroup = filters[index].group);
  }

  /// Builds the borderless search field row, mirroring
  /// `select_input_surface.dart`'s own `_buildSearchField` composition
  /// (`LayrzInputChrome` directly, no visible border of its own — the
  /// surrounding surface/drawer chrome supplies the outer boundary).
  Widget _buildSearchField(BuildContext context, LayrzUiL10n l10n) {
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: null,
      hintText: l10n.emojiPickerSearch,
      disabled: false,
      readOnly: false,
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (_) => setState(() {}),
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
      hintText: l10n.emojiPickerSearch,
      isRequired: false,
      prefixSlot: resolvePrefixSlot(prefixIcon: MdiIcons.magnify, isDecorative: true),
      suffixSlot: resolveSuffixSlot(
        suffixIcon: _searchController.text.isNotEmpty ? MdiIcons.close : null,
        onSuffixTap: _searchController.text.isNotEmpty
            ? () {
                _searchController.clear();
                setState(() {});
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

  /// Renders one grid cell's content: the emoji character alone, centered —
  /// [LayrzGlyphGrid] itself supplies the tap/focus/keyboard wiring and the
  /// [LayrzFocusRing] overlay, so this builder is purely visual.
  Widget _buildEmojiCell(BuildContext context, Emoji emoji, int index, bool isFocused) {
    return Center(
      child: Text(emoji.char, style: const TextStyle(fontSize: 24)),
    );
  }

  /// Builds the [LayrzGlyphGrid] (or the "no results" text) for the
  /// currently active group, shared by every [LayrzTab.child] below —
  /// [_filteredEmojiCache] is already filtered against both
  /// [_selectedGroup] and the search text, so each tab's content is simply
  /// this shared build wrapped in an [Expanded] to claim the tab view's own
  /// remaining height (Fix 4).
  Widget _buildGroupGridOrEmpty(BuildContext context, LayrzUiL10n l10n) {
    final tokens = context.tokens;
    final filteredEmoji = _filteredEmojiCache;

    if (filteredEmoji.isEmpty) {
      return Padding(
        padding: tokens.spacing.pd3,
        child: Text(l10n.emojiPickerEmpty, style: tokens.typography.label),
      );
    }

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
        child: LayrzGlyphGrid<Emoji>(
          items: filteredEmoji,
          columns: _kEmojiGridColumns,
          cellExtent: _kEmojiCellExtent,
          itemBuilder: _buildEmojiCell,
          // This surface is always hosted inside a bounded
          // `LayrzBottomSheet`/dialog body (the `Expanded`
          // above claims that bound), and the emoji list can run
          // into the thousands — so this grid needs the lazy,
          // parent-filling viewport mode rather than the shared
          // widget's shrink-to-content default. See
          // `LayrzGlyphGrid.shrinkWrap`'s doc for why the default
          // `true` would both truncate this grid's height and make
          // it lay out every cell eagerly on scroll.
          shrinkWrap: false,
          onItemActivated: (emoji) => widget.onEmojiSelected(emoji.char),
          keyboardHandler: buildGlyphGridKeyboardHandler(
            columns: _kEmojiGridColumns,
            itemCount: filteredEmoji.length,
            isDisabled: (_) => false,
            onSelect: (index) => widget.onEmojiSelected(filteredEmoji[index].char),
          ),
          semanticLabelBuilder: (emoji, index) => emoji.shortName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    _recomputeFilteredEmoji();

    final filters = _buildGroupFilters(l10n);
    final rawSelectedIndex = filters.indexWhere((filter) => filter.group == _selectedGroup);
    final selectedIndex = rawSelectedIndex < 0 ? 0 : rawSelectedIndex;

    // Whole-surface padding (user testing feedback: "add padding man" — the
    // surface read as cramped with its sections flush against the hosting
    // `LayrzBottomSheet`/dialog edges). `sp3` mirrors
    // `date_surface.dart`'s own outer-edge inset for the sibling pickers'
    // surfaces, one level up from the `sp2` inter-section gaps below so the
    // outer edge reads more generous than the internal rhythm.
    //
    // The outer `Column` is no longer `mainAxisSize: MainAxisSize.min` —
    // this surface is always hosted inside a `LayrzBottomSheet`/dialog
    // surface that gives it a bounded height, and the tab view's grid
    // section needs `Expanded` to claim all of that height rather than the
    // fixed 320.0 px box it used to render into (which is why the grid
    // used to stop after ~7 rows with a large blank area beneath it — the
    // box was hardcoded, not filling the surface).
    return Padding(
      padding: tokens.spacing.pd3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayrzPickerDialogHeader(
            labelText: widget.labelText,
            onClose: () => LayrzModalRoute.popIfCurrent(context),
          ),
          _buildSearchField(context, l10n),
          SizedBox(height: tokens.spacing.sp3),
          // Fix 4: the category strip is now a `LayrzTabView` (one
          // `LayrzTab` per `EmojiGroup`, plus "All emoji") instead of the
          // file-local chip row this surface used to build directly —
          // `isScrollable: true` (the default) keeps the strip
          // start-aligned and sized to each label's own content rather than
          // squeezing all eleven entries into equal `Expanded` slices (see
          // `LayrzTabView.isScrollable`'s own doc for that distinction),
          // preserving the readability the former chip row was written to
          // achieve.
          Expanded(
            child: LayrzTabView(
              initialIndex: selectedIndex,
              onTabChanged: (index) => _handleGroupTabChanged(index, filters),
              tabs: [
                for (final filter in filters)
                  LayrzTab(
                    labelText: filter.label,
                    child: _buildGroupGridOrEmpty(context, l10n),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

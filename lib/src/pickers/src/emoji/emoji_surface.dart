import 'package:emojis/emoji.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

import '../shared/glyph_grid.dart';
import '../shared/glyph_grid_keyboard.dart';

/// The number of grid columns rendered per row of emoji cells.
///
/// A fixed column count (rather than one derived from the surface's own
/// width) keeps cell size predictable across the [LayrzBottomSheet] and
/// [LayrzEndDrawer] hosts, both of which already constrain this surface to a
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
/// [LayrzBottomSheet]/[LayrzEndDrawer] immediately — this surface renders no
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
  /// Called with the tapped emoji's raw character when the user picks one.
  /// The caller is expected to close the hosting surface immediately after
  /// this fires (see [LayrzEmojiInput]'s own open methods).
  final ValueChanged<String> onEmojiSelected;

  /// Creates a new [LayrzEmojiSurface].
  const LayrzEmojiSurface({super.key, required this.onEmojiSelected});

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

  /// Applies a tapped group filter, re-running the search against the newly
  /// selected group's own emoji list.
  void _selectGroup(EmojiGroup? group) {
    setState(() => _selectedGroup = group);
  }

  /// Builds the horizontally scrollable group-filter row.
  ///
  /// **Not [LayrzPickerTabSwitcher] (U2's shared tab primitive).** That
  /// widget renders every tab as an `Expanded` slice of one fixed-width
  /// `Row`, which reads fine for two-to-three tabs (the color picker's
  /// Palette/Wheel pair) but squeezes unreadably narrow across the eleven
  /// entries here (ten [EmojiGroup] values plus "All emoji") — especially on
  /// the [LayrzBottomSheet] mobile host's narrower width. A horizontally
  /// scrollable chip row, sized to each label's own content, is this
  /// surface's own file-local widget instead; it is not shared with any
  /// other picker, so it does not belong under `shared/`.
  Widget _buildGroupFilterRow(BuildContext context, LayrzUiL10n l10n) {
    final tokens = context.tokens;
    final filters = _buildGroupFilters(l10n);

    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: tokens.spacing.sp1),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter.group == _selectedGroup;
          return _EmojiGroupChip(
            label: filter.label,
            isSelected: isSelected,
            onTap: isSelected ? null : () => _selectGroup(filter.group),
          );
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    _recomputeFilteredEmoji();
    final filteredEmoji = _filteredEmojiCache;

    // Whole-surface padding (user testing feedback: "add padding man" — the
    // surface read as cramped with its sections flush against the hosting
    // `LayrzBottomSheet`/`LayrzEndDrawer` edges). `sp3` mirrors
    // `date_surface.dart`'s own outer-edge inset for the sibling pickers'
    // surfaces, one level up from the `sp2` inter-section gaps below so the
    // outer edge reads more generous than the internal rhythm.
    //
    // The outer `Column` is no longer `mainAxisSize: MainAxisSize.min` —
    // this surface is always hosted inside a `LayrzBottomSheet`/
    // `LayrzEndDrawer` that gives it a bounded height, and the grid section
    // below needs `Expanded` to claim all of that height rather than the
    // fixed 320.0 px box it used to render into (which is why the grid
    // used to stop after ~7 rows with a large blank area beneath it — the
    // box was hardcoded, not filling the surface).
    return Padding(
      padding: tokens.spacing.pd3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGroupFilterRow(context, l10n),
          SizedBox(height: tokens.spacing.sp3),
          _buildSearchField(context, l10n),
          SizedBox(height: tokens.spacing.sp3),
          if (filteredEmoji.isEmpty)
            Padding(
              padding: tokens.spacing.pd3,
              child: Text(l10n.emojiPickerEmpty, style: tokens.typography.label),
            )
          else
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
                child: LayrzGlyphGrid<Emoji>(
                  items: filteredEmoji,
                  columns: _kEmojiGridColumns,
                  cellExtent: _kEmojiCellExtent,
                  itemBuilder: _buildEmojiCell,
                  // This surface is always hosted inside a bounded
                  // `LayrzBottomSheet`/`LayrzEndDrawer` body (the `Expanded`
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
            ),
        ],
      ),
    );
  }
}

/// A single chip within the emoji group-filter row — a rounded-rectangle,
/// tappable label that visually distinguishes the currently selected group
/// from every other entry via fill color alone (per D15: no geometry change
/// between selected and unselected).
///
/// **Corner radius matches the color picker's tabs.** This chip uses the same
/// [LayrzRadiusTokens.br2] rounded-rectangle radius as
/// [LayrzPickerTabSwitcher]'s tab pills, not a fully-rounded/stadium shape —
/// the two pickers' tab-shaped affordances are meant to read as one
/// consistent system, and a pill-shaped chip next to a rounded-rectangle tab
/// broke that consistency (user report).
///
/// **Restyle (user testing feedback):** the selected chip now paints the
/// full [LayrzColorTokens.primary] fill (matching the equivalent restyle
/// applied to the color picker's [LayrzPickerTabSwitcher] tabs, so the two
/// pickers' tab-shaped affordances read as one consistent system), and the
/// unselected chip paints [LayrzColorTokens.sf1] — the page-canvas/background
/// token — as a solid fill rather than a transparent one, per the user's
/// explicit note that a transparent idle chip produced a visible artifact
/// during the fill-color transition (see [LayrzTappable]'s own "black blink"
/// caveat for the mechanism: animating a literal transparent-black idle
/// color toward an opaque, differently-hued target ramps the wrong channels
/// mid-tween). Both colors are still resolved purely through
/// [LayrzTappable]'s `color`/`hoverColor`/`pressedColor`, so the fill
/// transition itself remains D15-compliant (color/opacity only, no geometry
/// change).
class _EmojiGroupChip extends StatelessWidget {
  /// This chip's visible label.
  final String label;

  /// Whether this chip is the currently active group filter.
  final bool isSelected;

  /// Called on tap. `null` when this chip is already selected (nothing to
  /// activate), which also renders it non-interactive.
  final VoidCallback? onTap;

  /// Creates a new [_EmojiGroupChip].
  const _EmojiGroupChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderRadius = tokens.radius.br2;

    final backgroundColor = isSelected ? tokens.colors.primary.shade500 : tokens.colors.sf1;
    final textColor = isSelected ? tokens.colors.sf1 : tokens.colors.fg2;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: LayrzTappable(
        onTap: onTap,
        color: backgroundColor,
        hoverColor: isSelected ? backgroundColor : tokens.colors.sf3,
        pressedColor: isSelected ? backgroundColor : tokens.colors.sf4,
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp1),
          child: Center(
            child: Text(
              label,
              style: tokens.typography.label.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

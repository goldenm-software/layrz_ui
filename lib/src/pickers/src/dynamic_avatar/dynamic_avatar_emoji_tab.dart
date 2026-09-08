import 'package:emojis/emoji.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../shared/glyph_grid.dart';
import '../shared/glyph_grid_keyboard.dart';
import 'dynamic_avatar_grid_constants.dart';

/// One entry in the Emoji tab's inline group-filter row: either "All emoji"
/// (no [group]) or one specific [EmojiGroup], paired with its localized
/// [label].
///
/// A file-local named class (rather than a bare tuple) so call sites below
/// read [group]/[label] as named fields — mirrors [LayrzEmojiSurface]'s
/// identical `_EmojiGroupFilter`.
class _DynamicAvatarEmojiGroupFilter {
  /// The group this entry filters to, or `null` for "All emoji".
  final EmojiGroup? group;

  /// The localized label shown for this entry in the filter row.
  final String label;

  /// Creates a new [_DynamicAvatarEmojiGroupFilter].
  const _DynamicAvatarEmojiGroupFilter({required this.group, required this.label});
}

/// The Emoji tab's content for [LayrzDynamicAvatarInput]'s surface: a
/// lightweight inline group-filter row (a horizontal scroll of selectable
/// chips, not a nested [LayrzTabView] — see this class's own "why chips, not
/// tabs" note), a search field, and a [LayrzGlyphGrid] of [Emoji] entries.
///
/// **Why chips, not a nested [LayrzTabView].** [LayrzEmojiSurface] uses an
/// inner [LayrzTabView] for its ~11 groups, but [LayrzDynamicAvatarSurface]'s
/// outer dialog is *itself* a [LayrzTabView] (URL/Upload/Icon/Emoji) — a
/// [LayrzTabView] nested inside a [LayrzTab.child] works mechanically, but
/// reads confusingly (two independent strips of tappable pills stacked on
/// top of one another) and was explicitly avoided per the work-unit brief.
/// A plain horizontally-scrolling row of tappable, selectable text chips
/// gives the same filtering capability with one visual "this is a tab
/// strip" language reserved for the outer dialog alone.
class LayrzDynamicAvatarEmojiTab extends StatefulWidget {
  /// Called with the tapped emoji when the user picks one. The caller is
  /// expected to map it to a [LayrzAvatarEmoji] and close the hosting
  /// surface.
  final ValueChanged<Emoji> onEmojiSelected;

  /// Creates a new [LayrzDynamicAvatarEmojiTab].
  const LayrzDynamicAvatarEmojiTab({super.key, required this.onEmojiSelected});

  @override
  State<LayrzDynamicAvatarEmojiTab> createState() => _LayrzDynamicAvatarEmojiTabState();
}

class _LayrzDynamicAvatarEmojiTabState extends State<LayrzDynamicAvatarEmojiTab> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Set<WidgetState> _searchStates = {};
  EmojiGroup? _selectedGroup;
  late List<Emoji> _filteredEmojiCache;
  String _cachedQuery = '';
  EmojiGroup? _cachedGroup;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _filteredEmojiCache = _computeFilteredEmoji();
    _cachedGroup = _selectedGroup;
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
  /// both [Emoji.shortName] and every entry in [Emoji.keywords], mirroring
  /// [LayrzEmojiSurface]'s identical `_matchesQuery`.
  bool _matchesQuery(Emoji emoji, String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    if (emoji.shortName.toLowerCase().contains(lowerQuery)) return true;
    return emoji.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
  }

  List<Emoji> _computeFilteredEmoji() {
    final base = _selectedGroup == null ? Emoji.all() : Emoji.byGroup(_selectedGroup!).toList();
    final query = _searchController.text;
    if (query.isEmpty) return base;
    return base.where((emoji) => _matchesQuery(emoji, query)).toList();
  }

  void _recomputeFilteredEmoji() {
    final query = _searchController.text;
    if (query == _cachedQuery && _selectedGroup == _cachedGroup) return;
    _filteredEmojiCache = _computeFilteredEmoji();
    _cachedQuery = query;
    _cachedGroup = _selectedGroup;
  }

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

  /// Builds the ten [EmojiGroup]-backed entries plus a leading "All emoji"
  /// entry, matching [LayrzEmojiSurface]'s own `_buildGroupFilters` order.
  List<_DynamicAvatarEmojiGroupFilter> _buildGroupFilters(LayrzUiL10n l10n) {
    return [
      _DynamicAvatarEmojiGroupFilter(group: null, label: l10n.dynamicAvatarEmojiGroupAll),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.smileysEmotion, label: l10n.emojiPickerGroupSmileysEmotion),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.peopleBody, label: l10n.emojiPickerGroupPeopleBody),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.animalsNature, label: l10n.emojiPickerGroupAnimalsNature),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.foodDrink, label: l10n.emojiPickerGroupFoodDrink),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.travelPlaces, label: l10n.emojiPickerGroupTravelPlaces),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.activities, label: l10n.emojiPickerGroupActivities),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.objects, label: l10n.emojiPickerGroupObjects),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.symbols, label: l10n.emojiPickerGroupSymbols),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.flags, label: l10n.emojiPickerGroupFlags),
      _DynamicAvatarEmojiGroupFilter(group: EmojiGroup.component, label: l10n.emojiPickerGroupComponent),
    ];
  }

  /// Builds one chip in the group-filter row — a plain [GestureDetector]
  /// over a styled [Container], exposed to screen readers as a selectable
  /// button via [Semantics].
  Widget _buildGroupChip(BuildContext context, _DynamicAvatarEmojiGroupFilter filter) {
    final tokens = context.tokens;
    final isSelected = filter.group == _selectedGroup;
    final background = isSelected ? tokens.colors.primary : tokens.colors.sf2;
    final foreground = isSelected ? tokens.colors.sf1 : tokens.colors.fg2;

    return Semantics(
      label: filter.label,
      button: true,
      selected: isSelected,
      onTap: () => setState(() => _selectedGroup = filter.group),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() => _selectedGroup = filter.group),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.only(right: tokens.spacing.sp2),
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp3, vertical: tokens.spacing.sp2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: tokens.radius.br5,
          ),
          child: Text(
            filter.label,
            style: tokens.typography.label.copyWith(color: foreground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiCell(BuildContext context, Emoji emoji, int index, bool isFocused) {
    return Center(child: Text(emoji.char, style: const TextStyle(fontSize: 24)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    _recomputeFilteredEmoji();
    final filters = _buildGroupFilters(l10n);
    final filteredEmoji = _filteredEmojiCache;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [for (final filter in filters) _buildGroupChip(context, filter)],
          ),
        ),
        SizedBox(height: tokens.spacing.sp2),
        _buildSearchField(context, l10n),
        SizedBox(height: tokens.spacing.sp3),
        if (filteredEmoji.isEmpty)
          Expanded(
            child: Padding(
              padding: tokens.spacing.pd3,
              child: Text(l10n.emojiPickerEmpty, style: tokens.typography.label),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
              child: LayrzGlyphGrid<Emoji>(
                items: filteredEmoji,
                columns: kDynamicAvatarGridColumns,
                cellExtent: kDynamicAvatarCellExtent,
                itemBuilder: _buildEmojiCell,
                shrinkWrap: false,
                onItemActivated: widget.onEmojiSelected,
                keyboardHandler: buildGlyphGridKeyboardHandler(
                  columns: kDynamicAvatarGridColumns,
                  itemCount: filteredEmoji.length,
                  isDisabled: (_) => false,
                  onSelect: (index) => widget.onEmojiSelected(filteredEmoji[index]),
                ),
                semanticLabelBuilder: (emoji, index) => emoji.shortName,
              ),
            ),
          ),
      ],
    );
  }
}

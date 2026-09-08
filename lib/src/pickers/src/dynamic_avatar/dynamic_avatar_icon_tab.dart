import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/images/src/avatar_source.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';

import '../shared/glyph_grid.dart';
import '../shared/glyph_grid_keyboard.dart';
import 'dynamic_avatar_grid_constants.dart';

/// The Icon tab's content for [LayrzDynamicAvatarInput]'s surface: a search
/// field over the `flutter_mdi_remap` registry plus a [LayrzGlyphGrid] of
/// [MdiRemapIcon] entries.
///
/// Rendered **inline** — this is deliberately not [LayrzIconSurface] reused
/// wholesale, since that surface carries its own [LayrzPickerDialogHeader]
/// and close ("X") affordance, which would double up with the single header
/// [LayrzDynamicAvatarSurface] already renders at the top of its own
/// [LayrzTabView]. See that class's own doc for the "one dialog, one header"
/// rule this tab exists to satisfy.
class LayrzDynamicAvatarIconTab extends StatefulWidget {
  /// Called with the tapped icon when the user picks one. The caller is
  /// expected to map it to a [LayrzAvatarIcon] and close the hosting surface.
  final ValueChanged<MdiRemapIcon> onIconSelected;

  /// Creates a new [LayrzDynamicAvatarIconTab].
  const LayrzDynamicAvatarIconTab({super.key, required this.onIconSelected});

  @override
  State<LayrzDynamicAvatarIconTab> createState() => _LayrzDynamicAvatarIconTabState();
}

class _LayrzDynamicAvatarIconTabState extends State<LayrzDynamicAvatarIconTab> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Set<WidgetState> _searchStates = {};
  late List<MdiRemapIcon> _filteredIconsCache;
  String _cachedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _filteredIconsCache = allMdiRemapIcons();
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Tracks focus on the search field for its own visual state, mirroring
  /// [LayrzIconSurface]'s identical `_handleSearchFocusChanged`.
  void _handleSearchFocusChanged() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _searchStates.add(WidgetState.focused);
      } else {
        _searchStates.remove(WidgetState.focused);
      }
    });
  }

  /// Refreshes [_filteredIconsCache] only when the search text has actually
  /// changed since it was last computed, mirroring [LayrzIconSurface]'s own
  /// memoization.
  void _recomputeFilteredIcons() {
    final query = _searchController.text;
    if (query == _cachedQuery) return;
    _filteredIconsCache = query.isEmpty ? allMdiRemapIcons() : searchMdiRemapIcons(query);
    _cachedQuery = query;
  }

  Widget _buildSearchField(BuildContext context, LayrzUiL10n l10n) {
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: null,
      hintText: l10n.iconPickerSearch,
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
      hintText: l10n.iconPickerSearch,
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

  Widget _buildIconCell(BuildContext context, MdiRemapIcon icon, int index, bool isFocused) {
    final tokens = context.tokens;
    return Center(child: Icon(icon.data, size: 24, color: tokens.colors.fg1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    _recomputeFilteredIcons();
    final filteredIcons = _filteredIconsCache;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(context, l10n),
        SizedBox(height: tokens.spacing.sp3),
        if (filteredIcons.isEmpty)
          Expanded(
            child: Padding(
              padding: tokens.spacing.pd3,
              child: Text(l10n.iconPickerEmpty, style: tokens.typography.label),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
              child: LayrzGlyphGrid<MdiRemapIcon>(
                items: filteredIcons,
                columns: kDynamicAvatarGridColumns,
                cellExtent: kDynamicAvatarCellExtent,
                itemBuilder: _buildIconCell,
                shrinkWrap: false,
                onItemActivated: widget.onIconSelected,
                keyboardHandler: buildGlyphGridKeyboardHandler(
                  columns: kDynamicAvatarGridColumns,
                  itemCount: filteredIcons.length,
                  isDisabled: (_) => false,
                  onSelect: (index) => widget.onIconSelected(filteredIcons[index]),
                ),
                semanticLabelBuilder: (icon, index) => icon.name,
              ),
            ),
          ),
      ],
    );
  }
}

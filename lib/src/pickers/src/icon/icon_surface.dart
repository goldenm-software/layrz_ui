import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_mdi_remap/flutter_mdi_remap.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/shared/editable_field.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_chrome.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';

import '../shared/glyph_grid.dart';
import '../shared/glyph_grid_keyboard.dart';
import '../shared/picker_dialog_header.dart';

/// The number of grid columns rendered per row of icon cells.
///
/// A fixed column count (rather than one derived from the surface's own
/// width) keeps cell size predictable across the [LayrzBottomSheet] and the
/// dialog branch of `LayrzResponsiveModal.show`, both of which already
/// constrain this surface to a known width band — mirrors
/// `emoji_surface.dart`'s identical `_kEmojiGridColumns` reasoning.
const int _kIconGridColumns = 8;

/// The side length, in logical pixels, of each icon cell — sized to make an
/// MDI glyph comfortably tappable and legible, matching
/// `emoji_surface.dart`'s own `_kEmojiCellExtent` scale.
const double _kIconCellExtent = 44.0;

/// The surface content for [LayrzIconInput]: a search field and a
/// [LayrzGlyphGrid] of [MdiRemapIcon] entries drawn from the
/// `flutter_mdi_remap` registry (~7,447 icons).
///
/// **Commit-on-tap.** Unlike the Save-carrying date/month/time surfaces in
/// this module, tapping an icon cell both commits the pick (via
/// [onIconSelected]) and is expected to close the hosting [LayrzBottomSheet]
/// or dialog surface immediately — this surface renders no Cancel/Save
/// footer of its own and takes no `onDraftChanged` callback, mirroring
/// [LayrzEmojiSurface]'s identical "commit on tap, no Save row" contract.
///
/// **Search.** [MdiRemapIcon.name] and [MdiRemapIcon.tags] are both matched,
/// case-insensitively, via `searchMdiRemapIcons` — an empty query resolves
/// to `allMdiRemapIcons()` (the full ~7,447-entry registry).
///
/// **Virtualized.** [LayrzGlyphGrid] is hosted with `shrinkWrap: false`
/// inside an `Expanded` section of this surface's own bounded `Column`, so
/// only the cells within (and slightly beyond) the visible viewport are
/// ever built — required at this item count, where an eager/shrink-wrapped
/// layout pass would need to lay out all ~7,447 cells up front. See
/// [LayrzGlyphGrid.shrinkWrap]'s own doc.
class LayrzIconSurface extends StatefulWidget {
  /// The title shown in this surface's own [LayrzPickerDialogHeader],
  /// normally [LayrzIconInput.labelText]. `null` renders an empty title
  /// slot rather than no header at all — see that widget's own doc.
  final String? labelText;

  /// Called with the tapped icon's stable `'mdi-...'` name when the user
  /// picks one. The caller is expected to close the hosting surface
  /// immediately after this fires (see [LayrzIconInput]'s own open method).
  final ValueChanged<String> onIconSelected;

  /// Creates a new [LayrzIconSurface].
  const LayrzIconSurface({super.key, this.labelText, required this.onIconSelected});

  @override
  State<LayrzIconSurface> createState() => LayrzIconSurfaceState();
}

/// The [State] for [LayrzIconSurface] — public so a caller (mirroring the
/// date/month/emoji surfaces' own `GlobalKey<...State>` convention) can
/// attach a [GlobalKey] to it without a private-type analyzer warning,
/// should a future caller need to reach into it.
class LayrzIconSurfaceState extends State<LayrzIconSurface> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final Set<WidgetState> _searchStates = {};

  /// The memoized filtered icon list, recomputed only when the search text
  /// actually changes (see [_recomputeFilteredIcons]) rather than on every
  /// `build()` — mirrors [LayrzEmojiSurface]'s identical
  /// `_filteredEmojiCache` reasoning, and matters even more here: the
  /// backing registry is ~7,447 entries versus emoji's ~1,900, so an
  /// unmemoized `searchMdiRemapIcons` call on every unrelated rebuild (e.g.
  /// the search field's own focus-state `setState`) would be more
  /// expensive still.
  late List<MdiRemapIcon> _filteredIconsCache;

  /// The search query the current [_filteredIconsCache] was computed
  /// against, so [_recomputeFilteredIcons] can tell whether the text
  /// actually changed before redoing the filter work.
  String _cachedQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _filteredIconsCache = allMdiRemapIcons();
    _cachedQuery = _searchController.text;
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
  /// `emoji_surface.dart`'s identical `_handleSearchFocusChanged`.
  void _handleSearchFocusChanged() {
    setState(() {
      if (_searchFocusNode.hasFocus) {
        _searchStates.add(WidgetState.focused);
      } else {
        _searchStates.remove(WidgetState.focused);
      }
    });
  }

  /// Refreshes [_filteredIconsCache] only if the search text has actually
  /// changed since it was last computed — called from `build()` so a
  /// rebuild triggered by something unrelated (e.g. the search field's own
  /// focus-state `setState`) reuses the existing list instead of
  /// re-querying the ~7,447-entry registry.
  void _recomputeFilteredIcons() {
    final query = _searchController.text;
    if (query == _cachedQuery) return;
    _filteredIconsCache = searchMdiRemapIcons(query);
    _cachedQuery = query;
  }

  /// Builds the borderless search field row, mirroring
  /// `emoji_surface.dart`'s own `_buildSearchField` composition
  /// (`LayrzInputChrome` directly, no visible border of its own — the
  /// surrounding surface/drawer chrome supplies the outer boundary).
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

  /// Renders one grid cell's content: the icon glyph alone, centered —
  /// [LayrzGlyphGrid] itself supplies the tap/focus/keyboard wiring and the
  /// [LayrzFocusRing] overlay, so this builder is purely visual.
  Widget _buildIconCell(BuildContext context, MdiRemapIcon icon, int index, bool isFocused) {
    final tokens = context.tokens;
    return Center(
      child: Icon(icon.data, size: 24, color: tokens.colors.fg1),
    );
  }

  /// Builds the [LayrzGlyphGrid] (or the "no results" text) for the current
  /// search text. [_filteredIconsCache] is already filtered, so this is
  /// simply this shared build wrapped in an [Expanded] to claim the
  /// surface's own remaining height.
  Widget _buildGridOrEmpty(BuildContext context, LayrzUiL10n l10n) {
    final tokens = context.tokens;
    final filteredIcons = _filteredIconsCache;

    if (filteredIcons.isEmpty) {
      return Expanded(
        child: Padding(
          padding: tokens.spacing.pd3,
          child: Text(l10n.iconPickerEmpty, style: tokens.typography.label),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1),
        child: LayrzGlyphGrid<MdiRemapIcon>(
          items: filteredIcons,
          columns: _kIconGridColumns,
          cellExtent: _kIconCellExtent,
          itemBuilder: _buildIconCell,
          // This surface is always hosted inside a bounded
          // `LayrzBottomSheet`/dialog body (the `Expanded` above claims that
          // bound), and the icon registry runs into the thousands (~7,447)
          // — so this grid needs the lazy, parent-filling viewport mode
          // rather than the shared widget's shrink-to-content default. See
          // `LayrzGlyphGrid.shrinkWrap`'s doc for why the default `true`
          // would both truncate this grid's height and make it lay out
          // every cell eagerly on scroll.
          shrinkWrap: false,
          onItemActivated: (icon) => widget.onIconSelected(icon.name),
          keyboardHandler: buildGlyphGridKeyboardHandler(
            columns: _kIconGridColumns,
            itemCount: filteredIcons.length,
            isDisabled: (_) => false,
            onSelect: (index) => widget.onIconSelected(filteredIcons[index].name),
          ),
          semanticLabelBuilder: (icon, index) => icon.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    _recomputeFilteredIcons();

    // Whole-surface padding, matching `emoji_surface.dart`'s own outer-edge
    // inset. The outer `Column` is not `mainAxisSize: MainAxisSize.min` --
    // this surface is always hosted inside a `LayrzBottomSheet`/dialog
    // surface that gives it a bounded height, and the grid section needs
    // `Expanded` to claim all of that height.
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
          _buildGridOrEmpty(context, l10n),
        ],
      ),
    );
  }
}

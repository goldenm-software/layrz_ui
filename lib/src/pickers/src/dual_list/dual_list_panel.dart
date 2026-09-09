import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// A single "Available" or "Selected" list panel rendered by
/// [LayrzDualListInput]'s desktop surface.
///
/// Composes a fixed header (title + row count), an optional
/// [LayrzSearchInput] in [LayrzSearchInputMode.field] mode, and a scrolling
/// `ListView` of tappable rows below it — each row's tap moves that item
/// across to the other panel (wired by the caller's [onItemTap], not by this
/// widget, which knows nothing about which panel it is or where a tap
/// should send the item).
///
/// This is a private implementation detail of `dual_list/`; consumers use
/// [LayrzDualListInput] instead.
class LayrzDualListPanel<T> extends StatefulWidget {
  /// The panel's own title, e.g. "Available" or "Selected".
  final String title;

  /// The items this panel currently shows, already narrowed to this panel's
  /// side (not-in-value or in-value) by the caller.
  final List<LayrzSelectItem<T>> items;

  /// Called when a row is tapped, with that row's value. Never called for a
  /// row whose [LayrzSelectItem.value] is null.
  final ValueChanged<T> onItemTap;

  /// Whether this panel renders its own search field. Mirrors
  /// [LayrzDualListInput.enableAvailableSearch]/[LayrzDualListInput.enableSelectedSearch].
  final bool enableSearch;

  /// Text shown when this panel has no items to display (either because
  /// [items] is empty, or a search query matched nothing).
  final String emptyText;

  /// The expected height of each row, forwarded to the internal
  /// `ListView.builder(itemExtent: ...)`.
  final double itemExtent;

  /// Whether the panel (and every row in it) is disabled — rows do not
  /// respond to taps and the search field, if shown, is disabled too.
  final bool disabled;

  /// Creates a new [LayrzDualListPanel].
  const LayrzDualListPanel({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    required this.enableSearch,
    required this.emptyText,
    required this.itemExtent,
    required this.disabled,
  });

  @override
  State<LayrzDualListPanel<T>> createState() => _LayrzDualListPanelState<T>();
}

class _LayrzDualListPanelState<T> extends State<LayrzDualListPanel<T>> {
  /// The panel's own search query, entirely local — [LayrzDualListInput]
  /// never sees it, mirroring how each `ThemedDualListInput` panel's search
  /// only ever narrows its own list.
  String _query = '';

  /// The panel's items narrowed by [_query], via [LayrzSelectItem.matches].
  List<LayrzSelectItem<T>> get _visibleItems {
    if (_query.isEmpty) return widget.items;
    return widget.items.where((item) => item.matches(_query)).toList();
  }

  void _handleSearch(String query) {
    setState(() => _query = query);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final visibleItems = _visibleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
          child: Text(
            '${widget.title} (${widget.items.length})',
            style: tokens.typography.label.copyWith(color: tokens.colors.fg2, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.enableSearch) ...[
          LayrzSearchInput(
            mode: LayrzSearchInputMode.field,
            hintText: context.l10n.dualListSearch(widget.title),
            onSearch: _handleSearch,
            disabled: widget.disabled,
            dense: true,
          ),
          SizedBox(height: tokens.spacing.sp2),
        ],
        Expanded(
          child: DecoratedBox(
            // Mirrors `LayrzInputStyleSpec`'s own enabled-state resolution
            // (`input_style_spec.dart`, default branch) so the panel reads as
            // an input surface rather than a bare bordered box -- `sf2` fill,
            // a transparent border at the input's own `borderWidth`. This
            // does not modify the frozen `input_chrome.dart`/
            // `input_style_spec.dart` files; it just matches their resolved
            // values from this panel's own decoration.
            decoration: BoxDecoration(
              color: tokens.colors.sf2,
              border: Border.all(color: const Color(0x00000000), width: tokens.border.base),
              borderRadius: tokens.radius.br2,
            ),
            child: ClipRRect(
              borderRadius: tokens.radius.br2,
              child: visibleItems.isEmpty
                  ? Padding(
                      padding: tokens.spacing.pd3,
                      child: Text(widget.emptyText, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemExtent: widget.itemExtent,
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return _DualListItemRow<T>(
                          key: ValueKey(item.value),
                          item: item,
                          disabled: widget.disabled,
                          onTap: widget.disabled || item.value == null ? null : () => widget.onItemTap(item.value as T),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single tappable row in [LayrzDualListPanel], tapping which moves its
/// item to the other panel.
///
/// Deliberately simpler than `_MultiSelectItemRow` in `multi_select_surface.dart`
/// — there is no per-row selected/checkbox state here, since membership in
/// this panel's own item list already *is* the state (a row visible in
/// "Available" is, by construction, not selected; a row visible in
/// "Selected" is).
class _DualListItemRow<T> extends StatelessWidget {
  /// The item this row renders.
  final LayrzSelectItem<T> item;

  /// Whether this row is inert (the panel, or the whole
  /// [LayrzDualListInput], is disabled).
  final bool disabled;

  /// Called when the row is tapped. Null when [disabled] or [item]'s value
  /// is null.
  final VoidCallback? onTap;

  /// Creates a new [_DualListItemRow].
  const _DualListItemRow({
    super.key,
    required this.item,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Idle matches the panel's own `sf2` fill (`dual_list_panel.dart`'s
    // `DecoratedBox`, above) so each row reads as a solid surface rather than
    // transparent-over-`sf2` -- an explicit idle color also avoids a
    // transparent-to-filled blink on first hover (see `LayrzTappable`'s own
    // "black blink" doc for the general shape of that problem). Hover steps
    // one level darker than the default (`sf4` instead of `sf3`) and pressed
    // goes one step deeper still; since the surface ramp stops at `sf4`
    // (there is no `sf5`), the pressed tone is derived by nudging `sf4`
    // toward `fg1` with [Color.lerp] at a small factor -- the same
    // token-derived-tone pattern already used for state colors elsewhere
    // (e.g. `month_grid_cell.dart`'s hover tint), rather than a hardcoded hex.
    final pressedColor = Color.lerp(tokens.colors.sf4, tokens.colors.fg1, 0.12)!;

    return Semantics(
      button: true,
      enabled: !disabled,
      onTap: onTap,
      child: LayrzTappable(
        onTap: onTap,
        disabled: disabled,
        color: tokens.colors.sf2,
        hoverColor: tokens.colors.sf4,
        pressedColor: pressedColor,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
          // A `Row` fills the fixed `itemExtent` height handed down by the
          // parent `ListView.builder` and centers its children on the cross
          // axis by default, so `item.child` is vertically centered in the
          // row's slot instead of top-aligning and clipping taller content --
          // mirrors `_MultiSelectItemRow` in `multi_select_surface.dart`.
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: context.bodyStyle.copyWith(
                    color: disabled ? tokens.colors.fg3.withValues(alpha: 0.5) : tokens.colors.fg1,
                  ),
                  child: item.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

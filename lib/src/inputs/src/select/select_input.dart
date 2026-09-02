import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/inputs/src/shared/input_footer_slot.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';
import '../shared/input_style_spec.dart';
import 'select_input_surface.dart';

/// A Material-free, adaptive select input in the layrz_ui design system.
///
/// [LayrzSelectInput] displays a field for picking an item, with a
/// dropdown chevron affordance rendered as an external sibling to the field (never inside
/// a caller-suppliable slot). Tapping the field opens a selection surface that adapts to
/// the viewport:
/// - **Desktop / wide (≥ 960px)**: [LayrzEndDrawer], a fixed-width right-edge
///   drawer (DESIGN-98) -- see [_LayrzSelectInputState._openDesktopDrawer] for
///   why it carries no `actions` row.
/// - **Below `md` breakpoint (< 960px)**: A bottom sheet covering the lower portion of the screen
///
/// This follows decision D52 (adaptive surface) and avoids depending on the dialog system
/// (DESIGN-96/99), keeping the component self-contained and lightweight.
///
/// **DESIGN-98 superseded the previous "elevated field" illusion (DESIGN-145).**
/// The selection surface no longer covers the field in place via
/// `LayrzAnchoredPanel.coverAnchor` -- the maintainer reported that overlay
/// "kinda weird" after live usage, and this field now opens the same
/// [LayrzEndDrawer] the eight date/time pickers use. The field itself is
/// unaffected by this: it is still always read-only and never the searcher
/// (see the next point), it simply no longer needs a focus node forwarded to
/// an anchored-panel `childFocusNode` the way the illusion required.
///
/// **Self-display (BREAKING, DESIGN-40/144):** The field renders from its own internal
/// state, not directly from [value]. Picking an item updates the field's display
/// immediately, whether or not the caller feeds an updated [value] back on the next
/// build -- a caller-supplied [value] change is still honored (it reconciles the internal
/// state), but is no longer required for the field to reflect a pick. See the CHANGELOG
/// for the full migration note; this widget was previously a strictly controlled
/// component and is not anymore.
///
/// **Search (when [enableSearch] is true, the default):** the field itself is never the
/// searcher (DESIGN-145 revises DESIGN-40/144 on this point) -- the opened surface owns
/// its own internal search field instead (see [LayrzSelectInputSurface]), which is what
/// removes the focus fight between the field and the surface entirely: the field is
/// always read-only and always shows the selected item's [LayrzSelectItem.child] (or the
/// hint, if nothing is selected), with no focus-dependent display logic left at all. When
/// [enableSearch] is false, the opened surface has no search field of its own either --
/// arrow keys alone navigate its list.
///
/// **Clearing a selection:** when [canUnselect] is true and an item is selected, the field
/// shows a clear ("unselect") affordance next to the dropdown chevron. Tapping it clears
/// the selection directly, calling [onChanged] with `null` -- independent of whether
/// [items] happens to contain an item with a null [LayrzSelectItem.value].
///
/// **Keyboard support:** When [enableSearch] is false, arrow keys move a highlight in the
/// list, Enter commits the highlighted item, Escape closes without changing the selection.
class LayrzSelectInput<T> extends StatefulWidget {
  /// The list of items to choose from.
  ///
  /// Each item combines a typed value, a required presentation widget ([LayrzSelectItem.child]),
  /// and search metadata ([LayrzSelectItem.searchableStrings]). Use [LayrzSelectItem] to
  /// construct items.
  final List<LayrzSelectItem<T>> items;

  /// The currently selected value.
  ///
  /// May be null to represent no selection. If the value matches no item,
  /// the field displays empty. Feeding this back after [onChanged] fires is no
  /// longer required for the field's own display to update (see the class doc),
  /// but it is still honored: a caller-supplied change reconciles the field's
  /// internal display state, without clobbering a query the user is mid-typing.
  final T? value;

  /// Callback fired when the user selects an item or clears the selection.
  ///
  /// Called with the selected [LayrzSelectItem], or `null` when the selection is
  /// cleared -- either by selecting an item with `value: null`, or by tapping the
  /// clear ("unselect") affordance rendered when [canUnselect] is true (see the
  /// class doc). If no item was selected, this callback is not called.
  final void Function(LayrzSelectItem<T>?)? onChanged;

  /// Whether the opened selection surface renders its own search field.
  ///
  /// Defaults to `true`. When true, the surface shows a search field above its list
  /// (see [LayrzSelectInputSurface]); typing into it filters the list live. When
  /// false, the surface has no search field of its own -- arrow keys alone navigate
  /// its list. Either way, this field itself (this widget's own closed display) is
  /// always read-only and never hosts a query -- see the class doc (DESIGN-145).
  final bool enableSearch;

  /// Whether the user can select an item with `value: null` to clear the selection.
  ///
  /// Defaults to `false`. When true, selecting an item with `null` value calls
  /// [onChanged] with `null`.
  final bool canUnselect;

  /// Optional custom filter function for search results.
  ///
  /// If provided, replaces the default [LayrzSelectItem.matches] logic.
  /// Called with the search query and each item; should return `true` if the
  /// item matches. When null, uses [LayrzSelectItem.matches] instead. Applied
  /// regardless of whether the field currently holds a query -- an empty query
  /// still runs through this callback rather than short-circuiting to "show all".
  final bool Function(String query, LayrzSelectItem<T> item)? filter;

  /// Text displayed when the search finds no matching items.
  ///
  /// If null, defaults to localized text from [LayrzUiL10n.selectEmpty].
  final String? emptyListText;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Icon to render as a prefix.
  ///
  /// Mutually exclusive with [prefix] and [prefixText].
  final IconData? prefixIcon;

  /// Widget to render as a prefix.
  ///
  /// Mutually exclusive with [prefixIcon] and [prefixText].
  final Widget? prefix;

  /// Text to render as a prefix.
  ///
  /// Mutually exclusive with [prefixIcon] and [prefix].
  final String? prefixText;

  /// Callback fired when the prefix is tapped.
  final VoidCallback? onPrefixTap;

  /// Icon to render as a suffix.
  ///
  /// Mutually exclusive with [suffix] and [suffixText]. Unlike the dropdown
  /// chevron -- which is always rendered as an external sibling to the field,
  /// never inside this slot -- this slot is entirely free for the caller: a
  /// caller-supplied suffix and the chevron always render together.
  final IconData? suffixIcon;

  /// Widget to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffixText]. See [suffixIcon]
  /// for why this slot never loses room to the dropdown chevron.
  final Widget? suffix;

  /// Text to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffix]. See [suffixIcon]
  /// for why this slot never loses room to the dropdown chevron.
  final String? suffixText;

  /// Callback fired when the suffix is tapped.
  final VoidCallback? onSuffixTap;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Whether the field is disabled.
  ///
  /// Disabled fields do not open the selection surface on tap.
  final bool disabled;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  ///
  /// When false (default), the field's internal padding is 14px on compact
  /// viewports and 10px on regular viewports. When true, padding drops one
  /// spacing level: 10px compact, 6px regular. No other dimension changes.
  final bool dense;

  /// Defines the expected height of the items in the list.
  final double itemExtent;

  /// Creates a new [LayrzSelectInput] with the given properties.
  const LayrzSelectInput({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.enableSearch = true,
    this.canUnselect = false,
    this.filter,
    this.emptyListText,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.onPrefixTap,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.onSuffixTap,
    this.helpTitleText,
    this.helpContentText,
    this.disabled = false,
    this.errors = const [],
    this.hideDetails = false,
    this.focusNode,
    this.dense = false,
    required this.itemExtent,
  }) : assert(
         (prefixIcon == null || prefix == null) &&
             (prefix == null || prefixText == null) &&
             (prefixIcon == null || prefixText == null),
         'At most one of prefixIcon, prefix, or prefixText may be non-null.',
       ),
       assert(
         (suffixIcon == null || suffix == null) &&
             (suffix == null || suffixText == null) &&
             (suffixIcon == null || suffixText == null),
         'At most one of suffixIcon, suffix, or suffixText may be non-null.',
       );

  @override
  State<LayrzSelectInput<T>> createState() => _LayrzSelectInputState<T>();
}

class _LayrzSelectInputState<T> extends State<LayrzSelectInput<T>> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  final Set<WidgetState> _states = {};

  /// The value the field currently displays, independent of [LayrzSelectInput.value]
  /// once a pick has been made locally.
  ///
  /// This is what makes both paths self-display (DESIGN-40/144's redesign): a pick
  /// updates this immediately via [_commitSelection], so the field's own display never
  /// depends on the caller feeding [LayrzSelectInput.value] back. [didUpdateWidget]
  /// still reconciles this with an externally-changed [LayrzSelectInput.value].
  T? _displayedValue;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    // Never fed text (DESIGN-145: the field never hosts a query, see the class doc) --
    // kept only because `LayrzEditableFieldConfig` requires a controller and
    // `LayrzInputChrome`'s hint-visibility logic reads it.
    _controller = TextEditingController();
    _displayedValue = widget.value;
  }

  @override
  void didUpdateWidget(LayrzSelectInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The focus node must be swapped in step with the widget's final
    // ownership state: `dispose()` decides what to dispose based on the
    // *current* `widget.focusNode`, so leaving `_focusNode` stale here would
    // let a later dispose() either leak an internally-created node or
    // dispose a node the caller still owns.
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.value != oldWidget.value) {
      // Reconcile with the caller's own value change. The field never hosts a
      // query anymore (DESIGN-145 -- see the class doc), so there is nothing to
      // clobber; the controller stays empty regardless.
      _displayedValue = widget.value;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Finds the item matching [_displayedValue], or null if not found.
  LayrzSelectItem<T>? _findSelectedItem() {
    try {
      return widget.items.firstWhere(
        (item) => item.value == _displayedValue,
      );
    } catch (e) {
      return null;
    }
  }

  /// Handles the field gaining or losing focus.
  ///
  /// Purely a visual concern now (DESIGN-145): the field is always read-only and never
  /// hosts a query, so this only tracks [WidgetState.focused] for [_buildField]'s own
  /// border/text styling.
  void _handleFieldFocusChanged(bool hasFocus) {
    setState(() {
      if (hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
    });
  }

  /// Commits [item] as the current selection, or clears it when [item] is null.
  ///
  /// Updates [_displayedValue] immediately -- this is what lets the field self-display
  /// without requiring the caller to feed [LayrzSelectInput.value] back -- then notifies
  /// the caller via [LayrzSelectInput.onChanged]. The field's controller is never
  /// touched: it is always empty (see the class doc), since the field never renders a
  /// text representation of the selection -- [_buildField] shows [LayrzSelectItem.child]
  /// directly instead.
  void _commitSelection(LayrzSelectItem<T>? item) {
    setState(() {
      _displayedValue = item?.value;
    });
    widget.onChanged?.call(item);
  }

  /// Clears the current selection directly, independent of whether [LayrzSelectInput.items]
  /// contains an item with a null [LayrzSelectItem.value].
  ///
  /// Wired to the clear ("unselect") affordance rendered by [_SelectClearButton] when
  /// [LayrzSelectInput.canUnselect] is true and a selection exists -- see the class doc.
  void _handleClear() {
    _commitSelection(null);
  }

  /// Opens the selection surface on mobile via bottom sheet.
  Future<void> _openMobileSurface() async {
    final result = await LayrzBottomSheet.show<LayrzSelectItem<T>?>(
      context,
      builder: (context) => SizedBox(
        child: LayrzSelectInputSurface(
          items: widget.items,
          selectedItem: _findSelectedItem(),
          enableSearch: widget.enableSearch,
          canUnselect: widget.canUnselect,
          filter: widget.filter,
          emptyListText: widget.emptyListText,
          itemExtent: widget.itemExtent,
          onItemSelected: (item) {
            Navigator.pop(context, item);
          },
        ),
      ),
    );

    if (result != null || widget.canUnselect) {
      _commitSelection(result);
    }
  }

  /// Builds the field's content: the chrome (as an [Expanded] sibling with no border
  /// or radius of its own) plus the dropdown chevron as an external caret.
  ///
  /// Mirrors `number_input.dart`'s step-button composition -- an outer bordered
  /// container around a [Row] of [chrome, caret] -- so that [suffixSlot] (and
  /// [prefixSlot]) stay entirely free for the caller: the widget's own dropdown
  /// affordance never occupies a slot the caller might want. [LayrzInputChrome]
  /// already exposes `showBorder`/`borderRadius` for exactly this composition, so
  /// this needs no change to the chrome itself.
  ///
  /// [onOpen] opens the selection surface -- [_openDesktopDrawer] on desktop,
  /// [_openMobileSurface] on mobile. [isExpanded] reports whether the surface is
  /// currently open; both hosts are routes rather than a queryable controller,
  /// so this is always `false` -- see [_openDesktopDrawer]'s own doc for why
  /// `LayrzEndDrawer` needs no controller the way `LayrzAnchoredPanel` did.
  Widget _buildField(
    BuildContext context, {
    required VoidCallback onOpen,
    required bool isExpanded,
  }) {
    final tokens = context.tokens;

    final prefixSlot = resolvePrefixSlot(
      prefixIcon: widget.prefixIcon,
      prefix: widget.prefix,
      prefixText: widget.prefixText,
      onPrefixTap: widget.onPrefixTap,
    );

    final suffixSlot = resolveSuffixSlot(
      suffixIcon: widget.suffixIcon,
      suffix: widget.suffix,
      suffixText: widget.suffixText,
      onSuffixTap: widget.onSuffixTap,
    );

    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    final hasErrors = widget.errors.isNotEmpty;

    // Deliberately blank when `_displayedValue` is null: a null value means "nothing
    // chosen", so the field must read as empty rather than showing an item that merely
    // happens to also carry a null `value` (a common "None"/clear entry convention).
    // `_findSelectedItem` itself carries no such guard -- it is also used for the
    // surface's highlighting, which still treats a null-value item as "the current
    // state" there.
    final selectedItem = _displayedValue == null ? null : _findSelectedItem();

    // DESIGN-145: the field is never the searcher (see the class doc), so this no
    // longer depends on focus at all -- an item is either selected or it is not.
    // This is what fixes the field reading as empty right after a pick: previously
    // the field stayed focused post-selection while `enableSearch` was true, which
    // kept this false until focus moved away.
    final showChildDisplay = selectedItem != null;

    // Always read-only (DESIGN-145): the field never accepts input, on any
    // `enableSearch` value -- typing happens in the opened surface's own internal
    // search field instead. See the class doc.
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: widget.labelText,
      // [LayrzEditableFieldConfig.hintText] is metadata only -- `LayrzEditableField`
      // never reads it; the visible hint is rendered by `LayrzInputChrome` itself, from
      // the `hintText:` passed to it directly below. Kept in sync with that value anyway
      // for consistency with the config's documented contract.
      hintText: selectedItem == null ? widget.hintText : null,
      disabled: widget.disabled,
      readOnly: true,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: null,
      onSubmit: null,
      onFocusChanged: _handleFieldFocusChanged,
      onTap: widget.disabled ? null : onOpen,
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

    final spec = LayrzInputStyleSpec.resolve(
      states: _states,
      tokens: tokens,
      hasErrors: hasErrors,
    );

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled,
      expanded: isExpanded,
      child: Container(
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: tokens.radius.br2,
          border: Border.all(
            color: spec.borderColor,
            width: spec.borderWidth,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // A fallback tap target for the chrome region outside the field's own
                // text content (e.g. the floating label, padding): `LayrzEditableField`'s
                // gesture handling only claims the text's own hit region, so a tap
                // landing elsewhere in the chrome would otherwise do nothing (verified:
                // see the doc comment on `_buildField`). `LayrzTappable` hit-tests
                // opaquely but tests children FIRST -- Flutter's hit-testing always
                // visits descendants before the ancestor considers itself -- so this
                // never intercepts a tap the field's own selection gesture recognizer
                // already claims; both simply enter the same arena for that pointer,
                // and the deeper (field's own) recognizer wins on the text itself.
                // Colors are fully transparent: `LayrzInputStyleSpec`-driven painting
                // on the chrome itself already reflects hover/press/focus, and this
                // must not paint a second, competing tint on top of that.
                child: LayrzTappable(
                  onTap: widget.disabled ? null : onOpen,
                  disabled: widget.disabled,
                  color: const Color(0x00000000),
                  hoverColor: const Color(0x00000000),
                  pressedColor: const Color(0x00000000),
                  borderRadius: tokens.radius.br2,
                  child: LayrzInputChrome(
                    labelText: null,
                    // Suppressed while a selection exists: the controller's text is
                    // always empty (the field never renders a text representation of
                    // the selection, see the class doc), and the chrome shows this
                    // hint whenever the controller reads empty -- so without this it
                    // would show through underneath (or beside) `selectedItem.child`
                    // below, as if nothing were selected.
                    hintText: selectedItem == null ? widget.hintText : null,
                    isRequired: widget.isRequired,
                    prefixSlot: prefixSlot,
                    suffixSlot: suffixSlot,
                    disabled: widget.disabled,
                    readOnly: false,
                    errors: widget.errors,
                    hideDetails: true,
                    states: _states,
                    helpTitleText: widget.helpTitleText,
                    helpContentText: widget.helpContentText,
                    controller: _controller,
                    dense: widget.dense,
                    borderRadius: BorderRadius.zero,
                    showBorder: false,
                    child: !showChildDisplay
                        ? LayrzEditableField(config: fieldConfig)
                        : Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              LayrzEditableField(config: fieldConfig),
                              // The selected item's own presentation, shown while idle.
                              // `IgnorePointer` keeps every tap routed to the
                              // `LayrzEditableField` beneath -- this overlay is purely
                              // visual, never a second hit-test target. Force-wrapped in
                              // its own `DefaultTextStyle` for the same reason
                              // `_SelectItemRow` is (see select_input_surface.dart): a
                              // plain `Text` inside `child` with no explicit color
                              // resolves to `null` without a real ancestor supplying
                              // one, which the engine then paints solid white.
                              IgnorePointer(
                                child: DefaultTextStyle(
                                  style: context.bodyStyle,
                                  child: selectedItem.child,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (widget.canUnselect && selectedItem != null && !widget.disabled)
                _SelectClearButton(
                  onTap: _handleClear,
                  hasErrors: hasErrors,
                  states: _states,
                ),
              _SelectFieldCaret(
                onTap: widget.disabled ? null : onOpen,
                isDisabled: widget.disabled,
                hasErrors: hasErrors,
                states: _states,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    if (isCompact) {
      // Mobile: build anchor that opens bottom sheet on tap
      // Note: Mobile bottom sheet does not expose expanded state since it is not
      // connected to a controller that can be queried. This is acceptable because
      // the bottom sheet itself is its own modal navigation layer.
      return _appendExtras(
        _buildField(context, onOpen: _openMobileSurface, isExpanded: false),
        context.tokens,
      );
    } else {
      // Desktop: opens the selection surface in a LayrzEndDrawer (DESIGN-98),
      // replacing the previous `LayrzAnchoredPanel` "elevated field" hosting
      // (DESIGN-145). See [_openDesktopDrawer]'s own doc for why this carries
      // no `actions` row.
      return _appendExtras(
        _buildField(
          context,
          onOpen: () => _openDesktopDrawer(context),
          isExpanded: false,
        ),
        context.tokens,
      );
    }
  }

  /// Opens the selection surface in [LayrzEndDrawer] on desktop (DESIGN-98).
  ///
  /// **No `actions` row.** Unlike the eight date/time pickers, picking an item
  /// here is the decision -- there is no separate value to compose across
  /// multiple fields before committing, so a Save button below the list would
  /// be pure friction: the user would tap an option, then have to find and tap
  /// Save for a choice already made. `actions: null` also means
  /// [LayrzEndDrawer.show]'s own `canDismiss` inference applies unchanged
  /// (dismissable, since there is nothing pinned to lose) -- no override
  /// needed, unlike every Cancel/Save-carrying picker.
  ///
  /// [LayrzSelectInputSurface] is passed no `panelController`: it has none to
  /// give, since the drawer has no `MenuController` the way
  /// `LayrzAnchoredPanel` did. The surface's own Escape/Enter/tap handlers
  /// already fall back to a bare `Navigator.pop(context)` whenever
  /// `panelController` is null -- the exact branch the mobile bottom sheet
  /// path below already exercises -- so closing the drawer this way needed no
  /// change to that widget.
  ///
  /// **The DESIGN-40 300px height cap is re-applied here, via [ConstrainedBox]
  /// plus its own [SingleChildScrollView], because [LayrzEndDrawer] does not
  /// offer either of its own for its `builder` content.** [LayrzAnchoredPanel]
  /// used to be the single place both existed (`maxHeight` plus the scroll view
  /// that let content past it keep scrolling -- see [LayrzSelectInputSurface]'s
  /// own class doc, which is deliberately host-agnostic and uncapped).
  /// [LayrzEndDrawer.show] wraps `builder(context)` in a bare
  /// [SingleChildScrollView] with no height cap at all, so a [ConstrainedBox]
  /// alone would clamp the available height but leave [LayrzSelectInputSurface]'s
  /// own uncapped-height `Column` (search field plus its fixed-height item
  /// list) with nowhere to put content past that cap -- it would overflow
  /// rather than scroll, since the surface relies on its host to be the one
  /// scrollable, not its own `Column`. The extra [SingleChildScrollView] here
  /// is that scrollable, reproducing [LayrzAnchoredPanel]'s own
  /// cap-then-scroll pairing exactly.
  Future<void> _openDesktopDrawer(BuildContext context) async {
    final result = await LayrzEndDrawer.show<LayrzSelectItem<T>?>(
      context,
      semanticLabel: widget.labelText ?? widget.hintText,
      builder: (context) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300.0),
        child: SingleChildScrollView(
          child: LayrzSelectInputSurface(
            items: widget.items,
            selectedItem: _findSelectedItem(),
            enableSearch: widget.enableSearch,
            canUnselect: widget.canUnselect,
            filter: widget.filter,
            emptyListText: widget.emptyListText,
            itemExtent: widget.itemExtent,
            onItemSelected: (item) {
              Navigator.pop(context, item);
            },
          ),
        ),
      ),
    );

    if (result != null || widget.canUnselect) {
      _commitSelection(result);
    }
  }

  /// Wraps [child] with the label above (when [LayrzSelectInput.labelText] is
  /// non-null) and the error/counter footer below, both rendered OUTSIDE
  /// [child] entirely -- see the class doc's DESIGN-145 note for why this
  /// hoisting is load-bearing, not cosmetic.
  ///
  /// **The footer is never gated on the label.** An earlier version
  /// short-circuited to `return child` whenever [LayrzSelectInput.labelText]
  /// was null, which meant [LayrzSelectInput.errors] rendered nothing at all
  /// on a field with no label -- a field with an error and no label showed no
  /// error text whatsoever. Only the label row itself is conditional now;
  /// this method always wraps in the [Column] so [LayrzInputFooterSlot]
  /// renders whenever it has something to show, independent of [labelText].
  Widget _appendExtras(Widget child, LayrzTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (rendered by number input, not by chrome)
        if (widget.labelText != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacing.sp2),
            child: ExcludeSemantics(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.labelText,
                      style: tokens.typography.label.copyWith(
                        color: tokens.colors.fg2,
                      ),
                    ),
                    if (widget.isRequired)
                      TextSpan(
                        text: '*',
                        style: tokens.typography.label.copyWith(
                          color: tokens.colors.danger,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        child,
        // Error block and character counter below the entire row
        LayrzInputFooterSlot(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
          maxLength: null,
          controller: _controller,
        ),
      ],
    );
  }
}

/// The clear ("unselect") affordance, rendered between the field's content and the
/// dropdown chevron when [LayrzSelectInput.canUnselect] is true and a selection exists.
///
/// **Root cause this fixes (DESIGN-145):** [LayrzSelectInput.canUnselect] previously had
/// no observable effect anywhere -- it was threaded all the way to
/// [LayrzSelectInputSurface] and stored there, but never read by anything, and nothing
/// gated selecting a null-valued [LayrzSelectItem] on it either. There was no way to
/// clear a selection unless the caller happened to include an explicit null-value item
/// in [LayrzSelectInput.items]. This widget is the fix: a direct, always-available clear
/// affordance, independent of what [LayrzSelectInput.items] contains. The maintainer's
/// own words: "canUnselect es la misma cosa que isClearable".
class _SelectClearButton extends StatelessWidget {
  /// Called when the button is tapped. Clears the current selection.
  final VoidCallback onTap;

  /// Whether the field currently has errors, for danger-tinted styling.
  final bool hasErrors;

  /// The field's current interaction states (focused, hovered, pressed), used to
  /// resolve matching colors via [LayrzInputStyleSpec.resolve].
  final Set<WidgetState> states;

  /// Creates a new [_SelectClearButton].
  const _SelectClearButton({
    required this.onTap,
    required this.hasErrors,
    required this.states,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
    );

    final dividerColor = hasErrors ? tokens.colors.danger : tokens.colors.divider.withValues(alpha: 0.3);
    final divider = BorderSide(color: dividerColor, width: tokens.border.stroke2);

    final content = Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Icon(
        MdiIcons.close,
        size: tokens.typography.body.fontSize,
        color: spec.textColor,
      ),
    );

    // Unlike the caret (whose action duplicates the field's own "opens picker"
    // semantics and is therefore excluded from the tree), this performs a distinct
    // action -- clearing the selection -- so it is announced as its own named button.
    return Semantics(
      button: true,
      label: l10n.selectUnselect,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: divider),
        ),
        child: LayrzTappable(
          onTap: onTap,
          color: spec.backgroundColor,
          hoverColor: tokens.colors.sf3,
          pressedColor: tokens.colors.sf4,
          child: content,
        ),
      ),
    );
  }
}

/// The dropdown chevron affordance, rendered as an external sibling to
/// [LayrzInputChrome] rather than inside its `suffixSlot`.
///
/// This is what frees [LayrzSelectInput.suffixIcon]/[LayrzSelectInput.suffix]/
/// [LayrzSelectInput.suffixText] for the caller: before this, the widget's own
/// chevron occupied the suffix slot whenever the caller left it empty, so a caller
/// that *did* supply a suffix lost the chevron entirely. Styled from
/// [LayrzInputStyleSpec] so it always matches the chrome's own current state
/// (focused, error, disabled), mirroring `NumberFieldControl`'s edge-control pattern.
class _SelectFieldCaret extends StatelessWidget {
  /// Called when the caret is tapped. Opens the selection surface, matching a tap
  /// anywhere else in the field. Null makes the caret inert (e.g. when disabled).
  final VoidCallback? onTap;

  /// Whether the field is disabled. Disabled carets render at reduced opacity and
  /// are never tappable, regardless of [onTap].
  final bool isDisabled;

  /// Whether the field currently has errors, for danger-tinted styling.
  final bool hasErrors;

  /// The field's current interaction states (focused, hovered, pressed, disabled),
  /// used to resolve matching colors via [LayrzInputStyleSpec.resolve].
  final Set<WidgetState> states;

  /// Creates a new [_SelectFieldCaret].
  const _SelectFieldCaret({
    required this.onTap,
    required this.isDisabled,
    required this.hasErrors,
    required this.states,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final spec = LayrzInputStyleSpec.resolve(
      states: states,
      tokens: tokens,
      hasErrors: hasErrors,
    );

    final innerR = Radius.circular(
      tokens.radius.innerRadiusValue(
        outerRadius: tokens.radius.r2,
        spacer: spec.borderWidth,
      ),
    );
    final capRadius = BorderRadius.only(topRight: innerR, bottomRight: innerR);

    final dividerColor = hasErrors ? tokens.colors.danger : tokens.colors.divider.withValues(alpha: 0.3);
    final divider = BorderSide(color: dividerColor, width: tokens.border.stroke2);

    final content = Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Icon(
        MdiIcons.chevronDown,
        size: tokens.typography.body.fontSize,
        color: spec.textColor,
      ),
    );

    final tappable = LayrzTappable(
      onTap: isDisabled ? null : onTap,
      disabled: isDisabled,
      borderRadius: capRadius,
      color: spec.backgroundColor,
      hoverColor: tokens.colors.sf3,
      pressedColor: tokens.colors.sf4,
      child: content,
    );

    // Excluded from semantics: the field's own outer `Semantics(button: true)`
    // already announces "opens the picker", and the caret triggers the exact same
    // action -- a second named button here would double-announce one affordance.
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: capRadius,
          color: spec.backgroundColor,
          border: Border(left: divider),
        ),
        child: AnimatedOpacity(
          duration: tokens.motion.dTransition,
          opacity: isDisabled ? 0.5 : 1.0,
          child: tappable,
        ),
      ),
    );
  }
}

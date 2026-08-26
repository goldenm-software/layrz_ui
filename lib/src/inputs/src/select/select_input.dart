import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/inputs.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

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
/// - **Desktop / wide (≥ 960px)**: An anchored overlay panel below the field
/// - **Below `md` breakpoint (< 960px)**: A bottom sheet covering the lower portion of the screen
///
/// This follows decision D52 (adaptive surface) and avoids depending on the dialog system
/// (DESIGN-96/99), keeping the component self-contained and lightweight.
///
/// **Self-display (BREAKING, DESIGN-40/144):** The field renders from its own internal
/// state, not directly from [value]. Picking an item updates the field's display
/// immediately, whether or not the caller feeds an updated [value] back on the next
/// build -- a caller-supplied [value] change is still honored (it reconciles the internal
/// state), but is no longer required for the field to reflect a pick. See the CHANGELOG
/// for the full migration note; this widget was previously a strictly controlled
/// component and is not anymore.
///
/// **Search (when [enableSearch] is true, the default):** the field itself is the
/// searcher -- there is no separate search box in the opened surface. Typing filters the
/// list live; the field is blank while idle (there is no text representation of a selected
/// item's [LayrzSelectItem.child] to show inline -- see [_updateControllerText]), shows the
/// typed query while typing, and reverts to blank on blur if nothing was picked. When
/// [enableSearch] is false, the field is not editable (a pure picker) but still
/// self-displays from internal state -- it just never diverges from the blank idle
/// display, since it never accepts input.
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
  /// Called with the selected [LayrzSelectItem] (or `null` if an item with
  /// `value: null` is selected and [canUnselect] is true).
  /// If no item was selected, this callback is not called.
  final void Function(LayrzSelectItem<T>?)? onChanged;

  /// Whether the field is the searcher for the selection surface.
  ///
  /// Defaults to `true`. When true, the field is editable: it shows the selected
  /// item's label while idle, the typed query while typing, and filters the opened
  /// surface's list live. When false, the field is not editable -- a pure picker --
  /// but still self-displays the selected item's label from internal state; it never
  /// accepts a query because it never accepts input.
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

  /// The padding applied inside the input field.
  ///
  /// If null, defaults to `tokens.spacing.pd2` (10px on regular, 14px on compact).
  final EdgeInsets? padding;

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
    this.padding,
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
  MenuController? _panelController;

  /// The value the field currently displays, independent of [LayrzSelectInput.value]
  /// once a pick has been made locally.
  ///
  /// This is what makes both paths self-display (DESIGN-40/144's redesign): a pick
  /// updates this immediately via [_commitSelection], so the field's own display never
  /// depends on the caller feeding [LayrzSelectInput.value] back. [didUpdateWidget]
  /// still reconciles this with an externally-changed [LayrzSelectInput.value] --
  /// silently, without disturbing a query the user is mid-typing (see [_isQuerying]).
  T? _displayedValue;

  /// Whether the field currently shows a user-typed query rather than the selected
  /// item's idle label.
  ///
  /// Only ever set by [_handleQueryChanged], which fires only for genuine user edits
  /// (never for a programmatic `_controller.text =` assignment) -- and only reachable
  /// at all when [LayrzSelectInput.enableSearch] is true, since the field is read-only
  /// otherwise and never receives edits. Cleared on a committed pick ([_commitSelection])
  /// and on blur with nothing picked ([_handleFieldFocusChanged]), both of which revert
  /// the display to the selected item's label.
  bool _isQuerying = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = TextEditingController();
    _displayedValue = widget.value;
    _updateControllerText();
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
      // Mode 4: reconcile with the caller's own value change, but never clobber
      // a query the user is actively typing -- `_updateControllerText` (and the
      // visible text change it causes) is deferred until the query resolves,
      // via `_isQuerying`'s own revert-on-blur / revert-on-commit paths.
      _displayedValue = widget.value;
      if (!_isQuerying) {
        _updateControllerText();
      }
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

  /// Clears the controller's text (mode 1: idle).
  ///
  /// **BREAKING (DESIGN-142):** this used to set the controller's text to the selected
  /// item's `labelText`, which was then displayed via [LayrzEditableField] itself.
  /// `labelText` is gone from [LayrzSelectItem] -- an item's only presentation is now
  /// [LayrzSelectItem.child], a widget, which this `TextEditingController`-backed field
  /// cannot render inline. There is no text representation of an item left to show, so
  /// the controller is simply kept empty; [_buildField] independently suppresses
  /// [LayrzInputChrome]'s own hint text while a selection exists, so an idle selected
  /// field reads as blank rather than showing the hint underneath nothing. Rendering the
  /// selected item's actual [LayrzSelectItem.child] while idle is tracked as follow-up
  /// work (an overlay-based field redesign), not attempted here. Kept as a named method
  /// (even though it is now a one-liner) because [_commitSelection] and the blur handler
  /// both call it, and its purpose reads better named than inlined.
  void _updateControllerText() {
    _controller.clear();
  }

  /// Handles a genuine user edit to the field's text (mode 2: typing).
  ///
  /// Never invoked for a programmatic `_controller.text =` assignment -- this is wired
  /// to [LayrzEditableFieldConfig.onChanged], which [LayrzEditableField] calls only from
  /// [EditableText]'s own `onChanged`, itself fired only by real user input.
  void _handleQueryChanged(String text) {
    setState(() {
      _isQuerying = true;
    });
  }

  /// Handles the field gaining or losing focus.
  ///
  /// On blur with an unresolved query (mode 3), reverts the display back to blank
  /// (idle) -- the case people forget, so it is a named method rather than inline
  /// logic, and it has its own test.
  void _handleFieldFocusChanged(bool hasFocus) {
    setState(() {
      if (hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
      if (!hasFocus && _isQuerying) {
        _isQuerying = false;
        _updateControllerText();
      }
    });
  }

  /// Commits [item] as the current selection.
  ///
  /// Updates [_displayedValue] and the field's text immediately -- this is what lets
  /// the field self-display without requiring the caller to feed [LayrzSelectInput.value]
  /// back -- then notifies the caller via [LayrzSelectInput.onChanged].
  void _commitSelection(LayrzSelectItem<T>? item) {
    setState(() {
      _displayedValue = item?.value;
      _isQuerying = false;
      _updateControllerText();
    });
    widget.onChanged?.call(item);
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

  /// Refocuses [_focusNode] after [LayrzAnchoredPanel] opens.
  ///
  /// [LayrzAnchoredPanel]'s own `_handlePanelOpenRequested` unconditionally moves
  /// focus to its internal panel-focus node one frame after opening (so Escape and
  /// arrow-key traversal reach the panel). Left alone, that steal would land after
  /// this callback's own single-frame refocus if both raced in the same frame, so
  /// this defers a *second* frame past that steal (an inner `addPostFrameCallback`
  /// registered from within an outer one) to reliably win the race and hand focus
  /// back to the field -- otherwise the field would lose focus the instant the panel
  /// opens, and "the field is the searcher" would be unusable on desktop the moment
  /// a caller actually taps it.
  void _handlePanelOpened() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enableSearch) {
          _focusNode.requestFocus();
        }
      });
    });
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
  /// [onOpen] opens the selection surface -- [MenuController.open] on desktop,
  /// [_openMobileSurface] on mobile. [isExpanded] reports whether the surface is
  /// currently open, for the semantics `expanded` flag (always `false` on mobile,
  /// which has no controller to query).
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

    // Deliberately blank when `_displayedValue` is null, matching `_updateControllerText`'s
    // own guard: a null value means "nothing chosen", so the field must read as empty rather
    // than showing an item that merely happens to also carry a null `value` (a common
    // "None"/clear entry convention). `_findSelectedItem` itself carries no such guard --
    // it is also used for the surface's highlighting, which still treats a null-value item
    // as "the current state" there.
    final selectedItem = _displayedValue == null ? null : _findSelectedItem();

    // Idle (mode 1) shows the selected item's `child`; focused-and-editable (mode 2)
    // shows the `EditableText` query instead. `enableSearch: false` never enters mode 2
    // at all -- it "never diverges from the selected [item]" (class doc) regardless of
    // focus.
    final showChildDisplay = selectedItem != null && (!widget.enableSearch || !_states.contains(WidgetState.focused));

    // Not editable when `enableSearch` is false: a pure picker that still
    // self-displays (mode-logic-free, per the class doc), never a query source.
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: widget.labelText,
      // [LayrzEditableFieldConfig.hintText] is metadata only -- `LayrzEditableField`
      // never reads it; the visible hint is rendered by `LayrzInputChrome` itself, from
      // the `hintText:` passed to it directly below. Kept in sync with that value anyway
      // for consistency with the config's documented contract.
      hintText: selectedItem == null ? widget.hintText : null,
      disabled: widget.disabled,
      readOnly: !widget.enableSearch,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.enableSearch ? _handleQueryChanged : null,
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
      child: Column(
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
          Container(
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
                        // always empty while idle (see `_updateControllerText`), and the
                        // chrome shows this hint whenever the controller reads empty --
                        // so without this it would show through underneath (or beside)
                        // `selectedItem.child` below, as if nothing were selected.
                        hintText: selectedItem == null ? widget.hintText : null,
                        isRequired: widget.isRequired,
                        prefixSlot: prefixSlot,
                        suffixSlot: suffixSlot,
                        disabled: widget.disabled,
                        readOnly: false,
                        errors: widget.errors,
                        hideDetails: widget.hideDetails,
                        states: _states,
                        helpTitleText: widget.helpTitleText,
                        helpContentText: widget.helpContentText,
                        controller: _controller,
                        padding: widget.padding,
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
                                      style: context.titleStyle,
                                      child: selectedItem.child,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
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
        ],
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
      return _buildField(context, onOpen: _openMobileSurface, isExpanded: false);
    } else {
      // Desktop: return anchored panel with selection surface.
      //
      // `maxHeight: 300` is the ONLY height cap for this surface (DESIGN-40):
      // `LayrzAnchoredPanel` already clamps its content to this value and
      // scrolls past it, while shrinking to content when the list is shorter
      // than 300 -- so no fixed-height wrapper is needed here, and the
      // surface itself must not impose a second, disagreeing cap.
      return LayrzAnchoredPanel(
        widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
        maxHeight: 300.0,
        childFocusNode: _focusNode,
        onOpen: _handlePanelOpened,
        builder: (context, controller) {
          _panelController = controller;
          return _buildField(
            context,
            onOpen: controller.open,
            isExpanded: controller.isOpen,
          );
        },
        child: LayrzSelectInputSurface(
          items: widget.items,
          selectedItem: _findSelectedItem(),
          enableSearch: widget.enableSearch,
          canUnselect: widget.canUnselect,
          filter: widget.filter,
          emptyListText: widget.emptyListText,
          panelController: _panelController,
          query: widget.enableSearch && _isQuerying ? _controller.text : '',
          onItemSelected: _commitSelection,
          itemExtent: widget.itemExtent,
        ),
      );
    }
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

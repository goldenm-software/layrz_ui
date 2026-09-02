import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/overlays/overlays.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_footer_slot.dart';
import '../shared/input_slot.dart';
import 'combobox_surface.dart';

/// Maximum height, in logical pixels, of the desktop overlay's option list.
///
/// Fixed, not caller-configurable: the overlay renders [LayrzComboBoxPanelContent]
/// up to this height and scrolls past it. This replaces the former
/// `maxOptionsToDisplay` parameter, which let a caller size the panel by row
/// count using a row-height constant (`48.0`) that did not match the actual
/// rendered row height (~36px) -- the panel it produced was already wrong for
/// any count other than the default.
const double _kComboBoxOverlayMaxHeight = 300.0;

/// A Material-free combobox input in the layrz_ui design system.
///
/// [LayrzComboBoxInput] is an editable input field with a dropdown list of options.
/// It composes [LayrzInputChrome] and the shared editable field primitive directly,
/// adding suggestion filtering and intelligent overlay positioning on top.
///
/// **Desktop vs. Mobile behavior**:
/// - **Desktop (>= 960px)**: Displays [LayrzAnchoredPanel], which covers the field
///   itself (`coverAnchor: true`) -- the same "elevated field" illusion
///   [LayrzSelectInput] uses (DESIGN-145) -- rather than sitting beside it.
/// - **Mobile (< 960px)**: Opens a bottom sheet instead, allowing touch-friendly interaction
///   with better use of screen space.
///
/// **The panel's first row IS the live input (Q3).** Unlike [LayrzSelectInput] --
/// whose field is always read-only, so its opened surface owns a second,
/// independent search field -- this field *is* the input, so typing must keep
/// working uninterrupted across the open transition. When the panel opens, the
/// SAME `TextEditingController` and `FocusNode` instances that back the closed
/// field are handed to the panel's first-row [LayrzEditableField] instead of
/// the closed field's own -- there is only ever one live editable field, one
/// controller, one focus node; only which host currently renders it changes.
/// This is what makes text, caret, and focus continuity structural rather than
/// copied: nothing needs to be seeded or resynced across the transition.
///
/// **Free-form entry** (default): When [allowFreeForm] is true, any text the user types
/// is a valid value -- reported via [onChanged] as the user types, with no separate
/// confirmation step required. On blur or Enter, the field commits whatever is typed.
/// When false, the field reverts to the last matching option on blur.
///
/// **Filtering**: Options are matched case-insensitively from the start of each option.
/// The [enableAutocomplete] flag controls whether filtering is applied (when true, default)
/// or all options are shown unfiltered (when false).
///
/// **Slot exclusivity**: At most one of `prefixIcon` / `prefix` / `prefixText` may be
/// non-null; the same rule applies to the suffix trio. Providing multiple slot values
/// triggers an assertion error in debug mode.
///
/// **Disposal contract**: When `controller` or `focusNode` is null, the widget creates
/// and disposes its own instances. Caller-supplied instances are never disposed.
class LayrzComboBoxInput extends StatefulWidget {
  /// The list of available options to display in the dropdown.
  final List<String> options;

  /// The current value of the input field.
  ///
  /// When set, the field is initialized to this value.
  final String? value;

  /// Callback fired when the input value changes.
  ///
  /// Fires once per genuine keystroke-driven text change while typing, once per
  /// external [value] update, and exactly once per committed selection —
  /// tapping an option in the desktop panel or bottom sheet, committing the
  /// "use '&lt;typed&gt;'" row, or pressing Enter on a highlighted row —
  /// **even when the committed value is identical to the text already shown**
  /// (for example, typing an option's full text and then tapping that same
  /// option, or re-selecting the option already displayed). A commit is
  /// always reported, regardless of how many `TextEditingValue` notifications
  /// the resulting controller assignment produces underneath (see
  /// `_lastNotifiedText` in the implementation for how those extra echoes are
  /// deduped without swallowing the commit itself).
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the input (e.g., presses Enter or picks
  /// an option from the panel or bottom sheet).
  ///
  /// Fires exactly once per commit, unconditionally — including when the
  /// committed value is identical to the text already shown. [onChanged] fires
  /// on every commit too, but also fires on every intermediate keystroke while
  /// typing; a caller that only cares about a deliberate commit — not each
  /// keystroke along the way — should prefer this one.
  final ValueChanged<String>? onSubmit;

  /// Whether free-form text entry is allowed.
  ///
  /// When true (default), any typed text is a valid value. When false, the field
  /// reverts to the last matching option on blur.
  final bool allowFreeForm;

  /// Text to display when no options match the current filter.
  ///
  /// If null, defaults to [LayrzUiL10n.comboboxEmpty].
  final String? emptyOptionsText;

  /// Whether autocomplete filtering is enabled.
  ///
  /// When true (default), options are filtered to match the typed text.
  /// When false, all options are shown regardless of the text.
  final bool enableAutocomplete;

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
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onPrefixTap;

  /// Icon to render as a suffix.
  ///
  /// Mutually exclusive with [suffix] and [suffixText].
  final IconData? suffixIcon;

  /// Widget to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffixText].
  final Widget? suffix;

  /// Text to render as a suffix.
  ///
  /// Mutually exclusive with [suffixIcon] and [suffix].
  final String? suffixText;

  /// Callback fired when the suffix is tapped.
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onSuffixTap;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and other detail text.
  final bool hideDetails;

  /// The text editing controller for the input field.
  ///
  /// If null, a controller is created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// Whether the field uses the dense density variant.
  ///
  /// When false (default), the field's internal padding is 14px on compact
  /// viewports and 10px on regular viewports. When true, padding drops one
  /// spacing level: 10px compact, 6px regular. No other dimension changes.
  /// Applies identically to the closed field and the open panel's own row.
  final bool dense;

  /// The keyboard type for the input field.
  final TextInputType keyboardType;

  /// The text input action (e.g., 'go', 'search', 'send').
  final TextInputAction? textInputAction;

  /// List of input formatters to apply to the input.
  final List<TextInputFormatter> inputFormatters;

  /// The set of text selection actions available in the context menu.
  ///
  /// When null, all four built-in actions (copy, cut, paste, selectAll) are offered.
  /// Pass an explicit set to narrow the list, or `const {}` to suppress the toolbar entirely.
  final Set<LayrzSelectableAction>? actions;

  /// Creates a new [LayrzComboBoxInput] with the given properties.
  const LayrzComboBoxInput({
    required this.options,
    super.key,
    this.value,
    this.onChanged,
    this.onSubmit,
    this.allowFreeForm = true,
    this.emptyOptionsText,
    this.enableAutocomplete = true,
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
    this.readOnly = false,
    this.errors = const [],
    this.hideDetails = false,
    this.controller,
    this.focusNode,
    this.dense = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters = const [],
    this.actions,
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
  State<LayrzComboBoxInput> createState() => _LayrzComboBoxInputState();
}

class _LayrzComboBoxInputState extends State<LayrzComboBoxInput> {
  late TextEditingController _controller;
  late FocusNode _fieldFocusNode;
  MenuController? _panelController;
  String? _lastValidOption;

  /// Identifies the single, shared [LayrzEditableField] across the open
  /// transition (Q3).
  ///
  /// Without this, toggling which host renders the live field (the closed
  /// anchor slot vs. the open panel's first row -- see [_buildFieldChrome]'s
  /// `readOnlyPlaceholder`) would destroy and recreate the [EditableText]
  /// each time: a genuine unmount fires a focus-loss notification on
  /// [_fieldFocusNode] *before* the new instance can request focus, which
  /// [_handleFocusChange] reads as "the user left the field" and reacts to by
  /// closing the panel via [_handleBlur] -- observed directly: a manual open
  /// probe showed the panel's options present for one frame and gone the
  /// next, exactly the unmount/remount window. A stable [GlobalKey] on the
  /// [LayrzEditableField] built in [_buildFieldChrome] instead makes this a
  /// single [Element] reparented within the same frame (both the anchor's
  /// `builder` and the panel's `overlayBuilder` are built inside one
  /// `RawMenuAnchor.build()` pass), so [_fieldFocusNode] is never actually
  /// detached -- no spurious blur, no self-inflicted close.
  final GlobalKey<LayrzEditableFieldState> _sharedFieldKey = GlobalKey<LayrzEditableFieldState>();

  /// Highlight index across the filtered options list. `-1` means no option
  /// is highlighted. See [_navigableRowCount] and [_commitHighlighted].
  int _highlightedIndex = -1;

  /// The text last reported to [LayrzComboBoxInput.onChanged].
  ///
  /// `TextEditingController`'s notifications fire on any change to its
  /// `TextEditingValue` — not just the text itself. A bare cursor tap changes only
  /// the selection and still notifies; more subtly, `EditableText` resyncs its own
  /// selection immediately after a programmatic `controller.text =` assignment
  /// (to keep the cursor within the new text's bounds), which notifies a *second*
  /// time with the text unchanged from the first notification. [_handleTextChange]
  /// compares against this field so [_LayrzComboBoxInputState] reports a change to
  /// [LayrzComboBoxInput.onChanged] only when the text itself actually moved,
  /// exactly once per genuine change — regardless of how many `TextEditingValue`
  /// notifications that change happens to produce underneath.
  ///
  /// [_commitValue] also writes to this field directly, *before* it assigns
  /// `_controller.text`. That write-ahead is what lets a commit notify
  /// [LayrzComboBoxInput.onChanged] itself (unconditionally, exactly once) while
  /// still using this same dedupe to swallow the assignment's own echo
  /// notifications — rather than, as a prior version did, using the dedupe as the
  /// *only* path to `onChanged` and having it silently swallow the commit whenever
  /// the committed value already matched the displayed text.
  String _lastNotifiedText = '';

  /// The current interaction states fed to [LayrzInputChrome].
  ///
  /// Carries only [WidgetState.disabled] and [WidgetState.focused] — set in [build]
  /// for disabled, and in the editable field config's `onFocusChanged` callback for
  /// focused. Hover and press live inside [LayrzEditableField]'s own private state.
  final Set<WidgetState> _states = {};

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _fieldFocusNode = widget.focusNode ?? FocusNode();

    // Initialize with the provided value if any
    if (widget.value != null) {
      _controller.text = widget.value!;
      _lastValidOption = widget.value;
    }

    _lastNotifiedText = _controller.text;
    _fieldFocusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(LayrzComboBoxInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      // The listener must always be removed from the outgoing controller,
      // regardless of ownership: an externally-supplied controller survives
      // this swap, so leaving the listener attached leaks it onto a
      // controller this state no longer tracks.
      _controller.removeListener(_handleTextChange);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChange);
      _lastNotifiedText = _controller.text;
    }

    // Handle focus node changes
    if (widget.focusNode != oldWidget.focusNode) {
      _fieldFocusNode.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _fieldFocusNode.dispose();
      }
      _fieldFocusNode = widget.focusNode ?? FocusNode();
      _fieldFocusNode.addListener(_handleFocusChange);
    }

    // If value changed externally, update
    if (widget.value != oldWidget.value && widget.value != null) {
      _controller.text = widget.value!;
      _lastValidOption = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _fieldFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _fieldFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_fieldFocusNode.hasFocus) {
      _handleBlur();
    }
  }

  void _handleTextChange() {
    setState(() {
      _highlightedIndex = -1;
    });

    final currentText = _controller.text;
    if (currentText == _lastNotifiedText) {
      // See [_lastNotifiedText]: this notification's text is identical to the one
      // already reported, so it is a selection-only echo, not a real change.
      return;
    }
    _lastNotifiedText = currentText;
    widget.onChanged?.call(currentText);
  }

  /// Closes the panel and, if free-form entry is disallowed, reverts the
  /// field's text — invoked on any loss of [_fieldFocusNode]'s focus.
  void _handleBlur() {
    // Deferred, and re-checked, rather than acted on synchronously: opening
    // the desktop panel briefly unfocuses `_fieldFocusNode` mid-gesture --
    // `EditableText`'s own tap handling loses focus for an instant before
    // `LayrzEditableField`'s own gesture recognizer re-requests it, and the
    // panel's own `onOpen` callback (see `build`) also explicitly moves
    // focus onto the panel's own field row via a double post-frame callback,
    // mirroring the exact race `LayrzSelectInputSurface` documents against
    // `LayrzAnchoredPanel`'s internal focus steal. Closing synchronously on
    // that transient blip would tear the panel down one frame after it
    // opened, before the user ever saw it (observed directly: a manual open
    // probe showed the panel's options present for one frame and gone the
    // next). Posting this check to the frame after every focus-driven
    // refocus has had a chance to run means a *genuine* loss of focus (tab
    // away, a real outside click, the window itself losing focus) still
    // closes the panel -- it is simply no longer treated as genuine before
    // this frame's own focus traffic has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_fieldFocusNode.hasFocus) return;
        _panelController?.close();
      });
    });

    // If allowFreeForm is false, revert to last valid option
    if (!widget.allowFreeForm && _lastValidOption != null) {
      _controller.text = _lastValidOption!;
    }
  }

  /// Filters options based on current text.
  List<String> _getFilteredOptions() {
    if (!widget.enableAutocomplete) {
      return widget.options;
    }

    final text = _controller.text.toLowerCase();
    if (text.isEmpty) {
      return widget.options;
    }

    return widget.options.where((option) => option.toLowerCase().startsWith(text)).toList();
  }

  /// The number of navigable rows in the currently open panel: the filtered
  /// options. Used to keep [_highlightedIndex] within bounds across
  /// arrow-key navigation.
  int _navigableRowCount() {
    return _getFilteredOptions().length;
  }

  void _openOverlay() {
    if (context.isCompact) {
      _openBottomSheet();
    } else {
      _panelController?.open();
    }
  }

  Future<void> _openBottomSheet() async {
    final filtered = _getFilteredOptions();
    final selected = await LayrzBottomSheet.show<String?>(
      context,
      builder: (context) => BottomSheetContent(
        options: filtered,
        emptyText: widget.emptyOptionsText ?? context.l10n.comboboxEmpty,
        labelText: widget.labelText,
      ),
      // BottomSheetContent renders a plain Column, never a same-axis ListView, so
      // it needs no lazy-loading scrollable of its own — but it still needs a
      // *bounded* incoming height to scroll within. scrollable: false hands it the
      // sheet's own ScrollController via an ambient PrimaryScrollController instead
      // of nesting it inside the sheet's SingleChildScrollView, so this content's
      // own SingleChildScrollView receives a real bound directly from the sheet's
      // Expanded region and shares the sheet's drag/scroll handoff.
      scrollable: false,
    );

    // The sheet reports the selection solely by popping with a value — see
    // BottomSheetContent's doc comment for why there is no second, callback-based
    // commit path here.
    if (selected != null) {
      _commitValue(selected);
    }
  }

  void _commitValue(String value) {
    // A commit (tapping an option, pressing Enter on a highlighted row, or
    // picking from the bottom sheet) always reports `onChanged`, exactly
    // once — including when `value` already
    // matches the field's current text (typing an option's full text and
    // then tapping it, or re-selecting the option already shown). Writing
    // `_lastNotifiedText` and calling `onChanged` *before* touching the
    // controller is what makes that hold: the assignment below still routes
    // through `_handleTextChange`, but by the time it fires,
    // `_lastNotifiedText` already equals `value`, so that notification — and
    // the second one from `EditableText`'s post-assignment selection resync
    // — are both deduped as echoes of the call just made here, rather than
    // the sole source of the notification.
    _lastNotifiedText = value;
    widget.onChanged?.call(value);

    _controller.text = value;
    _lastValidOption = value;
    widget.onSubmit?.call(value);
    _panelController?.close();
    _fieldFocusNode.unfocus();
  }

  /// Commits the option [_highlightedIndex] currently points at, invoked on Enter.
  void _commitHighlighted() {
    if (_highlightedIndex < 0) return;

    final filtered = _getFilteredOptions();
    if (_highlightedIndex < filtered.length) {
      _commitValue(filtered[_highlightedIndex]);
    }
  }

  /// Builds the field row shared, by instance, between the closed field and
  /// the open panel's first row (Q3). [readOnlyPlaceholder] renders a
  /// non-editable visual stand-in instead of the real [LayrzEditableField] —
  /// used for the closed-field slot while the panel is open, since
  /// `coverAnchor: true` means the panel already renders the real, focused
  /// field in exactly the same position; mounting a second [EditableText]
  /// bound to the same [FocusNode] there would conflict with the panel's.
  ///
  /// [isPanelRow] distinguishes the panel's own first row from every other
  /// caller of this function (the closed desktop field, and the compact/mobile
  /// field, both of which render standalone and need their own border to read
  /// as an input at all). The user's own framing: "the panel's input IS the
  /// field's input, continuing" -- so when this row sits *inside*
  /// `LayrzAnchoredPanel`'s already-bordered, already-rounded container, it
  /// must not draw a second border and a second rounded rect of its own. Doing
  /// so drew a bordered, rounded box nested inside the panel's own bordered,
  /// rounded box -- a self-contained "field" floating in the dropdown, which
  /// read as a search bar sitting above a results list (the user's own words:
  /// "partially search, partially just a TextInput") rather than the closed
  /// field's border simply continuing uninterrupted into the panel. Mirrors
  /// how `LayrzSelectInputSurface._buildSearchField` suppresses its own border
  /// for the identical reason (`showBorder: false`) -- see
  /// `select_input_surface.dart:307`.
  ///
  /// **`labelText`/`errors` are never passed to the inner [LayrzInputChrome]
  /// here** (`labelText: null`, `hideDetails: true`) -- [build] renders both
  /// outside this row instead, mirroring `LayrzSelectInput._appendExtras` and
  /// `LayrzDurationInput._buildInteractiveField`. This is load-bearing, not
  /// cosmetic: on desktop this chrome IS the anchor handed to
  /// `LayrzAnchoredPanel.builder`, and with `coverAnchor: true` the opened
  /// panel positions itself against that anchor's own rect. A label rendered
  /// *inside* the chrome extends the anchor's rect upward by the label's own
  /// height, so the panel would land on top of the label instead of the field
  /// underneath it -- measured directly before this fix: the panel's top
  /// landed exactly on the label's top, 24.0 logical pixels above the actual
  /// bordered field box, at the showroom's own configuration.
  Widget _buildFieldChrome(
    BuildContext context, {
    required VoidCallback onOpen,
    required bool readOnlyPlaceholder,
    bool isPanelRow = false,
  }) {
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

    final fieldConfig = LayrzEditableFieldConfig(
      labelText: widget.labelText,
      hintText: widget.hintText,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      errors: widget.errors,
      controller: _controller,
      focusNode: _fieldFocusNode,
      // Deliberately null: `_handleTextChange` is already registered as a
      // listener on `_controller` and wiring `onChanged` too would fire the
      // callback twice.
      onChanged: null,
      onSubmit: (_) => _commitHighlighted(),
      onFocusChanged: (isFocused) {
        setState(() {
          if (isFocused) {
            _states.add(WidgetState.focused);
          } else {
            _states.remove(WidgetState.focused);
          }
        });
      },
      onTap: () {
        if (!widget.disabled && !widget.readOnly) {
          onOpen();
        }
      },
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: null,
      autofocus: false,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: true,
      enableSuggestions: true,
      actions: widget.actions,
      minLines: 1,
      maxLines: 1,
      expands: false,
    );

    return LayrzInputChrome(
      // Deliberately null/true -- see the doc comment above on why the label
      // and error footer must never live inside this chrome.
      labelText: null,
      hintText: widget.hintText,
      isRequired: widget.isRequired,
      prefixSlot: prefixSlot,
      suffixSlot: suffixSlot,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      errors: widget.errors,
      hideDetails: true,
      states: _states,
      helpTitleText: widget.helpTitleText,
      helpContentText: widget.helpContentText,
      controller: _controller,
      dense: widget.dense,
      // Only the panel's own row suppresses its border/radius (see the class
      // doc on `isPanelRow`) -- the closed field (desktop or compact) always
      // keeps both, since nothing else draws a border around it.
      showBorder: !isPanelRow,
      borderRadius: isPanelRow ? BorderRadius.zero : null,
      child: readOnlyPlaceholder
          ? ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => Text(
                value.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : LayrzEditableField(key: _sharedFieldKey, config: fieldConfig),
    );
  }

  /// Builds the panel's content: the live input row and the filtered option
  /// list — see [LayrzComboBoxPanelContent].
  Widget _buildPanelContent(BuildContext context) {
    final filtered = _getFilteredOptions();
    final emptyText = widget.emptyOptionsText ?? context.l10n.comboboxEmpty;

    final fieldRow = _buildFieldChrome(
      context,
      onOpen: () {},
      readOnlyPlaceholder: false,
      isPanelRow: true,
    );

    return LayrzComboBoxPanelContent(
      fieldRow: fieldRow,
      options: filtered,
      highlightedIndex: _highlightedIndex,
      onSelected: _commitValue,
      emptyText: emptyText,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCompact = context.isCompact;
    final isOpen = _panelController?.isOpen ?? false;

    if (!isOpen) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (!isCompact) {
          _openOverlay();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    final rowCount = _navigableRowCount();
    if (rowCount == 0) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1) % rowCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = (_highlightedIndex - 1 + rowCount) % rowCount;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < rowCount) {
        _commitHighlighted();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _panelController?.close();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompact;

    final Widget anchor = isCompact
        ? _buildFieldChrome(context, onOpen: _openOverlay, readOnlyPlaceholder: false)
        : LayrzAnchoredPanel(
            widthPolicy: LayrzAnchoredPanelWidthPolicy.matchAnchor,
            coverAnchor: true,
            maxHeight: _kComboBoxOverlayMaxHeight,
            childFocusNode: _fieldFocusNode,
            onOpen: () {
              setState(() {
                _highlightedIndex = -1;
              });

              // Focus must land on the panel's own input (Q3), not on
              // `LayrzAnchoredPanel`'s internal `_panelFocusNode`. The
              // panel requests focus on its own node via a post-frame
              // callback in `_handlePanelOpenRequested`, registered
              // *before* `widget.onOpen` (this callback) runs — so a
              // single post-frame callback here would lose that race
              // (fire first, get stolen from one tick later). Nesting a
              // second callback inside the first pushes this request to
              // the frame after that steal, mirroring the exact fix
              // `LayrzSelectInputSurface` uses for the same race.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _fieldFocusNode.requestFocus();
                });
              });
            },
            onClose: () {
              setState(() {
                _highlightedIndex = -1;
              });
            },
            builder: (context, controller) {
              _panelController = controller;
              return _buildFieldChrome(
                context,
                onOpen: controller.open,
                readOnlyPlaceholder: controller.isOpen,
              );
            },
            border: LayrzAnchoredPanelBorder(
              color: widget.errors.isNotEmpty ? context.tokens.colors.danger : context.tokens.colors.primary,
              width: context.tokens.border.base,
            ),
            child: Builder(builder: _buildPanelContent),
          );

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled && !widget.readOnly,
      expanded: _panelController?.isOpen ?? false,
      onTap: (widget.disabled || widget.readOnly) ? null : _openOverlay,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: _appendExtras(anchor, context.tokens),
      ),
    );
  }

  /// Wraps [child] -- the anchor passed to [Semantics]/[Focus] in [build] --
  /// with the label above (when [LayrzComboBoxInput.labelText] is non-null)
  /// and the error/counter footer below, both rendered OUTSIDE [child]
  /// entirely.
  ///
  /// Mirrors `LayrzSelectInput._appendExtras` and
  /// `LayrzDurationInput._buildInteractiveField`'s identical composition, for
  /// the identical reason (see the doc comment on [_buildFieldChrome]):
  /// [child] is -- on desktop -- the exact anchor [LayrzAnchoredPanel] reads
  /// to position the opened overlay via `coverAnchor: true`. A label or error
  /// footer rendered inside that anchor would grow its rect and shift the
  /// overlay off the field it is meant to cover.
  ///
  /// **The footer is never gated on the label.** An earlier version of this
  /// method (copied from `LayrzSelectInput`, which carries the identical bug)
  /// short-circuited to `return child` whenever [LayrzComboBoxInput.labelText]
  /// was null, which meant [LayrzComboBoxInput.errors] rendered nothing at all
  /// on a field with no label -- a field with an error and no label showed no
  /// error text whatsoever. Only the label row itself is conditional now; this
  /// method always wraps in the [Column] so [LayrzInputFooterSlot] renders
  /// whenever it has something to show, independent of [labelText].
  Widget _appendExtras(Widget child, LayrzTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

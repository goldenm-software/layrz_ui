import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/sheets/sheets.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_footer_slot.dart';
import '../shared/input_slot.dart';
import 'combobox_surface.dart';

/// A Material-free combobox input in the layrz_ui design system.
///
/// [LayrzComboBoxInput] is an editable input field with a dropdown list of options.
/// It composes [LayrzInputChrome] and the shared editable field primitive directly,
/// adding suggestion filtering and intelligent overlay positioning on top.
///
/// **Desktop vs. Mobile behavior**:
/// - **Desktop (>= 960px)**: Opens [LayrzEndDrawer] (DESIGN-98), hosting the
///   same [BottomSheetContent] surface the mobile band opens -- see
///   [_LayrzComboBoxInputState._openDesktopDrawer] for why this replaced the
///   previous `LayrzAnchoredPanel`, and why that also means the field no
///   longer continues live into the opened surface (Q3 below no longer
///   applies once this widget adopted [LayrzEndDrawer]; kept here as
///   historical context for readers of the diff).
/// - **Mobile (< 960px)**: Opens a bottom sheet, allowing touch-friendly interaction
///   with better use of screen space.
///
/// **Q3, historical: the panel's first row WAS the live input, before
/// DESIGN-98.** Unlike [LayrzSelectInput] -- whose field is always read-only,
/// so its opened surface owns a second, independent search field -- this
/// field *is* the input conceptually, so before DESIGN-98 the SAME
/// `TextEditingController`/`FocusNode` instances backing the closed field were
/// reparented into the open `LayrzAnchoredPanel`'s first row via a stable
/// `GlobalKey`, letting text/caret/focus continue uninterrupted across the
/// open transition. That trick depended on `RawMenuAnchor` building both the
/// anchor and the overlay in one pass -- a route pushed via
/// [Navigator.push] (what [LayrzEndDrawer] and [LayrzBottomSheet] both are)
/// has no such shared pass to reparent across, so DESIGN-98 retires this
/// entirely: both bands now open a wholly independent [BottomSheetContent]
/// surface with its own search field, exactly like the mobile band already
/// did. **This is a real, user-visible behavior change on desktop:** the
/// drawer opens with an empty search field rather than continuing whatever
/// the closed field's own text and caret position already were.
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
  String? _lastValidOption;

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
    final currentText = _controller.text;
    if (currentText == _lastNotifiedText) {
      // See [_lastNotifiedText]: this notification's text is identical to the one
      // already reported, so it is a selection-only echo, not a real change.
      return;
    }
    _lastNotifiedText = currentText;
    widget.onChanged?.call(currentText);
  }

  /// If free-form entry is disallowed, reverts the field's text — invoked on
  /// any loss of [_fieldFocusNode]'s focus.
  ///
  /// **No longer closes anything (post-DESIGN-98).** Before DESIGN-98, this
  /// also closed the open `LayrzAnchoredPanel` on a genuine loss of focus,
  /// deferred and re-checked across two post-frame callbacks to tolerate the
  /// transient blur `RawMenuAnchor`'s own focus handoff caused. Now that the
  /// closed field never keeps its focus node live inside an open overlay --
  /// [LayrzEndDrawer] and [LayrzBottomSheet] both host a wholly independent
  /// [BottomSheetContent] with its own focus node instead (see the class doc)
  /// -- a blur here is never that transient handoff; it is simply the user
  /// leaving the closed field, and there is no panel left to close in
  /// response.
  void _handleBlur() {
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

  void _openOverlay() {
    if (context.isCompact) {
      _openBottomSheet();
    } else {
      _openDesktopDrawer();
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

  /// Opens the option list in [LayrzEndDrawer] on desktop (DESIGN-98),
  /// replacing the previous `LayrzAnchoredPanel` hosting.
  ///
  /// **The Q3 "same live field continues into the panel" trick does not carry
  /// over, and this is a real behavior change from before DESIGN-98.** That
  /// trick depended structurally on `RawMenuAnchor` building the closed
  /// field's anchor and the open panel's overlay in one and the same build
  /// pass, letting a stable `GlobalKey` reparent a single `Element` instead of
  /// unmounting and remounting it (see the class doc's Q3 section).
  /// [LayrzEndDrawer] is [Navigator.push]ed as a separate route -- there is no
  /// shared build pass for a `GlobalKey` to reparent across, so the field the
  /// user was typing into and the drawer's own content are unavoidably two
  /// separate widget subtrees. Rather than fight that boundary (and risk
  /// reintroducing the exact focus-loss-closes-the-panel race
  /// [_handleBlur] was written against, this time across a route boundary
  /// instead of a single frame), this reuses [BottomSheetContent] verbatim --
  /// the same self-contained surface the mobile branch already uses, with its
  /// own independent search field, filtering [_getFilteredOptions] pool taken
  /// at open time, and commit-by-pop contract (see that class's own doc for
  /// why it has no callback-based commit path). This makes desktop's drawer
  /// behavior consistent with mobile's sheet instead of continuing to differ
  /// from it, at the cost of the closed field's typed text and caret position
  /// not continuing into the drawer -- the drawer opens with its own empty
  /// search field instead of the closed field's current text.
  ///
  /// **Title (DESIGN-98 follow-up).** [LayrzEndDrawer.show]'s `title` slot
  /// renders [widget.labelText] as a real title (headline, left-aligned) --
  /// [BottomSheetContent.showInlineTitle] is `false` here so that widget does
  /// not ALSO render its own small, caption-styled inline heading for the
  /// same text; passing both would stack a title over a duplicate caption.
  /// The mobile bottom sheet path above keeps `showInlineTitle`'s default
  /// (`true`) unchanged, since [LayrzBottomSheet] has no title slot of its
  /// own to defer to.
  Future<void> _openDesktopDrawer() async {
    final filtered = _getFilteredOptions();
    final selected = await LayrzEndDrawer.show<String?>(
      context,
      semanticLabel: widget.labelText,
      title: widget.labelText == null ? null : Text(widget.labelText!),
      builder: (context) => BottomSheetContent(
        options: filtered,
        emptyText: widget.emptyOptionsText ?? context.l10n.comboboxEmpty,
        labelText: widget.labelText,
        showInlineTitle: false,
      ),
    );

    if (selected != null) {
      _commitValue(selected);
    }
  }

  /// Commits [value] -- tapping an option or picking from the bottom sheet or
  /// drawer, both of which report solely by popping with the selected value
  /// (see [BottomSheetContent]'s own doc for why there is no second,
  /// callback-based commit path).
  void _commitValue(String value) {
    // A commit always reports `onChanged`, exactly once — including when
    // `value` already matches the field's current text (typing an option's
    // full text and then tapping it, or re-selecting the option already
    // shown). Writing `_lastNotifiedText` and calling `onChanged` *before*
    // touching the controller is what makes that hold: the assignment below
    // still routes through `_handleTextChange`, but by the time it fires,
    // `_lastNotifiedText` already equals `value`, so that notification — and
    // the second one from `EditableText`'s post-assignment selection resync
    // — are both deduped as echoes of the call just made here, rather than
    // the sole source of the notification.
    _lastNotifiedText = value;
    widget.onChanged?.call(value);

    _controller.text = value;
    _lastValidOption = value;
    widget.onSubmit?.call(value);
    _fieldFocusNode.unfocus();
  }

  /// Builds the closed field's own bordered row.
  ///
  /// **Post-DESIGN-98: this is the field's only rendering, on both bands.**
  /// Before DESIGN-98, this function also rendered the open desktop
  /// `LayrzAnchoredPanel`'s first row -- a second, border/radius-suppressed
  /// mode distinguished by a since-removed `isPanelRow` flag, load-bearing
  /// because that panel covered the field in place (`coverAnchor: true`) and
  /// needed the two rows to read as one continuous field rather than two
  /// nested bordered boxes. Now that both bands open a wholly independent
  /// [BottomSheetContent] surface instead (see the class doc's Q3 section),
  /// there is only ever one row for this function to build, and it always
  /// keeps its own border -- exactly like [LayrzSelectInput]'s and
  /// [LayrzDurationInput]'s closed fields.
  ///
  /// **`labelText`/`errors` are still never passed to the inner
  /// [LayrzInputChrome] here** (`labelText: null`, `hideDetails: true`) --
  /// [build] renders both outside this row instead, mirroring
  /// `LayrzSelectInput._appendExtras` and
  /// `LayrzDurationInput._buildInteractiveField`.
  Widget _buildFieldChrome(
    BuildContext context, {
    required VoidCallback onOpen,
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
      // Enter on the closed field opens the overlay, mirroring arrow-down in
      // `_handleKeyEvent` -- post-DESIGN-98 there is no in-place highlighted
      // row on the closed field left to commit (see `_handleKeyEvent`'s own
      // doc for why that navigation moved entirely into the opened
      // BottomSheetContent surface).
      onSubmit: (_) => _openOverlay(),
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
      child: LayrzEditableField(config: fieldConfig),
    );
  }

  /// Handles keyboard events on the closed field.
  ///
  /// **Reduced scope, post-DESIGN-98.** Before DESIGN-98, this also drove
  /// arrow-key highlight navigation and Enter/Escape while the desktop
  /// `LayrzAnchoredPanel` was open in place, since that panel's option rows
  /// lived in the same subtree as this field. Now that opening the overlay
  /// always pushes a separate [LayrzEndDrawer]/[LayrzBottomSheet] route
  /// hosting its own independent [BottomSheetContent] -- with its own
  /// [Focus]/key handling, mirroring [LayrzSelectInputSurface]'s identical
  /// self-contained pattern -- there is no in-place option list left for this
  /// handler to navigate. It keeps exactly the one job that still belongs to
  /// the closed field: opening the overlay on arrow-down.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown && !context.isCompact) {
      _openOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Both bands render the same standalone field now (DESIGN-98): desktop no
    // longer continues this same live field into an overlay that covers it
    // (see [_openDesktopDrawer]'s own doc for why the Q3 shared-field trick
    // does not survive a route boundary) -- it opens [LayrzEndDrawer] hosting
    // an independent [BottomSheetContent], exactly like the compact band
    // already opens [LayrzBottomSheet] hosting the same widget.
    final anchor = _buildFieldChrome(context, onOpen: _openOverlay);

    return Semantics(
      label: widget.labelText,
      button: true,
      enabled: !widget.disabled && !widget.readOnly,
      // Always false, post-DESIGN-98: there is no `MenuController` left to
      // query for a live open/closed state (both the drawer and the bottom
      // sheet are routes, not a queryable controller) -- mirrors
      // `LayrzSelectInput`'s identical `isExpanded: false` on both of its own
      // bands after its own DESIGN-98 conversion. Still explicitly `false`,
      // not omitted: passing a literal bool (rather than leaving `expanded`
      // null) is what keeps `hasExpandedState` true in the semantics tree,
      // announcing this as an expandable control even though its live state
      // is not tracked.
      expanded: false,
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
  /// `LayrzDurationInput._buildInteractiveField`'s identical composition.
  /// Post-DESIGN-98 this is no longer load-bearing for anchor positioning the
  /// way it was under `LayrzAnchoredPanel.coverAnchor` (see [_buildFieldChrome]'s
  /// own doc) -- [LayrzEndDrawer] and [LayrzBottomSheet] both position
  /// themselves independently of this field's rect -- but the composition is
  /// kept identical to the other DESIGN-98 inputs regardless, for the same
  /// label/footer placement every one of them uses.
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

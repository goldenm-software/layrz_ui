import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/keyboard/keyboard.dart';
import 'package:layrz_ui/src/selection/selection.dart';

import 'editable_field.dart';
import 'input_chrome.dart';
import 'input_slot.dart';

/// A Material-free text input field in the layrz_ui design system.
///
/// [LayrzTextInput] is a single-line text input with optional label, prefix/suffix slots,
/// error display, help affordance, and keyboard shortcut badging. It wraps [EditableText]
/// to provide a themed, ready-to-use input control.
///
/// **Slot exclusivity**: At most one of `prefixIcon` / `prefix` / `prefixText` may be
/// non-null; the same rule applies to the suffix trio. Providing multiple slot values
/// triggers an assertion error in debug mode.
///
/// **Disposal contract**: When `controller` or `focusNode` is null, the widget creates
/// and disposes its own instances. Caller-supplied instances are never disposed.
///
/// **Interaction states**:
/// - **Disabled**: Not editable, not tappable. Callbacks do not fire.
/// - **Read-only**: Not editable but tap callbacks fire (used by picker-style inputs).
/// - **Error**: Renders danger-colored border and error icon, displays error messages below.
/// - **Read-only lock icon**: Appears only in read-only state, never in disabled state.
class LayrzTextInput extends StatefulWidget {
  /// The label text displayed above the input field.
  ///
  /// At least one of [labelText] or [hintText] must be non-null.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  ///
  /// At least one of [labelText] or [hintText] must be non-null.
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

  /// Callback fired when the input value changes.
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the input (e.g., presses Enter).
  final ValueChanged<String>? onSubmit;

  /// Callback fired when the input gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Callback fired when the field is tapped.
  ///
  /// Ignored if the field is disabled. Fires even if the field is read-only.
  final VoidCallback? onTap;

  /// The text editing controller for the input field.
  ///
  /// If null, a controller is created and disposed by the widget.
  final TextEditingController? controller;

  /// The focus node for the input field.
  ///
  /// If null, a focus node is created and disposed by the widget.
  final FocusNode? focusNode;

  /// The padding applied inside the input field.
  ///
  /// If null, defaults to `tokens.spacing.pd2` (8px all sides).
  final EdgeInsets? padding;

  /// The keyboard type for the input field.
  final TextInputType keyboardType;

  /// The text input action (e.g., 'go', 'search', 'send').
  final TextInputAction? textInputAction;

  /// List of input formatters to apply to the input.
  final List<TextInputFormatter> inputFormatters;

  /// Maximum length of the input text.
  ///
  /// If provided, a [LengthLimitingTextInputFormatter] is automatically appended.
  final int? maxLength;

  /// Whether the field should request focus on creation.
  final bool autofocus;

  /// The text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// List of autofill hints for platform autofill services.
  final List<String> autofillHints;

  /// Whether the input text should be obscured (for passwords).
  final bool obscureText;

  /// Whether autocorrection is enabled.
  final bool autocorrect;

  /// Whether suggestions are enabled.
  final bool enableSuggestions;

  /// The keyboard shortcut set to display as a muted badge.
  ///
  /// Display-only; does not bind any functionality. Automatically hidden on mobile.
  final Set<LogicalKeyboardKey>? shortcut;

  /// The set of text selection actions available in the context menu.
  ///
  /// When null, all four built-in actions (copy, cut, paste, selectAll) are offered.
  /// Pass an explicit set to narrow the list, or `const {}` to suppress the toolbar entirely.
  /// The set is further intersected with what the field's state permits, so an obscured
  /// field never offers copy or cut regardless of what is passed here.
  final Set<LayrzSelectableAction>? actions;

  /// Library-private: Whether to suppress the read-only lock icon.
  ///
  /// Used by picker-style inputs that want to be read-only but display their own
  /// affordance (e.g., a dropdown chevron) instead of a lock icon.
  final bool _suppressReadOnlyLock;

  /// Creates a new [LayrzTextInput] with the given properties.
  const LayrzTextInput({
    super.key,
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
    this.onChanged,
    this.onSubmit,
    this.onFocusChanged,
    this.onTap,
    this.controller,
    this.focusNode,
    this.padding,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters = const [],
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints = const [],
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.shortcut,
    this.actions,
    bool suppressReadOnlyLock = false,
    // ignore: prefer_initializing_formals
  }) : _suppressReadOnlyLock = suppressReadOnlyLock,
       assert(
         labelText != null || hintText != null,
         'At least one of labelText or hintText must be non-null.',
       ),
       assert(
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
  State<LayrzTextInput> createState() => _LayrzTextInputState();
}

class _LayrzTextInputState extends State<LayrzTextInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If controller changed, update the reference
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
    }
    // If focusNode changed, update the reference
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    // Only dispose if we created them
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve slots
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

    // Compute states
    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    // Format shortcut for display
    final shortcutText = widget.shortcut != null ? formatLayrzShortcut(widget.shortcut) : null;

    // Create the editable field configuration
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: widget.labelText,
      hintText: widget.hintText,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmit: widget.onSubmit,
      onFocusChanged: (isFocused) {
        setState(() {
          if (isFocused) {
            _states.add(WidgetState.focused);
          } else {
            _states.remove(WidgetState.focused);
          }
        });
        widget.onFocusChanged?.call(isFocused);
      },
      onTap: widget.onTap,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      actions: widget.actions,
      minLines: 1,
      maxLines: 1,
      expands: false,
    );

    return LayrzInputChrome(
      labelText: widget.labelText,
      hintText: widget.hintText,
      isRequired: widget.isRequired,
      prefixSlot: prefixSlot,
      suffixSlot: suffixSlot,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      errors: widget.errors,
      hideDetails: widget.hideDetails,
      states: _states,
      shortcutText: shortcutText,
      helpTitleText: widget.helpTitleText,
      helpContentText: widget.helpContentText,
      controller: _controller,
      padding: widget.padding,
      maxLength: widget.maxLength,
      suppressReadOnlyLock: widget._suppressReadOnlyLock,
      child: Listener(
        onPointerDown: widget.disabled ? null : _updateStates,
        onPointerUp: widget.disabled ? null : _updateStates,
        onPointerCancel: widget.disabled ? null : _updateStates,
        child: MouseRegion(
          onEnter: widget.disabled ? null : (_) => setState(() => _states.add(WidgetState.hovered)),
          onExit: widget.disabled ? null : (_) => setState(() => _states.remove(WidgetState.hovered)),
          child: gestureDetectorBuilder.buildGestureDetector(
            child: EditableText(
              key: _editableTextKey,
              rendererIgnoresPointer: true,
              controller: _controller,
              focusNode: _focusNode,
              style: tokens.typography.body.copyWith(
                color: spec.textColor,
              ),
              cursorColor: tokens.colors.primary,
              backgroundCursorColor: tokens.colors.fg3,
              selectionColor: tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity),
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: formatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmit,
              onSelectionChanged: _handleSelectionChanged,
              readOnly: widget.readOnly || widget.disabled,
              textCapitalization: widget.textCapitalization,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              autofillHints: widget.autofillHints.isNotEmpty ? widget.autofillHints : null,
              paintCursorAboveText: true,
              showSelectionHandles: _showSelectionHandles,
              selectionControls: LayrzTextSelectionControls.instance,
              contextMenuBuilder: _cachedContextMenuBuilder,
              magnifierConfiguration: _cachedMagnifierConfiguration ?? const TextMagnifierConfiguration(),
              maxLines: 1,
              minLines: 1,
              expands: false,
            ),
          ),
        ),
      ),
    );
  }
}

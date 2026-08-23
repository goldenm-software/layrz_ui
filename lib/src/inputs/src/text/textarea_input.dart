import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/selection/selection.dart';

import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_slot.dart';

/// A Material-free multi-line text input field in the layrz_ui design system.
///
/// [LayrzTextAreaInput] is a multi-line text input with optional label, prefix/suffix slots,
/// error display, help affordance, and character counter. It wraps [EditableText] through
/// the shared [LayrzEditableField] to provide consistent selection, magnifier, and context
/// menu behavior across single-line and multi-line inputs.
///
/// **Line limits**: The field grows from [minLines] (default 3) up to [maxLines] (default 10).
/// Once [maxLines] is reached, the field scrolls internally rather than continuing to grow.
/// Both bounds must be positive, and [minLines] must not exceed [maxLines].
///
/// **Keyboard behavior**: Enter inserts a newline by default. The [textInputAction] is set to
/// [TextInputAction.newline] if not explicitly provided. If you need to handle form submission,
/// combine the Enter key with an explicit keyboard action (e.g., [TextInputAction.send]).
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
class LayrzTextAreaInput extends StatefulWidget {
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

  /// Callback fired when the input value changes.
  final ValueChanged<String>? onChanged;

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
  /// If null, defaults to `tokens.spacing.pd2` (10px regular / 14px compact on all sides).
  final EdgeInsets? padding;

  /// The keyboard type for the input field.
  ///
  /// Defaults to [TextInputType.multiline] for multi-line text entry.
  final TextInputType keyboardType;

  /// The text input action (e.g., 'go', 'search', 'send').
  ///
  /// Defaults to [TextInputAction.newline] to insert newlines instead of submitting.
  final TextInputAction? textInputAction;

  /// List of input formatters to apply to the input.
  final List<TextInputFormatter> inputFormatters;

  /// Maximum length of the input text.
  ///
  /// If provided, a [LengthLimitingTextInputFormatter] is automatically appended
  /// and a character counter is displayed below the field.
  final int? maxLength;

  /// The minimum number of lines the field occupies.
  ///
  /// Defaults to 3. Must be a positive integer not exceeding [maxLines].
  final int minLines;

  /// The maximum number of lines before the field becomes scrollable.
  ///
  /// Defaults to 10. Must be a positive integer not less than [minLines].
  /// Once exceeded, the field scrolls internally rather than growing further.
  final int maxLines;

  /// Whether the field should request focus on creation.
  final bool autofocus;

  /// The text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// List of autofill hints for platform autofill services.
  final List<String> autofillHints;

  /// Whether autocorrection is enabled.
  final bool autocorrect;

  /// Whether suggestions are enabled.
  final bool enableSuggestions;

  /// The set of text selection actions available in the context menu.
  ///
  /// When null, all four built-in actions (copy, cut, paste, selectAll) are offered.
  /// Pass an explicit set to narrow the list, or `const {}` to suppress the toolbar entirely.
  /// The set is further intersected with what the field's state permits, so a read-only
  /// field never offers cut or paste regardless of what is passed here.
  final Set<LayrzSelectableAction>? actions;

  /// Creates a new [LayrzTextAreaInput] with the given properties.
  const LayrzTextAreaInput({
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
    this.onFocusChanged,
    this.onTap,
    this.controller,
    this.focusNode,
    this.padding,
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.inputFormatters = const [],
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 10,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints = const [],
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.actions,
  }) : assert(
         minLines > 0,
         'minLines must be a positive integer.',
       ),
       assert(
         maxLines > 0,
         'maxLines must be a positive integer.',
       ),
       assert(
         minLines <= maxLines,
         'minLines ($minLines) must not exceed maxLines ($maxLines).',
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
  State<LayrzTextAreaInput> createState() => _LayrzTextAreaInputState();
}

class _LayrzTextAreaInputState extends State<LayrzTextAreaInput> {
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
  void didUpdateWidget(LayrzTextAreaInput oldWidget) {
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
    final tokens = context.tokens;

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

    // Create the editable field configuration
    final fieldConfig = LayrzEditableFieldConfig(
      labelText: widget.labelText,
      hintText: widget.hintText,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmit: null, // Don't submit on Enter in multiline mode
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
      obscureText: false, // TextArea does not support obscureText
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      actions: widget.actions,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      expands: false,
    );

    // Calculate the minimum content height from minLines
    // Content height is approximately fontSize * lineHeightMultiplier * lineCount
    final fontSize = tokens.typography.body.fontSize ?? 16.0;
    final lineHeightMultiplier = tokens.typography.body.height ?? 1.0;
    final lineHeight = fontSize * lineHeightMultiplier;
    final minContentHeight = (lineHeight * widget.minLines).ceil().toDouble();

    // Calculate the maximum content height from maxLines
    final maxContentHeight = (lineHeight * widget.maxLines).ceil().toDouble();

    final isDisabled = widget.disabled || widget.readOnly;

    return Semantics(
      label: widget.labelText,
      enabled: !isDisabled,
      child: LayrzInputChrome.variableHeight(
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
        helpTitleText: widget.helpTitleText,
        helpContentText: widget.helpContentText,
        controller: _controller,
        padding: widget.padding,
        maxLength: widget.maxLength,
        minContentHeight: minContentHeight,
        maxContentHeight: maxContentHeight,
        child: LayrzEditableField(config: fieldConfig),
      ),
    );
  }
}

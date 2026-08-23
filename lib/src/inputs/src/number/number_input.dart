import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'decimal_separator.dart';
import '../shared/input_footer_slot.dart';
import '../shared/input_style_spec.dart';
import 'number_field_edge.dart';
import '../text/text_input.dart';

/// A Material-free numeric input field in the layrz_ui design system.
///
/// [LayrzNumberInput] is a specialized input control for entering numeric values (`int` or `double`).
/// It composes [LayrzTextInput] with flanking increment/decrement buttons (`+`/`−`) and provides:
///
/// - **Decimal separator control**: Caller specifies whether to parse/format with dot or comma
/// - **Numeric input enforcement**: By default, only numeric characters are accepted. Letters,
///   symbols, and non-configured separators are rejected at the keystroke. When [inputFormatters]
///   is supplied, it fully replaces the built-in numeric formatter, giving the caller complete
///   responsibility for keystroke filtering. Bounds ([minimum]/[maximum]) are not enforced on
///   typing; the step buttons clamp at limits, but the field accepts any numeric value.
/// - **Decimal precision**: [maximumDecimalDigits] limits precision (default 4, max 15)
/// - **Number formatting**: Formats values for display with the chosen separator
/// - **Input filtering**: By default enforces numeric-only input. Supply [inputFormatters] to
///   override completely and define your own keystroke filtering rules.
///
/// **Disposal contract**: When `controller` or `focusNode` is null, the widget creates and disposes
/// its own instances. Caller-supplied instances are never disposed.
///
/// **Value contract**: The `value` parameter holds the parsed numeric value (or `null` if empty
/// or unparseable). The `onChanged` callback fires with `null` when input cannot be parsed, or with
/// the parsed `num` when parsing succeeds.
///
/// **Step button behavior**:
/// - When [hideStepButtons] is false (default), the `+` and `−` buttons appear inside the field
///   at the trailing and leading edges respectively
/// - Buttons are flanked by optional prefix/suffix widgets and vertical dividers
/// - Buttons clamp at [minimum] (decrement disabled) and [maximum] (increment disabled)
/// - When [hideStepButtons] is true, the field renders as plain text input with prefix/suffix intact
/// - Buttons are disabled (not hidden) when [readOnly] is true; hidden when [disabled] is true
///
/// **Prefix and suffix**:
/// - [prefixIcon], [prefix], or [prefixText]: Rendered inside the field after the `−` button and divider
/// - [suffixIcon], [suffix], or [suffixText]: Rendered inside the field before the `+` button and divider
/// - Use these for currency symbols, units, or other value context
/// - At most one prefix and one suffix may be specified (same exclusivity as [LayrzTextInput])
class LayrzNumberInput extends StatefulWidget {
  /// The current numeric value displayed in the field.
  ///
  /// When null, the field renders empty. The field interprets null as "no value yet",
  /// not as a distinct state like 0.
  final num? value;

  /// Callback fired when the numeric value changes.
  ///
  /// Called with `null` when the input text is empty or cannot be parsed as a number.
  /// Called with the parsed `num` when valid input is entered via keyboard or step buttons.
  /// Not called from internal formatting operations.
  final ValueChanged<num?>? onChanged;

  /// The decimal separator used when parsing and formatting numbers.
  ///
  /// [LayrzDecimalSeparator.dot] uses `"3.14"` format.
  /// [LayrzDecimalSeparator.comma] uses `"3,14"` format.
  ///
  /// This choice is explicit and does not respond to device locale, ensuring
  /// parsing is stable across locale changes.
  final LayrzDecimalSeparator decimalSeparator;

  /// Optional formatter callback for the parsed numeric value.
  ///
  /// If provided, the field calls this function to format the number for display
  /// after parsing. Receive the parsed `num` and return a formatted `String`.
  /// For example: `(num n) => n.toStringAsFixed(2)`.
  final String Function(num)? format;

  /// Optional list of input formatters to apply to the input field.
  ///
  /// When null (default), the field applies its built-in numeric formatter that enforces
  /// numeric-only input based on [decimalSeparator], [minimum], and [maximumDecimalDigits].
  /// When provided, this list **fully replaces** the built-in numeric formatter. The caller
  /// takes complete responsibility for keystroke filtering and is responsible for their
  /// interaction with [decimalSeparator] and [maximumDecimalDigits]. The built-in numeric
  /// constraints are **not** applied when this is non-null.
  final List<TextInputFormatter>? inputFormatters;

  /// The minimum allowed numeric value.
  ///
  /// The decrement button is disabled when the value reaches this limit.
  /// Typed input is not blocked; validation is the caller's responsibility.
  final num? minimum;

  /// The maximum allowed numeric value.
  ///
  /// The increment button is disabled when the value reaches this limit.
  /// Typed input is not blocked; validation is the caller's responsibility.
  final num? maximum;

  /// The amount to increment or decrement when a step button is pressed.
  ///
  /// Defaults to 1. Can be fractional (e.g., 0.5, 0.1).
  final num step;

  /// The maximum number of decimal digits to allow after the decimal separator.
  ///
  /// Defaults to 4. Must be >= 0 and <= 15 (enforced by assertion).
  /// When the user types more digits than this limit, the field truncates
  /// or rejects the excess (formatter honors this).
  final int maximumDecimalDigits;

  /// Whether to hide the increment/decrement buttons.
  ///
  /// When true, the field renders as a plain text input with no step buttons.
  /// Prefix and suffix are unaffected. Useful for compact layouts or when manual number entry is preferred.
  final bool hideStepButtons;

  /// Icon to render as a prefix (before the value, after the `−` button).
  ///
  /// Mutually exclusive with [prefix] and [prefixText].
  final IconData? prefixIcon;

  /// Widget to render as a prefix (before the value, after the `−` button).
  ///
  /// Mutually exclusive with [prefixIcon] and [prefixText].
  final Widget? prefix;

  /// Text to render as a prefix (before the value, after the `−` button).
  ///
  /// Mutually exclusive with [prefixIcon] and [prefix].
  final String? prefixText;

  /// Callback fired when the prefix is tapped.
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onPrefixTap;

  /// Icon to render as a suffix (after the value, before the `+` button).
  ///
  /// Mutually exclusive with [suffix] and [suffixText].
  final IconData? suffixIcon;

  /// Widget to render as a suffix (after the value, before the `+` button).
  ///
  /// Mutually exclusive with [suffixIcon] and [suffixText].
  final Widget? suffix;

  /// Text to render as a suffix (after the value, before the `+` button).
  ///
  /// Mutually exclusive with [suffixIcon] and [suffix].
  final String? suffixText;

  /// Callback fired when the suffix is tapped.
  ///
  /// Ignored if the field is disabled.
  final VoidCallback? onSuffixTap;

  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is marked as required.
  final bool isRequired;

  /// Whether the field is disabled (not editable, not tappable).
  final bool disabled;

  /// Whether the field is read-only (not editable but tap callbacks fire).
  final bool readOnly;

  /// The list of error messages to display below the field.
  final List<String> errors;

  /// Whether to hide the error message block and character counter.
  final bool hideDetails;

  /// Helper text displayed below the field.
  ///
  /// When [errors] is non-empty, errors take precedence and helper text is hidden.
  final String? helperText;

  /// The title text for the help affordance tooltip.
  final String? helpTitleText;

  /// The content text for the help affordance tooltip.
  final String? helpContentText;

  /// Callback fired when the input gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Callback fired when the field is tapped.
  final VoidCallback? onTap;

  /// Callback fired when the user submits the input (e.g., presses Enter).
  final ValueChanged<String>? onSubmit;

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
  /// If null, defaults to `tokens.spacing.pd2` (10px on regular viewports, 14px on compact).
  final EdgeInsets? padding;

  /// Whether the input should request focus on creation.
  final bool autofocus;

  /// Creates a new [LayrzNumberInput] with the given properties.
  ///
  /// [maximumDecimalDigits] must be between 0 and 15 inclusive (debug assertion).
  /// At most one of [prefixIcon] / [prefix] / [prefixText] may be non-null (debug assertion).
  /// At most one of [suffixIcon] / [suffix] / [suffixText] may be non-null (debug assertion).
  const LayrzNumberInput({
    super.key,
    this.value,
    this.onChanged,
    this.decimalSeparator = LayrzDecimalSeparator.dot,
    this.format,
    this.minimum,
    this.maximum,
    this.step = 1,
    this.maximumDecimalDigits = 4,
    this.hideStepButtons = false,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.onPrefixTap,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.onSuffixTap,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.disabled = false,
    this.readOnly = false,
    this.errors = const [],
    this.hideDetails = false,
    this.helperText,
    this.helpTitleText,
    this.helpContentText,
    this.onFocusChanged,
    this.onTap,
    this.onSubmit,
    this.controller,
    this.focusNode,
    this.padding,
    this.autofocus = false,
    this.inputFormatters,
  }) : assert(
         maximumDecimalDigits >= 0 && maximumDecimalDigits <= 15,
         'maximumDecimalDigits must be between 0 and 15 inclusive.',
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
  State<LayrzNumberInput> createState() => _LayrzNumberInputState();
}

class _LayrzNumberInputState extends State<LayrzNumberInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isInternalUpdate = false;
  final Set<WidgetState> _states = {};

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.onKeyEvent = _handleKeyEvent;
    _updateControllerFromValue(widget.value);
  }

  @override
  void didUpdateWidget(LayrzNumberInput oldWidget) {
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
    // If value changed externally, update the controller
    if (widget.value != oldWidget.value) {
      _updateControllerFromValue(widget.value);
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

  /// Updates the text controller to display the given numeric value, formatted.
  void _updateControllerFromValue(num? value) {
    _isInternalUpdate = true;
    if (value == null) {
      _controller.text = '';
    } else {
      final formatted = _formatNumber(value);
      _controller.text = formatted;
    }
    _isInternalUpdate = false;
  }

  /// Parses the current controller text as a number, respecting the decimal separator.
  /// Returns null if the text is empty or cannot be parsed.
  num? _parseNumber(String text) {
    if (text.isEmpty) {
      return null;
    }

    // Normalize to dot separator for parsing
    final normalized = widget.decimalSeparator == LayrzDecimalSeparator.comma ? text.replaceAll(',', '.') : text;

    try {
      final parsed = num.parse(normalized);
      return parsed;
    } catch (e) {
      return null;
    }
  }

  /// Formats a number for display, using the configured decimal separator and formatter.
  String _formatNumber(num value) {
    // Apply custom formatter if provided
    String formatted = widget.format?.call(value) ?? value.toString();

    // Replace dot with the configured separator if needed
    if (widget.decimalSeparator == LayrzDecimalSeparator.comma) {
      formatted = formatted.replaceAll('.', ',');
    }

    return formatted;
  }

  /// Handles changes from the text field, parsing and emitting onChanged.
  void _handleTextChanged(String text) {
    if (_isInternalUpdate) {
      return;
    }

    final parsed = _parseNumber(text);
    widget.onChanged?.call(parsed);
  }

  /// Increments the value by [step] and calls onChanged.
  void _handleIncrement() {
    final currentValue = _parseNumber(_controller.text) ?? 0;
    num newValue = currentValue + widget.step;

    // Clamp at maximum if set
    if (widget.maximum != null && newValue > widget.maximum!) {
      newValue = widget.maximum!;
    }

    _updateControllerFromValue(newValue);
    widget.onChanged?.call(newValue);
  }

  /// Decrements the value by [step] and calls onChanged.
  void _handleDecrement() {
    final currentValue = _parseNumber(_controller.text) ?? 0;
    num newValue = currentValue - widget.step;

    // Clamp at minimum if set
    if (widget.minimum != null && newValue < widget.minimum!) {
      newValue = widget.minimum!;
    }

    _updateControllerFromValue(newValue);
    widget.onChanged?.call(newValue);
  }

  /// Returns true if the decrement button should be disabled (at minimum).
  bool _isDecrementDisabled() {
    final currentValue = _parseNumber(_controller.text) ?? 0;
    if (widget.minimum != null) {
      return currentValue <= widget.minimum!;
    }
    return false;
  }

  /// Returns true if the increment button should be disabled (at maximum).
  bool _isIncrementDisabled() {
    final currentValue = _parseNumber(_controller.text) ?? 0;
    if (widget.maximum != null) {
      return currentValue >= widget.maximum!;
    }
    return false;
  }

  /// Handles keyboard events for stepping (ArrowUp/Down, PageUp/Down).
  ///
  /// Only processes [KeyDownEvent] to prevent double-firing on repeat/up events.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Guard on KeyDownEvent only to prevent double-firing on repeat/up events
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Check for arrow keys and page keys
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (!widget.readOnly && !widget.disabled && !_isIncrementDisabled()) {
        _handleIncrement();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!widget.readOnly && !widget.disabled && !_isDecrementDisabled()) {
        _handleDecrement();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      if (!widget.readOnly && !widget.disabled && !_isIncrementDisabled()) {
        final currentValue = _parseNumber(_controller.text) ?? 0;
        num newValue = currentValue + (widget.step * 10);
        if (widget.maximum != null && newValue > widget.maximum!) {
          newValue = widget.maximum!;
        }
        _updateControllerFromValue(newValue);
        widget.onChanged?.call(newValue);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      if (!widget.readOnly && !widget.disabled && !_isDecrementDisabled()) {
        final currentValue = _parseNumber(_controller.text) ?? 0;
        num newValue = currentValue - (widget.step * 10);
        if (widget.minimum != null && newValue < widget.minimum!) {
          newValue = widget.minimum!;
        }
        _updateControllerFromValue(newValue);
        widget.onChanged?.call(newValue);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Build the input formatters list
    // When the caller supplies inputFormatters, use them exclusively (full override).
    // Otherwise, apply the built-in numeric formatter that enforces numeric-only input.
    final formatters =
        widget.inputFormatters ??
        <TextInputFormatter>[
          _NumericInputFormatter(
            decimalSeparator: widget.decimalSeparator,
            maximumDecimalDigits: widget.maximumDecimalDigits,
            allowNegative: widget.minimum == null || widget.minimum! < 0,
          ),
        ];

    // Resolve prefix and suffix from the caller's parameters
    final userPrefix = _resolvePrefix();
    final userSuffix = _resolveSuffix();

    // Determine if we should show buttons
    final showButtons = !widget.hideStepButtons && !widget.disabled;
    final hasErrors = widget.errors.isNotEmpty;

    // Manage states for the edge controls
    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    if (showButtons) {
      // New layout: label → [−] [chrome] [+] → error block
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
          // Row with controls and chrome, wrapped in a single-bordered container
          _buildNumberInputRow(
            tokens: tokens,
            formatters: formatters,
            userPrefix: userPrefix,
            userSuffix: userSuffix,
            hasErrors: hasErrors,
          ),
          // Error block and character counter below the entire row
          LayrzInputFooterSlot(
            errors: widget.errors,
            hideDetails: widget.hideDetails,
            maxLength: null,
            controller: _controller,
            helperText: widget.helperText,
          ),
        ],
      );
    } else {
      // No buttons: render as plain text input (hideStepButtons is true)
      return LayrzTextInput(
        labelText: widget.labelText,
        hintText: widget.hintText,
        isRequired: widget.isRequired,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        hideDetails: widget.hideDetails,
        helpTitleText: widget.helpTitleText,
        helpContentText: widget.helpContentText,
        onChanged: _handleTextChanged,
        onFocusChanged: widget.onFocusChanged,
        onTap: widget.onTap,
        onSubmit: widget.onSubmit,
        controller: _controller,
        focusNode: _focusNode,
        padding: widget.padding,
        keyboardType: TextInputType.number,
        inputFormatters: formatters,
        autofocus: widget.autofocus,
        textAlign: TextAlign.center,
        prefix: userPrefix,
        suffix: userSuffix,
        onPrefixTap: widget.onPrefixTap,
        onSuffixTap: widget.onSuffixTap,
      );
    }
  }

  /// Builds the number input row with unified border and dividers.
  ///
  /// Creates a single [Container] with a unified border wrapping the entire control,
  /// including decrement cap, chrome, and increment cap. This ensures non-uniform
  /// borders with rounded corners are drawn with the stroked-RRect path (antialiasing-friendly)
  /// rather than the non-uniform fill path.
  Widget _buildNumberInputRow({
    required LayrzTokens tokens,
    required List<TextInputFormatter> formatters,
    required Widget? userPrefix,
    required Widget? userSuffix,
    required bool hasErrors,
  }) {
    // Resolve the style spec once for the entire control
    final spec = LayrzInputStyleSpec.resolve(
      states: _states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: widget.readOnly,
    );

    final isDisabled = widget.disabled || widget.readOnly;

    return Semantics(
      label: widget.labelText,
      enabled: !isDisabled,
      child: Container(
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          border: Border.all(
            color: spec.borderColor,
            width: spec.borderWidth,
          ),
          borderRadius: tokens.radius.br2,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Decrement control (full height, no border/radius)
              NumberFieldControl(
                onTap: (widget.readOnly || _isDecrementDisabled()) ? null : _handleDecrement,
                isDisabled: widget.readOnly || _isDecrementDisabled(),
                hasErrors: hasErrors,
                states: _states,
                readOnly: widget.readOnly,
                isLeft: true,
              ),

              // Chrome (no border/radius, filled by outer container)
              Expanded(
                child: LayrzTextInput(
                  hintText: widget.hintText,
                  isRequired: widget.isRequired,
                  disabled: widget.disabled,
                  readOnly: widget.readOnly,
                  hideDetails: widget.hideDetails,
                  helpTitleText: widget.helpTitleText,
                  helpContentText: widget.helpContentText,
                  onChanged: _handleTextChanged,
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
                  onSubmit: widget.onSubmit,
                  controller: _controller,
                  focusNode: _focusNode,
                  padding: widget.padding,
                  keyboardType: TextInputType.number,
                  inputFormatters: formatters,
                  autofocus: widget.autofocus,
                  textAlign: TextAlign.center,
                  prefix: userPrefix,
                  suffix: userSuffix,
                  onPrefixTap: widget.onPrefixTap,
                  onSuffixTap: widget.onSuffixTap,
                  borderRadius: BorderRadius.zero,

                  showBorder: false,
                ),
              ),

              // Increment control (full height, no border/radius)
              NumberFieldControl(
                onTap: (widget.readOnly || _isIncrementDisabled()) ? null : _handleIncrement,
                isDisabled: widget.readOnly || _isIncrementDisabled(),
                hasErrors: hasErrors,
                states: _states,
                readOnly: widget.readOnly,
                isLeft: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolves the caller's prefix (icon/widget/text) into a single widget or null.
  Widget? _resolvePrefix() {
    if (widget.prefixIcon != null) {
      return Icon(widget.prefixIcon);
    } else if (widget.prefix != null) {
      return widget.prefix;
    } else if (widget.prefixText != null) {
      return Text(widget.prefixText!);
    }
    return null;
  }

  /// Resolves the caller's suffix (icon/widget/text) into a single widget or null.
  Widget? _resolveSuffix() {
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon);
    } else if (widget.suffix != null) {
      return widget.suffix;
    } else if (widget.suffixText != null) {
      return Text(widget.suffixText!);
    }
    return null;
  }
}

/// A custom [TextInputFormatter] that enforces numeric input based on configuration.
///
/// Restricts input to digits, the configured decimal separator, and (optionally) a leading minus sign.
/// Enforces [maximumDecimalDigits] limit on the fractional part. Invalid characters are filtered out,
/// allowing intermediate typing states (empty, lone minus, trailing separator) to work smoothly.
class _NumericInputFormatter extends TextInputFormatter {
  /// The decimal separator to accept (`.` or `,`).
  final LayrzDecimalSeparator decimalSeparator;

  /// The maximum number of decimal digits allowed.
  final int maximumDecimalDigits;

  /// Whether negative values are allowed (true if minimum is null or < 0).
  final bool allowNegative;

  /// Creates a new [_NumericInputFormatter] with the given configuration.
  _NumericInputFormatter({
    required this.decimalSeparator,
    required this.maximumDecimalDigits,
    required this.allowNegative,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Empty input is always allowed
    if (text.isEmpty) {
      return newValue;
    }

    // Build the separator character
    final separator = decimalSeparator == LayrzDecimalSeparator.dot ? '.' : ',';

    // Filter the text, keeping only valid characters
    final buffer = StringBuffer();
    var hasLeadingMinus = false;
    var hasSeparator = false;
    var decimalDigitCount = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Minus is allowed only at the start and only if negatives are allowed
      if (char == '-') {
        if (i == 0 && allowNegative && !hasLeadingMinus) {
          buffer.write(char);
          hasLeadingMinus = true;
          continue;
        } else {
          // Reject any other minus (not at start, or duplicates, or not allowed)
          continue;
        }
      }

      // Digits are always allowed
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        if (hasSeparator) {
          // We're in the fractional part
          if (decimalDigitCount < maximumDecimalDigits) {
            buffer.write(char);
            decimalDigitCount++;
          }
          // Skip if we exceed the decimal digit limit
        } else {
          // Before the separator
          buffer.write(char);
        }
        continue;
      }

      // The separator is allowed (once, and not if we don't allow decimals)
      if (char == separator && !hasSeparator && maximumDecimalDigits > 0) {
        buffer.write(char);
        hasSeparator = true;
        decimalDigitCount = 0;
        continue;
      }

      // Any other character is skipped (filtered out)
    }

    final formattedText = buffer.toString();

    // If the formatted text differs from the input, the user tried to enter invalid characters
    // But we still accept the valid part, so return the formatted text
    if (formattedText == text) {
      return newValue;
    } else {
      // Return the filtered text with the same selection position (or adjusted if text was shortened)
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }
  }
}

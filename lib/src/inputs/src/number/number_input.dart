import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/l10n/l10n.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'decimal_separator.dart';
import '../shared/editable_field.dart';
import '../shared/input_chrome.dart';
import '../shared/input_footer_slot.dart';
import '../shared/input_slot.dart';
import '../shared/input_style_spec.dart';
import 'number_field_edge.dart';
import 'numeric_input_formatter.dart';

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

  /// Whether the field uses the dense density variant.
  ///
  /// When false (default), the field's internal padding is 14px on compact
  /// viewports and 10px on regular viewports. When true, padding drops one
  /// spacing level: 10px compact, 6px regular. No other dimension changes.
  final bool dense;

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
    this.dense = false,
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

  /// The [_isDecrementDisabled] result the most recent [build] actually rendered.
  ///
  /// Refreshed **only** inside [build] — never here in the lifecycle methods and never by
  /// [_handleControllerValueChanged] itself — so it always describes what is on screen,
  /// including when the predicate changes for a reason other than controller text (a
  /// [LayrzNumberInput.minimum]/[LayrzNumberInput.maximum] prop change, or a controller
  /// swap in [didUpdateWidget]). [didUpdateWidget] always triggers a rebuild, and that
  /// rebuild recomputes and stores this field before [_handleControllerValueChanged] can
  /// next fire on the new controller, so no re-seed is needed in the controller-swap block
  /// below — deliberately absent, not an oversight. A cache instead maintained by the
  /// listener (mirroring `_wasEmpty` in [LayrzSearchInput]) would need exactly such a
  /// re-seed on every swap, and silently drift without one.
  bool _lastDecrementDisabled = false;

  /// The [_isIncrementDisabled] result the most recent [build] actually rendered.
  ///
  /// See [_lastDecrementDisabled].
  bool _lastIncrementDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateControllerFromValue(widget.value);
    _controller.addListener(_handleControllerValueChanged);
  }

  @override
  void didUpdateWidget(LayrzNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If controller changed, update the reference
    if (widget.controller != oldWidget.controller) {
      // The listener must always come off the outgoing controller, regardless of
      // ownership: an externally-supplied controller survives this swap, so leaving the
      // listener attached leaks it onto a controller this state no longer tracks — and it
      // would then call setState on a defunct State after this widget unmounts.
      // ChangeNotifier.removeListener is documented safe on a disposed instance.
      _controller.removeListener(_handleControllerValueChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleControllerValueChanged);
      // No `_last*Disabled` re-seed here, deliberately: this method always ends in a
      // rebuild, and `build()` recomputes both predicates unconditionally from whichever
      // controller is now current — see the doc comment on `_lastDecrementDisabled`.
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
    // Unconditional removal first, then dispose only what this state owns — mirrors the
    // controller-swap handling in didUpdateWidget above.
    _controller.removeListener(_handleControllerValueChanged);
    // Only dispose if we created them
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Rebuilds the field when a controller change flips either step cap's disabled state.
  ///
  /// Deliberately **not** gated on [_isInternalUpdate]. Every stepping path — both
  /// [_handleIncrement]/[_handleDecrement] and all four branches of [_handleKeyEvent] —
  /// writes through [_updateControllerFromValue], which raises that flag for the duration
  /// of the write. Copying the guard from [_handleTextChanged] (whose job is to suppress a
  /// re-entrant `onChanged` on internally-driven writes) would make this listener fire on
  /// typing only and silently skip the keyboard and cap-tap paths — two of the three paths
  /// it exists to cover. The bug would look fixed and would not be. See DESIGN-150.
  ///
  /// The rebuild is gated on an actual flip instead: [TextEditingController] is a
  /// [ValueNotifier] over [TextEditingValue] and notifies on selection and composing
  /// changes too, so an unguarded listener would rebuild on every caret move. The
  /// comparison basis ([_lastDecrementDisabled]/[_lastIncrementDisabled]) is maintained by
  /// [build], not by this method — see that field's doc comment for why.
  void _handleControllerValueChanged() {
    if (_isDecrementDisabled() == _lastDecrementDisabled && _isIncrementDisabled() == _lastIncrementDisabled) {
      return;
    }
    setState(() {});
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
  /// Installed as the [Focus.onKeyEvent] handler of the ancestor [Focus] widget
  /// built in [build] — not assigned directly onto [_focusNode]. That ancestor
  /// wraps whichever [FocusNode] is currently in use (own or hoisted by the
  /// caller via [LayrzNumberInput.focusNode]) without ever attaching itself to
  /// that node, so key events bubble up to it from the editable field
  /// regardless of node swaps, and Flutter tears the handler down automatically
  /// with the [Focus] widget's own lifecycle — it can never outlive this
  /// [State], so a caller-hoisted [FocusNode] can never retain a stale
  /// reference to a disposed [State] after this widget unmounts.
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
          NumericInputFormatter(
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

    // Computed once per build and cached in `_last*Disabled`, so `_handleControllerValueChanged`
    // has a comparison basis that always describes what is actually rendered — see the doc
    // comment on `_lastDecrementDisabled`. Computed unconditionally on both branches (the
    // no-step-buttons branch renders no caps) so the invariant holds with no branch to reason
    // about. Also removes the double evaluation each cap previously caused (`onTap:` and
    // `isDisabled:` each called the predicate separately).
    final decrementDisabled = _isDecrementDisabled();
    final incrementDisabled = _isIncrementDisabled();
    _lastDecrementDisabled = decrementDisabled;
    _lastIncrementDisabled = incrementDisabled;

    // True on both the "no step buttons" branch and the "disabled" branch, which routes
    // through the same plain-chrome layout even when hideStepButtons is false.
    final isDisabledOverall = widget.disabled || widget.readOnly;

    // Semantic label, suffixed with the localized "required" indicator so a screen-reader
    // user is told the field is required — the visible `*` above lives inside
    // ExcludeSemantics and never reaches accessibility on its own. Copied verbatim from
    // LayrzTextAreaInput (textarea_input.dart:371-374), which shipped the same pattern
    // under DESIGN-115.
    final l10n = LayrzUiL10n.of(context);
    final semanticLabel = widget.isRequired && widget.labelText != null
        ? '${widget.labelText}, ${l10n.inputsRequiredIndicator}'
        : widget.labelText;

    // Semantic tooltip built from the help affordance (caller-supplied text), joined the
    // same way as LayrzTextAreaInput (textarea_input.dart:376-383). Null when neither
    // help field is set, so `tooltip:` is omitted rather than announced as an empty string.
    //
    // Note: the chrome's own help icon (`_HelpAffordance` -> `LayrzTooltip`,
    // input_chrome.dart:539-548 / tooltip.dart:531-532) already sets
    // `Semantics(tooltip: helpContentText)` on itself, content-only, no title. Unlike the
    // hintText case above, this does NOT double-announce: the explicit `tooltip:` set here
    // on the field's own (ancestor) node takes precedence in the merge, so the richer
    // "title. content" string this widget builds is what actually surfaces — confirmed by
    // Phase 3's failure proof, where removing this derivation exposed the icon's bare
    // "content-only" tooltip instead of the value going missing outright.
    String? semanticTooltip;
    if (widget.helpTitleText != null || widget.helpContentText != null) {
      semanticTooltip = [
        if (widget.helpTitleText != null) widget.helpTitleText,
        if (widget.helpContentText != null) widget.helpContentText,
      ].join('. ');
    }

    // Deliberately NOT deriving a `hint:` value here. DESIGN-116's Phase 0 semantics dump
    // proved that LayrzInputChrome already renders hintText as a plain, non-excluded Text
    // (input_chrome.dart:417/:436) that Flutter merges straight into this field's own
    // label — e.g. labelText: 'Amount', hintText: 'Enter price' announces as a single
    // two-line label "Amount\nEnter price" on both branches. Adding `hint: widget.hintText`
    // on top of that would announce the hint a second time. See test T12 for the pinned
    // shape. (This also means LayrzTextAreaInput, which does set `hint:` while rendering
    // through the same chrome, has a latent double-announcement — reported upstream,
    // out of this unit's file set.)

    // Manage states for the edge controls
    if (widget.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    // Built by either branch below, then handed to the outer [Focus] wrapper
    // returned at the end of this method.
    final Widget content;

    if (showButtons) {
      // New layout: label → [−] [chrome] [+] → error block
      content = Column(
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
            semanticLabel: semanticLabel,
            semanticTooltip: semanticTooltip,
            decrementDisabled: decrementDisabled,
            incrementDisabled: incrementDisabled,
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
      // No buttons: render the chrome directly (hideStepButtons is true, or disabled is true).
      // This is the branch that was silently dropping `errors` (see the failing-first tests).
      final prefixSlot = resolvePrefixSlot(prefix: userPrefix, onPrefixTap: widget.onPrefixTap);
      final suffixSlot = resolveSuffixSlot(suffix: userSuffix, onSuffixTap: widget.onSuffixTap);
      final fieldConfig = _buildFieldConfig(formatters);

      content = Semantics(
        label: semanticLabel,
        tooltip: semanticTooltip,
        enabled: !isDisabledOverall,
        child: LayrzInputChrome(
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
          dense: widget.dense,
          helperText: widget.helperText,
          child: LayrzEditableField(config: fieldConfig),
        ),
      );
    }

    // Ancestor [Focus] that intercepts stepping keys for whichever [FocusNode]
    // is currently focused inside [content] (own or hoisted — see
    // [_handleKeyEvent]). It never attaches to [_focusNode] itself: doing so
    // would double-attach the node also passed to the descendant
    // [LayrzEditableField]/[EditableText], which independently hosts it via
    // its own internal `Focus(focusNode: ...)`. `skipTraversal` and
    // `canRequestFocus: false` keep this purely an interception point, so it
    // is never itself selected by Tab/Shift+Tab traversal and the field
    // remains the only focus stop this widget contributes.
    return Focus(
      onKeyEvent: _handleKeyEvent,
      skipTraversal: true,
      canRequestFocus: false,
      child: content,
    );
  }

  /// Shared focus-change handler that keeps [_states] in sync with [WidgetState.focused]
  /// before forwarding to [LayrzNumberInput.onFocusChanged].
  ///
  /// Used by both chrome configurations (with and without step buttons) so the chrome's
  /// focus border reacts identically on either branch.
  void _handleFocusChangedForStates(bool isFocused) {
    setState(() {
      if (isFocused) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
    });
    widget.onFocusChanged?.call(isFocused);
  }

  /// Builds the [LayrzEditableFieldConfig] shared by both chrome configurations.
  ///
  /// [formatters] is the resolved list built once in [build] (either the caller's
  /// [LayrzNumberInput.inputFormatters] override or the built-in [NumericInputFormatter]).
  ///
  /// [LayrzEditableFieldConfig.labelText] and [.hintText] are metadata carried by the config
  /// only — [LayrzEditableField] never reads them to render anything; the visual label and
  /// hint are entirely the chrome's responsibility. Passing [LayrzNumberInput.labelText] and
  /// [LayrzNumberInput.hintText] here on both branches is therefore harmless even though the
  /// step-buttons branch's chrome is given `labelText: null` (its visual label is rendered
  /// once, separately, by the outer [Column] in [build]).
  LayrzEditableFieldConfig _buildFieldConfig(List<TextInputFormatter> formatters) {
    return LayrzEditableFieldConfig(
      labelText: widget.labelText,
      hintText: widget.hintText,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      errors: widget.errors,
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _handleTextChanged,
      onSubmit: widget.onSubmit,
      onFocusChanged: _handleFocusChangedForStates,
      onTap: widget.onTap,
      keyboardType: TextInputType.number,
      textInputAction: null,
      inputFormatters: formatters,
      maxLength: null,
      autofocus: widget.autofocus,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [],
      obscureText: false,
      autocorrect: true,
      enableSuggestions: true,
      actions: null,
      minLines: 1,
      maxLines: 1,
      expands: false,
      textAlign: TextAlign.center,
    );
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

    /// The accessible name for the field's own [Semantics] node (label, plus the localized
    /// required-indicator suffix when [LayrzNumberInput.isRequired] is set). Computed once in
    /// [build] so this branch and the no-step-buttons branch always announce the same string.
    required String? semanticLabel,

    /// The accessible tooltip for the field's own [Semantics] node, built from
    /// [LayrzNumberInput.helpTitleText] / [LayrzNumberInput.helpContentText]. Computed once in
    /// [build] for the same reason as [semanticLabel].
    required String? semanticTooltip,

    /// Whether the decrement cap should render disabled, computed once in [build] via
    /// [_isDecrementDisabled] and passed down rather than called again here — see the doc
    /// comment on [_lastDecrementDisabled] for why [build] is the single source of this value.
    required bool decrementDisabled,

    /// Whether the increment cap should render disabled, computed once in [build] via
    /// [_isIncrementDisabled]. See [decrementDisabled].
    required bool incrementDisabled,
  }) {
    // Resolve the style spec once for the entire control
    final spec = LayrzInputStyleSpec.resolve(
      states: _states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: widget.readOnly,
    );

    final isDisabled = widget.disabled || widget.readOnly;

    // Resolve slots and the field config locally for this branch (Trap 2: this branch's
    // chrome settings differ from the no-step-buttons branch — square corners, no border
    // of its own, and a suppressed footer — see the class-level comment on the composition).
    final prefixSlot = resolvePrefixSlot(prefix: userPrefix, onPrefixTap: widget.onPrefixTap);
    final suffixSlot = resolveSuffixSlot(suffix: userSuffix, onSuffixTap: widget.onSuffixTap);
    final fieldConfig = _buildFieldConfig(formatters);

    // Deliberately unlabelled: unlike build()'s no-step-buttons branch (a
    // single child, so its own Semantics merges with the field's into one
    // labelled node), this Row always splits into three separately
    // focusable/actionable children (decrement cap / field / increment cap),
    // so this outer node can never merge into any one of them and stays a
    // pure grouping node. A label here would be announced when focus reaches
    // this group and then announced again when it reaches the field (see the
    // inner Semantics below) — one screen-reader-focusable node should own
    // the label, and that node is the field, the thing the user actually
    // edits. `enabled` still belongs here so the group's own enabled state is
    // exposed.
    return Semantics(
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
                onTap: (widget.readOnly || decrementDisabled) ? null : _handleDecrement,
                isDisabled: widget.readOnly || decrementDisabled,
                hasErrors: hasErrors,
                states: _states,
                readOnly: widget.readOnly,
                isLeft: true,
              ),

              // Chrome (no border/radius, filled by outer container). Wrapped in its own
              // Semantics so the field's node carries the input's label (decision D-F) — it
              // remains a distinct node from the outer one above, since the outer Row already
              // splits the tree into three branches (decrement cap / field / increment cap).
              Expanded(
                child: Semantics(
                  label: semanticLabel,
                  tooltip: semanticTooltip,
                  enabled: !isDisabled,
                  child: LayrzInputChrome(
                    labelText: null,
                    hintText: widget.hintText,
                    isRequired: widget.isRequired,
                    prefixSlot: prefixSlot,
                    suffixSlot: suffixSlot,
                    disabled: widget.disabled,
                    readOnly: widget.readOnly,
                    errors: widget.errors,
                    // Hardcoded to true: the outer footer (LayrzInputFooterSlot) already owns the error message
                    hideDetails: true,
                    states: _states,
                    helpTitleText: widget.helpTitleText,
                    helpContentText: widget.helpContentText,
                    controller: _controller,
                    dense: widget.dense,
                    borderRadius: BorderRadius.zero,
                    showBorder: false,
                    child: LayrzEditableField(config: fieldConfig),
                  ),
                ),
              ),

              // Increment control (full height, no border/radius)
              NumberFieldControl(
                onTap: (widget.readOnly || incrementDisabled) ? null : _handleIncrement,
                isDisabled: widget.readOnly || incrementDisabled,
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

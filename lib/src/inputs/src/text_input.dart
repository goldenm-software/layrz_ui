import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/keyboard/keyboard.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/selection/selection.dart';

import 'input_chrome.dart';
import 'input_slot.dart';
import 'input_style_spec.dart';

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
  }) : assert(
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

/// Custom gesture detector builder that threads the [onTap] callback through
/// the selection gesture recognizer to avoid conflicts.
///
/// Overrides [onUserTap] to invoke the field's [onTap] callback when the user
/// taps, eliminating the need for a separate wrapping [GestureDetector].
class _LayrzTextInputSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  /// Callback to invoke when the user taps the field.
  final VoidCallback? _onUserTapCallback;

  /// Whether the field is disabled.
  final bool _isDisabled;

  /// Creates a custom gesture detector builder for [LayrzTextInput].
  _LayrzTextInputSelectionGestureDetectorBuilder({
    required super.delegate,
    required VoidCallback? onUserTapCallback,
    required bool isDisabled,
  }) : _onUserTapCallback = onUserTapCallback, // ignore: prefer_initializing_formals
       _isDisabled = isDisabled; // ignore: prefer_initializing_formals

  /// Called when the user taps the field.
  ///
  /// Invoked by [TextSelectionGestureDetectorBuilder] when [selectionEnabled]
  /// is true and a tap is recognized. Threads the [onTap] callback through
  /// this method to avoid multiple competing tap recognizers.
  @override
  void onUserTap() {
    super.onUserTap();
    if (!_isDisabled) {
      _onUserTapCallback?.call();
    }
  }
}

class _LayrzTextInputState extends State<LayrzTextInput> implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};
  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();

  /// Cached magnifier configuration to prevent overlay disposal on every rebuild.
  /// Initialized once in initState.
  late TextMagnifierConfiguration? _cachedMagnifierConfiguration;

  /// Cached context menu builder to prevent overlay disposal on every rebuild.
  /// Method references are compared by identity, so we cache it to ensure the same
  /// reference is used across rebuilds.
  late EditableTextContextMenuBuilder _cachedContextMenuBuilder;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    // Initialize cached magnifier configuration once; it never changes.
    _cachedMagnifierConfiguration = LayrzSelectionMagnifier.magnifierConfigurationFor();
    // Cache the context menu builder to ensure the same reference is used across rebuilds.
    // Method references are compared by identity in EditableText.didUpdateWidget.
    _cachedContextMenuBuilder = _buildContextMenu;
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
    // If focusNode changed, update the reference and listener
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    // Only dispose if we created them
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      if (_focusNode.hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
      }
    });
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  // TextSelectionGestureDetectorBuilderDelegate implementation
  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => !widget.disabled;

  void _updateStates(PointerEvent event) {
    setState(() {
      if (event is PointerDownEvent) {
        _states.add(WidgetState.pressed);
      } else if (event is PointerUpEvent) {
        _states.remove(WidgetState.pressed);
      }
    });
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    // Resolve which actions to display based on editability state
    final tokens = context.tokens;

    // Filter actions based on field state
    final actionSet = widget.actions ?? LayrzSelectableAction.defaults;
    final resolvedActions = actionSet.where((action) {
      // Drop copy and cut for obscured text
      if (widget.obscureText && (action.type == 'copy' || action.type == 'cut')) {
        return false;
      }
      // Drop cut and paste for read-only text
      if (widget.readOnly && (action.type == 'cut' || action.type == 'paste')) {
        return false;
      }
      return true;
    }).toSet();

    // Wire selection toolbar with actual clipboard/selection handling
    return LayrzSelectionToolbar(
      actions: resolvedActions,
      anchorAbove: Offset.zero,
      tokens: tokens,
      onActionPressed: (actionType) {
        switch (actionType) {
          case 'copy':
            editableTextState.copySelection(SelectionChangedCause.toolbar);
          case 'cut':
            editableTextState.cutSelection(SelectionChangedCause.toolbar);
          case 'paste':
            editableTextState.pasteText(SelectionChangedCause.toolbar);
          case 'selectAll':
            editableTextState.selectAll(SelectionChangedCause.toolbar);
          default:
            // Custom action: find and invoke the callback
            final customAction = actionSet.firstWhere(
              (a) => a.type == actionType,
              orElse: () => throw StateError('Unknown action: $actionType'),
            );
            customAction.onPressed();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Build formatters list
    final formatters = [...widget.inputFormatters];
    if (widget.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength!));
    }

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

    // Resolve style spec once to use for EditableText text color (Task 2)
    final hasErrors = widget.errors.isNotEmpty;
    final spec = LayrzInputStyleSpec.resolve(
      states: _states,
      tokens: tokens,
      hasErrors: hasErrors,
      readOnly: widget.readOnly,
    );

    // Format shortcut for display
    final shortcutText = widget.shortcut != null ? formatLayrzShortcut(widget.shortcut) : null;

    // Build gesture detector for selection.
    // The custom builder threads the onTap callback through the selection gesture
    // detector to prevent conflicts between separate tap recognizers.
    final gestureDetectorBuilder = _LayrzTextInputSelectionGestureDetectorBuilder(
      delegate: this,
      onUserTapCallback: widget.disabled ? null : (widget.readOnly ? widget.onTap : _handleTap),
      isDisabled: widget.disabled,
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
              readOnly: widget.readOnly || widget.disabled,
              textCapitalization: widget.textCapitalization,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              autofillHints: widget.autofillHints.isNotEmpty ? widget.autofillHints : null,
              paintCursorAboveText: true,
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

  void _handleTap() {
    widget.onTap?.call();
    if (!widget.disabled && !widget.readOnly) {
      _focusNode.requestFocus();
    }
  }
}

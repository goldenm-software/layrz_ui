import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// Library-private configuration for the EditableText widget.
///
/// Used internally by LayrzTextInput and LayrzTextAreaInput to avoid duplicating
/// the complex selection, magnifier, and context menu wiring.
@immutable
class LayrzEditableFieldConfig {
  /// The label text displayed above the input field.
  final String? labelText;

  /// Hint text displayed as placeholder when the field is empty.
  final String? hintText;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// The text editing controller for the input field.
  final TextEditingController? controller;

  /// The focus node for the input field.
  final FocusNode? focusNode;

  /// Callback fired when the input value changes.
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the input (e.g., presses Enter).
  final ValueChanged<String>? onSubmit;

  /// Callback fired when the input gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Callback fired when the field is tapped.
  final VoidCallback? onTap;

  /// The keyboard type for the input field.
  final TextInputType keyboardType;

  /// The text input action (e.g., 'go', 'search', 'send').
  final TextInputAction? textInputAction;

  /// List of input formatters to apply to the input.
  final List<TextInputFormatter> inputFormatters;

  /// Maximum length of the input text.
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

  /// The set of text selection actions available in the context menu.
  final Set<LayrzSelectableAction>? actions;

  /// The minimum number of lines the field can occupy.
  final int minLines;

  /// The maximum number of lines the field can occupy.
  final int? maxLines;

  /// Whether the field expands to fill the available space.
  final bool expands;

  /// The text alignment for the editable value.
  final TextAlign textAlign;

  /// Creates a new [LayrzEditableFieldConfig].
  const LayrzEditableFieldConfig({
    required this.labelText,
    required this.hintText,
    required this.disabled,
    required this.readOnly,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onFocusChanged,
    required this.onTap,
    required this.keyboardType,
    required this.textInputAction,
    required this.inputFormatters,
    required this.maxLength,
    required this.autofocus,
    required this.textCapitalization,
    required this.autofillHints,
    required this.obscureText,
    required this.autocorrect,
    required this.enableSuggestions,
    required this.actions,
    required this.minLines,
    required this.maxLines,
    required this.expands,
    this.textAlign = TextAlign.start,
  });
}

/// Library-private widget that renders an EditableText with LayrzUI selection, magnifier, and context menu support.
///
/// This widget encapsulates all the complex wiring for text selection handles, magnifier configuration,
/// context menu building, and state management. Both LayrzTextInput and LayrzTextAreaInput use this
/// widget to avoid code duplication.
class LayrzEditableField extends StatefulWidget {
  /// The configuration for this editable field.
  final LayrzEditableFieldConfig config;

  /// Creates a new [LayrzEditableField].
  const LayrzEditableField({
    super.key,
    required this.config,
  });

  @override
  State<LayrzEditableField> createState() => LayrzEditableFieldState();
}

/// State for [LayrzEditableField].
///
/// Manages the text editing controller, focus node, selection visibility, and interaction states
/// for the editable text widget. Provides text selection handling and context menu support.
class LayrzEditableFieldState extends State<LayrzEditableField> implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};
  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey<EditableTextState>();

  /// Whether to show text selection handles (left/right/collapsed cursors).
  ///
  /// Handles are shown for touch-driven selection (longPress, drag) but not
  /// for keyboard-driven selection. This field is updated by [_handleSelectionChanged]
  /// and passed to [EditableText.showSelectionHandles].
  bool _showSelectionHandles = false;

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
    _controller = widget.config.controller ?? TextEditingController();
    _focusNode = widget.config.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    // Initialize cached magnifier configuration once; it never changes.
    _cachedMagnifierConfiguration = LayrzSelectionMagnifier.magnifierConfigurationFor();
    // Cache the context menu builder to ensure the same reference is used across rebuilds.
    // Method references are compared by identity in EditableText.didUpdateWidget.
    _cachedContextMenuBuilder = _buildContextMenu;
  }

  @override
  void didUpdateWidget(LayrzEditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If controller changed, update the reference
    if (widget.config.controller != oldWidget.config.controller) {
      if (oldWidget.config.controller == null) {
        _controller.dispose();
      }
      _controller = widget.config.controller ?? TextEditingController();
    }
    // If focusNode changed, update the reference and listener
    if (widget.config.focusNode != oldWidget.config.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (oldWidget.config.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.config.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    // Only dispose if we created them
    if (widget.config.controller == null) {
      _controller.dispose();
    }
    // The listener must always be removed, regardless of who owns the node:
    // an externally-supplied focus node outlives this State, so leaving the
    // listener attached means a later focus change invokes setState on a
    // disposed State.
    _focusNode.removeListener(_handleFocusChange);
    if (widget.config.focusNode == null) {
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
    widget.config.onFocusChanged?.call(_focusNode.hasFocus);
  }

  // TextSelectionGestureDetectorBuilderDelegate implementation
  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => true;

  @override
  bool get selectionEnabled => !widget.config.disabled;

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
    final actionSet = widget.config.actions ?? LayrzSelectableAction.defaults;
    final resolvedActions = actionSet.where((action) {
      // Drop copy and cut for obscured text
      if (widget.config.obscureText && (action.type == 'copy' || action.type == 'cut')) {
        return false;
      }
      // Drop cut and paste for read-only text
      if (widget.config.readOnly && (action.type == 'cut' || action.type == 'paste')) {
        return false;
      }
      return true;
    }).toSet();

    // Get the toolbar anchor positions from the editable text state
    // These provide both above and below positions for automatic flip logic
    final anchors = editableTextState.contextMenuAnchors;

    // Build the toolbar widget
    final toolbar = LayrzSelectionToolbar(
      actions: resolvedActions,
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor,
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

    // Wrap the toolbar with CustomSingleChildLayout to handle positioning
    // The TextSelectionToolbarLayoutDelegate automatically positions above the selection
    // and flips below when there is not enough room above
    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
      ),
      child: toolbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Build formatters list
    final formatters = [...widget.config.inputFormatters];
    if (widget.config.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(widget.config.maxLength!));
    }

    // Compute states
    if (widget.config.disabled) {
      _states.add(WidgetState.disabled);
    } else {
      _states.remove(WidgetState.disabled);
    }

    // Build gesture detector for selection.
    // The custom builder threads the onTap callback through the selection gesture
    // detector to prevent conflicts between separate tap recognizers.
    final gestureDetectorBuilder = LayrzEditableFieldSelectionGestureDetectorBuilder(
      delegate: this,
      onUserTapCallback: widget.config.disabled ? null : (widget.config.readOnly ? widget.config.onTap : _handleTap),
      isDisabled: widget.config.disabled,
    );

    return Listener(
      onPointerDown: widget.config.disabled ? null : _updateStates,
      onPointerUp: widget.config.disabled ? null : _updateStates,
      onPointerCancel: widget.config.disabled ? null : _updateStates,
      child: MouseRegion(
        onEnter: widget.config.disabled ? null : (_) => setState(() => _states.add(WidgetState.hovered)),
        onExit: widget.config.disabled ? null : (_) => setState(() => _states.remove(WidgetState.hovered)),
        child: gestureDetectorBuilder.buildGestureDetector(
          child: EditableText(
            key: _editableTextKey,
            rendererIgnoresPointer: true,
            controller: _controller,
            focusNode: _focusNode,
            style: tokens.typography.body.copyWith(
              color: _getTextColor(tokens),
            ),
            cursorColor: tokens.colors.primary,
            backgroundCursorColor: tokens.colors.fg3,
            selectionColor: tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity),
            keyboardType: widget.config.keyboardType,
            textInputAction: widget.config.textInputAction,
            inputFormatters: formatters,
            onChanged: widget.config.onChanged,
            onSubmitted: widget.config.onSubmit,
            onSelectionChanged: _handleSelectionChanged,
            readOnly: widget.config.readOnly || widget.config.disabled,
            textCapitalization: widget.config.textCapitalization,
            autocorrect: widget.config.autocorrect,
            enableSuggestions: widget.config.enableSuggestions,
            obscureText: widget.config.obscureText,
            autofocus: widget.config.autofocus,
            autofillHints: widget.config.autofillHints.isNotEmpty ? widget.config.autofillHints : null,
            paintCursorAboveText: true,
            showSelectionHandles: _showSelectionHandles,
            // DESIGN-147: on non-touch OSes, both selectionControls and
            // contextMenuBuilder are passed as null together. Per
            // editable_text.dart:4522, EditableText disposes the selection
            // overlay outright when both are null -- removing the drag
            // handles and the selection action menu -- while caret placement,
            // drag-selection and shift+arrow keyboard selection all keep
            // working, exactly as the vote requires. Both branches resolve to
            // stable references (the singleton instance, the cached method
            // reference, or a literal null) across rebuilds, per D50 Trap 2:
            // a changed identity here disposes the overlay mid-display.
            selectionControls: LayrzPlatform.isTouchOS ? LayrzTextSelectionControls.instance : null,
            contextMenuBuilder: LayrzPlatform.isTouchOS ? _cachedContextMenuBuilder : null,
            magnifierConfiguration: _cachedMagnifierConfiguration ?? const TextMagnifierConfiguration(),
            minLines: widget.config.minLines,
            maxLines: widget.config.maxLines,
            expands: widget.config.expands,
            textAlign: widget.config.textAlign,
          ),
        ),
      ),
    );
  }

  /// Computes the text color based on field state.
  Color _getTextColor(LayrzTokens tokens) {
    if (widget.config.disabled) {
      return tokens.colors.fg4;
    }
    return tokens.colors.fg1;
  }

  void _handleTap() {
    widget.config.onTap?.call();
    if (!widget.config.disabled && !widget.config.readOnly) {
      _focusNode.requestFocus();
    }
  }

  /// Determines whether selection handles should be displayed based on the selection cause.
  ///
  /// Handles are shown for touch-driven selection causes (longPress, drag) but not for
  /// keyboard-driven selection. Follows Material Design patterns:
  /// - longPress and drag: show handles (user is interacting directly)
  /// - keyboard: hide handles (selection is driven by software keyboard)
  /// - readOnly + collapsed: hide handles (no editing possible)
  /// - disabled: hide handles (field is not editable)
  /// - non-touch OS (DESIGN-147): hide handles regardless of cause -- the team vote
  ///   restricts drag handles, the magnifier and the selection action menu to
  ///   Android/iOS (web or native); every other platform keeps caret placement and
  ///   keyboard/mouse-driven selection, just without the touch-shaped UI
  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // DESIGN-147: touch selection handles are Android/iOS only, on web or native.
    if (!LayrzPlatform.isTouchOS) {
      return false;
    }

    // Don't show handles if field is disabled
    if (widget.config.disabled) {
      return false;
    }

    // Don't show handles for keyboard-driven selection
    if (cause == SelectionChangedCause.keyboard) {
      return false;
    }

    // Don't show handles if read-only and selection is collapsed (just a cursor)
    if (widget.config.readOnly && _controller.selection.isCollapsed) {
      return false;
    }

    // Show handles for touch-driven causes: long press, drag, force press
    if (cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.drag ||
        cause == SelectionChangedCause.forcePress) {
      return true;
    }

    // For other causes (tap), only show if there's text to select
    if (_controller.text.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Called when the text selection changes.
  ///
  /// Updates [_showSelectionHandles] based on the [cause] and rebuilds
  /// if the visibility changed. Also invokes the user's [onChanged] callback.
  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
  }
}

/// Custom gesture detector builder that threads the [onTap] callback through
/// the selection gesture recognizer to avoid conflicts.
///
/// Overrides [onUserTap] to invoke the field's [onTap] callback when the user
/// taps, eliminating the need for a separate wrapping [GestureDetector].
class LayrzEditableFieldSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  /// Callback to invoke when the user taps the field.
  final VoidCallback? _onUserTapCallback;

  /// Whether the field is disabled.
  final bool _isDisabled;

  /// Creates a custom gesture detector builder for [LayrzEditableField].
  LayrzEditableFieldSelectionGestureDetectorBuilder({
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

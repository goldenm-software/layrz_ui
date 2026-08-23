import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/preview.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/input_error_block.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// A Material-free, accessible checkbox input control in the layrz_ui design system.
///
/// [LayrzCheckboxInput] is a boolean toggle displayed as a square checkbox with an
/// optional label. The control renders a checkmark when checked and supports keyboard
/// navigation (Space and Enter to toggle). The label is tappable and toggles the control.
///
/// **State management**: When [value] changes, this widget animates the checked state
/// over [tokens.motion.dTransition] (200ms by default). When [onChanged] is null, the
/// control is disabled and unresponsive to user input.
///
/// **Disposal contract**: When [focusNode] is null, a focus node is created and
/// disposed by the widget. Caller-supplied focus nodes are never disposed.
///
/// **Boolean only**: This control does not support tristate (indeterminate) state.
/// The [value] is always true or false, never null.
///
/// **Accessibility**: The control announces its role and checked state to screen readers
/// via semantics. The checkmark glyph provides a non-colour indicator that the control
/// is checked, satisfying WCAG colour contrast requirements.
class LayrzCheckboxInput extends StatefulWidget {
  /// The label text displayed next to the checkbox.
  ///
  /// If null, only the checkbox control is rendered without a label.
  /// The label is tappable and toggles the checkbox when clicked.
  final String? labelText;

  /// The current checked state of the checkbox.
  ///
  /// When true, the checkbox displays a checkmark. When false, it is empty.
  /// Changing this value triggers a smooth animation of the checked state.
  final bool value;

  /// Callback fired when the checkbox is toggled by the user.
  ///
  /// The callback receives the new boolean value. If null, the checkbox is disabled
  /// and does not respond to user interaction.
  final ValueChanged<bool>? onChanged;

  /// The focus node for the checkbox control.
  ///
  /// If null, a focus node is created and disposed by the widget.
  /// Caller-supplied focus nodes are never disposed.
  final FocusNode? focusNode;

  /// The list of error messages to display below the control.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// Whether the checkbox is disabled (read-only and non-interactive).
  final bool disabled;

  /// The padding applied around the entire control and label.
  ///
  /// If null, defaults to [tokens.spacing.pd2] (10px all sides).
  final EdgeInsets? padding;

  /// Creates a new [LayrzCheckboxInput] with the given properties.
  const LayrzCheckboxInput({
    super.key,
    this.labelText,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.errors = const [],
    this.hideDetails = false,
    this.disabled = false,
    this.padding,
  });

  @override
  State<LayrzCheckboxInput> createState() => _LayrzCheckboxInputState();
}

class _LayrzCheckboxInputState extends State<LayrzCheckboxInput> with TickerProviderStateMixin, ToggleableStateMixin {
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};

  /// Whether focus was gained from a pointer interaction (tap/click).
  ///
  /// Used to implement :focus-visible semantics: focus visual effects (colour)
  /// are only shown when focus is gained from the keyboard, not from a pointer tap.
  /// This prevents the focus colouring from appearing stuck after a tap.
  bool _focusFromPointer = false;

  @override
  bool? get value => widget.value;

  @override
  bool get tristate => false;

  @override
  ValueChanged<bool?>? get onChanged =>
      widget.onChanged == null ? null : (bool? newValue) => widget.onChanged!(newValue ?? false);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(LayrzCheckboxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      animateToValue();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleCheckbox() {
    if (widget.disabled || widget.onChanged == null) return;
    _focusNode.requestFocus();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDisabled = widget.disabled || widget.onChanged == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: widget.padding ?? tokens.spacing.pd2,
          child: GestureDetector(
            onTap: isDisabled ? null : _toggleCheckbox,
            onTapDown: isDisabled
                ? null
                : (_) {
                    setState(() {
                      _focusFromPointer = true;
                      _states.add(WidgetState.pressed);
                    });
                  },
            onTapUp: isDisabled ? null : (_) => setState(() => _states.remove(WidgetState.pressed)),
            onTapCancel: isDisabled ? null : () => setState(() => _states.remove(WidgetState.pressed)),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
                  _toggleCheckbox();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              focusNode: _focusNode,
              onFocusChange: (hasFocus) {
                setState(() {
                  if (hasFocus) {
                    _states.add(WidgetState.focused);
                  } else {
                    _states.remove(WidgetState.focused);
                    _focusFromPointer = false;
                  }
                });
              },
              child: MouseRegion(
                cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                onEnter: isDisabled ? null : (_) => setState(() => _states.add(WidgetState.hovered)),
                onExit: isDisabled ? null : (_) => setState(() => _states.remove(WidgetState.hovered)),
                child: Semantics(
                  checked: widget.value,
                  enabled: !isDisabled,
                  onTap: isDisabled ? null : _toggleCheckbox,
                  label: widget.labelText,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListenableBuilder(
                        listenable: position,
                        builder: (context, _) => _buildCheckboxBox(tokens, isDisabled),
                      ),
                      if (widget.labelText != null) ...[
                        SizedBox(width: tokens.spacing.sp2),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              widget.labelText!,
                              style: tokens.typography.body.copyWith(
                                color: isDisabled ? tokens.colors.fg4 : tokens.colors.fg1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        LayrzInputErrorBlock(
          errors: widget.errors,
          hideDetails: widget.hideDetails,
        ),
      ],
    );
  }

  Widget _buildCheckboxBox(LayrzTokens tokens, bool isDisabled) {
    final size = 20.0;
    final animationProgress = position.value;

    /// Derived focus-visible state: border colour shows primary only for keyboard focus, not pointer.
    final isFocusVisible = _states.contains(WidgetState.focused) && !_focusFromPointer;

    // State precedence: disabled > error > hover/focused/pressed > default
    late Color backgroundColor;
    late Color borderColor;

    if (isDisabled) {
      backgroundColor = tokens.colors.sf3;
      borderColor = tokens.colors.fg4;
    } else if (widget.errors.isNotEmpty) {
      final uncheckedBackground = tokens.colors.danger.shade50;
      final checkedBackground = tokens.colors.danger;
      backgroundColor = Color.lerp(uncheckedBackground, checkedBackground, animationProgress)!;
      borderColor = tokens.colors.danger;
    } else if (_states.contains(WidgetState.hovered) || isFocusVisible || _states.contains(WidgetState.pressed)) {
      final uncheckedBackground = tokens.colors.sf3;
      final checkedBackground = tokens.colors.primary;
      backgroundColor = Color.lerp(uncheckedBackground, checkedBackground, animationProgress)!;
      borderColor = isFocusVisible ? tokens.colors.primary : tokens.colors.fg2;
    } else {
      final uncheckedBackground = tokens.colors.sf2;
      final checkedBackground = tokens.colors.primary;
      backgroundColor = Color.lerp(uncheckedBackground, checkedBackground, animationProgress)!;
      borderColor = tokens.colors.fg2;
    }

    return SizedBox.square(
      dimension: size,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: tokens.border.base,
          ),
          borderRadius: tokens.radius.br1,
        ),
        child: animationProgress > 0
            ? Opacity(
                opacity: animationProgress,
                child: Center(
                  child: Icon(
                    MdiIcons.check,
                    size: 14,
                    color: tokens.colors.sf1,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Preview: unchecked checkbox with label.
@Preview(
  name: 'Unchecked',
  theme: layrzPreviewLightTheme,
)
Widget previewCheckboxInputUnchecked() => LayrzCheckboxInput(
  labelText: 'Accept terms and conditions',
  value: false,
  onChanged: (_) {},
);

/// Preview: checked checkbox with label.
@Preview(
  name: 'Checked',
  theme: layrzPreviewLightTheme,
)
Widget previewCheckboxInputChecked() => LayrzCheckboxInput(
  labelText: 'I agree to the terms',
  value: true,
  onChanged: (_) {},
);

/// Preview: disabled checkbox.
@Preview(
  name: 'Disabled',
  theme: layrzPreviewLightTheme,
)
Widget previewCheckboxInputDisabled() => LayrzCheckboxInput(
  labelText: 'Disabled checkbox',
  value: false,
  disabled: true,
  onChanged: (_) {},
);

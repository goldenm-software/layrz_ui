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
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
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
  }

  void _toggleCheckbox() {
    if (widget.disabled || widget.onChanged == null) return;
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
            child: Focus(
              onKeyEvent: (node, event) {
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
                  }
                });
              },
              child: MouseRegion(
                cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                onEnter: (_) => setState(() => _states.add(WidgetState.hovered)),
                onExit: (_) => setState(() => _states.remove(WidgetState.hovered)),
                child: Semantics(
                  checked: widget.value,
                  enabled: !isDisabled,
                  onTap: isDisabled ? null : _toggleCheckbox,
                  label: widget.labelText,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCheckboxBox(tokens, isDisabled),
                      if (widget.labelText != null) ...[
                        SizedBox(width: tokens.spacing.sp2),
                        Expanded(
                          child: Text(
                            widget.labelText!,
                            style: tokens.typography.body.copyWith(
                              color: isDisabled ? tokens.colors.fg4 : tokens.colors.fg1,
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

    // State precedence: disabled > error > hover/focused > default
    late Color backgroundColor;
    late Color borderColor;

    if (isDisabled) {
      backgroundColor = tokens.colors.sf3;
      borderColor = tokens.colors.fg4;
    } else if (widget.errors.isNotEmpty) {
      backgroundColor = animationProgress > 0.5 ? tokens.colors.danger : tokens.colors.danger.shade50;
      borderColor = tokens.colors.danger;
    } else if (_states.contains(WidgetState.hovered) || _states.contains(WidgetState.focused)) {
      backgroundColor = animationProgress > 0.5 ? tokens.colors.primary : tokens.colors.sf3;
      borderColor = _states.contains(WidgetState.focused) ? tokens.colors.primary : tokens.colors.fg2;
    } else {
      backgroundColor = animationProgress > 0.5 ? tokens.colors.primary : tokens.colors.sf2;
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
        child: widget.value
            ? Center(
                child: Icon(
                  MdiIcons.check,
                  size: 14,
                  color: tokens.colors.sf1,
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

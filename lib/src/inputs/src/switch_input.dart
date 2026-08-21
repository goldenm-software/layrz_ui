import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/preview.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/input_error_block.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// A Material-free, accessible switch (toggle) input control in the layrz_ui design system.
///
/// [LayrzSwitchInput] is a boolean toggle displayed as a horizontal pill-shaped track
/// with a moving thumb. When toggled, the thumb slides to the opposite end of the track
/// and the track color changes to indicate the new state.
///
/// **State management**: When [value] changes, this widget animates the thumb position
/// over [tokens.motion.dTransition] (200ms by default). When [onChanged] is null, the
/// control is disabled and unresponsive to user input.
///
/// **Disposal contract**: When [focusNode] is null, a focus node is created and
/// disposed by the widget. Caller-supplied focus nodes are never disposed.
///
/// **Boolean only**: This control does not support tristate (indeterminate) state.
/// The [value] is always true or false, never null.
///
/// **Accessibility**: The control announces its role and toggled state to screen readers
/// via semantics. The thumb's position provides a non-colour indicator that the switch
/// is on or off, satisfying WCAG colour contrast requirements.
class LayrzSwitchInput extends StatefulWidget {
  /// The label text displayed next to the switch.
  ///
  /// If null, only the switch control is rendered without a label.
  /// The label is tappable and toggles the switch when clicked.
  final String? labelText;

  /// The current toggled state of the switch.
  ///
  /// When true, the switch is "on" and the thumb is on the right side of the track.
  /// When false, the switch is "off" and the thumb is on the left side.
  /// Changing this value triggers a smooth animation of the thumb position.
  final bool value;

  /// Callback fired when the switch is toggled by the user.
  ///
  /// The callback receives the new boolean value. If null, the switch is disabled
  /// and does not respond to user interaction.
  final ValueChanged<bool>? onChanged;

  /// The focus node for the switch control.
  ///
  /// If null, a focus node is created and disposed by the widget.
  /// Caller-supplied focus nodes are never disposed.
  final FocusNode? focusNode;

  /// The list of error messages to display below the control.
  final List<String> errors;

  /// Whether to hide the error message block.
  final bool hideDetails;

  /// Whether the switch is disabled (read-only and non-interactive).
  final bool disabled;

  /// The padding applied around the entire control and label.
  ///
  /// If null, defaults to [tokens.spacing.pd2] (10px all sides).
  final EdgeInsets? padding;

  /// Creates a new [LayrzSwitchInput] with the given properties.
  const LayrzSwitchInput({
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
  State<LayrzSwitchInput> createState() => _LayrzSwitchInputState();
}

class _LayrzSwitchInputState extends State<LayrzSwitchInput> with TickerProviderStateMixin, ToggleableStateMixin {
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

  void _toggleSwitch() {
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
            onTap: isDisabled ? null : _toggleSwitch,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
                  _toggleSwitch();
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
                  toggled: widget.value,
                  enabled: !isDisabled,
                  onTap: isDisabled ? null : _toggleSwitch,
                  label: widget.labelText,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwitchTrack(tokens, isDisabled),
                      if (widget.labelText != null) ...[
                        SizedBox(width: tokens.spacing.sp3),
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

  Widget _buildSwitchTrack(LayrzTokens tokens, bool isDisabled) {
    const trackHeight = 28.0;
    const trackWidth = 52.0;
    const thumbSize = 24.0;

    final animationProgress = position.value;

    // State precedence: disabled > error > hover/focused > default
    late Color trackColor;

    if (isDisabled) {
      trackColor = tokens.colors.sf3;
    } else if (widget.errors.isNotEmpty) {
      trackColor = animationProgress > 0.5 ? tokens.colors.danger : tokens.colors.danger.shade50;
    } else if (_states.contains(WidgetState.hovered) || _states.contains(WidgetState.focused)) {
      trackColor = animationProgress > 0.5 ? tokens.colors.primary : tokens.colors.sf3;
    } else {
      trackColor = animationProgress > 0.5 ? tokens.colors.primary : tokens.colors.sf2;
    }

    // Calculate thumb position: slides from left to right as value goes from 0 to 1
    final thumbX = (trackWidth - thumbSize) * animationProgress;

    return SizedBox(
      width: trackWidth,
      height: trackHeight,
      child: Container(
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(tokens.radius.full),
          border: Border.all(
            color: isDisabled
                ? tokens.colors.fg4
                : widget.errors.isNotEmpty
                ? tokens.colors.danger
                : _states.contains(WidgetState.focused)
                ? tokens.colors.primary
                : tokens.colors.fg2,
            width: tokens.border.base,
          ),
        ),
        child: Stack(
          children: [
            // Thumb
            Positioned(
              left: thumbX,
              top: (trackHeight - thumbSize) / 2,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: isDisabled ? tokens.colors.fg4 : tokens.colors.sf1,
                  borderRadius: BorderRadius.circular(tokens.radius.full),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.colors.fg1.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview: switch in off state with label.
@Preview(
  name: 'Off',
  theme: layrzPreviewLightTheme,
)
Widget previewSwitchInputOff() => LayrzSwitchInput(
  labelText: 'Enable notifications',
  value: false,
  onChanged: (_) {},
);

/// Preview: switch in on state with label.
@Preview(
  name: 'On',
  theme: layrzPreviewLightTheme,
)
Widget previewSwitchInputOn() => LayrzSwitchInput(
  labelText: 'Notifications enabled',
  value: true,
  onChanged: (_) {},
);

/// Preview: disabled switch.
@Preview(
  name: 'Disabled',
  theme: layrzPreviewLightTheme,
)
Widget previewSwitchInputDisabled() => LayrzSwitchInput(
  labelText: 'Unavailable feature',
  value: false,
  disabled: true,
  onChanged: (_) {},
);

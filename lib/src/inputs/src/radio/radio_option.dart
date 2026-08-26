import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import '../select/select_item.dart';

/// Stateful widget for a single radio option with full state management.
///
/// This widget manages focus, hover, pressed, and focus-visible states for a single
/// radio option within a [LayrzRadioInput] group. It owns its [FocusNode] and
/// animation state, ensuring proper lifecycle and preventing focus leaks.
///
/// Each option renders a [RawRadio] button combined with a label (text or custom widget).
/// State changes trigger colour animations via [Color.lerp].
///
/// **Note:** This widget is internal to [LayrzRadioInput] and not part of the public API.
class LayrzRadioOption<T> extends StatefulWidget {
  /// The radio item to render.
  ///
  /// Holds the value, label text, and optional custom widget child.
  final LayrzSelectItem<T> item;

  /// The current value selected in the parent group.
  ///
  /// Used to determine if this option is currently selected.
  final T? groupValue;

  /// Callback fired when this option is selected.
  ///
  /// Receives the option's [item.value].
  final ValueChanged<T?> onChanged;

  /// Whether the parent group is disabled.
  ///
  /// When true, this option cannot be selected and all interaction is blocked.
  final bool disabled;

  /// Creates a new [LayrzRadioOption].
  const LayrzRadioOption({
    super.key,
    required this.item,
    required this.groupValue,
    required this.onChanged,
    required this.disabled,
  });

  @override
  State<LayrzRadioOption<T>> createState() => _LayrzRadioOptionState<T>();
}

/// State for [LayrzRadioOption].
class _LayrzRadioOptionState<T> extends State<LayrzRadioOption<T>> with TickerProviderStateMixin {
  late FocusNode _focusNode;
  final Set<WidgetState> _states = {};

  /// Whether focus was gained from a pointer interaction (tap/click).
  ///
  /// Used to implement :focus-visible semantics: focus visual effects (colour)
  /// are only shown when focus is gained from the keyboard, not from a pointer tap.
  /// This prevents the focus colouring from appearing stuck after a tap.
  bool _focusFromPointer = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      if (_focusNode.hasFocus) {
        _states.add(WidgetState.focused);
      } else {
        _states.remove(WidgetState.focused);
        _focusFromPointer = false;
      }
    });
  }

  void _handleTap() {
    if (widget.disabled) return;
    _focusNode.requestFocus();
    widget.onChanged(widget.item.value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isSelected = widget.groupValue == widget.item.value;
    final isDisabled = widget.disabled;

    return GestureDetector(
      onTap: isDisabled ? null : _handleTap,
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
      child: MouseRegion(
        cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: isDisabled ? null : (_) => setState(() => _states.add(WidgetState.hovered)),
        onExit: isDisabled ? null : (_) => setState(() => _states.remove(WidgetState.hovered)),
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: isSelected,
          enabled: !isDisabled,
          onTap: isDisabled ? null : _handleTap,
          // No explicit `label` here -- `widget.item.child` is the item's only
          // presentation (BREAKING: `LayrzSelectItem.labelText` is gone), so it is
          // left un-excluded below and its own semantics (a plain `Text`, most
          // commonly) merge upward into this node instead of being replaced by a
          // separate string. Verified this produces the exact same single merged
          // node as the old explicit label, with no double announcement. A caller
          // whose `child` carries no text semantics of its own (icon-only, a color
          // swatch) announces with no name unless that `child` supplies its own
          // `Semantics(label:)` -- this type no longer owns any text to fall back to.
          child: Row(
            children: [
              // Radio button using RawRadio
              RawRadio<T?>(
                value: widget.item.value,
                focusNode: _focusNode,
                autofocus: false,
                enabled: !isDisabled,
                mouseCursor: WidgetStateMouseCursor.clickable,
                toggleable: false,
                groupRegistry: RadioGroup.maybeOf<T?>(context),
                builder: (context, state) => ListenableBuilder(
                  listenable: state.position,
                  builder: (context, _) => _buildRadioBox(tokens, state.position.value, isDisabled),
                ),
              ),
              SizedBox(width: tokens.spacing.sp2),
              // The item's presentation. Force-wrapped in its own `DefaultTextStyle`
              // (body, dimmed to fg4 when disabled) rather than left to inherit
              // whatever `DefaultTextStyle` happens to be ambient -- a plain `Text`
              // inside `child` with no explicit color resolves to `null` without a
              // real ancestor supplying one, which the engine then paints solid
              // white rather than the theme's body color.
              Expanded(
                child: DefaultTextStyle(
                  style: tokens.typography.body.copyWith(
                    color: isDisabled ? tokens.colors.fg4.withValues(alpha: 0.4) : tokens.colors.fg1,
                  ),
                  child: widget.item.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the radio circle box with proper state-based colouring.
  ///
  /// Uses [Color.lerp] to animate the ring and dot colours smoothly, and derives
  /// focus-visible (keyboard-only focus) state from [_states] and [_focusFromPointer].
  /// State precedence: disabled > pressed > focus-visible > hover > default.
  ///
  /// The [animationProgress] parameter is the selection animation value from the radio's
  /// internal state, ranging from 0 (unselected) to 1 (selected).
  Widget _buildRadioBox(LayrzTokens tokens, double animationProgress, bool isDisabled) {
    const size = 20.0;
    const dotSize = 8.0;

    /// Derived focus-visible state: border colour shows primary only for keyboard focus, not pointer.
    final isFocusVisible = _states.contains(WidgetState.focused) && !_focusFromPointer;

    // State precedence: disabled > pressed > focus-visible > hover > default
    late Color ringColor;

    if (isDisabled) {
      ringColor = tokens.colors.fg4.withValues(alpha: 0.4);
    } else if (_states.contains(WidgetState.pressed)) {
      final unselectedRing = tokens.colors.fg1;
      final selectedRing = tokens.colors.primary;
      ringColor = Color.lerp(unselectedRing, selectedRing, animationProgress)!;
    } else if (isFocusVisible) {
      final unselectedRing = tokens.colors.primary;
      final selectedRing = tokens.colors.primary;
      ringColor = Color.lerp(unselectedRing, selectedRing, animationProgress)!;
    } else if (_states.contains(WidgetState.hovered)) {
      final unselectedRing = tokens.colors.fg2;
      final selectedRing = tokens.colors.primary;
      ringColor = Color.lerp(unselectedRing, selectedRing, animationProgress)!;
    } else {
      final unselectedRing = tokens.colors.fg3;
      final selectedRing = tokens.colors.primary;
      ringColor = Color.lerp(unselectedRing, selectedRing, animationProgress)!;
    }

    return SizedBox.square(
      dimension: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor,
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox.square(
            dimension: dotSize * animationProgress,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled ? tokens.colors.fg4.withValues(alpha: 0.4) : tokens.colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

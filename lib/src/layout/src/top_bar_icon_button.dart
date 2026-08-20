import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// A module-private icon-only button for the top bar with neutral interaction states.
///
/// This widget is a 40×40 hit target with hover and pressed states that change
/// background color only (no geometry changes per decision D15). It is used as the
/// drawer trigger in the top bar.
///
/// This widget is private to the layout module and is not exported.
class LayrzLayoutTopBarIconButton extends StatefulWidget {
  /// Creates a top bar icon button.
  const LayrzLayoutTopBarIconButton({
    /// The icon to display.
    required this.icon,

    /// The color of the icon.
    required this.iconColor,

    /// The size of the icon in logical pixels.
    required this.iconSize,

    /// Callback fired when the button is tapped.
    required this.onTap,

    super.key,
  });

  /// The icon to display.
  final IconData icon;

  /// The color of the icon.
  final Color iconColor;

  /// The size of the icon in logical pixels.
  final double iconSize;

  /// Callback fired when the button is tapped.
  final VoidCallback onTap;

  @override
  State<LayrzLayoutTopBarIconButton> createState() => _LayrzLayoutTopBarIconButtonState();
}

class _LayrzLayoutTopBarIconButtonState extends State<LayrzLayoutTopBarIconButton> {
  late WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _statesController.addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    _statesController.removeListener(_onStatesChanged);
    _statesController.dispose();
    super.dispose();
  }

  void _onStatesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Handles pointer-down to set the pressed state immediately.
  void _onPointerDown(PointerDownEvent event) {
    _statesController.update(WidgetState.pressed, true);
  }

  /// Handles pointer-up and pointer-cancel to release the pressed state.
  void _onPointerUp(PointerEvent event) {
    _statesController.update(WidgetState.pressed, false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final states = _statesController.value;

    // Determine the background color based on interaction state.
    Color? backgroundColor; // null = transparent
    if (states.contains(WidgetState.pressed)) {
      backgroundColor = tokens.colors.surface2;
    } else if (states.contains(WidgetState.hovered)) {
      backgroundColor = tokens.colors.surface3;
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (show) {
        _statesController.update(WidgetState.hovered, show);
      },
      onShowFocusHighlight: (show) {
        _statesController.update(WidgetState.focused, show);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapCancel: () {
              _statesController.update(WidgetState.pressed, false);
            },
            child: AnimatedContainer(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easing,
              width: kLayrzLayoutTopBarIconButtonSize,
              height: kLayrzLayoutTopBarIconButtonSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(kLayrzLayoutItemRadius),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

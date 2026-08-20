import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays motion tokens (durations and easing curves) with interactive demonstrations.
///
/// Shows interactive tiles that animate on hover and press using the motion tokens.
/// This is the one section that actually moves, demonstrating the animation durations
/// and easing curves in a tangible way.
class MotionSection extends StatelessWidget {
  const MotionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Motion',
      description: 'Animation durations and easing curves with interactive demos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motion values reference
          Text('Motion Token Values', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp12),
          _MotionValuesTable(tokens: tokens),

          SizedBox(height: tokens.spacing.sp24),

          // Interactive demonstrations
          Text('Interactive Demonstrations', style: tokens.typography.title),
          SizedBox(height: tokens.spacing.sp12),
          Row(
            children: [
              Expanded(child: _HoverAnimationDemo(tokens: tokens)),
              SizedBox(width: tokens.spacing.sp16),
              Expanded(child: _PressAnimationDemo(tokens: tokens)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A table displaying all motion token values.
class _MotionValuesTable extends StatelessWidget {
  /// Creates a new [_MotionValuesTable].
  const _MotionValuesTable({required this.tokens});

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Durations
        _MotionValueRow(label: 'dHover', value: '${tokens.motion.dHover.inMilliseconds} ms', tokens: tokens),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(label: 'dPress', value: '${tokens.motion.dPress.inMilliseconds} ms', tokens: tokens),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(label: 'dTransition', value: '${tokens.motion.dTransition.inMilliseconds} ms', tokens: tokens),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(
          label: 'dPageTransition',
          value: '${tokens.motion.dPageTransition.inMilliseconds} ms',
          tokens: tokens,
        ),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(label: 'dDialog', value: '${tokens.motion.dDialog.inMilliseconds} ms', tokens: tokens),
        SizedBox(height: tokens.spacing.sp16),
        // Easing curves
        _MotionValueRow(label: 'easing', value: 'easeInOut', tokens: tokens),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(label: 'easingEnter', value: 'easeOut', tokens: tokens),
        SizedBox(height: tokens.spacing.sp8),
        _MotionValueRow(label: 'easingExit', value: 'easeIn', tokens: tokens),
      ],
    );
  }
}

/// A row displaying a single motion token value.
class _MotionValueRow extends StatelessWidget {
  /// Creates a new [_MotionValueRow].
  const _MotionValueRow({required this.label, required this.value, required this.tokens});

  /// The token name.
  final String label;

  /// The token value as a string.
  final String value;

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    final tooltip = _getTooltip(label);

    return LayrzTooltip(
      contentText: tooltip,
      child: Row(
        children: [
          SizedBox(
            width: tokens.spacing.sp48 * 2,
            child: Text(label, style: tokens.typography.label),
          ),
          Expanded(
            child: Text(value, style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
          ),
        ],
      ),
    );
  }

  /// Returns a descriptive tooltip for each motion token.
  String _getTooltip(String label) {
    switch (label) {
      case 'dHover':
        return 'Hover state transition duration';
      case 'dPress':
        return 'Press state transition duration';
      case 'dTransition':
        return 'General transition animation duration';
      case 'dPageTransition':
        return 'Page navigation/route transition duration';
      case 'dDialog':
        return 'Dialog open/close animation duration';
      case 'easing':
        return 'Standard easing curve (easeInOut)';
      case 'easingEnter':
        return 'Entrance animation easing curve (easeOut)';
      case 'easingExit':
        return 'Exit animation easing curve (easeIn)';
      default:
        return label;
    }
  }
}

/// An interactive tile that animates on hover using [dHover] duration.
class _HoverAnimationDemo extends StatefulWidget {
  /// Creates a new [_HoverAnimationDemo].
  const _HoverAnimationDemo({required this.tokens});

  /// The token set.
  final LayrzTokens tokens;

  @override
  State<_HoverAnimationDemo> createState() => _HoverAnimationDemoState();
}

class _HoverAnimationDemoState extends State<_HoverAnimationDemo> {
  /// Whether the mouse is hovering over the demo tile.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hover Animation', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
        SizedBox(height: tokens.spacing.sp8),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            key: const Key('hover-demo-container'),
            duration: tokens.motion.dHover,
            curve: tokens.motion.easing,
            decoration: BoxDecoration(
              color: _isHovered ? tokens.colors.primary : tokens.colors.surface,
              borderRadius: BorderRadius.circular(tokens.radius.r8),
              border: Border.all(
                color: _isHovered ? tokens.colors.primary : tokens.colors.divider,
                width: tokens.border.stroke1,
              ),
            ),
            padding: EdgeInsets.all(tokens.spacing.sp16),
            child: AnimatedDefaultTextStyle(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easing,
              style: tokens.typography.label.copyWith(
                color: _isHovered ? tokens.colors.surface : tokens.colors.fg1,
              ),
              child: Text('Hover me (${tokens.motion.dHover.inMilliseconds}ms)'),
            ),
          ),
        ),
      ],
    );
  }
}

/// An interactive tile that animates on press using [dPress] duration.
class _PressAnimationDemo extends StatefulWidget {
  /// Creates a new [_PressAnimationDemo].
  const _PressAnimationDemo({required this.tokens});

  /// The token set.
  final LayrzTokens tokens;

  @override
  State<_PressAnimationDemo> createState() => _PressAnimationDemoState();
}

class _PressAnimationDemoState extends State<_PressAnimationDemo> {
  /// Whether the demo tile is currently pressed.
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Press Animation', style: tokens.typography.label.copyWith(color: tokens.colors.fg3)),
        SizedBox(height: tokens.spacing.sp8),
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            key: const Key('press-demo-container'),
            duration: tokens.motion.dPress,
            curve: tokens.motion.easing,
            decoration: BoxDecoration(
              color: _isPressed ? tokens.colors.primary : tokens.colors.surface,
              borderRadius: BorderRadius.circular(tokens.radius.r8),
              border: Border.all(
                color: _isPressed ? tokens.colors.primary : tokens.colors.divider,
                width: tokens.border.stroke1,
              ),
            ),
            padding: EdgeInsets.all(tokens.spacing.sp16),
            child: AnimatedDefaultTextStyle(
              duration: tokens.motion.dPress,
              curve: tokens.motion.easing,
              style: tokens.typography.label.copyWith(
                color: _isPressed ? tokens.colors.surface : tokens.colors.fg1,
              ),
              child: Text('Press me (${tokens.motion.dPress.inMilliseconds}ms)'),
            ),
          ),
        ),
      ],
    );
  }
}

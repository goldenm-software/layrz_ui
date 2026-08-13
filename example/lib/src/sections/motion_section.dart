// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays motion tokens (durations and easing curves) with interactive demonstrations.
///
/// Shows interactive tiles that animate on hover and press using the motion tokens.
/// This is the one section that actually moves, demonstrating the animation durations
/// and easing curves in a tangible way.
Widget buildMotionSection() {
  return Builder(
    builder: (context) {
      final tokens = context.tokens;

      return ShowroomSection(
        title: 'Motion',
        description: 'Animation durations and easing curves with interactive demos',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motion values reference
            Text('Motion Token Values', style: tokens.typography.titleMedium),
            SizedBox(height: tokens.spacing.sp12),
            _MotionValuesTable(tokens: tokens),

            SizedBox(height: tokens.spacing.sp24),

            // Interactive demonstrations
            Text('Interactive Demonstrations', style: tokens.typography.titleMedium),
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
    },
  );
}

/// A table displaying all motion token values.
class _MotionValuesTable extends StatelessWidget {
  /// Creates a new [_MotionValuesTable].
  const _MotionValuesTable({required this.tokens, super.key});

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
  const _MotionValueRow({required this.label, required this.value, required this.tokens, super.key});

  /// The token name.
  final String label;

  /// The token value as a string.
  final String value;

  /// The token set.
  final LayrzTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: tokens.typography.labelSmall)),
        Expanded(
          child: Text(value, style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        ),
      ],
    );
  }
}

/// An interactive tile that animates on hover using [dHover] duration.
class _HoverAnimationDemo extends StatefulWidget {
  /// Creates a new [_HoverAnimationDemo].
  const _HoverAnimationDemo({required this.tokens, super.key});

  /// The token set.
  final LayrzTokens tokens;

  @override
  State<_HoverAnimationDemo> createState() => _HoverAnimationDemoState();
}

class _HoverAnimationDemoState extends State<_HoverAnimationDemo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hover Animation', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        SizedBox(height: tokens.spacing.sp8),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: tokens.motion.dHover,
            curve: tokens.motion.easing,
            decoration: BoxDecoration(
              color: _isHovered ? tokens.colors.primary : tokens.colors.surface,
              borderRadius: BorderRadius.circular(tokens.radius.r8),
              border: Border.all(
                color: _isHovered ? tokens.colors.primary : tokens.colors.divider,
                width: _isHovered ? tokens.border.stroke2 : tokens.border.stroke1,
              ),
            ),
            padding: EdgeInsets.all(tokens.spacing.sp16),
            child: AnimatedDefaultTextStyle(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easing,
              style: tokens.typography.labelSmall.copyWith(
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
  const _PressAnimationDemo({required this.tokens, super.key});

  /// The token set.
  final LayrzTokens tokens;

  @override
  State<_PressAnimationDemo> createState() => _PressAnimationDemoState();
}

class _PressAnimationDemoState extends State<_PressAnimationDemo> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Press Animation', style: tokens.typography.labelSmall.copyWith(color: tokens.colors.fg3)),
        SizedBox(height: tokens.spacing.sp8),
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: tokens.motion.dPress,
            curve: tokens.motion.easing,
            decoration: BoxDecoration(
              color: _isPressed ? tokens.colors.accent : tokens.colors.surface,
              borderRadius: BorderRadius.circular(tokens.radius.r8),
              border: Border.all(
                color: _isPressed ? tokens.colors.accent : tokens.colors.divider,
                width: _isPressed ? tokens.border.stroke2 : tokens.border.stroke1,
              ),
            ),
            padding: EdgeInsets.all(tokens.spacing.sp16),
            child: AnimatedDefaultTextStyle(
              duration: tokens.motion.dPress,
              curve: tokens.motion.easing,
              style: tokens.typography.labelSmall.copyWith(
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

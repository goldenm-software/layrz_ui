import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// A small floating label showing the current value of a [LayrzSlider] while
/// it is being dragged.
///
/// This supplements — it never replaces — the always-visible static value
/// label already rendered above the slider's track. On a touch device a
/// dragging fingertip can cover the thumb (and the static label sits far
/// enough away that it stays readable regardless), so the bubble exists
/// purely as an additional, thumb-anchored affordance for pointer users who
/// are looking at the thumb itself while dragging. It is wrapped in
/// [ExcludeSemantics] by the caller since the value is already announced via
/// the slider's own `Semantics.value`.
///
/// The bubble is laid out by the caller as a [Positioned] child of a [Stack]
/// with `clipBehavior: Clip.none`, anchored above the thumb — it never
/// participates in the [Stack]'s intrinsic size, so its appearance and
/// disappearance across a drag never changes the slider's laid-out height
/// (the D15 concern that motivated keeping it out of the normal layout flow).
class LayrzSliderValueBubble extends StatelessWidget {
  /// The already-formatted value text to display inside the bubble.
  final String text;

  /// The fill colour of the bubble's surface.
  final Color color;

  /// The colour of the text drawn inside the bubble.
  final Color textColor;

  /// The design tokens used to resolve the bubble's padding, radius,
  /// typography, and elevation shadow.
  final LayrzTokens tokens;

  /// Creates a new [LayrzSliderValueBubble].
  const LayrzSliderValueBubble({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: tokens.radius.br1,
        boxShadow: tokens.shadow.compact2,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp2,
          vertical: tokens.spacing.sp1 / 2,
        ),
        child: Text(
          text,
          style: tokens.typography.label.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

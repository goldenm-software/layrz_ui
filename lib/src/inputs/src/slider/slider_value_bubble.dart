import 'package:flutter/foundation.dart' show listEquals;
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
///
/// **Shape**: the bubble is a single filled [Path] — a rounded rectangle
/// (the body, holding the text) unioned with a downward-pointing triangle
/// (the tail) centred beneath it, so the two read as one continuous shape
/// with no seam between them. Both are painted by [LayrzSliderBubblePainter]
/// as a background [CustomPaint] behind the [Text] child: the painter is
/// handed the *child's* laid-out size (Flutter sizes a background
/// `CustomPaint` to its child when one is supplied and the painter declares
/// no explicit `size`), and this widget reserves [_tailHeight] of that size
/// as bottom padding so the child is measured tall enough for the tail to
/// have room to be painted into without touching the text. The body occupies
/// the region above that reserved strip; the tail triangle occupies the
/// strip itself, tip pointing down at the thumb.
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

  /// The width, in logical pixels, of the tail's base where it meets the
  /// bubble's body.
  ///
  /// No existing spacing token expresses a value this small and specific to
  /// a tail glyph, so this is a local named constant rather than a token —
  /// it is a minor geometric detail of this one shape, not a semantic
  /// spacing value used elsewhere. Public (rather than private) so tests and
  /// callers reasoning about the bubble's overall footprint (e.g.
  /// `LayrzSlider`'s `_bubbleClearance` doc) can reference the same value
  /// instead of duplicating the literal.
  static const double tailWidth = 10.0;

  /// The height, in logical pixels, of the tail's protrusion below the
  /// bubble's rounded-rect body.
  ///
  /// Same rationale as [tailWidth]: a small geometric constant local to this
  /// shape rather than a design token, made public for the same reason.
  static const double tailHeight = 6.0;

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
    return CustomPaint(
      painter: LayrzSliderBubblePainter(
        color: color,
        radius: tokens.radius.r1,
        tailWidth: tailWidth,
        tailHeight: tailHeight,
        shadows: tokens.shadow.compact2,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: tokens.spacing.sp2,
          right: tokens.spacing.sp2,
          top: tokens.spacing.sp1 / 2,
          bottom: tokens.spacing.sp1 / 2 + tailHeight,
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

/// Paints the seamless body+tail shape behind a [LayrzSliderValueBubble].
///
/// Builds exactly one [Path] — a rounded rectangle unioned with a downward
/// triangle — and fills it (plus, per shadow, a shifted copy stroked as a
/// shadow) in a single `canvas.drawPath` pass each, so the body and tail
/// never show a seam between them. This mirrors the pattern
/// `LayrzSliderPainter` already uses for the thumb's shadow: iterate the
/// resolved [BoxShadow] list, get each one's [Paint] via
/// `BoxShadow.toPaint()`, shift the *same* combined path by the shadow's
/// offset, and draw it before the solid fill on top.
class LayrzSliderBubblePainter extends CustomPainter {
  /// The fill colour applied to the combined body+tail path.
  final Color color;

  /// The corner radius applied to the body's rounded-rect corners.
  final double radius;

  /// The width of the tail's base, centred horizontally under the body.
  final double tailWidth;

  /// The height of the tail's downward protrusion below the body.
  final double tailHeight;

  /// The elevation shadow drawn behind the combined shape, resolved from
  /// design tokens. An empty list paints no shadow.
  final List<BoxShadow> shadows;

  /// Creates a painter for the slider value bubble's body+tail shape.
  const LayrzSliderBubblePainter({
    required this.color,
    required this.radius,
    required this.tailWidth,
    required this.tailHeight,
    required this.shadows,
  });

  /// Builds the single unioned [Path] of the rounded-rect body and the
  /// downward tail triangle for a background of the given [size].
  ///
  /// [size] is the full painted area, including the [tailHeight] strip
  /// reserved at its bottom by the caller's padding — the body occupies
  /// `size.height - tailHeight` and the tail fills the remaining strip,
  /// tip-down at the horizontal centre.
  ///
  /// Exposed as a public method (rather than kept private) specifically so
  /// tests can assert on the shape's geometry directly — e.g. that the tail's
  /// tip sits below the body's rect and is horizontally centred — without
  /// needing to decode recorded canvas operations.
  Path buildPath(Size size) {
    final bodyHeight = size.height - tailHeight;
    final bodyRect = Rect.fromLTWH(0, 0, size.width, bodyHeight);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(radius)));

    final tailCenterX = size.width / 2;
    final tailPath = Path()
      ..moveTo(tailCenterX - tailWidth / 2, bodyHeight)
      ..lineTo(tailCenterX + tailWidth / 2, bodyHeight)
      ..lineTo(tailCenterX, size.height)
      ..close();

    return Path.combine(PathOperation.union, bodyPath, tailPath);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(size);

    // Same pattern as LayrzSliderPainter's thumb shadow: BoxShadow.toPaint()
    // hands back a Paint configured with the shadow's colour and blur
    // MaskFilter, and the caller shifts the shape by the shadow's offset
    // before filling with it.
    for (final shadow in shadows) {
      canvas.drawPath(path.shift(shadow.offset), shadow.toPaint());
    }

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant LayrzSliderBubblePainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        tailWidth != oldDelegate.tailWidth ||
        tailHeight != oldDelegate.tailHeight ||
        !listEquals(shadows, oldDelegate.shadows);
  }
}

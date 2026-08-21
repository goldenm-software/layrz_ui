import 'package:flutter/widgets.dart';

/// Paints a text selection handle as a teardrop shape (left/right/collapsed cursor indicator).
///
/// [LayrzSelectionHandlePainter] renders a teardrop-shaped handle that marks the
/// start/end position of a text selection or the position of a collapsed caret.
///
/// The teardrop is a circle with a square corner in the top-left quadrant, creating a
/// circular bulge with a pointed corner. Unrotated, the square corner points to the
/// top-left (NW). The point orientation for each handle type is controlled via
/// Transform.rotate in [LayrzTextSelectionControls.buildHandle]:
/// - **left**: rotated 90° clockwise (π/2) → corner points up-right (NE), touching selection start
/// - **right**: no rotation (0°) → corner points up-left (NW), touching selection end
/// - **collapsed**: rotated 45° clockwise (π/4) → corner points up (N), marking caret position
///
/// Transform.rotate rotates clockwise for positive angles in Flutter.
class LayrzSelectionHandlePainter extends CustomPainter {
  /// Color of the handle, typically from tokens.colors.primary.
  final Color color;

  /// Creates a new [LayrzSelectionHandlePainter].
  ///
  /// Parameters:
  ///   - [color]: The fill color for the handle.
  const LayrzSelectionHandlePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Create a circle and a square corner (top-left quadrant).
    // When combined with path winding rules, this creates a teardrop:
    // a circle with a pointed corner at the top-left (NW).
    final double radius = size.width / 2.0;
    final circle = Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final point = Rect.fromLTWH(0.0, 0.0, radius, radius);

    // Path combining the circle and the square point creates the teardrop.
    // addOval traces the circle outline, addRect traces the square outline.
    // The winding rule determines the final fill, producing the teardrop shape.
    final path = Path()
      ..addOval(circle)
      ..addRect(point);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LayrzSelectionHandlePainter oldDelegate) => oldDelegate.color != color;
}

import 'package:flutter/widgets.dart';

/// Paints a text selection handle as a teardrop shape (left/right/collapsed cursor indicator).
///
/// [LayrzSelectionHandlePainter] renders a teardrop-shaped handle that marks the
/// start/end position of a text selection or the position of a collapsed caret.
///
/// The teardrop is a circle with the top-left quadrant removed, creating a circular
/// bulge with a square corner / point. Unrotated, the square corner points up-right (NE).
/// The point orientation for each handle type is controlled via Transform.rotate in
/// [LayrzTextSelectionControls.buildHandle]:
/// - **left**: no rotation (0°) → square corner points up-right, touching selection start
/// - **right**: rotated 90° (π/2) → square corner points up-left, touching selection end
/// - **collapsed**: rotated 45° (π/4) → square corner points up, marking caret position
///
/// This matches Material Design's text selection handle pattern.
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
    // When combined, this creates a teardrop: a circle with a square corner
    // cut out of the top-left, leaving a sharp point.
    final double radius = size.width / 2.0;
    final circle = Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final point = Rect.fromLTWH(0.0, 0.0, radius, radius);

    // Path combining the circle and the square point creates the teardrop.
    // addOval draws the circle, addRect removes the top-left quadrant.
    final path = Path()
      ..addOval(circle)
      ..addRect(point);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LayrzSelectionHandlePainter oldDelegate) => oldDelegate.color != color;
}

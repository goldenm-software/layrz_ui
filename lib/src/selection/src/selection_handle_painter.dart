import 'package:flutter/widgets.dart';

/// Paints a text selection handle as a teardrop shape (left/right/collapsed cursor indicator).
///
/// [LayrzSelectionHandlePainter] renders a teardrop-shaped handle that marks the
/// start/end position of a text selection or the position of a collapsed caret.
///
/// The teardrop is a circle with one square corner cut out from the top-left quadrant,
/// creating a circular shape with a sharp "point". The point orientation changes based
/// on the handle type, controlled via Transform.rotate in [LayrzTextSelectionControls.buildHandle]:
/// - **left**: rotated 90° to point up-right
/// - **right**: not rotated, points up-left
/// - **collapsed**: rotated 45° to point up
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

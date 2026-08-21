import 'package:flutter/widgets.dart';

/// Paints a text selection handle as a teardrop shape (left/right/collapsed cursor indicator).
///
/// [LayrzSelectionHandlePainter] renders a teardrop-shaped handle that marks the
/// start/end position of a text selection or the position of a collapsed caret.
/// The teardrop is a circle with one square corner pointing toward the text.
/// The corner orientation changes based on the handle type:
/// - **left**: square corner points up-right
/// - **right**: square corner points up-left
/// - **collapsed**: square corner points downward
///
/// The handle uses color from the design system tokens.
class LayrzSelectionHandlePainter extends CustomPainter {
  /// The handle type (left, right, or collapsed), determining the corner orientation.
  final TextSelectionHandleType type;

  /// Color of the handle, typically from tokens.colors.primary.
  final Color color;

  /// Creates a new [LayrzSelectionHandlePainter].
  ///
  /// Parameters:
  ///   - [type]: The selection handle type (left, right, or collapsed).
  ///   - [color]: The fill color for the handle.
  const LayrzSelectionHandlePainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = _buildTeardropPath(size);

    // Rotate the path based on handle type
    final rotation = _getRotationForType(type);
    final center = Offset(size.width / 2, size.height / 2);

    if (rotation != 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// Builds a teardrop path: a circle with one square corner.
  /// This creates the base teardrop shape before rotation.
  Path _buildTeardropPath(Size size) {
    final path = Path();
    const cornerSize = 6.0; // Size of the square corner point
    final radius = (size.width - cornerSize) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Start from the top of the circle and draw clockwise
    // This creates a teardrop that points down (square corner at bottom)
    path.moveTo(center.dx, center.dy - radius);

    // Right arc: top-right to bottom-right of circle
    path.arcToPoint(
      Offset(center.dx + radius, center.dy),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom-right arc: to the square corner position
    path.arcToPoint(
      Offset(center.dx + cornerSize / 2, center.dy + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Square corner: right edge going down
    path.lineTo(center.dx + cornerSize / 2, center.dy + radius + cornerSize / 2);

    // Square corner: bottom edge going left
    path.lineTo(center.dx - cornerSize / 2, center.dy + radius + cornerSize / 2);

    // Square corner: left edge going up
    path.lineTo(center.dx - cornerSize / 2, center.dy + radius);

    // Bottom-left arc: from square corner position back to circle
    path.arcToPoint(
      Offset(center.dx - radius, center.dy),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Left arc: bottom-left to top-left
    path.arcToPoint(
      Offset(center.dx, center.dy - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.close();
    return path;
  }

  /// Returns the rotation angle in radians for the given handle type.
  /// This determines which direction the square corner points.
  double _getRotationForType(TextSelectionHandleType type) {
    return switch (type) {
      TextSelectionHandleType.left => -3.927, // ~-225 degrees (points up-right)
      TextSelectionHandleType.right => -2.356, // ~-135 degrees (points up-left)
      TextSelectionHandleType.collapsed => 0, // No rotation (points down)
    };
  }

  @override
  bool shouldRepaint(LayrzSelectionHandlePainter oldDelegate) => oldDelegate.type != type || oldDelegate.color != color;
}

import 'package:flutter/widgets.dart';

/// Paints a text selection handle (left/right/collapsed cursor indicator).
///
/// [LayrzSelectionHandlePainter] renders a simple rounded rectangle indicator
/// that marks the start/end position of a text selection or the position
/// of a collapsed caret. The handle uses color and shape tokens from the
/// design system.
class LayrzSelectionHandlePainter extends CustomPainter {
  /// Color of the handle, typically from tokens.colors.primary.
  final Color color;

  /// Border radius applied to the handle.
  final BorderRadius borderRadius;

  /// Creates a new [LayrzSelectionHandlePainter].
  ///
  /// Parameters:
  ///   - [color]: The fill color for the handle.
  ///   - [borderRadius]: The border radius for rounded corners.
  const LayrzSelectionHandlePainter({
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(LayrzSelectionHandlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}

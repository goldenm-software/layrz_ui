import 'package:flutter/widgets.dart';

/// Custom painter that renders a dashed border around a rounded rectangle.
///
/// Used to draw dashed borders for disabled and read-only [LayrzTextInput] fields.
/// The dashes are evenly spaced along the path of the rectangle's outline.
class DashedBorderPainter extends CustomPainter {
  /// The color of the dashed border.
  final Color color;

  /// The width (stroke width) of the border in logical pixels.
  final double strokeWidth;

  /// The radius of the rounded corners.
  final BorderRadius borderRadius;

  /// The length of each dash segment in logical pixels.
  final double dashLength;

  /// The length of each gap between dashes in logical pixels.
  final double gapLength;

  /// Creates a new [DashedBorderPainter] with the given properties.
  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    this.dashLength = 4.0,
    this.gapLength = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Create an RRect for the rounded rectangle
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      topLeft: Radius.circular(borderRadius.topLeft.x),
      topRight: Radius.circular(borderRadius.topRight.x),
      bottomLeft: Radius.circular(borderRadius.bottomLeft.x),
      bottomRight: Radius.circular(borderRadius.bottomRight.x),
    );

    // Convert RRect to Path
    final path = Path()..addRRect(rrect);

    // Use PathMetrics to extract segments and draw dashes
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        // Draw dash
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashLength,
        );
        canvas.drawPath(extractPath, paint);

        // Skip gap
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

import 'package:flutter/widgets.dart';

/// Paints the "connected chrome" tab shape used by [LayrzWorkspaceTabs].
///
/// [LayrzWorkspaceTabChromePainter] draws a single tab's background as a
/// browser-style shape: flat outer shoulders that curve up into a rounded
/// top, so a row of these shapes reads as tabs rising out of the bar behind
/// them, and the active tab's flat bottom edge merges seamlessly into the
/// content panel below.
///
/// Geometry:
/// - The top-left and top-right corners are rounded by [topRadius].
/// - The bottom-left and bottom-right corners are rounded by [bottomRadius]
///   (typically `0` for the active tab, so its bottom edge is a flush,
///   straight line that continues into the panel; inactive tabs may use a
///   small [bottomRadius] to read as separate, receded chips).
/// - The whole shape is filled with [fillColor].
/// - When [borderColor] is non-null, the shape's outline is additionally
///   stroked with [borderWidth].
///
/// This painter reads no [BuildContext], theme, or tokens itself — per the
/// repo's `CustomPainter` convention (see `LayrzSelectionHandlePainter`),
/// every colour and dimension is supplied by the caller, which is
/// responsible for resolving them from `context.tokens`.
@immutable
class LayrzWorkspaceTabChromePainter extends CustomPainter {
  /// The fill colour painted inside the tab shape.
  final Color fillColor;

  /// The corner radius applied to the top-left and top-right corners.
  final double topRadius;

  /// The corner radius applied to the bottom-left and bottom-right corners.
  ///
  /// Pass `0` for a tab whose bottom edge must merge flush into the content
  /// panel below (the active tab); pass a small positive value for a tab
  /// that should read as a separate, fully-rounded chip (inactive tabs).
  final double bottomRadius;

  /// Optional stroke colour drawn along the shape's outline.
  ///
  /// When `null`, no stroke is drawn — the shape is fill-only.
  final Color? borderColor;

  /// The stroke width used when [borderColor] is non-null.
  final double borderWidth;

  /// Creates a new [LayrzWorkspaceTabChromePainter].
  ///
  /// Parameters:
  ///   - [fillColor]: the tab shape's fill colour.
  ///   - [topRadius]: corner radius for the top-left/top-right corners.
  ///   - [bottomRadius]: corner radius for the bottom-left/bottom-right
  ///     corners. Defaults to `0`.
  ///   - [borderColor]: optional outline stroke colour. Defaults to `null`
  ///     (no outline).
  ///   - [borderWidth]: outline stroke width, used only when [borderColor]
  ///     is non-null. Defaults to `1.0`.
  const LayrzWorkspaceTabChromePainter({
    required this.fillColor,
    required this.topRadius,
    this.bottomRadius = 0.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Builds the tab outline as a [Path] of straight edges and quarter-circle
  /// arcs, starting at the bottom-left corner and winding clockwise.
  Path _buildPath(Size size) {
    final width = size.width;
    final height = size.height;
    final tr = topRadius.clamp(0.0, width / 2).clamp(0.0, height);
    final br = bottomRadius.clamp(0.0, width / 2).clamp(0.0, height);

    final path = Path()
      // Start at the bottom-left corner, above its curve (or exactly at the
      // corner when br is 0).
      ..moveTo(0, height - br)
      // Bottom-left curve (or a no-op straight continuation when br is 0).
      ..arcToPoint(Offset(br, height), radius: Radius.circular(br), clockwise: false)
      // Bottom edge, left to right.
      ..lineTo(width - br, height)
      // Bottom-right curve.
      ..arcToPoint(Offset(width, height - br), radius: Radius.circular(br), clockwise: false)
      // Right edge, up to the top-right curve.
      ..lineTo(width, tr)
      // Top-right curve.
      ..arcToPoint(Offset(width - tr, 0), radius: Radius.circular(tr), clockwise: true)
      // Top edge, right to left.
      ..lineTo(tr, 0)
      // Top-left curve.
      ..arcToPoint(Offset(0, tr), radius: Radius.circular(tr), clockwise: true)
      // Left edge, back down to the start.
      ..close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(path, Paint()..color = fillColor);

    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LayrzWorkspaceTabChromePainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.topRadius != topRadius ||
      oldDelegate.bottomRadius != bottomRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}

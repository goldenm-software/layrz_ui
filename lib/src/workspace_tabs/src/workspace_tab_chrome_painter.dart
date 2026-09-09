import 'package:flutter/widgets.dart';

/// Paints the "connected chrome" tab shape used by [LayrzWorkspaceTabs].
///
/// [LayrzWorkspaceTabChromePainter] draws a single tab's background as a
/// classic browser-tab silhouette: the top-left and top-right corners curve
/// *inward* (a normal rounded corner), while the bottom-left and
/// bottom-right corners flare *outward* into a convex shoulder that widens
/// as it sweeps down to the baseline — the S-curve that makes a tab read as
/// rising out of, and blending into, the panel below it rather than sitting
/// on top of it as a boxy rectangle.
///
/// Geometry:
/// - The top-left and top-right corners are rounded inward by [topRadius].
/// - The bottom-left and bottom-right corners flare outward by
///   [shoulderRadius] — a small convex curve, sized off the design tokens
///   (typically `tokens.radius.r2` or similar), that bulges past the tab's
///   vertical sides before meeting the baseline. This is what merges the
///   tab into the panel instead of leaving a boxy silhouette.
/// - The whole shape is filled with [fillColor].
/// - When [borderColor] is non-null, the shape's outline is stroked with
///   [borderWidth]. When [mergeBottom] is `true` (the active tab, whose
///   bottom edge is flush with the content panel below), only the open
///   top+sides+shoulders sub-path is stroked, so no seam line is drawn
///   across the join — the active tab visually merges into the panel
///   instead of being boxed off from it. When `false`, the full closed path
///   is stroked as before.
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
  ///
  /// These curve inward, like an ordinary rounded rectangle corner.
  final double topRadius;

  /// The size of the outward-flaring shoulder at the bottom-left and
  /// bottom-right corners.
  ///
  /// Unlike [topRadius], this does not round the corner inward — it
  /// controls how far the convex shoulder bulges outward and how tall the
  /// S-curve is before it meets the baseline, so the tab widens at its very
  /// bottom rather than narrowing. Pass `0` to fall back to a square
  /// bottom corner with no shoulder.
  final double shoulderRadius;

  /// Optional stroke colour drawn along the shape's outline.
  ///
  /// When `null`, no stroke is drawn — the shape is fill-only.
  final Color? borderColor;

  /// The stroke width used when [borderColor] is non-null.
  final double borderWidth;

  /// Whether this tab's bottom edge merges flush into the content panel
  /// below it (the active tab).
  ///
  /// When `true`, [borderColor]'s stroke is drawn only along the open
  /// top+sides+shoulders sub-path, omitting the bottom baseline, so the
  /// join between the tab and the panel is not sealed off by a visible
  /// line. When `false` (an inactive tab), the full closed outline is
  /// stroked, including its bottom edge.
  final bool mergeBottom;

  /// Creates a new [LayrzWorkspaceTabChromePainter].
  ///
  /// Parameters:
  ///   - [fillColor]: the tab shape's fill colour.
  ///   - [topRadius]: inward corner radius for the top-left/top-right
  ///     corners.
  ///   - [shoulderRadius]: outward-flare size for the bottom-left/
  ///     bottom-right shoulders. Defaults to `0`.
  ///   - [borderColor]: optional outline stroke colour. Defaults to `null`
  ///     (no outline).
  ///   - [borderWidth]: outline stroke width, used only when [borderColor]
  ///     is non-null. Defaults to `1.0`.
  ///   - [mergeBottom]: whether to omit the bottom edge from the stroked
  ///     outline so the tab merges into the panel below. Defaults to
  ///     `false`.
  const LayrzWorkspaceTabChromePainter({
    required this.fillColor,
    required this.topRadius,
    this.shoulderRadius = 0.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.mergeBottom = false,
  });

  /// Builds the tab outline as a [Path], starting at the bottom-left corner
  /// and winding clockwise.
  ///
  /// The top corners are ordinary inward quarter-circle arcs of
  /// [topRadius]. The bottom corners are outward-bulging convex shoulders:
  /// each vertical side ends [shoulderRadius] above the baseline, then a
  /// cubic Bézier curve bulges outward (past the tab's own vertical edge)
  /// before curving back in to meet the baseline — the classic browser-tab
  /// S-curve silhouette.
  Path _buildPath(Size size) {
    final width = size.width;
    final height = size.height;
    final tr = topRadius.clamp(0.0, width / 2).clamp(0.0, height);
    final sr = shoulderRadius.clamp(0.0, width / 2).clamp(0.0, height);

    return Path()
      // Start at the top of the left shoulder curve.
      ..moveTo(0, height - sr)
      // Bottom-left shoulder: bulge outward (to negative x) then sweep back
      // in to the baseline.
      ..cubicTo(-sr, height - sr, -sr, height, 0, height)
      // Bottom edge, left to right.
      ..lineTo(width, height)
      // Bottom-right shoulder: mirror of the left one, sweeping back up.
      ..cubicTo(width + sr, height, width + sr, height - sr, width, height - sr)
      // Right edge, up to the top-right curve.
      ..lineTo(width, tr)
      // Top-right curve (inward).
      ..arcToPoint(Offset(width - tr, 0), radius: Radius.circular(tr), clockwise: true)
      // Top edge, right to left.
      ..lineTo(tr, 0)
      // Top-left curve (inward).
      ..arcToPoint(Offset(0, tr), radius: Radius.circular(tr), clockwise: true)
      // Left edge, back down to the start.
      ..close();
  }

  /// Builds the open border sub-path used when [mergeBottom] is `true`: the
  /// same outline as [_buildPath] but omitting the bottom baseline segment,
  /// so a stroke along it never draws the seam between the tab and the
  /// panel it merges into.
  ///
  /// Traced left-to-right so both shoulders and both sides are still
  /// included, just not connected across the bottom.
  Path _buildOpenBorderPath(Size size) {
    final width = size.width;
    final height = size.height;
    final tr = topRadius.clamp(0.0, width / 2).clamp(0.0, height);
    final sr = shoulderRadius.clamp(0.0, width / 2).clamp(0.0, height);

    return Path()
      // Start at the baseline end of the left shoulder.
      ..moveTo(0, height)
      // Left shoulder, sweeping up and outward from the baseline.
      ..cubicTo(-sr, height, -sr, height - sr, 0, height - sr)
      // Left edge, up to the top-left curve.
      ..lineTo(0, tr)
      // Top-left curve (inward).
      ..arcToPoint(Offset(tr, 0), radius: Radius.circular(tr), clockwise: true)
      // Top edge, left to right.
      ..lineTo(width - tr, 0)
      // Top-right curve (inward).
      ..arcToPoint(Offset(width, tr), radius: Radius.circular(tr), clockwise: true)
      // Right edge, down to the right shoulder.
      ..lineTo(width, height - sr)
      // Right shoulder, sweeping down and outward to the baseline.
      ..cubicTo(width + sr, height - sr, width + sr, height, width, height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(path, Paint()..color = fillColor);

    if (borderColor != null) {
      final strokePath = mergeBottom ? _buildOpenBorderPath(size) : path;
      canvas.drawPath(
        strokePath,
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
      oldDelegate.shoulderRadius != shoulderRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.mergeBottom != mergeBottom;
}
